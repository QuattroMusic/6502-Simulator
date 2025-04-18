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
	
	// caret_idx -= 1;
}

event_right :: () {
	using editor;
	
	if caret_col == rows_length[caret_row] {
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
	
	array_insert_at(*content, #char " ", idx);
	array_insert_at(*content, #char " ", idx);
	array_insert_at(*content, #char " ", idx);
	array_insert_at(*content, #char " ", idx);
	
	rows_length[caret_row] += 4;
	caret_col += 4;
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
	
	p := get_panel(ui.display_panel);
	if p.visible && is_inside_rect(.{cast(f32, mouse_x), cast(f32, mouse_y)}, p.pos, p.size) then return;
	
	p = get_panel(ui.settings_panel);
	if p.visible && is_inside_rect(.{cast(f32, mouse_x), cast(f32, mouse_y)}, p.pos, p.size) then return;
	
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
	
	x /= 16;
	y /= 16;
	
	if y >= rows_length.count {
		caret_row = xx (rows_length.count - 1);
	} else {
		caret_row = xx y;
	}
	
	if cast(u32, x) > rows_length[caret_row] {
		caret_col = rows_length[caret_row];
	} else {
		caret_col = xx x;
	}
}

handle_code_editor_events :: () {
	if !editor.file_path then return;
	
	// focus
	if is_mouse_inside_rect(editor.pos, editor.size) then editor.focused = true;
	else                                                  editor.focused = false;

	if is_panel_visible(ui.modal_panel) then editor.focused = false;
	else                                     editor.focused = true;

	if !editor.focused then return;

	// interaction
	moved := false;
	edited := false;
	
	Mod :: enum_flags {
		SHIFT;
		CTRL;
		ALT;
	}
	
	modifiers: Mod;
	if is_key_down(KEY_SHIFT) then modifiers |= .SHIFT;
	if is_key_down(KEY_CTRL)  then modifiers |= .CTRL;
	if is_key_down(KEY_ALT)   then modifiers |= .ALT;
	
	if modifiers == {
		case .CTRL;
			// Todo - Quattro - word movement with arrows
			// Todo - Quattro - word deletion
			// Todo - Quattro - new line without changing the selected one
			// Todo - Quattro - jump to label
		case .SHIFT;
			if pressed_char { event_char(); moved = true; edited = true; }
			// Todo - Quattro - selection
			// Todo - Quattro - shift-alt
		case .ALT;
			// Todo - Quattro - line movement
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
	}
}
