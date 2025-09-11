get_caret_pos :: (row: u32, col: u32) -> u32 {
	idx := col;
	for 1 .. row idx += rows_length[it - 1] + 1;
	return idx;
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
	forward := current_caret.* > other_caret;
	
	first_cursor: *void = ---;
	last_cursor:  *void = ---;
	distance:      s64  = ---;
	amount:        s64  = ---;
	
	// If it's forward, the other caret is in the back.
	// Otherwise, it's in the front
	if forward {
		distance     = current_caret.* - other_caret;
		amount       = content.count   - current_caret.*;
		first_cursor = content.data    + other_caret;
		last_cursor  = content.data    + current_caret.*;
		
		// override caret with the back one
		current_caret.* = other_caret;
		caret_col = caret_col_selection;
		caret_row = caret_row_selection;
	} else {
		distance     = other_caret   - current_caret.*;
		amount       = content.count - other_caret;
		first_cursor = content.data  + current_caret.*;
		last_cursor  = content.data  + other_caret;
	}
	
	copy(first_cursor, last_cursor, amount);
	content.count -= distance;
}

event_left :: () {
	if caret_row == 0 && caret_col == 0 then return;
	
	if caret_col == 0 {
		caret_row -= 1;
		caret_col = rows_length[caret_row];
	} else {
		caret_col -= 1;
	}
}

event_right :: () {
	if caret_col == rows_length[caret_row] {
		if caret_row == rows_length.count - 1 then return;

		caret_col = 0;
		caret_row += 1;
	} else {
		caret_col += 1;
	}
}

event_up :: () {
	// Todo - Quattro - move the visual
	if caret_row == 0 then return;
	
	caret_row -= 1;
	
	if rows_length[caret_row] < caret_col {
		caret_col = rows_length[caret_row];
	}
}

event_down :: () {
	// Todo - Quattro - move the visual
	if caret_row == rows_length.count - 1 {
		caret_col = rows_length[rows_length.count - 1];
		return;
	}
	
	caret_row += 1;
	
	if rows_length[caret_row] < caret_col {
		caret_col = rows_length[caret_row];
	}
}

event_tab :: () {
	idx := get_caret_pos(caret_row, caret_col);
	if area_selecting() then remove_selected_area(*idx);
	
	array_insert_at(*content, #char "\t", idx);
	caret_col += 1;

	calculate_rows_length();
}

event_enter :: () {
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
}

event_cancel :: () {
	idx := get_caret_pos(caret_row, caret_col);
	if area_selecting() {
		remove_selected_area(*idx);
		calculate_rows_length();
		return;
	} else {
		if idx == 0 then return;
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
}

event_delete :: () {
	if !area_selecting() {
		// reject the movement if the area is selected
		event_right();
	}
	
	event_cancel();
}

event_char :: () {
	idx := get_caret_pos(caret_row, caret_col);
	
	if area_selecting() {
		remove_selected_area(*idx);
	}
	
	c := to_lower(pressed_char);
	
	array_insert_at(*content, c, idx);
	rows_length[caret_row] += 1;
	
	caret_col += 1;
	
	calculate_rows_length();
}

event_mouse_down :: () {
	x := cast(s32, mouse_x - pos.x);
	y := cast(s32, mouse_y - pos.y);
	
	size_x, size_y := editor_content_size.x, editor_content_size.y;
	
	// if the mouse is inside the area
	if x < 0 || x > cast(s32, size_x) || y < 0 || y > cast(s32, size_y) then return;
	
	// get the current char with "rounding"
	x = cast(s32, mouse_x - pos.x + 8);
	
	x += cast(s32, editor.scrollbar_pos.x);
	y += cast(s32, editor.scrollbar_pos.y);
	
	// Todo - Quattro - 5 is because of padding, make it more robust
	x -= cast(s32, get_width_of_line_count_bar());
	y -= 5;
	
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
	
	if is_mouse_pressed(0) {
		caret_col_selection = caret_col;
		caret_row_selection = caret_row;
	}
}

event_end :: () {
	line_length := rows_length[caret_row];
	caret_col = line_length;
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
	
	if modifiers == {
		case .CTRL;
			if is_key_pressed(KEY_S) then save_editor_file();
			// Todo - Quattro - word movement with arrows
			// Todo - Quattro - word deletion
			// Todo - Quattro - new line without changing the selected one
			// Todo - Quattro - jump to label
		case .SHIFT;
			if pressed_char { event_char(); moved = true; edited = true; }
			// Todo - Quattro - selection
		case .ALT;
			// Todo - Quattro - move line up or down
		case;
			if pressed_char { event_char(); moved = true; edited = true; }

			if is_key_pressed_or_repeated(KEY_LEFT)  { event_left();        moved = true; }
			if is_key_pressed_or_repeated(KEY_RIGHT) { event_right();       moved = true; }
			if is_key_pressed_or_repeated(KEY_UP)    { event_up();          moved = true; }
			if is_key_pressed_or_repeated(KEY_DOWN)  { event_down();        moved = true; }
			if is_key_pressed_or_repeated(KEY_TAB)   { event_tab();         moved = true; edited = true; }
			if is_key_pressed_or_repeated(KEY_ENTER) { event_enter();       moved = true; edited = true; }
			if is_key_pressed_or_repeated(KEY_CANC)  { event_cancel();      moved = true; edited = true; }
			if is_key_pressed_or_repeated(KEY_DEL)   { event_delete();      moved = true; edited = true; }
			if is_key_pressed_or_repeated(KEY_END)   { event_end();         moved = true; }
			if is_mouse_down(0) && !focused_uuid     { event_mouse_down();  moved = true; }
	}

	if moved {
		editor.caret_time = ms_since_init();
		
		if !is_mouse_down(0) {
			caret_col_selection = caret_col;
			caret_row_selection = caret_row;
		}
	}
	
	if edited {
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
