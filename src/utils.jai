round_up :: (n: f32, base: f32) -> f32 {
	if base != 0 && n != 0 {
		sign := ifx n > 0 then 1 else -1;
		n *= sign;
		n /= base;
		n = (cast(int)ceil(n)) * base;
		n *= sign;
	}
	return n;
}

round_down :: (x: f32) -> f32 {
	// ignoring negative numbers
	return cast(f32, cast(s32, x));
}

print :: (v: Any) {
	print("%\n", v);
}

printv :: (v: ..Any) {
	for v {
		print("% ", it);
	}
	print("");
}

round_number_power_of_2 :: (n: type_of(Resizable_Array.count)) -> type_of(Resizable_Array.count) {
	out: type_of(Resizable_Array.count);
	out = 32;  // min size
	while out < n {
		out *= 2;
	}
	return out;
}

count_digits :: (x: u32) -> u32 {
	n: u32 = 1;
	while x / 10 {
		x /= 10;
		n += 1;
	}
	return n;
}

split_from_right :: (s: string, c: u8) -> right: string {
	out: string;
	amt := s.count;
	
	while amt > 0 {
		amt -= 1;
		
		if s[amt] == c {
			out.count = s.count - amt - 1;
			out.data = s.data + amt + 1;
			return out;
		}
	}
	
	return s;
}

string_length :: (d: *u8) -> s64 {
	it: int;
	while d[it] it += 1;
	return it;
}

display_error_panel :: (error: Error_Type, title: string) {
	ui.modal_error_type = error;
	set_panel_name(ui.modal_panel, title);
	toggle_panel(ui.modal_panel);
}

RGB_to_HSV :: (c: Col) -> Vec3 {
	r := c.r / 255.0;
	g := c.g / 255.0;
	b := c.b / 255.0;
	
	h, s, v: f32;
	
	cmax := max(r, max(g, b));
	cmin := min(r, min(g, b));
	delta := cmax - cmin;
	
	if delta < 0.0001 {
		return .{0, 0, cmax};
	}
	
	if cmax != 0 {
		s = delta / cmax;
	} else {
		return .{0, 0, cmax};
	}
	
	if cmax == r {
		h = fmod_cycling((g - b) / delta, 6) / 6.0;
	} else if cmax == g {
		h = ((b - r) / delta + 2) / 6.0;
	} else if cmax == b {
		h = ((r - g) / delta + 4) / 6.0;
	} else {
		h = 1.0;
	}
	
	s = ifx cmax == 0 then 0 else delta / cmax;
	v = cmax;
	return .{h, s, v};
}

HSV_to_RGB :: (col: Vec3) -> Col {
	if col.y == 0 return .{cast(u8)(col.z * 255), cast(u8)(col.z * 255), cast(u8)(col.z * 255), 255};
	
	h := col.x * 6.0;
	f := h - cast(s32)h;
	
	p := col.z * (1.0 - col.y);
	q := col.z * (1.0 - (col.y * f));
	t := col.z * (1.0 - (col.y * (1.0 - f)));
	
	if cast(s32)h == {
		case 1; return .{cast(u8)(q     * 255), cast(u8)(col.z * 255), cast(u8)(p     * 255), 255};
		case 2; return .{cast(u8)(p     * 255), cast(u8)(col.z * 255), cast(u8)(t     * 255), 255};
		case 3; return .{cast(u8)(p     * 255), cast(u8)(q     * 255), cast(u8)(col.z * 255), 255};
		case 4; return .{cast(u8)(t     * 255), cast(u8)(p     * 255), cast(u8)(col.z * 255), 255};
		case 5; return .{cast(u8)(col.z * 255), cast(u8)(p     * 255), cast(u8)(q     * 255), 255};
		case;   return .{cast(u8)(col.z * 255), cast(u8)(t     * 255), cast(u8)(p     * 255), 255};
	}
}

operator * :: (col: Col, s: f32) -> Col #symmetric {
	out: Col = ---;
	out.r = cast(u8)(col.r * s);
	out.g = cast(u8)(col.g * s);
	out.b = cast(u8)(col.b * s);
	out.a = col.a;
	return out;
}

operator + :: (a: Col, b: Col) -> Col {
	out: Col = ---;
	out.r = a.r + b.r;
	out.g = a.g + b.g;
	out.b = a.b + b.b;
	out.a = a.a + b.a;
	return out;
}

operator == :: (a: Col, b: Col) -> bool {
	return a.data == b.data;
}

is_mouse_inside_rect :: (pos: Vec2, size: Vec2) -> bool {
	return (xx pos.x <= mouse_x) && (mouse_x < xx (pos.x + size.x)) && (xx pos.y <= mouse_y) && (mouse_y < xx (pos.y + size.y));
}

_profile_ident: int;

profile_block :: () #expand {
	`_start := current_time_monotonic();
	_profile_ident += 1;
	
	`defer {
		_end := current_time_monotonic();
		
		ctx: #Context;
		ctx.allocator = temp;
		push_context,defer_pop ctx;
		
		s: String_Builder;
		
		for 1.._profile_ident - 1 {
			append(*s, "\t");
		}
		name :: #procedure_name();
		delta := to_nanoseconds(_end - _start);
		append(*s, tprint("% took %us", name, delta / 1000.0));
		print(builder_to_string(*s));
		
		_profile_ident -= 1;
	}
}
