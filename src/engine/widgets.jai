button :: ($$text: string, pos: Vec2, size: Vec2, $t: f32 = FONT_SIZE_SMALL, disabled := false, it: s64 = 0, loc := #caller_location) -> bool {
	state := create_selectable_region(.BUTTON, pos, size, loc, it);

	bg_col:     Col = ---;
	border_col: Col = ---;
	text_col:   Col = ---;

	if disabled {
		bg_col     = settings.themes.platform_widget_bg_normal;
		border_col = settings.themes.platform_disabled;
		text_col   = settings.themes.platform_disabled;
	} else {
		if state == {
			case .RELEASE_NON_HOVER; #through;
			case .NORMAL;
				bg_col     = settings.themes.platform_widget_bg_normal;
				border_col = settings.themes.platform_widget_border_normal;
				text_col   = settings.themes.platform_text_normal;
			case .PRESSED; #through;
			case .HOLD;
				bg_col     = settings.themes.platform_widget_bg_press;
				border_col = settings.themes.platform_widget_border_press;
				text_col   = settings.themes.platform_text_press;
			case .RELEASE; #through;
			case .HOVER; #through;
			case .HOLD_NON_HOVER;
				bg_col     = settings.themes.platform_widget_bg_hover;
				border_col = settings.themes.platform_widget_border_hover;
				text_col   = settings.themes.platform_text_hover;
		}
	}

	draw_rect(pos, size, bg_col);
	draw_rect_lines(pos, size, border_col, #run t / FONT_SIZE_GRANULARITY);

	#if is_constant(text) {
		s :: #run measure_text(text, t);
	} else {
		s := measure_text(text, t);
	}
	draw_text(text, pos + size / 2 - s / 2, t, text_col);

	return state == .RELEASE;
}

button :: ($$icon: Icon, pos: Vec2, size: Vec2, $t: f32 = FONT_SIZE_SMALL, it: s64 = 0, loc := #caller_location) -> bool {
	state := create_selectable_region(.BUTTON, pos, size, loc, it);

	bg_col:     Col = ---;
	border_col: Col = ---;
	text_col:   Col = ---;
	if state == {
		case .RELEASE_NON_HOVER; #through;
		case .NORMAL;
			bg_col     = settings.themes.platform_widget_bg_normal;
			border_col = settings.themes.platform_widget_border_normal;
			text_col   = settings.themes.platform_text_normal;
		case .PRESSED; #through;
		case .HOLD;
			bg_col     = settings.themes.platform_widget_bg_press;
			border_col = settings.themes.platform_widget_border_press;
			text_col   = settings.themes.platform_text_press;
		case .RELEASE; #through;
		case .HOVER; #through;
		case .HOLD_NON_HOVER;
			bg_col     = settings.themes.platform_widget_bg_hover;
			border_col = settings.themes.platform_widget_border_hover;
			text_col   = settings.themes.platform_text_hover;
	}

	draw_rect(pos, size, bg_col);
	draw_rect_lines(pos, size, border_col, #run t / FONT_SIZE_GRANULARITY);

	s :: Vec2.{t, t};
	draw_icon(icon, pos + size / 2 - s / 2, t, text_col);

	return state == .RELEASE;
}

checkbox :: ($$text: string, pos: Vec2, size: Vec2, value: *bool, it: s64 = 0, loc := #caller_location) -> bool {
	#if is_constant(text) {
		s :: #run measure_text(text, FONT_SIZE_SMALL);
	} else {
		s := measure_text(text, FONT_SIZE_SMALL);
	}

	state := create_selectable_region(.CHECKBOX, pos, size + .{s.x + 12, 0}, loc, it);

	bg_col:     Col = ---;
	text_col:   Col = ---;
	if state == {
		case .RELEASE_NON_HOVER; #through;
		case .NORMAL;
			bg_col     = settings.themes.platform_widget_bg_hover;
			text_col   = settings.themes.platform_text_normal;
		case .RELEASE;
			value.* = !value.*;
			#through;
		case .PRESSED; #through;
		case .HOLD;
			bg_col     = settings.themes.platform_widget_bg_press;
			text_col   = settings.themes.platform_text_press;
		case .HOVER; #through;
		case .HOLD_NON_HOVER;
			bg_col     = settings.themes.platform_widget_bg_hover;
			text_col   = settings.themes.platform_text_hover;
	}

	if value.* || state == .PRESSED || state == .HOLD then draw_rect(pos + .{4, 4}, size - .{8, 8}, bg_col);
	draw_rect_lines(pos, size, settings.themes.platform_line);
	draw_text(text, pos + .{size.x + 8, (size.y - s.y) / 2}, FONT_SIZE_SMALL, text_col);
	
	return state == .RELEASE;
}

draw_step_hslider :: (pos: Vec2, size: Vec2, amt: s32, value: *s64, disabled: bool = false, it: s64 = 0, loc := #caller_location) {
	draw_rect(pos + .{0, size.y / 2 - 1}, .{size.x, 2}, ifx disabled then settings.themes.platform_disabled else settings.themes.platform_line);

	col_main: Col = ---;
	col_step: Col = ---;

	if !disabled {
		col_main = settings.themes.platform_widget_bg_hover;
		col_step = settings.themes.platform_widget_border_normal;

		state := create_selectable_region(.SLIDER, pos, size, loc, it);

		if state == .PRESSED || state == .HOLD {
			col_main = settings.themes.platform_widget_bg_press;
			value.* = xx clamp((cast(f32, mouse_x) - pos.x) / size.x * amt, 0, xx (amt - 1));
		}
	} else {
		col_main = settings.themes.platform_disabled;
		col_step = settings.themes.platform_disabled;
	}

	for 0..amt / 3 {
		x := cast(f32)(it * 3) / (amt - 1) * size.x;
		s := size.y / 2;
		if it % 3 == 0 then s = size.y / 3 * 2;

		step_bar_pos := pos + .{x - 1, size.y / 2 - s / 2};
		step_bar_pos.x = cast(f32, cast(s64, step_bar_pos.x));
		step_bar_pos.y = cast(f32, cast(s64, step_bar_pos.y));

		bar_size := Vec2.{2, s};
		bar_size.y = cast(f32, cast(s64, bar_size.y));

		draw_rect(step_bar_pos, bar_size, col_step);
	}

	pos_x := pos.x + cast(f32)value.* / (amt - 1) * size.x;

	main_step_bar_pos := Vec2.{pos_x - 4, pos.y};
	main_step_bar_pos.x = cast(f32, cast(s64, main_step_bar_pos.x));
	main_step_bar_pos.y = cast(f32, cast(s64, main_step_bar_pos.y));

	draw_rect(main_step_bar_pos, .{8, size.y}, col_main);
}

draw_scrollbar :: (pos: Vec2, size: Vec2, scroll_pos: *Vec2, scroll_size: Vec2, min_size: Vec2, speed_slow: s64, speed_fast: s64, it: s64 = 0, loc := #caller_location) -> Vec2 {
	y_visible := (min_size.y + size.y) < scroll_size.y;
	x_visible := (min_size.x + size.x) < scroll_size.x;

	true_size := size;

	content_size_without_scrollbar := size;
	if x_visible then content_size_without_scrollbar.y -= WIDGET_SCROLLBAR_SIZE;
	if y_visible then content_size_without_scrollbar.x -= WIDGET_SCROLLBAR_SIZE;

	// Todo - Quattro - Check again and document this use case of disable_interactions = true
	content_state := create_selectable_region(.SCROLLBAR, pos, content_size_without_scrollbar, loc, it, disable_interactions = true);

	if y_visible {
		true_size.x -= WIDGET_SCROLLBAR_SIZE;

		scroll_pos_x := pos.x + size.x - WIDGET_SCROLLBAR_SIZE;
		scroll_pos_y := pos.y;
		off := ifx x_visible then cast(f32)WIDGET_SCROLLBAR_SIZE;

		state := create_selectable_region(.SCROLLBAR, .{scroll_pos_x, scroll_pos_y}, .{WIDGET_SCROLLBAR_SIZE, size.y - off}, loc, it + 1);

		if mouse_dz && !is_key_down(KEY_SHIFT) && content_state == .HOVER {
			true_speed := ifx is_key_down(KEY_CTRL) then speed_fast else speed_slow;
			amt := mouse_dz * FONT_SIZE_NORMAL * true_speed;
			scroll_pos.*.y -= amt;
		}

		aspect_ratio := (size.y - off) / (scroll_size.y - min_size.y);
		bar_height := ceil(aspect_ratio * size.y);

		if state == .PRESSED || state == .HOLD || state == .HOLD_NON_HOVER {
			scroll_pos.*.y = (cast(f32, mouse_y) - pos.y - bar_height / 2) / aspect_ratio;
		}

		bar_col := ifx state == .NORMAL then settings.themes.platform_widget_border_normal else settings.themes.platform_widget_bg_press;

		val := round_up(scroll_pos.y, FONT_SIZE_NORMAL);
		scroll_pos.*.y = clamp(val, 0, scroll_size.y - size.y - min_size.y);
		
		scrollbar_pos := Vec2.{scroll_pos_x, scroll_pos_y + aspect_ratio * scroll_pos.*.y};
		scrollbar_pos.y = round_down(scrollbar_pos.y);

		draw_rect(.{scroll_pos_x, scroll_pos_y}, .{WIDGET_SCROLLBAR_SIZE, size.y}, settings.themes.platform_widget_bg_normal);
		draw_rect(scrollbar_pos, .{WIDGET_SCROLLBAR_SIZE, bar_height}, bar_col);
	}

	if x_visible {
		true_size.y -= WIDGET_SCROLLBAR_SIZE;

		scroll_pos_x := pos.x;
		scroll_pos_y := pos.y + size.y - WIDGET_SCROLLBAR_SIZE;
		off := ifx y_visible then cast(f32)WIDGET_SCROLLBAR_SIZE;

		state := create_selectable_region(.SCROLLBAR, .{scroll_pos_x, scroll_pos_y}, .{size.x - off, WIDGET_SCROLLBAR_SIZE}, loc, it + 2);

		if mouse_dz && is_key_down(KEY_SHIFT) && content_state == .HOVER {
			true_speed := ifx is_key_down(KEY_CTRL) then speed_fast else speed_slow;
			amt := mouse_dz * FONT_SIZE_NORMAL * true_speed;
			scroll_pos.*.x -= amt;
		}

		aspect_ratio := (size.x - off) / (scroll_size.x - min_size.x);
		bar_width := ceil(aspect_ratio * size.x);

		if state == .PRESSED || state == .HOLD || state == .HOLD_NON_HOVER {
			scroll_pos.*.x = (cast(f32, mouse_x) - pos.x - bar_width / 2) / aspect_ratio;
		}

		bar_col := ifx state == .NORMAL then settings.themes.platform_widget_border_normal else settings.themes.platform_widget_bg_press;

		val := round_up(scroll_pos.x, FONT_SIZE_NORMAL);
		scroll_pos.*.x = clamp(val, 0, scroll_size.x - size.x - min_size.x);

		draw_rect(.{scroll_pos_x, scroll_pos_y}, .{size.x, WIDGET_SCROLLBAR_SIZE}, settings.themes.platform_widget_bg_normal);
		draw_rect(.{scroll_pos_x + aspect_ratio * scroll_pos.*.x, scroll_pos_y}, .{bar_width, WIDGET_SCROLLBAR_SIZE}, bar_col);
	}

	return true_size;
}

tab_bar :: (pos: Vec2, width: f32, focused_tab: *$T, it_: s64 = 0, loc := #caller_location) #modify {
	v := cast(*Type_Info, T);
	return v.type == .ENUM, "tab type should be of type enum";
} {
	draw_selected_rect :: (pos: Vec2, size: Vec2) {
		draw_rect(pos, .{1, size.y}, settings.themes.platform_line);
		draw_rect(pos, .{size.x, 1}, settings.themes.platform_line);
		draw_rect(pos + .{size.x, 0}, .{1, size.y}, settings.themes.platform_line);
	}

	tab_height :: 24;

	tabs :: #run -> []string {
		n := cast(*Type_Info_Enum, T).names;
		for s, idx_s: n for s if it == #char "_" n[idx_s][it_index] = #char " ";
		return n;
	}

	focus := cast(s64, focused_tab.*);

	x: f32;
	for tabs {
		d := measure_text(it, FONT_SIZE_NORMAL);
		state := create_selectable_region(.TAB, pos + .{4 + x, 0}, .{d.x + 8, tab_height}, loc, it_ + it_index);

		if state == .RELEASE then focused_tab.* = cast(T, it_index);

		x += d.x + FONT_SIZE_NORMAL;
	}

	x = 0;
	w: f32 = 4;
	w_continue: f32;
	for tabs {
		d := measure_text(it, FONT_SIZE_NORMAL);

		text_col: Col = ---;
		if it_index == focus {
			text_col = settings.themes.platform_text_normal;
			draw_selected_rect(pos + .{4 + x, 0}, .{d.x + 8, tab_height});
			draw_rect(pos + .{0, tab_height - 1}, .{w, 1}, settings.themes.platform_line);
			w_continue = w + d.x + 8;
		} else {
			text_col = settings.themes.platform_disabled;
			draw_selected_rect(.{4 + pos.x + x, pos.y}, .{d.x + 8, tab_height});
			w += d.x + FONT_SIZE_NORMAL;
		}

		draw_text(it, .{8 + pos.x + x, pos.y + 4}, FONT_SIZE_NORMAL, text_col);

		x += d.x + FONT_SIZE_NORMAL;
	}

	draw_rect(pos + .{w_continue, tab_height - 1}, .{width - w_continue, 1}, settings.themes.platform_line);
}

h_separator :: ($name: string, pos: Vec2, width: f32) {
	#if name {
		p :: 12;
		draw_rect(pos, .{p, 1}, settings.themes.platform_line);

		draw_text(name, pos + .{p + 4, -5}, FONT_SIZE_SMALL, settings.themes.platform_text_normal);
		s :: #run measure_text(name, FONT_SIZE_SMALL);

		draw_rect(pos + .{p + 8 + s.x, 0}, .{width - p - 8 - s.x, 1}, settings.themes.platform_line);
	} else {
		draw_rect(pos, .{width, 1}, settings.themes.platform_line);
	}
}

combo_box :: (pos: Vec2, size: Vec2, sel: *$T, it_: s64 = 0, loc := #caller_location) -> bool #modify {
	v := cast(*Type_Info, T);
	return v.type == .ENUM;
} {
	selected := cast(s64)sel.*;

	items :: #run -> []string {
		n := cast(*Type_Info_Enum, T).names;
		for s, idx_s: n for s if it == #char "_" n[idx_s][it_index] = #char " ";
		return n;
	}

	uuid   := hash_widget(loc, it_);
	state  := create_selectable_region(.COMBO, pos, size, uuid);
	widget := *find_or_add(*widgets, uuid).combo_box;

	border_col: Col = ---;
	text_col:   Col = ---;

	if state == {
		case .RELEASE_NON_HOVER; #through;
		case .NORMAL;
			border_col = settings.themes.platform_widget_border_normal;
			text_col   = settings.themes.platform_text_normal;
		case .PRESSED; #through;
		case .HOLD;
			border_col = settings.themes.platform_widget_border_press;
			text_col   = settings.themes.platform_text_press;
		case .RELEASE; #through;
		case .HOVER; #through;
		case .HOLD_NON_HOVER;
			border_col = settings.themes.platform_widget_border_hover;
			text_col   = settings.themes.platform_text_hover;
	}

	draw_rect_lines(pos, size, border_col);
	draw_text( items[selected], pos + .{3, 1}, FONT_SIZE_NORMAL, text_col);

	if state == .RELEASE then widget.*.open = !widget.*.open;

	h :: items.count * 20.0;

	if is_mouse_pressed(0) && !is_mouse_inside_rect(pos, .{size.x, h + 20.0}) then widget.*.open = false;
	if is_key_pressed(KEY_ESC) then widget.*.open = false;

	fire_internal := false;

	if state == .HOVER && mouse_dz {
		selected = clamp(selected - mouse_dz, 0, items.count - 1);
		fire_internal = true;
	}

	if widget.open {
		occlusion.pos = pos;
		occlusion.size = .{size.x, h + 20.0};
		occlusion.type = .COMBO;
		
		draw_icon(.ARROW_DOWN, pos + .{size.x - 18, 2}, FONT_SIZE_NORMAL, text_col);
		draw_rect_lines(pos + .{size.x - 20, 0}, .{20, 20}, border_col);

		draw_rect(pos + .{0, 20}, .{size.x, h}, settings.themes.platform_widget_bg_normal);
		
		for items {
			state_internal := create_selectable_region(.COMBO, pos + .{0, 20.0 * (it_index + 1)}, .{size.x, 20.0}, loc, it_ + it_index + 1);
			single_selected := state_internal == .RELEASE;

			border_col: Col = ---;
			text_col:   Col = ---;

			if state_internal == {
				case .RELEASE_NON_HOVER; #through;
				case .NORMAL;
					border_col = settings.themes.platform_widget_border_normal;
					text_col   = settings.themes.platform_text_normal;
				case .PRESSED; #through;
				case .RELEASE; #through;
				case .HOLD;
					border_col = settings.themes.platform_widget_border_press;
					text_col   = settings.themes.platform_text_press;
				case .HOVER; #through;
				case .HOLD_NON_HOVER;
					border_col = settings.themes.platform_widget_border_hover;
					text_col   = settings.themes.platform_text_hover;
			}

			rel_x := pos.x;
			rel_y := pos.y + 20.0 * (it_index + 1);

			draw_rect_lines(.{rel_x, rel_y}, .{size.x, 20.0}, border_col);
			draw_text(it, .{rel_x + 2, rel_y + 1}, FONT_SIZE_NORMAL, text_col);

			if single_selected {
				selected = it_index;
				widget.*.open = false;
				occlusion.type = .NONE;
				fire_internal = true;
			}
		}
	} else {
		draw_icon(.ARROW_LEFT, pos + .{size.x - 18, 2}, FONT_SIZE_NORMAL, text_col);
		draw_rect_lines(pos + .{size.x - 20, 0}, .{20, 20}, border_col);
	}
	
	sel.* = cast(T, selected);

	return fire_internal;
}

input_int :: (pos: Vec2, $s: f32, value: *$T, $$min_value: T, $$max_value: T, it: s64 = 0, $draw_border_when_focused := false, $update_on_change := false, loc := #caller_location) -> bool #modify {
	info := cast(*Type_Info, T);
	return info.type == .INTEGER;
	} {

	digits :: #run count_digits(max_value);
	size   :: #run Vec2.{digits * s + 8.0, s + 4.0};

	uuid := hash_widget(loc, it);
	state := create_selectable_region(.INPUT, pos, size, uuid);
	widget := *find_or_add(*widgets, uuid).input_int;

	unfocused := false;
	if is_mouse_pressed(0) || is_key_pressed(KEY_ESC) || is_key_pressed(KEY_ENTER) {
		if state == .PRESSED then widget.selected = true;
		else if widget.selected {
			widget.selected = false;
			unfocused = true;
		}
	}
	
	border_col: Col = ---;
	text_col:   Col = ---;

	if state == {
		case .RELEASE_NON_HOVER; #through;
		case .NORMAL;
			border_col = settings.themes.platform_widget_border_normal;
			text_col   = settings.themes.platform_text_normal;
		case .PRESSED; #through;
		case .HOLD;
			border_col = settings.themes.platform_widget_border_press;
			text_col   = settings.themes.platform_text_press;
		case .RELEASE; #through;
		case .HOVER; #through;
		case .HOLD_NON_HOVER;
			border_col = settings.themes.platform_widget_border_hover;
			text_col   = settings.themes.platform_text_hover;
	}

	// at the moment it doesn't handle negative values
	if widget.selected {
		if is_mouse_up(0) {
			border_col = settings.themes.platform_widget_border_hover;
			text_col = settings.themes.platform_text_hover;
		}
		
		if is_digit(pressed_char) {
			v := pressed_char - #char "0";
			new_value := value.* * 10 + v;

			value.* = min(new_value, max_value);
			widget.edited = true;
		}
		if is_key_pressed_or_repeated(KEY_DELETE) {
			value.* /= 10;
			widget.edited = true;
		}
	} else {
		if value.* < min_value {
			value.* = min_value;
			widget.edited = true;
		}
	}
	
	#if draw_border_when_focused {
		if widget.selected {
			draw_rect_lines(pos + .{0, -1}, size, border_col);
		}
	} else {
		draw_rect_lines(pos + .{0, -1}, size, border_col);
	}

	fmt :: #bake_arguments formatInt(minimum_digits = digits, padding = #char " ");
	draw_text(tprint("%", fmt(value.*)), pos + .{4, 0}, s, text_col);

	if unfocused {
		value.* = clamp(value.*, min_value, max_value);
		defer widget.edited = false;
		return widget.edited;
	}
	
	#if update_on_change {
		if widget.edited {
			defer widget.edited = false;
			return widget.edited;
		}
	}
	
	return false;
}

color_picker :: (pos: Vec2, rgb: *Col, external_update: bool, it: s64 = 0, loc := #caller_location) -> bool {
	// the external_update is kind of sloppy, though it's used to compensate
	// other problems, like drifting

	s :: 160.0;

	uuid := hash_widget(loc, it);
	state_quad := create_selectable_region(.COLOR_PICKER, pos + .{8,      8}, .{s,  s}, uuid);
	state_bar  := create_selectable_region(.COLOR_PICKER, pos + .{s + 12, 8}, .{20, s}, loc, it + 1);

	widget := *find_or_add(*widgets, uuid).color_picker;

	draw_panel("picker", pos, .{200, 220});

	edited := false;
	visual_update := false;

	if rgb != widget.stored_pointer || external_update {
		widget.hsv = RGB_to_HSV(rgb.*);
		widget.stored_pointer = rgb;
		visual_update = true;
	}

	steps  :: 16;  // quads amount of the grid (steps * steps)
	vsteps :: 40;  // quads amount on the right panel

	quad_size :: s /  steps;
	grid_dist :: s / (steps - 1);

	rect_height :: s /  vsteps;
	rect_steps  :: s / (vsteps - 1);

	if state_quad == .HOLD || state_quad == .HOLD_NON_HOVER {
		mouse := Vec2.{cast(f32, mouse_x) - pos.x, cast(f32, mouse_y) - pos.y};

		// snapping on the grid
		x := cast(s32, (mouse.x - 8) / quad_size);
		mouse.x = cast(f32, x) * grid_dist;

		y := cast(s32, (mouse.y - 8) / quad_size);
		mouse.y = cast(f32, y) * grid_dist;

		sat :=     mouse.x / s;
		val := 1 - mouse.y / s;

		sat = clamp(sat, 0, 1);
		val = clamp(val, 0, 1);

		widget.*.hsv.y = sat;
		widget.*.hsv.z = val;

		edited = true;
	} else if state_bar == .HOLD || state_bar == .HOLD_NON_HOVER {
		y := cast(f32, mouse_y) - pos.y;

		v := cast(s32, (y - 8) / rect_height);
		y = cast(f32, v) * rect_steps;

		hue := y / s;
		hue  = clamp(hue, 0, 1);

		widget.*.hsv.x = hue;

		edited = true;
	}
	
	if edited {
		rgb.* = HSV_to_RGB(widget.hsv);
		visual_update = true;
	}

	{  // numbers
		text_pos :: Vec2.{13, 162};
		fmt :: #bake_arguments formatInt(minimum_digits = 3, padding = #char " ");

		draw_text("R:", pos + text_pos + .{  0, 20}, FONT_SIZE_SMALL, settings.themes.platform_text_normal);
		draw_text("G:", pos + text_pos + .{ 62, 20}, FONT_SIZE_SMALL, settings.themes.platform_text_normal);
		draw_text("B:", pos + text_pos + .{124, 20}, FONT_SIZE_SMALL, settings.themes.platform_text_normal);
		draw_text("H:", pos + text_pos + .{  0, 36}, FONT_SIZE_SMALL, settings.themes.platform_text_normal);
		draw_text("S:", pos + text_pos + .{ 62, 36}, FONT_SIZE_SMALL, settings.themes.platform_text_normal);
		draw_text("V:", pos + text_pos + .{124, 36}, FONT_SIZE_SMALL, settings.themes.platform_text_normal);
		
		// using `rgb_edited` to edit the internal hsv value
		rgb_edited := false;
		rgb_edited |= input_int(pos + text_pos + .{ 24, 20}, FONT_SIZE_SMALL, *widget.stored_pointer.r, 0, 255, uuid, draw_border_when_focused = true, update_on_change = true);
		rgb_edited |= input_int(pos + text_pos + .{ 86, 20}, FONT_SIZE_SMALL, *widget.stored_pointer.g, 0, 255, uuid, draw_border_when_focused = true, update_on_change = true);
		rgb_edited |= input_int(pos + text_pos + .{148, 20}, FONT_SIZE_SMALL, *widget.stored_pointer.b, 0, 255, uuid, draw_border_when_focused = true, update_on_change = true);

		h := cast(s64, round_ignoring_negative(widget.hsv.x * 360));
		s := cast(s64, round_ignoring_negative(widget.hsv.y * 100));
		v := cast(s64, round_ignoring_negative(widget.hsv.z * 100));
		
		hsv_edited := false;
		hsv_edited |= input_int(pos + text_pos + .{ 24, 36}, FONT_SIZE_SMALL, *h, 0, 360, uuid, draw_border_when_focused = true, update_on_change = true);
		hsv_edited |= input_int(pos + text_pos + .{ 86, 36}, FONT_SIZE_SMALL, *s, 0, 100, uuid, draw_border_when_focused = true, update_on_change = true);
		hsv_edited |= input_int(pos + text_pos + .{148, 36}, FONT_SIZE_SMALL, *v, 0, 100, uuid, draw_border_when_focused = true, update_on_change = true);
		widget.hsv.x = h / 360.0;
		widget.hsv.y = s / 100.0;
		widget.hsv.z = v / 100.0;

		if rgb_edited {
			visual_update = true;
			widget.hsv = RGB_to_HSV(widget.stored_pointer);
			edited = true;
		}
		if hsv_edited {
			visual_update = true;
			widget.stored_pointer.* = HSV_to_RGB(widget.hsv);
			edited = true;
		}
	}

	{  // content drawing
		size :: s / steps;

		if visual_update {
			t := widget.hsv.x;

			k :: Vec4.{1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0};
			p := abs(frac(Vec3.{t + k.x, t + k.y, t + k.z}) * 6.0 - Vec3.{k.w, k.w, k.w});
			p2 := clamp(p - Vec3.{k.x, k.x, k.x}, 0.0, 1.0);

			widget.gradient = p2;
		}

		// steps - 2 for the y because the last line is full black
		for y: 0 .. (steps - 2) {
			uvy := 1 - (cast(f32, y)) / (steps - 1);

			for x: 0 .. (steps - 1) {
				uvx := (cast(f32, x)) / (steps - 1);

				res := uvy * lerp(.{1.0, 1.0, 1.0}, widget.gradient, uvx) * 255;
				c := Col.{cast,trunc(u8, res.x), cast,trunc(u8, res.y), cast,trunc(u8, res.z), 255};

				pos2 := pos + .{8, 8} + .{x * size, y * size};
				draw_rect(pos2, .{size, size}, c);
			}
		}
		draw_rect(pos + .{8, 8} + .{0, (steps - 1) * size}, .{steps * size, size}, .{0, 0, 0, 255});
		
		for 0 .. (vsteps - 1) {
			pos2 := pos + .{s + 12, s * it / vsteps + 8};
			size2 := Vec2.{20, round_down(s / vsteps + 1)};

			x := cast(f32, it) / (vsteps - 1);
			draw_rect(pos2, size2, HSV_to_RGB(.{x, 1, 1}));
		}
	}

	draw_rect_lines(pos + .{7, 7}, .{s + 2, s + 2}, settings.themes.platform_line);
	draw_rect_lines(pos + .{s + 12, 7}, .{20, s + 2}, settings.themes.platform_line);

	cursor := Vec2.{(s - s / steps) * widget.hsv.y, (s - s / steps) * (1 - widget.hsv.z)} + .{8, 8};
	cursor.x = cast(f32, cast(s32, cursor.x / quad_size) * quad_size);
	cursor.y = cast(f32, cast(s32, cursor.y / quad_size) * quad_size);
	cursor += .{8, 8} + .{(s / steps) / 2, (s / steps) / 2};
	draw_rect_lines(pos + cursor - .{4, 4}, .{8, 8}, settings.themes.platform_line);

	cursor = .{s + 12, 8 + (s - s / vsteps) * widget.hsv.x};
	cursor.y = cast(f32, cast(s32, cursor.y / rect_height) * rect_height);
	cursor.y += 1;

	rgb2 := HSV_to_RGB(.{widget.hsv.x, 1, 1});
	draw_rect(pos + cursor - .{2, 1}, .{24, 4}, rgb2);
	draw_rect_lines(pos + cursor - .{2, 2}, .{24, 6}, settings.themes.platform_line);

	return edited;
}

draw_panel :: ($$text: string, pos: Vec2, size: Vec2) {
	p :: 4;

	s :: FONT_SIZE_SMALL;
	m: Vec2 = ---;
	m = measure_text(text, s);

	if text.count != 0 {
		draw_rect(pos, .{p, 1}, settings.themes.platform_line);
		draw_rect(pos + .{p + 8 + m.x, 0}, .{size.x - p - 8 - m.x, 1}, settings.themes.platform_line);
	} else {
		draw_rect(pos, .{size.x, 1}, settings.themes.platform_line);
	}

	draw_rect(pos, .{1, size.y}, settings.themes.platform_line);
	draw_rect(pos + .{0, size.y - 1}, .{size.x, 1}, settings.themes.platform_line);
	draw_rect(pos + .{size.x - 1, 0}, .{1, size.y}, settings.themes.platform_line);

	draw_text(text, pos + .{p + 4, -m.y / 2}, s, settings.themes.platform_line);
}

window :: (p: *Window) -> want_a_rise: bool {
	draw_rect(p.pos, p.size, settings.themes.platform_widget_bg_normal);
	draw_rect_lines(p.pos, p.size, settings.themes.platform_widget_border_normal);
	if p.name then draw_text(p.name, p.pos + .{9, 8}, FONT_SIZE_SMALL, settings.themes.platform_text_normal);

	array_add(*stack, p.pos + .{0, WIDGET_HEADER_HEIGHT});

	current_panel_uuid = p.uuid;

	fire := button(.CLOSE, p.pos + .{p.size.x - WIDGET_HEADER_HEIGHT, 0}, .{WIDGET_HEADER_HEIGHT, WIDGET_HEADER_HEIGHT}, it = p.uuid);
	draw_rect(p.pos + .{0, WIDGET_HEADER_HEIGHT - 1}, .{p.size.x, 1}, settings.themes.platform_widget_border_normal);

	if fire {
		toggle_window(p);
		if p.on_close then p.on_close();
	}

	if p.draw_func then p.draw_func(p);

	current_panel_uuid = 0;
	stack.count      -= 1;

	// after drawing the inside, handle the movement
	state := create_selectable_region(.WINDOW, p.pos, p.size, p.uuid);

	want_a_rise := false;

	// if it's modal, you cannot move it
	if state == {
		case .PRESSED;
			p.pressed = true;
			p.pressed_pos.x = mouse_x - p.pos.x;
			p.pressed_pos.y = mouse_y - p.pos.y;
			want_a_rise = true;
		case .RELEASE_NON_HOVER; #through;
		case .RELEASE;
			p.pressed = false;
	}
	
	if p.pressed {
		delta := Vec2.{cast(f32, mouse_x), cast(f32, mouse_y)} - p.pressed_pos;
		p.pos = delta;
	}

	p.pos.x = clamp(p.pos.x, -p.size.x + 40, cast(f32, vp.width - 40));
	p.pos.y = clamp(p.pos.y, HEADER_HEIGHT,  cast(f32, vp.height - WIDGET_HEADER_HEIGHT));

	return want_a_rise;
}

create_new_window :: (draw: (*Window) -> (), name: string, size: Vec2, on_close: () -> () = null, it: s64 = 0, loc := #caller_location) -> *Window {
	uuid := hash_widget(loc, it);

	#if DEBUG {
		for windows_order {
			if it.uuid == uuid assert(false, "Found a window with the same uuid");
		}
	}

	p := New(Window, initialized = false);

	p.*.size      = size;
	p.*.draw_func = draw;
	p.*.visible   = false;
	p.*.name      = name;
	p.*.on_close  = on_close;
	p.*.uuid      = uuid;

	array_add(*windows_order, p);

	return p;
}

draw_windows :: () {
	// drawing windows
	idx := -1;
	for < windows_order {
		if !it.visible then continue;

		rise := window(it);
		if rise then idx = it_index;
	}

	if idx != -1 then make_window_topmost_by_index(idx);
	
	Swap(*occlusion, *prev_occlusion);
	occlusion.type = .NONE;
}

init_widgets :: () {
	init(*widgets);
}

deinit_widgets :: () {
	deinit(*widgets);
}

make_window_topmost_by_index :: (idx: s64) {
	panel := windows_order[idx];

	// remove ordered
	for #v2 < i: 1 .. idx { windows_order[i] = windows_order[i - 1]; }

	windows_order[0] = panel;
}

make_window_topmost_by_value :: inline (p: *Window) {
	idx := -1;
	for windows_order if it == p then idx = it_index;
	#if DEBUG then assert(idx != -1);

	make_window_topmost_by_index(idx);
}

toggle_window :: (panel: *Window, $centered := false) {
	if panel.*.visible {
		panel.*.visible = false;
		panel.*.pressed = false;
	} else {
		panel.*.visible = true;
		make_window_topmost_by_value(panel);
	}

	#if centered {
		x := (vp.width  - panel.size.x) / 2;
		y := (vp.height - panel.size.y) / 2;
		panel.*.pos = .{x, y};
	}
}

mouse_inside_a_window :: () -> bool {
	for windows_order {
		if !it.visible then continue;
		
		if is_mouse_inside_rect(it.pos, it.size) {
			return true;
		}
	}
	
	return false;
}

fetch_parent :: inline () -> Vec2 {
	if stack.count then return stack[stack.count - 1]; else return .{0, 0};
}

create_selectable_region :: inline (type: Widget_Type, pos: Vec2, size: Vec2, loc := #caller_location, it: s64 = 0, $disable_interactions := false) -> Interaction_State {
	uuid := hash_widget(loc, it);
	return create_selectable_region(type, pos, size, uuid, disable_interactions);
}

create_selectable_region :: (type: Widget_Type, pos: Vec2, size: Vec2, uuid: ID, $disable_interactions := false) -> Interaction_State {
	// handling of the focused ID
	if focused_uuid == uuid {
		if is_mouse_inside_rect(pos, size) {
			if is_mouse_released(0) {
				focused_uuid = 0;
				return .RELEASE;
			}
			return .HOLD;
		} else {
			if is_mouse_released(0) {
				focused_uuid = 0;
				return .RELEASE_NON_HOVER;
			}
			return .HOLD_NON_HOVER;
		}
	}

	if focused_uuid != 0 then return .NORMAL;

	state := Interaction_State.NORMAL;

	for windows_order {
		if !it.visible then continue;
		if it.uuid == uuid || it.uuid == current_panel_uuid then break;

		if is_mouse_inside_rect(it.pos, it.size) {
			return state;
		}
	}
	
	if prev_occlusion.type != .NONE && prev_occlusion.type != type && is_mouse_inside_rect(prev_occlusion.pos, prev_occlusion.size) then return state;

	if is_mouse_inside_rect(pos, size) {
		state = .HOVER;
	}

	if state == .HOVER && is_mouse_pressed(0) {
		state = .PRESSED;
		#if !disable_interactions then focused_uuid = uuid;
	}

	return state;
}

#scope_file
hash_widget :: (loc: Source_Code_Location, it: s64) -> ID {
	h1 := fnv1a_hash(loc.fully_pathed_filename.data, loc.fully_pathed_filename.count);
	h2 := knuth_hash(cast,no_check(u64)loc.line_number);
	h3 := knuth_hash(cast,no_check(u64)it);

	out := cast,no_check(ID)(h1 ^ h2 ^ h3);

	// With this widgets architecture, an ID of zero means that the user hasn't any focused widget.
	// If for some reasons we're hashing a widget and we get zero, we should rethink the hashing algoritm.
	#if DEBUG then assert(out != 0);

	return out;
}

Widget_Type :: enum u32 {
	NONE;
	BUTTON;
	CHECKBOX;
	SLIDER;
	SCROLLBAR;
	TAB;
	SEPARATOR;
	COMBO;
	COLOR_PICKER;
	TEXT;
	INPUT;
	WINDOW;
}

Widget_Color_Picker :: struct {
	hsv: Vec3;
	gradient: Vec3;
	stored_pointer: *Col;
	
	red_focused := false;
	red_value: u8;
}

Widget_Combo_Box :: struct {
	open: bool;
}

Widget_Input_Int :: struct {
	selected: bool;
	edited: bool;
}

Widget :: struct {
	type: Widget_Type;
	uuid: ID;

	pos: Vec2;
	size: Vec2;

	union {
		color_picker: Widget_Color_Picker;
		combo_box:    Widget_Combo_Box;
		input_int:    Widget_Input_Int;
	}
}

Occlusion_Area :: struct {
	pos:  Vec2;
	size: Vec2;
	type: Widget_Type;
}

widgets: Table(ID, Widget);

stack:           [..]  Vec2;
windows_order:   [..] *Window;

// Note that this should be a stack, but since we just need one occlusion, it's just an item
occlusion: Occlusion_Area;
prev_occlusion: Occlusion_Area;

occluder_area: *Widget;

current_panel_uuid: ID;

#scope_export

Interaction_State :: enum {
	NORMAL;
	HOVER;
	PRESSED;
	HOLD;
	HOLD_NON_HOVER;
	RELEASE;
	RELEASE_NON_HOVER;
}

Window :: struct {
	pos: Vec2;
	size: Vec2;
	z: f32;
	uuid: ID;

	pressed_pos: Vec2;
	pressed: bool;

	visible: bool;
	name: string;

	draw_func: (*Window) -> ();
	on_close:  () -> ();
}

ID :: #type u32;

WIDGET_HEADER_HEIGHT  :: 24;
WIDGET_SCROLLBAR_SIZE :: 12;

focused_uuid: ID;
