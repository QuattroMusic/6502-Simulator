#scope_file
passed_tests: s64;
tests_cumulative: s64;

print_data :: () {
	using engine;
	using engine.flags;
	print("A: % - X: % - Y: % - PC: % - S: % - ", A, X, Y, PC, S);
	print("[NV-BDIZC]: [%1%2-%3%4%5%6%7]\n\n", cast(u8)N, cast(u8)V, cast(u8)B, cast(u8)D, cast(u8)I, cast(u8)Z, cast(u8)C);
}

assert_flags :: (C: u8 = 0, V: u8 = 0, N: u8 = 0, Z: u8 = 0, D: u8 = 0, loc := #caller_location) {
	using engine;
	passed := true;
	
	if(flags.C != cast(bool)C) then passed = false;
	if(flags.V != cast(bool)V) then passed = false;
	if(flags.N != cast(bool)N) then passed = false;
	if(flags.Z != cast(bool)Z) then passed = false;
	if(flags.D != cast(bool)D) then passed = false;
	
	if(!passed) {
		print("Flags doesn't match!\n");
		print("[CVNZD]: [%1%2%3%4%5] expected [%6%7%8%9%10]\n", cast(u8)flags.C, cast(u8)flags.V, cast(u8)flags.N, cast(u8)flags.Z, cast(u8)flags.D, C, V, N, Z, D);
		print("Line %\n", loc.line_number);
		while true {}
	}
	passed_tests += 1;
}

assert_reg :: (A: u8 = 0, X: u8 = 0, Y: u8 = 0, S: u8 = 0xFF, loc := #caller_location) {
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
		print("Line %\n", loc.line_number);
		while true {}
	}
	passed_tests += 1;
}

assert_RAM :: (pos: u16, value: u8, loc := #caller_location) {
	if engine.RAM[pos] != value {
		print("RAM doesn't match!\n");
		print("RAM[%] = % expected %\n", pos, engine.RAM[pos], value);
		print("Line %\n", loc.line_number);
		while true {}
	}
	passed_tests += 1;
}

test_handler :: (name: string) #expand {
	start_time := current_time_monotonic();
	`defer {
		end_time := current_time_monotonic();
		delta := end_time - start_time;
		print("Passed % tests '%' in %us\n", passed_tests, name, to_microseconds(delta));
		tests_cumulative += passed_tests;
		passed_tests = 0;
		cpu_reset(virtual = true);
	}
}

test_ADD :: () {
	test_handler("ADD");
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
}

test_AND :: () {
	test_handler("AND");
	for x: 0..0xFF {
		for y: 0..0xFF {
			virtual_exec_operation(.LDA_IMM, xx x);
			virtual_exec_operation(.AND_IMM, xx y);
			res := cast,trunc(u8)(x & y);
			assert_reg(A = res);
			assert_flags(Z = cast(u8)(res == 0), N = cast(u8)((cast,no_check(s8)res) < 0));
		}
		cpu_reset(virtual = true);  // this, or the ROM will overflow
	}
}

test_ASL :: () {
	test_handler("ASL");
	virtual_exec_operation(.CLC);
	virtual_exec_operation(.LDA_IMM, 0x00);
	virtual_exec_operation(.ASL_ACC);
	assert_reg(A = 0x00);
	assert_flags(C = 0, Z = 1, N = 0);
	
	virtual_exec_operation(.SEC);
	virtual_exec_operation(.LDA_IMM, 0x00);
	virtual_exec_operation(.ASL_ACC);
	assert_reg(A = 0x00);
	assert_flags(C = 0, Z = 1, N = 0);
	
	virtual_exec_operation(.CLC);
	virtual_exec_operation(.LDA_IMM, 0x01);
	virtual_exec_operation(.ASL_ACC);
	assert_reg(A = 0x02);
	assert_flags(C = 0, Z = 0, N = 0);
	
	virtual_exec_operation(.CLC);
	virtual_exec_operation(.LDA_IMM, 0x02);
	virtual_exec_operation(.ASL_ACC);
	assert_reg(A = 0x04);
	assert_flags(C = 0, Z = 0, N = 0);
	
	virtual_exec_operation(.CLC);
	virtual_exec_operation(.LDA_IMM, 0x04);
	virtual_exec_operation(.ASL_ACC);
	assert_reg(A = 0x08);
	assert_flags(C = 0, Z = 0, N = 0);
	
	virtual_exec_operation(.CLC);
	virtual_exec_operation(.LDA_IMM, 0x08);
	virtual_exec_operation(.ASL_ACC);
	assert_reg(A = 0x10);
	assert_flags(C = 0, Z = 0, N = 0);
	
	virtual_exec_operation(.CLC);
	virtual_exec_operation(.LDA_IMM, 0x10);
	virtual_exec_operation(.ASL_ACC);
	assert_reg(A = 0x20);
	assert_flags(C = 0, Z = 0, N = 0);
	
	virtual_exec_operation(.CLC);
	virtual_exec_operation(.LDA_IMM, 0x20);
	virtual_exec_operation(.ASL_ACC);
	assert_reg(A = 0x40);
	assert_flags(C = 0, Z = 0, N = 0);
	
	virtual_exec_operation(.CLC);
	virtual_exec_operation(.LDA_IMM, 0x40);
	virtual_exec_operation(.ASL_ACC);
	assert_reg(A = 0x80);
	assert_flags(C = 0, Z = 0, N = 1);
	
	virtual_exec_operation(.CLC);
	virtual_exec_operation(.LDA_IMM, 0x80);
	virtual_exec_operation(.ASL_ACC);
	assert_reg(A = 0x00);
	assert_flags(C = 1, Z = 1, N = 0);
}

test_BIT :: () {
	test_handler("BIT");
	
	virtual_exec_operation(.LDA_IMM, 0x22);
	virtual_exec_operation(.STA_ZPG, 0x00);
	virtual_exec_operation(.BIT_ZPG, 0x00);
	
	assert_reg(A = 0x22);
	assert_flags(Z = 0, N = 0, V = 0);
	
	virtual_exec_operation(.LDA_IMM, 0xDD);  // ~0x22
	virtual_exec_operation(.BIT_ZPG, 0x00);
	
	assert_reg(A = 0xDD);
	assert_flags(Z = 1, N = 0, V = 0);
	
	virtual_exec_operation(.LDA_IMM, 0x80);
	virtual_exec_operation(.STA_ZPG, 0x00);
	virtual_exec_operation(.BIT_ZPG, 0x00);
	assert_flags(Z = 0, N = 1, V = 0);
	
	virtual_exec_operation(.LDA_IMM, 0x40);
	virtual_exec_operation(.STA_ZPG, 0x00);
	virtual_exec_operation(.BIT_ZPG, 0x00);
	assert_flags(Z = 0, N = 0, V = 1);
}

test_CMP :: () {
	test_handler("CMP");
	
	virtual_exec_operation(.LDA_IMM, 0x10);
	virtual_exec_operation(.CMP_IMM, 0x0F);
	assert_flags(Z = 0, N = 0, C = 1);
	virtual_exec_operation(.LDA_IMM, 0x10);
	virtual_exec_operation(.CMP_IMM, 0x10);
	assert_flags(Z = 1, N = 0, C = 1);
	virtual_exec_operation(.LDA_IMM, 0x10);
	virtual_exec_operation(.CMP_IMM, 0x11);
	assert_flags(Z = 0, N = 1, C = 0);
	
	virtual_exec_operation(.LDA_IMM, 0x80);
	virtual_exec_operation(.CMP_IMM, 0x7F);
	assert_flags(Z = 0, N = 0, C = 1);
	virtual_exec_operation(.LDA_IMM, 0x80);
	virtual_exec_operation(.CMP_IMM, 0x80);
	assert_flags(Z = 1, N = 0, C = 1);
	virtual_exec_operation(.LDA_IMM, 0x80);
	virtual_exec_operation(.CMP_IMM, 0x81);
	assert_flags(Z = 0, N = 1, C = 0);
	
	virtual_exec_operation(.LDX_IMM, 0x10);
	virtual_exec_operation(.CPX_IMM, 0x0F);
	assert_flags(Z = 0, N = 0, C = 1);
	virtual_exec_operation(.LDX_IMM, 0x10);
	virtual_exec_operation(.CPX_IMM, 0x10);
	assert_flags(Z = 1, N = 0, C = 1);
	virtual_exec_operation(.LDX_IMM, 0x10);
	virtual_exec_operation(.CPX_IMM, 0x11);
	assert_flags(Z = 0, N = 1, C = 0);
	
	virtual_exec_operation(.LDY_IMM, 0x10);
	virtual_exec_operation(.CPY_IMM, 0x0F);
	assert_flags(Z = 0, N = 0, C = 1);
	virtual_exec_operation(.LDY_IMM, 0x10);
	virtual_exec_operation(.CPY_IMM, 0x10);
	assert_flags(Z = 1, N = 0, C = 1);
	virtual_exec_operation(.LDY_IMM, 0x10);
	virtual_exec_operation(.CPY_IMM, 0x11);
	assert_flags(Z = 0, N = 1, C = 0);
}

test_DEC :: () {
	test_handler("DEC");
	
	virtual_exec_operation(.LDA_IMM, 0x10);
	virtual_exec_operation(.STA_ZPG, 0x01);
	virtual_exec_operation(.DEC_ZPG, 0x01);
	assert_RAM(pos = 0x01, value = 0x0F);
	assert_flags(N = 0, Z = 0);
	
	virtual_exec_operation(.LDA_IMM, 0x80);
	virtual_exec_operation(.STA_ZPG, 0x01);
	virtual_exec_operation(.DEC_ZPG, 0x01);
	assert_RAM(pos = 0x01, value = 0x7F);
	assert_flags(N = 0, Z = 0);
	
	virtual_exec_operation(.LDA_IMM, 0x81);
	virtual_exec_operation(.STA_ZPG, 0x01);
	virtual_exec_operation(.DEC_ZPG, 0x01);
	assert_RAM(pos = 0x01, value = 0x80);
	assert_flags(N = 1, Z = 0);

	virtual_exec_operation(.LDA_IMM, 0x01);
	virtual_exec_operation(.STA_ZPG, 0x01);
	virtual_exec_operation(.DEC_ZPG, 0x01);
	assert_RAM(pos = 0x01, value = 0x00);
	assert_flags(N = 0, Z = 1);
	
	virtual_exec_operation(.LDA_IMM, 0x00);
	virtual_exec_operation(.STA_ZPG, 0x01);
	virtual_exec_operation(.DEC_ZPG, 0x01);
	assert_RAM(pos = 0x01, value = 0xFF);
	assert_flags(N = 1, Z = 0);
	
	cpu_reset(virtual = true);
	
	virtual_exec_operation(.LDX_IMM, 0x10);
	virtual_exec_operation(.DEX);
	assert_reg(X = 0x0F);
	assert_flags(N = 0, Z = 0);
	
	virtual_exec_operation(.LDX_IMM, 0x81);
	virtual_exec_operation(.DEX);
	assert_reg(X = 0x80);
	assert_flags(N = 1, Z = 0);
	
	virtual_exec_operation(.LDX_IMM, 0x80);
	virtual_exec_operation(.DEX);
	assert_reg(X = 0x7F);
	assert_flags(N = 0, Z = 0);
	
	virtual_exec_operation(.LDX_IMM, 0x01);
	virtual_exec_operation(.DEX);
	assert_reg(X = 0x00);
	assert_flags(N = 0, Z = 1);
	
	virtual_exec_operation(.LDX_IMM, 0x00);
	virtual_exec_operation(.DEX);
	assert_reg(X = 0xFF);
	assert_flags(N = 1, Z = 0);
	
	cpu_reset(virtual = true);
	
	virtual_exec_operation(.LDY_IMM, 0x10);
	virtual_exec_operation(.DEY);
	assert_reg(Y = 0x0F);
	assert_flags(N = 0, Z = 0);
	
	virtual_exec_operation(.LDY_IMM, 0x81);
	virtual_exec_operation(.DEY);
	assert_reg(Y = 0x80);
	assert_flags(N = 1, Z = 0);
	
	virtual_exec_operation(.LDY_IMM, 0x80);
	virtual_exec_operation(.DEY);
	assert_reg(Y = 0x7F);
	assert_flags(N = 0, Z = 0);
	
	virtual_exec_operation(.LDY_IMM, 0x01);
	virtual_exec_operation(.DEY);
	assert_reg(Y = 0x00);
	assert_flags(N = 0, Z = 1);
	
	virtual_exec_operation(.LDY_IMM, 0x00);
	virtual_exec_operation(.DEY);
	assert_reg(Y = 0xFF);
	assert_flags(N = 1, Z = 0);
}

test_EOR :: () {
	test_handler("EOR");
	for x: 0..0xFF {
		for y: 0..0xFF {
			virtual_exec_operation(.LDA_IMM, xx x);
			virtual_exec_operation(.EOR_IMM, xx y);
			res := cast,trunc(u8)(x ^ y);
			assert_reg(A = res);
			assert_flags(Z = cast(u8)(res == 0), N = cast(u8)((cast,no_check(s8)res) < 0));
		}
		cpu_reset(virtual = true);  // this, or the ROM will overflow
	}
}

test_INC :: () {
	test_handler("INC");
	
	virtual_exec_operation(.LDA_IMM, 0x10);
	virtual_exec_operation(.STA_ZPG, 0x01);
	virtual_exec_operation(.INC_ZPG, 0x01);
	assert_RAM(pos = 0x01, value = 0x11);
	assert_flags(N = 0, Z = 0);
	
	virtual_exec_operation(.LDA_IMM, 0x7F);
	virtual_exec_operation(.STA_ZPG, 0x01);
	virtual_exec_operation(.INC_ZPG, 0x01);
	assert_RAM(pos = 0x01, value = 0x80);
	assert_flags(N = 1, Z = 0);
	
	virtual_exec_operation(.LDA_IMM, 0xFF);
	virtual_exec_operation(.STA_ZPG, 0x01);
	virtual_exec_operation(.INC_ZPG, 0x01);
	assert_RAM(pos = 0x01, value = 0x00);
	assert_flags(N = 0, Z = 1);
	
	cpu_reset(virtual = true);
	
	virtual_exec_operation(.LDX_IMM, 0x00);
	virtual_exec_operation(.INX);
	assert_reg(X = 0x01);
	assert_flags(N = 0, Z = 0);
	
	virtual_exec_operation(.LDX_IMM, 0xFF);
	virtual_exec_operation(.INX);
	assert_reg(X = 0x00);
	assert_flags(N = 0, Z = 1);
	
	virtual_exec_operation(.LDX_IMM, 0x7F);
	virtual_exec_operation(.INX);
	assert_reg(X = 0x80);
	assert_flags(N = 1, Z = 0);
	
	cpu_reset(virtual = true);
	
	virtual_exec_operation(.LDY_IMM, 0x00);
	virtual_exec_operation(.INY);
	assert_reg(Y = 0x01);
	assert_flags(N = 0, Z = 0);
	
	virtual_exec_operation(.LDY_IMM, 0xFF);
	virtual_exec_operation(.INY);
	assert_reg(Y = 0x00);
	assert_flags(N = 0, Z = 1);
	
	virtual_exec_operation(.LDY_IMM, 0x7F);
	virtual_exec_operation(.INY);
	assert_reg(Y = 0x80);
	assert_flags(N = 1, Z = 0);
}

test_JMP :: () {
	test_handler("JMP");
	
	cpu_reset(virtual = true);

	virtual_write_ROM(engine.PC    , xx Opcode.JMP_ABS);
	virtual_write_ROM(engine.PC + 1, xx ((engine.PC + 4 ) & 0xFF));
	virtual_write_ROM(engine.PC + 2, xx (engine.PC >> 8));
	virtual_write_ROM(engine.PC + 3, xx Opcode.CLD);
	virtual_write_ROM(engine.PC + 4, xx Opcode.SED);
	
	next_instruction();
	next_instruction();
	
	assert_flags(D = 1);
	virtual_exec_operation(.CLD);
	
	virtual_write_ROM(engine.PC    , xx Opcode.JMP_ABS);
	virtual_write_ROM(engine.PC + 1, xx ((engine.PC + 4 ) & 0xFF));
	virtual_write_ROM(engine.PC + 2, xx (engine.PC >> 8));
	virtual_write_ROM(engine.PC + 3, xx Opcode.SED);
	virtual_write_ROM(engine.PC + 4, xx Opcode.CLD);
	
	next_instruction();
	next_instruction();
	assert_flags(D = 0);
}

test_LSR :: () {
	test_handler("LSR");
	
	virtual_exec_operation(.CLC);
	virtual_exec_operation(.LDA_IMM, 0x00);
	virtual_exec_operation(.LSR_ACC);
	assert_reg(A = 0x00);
	assert_flags(C = 0, Z = 1, N = 0);
	
	virtual_exec_operation(.SEC);
	virtual_exec_operation(.LDA_IMM, 0x00);
	virtual_exec_operation(.LSR_ACC);
	assert_reg(A = 0x00);
	assert_flags(C = 0, Z = 1, N = 0);
	
	virtual_exec_operation(.CLC);
	virtual_exec_operation(.LDA_IMM, 0x01);
	virtual_exec_operation(.LSR_ACC);
	assert_reg(A = 0x00);
	assert_flags(C = 1, Z = 1, N = 0);
	
	virtual_exec_operation(.CLC);
	virtual_exec_operation(.LDA_IMM, 0x02);
	virtual_exec_operation(.LSR_ACC);
	assert_reg(A = 0x01);
	assert_flags(C = 0, Z = 0, N = 0);
	
	virtual_exec_operation(.CLC);
	virtual_exec_operation(.LDA_IMM, 0x04);
	virtual_exec_operation(.LSR_ACC);
	assert_reg(A = 0x02);
	assert_flags(C = 0, Z = 0, N = 0);
	
	virtual_exec_operation(.CLC);
	virtual_exec_operation(.LDA_IMM, 0x08);
	virtual_exec_operation(.LSR_ACC);
	assert_reg(A = 0x04);
	assert_flags(C = 0, Z = 0, N = 0);
	
	virtual_exec_operation(.CLC);
	virtual_exec_operation(.LDA_IMM, 0x10);
	virtual_exec_operation(.LSR_ACC);
	assert_reg(A = 0x08);
	assert_flags(C = 0, Z = 0, N = 0);
	
	virtual_exec_operation(.CLC);
	virtual_exec_operation(.LDA_IMM, 0x20);
	virtual_exec_operation(.LSR_ACC);
	assert_reg(A = 0x10);
	assert_flags(C = 0, Z = 0, N = 0);
	
	virtual_exec_operation(.CLC);
	virtual_exec_operation(.LDA_IMM, 0x40);
	virtual_exec_operation(.LSR_ACC);
	assert_reg(A = 0x20);
	assert_flags(C = 0, Z = 0, N = 0);
	
	virtual_exec_operation(.CLC);
	virtual_exec_operation(.LDA_IMM, 0x80);
	virtual_exec_operation(.LSR_ACC);
	assert_reg(A = 0x40);
	assert_flags(C = 0, Z = 0, N = 0);
}

test_NOP :: () {
	test_handler("NOP");
	
	virtual_exec_operation(.NOP);
	assert_flags();  // all zero
	assert_reg();    // all default
}

test_ORA :: () {
	test_handler("ORA");
	for x: 0..0xFF {
		for y: 0..0xFF {
			virtual_exec_operation(.LDA_IMM, xx x);
			virtual_exec_operation(.ORA_IMM, xx y);
			res := cast,trunc(u8)(x | y);
			assert_reg(A = res);
			assert_flags(Z = cast(u8)(res == 0), N = cast(u8)((cast,no_check(s8)res) < 0));
		}
		cpu_reset(virtual = true);  // this, or the ROM will overflow
	}
}

test_ROL :: () {
	test_handler("ROL");
	
	virtual_exec_operation(.CLC);
	virtual_exec_operation(.LDA_IMM, 0x00);
	virtual_exec_operation(.ROL_ACC);
	assert_reg(A = 0x00);
	assert_flags(C = 0, Z = 1, N = 0);
	
	virtual_exec_operation(.SEC);
	virtual_exec_operation(.LDA_IMM, 0x00);
	virtual_exec_operation(.ROL_ACC);
	assert_reg(A = 0x01);
	assert_flags(C = 0, Z = 0, N = 0);
	
	virtual_exec_operation(.CLC);
	virtual_exec_operation(.LDA_IMM, 0x01);
	virtual_exec_operation(.ROL_ACC);
	assert_reg(A = 0x02);
	assert_flags(C = 0, Z = 0, N = 0);
	
	virtual_exec_operation(.CLC);
	virtual_exec_operation(.LDA_IMM, 0x02);
	virtual_exec_operation(.ROL_ACC);
	assert_reg(A = 0x04);
	assert_flags(C = 0, Z = 0, N = 0);
	
	virtual_exec_operation(.CLC);
	virtual_exec_operation(.LDA_IMM, 0x04);
	virtual_exec_operation(.ROL_ACC);
	assert_reg(A = 0x08);
	assert_flags(C = 0, Z = 0, N = 0);
	
	virtual_exec_operation(.CLC);
	virtual_exec_operation(.LDA_IMM, 0x08);
	virtual_exec_operation(.ROL_ACC);
	assert_reg(A = 0x10);
	assert_flags(C = 0, Z = 0, N = 0);
	
	virtual_exec_operation(.CLC);
	virtual_exec_operation(.LDA_IMM, 0x10);
	virtual_exec_operation(.ROL_ACC);
	assert_reg(A = 0x20);
	assert_flags(C = 0, Z = 0, N = 0);
	
	virtual_exec_operation(.CLC);
	virtual_exec_operation(.LDA_IMM, 0x20);
	virtual_exec_operation(.ROL_ACC);
	assert_reg(A = 0x40);
	assert_flags(C = 0, Z = 0, N = 0);
	
	virtual_exec_operation(.CLC);
	virtual_exec_operation(.LDA_IMM, 0x40);
	virtual_exec_operation(.ROL_ACC);
	assert_reg(A = 0x80);
	assert_flags(C = 0, Z = 0, N = 1);
	
	virtual_exec_operation(.CLC);
	virtual_exec_operation(.LDA_IMM, 0x80);
	virtual_exec_operation(.ROL_ACC);
	assert_reg(A = 0x00);
	assert_flags(C = 1, Z = 1, N = 0);
}

test_ROR :: () {
	test_handler("ROR");
	
	virtual_exec_operation(.CLC);
	virtual_exec_operation(.LDA_IMM, 0x00);
	virtual_exec_operation(.ROR_ACC);
	assert_reg(A = 0x00);
	assert_flags(C = 0, Z = 1, N = 0);
	
	virtual_exec_operation(.SEC);
	virtual_exec_operation(.LDA_IMM, 0x00);
	virtual_exec_operation(.ROR_ACC);
	assert_reg(A = 0x80);
	assert_flags(C = 0, Z = 0, N = 1);
	
	virtual_exec_operation(.CLC);
	virtual_exec_operation(.LDA_IMM, 0x01);
	virtual_exec_operation(.ROR_ACC);
	assert_reg(A = 0x00);
	assert_flags(C = 1, Z = 1, N = 0);
	
	virtual_exec_operation(.CLC);
	virtual_exec_operation(.LDA_IMM, 0x02);
	virtual_exec_operation(.ROR_ACC);
	assert_reg(A = 0x01);
	assert_flags(C = 0, Z = 0, N = 0);
	
	virtual_exec_operation(.CLC);
	virtual_exec_operation(.LDA_IMM, 0x04);
	virtual_exec_operation(.ROR_ACC);
	assert_reg(A = 0x02);
	assert_flags(C = 0, Z = 0, N = 0);
	
	virtual_exec_operation(.CLC);
	virtual_exec_operation(.LDA_IMM, 0x08);
	virtual_exec_operation(.ROR_ACC);
	assert_reg(A = 0x04);
	assert_flags(C = 0, Z = 0, N = 0);
	
	virtual_exec_operation(.CLC);
	virtual_exec_operation(.LDA_IMM, 0x10);
	virtual_exec_operation(.ROR_ACC);
	assert_reg(A = 0x08);
	assert_flags(C = 0, Z = 0, N = 0);
	
	virtual_exec_operation(.CLC);
	virtual_exec_operation(.LDA_IMM, 0x20);
	virtual_exec_operation(.ROR_ACC);
	assert_reg(A = 0x10);
	assert_flags(C = 0, Z = 0, N = 0);
	
	virtual_exec_operation(.CLC);
	virtual_exec_operation(.LDA_IMM, 0x40);
	virtual_exec_operation(.ROR_ACC);
	assert_reg(A = 0x20);
	assert_flags(C = 0, Z = 0, N = 0);
	
	virtual_exec_operation(.CLC);
	virtual_exec_operation(.LDA_IMM, 0x80);
	virtual_exec_operation(.ROR_ACC);
	assert_reg(A = 0x40);
	assert_flags(C = 0, Z = 0, N = 0);
}

test_SBC :: () {
	test_handler("SBC");
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

test_stack :: () {
	test_handler("stack");
	
	cpu_reset(virtual = true);
	virtual_exec_operation(.LDA_IMM, 0x20);
	virtual_exec_operation(.PHA);
	
	assert_reg(A = 0x20, S = 0xFE);
	assert_RAM(pos = 0x01FF, value = 0x20);
	
	virtual_exec_operation(.LDA_IMM, 0x10);
	assert_reg(A = 0x10, S = 0xFE);
	
	virtual_exec_operation(.PLA);
	assert_reg(A = 0x20, S = 0xFF);
	
	cpu_reset(virtual = true);
	
	virtual_exec_operation(.CLC);
	virtual_exec_operation(.LDA_IMM, 0x7F);
	virtual_exec_operation(.ADC_IMM, 0x01);  // V and N = 1
	virtual_exec_operation(.SEC);
	virtual_exec_operation(.SED);
	virtual_exec_operation(.PHP);
	assert_RAM(pos = 0x01FF, value = 0xC9);
	virtual_exec_operation(.LDA_IMM, 0x00);
	assert_reg(S = 0xFE);
	virtual_exec_operation(.CLC);
	virtual_exec_operation(.CLD);
	virtual_exec_operation(.CLV);
	assert_flags(C = 0, D = 0, V = 0, N = 0, Z = 1);  // because of the load
	
	virtual_exec_operation(.PLP);
	assert_reg(S = 0xFF);
	assert_flags(C = 1, D = 1, V = 1, N = 1, Z = 0);
	// Todo - maybe a test of a function call
}

test_load :: () {
	test_handler("load");
	
	virtual_exec_operation(.LDA_IMM, 0x10);
	assert_reg(A = 0x10);
	assert_flags(N = 0, Z = 0);
	
	virtual_exec_operation(.LDX_IMM, 0x80);
	assert_reg(A = 0x10, X = 0x80);
	assert_flags(N = 1, Z = 0);
	
	virtual_exec_operation(.LDY_IMM, 0x00);
	assert_reg(A = 0x10, X = 0x80, Y = 0x00);
	assert_flags(N = 0, Z = 1);
}

test_store :: () {
	test_handler("store");
	
	virtual_exec_operation(.LDA_IMM, 0x10);
	virtual_exec_operation(.LDX_IMM, 0x80);
	virtual_exec_operation(.LDY_IMM, 0x00);
	
	virtual_exec_operation(.STA_ZPG, 0x00);
	assert_RAM(pos = 0x00, value = 0x10);
	for 1..RAM_SIZE - 1 {
		assert_RAM(pos = xx it, value = 0x00);
	}
	
	virtual_exec_operation(.STX_ZPG, 0x01);
	assert_RAM(pos = 0x00, value = 0x10);
	assert_RAM(pos = 0x01, value = 0x80);
	for 2..RAM_SIZE - 1 {
		assert_RAM(pos = xx it, value = 0x00);
	}
	
	virtual_exec_operation(.STY_ZPG, 0x02);
	assert_RAM(pos = 0x00, value = 0x10);
	assert_RAM(pos = 0x01, value = 0x80);
	assert_RAM(pos = 0x02, value = 0x00);
	for 3..RAM_SIZE - 1 {
		assert_RAM(pos = xx it, value = 0x00);
	}
}

test_transfer :: () {
	test_handler("transfer");
	
	virtual_exec_operation(.LDA_IMM, 0x01);
	virtual_exec_operation(.LDX_IMM, 0x00);
	virtual_exec_operation(.LDY_IMM, 0x00);
	virtual_exec_operation(.TAX);
	assert_reg(A = 1, X = 1);
	
	virtual_exec_operation(.LDA_IMM, 0x01);
	virtual_exec_operation(.LDX_IMM, 0x00);
	virtual_exec_operation(.LDY_IMM, 0x00);
	virtual_exec_operation(.TAY);
	assert_reg(A = 1, Y = 1);
	
	virtual_exec_operation(.LDA_IMM, 0x00);
	virtual_exec_operation(.LDX_IMM, 0x00);
	virtual_exec_operation(.LDY_IMM, 0x00);
	virtual_exec_operation(.TSX);
	assert_reg(X = 0xFF);
	
	virtual_exec_operation(.LDA_IMM, 0x00);
	virtual_exec_operation(.LDX_IMM, 0x01);
	virtual_exec_operation(.LDY_IMM, 0x00);
	virtual_exec_operation(.TXA);
	assert_reg(X = 0x01, A = 0x01);
	
	virtual_exec_operation(.LDA_IMM, 0x00);
	virtual_exec_operation(.LDX_IMM, 0x00);
	virtual_exec_operation(.LDY_IMM, 0x01);
	virtual_exec_operation(.TYA);
	assert_reg(A = 0x01, Y = 0x01);
	
	virtual_exec_operation(.LDA_IMM, 0x00);
	virtual_exec_operation(.LDX_IMM, 0x00);
	virtual_exec_operation(.LDY_IMM, 0x00);
	virtual_exec_operation(.TXS);
	assert_reg(S = 0x00);
}

test_addressing :: () {
	test_handler("addressing");
	
	internal_all_zero_except :: (pos: u16, value: u8) {
		for 0..RAM_SIZE - 1 {
			if it == pos {
				assert_RAM(pos = xx it, value = value);
			} else {
				assert_RAM(pos = xx it, value = 0x00);
			}
		}
	}
	
	// zero page
	virtual_exec_operation(.LDA_IMM, 0x01);
	virtual_exec_operation(.STA_ZPG, 0x00);
	internal_all_zero_except(pos = 0x00, value = 0x01);
	memset(engine.RAM.data, 0, RAM_SIZE);
	
	// absolute
	virtual_exec_operation(.STA_ABS, 0x0808);
	internal_all_zero_except(pos = 0x0808, value = 0x01);
	memset(engine.RAM.data, 0, RAM_SIZE);
	
	// zero page X
	virtual_exec_operation(.LDA_IMM, 0x01);
	virtual_exec_operation(.LDX_IMM, 0x01);
	virtual_exec_operation(.STA_ZPX, 0x00);
	internal_all_zero_except(pos = 0x01, value = 0x01);
	memset(engine.RAM.data, 0, RAM_SIZE);
	
	// zero page Y
	virtual_exec_operation(.LDA_IMM, 0x00);
	virtual_exec_operation(.LDY_IMM, 0x02);
	virtual_exec_operation(.STY_ZPG, 0x02);
	virtual_exec_operation(.LDX_ZPY, 0x00);
	assert_reg(Y = 0x02, X = 0x02);
	memset(engine.RAM.data, 0, RAM_SIZE);
	
	// absolute X
	virtual_exec_operation(.LDA_IMM, 0x02);
	virtual_exec_operation(.LDX_IMM, 0x01);
	virtual_exec_operation(.LDY_IMM, 0x00);
	virtual_exec_operation(.STA_ABX, 0x0200);
	internal_all_zero_except(pos = 0x0201, value = 0x02);
	memset(engine.RAM.data, 0, RAM_SIZE);
	
	// absolute Y
	virtual_exec_operation(.LDA_IMM, 0x06);
	virtual_exec_operation(.LDX_IMM, 0x00);
	virtual_exec_operation(.LDY_IMM, 0x01);
	virtual_exec_operation(.STA_ABY, 0x0200);
	internal_all_zero_except(pos = 0x0201, value = 0x06);
	memset(engine.RAM.data, 0, RAM_SIZE);
	
	// indirect X
	virtual_exec_operation(.LDA_IMM, 0x02);
	virtual_exec_operation(.STA_ZPG, 0x04);
	virtual_exec_operation(.LDA_IMM, 0x02);
	virtual_exec_operation(.STA_ZPG, 0x05);
	assert_RAM(pos = 0x04, value = 0x02);
	assert_RAM(pos = 0x05, value = 0x02);
	
	virtual_exec_operation(.LDA_IMM, 0x10);
	virtual_exec_operation(.LDX_IMM, 0x04);
	virtual_exec_operation(.STA_INX, 0x00);

	assert_RAM(pos = 0x0202, value = 0x10);
	
	// indirect Y
	virtual_exec_operation(.LDA_IMM, 0x02);
	virtual_exec_operation(.STA_ZPG, 0x01);
	virtual_exec_operation(.LDA_IMM, 0x02);
	virtual_exec_operation(.STA_ZPG, 0x02);
	assert_RAM(pos = 0x01, value = 0x02);
	assert_RAM(pos = 0x02, value = 0x02);
	
	virtual_exec_operation(.LDA_IMM, 0x10);
	virtual_exec_operation(.LDY_IMM, 0x04);
	virtual_exec_operation(.STA_INY, 0x01);

	assert_RAM(pos = 0x0206, value = 0x10);
}

test_flags :: () {
	test_handler("flags");
	
	virtual_exec_operation(.SEC);
	assert_flags(C = 1);
	virtual_exec_operation(.CLC);
	assert_flags(C = 0);
	
	virtual_exec_operation(.SED);
	assert_flags(D = 1);
	virtual_exec_operation(.CLD);
	assert_flags(D = 0);
	
	virtual_exec_operation(.CLC);
	virtual_exec_operation(.LDA_IMM, 0x7F);
	virtual_exec_operation(.ADC_IMM, 0x01);
	assert_flags(V = 1, N = 1);
	virtual_exec_operation(.CLV);
	assert_flags(V = 0, N = 1);
}

test_branch :: () {
	test_handler("branch");
	
	internal_branch :: (op: Opcode) {
		virtual_write_ROM(engine.PC    , xx op);
		virtual_write_ROM(engine.PC + 1, 1);
		virtual_write_ROM(engine.PC + 2, xx Opcode.SED);
		virtual_write_ROM(engine.PC + 3, xx Opcode.CLD);
		
		next_instruction();
		next_instruction();
	}
	
	virtual_exec_operation(.LDA_IMM, 0x10);
	virtual_exec_operation(.CMP_IMM, 0x0F);
	internal_branch(.BCS);
	assert_flags(D = 0, C = 1, N = 0);
	
	virtual_exec_operation(.LDA_IMM, 0x10);
	virtual_exec_operation(.CMP_IMM, 0x11);
	internal_branch(.BCC);
	assert_flags(D = 0, C = 0, N = 1);
	
	virtual_exec_operation(.LDA_IMM, 0x10);
	virtual_exec_operation(.CMP_IMM, 0x10);
	internal_branch(.BEQ);
	assert_flags(D = 0, Z = 1, C = 1);
	
	virtual_exec_operation(.LDA_IMM, 0x10);
	virtual_exec_operation(.CMP_IMM, 0x11);
	internal_branch(.BNE);
	assert_flags(D = 0, C = 0, N = 1);
	
	virtual_exec_operation(.LDA_IMM, 0x10);
	virtual_exec_operation(.CMP_IMM, 0x11);
	internal_branch(.BMI);
	assert_flags(D = 0, C = 0, N = 1);
	
	virtual_exec_operation(.LDA_IMM, 0x10);
	virtual_exec_operation(.CMP_IMM, 0x0F);
	internal_branch(.BPL);
	assert_flags(D = 0, C = 1, N = 0);
	
	virtual_exec_operation(.CLC);
	virtual_exec_operation(.LDA_IMM, 0x7F);
	virtual_exec_operation(.ADC_IMM, 0x01);  // to overflow
	internal_branch(.BVS);
	assert_flags(D = 0, C = 0, N = 1, V = 1);
	
	virtual_exec_operation(.CLV);
	internal_branch(.BVC);
	assert_flags(D = 0, C = 0, N = 1);
}

test_ADD_decimal :: () {
	test_handler("Decimal ADC");

	virtual_exec_operation(.SED);
	virtual_exec_operation(.SEC);
	virtual_exec_operation(.LDA_IMM, 0x58);
	virtual_exec_operation(.ADC_IMM, 0x46);
	assert_reg(A = 0x05);
	assert_flags(C = 1, D = 1);
	
	virtual_exec_operation(.CLC);
	virtual_exec_operation(.LDA_IMM, 0x12);
	virtual_exec_operation(.ADC_IMM, 0x34);
	assert_reg(A = 0x46);
	assert_flags(C = 0, D = 1);
	
	virtual_exec_operation(.CLC);
	virtual_exec_operation(.LDA_IMM, 0x15);
	virtual_exec_operation(.ADC_IMM, 0x26);
	assert_reg(A = 0x41);
	assert_flags(C = 0, D = 1);
	
	virtual_exec_operation(.CLC);
	virtual_exec_operation(.LDA_IMM, 0x81);
	virtual_exec_operation(.ADC_IMM, 0x92);
	assert_reg(A = 0x73);
	assert_flags(C = 1, D = 1);
}

test_SUB_decimal :: () {
	test_handler("Decimal SBC");
	
	virtual_exec_operation(.SED);
	virtual_exec_operation(.SEC);
	virtual_exec_operation(.LDA_IMM, 0x46);
	virtual_exec_operation(.SBC_IMM, 0x12);
	assert_flags(C = 1, D = 1);
	assert_reg(A = 0x34);
	
	virtual_exec_operation(.SEC);
	virtual_exec_operation(.LDA_IMM, 0x40);
	virtual_exec_operation(.SBC_IMM, 0x13);
	assert_flags(C = 1, D = 1);
	assert_reg(A = 0x27);
	
	virtual_exec_operation(.CLC);
	virtual_exec_operation(.LDA_IMM, 0x32);
	virtual_exec_operation(.SBC_IMM, 0x02);
	assert_flags(C = 1, D = 1);
	assert_reg(A = 0x29);
}

#scope_export
run_all_tests :: () {
	start := current_time_monotonic();
	cpu_init(virtual = true);
	
	write_string("---    BITWISE   ---\n");
	test_AND();
	test_EOR();
	test_ORA();
	
	write_string("\n--- LOAD / STORE ---\n");
	test_load();
	test_store();
	
	write_string("\n---      MATH    ---\n");
	test_ADD();
	test_INC();
	test_DEC();
	test_SBC();
	test_ADD_decimal();
	test_SUB_decimal();
	
	write_string("\n---    SHIFT     ---\n");
	test_ASL();
	test_LSR();
	test_ROL();
	test_ROR();
	
	write_string("\n---    VARIOUS   ---\n");
	test_NOP();
	test_BIT();
	test_transfer();
	test_addressing();
	test_flags();
	
	write_string("\n---    BRANCH    ---\n");
	test_CMP();
	test_branch();
	test_JMP();
	
	write_string("\n---     STACK    ---\n");
	test_stack();
	
	end := current_time_monotonic();
	delta := end - start;
	print("\nPassed all % tests in %ms\n", tests_cumulative, to_milliseconds(delta));
	
	while true {}
}
