round_up :: (n: f32, $base: f32) -> f32 {
	#assert base != 0 "base must not be zero";
	
	if n != 0 {
		sign := ifx n > 0 then 1 else -1;
		n *= sign;
		n /= base;
		n = (cast(s64)ceil(n)) * base;
		n *= sign;
	}
	return n;
}

round_down :: (x: f32) -> f32 {
	// ignoring negative numbers
	return cast(f32, cast(s32, x));
}

round_ignoring_negative :: inline (x: f32) -> f32 {
	// normal round is
	// ifx x >= 0 then floor(x + 0.5) else ceil(x - 0.5);
	// but if we ignore negative, we'll get
	// floor(x + 0.5);
	// but again, since floor is ignoring negative
	return round_down(x + 0.5);
}

print :: (v: Any) {
	print("%\n", v);
}

printv :: (v: ..Any) {
	for v {
		print("% ", it);
	}
	write_string("\n");
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

display_error_window :: (error: Error_Type, title: string) {
	ui.modal_error_type = error;
	ui.modal_window.name = title;
	toggle_window(ui.modal_window, centered = true);
}

RGB_to_HSV :: (c: Col) -> Vec3 {
	r := c.r / 255.0;
	g := c.g / 255.0;
	b := c.b / 255.0;
	
	h, s, v: f32 = ---;
	
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

operator == :: inline (a: Col, b: Col) -> bool {
	return a.data == b.data;
}

is_inside_rect :: (p: Vec2, pos: Vec2, size: Vec2) -> bool {
	return (pos.x <= p.x) && (p.x < (pos.x + size.x)) && (pos.y <= p.y) && (p.y < (pos.y + size.y));
}

is_mouse_inside_rect :: inline (pos: Vec2, size: Vec2) -> bool {
	return is_inside_rect(.{cast(f32, mouse_x), cast(f32, mouse_y)}, pos, size);
}

clamp :: (v: Vec3, x: f32, y: f32) -> Vec3 {
	return .{clamp(v.x, x, y), clamp(v.y, x, y), clamp(v.z, x, y)};
}

frac :: (v: Vec3) -> Vec3 {
	return .{frac(v.x), frac(v.y), frac(v.z)};
}

_profile_ident: s64;

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
