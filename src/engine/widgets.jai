Interaction_State :: enum {
	NORMAL;
	HOVER;
	PRESSED;
}

WIDGET_HEADER_HEIGHT :: 24;
WIDGET_SCROLLBAR_SIZE :: 12;

generate_new_uuid :: () -> int #compile_time {
	// since the widgets have `#expand` and this procedure could be only called at compile time
	// we're creating a new UUID per widget
	defer widget_uuid += 1;
	return widget_uuid;
}

fetch_colors :: (state: Interaction_State) -> (main: Col, border: Col, text: Col) {
	if #complete state == {
		case .NORMAL;  return COLOR_WIDGET_BG_NORMAL,  COLOR_WIDGET_BORDER_NORMAL,  COLOR_TEXT_NORMAL;
		case .HOVER;   return COLOR_WIDGET_BG_HOVERED, COLOR_WIDGET_BORDER_HOVERED, COLOR_TEXT_HOVERED;
		case .PRESSED; return COLOR_WIDGET_BG_PRESSED, COLOR_WIDGET_BORDER_PRESSED, COLOR_TEXT_PRESSED;
	}
}

fetch_parent :: () -> (pos: Vec2, layer: f32) {
	pos_off := Vec2.{0, 0};
	layer_off: f32 = 0;
	if selected_widget.count {
		pos_off   = selected_widget[selected_widget.count - 1].pos + .{0, WIDGET_HEADER_HEIGHT};
		layer_off = selected_widget[selected_widget.count - 1].layer;
	}
	return pos_off, layer_off;
}

widget_interaction :: (pos: Vec2, size: Vec2, layer: f32) -> (Interaction_State, fire: bool) #expand {
	state: Interaction_State = .NORMAL;

	uuid : int : #run generate_new_uuid();

	fire := false;

	if is_mouse_inside_rect(pos, size) && can_interact_with_widget(layer) {
		state = .HOVER;

		if is_mouse_pressed(0) {
			focused_uuid = uuid;
			fire = true;
		}
	}

	if focused_uuid != uuid then return state, false;

	if is_mouse_down(0) then state = .PRESSED;

	return state, fire;
}

button :: ($$text: string, pos: Vec2, size: Vec2, layer: f32, $t: f32 = 1) -> bool #expand {
	pos_off, layer_off := fetch_parent();

	state, fire := widget_interaction(pos + pos_off, size, layer + layer_off);

	bg_col, border_col, text_col := fetch_colors(state);

	draw_rect(pos + pos_off, size, layer + layer_off, bg_col);
	draw_rect_lines(pos + pos_off, size, layer + 1 + layer_off, border_col, t);

	s := measure_text(text, t);
	draw_text(text, pos + size / 2 - s / 2 + pos_off, layer + 1 + layer_off, t, text_col);

	return fire;
}

button :: (icon: Icon, pos: Vec2, size: Vec2, layer: f32, $t: f32 = 1) -> bool #expand {
	pos_off, layer_off := fetch_parent();

	state, fire := widget_interaction(pos + pos_off, size, layer + layer_off);

	bg_col, border_col, text_col := fetch_colors(state);

	draw_rect(pos + pos_off, size, layer + layer_off, bg_col);
	draw_rect_lines(pos + pos_off, size, layer + 1 + layer_off, border_col, t);

	s :: Vec2.{8.0 * t, 8.0 * t};
	draw_icon(icon, pos + size / 2 - s / 2 + pos_off, layer + 1 + layer_off, t, text_col);
	return fire;
}

checkbox :: ($$text: string, pos: Vec2, size: Vec2, layer: f32, value: *bool) {
	s := measure_text(text, 1);

	state, fire := widget_interaction(pos, size + .{s.x + 12, 0}, layer);

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
			text_col = COLOR_TEXT_HOVERED;
	}

	if value.* || state == .PRESSED then draw_rect(pos + .{4, 4}, size - .{8, 8}, layer, bg_col);
	draw_rect_lines(pos, size, layer + 1, COLOR_LINE);
	draw_text(text, pos + .{size.x + 8, (size.y - s.y) / 2}, layer, 1, text_col);

	if fire then value.* = !value.*;
}

draw_step_hslider :: (pos: Vec2, size: Vec2, layer: f32, amt: s32, value: *int, disabled: bool = false) {
	draw_rect(.{pos.x, pos.y + size.y / 2 - 1}, .{size.x, 2}, layer, ifx disabled then GRAY else COLOR_LINE);

	col_main: Col = ---;
	col_step: Col = ---;

	if !disabled {
		col_main = COLOR_WIDGET_BG_NORMAL;
		col_step = COLOR_WIDGET_BORDER_NORMAL;

		state := widget_interaction(pos, size, layer);

		col_main, _, _ = fetch_colors(state);

		if state == .PRESSED {
			value.* = xx clamp((cast(f32)mouse_x - pos.x) / size.x * amt, 0, xx (amt - 1));
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

window_begin :: ($$text: string, pos: *Vec2, size: Vec2, visible: *bool, $modal := false) #expand {
	uuid: int : #run generate_new_uuid();

	// window creation
	index: int = -1;
	for * all_panels if it.uuid == uuid {
		index = it_index;
		break;
	}
	if index == -1 {
		new := Panel.{uuid, 1, pos, size, .{0, 0}, false};
		array_add(*all_panels, new);
		index = all_panels.count - 1;
	} else if all_panels[index].layer == -1 {  // if become visible after being closed
		all_panels[index].layer = 0;
		make_panel_topmost(index);
		index = all_panels.count - 1;
	}
	p := *all_panels[index];

	// window movement
	#if !modal {
		if is_mouse_inside_rect(p.pos, .{size.x - WIDGET_HEADER_HEIGHT, WIDGET_HEADER_HEIGHT}) && can_interact_with_widget(p.layer) {
			if is_mouse_pressed(0) {
				p.pressed_pos.x = mouse_x - p.pos.x;
				p.pressed_pos.y = mouse_y - p.pos.y;
				p.pressed = true;
			}
		}
		if p.pressed {
			delta := Vec2.{xx mouse_x, xx mouse_y} - p.pressed_pos;
			p.pos.* = delta;
		}
		if is_mouse_released(0) then p.*.pressed = false;
	} else {
		modal_open = true;
	}

	// drawing
	fire := button(.CLOSE, p.pos + .{size.x - WIDGET_HEADER_HEIGHT, 0}, .{WIDGET_HEADER_HEIGHT, WIDGET_HEADER_HEIGHT}, p.layer + 1, 2);

	draw_rect(p.pos, size, p.layer, COLOR_WIDGET_BG_NORMAL);
	draw_rect_lines(p.pos, size, p.layer + 1, COLOR_WIDGET_BORDER_NORMAL);
	draw_rect(p.pos + .{0, WIDGET_HEADER_HEIGHT - 1}, .{size.x, 1}, p.layer + 1, COLOR_WIDGET_BORDER_NORMAL);
	draw_text(text, p.pos + .{9, 8}, p.layer + 1, 1, COLOR_TEXT_NORMAL);

	w: Selected_Widget;
	w.pos = p.pos;
	w.layer = p.layer;
	array_add(*selected_widget, w);

	#if modal {
		fire |= is_key_pressed(KEY_ESC);
	}

	if fire {
		p.layer = -1;
		visible.* = false;
		closed_a_window = true;
		#if modal {
			modal_open = false;
		}
	}
}

child_begin :: ($$text: string, pos: Vec2, size: Vec2, layer: f32) {
	p :: 4;

	pos_off, layer_off := fetch_parent();

	draw_rect(pos + pos_off, .{p, 1}, layer + layer_off, COLOR_LINE);
	draw_rect(pos + pos_off, .{1, size.y}, layer + layer_off, COLOR_LINE);
	draw_rect(pos + pos_off + .{0, size.y - 1}, .{size.x, 1}, layer + layer_off, COLOR_LINE);
	draw_rect(pos + pos_off + .{size.x - 1, 0}, .{1, size.y}, layer + layer_off, COLOR_LINE);

	s :: 1;
	m := measure_text(text, s);
	draw_text(text, pos + pos_off + .{p + 4, -m.y / 2}, layer + layer_off, s, COLOR_LINE);

	draw_rect(pos + pos_off + .{p + 8 + m.x, 0}, .{size.x - p - 8 - m.x, 1}, layer + layer_off, COLOR_LINE);

	w: Selected_Widget;
	w.pos = pos;
	w.layer = layer;
	array_add(*selected_widget, w);
}

widget_end :: () {
	selected_widget.count -= 1;
}

draw_scrollbar :: (pos: Vec2, size: Vec2, layer: f32, scroll_pos: *Vec2, scroll_size: Vec2, min_size: Vec2, max_value: Vec2) #expand {
	x_visible := min_size.x + size.x < scroll_size.x;
	y_visible := min_size.y + size.y < scroll_size.y;

	if y_visible {
		scroll_pos_x := pos.x + size.x - WIDGET_SCROLLBAR_SIZE;
		scroll_pos_y := pos.y;
		off := ifx x_visible then WIDGET_SCROLLBAR_SIZE;

		state := widget_interaction(.{scroll_pos_x, scroll_pos_y - off}, .{WIDGET_SCROLLBAR_SIZE, size.y}, layer);

		if is_mouse_inside_rect(pos, size) && mouse_dz && !is_key_down(KEY_SHIFT) && can_interact_with_widget(layer) {
			amt := mouse_dz * 16 * 3;
			scroll_pos.*.y -= amt;
		}

		aspect_ratio := (size.y - off) / (scroll_size.y - min_size.y);
		bar_height := ceil(aspect_ratio * size.y);

		if state == .PRESSED {
			scroll_pos.*.y = (mouse_y - pos.y - bar_height / 2) / aspect_ratio;
		}

		bar_col := ifx state == .NORMAL then COLOR_WIDGET_BORDER_NORMAL else COLOR_WIDGET_BG_PRESSED;

		val := round_up(scroll_pos.y, 16);
		scroll_pos.*.y = clamp(val, 0, max_value.y - min_size.y);

		// drawing
		draw_rect(.{scroll_pos_x, scroll_pos_y}, .{WIDGET_SCROLLBAR_SIZE, size.y}, layer, COLOR_WIDGET_BG_NORMAL);
		draw_rect(.{scroll_pos_x, floor(scroll_pos_y + aspect_ratio * scroll_pos.*.y)}, .{WIDGET_SCROLLBAR_SIZE, bar_height}, layer + 1, bar_col);
	}

	if x_visible {
		scroll_pos_x := pos.x;
		scroll_pos_y := pos.y + size.y - WIDGET_SCROLLBAR_SIZE;
		off := ifx y_visible then WIDGET_SCROLLBAR_SIZE;

		state := widget_interaction(.{scroll_pos_x, scroll_pos_y}, .{size.x - off, WIDGET_SCROLLBAR_SIZE}, layer);

		if is_mouse_inside_rect(pos, size) && mouse_dz && is_key_down(KEY_SHIFT) && can_interact_with_widget(layer) {
			amt := mouse_dz * 16 * 3;
			scroll_pos.*.x -= amt;
		}

		aspect_ratio := (size.x - off) / (scroll_size.x - min_size.x);
		bar_width := ceil(aspect_ratio * size.x);

		if state == .PRESSED {
			scroll_pos.*.x = (mouse_x - pos.x - bar_width / 2) / aspect_ratio;
		}

		bar_col := ifx state == .NORMAL then COLOR_WIDGET_BORDER_NORMAL else COLOR_WIDGET_BG_PRESSED;

		val := round_up(scroll_pos.x, 16);
		scroll_pos.*.x = clamp(val, 0, max_value.x - min_size.x);

		// drawing
		draw_rect(.{scroll_pos_x, scroll_pos_y}, .{size.x, WIDGET_SCROLLBAR_SIZE}, layer, COLOR_WIDGET_BG_NORMAL);
		draw_rect(.{floor(scroll_pos_x + aspect_ratio * scroll_pos.*.x), scroll_pos_y}, .{bar_width, WIDGET_SCROLLBAR_SIZE}, layer + 1, bar_col);
	}
}

can_interact_with_widget :: (layer: f32) -> bool {
	if modal_open {
		return layer >= all_panels[all_panels.count - 1].layer;
	} else {
		if closed_a_window then return false;
		if focused_uuid != -1 then return false;

		for all_panels if it.layer != -1 {
			if is_mouse_inside_rect(it.pos, it.size) {
				if layer >= it.layer then continue;

				return false;
			}
		}
		return true;
	}
}

Panel :: struct {
	uuid: int;
	layer: f32;
	pos: *Vec2;
	size: Vec2;
	pressed_pos: Vec2;
	pressed := false;
}

Selected_Widget :: struct {
	pos: Vec2;
	layer: f32;
}

begin_widgets :: () {
	layer: f32 = 10;

	for * all_panels if it.layer != -1 {
		it.*.layer = layer;
		layer += 5;
	}

	if is_mouse_released(0) then focused_uuid = -1;
}

make_panel_topmost :: (idx: int) {
	p := all_panels[idx];
	array_ordered_remove_by_index(*all_panels, idx);
	array_add(*all_panels, p);
}

finalize_widgets :: () {
	target_fade := ifx ui.show_popup 0.75 else 0;
	T :: 0.35;  // seconds took from 0 to target_fade (I didn't solve the equation, but it's a nice approx, maybe it's good)
	k := 1 / (T * vp.dt * 1000);

	fade_value = lerp(fade_value, target_fade, k);

	layer := ifx all_panels.count then all_panels[all_panels.count - 1].layer;
	draw_rect(.{0, 0}, .{xx vp.width, xx vp.height}, layer, .{0, 0, 0, cast(u8)(fade_value * 255)});

	// make the selected window the topmost
	// p: Panel;
	idx := -1;
	for all_panels if it.pressed {
		// p = it;
		idx = it_index;
		break;
	}
	if idx != -1 then make_panel_topmost(idx);
	closed_a_window = false;
}

widget_uuid: u32;  // used only at compile time

fade_value: f32;

focused_uuid: int = -1;
closed_a_window := false;
modal_open := false;
selected_widget: [..]Selected_Widget;  // handled as a stack
all_panels: [..]Panel;
