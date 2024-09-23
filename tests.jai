print_data :: () {
	using engine;
	using engine.flags;
	print("A: % - X: % - Y: % - PC: % - S: % - ", A, X, Y, PC, S);
	print("[NV-BDIZC]: [%1%2-%3%4%5%6%7]\n\n", cast(u8)N, cast(u8)V, cast(u8)B, cast(u8)D, cast(u8)I, cast(u8)Z, cast(u8)C);
}

test1 :: () {
	engine.ROM[0x7FFD] = 0x80;
	update_PC(0, read_address(0xFFFC));
	
	// engine.ROM[0] = 255;
	// engine.ROM[1] = 1;
	// engine.ROM[2] = 0;
	
	// exec_operation(.ADC_IMM);
	// exec_operation(.ADC_IMM);
	// exec_operation(.ADC_IMM);
	
	// engine.A = 128;
	// engine.ROM[0] = 1;
	// exec_operation(.SBC_IMM);
	
	// engine.A = 10;
	// engine.ROM[0] = 11;
	// exec_operation(.CMP_IMM);
	
	print_data();
}

run_all_tests :: () {
	test1();
	
	while true {}
}
