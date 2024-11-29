draw_widget_rect :: inline (pos: Vec2, size: Vec2, z: f32, col: Col) {
	p := fetch_parent();
	draw_rect(p.pos + pos, size, p.z + z, col);
}

draw_widget_rect :: inline (pos: Vec2, size: Vec2, z: f32, c1: Col, c2: Col, c3: Col, c4: Col) {
	p := fetch_parent();
	draw_rect(p.pos + pos, size, p.z + z, c1, c2, c3, c4);
}

draw_widget_rect_lines :: inline (pos: Vec2, size: Vec2, z: f32, col: Col, t: f32 = 1) {
	p := fetch_parent();
	draw_rect_lines(p.pos + pos, size, p.z + z, col, t);
}

draw_widget_text :: inline (text: string, pos: Vec2, z: f32, scale: f32, color: Col, $wrap: f32 = 0) {
	p := fetch_parent();
	draw_text(text, p.pos + pos, p.z + z, scale, color, wrap);
}

draw_widget_icon :: inline (icon: Icon, pos: Vec2, z: f32, $scale: f32, col: Col) {
	p := fetch_parent();
	draw_icon(icon, p.pos + pos, p.z + z, scale, col);
}

get_relative_x :: inline () -> f32 {
	p := fetch_parent();
	return mouse_x - p.pos.x;
}

get_relative_y :: inline () -> f32 {
	p := fetch_parent();
	return mouse_y - p.pos.y;
}

get_relative_pos :: inline () -> Vec2 {
	p := fetch_parent();
	x := mouse_x - p.pos.x;
	y := mouse_y - p.pos.y;
	return .{x, y};
}

is_mouse_inside_widget_rect :: inline (pos: Vec2, size: Vec2) -> bool {
	p := fetch_parent();
	return is_mouse_inside_rect(p.pos + pos, size);
}

button :: ($$text: string, pos: Vec2, size: Vec2, z: f32, $t: f32 = 1, disabled := false, it: int = 0, loc := #caller_location) -> bool {
	state, fire := create_selectable_region(.BUTTON, loc, it, pos, size, z);

	bg_col:     Col = ---;
	border_col: Col = ---;
	text_col:   Col = ---;
	
	if disabled {
		bg_col = settings.themes.platform_widget_bg_normal;
		border_col = settings.themes.platform_disabled;
		text_col = settings.themes.platform_disabled;
	} else {
		bg_col, border_col, text_col = fetch_colors(state);
	}

	draw_widget_rect(pos, size, z, bg_col);
	draw_widget_rect_lines(pos, size, z + 1, border_col, t);

	s := measure_text(text, t);
	draw_widget_text(text, pos + size / 2 - s / 2, z + 1, t, text_col);

	return fire;
}

button :: (icon: Icon, pos: Vec2, size: Vec2, z: f32, $t: f32 = 1, it: int = 0, loc := #caller_location) -> bool {
	state, fire := create_selectable_region(.BUTTON, loc, it, pos, size, z);

	bg_col, border_col, text_col := fetch_colors(state);

	draw_widget_rect(pos, size, z, bg_col);
	draw_widget_rect_lines(pos, size, z + 1, border_col, t);

	s :: Vec2.{8.0 * t, 8.0 * t};
	draw_widget_icon(icon, pos + size / 2 - s / 2, z + 1, t, text_col);

	return fire;
}

checkbox :: ($$text: string, pos: Vec2, size: Vec2, z: f32, value: *bool, it: int = 0, loc := #caller_location) {
	s := measure_text(text, 1);

	state, fire := create_selectable_region(.CHECKBOX, loc, it, pos, size + .{s.x + 12, 0}, z);

	bg_col: Col;
	text_col: Col;
	if state == {
		case .NORMAL;
			bg_col = settings.themes.platform_widget_bg_hover;
			text_col = settings.themes.platform_text_normal;
		case .HOVER;
			bg_col = settings.themes.platform_widget_bg_hover;
			text_col = settings.themes.platform_text_hover;
		case .PRESSED;
			bg_col = settings.themes.platform_widget_bg_press;
			text_col = settings.themes.platform_text_hover;
	}

	if value.* || state == .PRESSED then draw_widget_rect(pos + .{4, 4}, size - .{8, 8}, z, bg_col);
	draw_widget_rect_lines(pos, size, z + 1, settings.themes.platform_line);
	draw_widget_text(text, pos + .{size.x + 8, (size.y - s.y) / 2}, z, 1, text_col);

	if fire then value.* = !value.*;
}

draw_step_hslider :: (pos: Vec2, size: Vec2, z: f32, amt: s32, value: *int, disabled: bool = false, it: int = 0, loc := #caller_location) -> bool {
	draw_widget_rect(pos + .{0, size.y / 2 - 1}, .{size.x, 2}, z, ifx disabled then settings.themes.platform_disabled else settings.themes.platform_line);

	col_main: Col = ---;
	col_step: Col = ---;

	edited: bool;

	if !disabled {
		col_main = settings.themes.platform_widget_bg_hover;
		col_step = settings.themes.platform_widget_border_normal;

		state := create_selectable_region(.SLIDER, loc, it, pos, size, z);
		
		if state == .PRESSED {
			col_main = settings.themes.platform_widget_bg_press;
			value.* = xx clamp((cast(f32)get_relative_x() - pos.x) / size.x * amt, 0, xx (amt - 1));
			edited = true;
		}
	} else {
		col_main = settings.themes.platform_disabled;
		col_step = settings.themes.platform_disabled;
	}

	for 0..amt / 3 {
		x := cast(f32)(it * 3) / (amt - 1) * size.x;
		s := size.y / 2;
		if it % 3 == 0 then s = size.y / 3 * 2;

		draw_widget_rect(pos + .{x - 1, size.y / 2 - s / 2}, .{2, s}, z + 1, col_step);
	}

	pos_x := pos.x + cast(f32)value.* / (amt - 1) * size.x;
	draw_widget_rect(.{pos_x - 4, pos.y}, .{8, size.y}, z + 2, col_main);
	
	return edited;
}

draw_scrollbar :: (pos: Vec2, size: Vec2, z: f32, scroll_pos: *Vec2, scroll_size: Vec2, min_size: Vec2, max_value: Vec2, speed_slow: int, speed_fast: int, it: int = 0, loc := #caller_location) {
	x_visible := min_size.x + size.x < scroll_size.x;
	y_visible := min_size.y + size.y < scroll_size.y;

	if y_visible {
		scroll_pos_x := pos.x + size.x - WIDGET_SCROLLBAR_SIZE;
		scroll_pos_y := pos.y;
		off := ifx x_visible then cast(f32)WIDGET_SCROLLBAR_SIZE;

		state, _ , uuid := create_selectable_region(.SCROLLBAR, loc, it, .{scroll_pos_x, scroll_pos_y}, .{WIDGET_SCROLLBAR_SIZE, size.y - off}, z);

		if mouse_dz && !is_key_down(KEY_SHIFT) && can_interact_with_widget(uuid, pos, size, z) {
			true_speed := ifx is_key_down(KEY_CTRL) then speed_fast else speed_slow;
			amt := mouse_dz * 16 * true_speed;
			scroll_pos.*.y -= amt;
		}

		aspect_ratio := (size.y - off) / (scroll_size.y - min_size.y);
		bar_height := ceil(aspect_ratio * size.y);

		if state == .PRESSED {
			scroll_pos.*.y = (get_relative_y() - pos.y - bar_height / 2) / aspect_ratio;
		}

		bar_col := ifx state == .NORMAL then settings.themes.platform_widget_border_normal else settings.themes.platform_widget_bg_press;

		val := round_up(scroll_pos.y, 16);
		scroll_pos.*.y = clamp(val, 0, max_value.y - min_size.y);

		draw_widget_rect(.{scroll_pos_x, scroll_pos_y}, .{WIDGET_SCROLLBAR_SIZE, size.y}, z, settings.themes.platform_widget_bg_normal);
		draw_widget_rect(.{scroll_pos_x, floor(scroll_pos_y + aspect_ratio * scroll_pos.*.y)}, .{WIDGET_SCROLLBAR_SIZE, bar_height}, z + 1, bar_col);
	}

	if x_visible {
		scroll_pos_x := pos.x;
		scroll_pos_y := pos.y + size.y - WIDGET_SCROLLBAR_SIZE;
		off := ifx y_visible then cast(f32)WIDGET_SCROLLBAR_SIZE;

		state, _, uuid := create_selectable_region(.SCROLLBAR, loc, it + 1, .{scroll_pos_x, scroll_pos_y}, .{size.x - off, WIDGET_SCROLLBAR_SIZE}, z);

		if mouse_dz && is_key_down(KEY_SHIFT) && can_interact_with_widget(uuid, pos, size, z) {
			true_speed := ifx is_key_down(KEY_CTRL) then speed_fast else speed_slow;
			amt := mouse_dz * 16 * true_speed;
			scroll_pos.*.x -= amt;
		}

		aspect_ratio := (size.x - off) / (scroll_size.x - min_size.x);
		bar_width := ceil(aspect_ratio * size.x);

		if state == .PRESSED {
			scroll_pos.*.x = (get_relative_x() - pos.x - bar_width / 2) / aspect_ratio;
		}

		bar_col := ifx state == .NORMAL then settings.themes.platform_widget_border_normal else settings.themes.platform_widget_bg_press;

		val := round_up(scroll_pos.x, 16);
		scroll_pos.*.x = clamp(val, 0, max_value.x - min_size.x);

		draw_widget_rect(.{scroll_pos_x, scroll_pos_y}, .{size.x, WIDGET_SCROLLBAR_SIZE}, z, settings.themes.platform_widget_bg_normal);
		draw_widget_rect(.{floor(scroll_pos_x + aspect_ratio * scroll_pos.*.x), scroll_pos_y}, .{bar_width, WIDGET_SCROLLBAR_SIZE}, z + 1, bar_col);
	}
}

tab_bar :: (pos: Vec2, width: f32, z: f32, $tabs: []string, focused_tab: *int, it_: int = 0, loc := #caller_location) {
	draw_selected_rect :: (pos: Vec2, size: Vec2, z: f32) {
		draw_widget_rect(pos, .{1, size.y}, z, settings.themes.platform_line);
		draw_widget_rect(pos, .{size.x, 1}, z, settings.themes.platform_line);
		draw_widget_rect(pos + .{size.x, 0}, .{1, size.y}, z, settings.themes.platform_line);
	}

	s :: 24;

	x: f32;
	for tabs {
		d := measure_text(it, 2);
		_, fire := create_selectable_region(.TAB, loc, it_ + it_index, pos + .{4 + x, 0}, .{d.x + 8, s}, z);
		
		if fire then focused_tab.* = it_index;

		x += d.x + 16;
	}

	x = 0;
	w: f32 = 4;
	w_continue: f32;
	for tabs {
		d := measure_text(it, 2);

		text_col: Col = ---;
		if it_index == focused_tab.* {
			text_col = settings.themes.platform_text_normal;
			draw_selected_rect(pos + .{4 + x, 0}, .{d.x + 8, s}, z);
			draw_widget_rect(pos + .{0, s - 1}, .{w, 1}, z, settings.themes.platform_line);
			w_continue = w + d.x + 8;
		} else {
			text_col = settings.themes.platform_disabled;
			draw_selected_rect(.{4 + pos.x + x, pos.y}, .{d.x + 8, s}, z);
			w += d.x + 16;
		}

		draw_widget_text(it, .{8 + pos.x + x, pos.y + 4}, z, 2, text_col);

		x += d.x + 16;
	}

	draw_widget_rect(pos + .{w_continue, s - 1}, .{width - w_continue, 1}, z, settings.themes.platform_line);
}

h_separator :: ($name: string, pos: Vec2, width: f32, z: f32) {
	p :: 12;

	draw_widget_rect(pos, .{p, 1}, z, settings.themes.platform_line);

	draw_widget_text(name, pos + .{p + 4, -5}, z, 1, settings.themes.platform_text_normal);
	s :: #run measure_text(name, 1);

	draw_widget_rect(pos + .{p + 8 + s.x, 0}, .{width - p - 8 - s.x, 1}, z, settings.themes.platform_line);
}

combo_box :: (pos: Vec2, size: Vec2, z: f32, items: []string, selected: *int, opened: *bool, it_: int = 0, loc := #caller_location) -> bool {
	state, fire := create_selectable_region(.COMBO, loc, it_, pos, size, z);

	_, border_col, text_col := fetch_colors(state);

	draw_widget_rect_lines(pos, size, z, border_col);
	draw_widget_text( items[selected.*], pos + .{2, 1}, z, 2, text_col);

	if fire then opened.* = !opened.*;
	
	h := items.count * 20.0;
	
	if is_mouse_pressed(0) && !is_mouse_inside_widget_rect(pos, .{size.x, h + 20.0}) then opened.* = false;
	
	fire_internal: bool;
	
	if state == .HOVER && mouse_dz {
		selected.* = clamp(selected.* - mouse_dz, 0, items.count - 1);
		fire_internal = true;
	}
	
	if opened.* {
		draw_widget_icon(.ARROW_DOWN, pos + .{size.x - 18, 2}, z + 1, 2, text_col);
		draw_widget_rect_lines(pos + .{size.x - 20, 0}, .{20, 20}, z + 1, border_col);
		
		draw_widget_rect(pos + .{0, 20}, .{size.x, h}, z + 1, settings.themes.platform_widget_bg_normal);
		
		for items {
			state_internal:, fire_internal = create_selectable_region(.COMBO, loc, it_ + it_index + 1, pos + .{0, 20.0 * (it_index + 1)}, .{size.x, 20.0}, z);
			
			_, border_col, text_col := fetch_colors(state_internal);

			rel_x := pos.x;
			rel_y := pos.y + 20.0 * (it_index + 1);
			
			draw_widget_rect_lines(.{rel_x, rel_y}, .{size.x, 20.0}, z + 2, border_col);
			draw_widget_text(it, .{rel_x + 2, rel_y + 1}, z + 2, 2, text_col);
			
			if fire_internal {
				selected.* = it_index;
				opened.* = false;
				break;
			}
		}
	} else {
		draw_widget_icon(.ARROW_LEFT, pos + .{size.x - 18, 2}, z + 1, 2, text_col);
		draw_widget_rect_lines(pos + .{size.x - 20, 0}, .{20, 20}, z + 1, border_col);
	}
	
	return fire_internal;
}

color_picker :: (pos: Vec2, z: f32, hsv: *Vec3, rgb: *Col, it: int = 0, loc := #caller_location) -> bool {
	width  :: 207.0;
	height :: 216.0;

	child_begin("picker", pos, .{width, height}, z);
	
	s := width - 40;

	state_quad, _ := create_selectable_region(.COLOR_PICKER, loc, it, .{8, 8}, .{s, s}, z);
	state_bar,  _ := create_selectable_region(.COLOR_PICKER, loc, it + 1, .{s + 12, 8}, .{20, s}, z);
	
	edited := false;
	if state_quad == .PRESSED {
		mouse := get_relative_pos();
		
		hsv.*.y = clamp((mouse.x - 8) / s, 0, 1);
		hsv.*.z = clamp(1 - (mouse.y - 8) / s, 0, 1);
		
		edited = true;
	} else if state_bar == .PRESSED {
		y := get_relative_y();
		
		hsv.*.x = clamp((y - 8) / s, 0, 1);

		edited = true;
	}
	rgb.* = HSV_to_RGB(hsv);
	
	text_pos :: Vec2.{18, 162};
	fmt :: #bake_arguments formatInt(minimum_digits = 3, padding = #char " ");
	draw_widget_text(tprint("R: %", fmt(rgb.r)),                  text_pos + .{  0, 20}, z, 1, settings.themes.platform_text_normal);
	draw_widget_text(tprint("G: %", fmt(rgb.g)),                  text_pos + .{ 62, 20}, z, 1, settings.themes.platform_text_normal);
	draw_widget_text(tprint("B: %", fmt(rgb.b)),                  text_pos + .{124, 20}, z, 1, settings.themes.platform_text_normal);
	draw_widget_text(tprint("H: %", fmt(cast(s32)(hsv.x * 360))), text_pos + .{  0, 36}, z, 1, settings.themes.platform_text_normal);
	draw_widget_text(tprint("S: %", fmt(cast(s32)(hsv.y * 100))), text_pos + .{ 62, 36}, z, 1, settings.themes.platform_text_normal);
	draw_widget_text(tprint("V: %", fmt(cast(s32)(hsv.z * 100))), text_pos + .{124, 36}, z, 1, settings.themes.platform_text_normal);
	
	{
		p := fetch_parent();
		draw_color_picker_rect(p.pos + .{8, 8}, .{s, s}, p.z + z, hsv.x);
	}
	
	draw_widget_rect(.{s + 12,             8}, .{20, s / 6}, z, .{255,   0,   0, 255}, .{255,   0,   0, 255}, .{255, 255,   0, 255}, .{255, 255,   0, 255});
	draw_widget_rect(.{s + 12, s     / 6 + 8}, .{20, s / 6}, z, .{255, 255,   0, 255}, .{255, 255,   0, 255}, .{  0, 255,   0, 255}, .{  0, 255,   0, 255});
	draw_widget_rect(.{s + 12, s * 2 / 6 + 8}, .{20, s / 6}, z, .{  0, 255,   0, 255}, .{  0, 255,   0, 255}, .{  0, 255, 255, 255}, .{  0, 255, 255, 255});
	draw_widget_rect(.{s + 12, s * 3 / 6 + 8}, .{20, s / 6}, z, .{  0, 255, 255, 255}, .{  0, 255, 255, 255}, .{  0,   0, 255, 255}, .{  0,   0, 255, 255});
	draw_widget_rect(.{s + 12, s * 4 / 6 + 8}, .{20, s / 6}, z, .{  0,   0, 255, 255}, .{  0,   0, 255, 255}, .{255,   0, 255, 255}, .{255,   0, 255, 255});
	draw_widget_rect(.{s + 12, s * 5 / 6 + 8}, .{20, s / 6}, z, .{255,   0, 255, 255}, .{255,   0, 255, 255}, .{255,   0,   0, 255}, .{255,   0,   0, 255});
	
	draw_widget_rect_lines(.{8, 8}, .{s, s}, z + 1, settings.themes.platform_line);
	draw_widget_rect_lines(.{s + 12, 8}, .{20, s}, z + 1, settings.themes.platform_line);
	
	cursor := Vec2.{(s - 2) * hsv.y, (s - 2) * (1 - hsv.z)} + .{9, 9};
	draw_widget_rect(cursor - .{3, 3}, .{6, 6}, z + 2, rgb);
	draw_widget_rect_lines(cursor - .{4, 4}, .{8, 8}, z + 2, settings.themes.platform_line);
	
	rgb2 := HSV_to_RGB(.{hsv.x, 1, 1});
	p1 := Vec2.{s + 12, 8 + hsv.x * (s - 1)};
	draw_widget_rect_lines(p1 - .{2, 2}, .{24, 6}, z + 2, settings.themes.platform_line);
	draw_widget_rect(p1 - .{2, 2}, .{24, 6}, z + 2, rgb2);
	
	child_end();
	
	return edited;
}

window :: (uuid: ID, p: *Panel) {
	// handle window movement
	if p.flags & .HEADER {
		if !(p.flags & .MODAL) {
			if can_interact_with_widget(uuid, p.pos, .{p.size.x - WIDGET_HEADER_HEIGHT, WIDGET_HEADER_HEIGHT}, p.z, .{}) {
				if is_mouse_pressed(0) {
					p.pressed_pos.x = mouse_x - p.pos.x;
					p.pressed_pos.y = mouse_y - p.pos.y;
					p.pressed = true;
					make_panel_topmost(p);
				}
			}
			if p.pressed {
				delta := Vec2.{xx mouse_x, xx mouse_y} - p.pressed_pos;
				p.pos = delta;
			}
			if is_mouse_released(0) then p.pressed = false;
		} else {
			p.pos.x = (vp.width - p.size.x) / 2;
			p.pos.y = (vp.height - p.size.y) / 2;
		}
		p.pos.x = clamp(p.pos.x, -p.size.x + 40, cast(f32)vp.width - 40);
		p.pos.y = clamp(p.pos.y, HEADER_HEIGHT,  cast(f32)vp.height - WIDGET_HEADER_HEIGHT);
	}

	parent: Panel = ---;
	parent.pos = p.pos + .{0, WIDGET_HEADER_HEIGHT};
	parent.z = p.z;
	parent.uuid = uuid;
	array_add(*parent_panels, parent);

	draw_rect(p.pos, p.size, p.z, settings.themes.platform_widget_bg_normal);
	draw_rect_lines(p.pos, p.size, p.z + 1, settings.themes.platform_widget_border_normal);
	if p.name then draw_text(p.name, p.pos + .{9, 8}, p.z + 1, 1, settings.themes.platform_text_normal);

	fire: bool;
	if p.flags & .HEADER {
		fire = button(.CLOSE, .{p.size.x - WIDGET_HEADER_HEIGHT, -WIDGET_HEADER_HEIGHT}, .{WIDGET_HEADER_HEIGHT, WIDGET_HEADER_HEIGHT}, z = 1, it = uuid);
		draw_rect(p.pos + .{0, WIDGET_HEADER_HEIGHT - 1}, .{p.size.x, 1}, p.z + 1, settings.themes.platform_widget_border_normal);
	}

	if p.flags & .MODAL then fire |= is_key_pressed(KEY_ESC);
	if fire  {
		p.visible = false;
		if p.on_close then p.on_close();
	}

	if p.draw_func then p.draw_func();

	parent_panels.count -= 1;
}

child_begin :: ($$text: string, pos: Vec2, size: Vec2, z: f32) {
	padding :: 4;

	draw_widget_rect(pos, .{padding, 1}, z, settings.themes.platform_line);
	draw_widget_rect(pos, .{1, size.y}, z, settings.themes.platform_line);
	draw_widget_rect(pos + .{0, size.y - 1}, .{size.x, 1}, z, settings.themes.platform_line);
	draw_widget_rect(pos + .{size.x - 1, 0}, .{1, size.y}, z, settings.themes.platform_line);

	s :: 1;
	m := measure_text(text, s);
	draw_widget_text(text, pos + .{padding + 4, -m.y / 2}, z, s, settings.themes.platform_line);

	draw_widget_rect(pos + .{padding + 8 + m.x, 0}, .{size.x - padding - 8 - m.x, 1}, z, settings.themes.platform_line);

	p := fetch_parent();
	parent: Panel = ---;
	parent.pos = pos + p.pos;
	parent.z = z + p.z;
	array_add(*parent_panels, parent);
}

child_end :: () {
	parent_panels.count -= 1;
}

create_new_panel :: (draw: () -> (), name: string, size: Vec2, on_close: () -> () = null, modal := false, it: int = 0, loc := #caller_location) -> ID {
	uuid := hash_widget(loc, it);
	panel, newly_added := find_or_add(*panels, uuid);
	assert(newly_added);

	panel.*.size = size;
	panel.*.draw_func = draw;
	panel.*.visible = false;
	panel.*.name = name;
	panel.*.on_close = on_close;

	              panel.*.flags |= .HEADER;
	if modal then panel.*.flags |= .MODAL;

	return uuid;
}

begin_widgets :: () {
	if is_mouse_released(0) then focused_uuid = 0;
}

finalize_widgets :: () {
	target_fade := ifx modal_visible 0.75 else 0;
	T :: 0.35;  // seconds took to reach target_fade
	k := 1 / (T * vp.dt * 1000);

	fade_value = lerp(fade_value, target_fade, k);

	// black background when modal is enabled
	z := 10.0 + (panels.count - 1) * 5;
	draw_rect(.{0, 0}, .{xx vp.width, xx vp.height}, z, .{0, 0, 0, cast(u8)(fade_value * 255)});

	assert(parent_panels.count == 0);
}

widgets_draw_panels :: () {
	ctx := context;
	ctx.allocator = temp;
	push_context,defer_pop ctx;

	Panel_Internal :: struct {
		p: *Panel;
		uuid: ID;
	}

	panels_internal: [..]Panel_Internal;

	for * panels if it.visible {
		array_add(*panels_internal, .{it, it_index});
	}

	quick_sort(panels_internal, (x, y) => x.p.z - y.p.z);

	modal_panel: Panel_Internal = .{null, 0};

	z: f32 = 10;
	for panels_internal {
		if it.p.visible && (it.p.flags & .MODAL) {
			modal_panel = it;
			continue;
		}
		it.p.z = z;
		window(it.uuid, it.p);
		z += 5;
	}

	modal_visible = cast(bool)modal_panel.p;

	if modal_panel.p != null {
		make_panel_topmost(modal_panel.p);
		window(modal_panel.uuid, modal_panel.p);
	}
}

deinit_widgets :: () {
	deinit(*panels);
}

make_panel_topmost :: (p: *Panel) {
	p.*.z = 10.0 + 5 * panels.count;
}

toggle_panel :: (uuid: ID, pos: Vec2 = .{}, $centered := false) {
	p := table_find_pointer(*panels, uuid);

	#if DEBUG then assert(p != null);

	if p.*.visible {
		p.*.visible = false;
		p.*.pressed = false;
	} else {
		p.*.visible = true;
	}
	
	#if centered {
		x := (vp.width - p.size.x) / 2;
		y := (vp.height - p.size.y) / 2;
		p.*.pos = .{x, y};
	} else {
		p.*.pos = pos;
	}

	make_panel_topmost(p);
}

is_panel_visible :: (uuid: ID) -> bool {
	p := table_find_pointer(*panels, uuid);

	#if DEBUG then assert(p != null);

	return p.*.visible;
}

set_panel_name :: (uuid: ID, name: string) {
	p := table_find_pointer(*panels, uuid);

	#if DEBUG then assert(p != null);

	p.*.name = name;
}

fetch_parent :: () -> Panel {
	if parent_panels.count {
		return parent_panels[parent_panels.count - 1];
	}
	
	p: Panel = ---;
	p.pos = .{0, 0};
	p.z = 0;
	return p;
}

fetch_colors :: (state: Interaction_State) -> (main: Col, border: Col, text: Col) {
	if #complete state == {
		case .NORMAL;  return settings.themes.platform_widget_bg_normal,  settings.themes.platform_widget_border_normal,  settings.themes.platform_text_normal;
		case .HOVER;   return settings.themes.platform_widget_bg_hover, settings.themes.platform_widget_border_hover, settings.themes.platform_text_hover;
		case .PRESSED; return settings.themes.platform_widget_bg_press, settings.themes.platform_widget_border_press, settings.themes.platform_text_press;
	}
}

create_selectable_region :: (type: Widget_Type, loc: Source_Code_Location, it: int, pos: Vec2, size: Vec2, z: f32) -> (Interaction_State, bool, ID) {
	uuid := hash_widget(loc, it);
	
	widget, newly_added := find_or_add(*widgets, uuid);
	
	if newly_added {
		widget.*.uuid = uuid;
		widget.*.type = type;
		widget.*.size = size;
		widget.*.z    = z;
	}
	widget.*.pos  = pos;
	
	state, fire := widget_interaction(uuid);
	return state, fire, uuid;
}

#scope_file
widget_interaction :: (uuid: ID) -> (Interaction_State, fire: bool) {
	p := fetch_parent();
	
	widget := table_find_pointer(*widgets, uuid);
	#if DEBUG then assert(widget != null);
	
	state: Interaction_State = .NORMAL;

	fire := false;

	if can_interact_with_widget(uuid, widget.pos, widget.size, widget.z, p) {
		state = .HOVER;

		if is_mouse_pressed(0) {
			ifx !focused_uuid then focused_uuid = uuid;
			fire = true;
		}
	}

	if focused_uuid != uuid then return state, false;

	if is_mouse_down(0) then state = .PRESSED;

	return state, fire;
}

can_interact_with_widget :: (uuid: ID, pos: Vec2, size: Vec2, z: f32, p: Panel) -> bool {
	if !is_mouse_inside_rect(pos + p.pos, size) then return false;  // mouse inside widget

	if modal_visible then return z + p.z >= 10 + (panels.count - 1) * 5.0;

	for panels if it_index != uuid {
		if !it.visible then continue;

		if z + p.z < it.z && is_mouse_inside_rect(it.pos, it.size) {  // mouse over higher-z panel
			return false;
		}
	}

	return true;
}

can_interact_with_widget :: inline (uuid: ID, pos: Vec2, size: Vec2, z: f32) -> bool {
	p := fetch_parent();
	return can_interact_with_widget(uuid, pos, size, z, p);
}

hash_widget :: (loc: Source_Code_Location, it: int) -> ID {
	h1 := fnv1a_hash(loc.fully_pathed_filename.data, loc.fully_pathed_filename.count);
	h2 := knuth_hash(cast,no_check(u64)loc.line_number);
	h3 := knuth_hash(cast,no_check(u64)it);

	out := cast,no_check(ID)(h1 ^ h2 ^ h3);

	// ID 0 means no widget is focused, better to not happen this!
	#if DEBUG then assert(out != 0);

	return out;
}

Panel_Flags :: enum_flags {
	NONE;
	HEADER;
	MODAL;
}

Widget_Type :: enum {
	BUTTON;
	CHECKBOX;
	SLIDER;
	SCROLLBAR;
	TAB;
	SEPARATOR;
	COMBO;
	COLOR_PICKER;
	TEXT;
}

Widget :: struct {
	type: Widget_Type;
	uuid: ID;
	
	pos: Vec2;
	size: Vec2;
	z: f32;
}

panels: Table(ID, Panel);
widgets: Table(ID, Widget);

parent_panels: [..]Panel;

modal_visible: bool;

fade_value: f32;

#scope_export
Interaction_State :: enum {
	NORMAL;
	HOVER;
	PRESSED;
}

Panel :: struct {
	pos: Vec2;
	size: Vec2;
	z: f32;
	uuid: ID;

	pressed_pos: Vec2;
	pressed: bool;

	visible: bool;
	name: string;

	flags: Panel_Flags;

	draw_func: () -> ();
	on_close:  () -> ();
}

ID :: #type u32;

WIDGET_HEADER_HEIGHT  :: 24;
WIDGET_SCROLLBAR_SIZE :: 12;

focused_uuid: ID;
