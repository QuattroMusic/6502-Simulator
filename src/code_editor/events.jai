get_caret_pos :: (row: u32, col: u32) -> u32 {
	idx := col;
	for 1 .. row idx += rows_length[it - 1] + 1;
	return idx;
}

get_caret_col_and_row :: (idx: u32) -> (row: u32, col: u32) {
	col := idx;
	row: u32 = 0;
	
	for rows_length {
		if col >= it + 1 {
			col -= it + 1;
			row += 1;
		} else break;
	}
	
	return row, col;
}

area_selecting :: () -> bool {
	return caret_col != caret_col_selection || caret_row != caret_row_selection;
}

calculate_row_length :: (row: u32) {
	caret := get_caret_pos(row, 0);
	
	line_length: u32 = 0;
	while caret < content.count {
		line_length += 1;
		caret += 1;
		if content.data[caret] == #char "\n" then break;
	}
	
	rows_length[row] = line_length;
}

remove_selected_area :: (current_caret: *u32) {
	other_caret := get_caret_pos(caret_row_selection, caret_col_selection);
	
	first_cursor: *void = ---;
	last_cursor:  *void = ---;
	distance:      s64  = ---;
	amount:        s64  = ---;
	
	// If it's forward, the other caret is in the back.
	// Otherwise, it's in the front
	if current_caret.* > other_caret {  // forward
		distance     = current_caret.* - other_caret;
		amount       = content.count   - current_caret.*;
		first_cursor = content.data    + other_caret;
		last_cursor  = content.data    + current_caret.*;
		
		// override caret with the back one
		current_caret.* = other_caret;
		caret_col = caret_col_selection;
		caret_row = caret_row_selection;
	} else {  // reverse
		distance     = other_caret   - current_caret.*;
		amount       = content.count - other_caret;
		first_cursor = content.data  + current_caret.*;
		last_cursor  = content.data  + other_caret;
	}
	
	copy(first_cursor, last_cursor, amount);
	content.count -= distance;
}

event_left :: () -> Editor_Interaction {
	if caret_row == 0 && caret_col == 0 then return .RESET_CARET | .RESET_SELECTION;
	
	if caret_col == 0 {
		caret_row -= 1;
		caret_col = rows_length[caret_row];
	} else {
		caret_col -= 1;
	}
	
	return .RESET_CARET | .RESET_SELECTION;
}

event_right :: () -> Editor_Interaction {
	if caret_col == rows_length[caret_row] {
		if caret_row == rows_length.count - 1 then return .RESET_CARET | .RESET_SELECTION;

		caret_col = 0;
		caret_row += 1;
	} else {
		caret_col += 1;
	}
	
	return .RESET_CARET | .RESET_SELECTION;
}

event_up :: () -> Editor_Interaction {
	// Todo - Quattro - move the visual
	if caret_row == 0 then return .RESET_CARET | .RESET_SELECTION;
	
	caret_row -= 1;
	
	if rows_length[caret_row] < caret_col {
		caret_col = rows_length[caret_row];
	}
	
	return .RESET_CARET | .RESET_SELECTION;
}

event_down :: () -> Editor_Interaction {
	// Todo - Quattro - move the visual
	if caret_row == rows_length.count - 1 {
		caret_col = rows_length[rows_length.count - 1];
		return .RESET_CARET | .RESET_SELECTION;
	}
	
	caret_row += 1;
	
	if rows_length[caret_row] < caret_col {
		caret_col = rows_length[caret_row];
	}
	
	return .RESET_CARET | .RESET_SELECTION;
}

event_tab :: () -> Editor_Interaction {
	idx := get_caret_pos(caret_row, caret_col);
	if area_selecting() then remove_selected_area(*idx);
	
	array_insert_at(*content, #char "\t", idx);
	caret_col += 1;

	calculate_rows_length();
	
	return .UPDATE_COLORING | .RESET_CARET | .RESET_SELECTION;
}

event_enter :: () -> Editor_Interaction {
	idx := get_caret_pos(caret_row, caret_col);
	
	if area_selecting() {
		remove_selected_area(*idx);
		calculate_row_length(caret_row);
	}
	
	// count tabs on the current line
	tabs := 0;
	for 0 .. cast(s64, caret_col) - 1 {
		c := content[idx + it - caret_col];
		if c == #char "\t" then tabs += 1;
	}
	
	array_insert_at(*content, #char "\n", idx);
	for 0 .. tabs - 1 {
		array_insert_at(*content, #char "\t", idx + 1);
	}
	
	diff := rows_length[caret_row] - caret_col;
	array_insert_at(*rows_length, diff, caret_row + 1);
	
	caret_row += 1;
	caret_col = xx tabs;
	
	editor.row_digits = count_digits(xx rows_length.count);
	
	// advance scrollbar if pressing enter at the bottom of the screen
	rows_on_screen     := editor_content_size.y / FONT_SIZE_NORMAL;
	first_visible_row  := scrollbar_pos.y       / FONT_SIZE_NORMAL;
	
	relative_row_on_screen := caret_row - first_visible_row;
	rows_delta_from_bottom_of_screen := rows_on_screen - relative_row_on_screen;
	
	if rows_delta_from_bottom_of_screen < 6 && rows_delta_from_bottom_of_screen >= 0 {
		editor.scrollbar_pos.y += FONT_SIZE_NORMAL;
	}
	
	calculate_rows_length();
	
	return .UPDATE_COLORING | .RESET_CARET | .RESET_SELECTION;
}

event_cancel :: () -> Editor_Interaction {
	idx := get_caret_pos(caret_row, caret_col);

	if area_selecting() {
		remove_selected_area(*idx);
		calculate_rows_length();
		return .UPDATE_COLORING | .RESET_CARET | .RESET_SELECTION;
	} else {
		if idx == 0 then return 0;
	}
	
	array_ordered_remove_by_index(*content, idx - 1);
	
	if caret_col == 0 {  // deleting a row
		v := rows_length[caret_row];
		array_ordered_remove_by_index(*rows_length, caret_row);
		caret_row -= 1;
		caret_col = rows_length[caret_row];
		rows_length[caret_row] += v;
		
		editor.row_digits = count_digits(xx editor.rows_length.count);
		
		// advance scrollbar if pressing delete at the top of the screen
		rows_on_screen     := editor_content_size.y / FONT_SIZE_NORMAL;
		first_visible_row  := scrollbar_pos.y       / FONT_SIZE_NORMAL;
		
		relative_row_on_screen := caret_row - first_visible_row;
		
		if relative_row_on_screen < 6 && relative_row_on_screen >= 0 {
			editor.scrollbar_pos.y -= FONT_SIZE_NORMAL;
			editor.scrollbar_pos.y = max(0.0, editor.scrollbar_pos.y);
		}
	} else {
		rows_length[caret_row] -= 1;
		
		caret_col -= 1;
	}
	
	calculate_rows_length();
	
	return .UPDATE_COLORING | .RESET_CARET | .RESET_SELECTION;
}

event_delete :: () -> Editor_Interaction {
	if !area_selecting() {
		// reject the movement if the area is selected
		event_right();
	}
	
	event_cancel();
	
	return .UPDATE_COLORING | .RESET_CARET | .RESET_SELECTION;
}

event_char :: () -> Editor_Interaction {
	idx := get_caret_pos(caret_row, caret_col);
	
	if area_selecting() {
		remove_selected_area(*idx);
	}
	
	c := to_lower(pressed_char);
	
	array_insert_at(*content, c, idx);
	rows_length[caret_row] += 1;
	
	caret_col += 1;
	
	calculate_rows_length();
	
	return .RESET_CARET | .RESET_SELECTION | .UPDATE_COLORING;
}

event_mouse_down :: () -> Editor_Interaction {
	x := cast(s32, mouse_x - pos.x);
	y := cast(s32, mouse_y - pos.y);
	
	size_x, size_y := editor_content_size.x, editor_content_size.y;
	
	// if the mouse is inside the area
	if x < 0 || x > cast(s32, size_x) || y < 0 || y > cast(s32, size_y) then return 0;
	
	// get the current char with "rounding"
	x = cast(s32, mouse_x - pos.x + 8);
	
	x += cast(s32, editor.scrollbar_pos.x);
	y += cast(s32, editor.scrollbar_pos.y);
	
	x -= cast(s32, get_width_of_line_count_bar());
	y -= TOP_PADDING;
	
	y /= 16;
	if y >= rows_length.count {
		caret_row = xx (rows_length.count - 1);
	} else {
		caret_row = xx y;
	}
	
	x /= 16;
	cursor_start_row: u32 = 0;
	for 0 .. cast(s64, caret_row) - 1 { cursor_start_row += rows_length[it] + 1; }

	cursor := 0;
	count := 0;
	for 0 .. rows_length[caret_row] - 1 {
		if cursor >= x || cursor_start_row + it >= content.count then break;
		count += 1;
		cursor += 1;
		
		c := content[cursor_start_row + it];
		if c == #char "\t" {
			cursor += 3;
		}
	}
	
	x = xx count;
	
	if cast(u32, x) > rows_length[caret_row] {
		caret_col = rows_length[caret_row];
	} else {
		caret_col = xx x;  // :)
	}
	
	interaction := Editor_Interaction.RESET_CARET;
	
	if is_mouse_pressed(0) {
		caret_col_selection = caret_col;
		caret_row_selection = caret_row;
		interaction |= .RESET_SELECTION;
	}
	
	return interaction;
}

event_end :: () -> Editor_Interaction {
	line_length := rows_length[caret_row];
	caret_col = line_length;
	
	return .RESET_CARET | .RESET_SELECTION;
}

event_copy :: () -> Editor_Interaction {
	text_to_copy: string;

	if area_selecting() {
		caret := get_caret_pos(caret_row, caret_col);
		other_caret := get_caret_pos(caret_row_selection, caret_col_selection);
		
		if caret > other_caret {  // forward
			text_to_copy.data = content.data + other_caret;
			text_to_copy.count = caret - other_caret;
		} else {  // reverse
			text_to_copy.data = content.data + caret;
			text_to_copy.count = other_caret - caret;
		}
	} else {
		// copy entire row
		caret := get_caret_pos(caret_row, 0);
		
		text_to_copy.data = content.data + caret;
		text_to_copy.count = rows_length[caret_row] + 1;  // +1 because of \n
	}
	
	clipboard_set_text(vp.window, text_to_copy);
	
	return .RESET_CARET;
}

event_paste :: () -> Editor_Interaction {
	data := clipboard_get_text(vp.window);
	if !data then return .RESET_CARET;
	
	interaction: Editor_Interaction = .RESET_CARET | .UPDATE_COLORING;
	
	idx := get_caret_pos(caret_row, caret_col);
	if area_selecting() {
		// Todo - Quattro - avoid eccessive copy
		remove_selected_area(*idx);
		// now idx points to the correct position
		
		interaction |= .RESET_SELECTION;
	}
	
	if content.count + data.count >= content.allocated {
		// need more space to put data
		array_reserve(*content, (content.count + data.count) * 2);
	}
	
	from := content.data + idx;
	to   := content.data + idx + data.count;
	size := content.count - idx;
	
	copy(to, from, size);
	
	memcpy(from, data.data, data.count);
	content.count += data.count;
	
	calculate_rows_length();
	
	// move the caret after the paste area
	row, col := get_caret_col_and_row(xx (idx + data.count));
	caret_row, caret_col = row, col;
	caret_row_selection, caret_col_selection = row, col;
	
	return interaction;
}

handle_code_editor_events :: () {
	if !editor.file_path then return;
	
	if is_mouse_pressed(0) {
		if mouse_inside_a_window() {
			editor.focused = false;
			return;
		}
		
		state := create_selectable_region(.SCROLLBAR, editor.pos, editor.size, disable_interactions = true);
		editor.focused = (state == .PRESSED);
	}
	
	if !editor.focused then return;

	// interactions
	edited := false;
	moved  := false;
	
	Mod :: enum_flags {
		SHIFT;
		CTRL;
		ALT;
	}
	
	modifiers: Mod;
	modifiers |= xx cast(u64, is_key_down(KEY_SHIFT)) << 0;
	modifiers |= xx cast(u64, is_key_down(KEY_CTRL))  << 1;
	modifiers |= xx cast(u64, is_key_down(KEY_ALT))   << 2;
	
	interactions: Editor_Interaction;
	
	// Intentionally ignoring combinations at the moment
	if modifiers == {
		case .CTRL;
			if is_key_pressed(KEY_S) then { save_editor_file(); interactions |= .RESET_CARET; }
			if is_key_pressed(KEY_C) then interactions |= event_copy();
			if is_key_pressed_or_repeated(KEY_V) then interactions |= event_paste();
			// Todo - Quattro - word movement with arrows
			// Todo - Quattro - word deletion
			// Todo - Quattro - new line without changing the selected one
			// Todo - Quattro - jump to label
		case .SHIFT;
			if pressed_char interactions |= event_char();
			// Todo - Quattro - selection
		case .ALT;
			// Todo - Quattro - move line up or down
		case;
			if pressed_char then interactions |= event_char();

			if is_key_pressed_or_repeated(KEY_LEFT)  then interactions |= event_left();      
			if is_key_pressed_or_repeated(KEY_RIGHT) then interactions |= event_right();     
			if is_key_pressed_or_repeated(KEY_UP)    then interactions |= event_up();        
			if is_key_pressed_or_repeated(KEY_DOWN)  then interactions |= event_down();      
			if is_key_pressed_or_repeated(KEY_TAB)   then interactions |= event_tab();       
			if is_key_pressed_or_repeated(KEY_ENTER) then interactions |= event_enter();     
			if is_key_pressed_or_repeated(KEY_CANC)  then interactions |= event_cancel();    
			if is_key_pressed_or_repeated(KEY_DEL)   then interactions |= event_delete();    
			if is_key_pressed_or_repeated(KEY_END)   then interactions |= event_end();
			if is_mouse_down(0) && !focused_uuid     then interactions |= event_mouse_down();
	}

	if interactions & .RESET_CARET {
		editor.caret_time = ms_since_init();
	}
	
	if interactions & .RESET_SELECTION {
		caret_col_selection = caret_col;
		caret_row_selection = caret_row;
	}
	
	if interactions & .UPDATE_COLORING {
		// Todo - Quattro - This is updating everything, maybe we could update where needed.
		update_code_editor_coloring();
		
		if settings.editor.when_to_save == .EACH_EDIT then save_editor_file();
		if settings.editor.when_to_save == .EVERY_MS then editor.asked_to_save = true;
	}
	
	if editor.asked_to_save {
		time := ms_since_init();
		
		if time - last_saved_time > settings.editor.save_interval_in_ms {
			editor.last_saved_time = time;
			editor.asked_to_save = false;
			
			save_editor_file();
		}
	}
}

#scope_file
using editor;

Editor_Interaction :: enum_flags {
	RESET_CARET;
	RESET_SELECTION;
	UPDATE_COLORING;
}
