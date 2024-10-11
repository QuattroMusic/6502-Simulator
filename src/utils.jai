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

print :: (v: Any) {
	print("%\n", v);
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

display_error_panel :: (error: Error_Type) {
	ui.modal_error_type = error;
	toggle_panel(ui.modal_window);
}

_profile_ident: int;

profile_block :: () #expand {
	_profile_ident += 1;
	`_start := current_time_monotonic();
	
	`defer {
		_end := current_time_monotonic();
		
		ctx: Context;
		ctx.allocator = temp;
		push_context,defer_pop ctx;
		
		s: String_Builder;
		
		for 1.._profile_ident - 1 {
			append(*s, "\t");
		}
		name :: #procedure_name();
		delta := to_microseconds(_end - _start);
		append(*s, tprint("% took %us", name, delta));
		print(builder_to_string(*s));
		
		_profile_ident -= 1;
	}
}
