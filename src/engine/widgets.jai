button :: ($$text: string, pos: Vec2, size: Vec2, z: f32, $t: f32 = 1, it: int = 0, loc := #caller_location) -> bool {
	uuid := hash_widget(loc, it);
	p := fetch_parent();
	state, fire := widget_interaction(uuid, pos, size, z, p);

	bg_col, border_col, text_col := fetch_colors(state);

	draw_rect(pos + p.pos, size, z + p.z, bg_col);
	draw_rect_lines(pos + p.pos, size, z + 1 + p.z, border_col, t);

	s := measure_text(text, t);
	draw_text(text, pos + size / 2 - s / 2 + p.pos, z + 1 + p.z, t, text_col);

	return fire;
}

button :: (icon: Icon, pos: Vec2, size: Vec2, z: f32, $t: f32 = 1, it: int = 0, loc := #caller_location) -> bool {
	uuid := hash_widget(loc, it);
	p := fetch_parent();
	state, fire := widget_interaction(uuid, pos, size, z, p);

	bg_col, border_col, text_col := fetch_colors(state);

	draw_rect(pos + p.pos, size, z + p.z, bg_col);
	draw_rect_lines(pos + p.pos, size, z + 1 + p.z, border_col, t);

	s :: Vec2.{8.0 * t, 8.0 * t};
	draw_icon(icon, pos + size / 2 - s / 2 + p.pos, z + 1 + p.z, t, text_col);

	return fire;
}

checkbox :: ($$text: string, pos: Vec2, size: Vec2, z: f32, value: *bool, it: int = 0, loc := #caller_location) {
	s := measure_text(text, 1);
	
	uuid := hash_widget(loc, it);
	p := fetch_parent();
	state, fire := widget_interaction(uuid, pos, size + .{s.x + 12, 0}, z, p);

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
	
	if value.* || state == .PRESSED then draw_rect(pos + p.pos + .{4, 4}, size - .{8, 8}, z + p.z, bg_col);
	draw_rect_lines(pos + p.pos, size, z + p.z + 1, COLOR_LINE);
	draw_text(text, pos + p.pos + .{size.x + 8, (size.y - s.y) / 2}, z + p.z, 1, text_col);

	if fire then value.* = !value.*;
}

draw_step_hslider :: (pos: Vec2, size: Vec2, z: f32, amt: s32, value: *int, disabled: bool = false, it: int = 0, loc := #caller_location) {
	draw_rect(.{pos.x, pos.y + size.y / 2 - 1}, .{size.x, 2}, z, ifx disabled then GRAY else COLOR_LINE);

	col_main: Col = ---;
	col_step: Col = ---;

	if !disabled {
		col_main = COLOR_WIDGET_BG_NORMAL;
		col_step = COLOR_WIDGET_BORDER_NORMAL;

		uuid := hash_widget(loc, it);
		p := fetch_parent();
		state, fire := widget_interaction(uuid, pos, size, z, p);

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

		draw_rect(.{pos.x + x - 1, pos.y + size.y / 2 - s / 2}, .{2, s}, z + 1, col_step);
	}

	pos_x := pos.x + cast(f32)value.* / (amt - 1) * size.x;
	draw_rect(.{pos_x - 4, pos.y}, .{8, size.y}, z + 2, col_main);
}

draw_scrollbar :: (pos: Vec2, size: Vec2, z: f32, scroll_pos: *Vec2, scroll_size: Vec2, min_size: Vec2, max_value: Vec2, it: int = 0, loc := #caller_location) {
	x_visible := min_size.x + size.x < scroll_size.x;
	y_visible := min_size.y + size.y < scroll_size.y;

	if y_visible {
		scroll_pos_x := pos.x + size.x - WIDGET_SCROLLBAR_SIZE;
		scroll_pos_y := pos.y;
		off := ifx x_visible then cast(f32)WIDGET_SCROLLBAR_SIZE;

		uuid := hash_widget(loc, it);
		p := fetch_parent();
		state, fire := widget_interaction(uuid, .{scroll_pos_x, scroll_pos_y}, .{WIDGET_SCROLLBAR_SIZE, size.y - off}, z, p);
		
		if mouse_dz && !is_key_down(KEY_SHIFT) && can_interact_with_widget(uuid, pos, size, z, p){
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

		draw_rect(.{scroll_pos_x, scroll_pos_y}, .{WIDGET_SCROLLBAR_SIZE, size.y}, z, COLOR_WIDGET_BG_NORMAL);
		draw_rect(.{scroll_pos_x, floor(scroll_pos_y + aspect_ratio * scroll_pos.*.y)}, .{WIDGET_SCROLLBAR_SIZE, bar_height}, z + 1, bar_col);
	}

	if x_visible {
		scroll_pos_x := pos.x;
		scroll_pos_y := pos.y + size.y - WIDGET_SCROLLBAR_SIZE;
		off := ifx y_visible then cast(f32)WIDGET_SCROLLBAR_SIZE;

		uuid := hash_widget(loc, it + 1);
		p := fetch_parent();
		state, fire := widget_interaction(uuid, .{scroll_pos_x, scroll_pos_y}, .{size.x - off, WIDGET_SCROLLBAR_SIZE}, z, p);
		
		if mouse_dz && is_key_down(KEY_SHIFT) && can_interact_with_widget(uuid, pos, size, z, p){
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

		draw_rect(.{scroll_pos_x, scroll_pos_y}, .{size.x, WIDGET_SCROLLBAR_SIZE}, z, COLOR_WIDGET_BG_NORMAL);
		draw_rect(.{floor(scroll_pos_x + aspect_ratio * scroll_pos.*.x), scroll_pos_y}, .{bar_width, WIDGET_SCROLLBAR_SIZE}, z + 1, bar_col);
	}
}

window :: (uuid: ID, p: *Panel) {
	// handle window movement
	if !p.modal {
		if can_interact_with_widget(uuid, p.pos, .{p.size.x, WIDGET_HEADER_HEIGHT}, p.z, .{}) {
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
			p.pos.y = max(p.pos.y, HEADER_HEIGHT);  // clamp because of window header
		}
		if is_mouse_released(0) then p.pressed = false;
	} else {
		p.pos.x = (vp.width - p.size.x) / 2;
		p.pos.y = (vp.height - p.size.y) / 2;
	}
	
	parent: Parent_Panels = ---;
	parent.pos = p.pos + .{0, WIDGET_HEADER_HEIGHT};
	parent.z = p.z;
	array_add(*parent_panels, parent);

	fire := button(.CLOSE, .{p.size.x - WIDGET_HEADER_HEIGHT, -WIDGET_HEADER_HEIGHT}, .{WIDGET_HEADER_HEIGHT, WIDGET_HEADER_HEIGHT}, z = 1, it = uuid);

	draw_rect(p.pos, p.size, p.z, COLOR_WIDGET_BG_NORMAL);
	draw_rect_lines(p.pos, p.size, p.z + 1, COLOR_WIDGET_BORDER_NORMAL);
	draw_rect(p.pos + .{0, WIDGET_HEADER_HEIGHT - 1}, .{p.size.x, 1}, p.z + 1, COLOR_WIDGET_BORDER_NORMAL);
	draw_text(p.name, p.pos + .{9, 8}, p.z + 1, 1, COLOR_TEXT_NORMAL);
	
	if p.modal then fire |= is_key_pressed(KEY_ESC);
	if fire    then {
		p.*.visible = false;
		if p.on_close then p.on_close();
	}

	p.draw_func();

	parent_panels.count -= 1;
}

child_begin :: ($$text: string, pos: Vec2, size: Vec2, z: f32) {
	padding :: 4;

	p := fetch_parent();

	draw_rect(pos + p.pos, .{padding, 1}, z + p.z, COLOR_LINE);
	draw_rect(pos + p.pos, .{1, size.y}, z + p.z, COLOR_LINE);
	draw_rect(pos + p.pos + .{0, size.y - 1}, .{size.x, 1}, z + p.z, COLOR_LINE);
	draw_rect(pos + p.pos + .{size.x - 1, 0}, .{1, size.y}, z + p.z, COLOR_LINE);

	s :: 1;
	m := measure_text(text, s);
	draw_text(text, pos + p.pos + .{padding + 4, -m.y / 2}, z + p.z, s, COLOR_LINE);

	draw_rect(pos + p.pos + .{padding + 8 + m.x, 0}, .{size.x - padding - 8 - m.x, 1}, z + p.z, COLOR_LINE);

	parent: Parent_Panels;
	parent.pos = pos + p.pos;
	parent.z = z + p.z;
	array_add(*parent_panels, parent);
}

child_end :: () {
	parent_panels.count -= 1;
}

create_new_window :: (draw: () -> (), name: string, size: Vec2, on_close: () -> () = null, modal := false, it: int = 0, loc := #caller_location) -> ID {
	uuid := hash_widget(loc, it);
	widget, newly_added := find_or_add(*panels, uuid);
	assert(newly_added);

	widget.*.size = size;
	widget.*.draw_func = draw;
	widget.*.visible = false;
	widget.*.name = name;
	widget.*.modal = modal;
	widget.*.on_close = on_close;

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
		if it.p.visible && it.p.modal {
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

toggle_panel :: (uuid: ID, pos: Vec2 = .{}) {
	p := table_find_pointer(*panels, uuid);
	
	#if DEBUG then assert(p != null);
	
	p.*.visible = !p.*.visible;
	p.*.pos = pos;
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

fetch_parent :: () -> Parent_Panels {
	p: Parent_Panels;

	if parent_panels.count {
		p = parent_panels[parent_panels.count - 1];
	}

	return p;
}

#scope_file

can_interact_with_widget :: (uuid: ID, pos: Vec2, size: Vec2, z: f32, p: Parent_Panels) -> bool {
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

fetch_colors :: (state: Interaction_State) -> (main: Col, border: Col, text: Col) {
	if #complete state == {
		case .NORMAL;  return COLOR_WIDGET_BG_NORMAL,  COLOR_WIDGET_BORDER_NORMAL,  COLOR_TEXT_NORMAL;
		case .HOVER;   return COLOR_WIDGET_BG_HOVERED, COLOR_WIDGET_BORDER_HOVERED, COLOR_TEXT_HOVERED;
		case .PRESSED; return COLOR_WIDGET_BG_PRESSED, COLOR_WIDGET_BORDER_PRESSED, COLOR_TEXT_PRESSED;
	}
}

widget_interaction :: (uuid: ID, pos: Vec2, size: Vec2, z: f32, p: Parent_Panels) -> (Interaction_State, fire: bool) {
	state: Interaction_State = .NORMAL;

	fire := false;

	if can_interact_with_widget(uuid, pos, size, z, p) {
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

hash_widget :: (loc: Source_Code_Location, it: int) -> ID {
	h1 := fnv1a_hash(loc.fully_pathed_filename.data, loc.fully_pathed_filename.count);
	h2 := knuth_hash(cast,no_check(u64)loc.line_number);
	h3 := knuth_hash(cast,no_check(u64)it);

	return cast,no_check(ID)(h1 ^ h2 ^ h3);
}

fade_value: f32;

Interaction_State :: enum {
	NORMAL;
	HOVER;
	PRESSED;
}

Panel :: struct {
	pos: Vec2;
	size: Vec2;
	z: f32;
	pressed_pos: Vec2;
	pressed: bool;
	visible: bool;
	modal: bool;
	name: string;
	draw_func: () -> ();
	on_close:  () -> ();
}

Parent_Panels :: struct {
	pos: Vec2;
	z: f32;
}

panels: Table(ID, Panel);

parent_panels: [..]Parent_Panels;

modal_visible: bool;

#scope_export
ID :: #type u32;

WIDGET_HEADER_HEIGHT  :: 24;
WIDGET_SCROLLBAR_SIZE :: 12;

focused_uuid: ID;
