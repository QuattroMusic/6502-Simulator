get_current_idx :: () -> u32 {
	using editor;
	
	idx := caret_col;
	for 1..caret_row idx += rows_length[it - 1] + 1;
	return idx;
}

event_left :: () {
	using editor;
	
	if caret_row == 0 && caret_col == 0 then return;
	
	if caret_col == 0 {
		caret_row -= 1;
		caret_col = rows_length[caret_row];
	} else {
		caret_col -= 1;
	}
}

event_right :: () {
	using editor;
	
	if caret_col == rows_length[caret_row] {
		if caret_row == rows_length.count - 1 then return;

		caret_col = 0;
		caret_row += 1;
	} else {
		caret_col += 1;
	}
}

event_up :: () {
	using editor;
	
	if caret_row == 0 then return;
	
	caret_row -= 1;
	
	if rows_length[caret_row] < caret_col {
		caret_col = rows_length[caret_row];
	}
}

event_down :: () {
	using editor;
	
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
	using editor;
	
	idx := get_current_idx();
	
	array_insert_at(*content, #char "\t", idx);
	// array_insert_at(*content, #char " ", idx);
	// array_insert_at(*content, #char " ", idx);
	// array_insert_at(*content, #char " ", idx);
	
	rows_length[caret_row] += 1;
	caret_col += 1;
}

event_enter :: () {
	using editor;
	
	idx := get_current_idx();
	array_insert_at(*content, #char "\n", idx);
	
	diff := rows_length[caret_row] - caret_col;
	array_insert_at(*rows_length, diff, caret_row + 1);
	
	rows_length[caret_row] = caret_col;
	
	caret_row += 1;
	caret_col = 0;
	
	editor.row_digits = count_digits(xx rows_length.count);
}

event_delete :: () {
	using editor;
	
	idx := get_current_idx();
	if idx == 0 then return;
	
	array_ordered_remove_by_index(*content, idx - 1);
	
	if caret_col == 0 {
		v := rows_length[caret_row];
		array_ordered_remove_by_index(*rows_length, caret_row);
		caret_row -= 1;
		caret_col = rows_length[caret_row];
		rows_length[caret_row] += v;
		
		editor.row_digits = count_digits(xx editor.rows_length.count);
	} else {
		rows_length[caret_row] -= 1;
		
		caret_col -= 1;
	}
}

event_char :: () {
	using editor;

	idx := get_current_idx();
	
	array_insert_at(*content, pressed_char, idx);
	rows_length[caret_row] += 1;
	
	caret_col += 1;
}

event_mouse :: () {
	using editor;
	
	x := cast(s32, mouse_x - pos.x);
	y := cast(s32, mouse_y - pos.y);
	
	size_x, size_y := editor_content_size.x, editor_content_size.y;
	
	// if the mouse is inside the area
	if x < 0 || x > cast(s32, size_x) || y < 0 || y > cast(s32, size_y) then return;
	
	// get the current char with "rounding"
	x = cast(s32, mouse_x - pos.x + 8);
	
	x += cast(s32, editor.scrollbar_pos.x);
	y += cast(s32, editor.scrollbar_pos.y);
	
	// Todo - Quattro - 3 and 5 is because of padding, make it more robust
	x -= 3 + cast(s32, get_width_of_line_count_bar());
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

			if is_key_pressed_or_repeated(KEY_LEFT)   { event_left();   moved = true; }
			if is_key_pressed_or_repeated(KEY_RIGHT)  { event_right();  moved = true; }
			if is_key_pressed_or_repeated(KEY_UP)     { event_up();     moved = true; }
			if is_key_pressed_or_repeated(KEY_DOWN)   { event_down();   moved = true; }
			if is_key_pressed_or_repeated(KEY_TAB)    { event_tab();    moved = true; edited = true; }
			if is_key_pressed_or_repeated(KEY_ENTER)  { event_enter();  moved = true; edited = true; }
			if is_key_pressed_or_repeated(KEY_DELETE) { event_delete(); moved = true; edited = true; }
			if is_mouse_pressed(0)                    { event_mouse();  moved = true; }
	}

	if moved {
		editor.caret_time = ms_since_init();
	}
	
	if edited {
		// Todo - Quattro - This is updating everything, maybe we could update where needed.
		update_code_editor_coloring();
		
		if settings.editor.when_to_save == .EACH_EDIT then save_editor_file();
		
		if settings.editor.when_to_save == .EVERY_MS then editor.asked_to_save = true;
	}
	
	if editor.asked_to_save {
		time := ms_since_init();
		
		if time - editor.last_saved_time > settings.editor.save_interval_in_ms {
			editor.last_saved_time = time;
			editor.asked_to_save = false;
			
			save_editor_file();
		}
	}
}
