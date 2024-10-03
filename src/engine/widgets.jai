Interaction_State :: enum {
	NORMAL;
	HOVER;
	PRESSED;
}

scrollbar_interaction :: (pos: Vec2, size: Vec2, layer: f32) -> Interaction_State {
	state := Interaction_State.NORMAL;
	widget_uuid += 1;
	
	if is_mouse_inside_rect(pos, size) && can_interact_with_widget(layer) {
		if is_mouse_pressed(0) then widget_selected = widget_uuid;
		
		state = .HOVER;
		if widget_selected == 0 then return state;
		if widget_selected != widget_uuid then return .NORMAL;
	}
	
	if widget_selected == widget_uuid {
		return .PRESSED;
	}
	return state;
}

button_interaction :: (pos: Vec2, size: Vec2, id: u32, layer: f32) -> (bool, Interaction_State) {
	state := Interaction_State.NORMAL;
	
	if is_mouse_inside_rect(pos, size) && can_interact_with_widget(layer) {
		if is_mouse_pressed(0) then widget_selected = id;
		
		state = .HOVER;
		if widget_selected == 0  then return false, state;
		if widget_selected != id then return false, .NORMAL;
	}

	released := is_mouse_released(0);
	fire := false;
	if state == .HOVER {
		
		if is_mouse_down(0) || released {
			state = .PRESSED;
			fire = released;
		}
	}

	return fire, state;
}

button_internal :: (pos: Vec2, size: Vec2, layer: f32, $t: f32, id: u32) -> (bool, Col) {
	fire, state := button_interaction(pos, size, id, layer);

	bg_col: Col;
	border_col: Col;
	text_col: Col;
	if state == {
		case .NORMAL;
			bg_col = COLOR_WIDGET_BG;
			border_col = COLOR_WIDGET_BORDER;
			text_col = COLOR_TEXT_NORMAL;
		case .HOVER;
			bg_col = COLOR_WIDGET_BG_HOVERED;
			border_col = COLOR_WIDGET_BORDER_HOVERED;
			text_col = COLOR_TEXT_HOVERED;
		case .PRESSED;
			bg_col = COLOR_WIDGET_BG_PRESSED;
			border_col = COLOR_WIDGET_BORDER_PRESSED;
			text_col = COLOR_TEXT_PRESSED;
	}

	draw_rect(pos, size, layer, bg_col);
	draw_rect_lines(pos, size, layer + 1, border_col, 2);

	return fire, text_col;
}

button :: ($$text: string, pos: Vec2, size: Vec2, layer: f32, $t: f32) -> bool {
	widget_uuid += 1;
	fire, text_col := button_internal(pos, size, layer, t, widget_uuid);
	
	s := measure_text(text, t);
	draw_text(text, pos + size / 2 - s / 2, layer + 1, t, text_col);
	
	return fire;
}

button :: (icon: Icon, pos: Vec2, size: Vec2, layer: f32, $t: f32) -> bool {
	widget_uuid += 1;
	fire, icon_col := button_internal(pos, size, layer, t, widget_uuid);
	
	s :: Vec2.{8.0 * t, 8.0 * t};
	
	draw_icon(icon, pos + size / 2 - s / 2, layer + 1, t, icon_col);
	return fire;
}

checkbox :: (value: *bool, $$text: string, pos: Vec2, size: Vec2, layer: f32) {
	widget_uuid += 1;
	s := measure_text(text, 1);
	
	fire, state := button_interaction(pos, size + .{s.x + 12, 0}, widget_uuid, layer);

	bg_col: Col;
	text_col: Col;
	if state == {
		case .NORMAL;
			bg_col = COLOR_WIDGET_BG_HOVERED;
			text_col = COLOR_TEXT_NORMAL;
		case .HOVER;
			bg_col = COLOR_WIDGET_BG_HOVERED;
			text_col = COLOR_TEXT_HOVERED;
		case .PRESSED;
			bg_col = COLOR_WIDGET_BG_PRESSED;
			text_col = COLOR_TEXT_PRESSED;
	}
	
	if value.* || state == .PRESSED then draw_rect(pos + .{4, 4}, size - .{8, 8}, layer, bg_col);
	draw_rect_lines(pos, size, layer + 1, COLOR_LINE);
	draw_text(text, pos + .{size.x + 8, (size.y - s.y) / 2}, layer, 1, text_col);
	
	if fire then value.* = !value.*;
}

draw_step_hslider :: (pos: Vec2, size: Vec2, layer: f32, amt: s32, value: *int, disabled: bool = false) {
	widget_uuid += 1;
	draw_rect(.{pos.x, pos.y + size.y / 2 - 1}, .{size.x, 2}, layer, ifx disabled then GRAY else COLOR_LINE);
	
	col_main: Col = ---;
	col_step: Col = ---;
	
	if !disabled {
		col_main = COLOR_WIDGET_BG;
		col_step = COLOR_WIDGET_BORDER;
		if is_mouse_inside_rect(.{pos.x - 4, pos.y}, .{size.x + 8, size.y}) && can_interact_with_widget(layer) {
			if widget_selected == 0 then col_main = COLOR_WIDGET_BG_HOVERED;
			if is_mouse_pressed(0) then widget_selected = widget_uuid;
		}
		
		if widget_selected == widget_uuid {
			value.* = xx clamp((cast(f32)mouse_x - pos.x) / (size.x) * amt, 0, xx (amt - 1));
			col_main = COLOR_WIDGET_BG_PRESSED;
		}
	} else {
		col_main = GRAY;
		col_step = GRAY;
	}
	
	for 0..amt / 3 {
		x := cast(f32)(it * 3) / (amt - 1) * size.x;
		s := size.y / 2;
		if it % 3 == 0 then s = size.y / 3 * 2;
		
		draw_rect(.{pos.x + x - 1, pos.y + size.y / 2 - s / 2}, .{2, s}, layer + 1, col_step);
	}
	
	pos_x := pos.x + cast(f32)value.* / (amt - 1) * size.x;
	draw_rect(.{pos_x - 4, pos.y}, .{8, size.y}, layer + 2, col_main);
}

draw_window :: (pos: Vec2, size: Vec2, layer: f32, $$name: string) {
	draw_rect(pos, size, layer, COLOR_WIDGET_BG);
	draw_rect_lines(pos, size, layer + 1, COLOR_WIDGET_BORDER);
	
	draw_rect_lines(pos, .{size.x, 24}, layer + 1, COLOR_WIDGET_BORDER);
	
	draw_text(name, pos + .{9, 8}, layer + 1, 1, COLOR_WIDGET_BORDER);
}

draw_popup :: ($width: f32, $height: f32) {
	x := (vp.width - width) / 2;
	y := (vp.height - height) / 2;

	draw_window(.{x, y}, .{width, height}, 10, ui.popup_title);
	
	if ui.popup_error_type == {
		case .FAILED_COMPILATION;
			draw_text(ui.error_message, .{x + 10, y + 40}, 11, 2, WHITE, wrap = width - 20);
		case .UNABLE_TO_OPEN_BINARY;
			draw_text("Unable to open binary file <out.bin> for reading", .{x + 10, y + 40}, 11, 2, WHITE);
		case .INCOMPATIBLE_ROM_SIZE;
			draw_text("Incompatible ROM size", .{x + 10, y + 40}, 11, 2, WHITE);
			draw_text("ROM size must to be 32kB", .{x + 10, y + 56}, 11, 2, WHITE);
		case .ERROR_OPENING_FILE;
			draw_text("An error has occured while opening the file", .{x + 10, y + 40}, 11, 2, WHITE);
		case .READING_FILE_TIMED_OUT;
			draw_text("Reading file timed out", .{x + 10, y + 40}, 11, 2, WHITE);
		case .NO_INPUT_FILE_GIVEN;
			draw_text("No input file given", .{x + 10, y + 40}, 11, 2, WHITE);
		case .GIVEN_FILE_NOT_VALID;
			draw_text("Unsupported given file", .{x + 10, y + 40}, 11, 2, WHITE);
			draw_text("File must to have the '.s' extension", .{x + 10, y + 56}, 11, 2, WHITE);
		case .UNABLE_TO_FIND_COMPILER;
			draw_text("Unable to find 'vasm6502_oldstyle.exe', aborting", .{x + 10, y + 40}, 11, 2, WHITE);
	}
	
	w :: 90;
	h :: 24;
	if button("Continue", .{x + width - w - 10, y + height - h - 10}, .{w, h}, 11, 1) || is_key_pressed(KEY_ESC) {
		ui.show_popup = false;
		if ui.popup_error_type == .FAILED_COMPILATION then free(ui.error_message);
	}
}

finalize_widgets :: () {
	widget_uuid = 0;
	if is_mouse_released(0) then widget_selected = 0;
	
	target_fade := ifx ui.show_popup 0.75 else 0;
	T :: 0.35;  // seconds took from 0 to target_fade (I didn't solve the equation, but it's a nice approx, maybe it's good)
	k := 1 / (T * vp.dt * 1000);
	
	fade_value = lerp(fade_value, target_fade, k);
	draw_rect(.{0, 0}, .{xx vp.width, xx vp.height}, 9, .{0, 0, 0, fade_value});
}

handle_widget_layering :: () {
	if ui.show_popup { focused_layer = 10; return; }
	if ui.display_visible { focused_layer = 4; return; }
	focused_layer = 0;
}

can_interact_with_widget :: (layer: f32) -> bool {
	if ui.show_popup {
		return focused_layer <= layer;
	}
	return (!mouse_over_panel);
}

widget_uuid: u32;
widget_selected: u32;
mouse_over_panel: bool;

fade_value: f32;
focused_layer: f32;
