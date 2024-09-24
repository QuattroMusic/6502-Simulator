#scope_file
print_data :: () {
	using engine;
	using engine.flags;
	print("A: % - X: % - Y: % - PC: % - S: % - ", A, X, Y, PC, S);
	print("[NV-BDIZC]: [%1%2-%3%4%5%6%7]\n\n", cast(u8)N, cast(u8)V, cast(u8)B, cast(u8)D, cast(u8)I, cast(u8)Z, cast(u8)C);
}

assert_flags :: (C: u8, V: u8, N: u8, Z: u8, loc := #caller_location) {
	using engine;
	passed := true;
	
	if(flags.C != cast(bool)C) then passed = false;
	if(flags.V != cast(bool)V) then passed = false;
	if(flags.N != cast(bool)N) then passed = false;
	if(flags.Z != cast(bool)Z) then passed = false;
	
	if(!passed) {
		print("Flags doesn't match!\n");
		print("[CVNZ]: [%1%2%3%4] expected [%5%6%7%8]\n", cast(u8)flags.C, cast(u8)flags.V, cast(u8)flags.N, cast(u8)flags.Z, C, V, N, Z);
		print("Line %\n", loc.line_number);
		while true {}
	}
}

assert_reg :: (A: u8 = 0, X: u8 = 0, Y: u8 = 0, S: u8 = 0, loc := #caller_location) {
	passed := true;
	
	if(engine.A != A) then passed = false;
	if(engine.X != X) then passed = false;
	if(engine.Y != Y) then passed = false;
	if(engine.S != S) then passed = false;
	
	if(!passed) {
		print("Registers doesn't match!\n");
		print("A = % expected %\n", engine.A, A);
		print("X = % expected %\n", engine.X, X);
		print("Y = % expected %\n", engine.Y, Y);
		print("S = % expected %\n", engine.S, S);
		while true {}
	}
}

add_sub_CVZN :: () {
	virtual_exec_operation(.CLC);
	virtual_exec_operation(.LDA_IMM, 0x01);
	virtual_exec_operation(.ADC_IMM, 0x01);
	assert_flags(C = 0, V = 0, N = 0, Z = 0);
	
	virtual_exec_operation(.CLC);
	virtual_exec_operation(.LDA_IMM, 0x01);
	virtual_exec_operation(.ADC_IMM, 0xFF);
	assert_flags(C = 1, V = 0, N = 0, Z = 1);
	
	virtual_exec_operation(.CLC);
	virtual_exec_operation(.LDA_IMM, 0x7F);
	virtual_exec_operation(.ADC_IMM, 0x01);
	assert_flags(C = 0, V = 1, N = 1, Z = 0);
	
	virtual_exec_operation(.CLC);
	virtual_exec_operation(.LDA_IMM, 0x80);
	virtual_exec_operation(.ADC_IMM, 0xFF);
	assert_flags(C = 1, V = 1, N = 0, Z = 0);

	virtual_exec_operation(.SEC);
	virtual_exec_operation(.LDA_IMM, 0x00);
	virtual_exec_operation(.SBC_IMM, 0x01);
	assert_flags(C = 0, V = 0, N = 1, Z = 0);
	
	virtual_exec_operation(.SEC);
	virtual_exec_operation(.LDA_IMM, 0x80);
	virtual_exec_operation(.SBC_IMM, 0x01);
	assert_flags(C = 1, V = 1, N = 0, Z = 0);
	
	virtual_exec_operation(.SEC);
	virtual_exec_operation(.LDA_IMM, 0x7F);
	virtual_exec_operation(.SBC_IMM, 0xFF);
	assert_flags(C = 0, V = 1, N = 1, Z = 0);
	
	virtual_exec_operation(.SEC);
	virtual_exec_operation(.LDA_IMM, 0x00);
	virtual_exec_operation(.SBC_IMM, 0x80);
	assert_flags(C = 0, V = 1, N = 1, Z = 0);
}

#scope_export
run_all_tests :: () {
	// tests took from here https://github.com/blitzcode/neskell/tree/master/src/tests/unit
	cpu_init();
	add_sub_CVZN();
	
	while true {}
}
