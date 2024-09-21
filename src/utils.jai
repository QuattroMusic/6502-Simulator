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
