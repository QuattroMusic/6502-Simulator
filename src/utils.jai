round_up :: (n: float, base: float) -> float {
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
