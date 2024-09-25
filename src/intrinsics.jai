#scope_file
ADC :: (data: u8) {
	temp: u16 = cast(u16)engine.A + cast(u16)data + cast(u16)engine.flags.C;

	set_overflow(engine.A, data, temp);

	engine.A = cast,trunc(u8)temp;

	engine.flags.C = cast(bool)bit(temp, 8);
	update_N_and_Z(engine.A);
}

AND :: (data: u8) {
	engine.A &= data;

	update_N_and_Z(engine.A);
}

ASL :: (addr: u16) {
	temp: u16 = (cast(u16)read_data(addr)) << 1;
	data: u8 = cast,trunc(u8)temp;

	write_data(addr, data);

	engine.flags.C = cast(bool)bit(temp, 8);
	update_N_and_Z(data);
}

ASLA :: () {
	temp: u16 = (cast(u16)engine.A) << 1;
	engine.A = cast,trunc(u8)temp;

	engine.flags.C = cast(bool)bit(temp, 8);
	update_N_and_Z(engine.A);
}

BIT :: (data: u8) {
	temp: u8 = engine.A & data;

	engine.flags.V = cast(bool)bit(temp, 6);

	update_N_and_Z(temp);
}

CMP :: (data: u8) {
	temp: u16 = cast(u16)engine.A - cast(u16)data;

	engine.flags.C = (engine.A >= data);
	update_N_and_Z(cast,trunc(u8)temp);
}

CPX :: (data: u8) {
	temp: u16 = cast(u16)engine.X - cast(u16)data;

	engine.flags.C = (engine.A >= data);
	update_N_and_Z(cast,trunc(u8)temp);
}

CPY :: (data: u8) {
	temp: u16 = cast(u16)engine.Y - cast(u16)data;

	engine.flags.C = (engine.A >= data);
	update_N_and_Z(cast,trunc(u8)temp);
}

DEC :: (addr: u16) {
	data: u8 = read_data(addr);

	data -= 1;

	update_N_and_Z(data);

	write_data(addr, data);
}

EOR :: (data: u8) {
	engine.A ^= data;

	update_N_and_Z(engine.A);
}

INC :: (addr: u16) {
	data := read_data(addr);

	data += 1;

	update_N_and_Z(data);

	write_data(addr, data);
}

JMP :: (addr: u16) {
	update_PC(0, addr);
}

JSR :: (addr: u16) {
	update_PC(2);
	stack_push(cast,trunc(u8)(engine.PC >> 8));
	stack_push(cast,trunc(u8)engine.PC);

	update_PC(0, addr);
}

LDA :: (data: u8) {
	engine.A = data;
	update_N_and_Z(data);
}

LDX :: (data: u8) {
	engine.X = data;
	update_N_and_Z(data);
}

LDY :: (data: u8) {
	engine.Y = data;
	update_N_and_Z(data);
}

LSR :: (addr: u16) {
	data := read_data(addr);

	engine.flags.C = cast(bool)(data & 1);

	data >>= 1;

	write_data(addr, data);

	engine.flags.N = false;
	engine.flags.Z = (data == 0);
}

LSRA :: () {
	engine.flags.C = cast(bool)(engine.A & 1);

	engine.A >>= 1;

	engine.flags.N = false;
	engine.flags.Z = (engine.A == 0);
}

ORA :: (data: u8) {
	engine.A |= data;

	update_N_and_Z(engine.A);
}

ROL :: (addr: u16) {
	data := read_data(addr);

	temp: u16 = (cast(u16)data) << 1;

	temp |= cast(u8)engine.flags.C;

	data = cast,trunc(u8)temp;

	write_data(addr, data);

	engine.flags.C = cast(bool)bit(temp, 8);
	update_N_and_Z(data);
}

ROLA :: () {
	temp: u16 = (cast(u16)engine.A) << 1;

	temp |= cast(u8)engine.flags.C;

	engine.A = cast,trunc(u8)temp;

	engine.flags.C = cast(bool)bit(temp, 8);
	update_N_and_Z(engine.A);
}

ROR :: (addr: u16) {
	data := read_data(addr);
	temp: u8 = cast(u8)engine.flags.C;
	engine.flags.C = cast(bool)bit(data, 0);

	data >>= 1;
	data |= (temp << 7);

	update_N_and_Z(data);
}

RORA :: () {
	temp: u8 = cast(u8)engine.flags.C;
	engine.flags.C = cast(bool)bit(engine.A, 0);

	engine.A >>= 1;
	engine.A |= temp << 7;

	update_N_and_Z(engine.A);
}

RTS :: () {
	d1 := cast(u16)stack_pop();
	d2 := cast(u16)stack_pop();
	
	addr: u16 = (d2 << 8) | d1;
	
	update_PC(0, addr);
}

SBC :: (data: u8) {
	temp: u8 = engine.A - data - cast(u8)(!engine.flags.C);

	set_overflow(engine.A, ~data, temp);
	engine.flags.C = (0xFF + cast(u16)engine.A - data + cast(u8)engine.flags.C) >= 0x100;

	engine.A = temp;

	update_N_and_Z(engine.A);
}

STA :: (addr: u16) {
	write_data(addr, engine.A);
}

STX :: (addr: u16) {
	write_data(addr, engine.X);
}

STY :: (addr: u16) {
	write_data(addr, engine.Y);
}

#scope_export
exec_operation :: (opcode: Opcode) {
	engine.current_instruction = opcode;
	
	if #complete opcode == {
		case .BRK;  log_intrinsic("BRK"); engine.flags.B = true;  cpu_stop();
		case .NOP;  log_intrinsic("NOP"); update_PC(1);
		case .CLC;  log_intrinsic("CLC"); engine.flags.C = false;
		case .CLD;  log_intrinsic("CLD"); engine.flags.D = false;
		case .CLI;  log_intrinsic("CLI"); engine.flags.I = false;
		case .CLV;  log_intrinsic("CLV"); engine.flags.V = false;
		case .SEC;  log_intrinsic("SEC"); engine.flags.C = true;
		case .SED;  log_intrinsic("SED"); engine.flags.D = true;
		case .SEI;  log_intrinsic("SEI"); engine.flags.I = true;
		case .DEX;  log_intrinsic("DEX"); engine.X -= 1;  update_N_and_Z(engine.X);
		case .DEY;  log_intrinsic("DEY"); engine.Y -= 1;  update_N_and_Z(engine.Y);
		case .INX;  log_intrinsic("INX"); engine.X += 1;  update_N_and_Z(engine.X);
		case .INY;  log_intrinsic("INY"); engine.Y += 1;  update_N_and_Z(engine.X);
		case .PHA;  log_intrinsic("PHA"); stack_push(engine.A);
		case .PHP;  log_intrinsic("PHP"); stack_push(pack_P());
		case .PLA;  log_intrinsic("PLA"); engine.A = stack_pop();  update_N_and_Z(engine.A);
		case .PLP;  log_intrinsic("PLP"); unpack_P(stack_pop());
		case .RTI;  log_warn("RTI not supported at the moment");  cpu_stop();
		case .RTS;  log_intrinsic("RTS");            RTS();
		case .TAX;  log_intrinsic("TAX");            engine.X = engine.A;  update_N_and_Z(engine.X);
		case .TAY;  log_intrinsic("TAY");            engine.Y = engine.A;  update_N_and_Z(engine.Y);
		case .TSX;  log_intrinsic("TSX");            engine.X = engine.S;  update_N_and_Z(engine.X);
		case .TXA;  log_intrinsic("TXA");            engine.A = engine.X;  update_N_and_Z(engine.A);
		case .TXS;  log_intrinsic("TXS");            engine.S = engine.X;
		case .TYA;  log_intrinsic("TYA");            engine.A = engine.Y;  update_N_and_Z(engine.A);
		case .BIT_ABS;  log_intrinsic("BIT nn");     BIT(read_data(read_address(engine.PC)));  update_PC(2);
		case .BIT_ZPG;  log_intrinsic("BIT n, X");   BIT(read_data(cast(u16)read_data(engine.PC)));  update_PC(1);
		case .JMP_ABS;  log_intrinsic("JMP nn");     JMP(read_address(engine.PC));
		case .JMP_IND;  log_intrinsic("JMP (nn)");   JMP(read_address(read_address(engine.PC)));
		case .JSR_ABS;  log_intrinsic("JSR nn");     JSR(read_address(engine.PC));
		case .BCS;  log_intrinsic("BCS n");      branch_if(cast,no_check(s8)read_data(engine.PC),  engine.flags.C);
		case .BCC;  log_intrinsic("BCC n");      branch_if(cast,no_check(s8)read_data(engine.PC), !engine.flags.C);
		case .BEQ;  log_intrinsic("BEQ n");      branch_if(cast,no_check(s8)read_data(engine.PC),  engine.flags.Z);
		case .BNE;  log_intrinsic("BNE n");      branch_if(cast,no_check(s8)read_data(engine.PC), !engine.flags.Z);
		case .BMI;  log_intrinsic("BMI n");      branch_if(cast,no_check(s8)read_data(engine.PC),  engine.flags.N);
		case .BPL;  log_intrinsic("BPL n");      branch_if(cast,no_check(s8)read_data(engine.PC), !engine.flags.N);
		case .BVS;  log_intrinsic("BVS n");      branch_if(cast,no_check(s8)read_data(engine.PC),  engine.flags.V);
		case .BVC;  log_intrinsic("BVC n");      branch_if(cast,no_check(s8)read_data(engine.PC), !engine.flags.V);
		case .INC_ABS;  log_intrinsic("INC nn");     compact_absolute_address(INC);
		case .INC_ZPG;  log_intrinsic("INC n");      compact_zero_page_address(INC);
		case .INC_ZPX;  log_intrinsic("INC n, X");   compact_zero_page_X_address(INC);
		case .INC_ABX;  log_intrinsic("INC nn, X");  compact_absolute_X_address(INC);
		case .DEC_ABS;  log_intrinsic("DEC nn");     compact_absolute_address(DEC);
		case .DEC_ZPG;  log_intrinsic("DEC n");      compact_zero_page_address(DEC);
		case .DEC_ZPX;  log_intrinsic("DEC n, X");   compact_zero_page_X_address(DEC);
		case .DEC_ABX;  log_intrinsic("DEC nn, X");  compact_absolute_X_address(DEC);
		case .STA_ABS;  log_intrinsic("STA nn");     compact_absolute_address(STA);
		case .STA_ZPG;  log_intrinsic("STA n");      compact_zero_page_address(STA);
		case .STA_INX;  log_intrinsic("STA (n, X)"); compact_ind_X_address(STA);
		case .STA_INY;  log_intrinsic("STA (n), Y"); compact_ind_Y_address(STA);
		case .STA_ZPX;  log_intrinsic("STA n, X");   compact_zero_page_X_address(STA);
		case .STA_ABX;  log_intrinsic("STA nn, X");  compact_absolute_X_address(STA);
		case .STA_ABY;  log_intrinsic("STA nn, Y");  compact_absolute_Y_address(STA);
		case .STX_ABS;  log_intrinsic("STX nn");     compact_absolute_address(STX);
		case .STX_ZPG;  log_intrinsic("STX n");      compact_zero_page_address(STX);
		case .STX_ZPY;  log_intrinsic("STX n, Y");   compact_zero_page_Y_address(STX);
		case .STY_ABS;  log_intrinsic("STY nn");     compact_absolute_address(STY);
		case .STY_ZPG;  log_intrinsic("STY n");      compact_zero_page_address(STY);
		case .STY_ZPX;  log_intrinsic("STY n, X");   compact_zero_page_X_address(STY);
		case .ADC_IMM;  log_intrinsic("ADC #n");     compact_immediate(ADC);
		case .ADC_ABS;  log_intrinsic("ADC nn");     compact_absolute_data(ADC);
		case .ADC_ZPG;  log_intrinsic("ADC n");      compact_zero_page_data(ADC);
		case .ADC_INX;  log_intrinsic("ADC (n, X)"); compact_ind_X_data(ADC);
		case .ADC_INY;  log_intrinsic("ADC (n), Y"); compact_ind_Y_data(ADC);
		case .ADC_ZPX;  log_intrinsic("ADC n, X");   compact_zero_page_X_data(ADC);
		case .ADC_ABX;  log_intrinsic("ADC nn, X");  compact_absolute_X_data(ADC);
		case .ADC_ABY;  log_intrinsic("ADC nn, Y");  compact_absolute_Y_data(ADC);
		case .AND_IMM;  log_intrinsic("AND #n");     compact_immediate(AND);
		case .AND_ABS;  log_intrinsic("AND nn");     compact_absolute_data(AND);
		case .AND_ZPG;  log_intrinsic("AND n");      compact_zero_page_data(AND);
		case .AND_INX;  log_intrinsic("AND (n, X)"); compact_ind_X_data(AND);
		case .AND_INY;  log_intrinsic("AND (n), Y"); compact_ind_Y_data(AND);
		case .AND_ZPX;  log_intrinsic("AND n, X");   compact_zero_page_X_data(AND);
		case .AND_ABX;  log_intrinsic("AND nn, X");  compact_absolute_X_data(AND);
		case .AND_ABY;  log_intrinsic("AND nn, Y");  compact_absolute_Y_data(AND);
		case .CMP_IMM;  log_intrinsic("CMP #n");     compact_immediate(CMP);
		case .CMP_ABS;  log_intrinsic("CMP nn");     compact_absolute_data(CMP);
		case .CMP_ZPG;  log_intrinsic("CMP n");      compact_zero_page_data(CMP);
		case .CMP_INX;  log_intrinsic("CMP (n, X)"); compact_ind_X_data(CMP);
		case .CMP_INY;  log_intrinsic("CMP (n), Y"); compact_ind_Y_data(CMP);
		case .CMP_ABX;  log_intrinsic("CMP nn, X");  compact_absolute_X_data(CMP);
		case .CMP_ABY;  log_intrinsic("CMP nn, Y");  compact_absolute_Y_data(CMP);
		case .CPX_IMM;  log_intrinsic("CPX #n");     compact_immediate(CPX);
		case .CPX_ABS;  log_intrinsic("CPX nn");     compact_absolute_data(CPX);
		case .CPX_ZPG;  log_intrinsic("CPX n");      compact_zero_page_data(CPX);
		case .CPY_IMM;  log_intrinsic("CPY #n");     compact_immediate(CPY);
		case .CPY_ABS;  log_intrinsic("CPY nn");     compact_absolute_data(CPY);
		case .CPY_ZPG;  log_intrinsic("CPY n");      compact_zero_page_data(CPY);
		case .EOR_IMM;  log_intrinsic("EOR #n");     compact_immediate(EOR);
		case .EOR_ABS;  log_intrinsic("EOR nn");     compact_absolute_data(EOR);
		case .EOR_ZPG;  log_intrinsic("EOR n");      compact_zero_page_data(EOR);
		case .EOR_INX;  log_intrinsic("EOR (n, X)"); compact_ind_X_data(EOR);
		case .EOR_INY;  log_intrinsic("EOR (n), Y"); compact_ind_Y_data(EOR);
		case .EOR_ZPX;  log_intrinsic("EOR n, X");   compact_zero_page_X_data(EOR);
		case .EOR_ABX;  log_intrinsic("EOR nn, X");  compact_absolute_X_data(EOR);
		case .EOR_ABY;  log_intrinsic("EOR nn, Y");  compact_absolute_Y_data(EOR);
		case .LDA_IMM;  log_intrinsic("LDA #n");     compact_immediate(LDA);
		case .LDA_ABS;  log_intrinsic("LDA nn");     compact_absolute_data(LDA);
		case .LDA_ZPG;  log_intrinsic("LDA n");      compact_zero_page_data(LDA);
		case .LDA_INX;  log_intrinsic("LDA (n, X)"); compact_ind_X_data(LDA);
		case .LDA_INY;  log_intrinsic("LDA (n), Y"); compact_ind_Y_data(LDA);
		case .LDA_ZPX;  log_intrinsic("LDA n, X");   compact_zero_page_X_data(LDA);
		case .LDA_ABX;  log_intrinsic("LDA nn, X");  compact_absolute_X_data(LDA);
		case .LDA_ABY;  log_intrinsic("LDA nn, Y");  compact_absolute_Y_data(LDA);
		case .ORA_IMM;  log_intrinsic("ORA #n");     compact_immediate(ORA);
		case .ORA_ABS;  log_intrinsic("ORA nn");     compact_absolute_data(ORA);
		case .ORA_ZPG;  log_intrinsic("ORA n");      compact_zero_page_data(ORA);
		case .ORA_INX;  log_intrinsic("ORA (n, X)"); compact_ind_X_data(ORA);
		case .ORA_INY;  log_intrinsic("ORA (n), Y"); compact_ind_Y_data(ORA);
		case .ORA_ZPX;  log_intrinsic("ORA n, X");   compact_zero_page_X_data(ORA);
		case .ORA_ABX;  log_intrinsic("ORA nn, X");  compact_absolute_X_data(ORA);
		case .ORA_ABY;  log_intrinsic("ORA nn, Y");  compact_absolute_Y_data(ORA);
		case .SBC_IMM;  log_intrinsic("SBC #n");     compact_immediate(SBC);
		case .SBC_ABS;  log_intrinsic("SBC nn");     compact_absolute_data(SBC);
		case .SBC_ZPG;  log_intrinsic("SBC n");      compact_zero_page_data(SBC);
		case .SBC_INX;  log_intrinsic("SBC (n, X)"); compact_ind_X_data(SBC);
		case .SBC_INY;  log_intrinsic("SBC (n), Y"); compact_ind_Y_data(SBC);
		case .SBC_ZPX;  log_intrinsic("SBC n, X");   compact_zero_page_X_data(SBC);
		case .SBC_ABX;  log_intrinsic("SBC nn, X");  compact_absolute_X_data(SBC);
		case .SBC_ABY;  log_intrinsic("SBC nn, Y");  compact_absolute_Y_data(SBC);
		case .LDX_IMM;  log_intrinsic("LDX #n");     compact_immediate(LDX);
		case .LDX_ABS;  log_intrinsic("LDX nn");     compact_absolute_data(LDX);
		case .LDX_ZPG;  log_intrinsic("LDX n");      compact_zero_page_data(LDX);
		case .LDX_ABY;  log_intrinsic("LDX nn, Y");  compact_absolute_Y_data(LDX);
		case .LDX_ZPY;  log_intrinsic("LDX n, Y");   compact_zero_page_Y_data(LDX);
		case .LDY_IMM;  log_intrinsic("LDY #n");     compact_immediate(LDY);
		case .LDY_ABS;  log_intrinsic("LDY nn");     compact_absolute_data(LDY);
		case .LDY_ZPG;  log_intrinsic("LDY n");      compact_zero_page_data(LDY);
		case .LDY_ZPX;  log_intrinsic("LDY n, X");   compact_zero_page_X_data(LDY);
		case .LDY_ABX;  log_intrinsic("LDY nn, X");  compact_absolute_X_data(LDY);
		case .ROR_ABS;  log_intrinsic("ROR nn");     compact_absolute_address(ROR);
		case .ROR_ZPG;  log_intrinsic("ROR n");      compact_zero_page_address(ROR);
		case .ROR_ACC;  log_intrinsic("ROR A");      RORA();
		case .ROR_ZPX;  log_intrinsic("ROR n, X");   compact_zero_page_X_address(ROR);
		case .ROR_ABX;  log_intrinsic("ROR nn, X");  compact_absolute_X_address(ROR);
		case .ROL_ABS;  log_intrinsic("ROL nn");     compact_absolute_address(ROL);
		case .ROL_ZPG;  log_intrinsic("ROL n");      compact_zero_page_address(ROL);
		case .ROL_ACC;  log_intrinsic("ROL A");      ROLA();
		case .ROL_ZPX;  log_intrinsic("ROL n, X");   compact_zero_page_X_address(ROL);
		case .ROL_ABX;  log_intrinsic("ROL nn, X");  compact_absolute_X_address(ROL);
		case .LSR_ABS;  log_intrinsic("LSR nn");     compact_absolute_address(LSR);
		case .LSR_ZPG;  log_intrinsic("LSR n");      compact_zero_page_address(LSR);
		case .LSR_ACC;  log_intrinsic("LSR A");      LSRA();
		case .LSR_ZPX;  log_intrinsic("LSR n, X");   compact_zero_page_X_address(LSR);
		case .LSR_ABX;  log_intrinsic("LSR nn, X");  compact_absolute_X_address(LSR);
		case .ASL_ABS;  log_intrinsic("ASL nn");     compact_absolute_address(ASL);
		case .ASL_ZPG;  log_intrinsic("ASL n");      compact_zero_page_address(ASL);
		case .ASL_ACC;  log_intrinsic("ASL A");      ASLA();
		case .ASL_ZPX;  log_intrinsic("ASL n, X");   compact_zero_page_X_address(ASL);
		case .ASL_ABX;  log_intrinsic("ASL nn, X");  compact_absolute_X_address(ASL);
	}
}

virtual_exec_operation :: (opcode: Opcode, data: u16 = 0) {
	if opcode == {
		// case .BRK;     engine.flags.B = true; cpu_stop();
		// case .NOP;
		case .CLC;     engine.flags.C = false;
		// case .CLD;     engine.flags.D = false;
		// case .CLI;     engine.flags.I = false;
		// case .CLV;     engine.flags.V = false;
		case .SEC;     engine.flags.C = true;
		// case .SED;     engine.flags.D = true;
		// case .SEI;     engine.flags.I = true;
		// case .DEX;     engine.X -= 1;  update_N_and_Z(engine.X);
		// case .DEY;     engine.Y -= 1;  update_N_and_Z(engine.Y);
		// case .INX;     engine.X += 1;  update_N_and_Z(engine.X);
		// case .INY;     engine.Y += 1;  update_N_and_Z(engine.X);
		// case .PHA;     stack_push(engine.A);
		// case .PHP;     stack_push(pack_P());
		// case .PLA;     engine.A = stack_pop();  update_N_and_Z(engine.A);
		// case .PLP;     unpack_P(stack_pop());
		// case .RTI;     log_warn("RTI not supported at the moment"); cpu_stop();
		// case .RTS;     
		case .TAX;     engine.X = engine.A;  update_N_and_Z(engine.X);
		// case .TAY;     engine.Y = engine.A;  update_N_and_Z(engine.Y);
		// case .TSX;     engine.X = engine.S;  update_N_and_Z(engine.X);
		// case .TXA;     engine.A = engine.X;  update_N_and_Z(engine.A);
		case .TXS;     engine.S = engine.X;
		// case .TYA;     engine.A = engine.Y;  update_N_and_Z(engine.A);
		// case .BIT_ABS; BIT(read_data(data));
		// case .BIT_ZPG; BIT(read_data(data));
		// case .JMP_ABS; JMP(data);
		// case .JMP_IND; JMP(read_address(data));
		// case .JSR_ABS; JSR(data);
		// case .BCS; branch_if(cast,no_check(s8)data,  engine.flags.C);
		// case .BCC; branch_if(cast,no_check(s8)data, !engine.flags.C);
		// case .BEQ; branch_if(cast,no_check(s8)data,  engine.flags.Z);
		// case .BNE; branch_if(cast,no_check(s8)data, !engine.flags.Z);
		// case .BMI; branch_if(cast,no_check(s8)data,  engine.flags.N);
		// case .BPL; branch_if(cast,no_check(s8)data, !engine.flags.N);
		// case .BVS; branch_if(cast,no_check(s8)data,  engine.flags.V);
		// case .BVC; branch_if(cast,no_check(s8)data, !engine.flags.V);
		// case .INC_ABS; INC(data);
		// case .INC_ZPG; INC(data);
		// case .INC_ZPX; INC(data + cast(u16)engine.X);
		// case .INC_ABX; INC(data + cast(u16)engine.X);
		// case .DEC_ABS; DEC(data);
		// case .DEC_ZPG; DEC(data);
		// case .DEC_ZPX; DEC(data + cast(u16)engine.X);
		// case .DEC_ABX; DEC(data + cast(u16)engine.X);
		// case .STA_ABS; STA(data);
		case .STA_ZPG; STA(data);
		// case .STA_INX; STA(read_address(data + cast(u16)engine.X));
		// case .STA_INY; STA(read_address(data) + cast(u16)engine.Y);
		// case .STA_ZPX; STA(data + cast(u16)engine.X);
		// case .STA_ABX; STA(data + cast(u16)engine.X);
		// case .STA_ABY; STA(data + cast(u16)engine.Y);
		// case .STX_ABS; STX(data);
		// case .STX_ZPG; STX(data);
		// case .STX_ZPY; STX(data + cast(u16)engine.Y);
		// case .STY_ABS; STY(data);
		// case .STY_ZPG; STY(data);
		// case .STY_ZPX; STY(data + cast(u16)engine.X);
		case .ADC_IMM; ADC(cast,trunc(u8)data);
		// case .ADC_ABS; ADC(read_data(data));
		// case .ADC_ZPG; ADC(read_data(data));
		// case .ADC_INX; ADC(read_data(read_address(data + cast(u16)engine.X)));
		// case .ADC_INY; ADC(read_data(read_address(data) + cast(u16)engine.Y));
		// case .ADC_ZPX; ADC(read_data(data + cast(u16)engine.X));
		// case .ADC_ABX; ADC(read_data(data + cast(u16)engine.X));
		// case .ADC_ABY; ADC(read_data(data + cast(u16)engine.Y));
		// case .AND_IMM; AND(cast,trunc(u8)data);
		// case .AND_ABS; AND(read_data(data));
		// case .AND_ZPG; AND(read_data(data));
		// case .AND_INX; AND(read_data(read_address(data + cast(u16)engine.X)));
		// case .AND_INY; AND(read_data(read_address(data) + cast(u16)engine.Y));
		// case .AND_ZPX; AND(read_data(data + cast(u16)engine.X));
		// case .AND_ABX; AND(read_data(data + cast(u16)engine.X));
		// case .AND_ABY; AND(read_data(data + cast(u16)engine.Y));
		// case .CMP_IMM; CMP(cast,trunc(u8)data);
		// case .CMP_ABS; CMP(read_data(data));
		// case .CMP_ZPG; CMP(read_data(data));
		// case .CMP_INX; CMP(read_data(read_address(data + cast(u16)engine.X)));
		// case .CMP_INY; CMP(read_data(read_address(data) + cast(u16)engine.Y));
		// case .CMP_ABX; CMP(read_data(data + cast(u16)engine.X));
		// case .CMP_ABY; CMP(read_data(data + cast(u16)engine.Y));
		// case .CPX_IMM; CPX(cast,trunc(u8)data);
		// case .CPX_ABS; CPX(read_data(data));
		// case .CPX_ZPG; CPX(read_data(data));
		// case .CPY_IMM; CPY(data);
		// case .CPY_ABS; CPY(read_data(data));
		// case .CPY_ZPG; CPY(read_data(data));
		// case .EOR_IMM; EOR(cast,trunc(u8)data);
		// case .EOR_ABS; EOR(read_data(data));
		// case .EOR_ZPG; EOR(read_data(data));
		// case .EOR_INX; EOR(read_data(read_address(data + cast(u16)engine.X)));
		// case .EOR_INY; EOR(read_data(read_address(data) + cast(u16)engine.Y));
		// case .EOR_ZPX; EOR(read_data(data + cast(u16)engine.X));
		// case .EOR_ABX; EOR(read_data(data + cast(u16)engine.X));
		// case .EOR_ABY; EOR(read_data(data + cast(u16)engine.Y));
		case .LDA_IMM; LDA(cast,trunc(u8)data);
		// case .LDA_ABS; LDA(read_data(data));
		// case .LDA_ZPG; LDA(read_data(data));
		// case .LDA_INX; LDA(read_data(read_address(data + cast(u16)engine.X)));
		// case .LDA_INY; LDA(read_data(read_address(data) + cast(u16)engine.Y));
		// case .LDA_ZPX; LDA(read_data(data + cast(u16)engine.X));
		// case .LDA_ABX; LDA(read_data(data + cast(u16)engine.X));
		// case .LDA_ABY; LDA(read_data(data + cast(u16)engine.Y));
		// case .ORA_IMM; ORA(cast,trunc(u8)data);
		// case .ORA_ABS; ORA(read_data(data));
		// case .ORA_ZPG; ORA(read_data(data));
		// case .ORA_INX; ORA(read_data(read_address(data + cast(u16)engine.X)));
		// case .ORA_INY; ORA(read_data(read_address(data) + cast(u16)engine.Y));
		// case .ORA_ZPX; ORA(read_data(data + cast(u16)engine.X));
		// case .ORA_ABX; ORA(read_data(data + cast(u16)engine.X));
		// case .ORA_ABY; ORA(read_data(data + cast(u16)engine.Y));
		case .SBC_IMM; SBC(cast,trunc(u8)data);
		// case .SBC_ABS; SBC(read_data(data));
		// case .SBC_ZPG; SBC(read_data(data));
		// case .SBC_INX; SBC(read_data(read_address(data + cast(u16)engine.X)));
		// case .SBC_INY; SBC(read_data(read_address(data) + cast(u16)engine.Y));
		// case .SBC_ZPX; SBC(read_data(data + cast(u16)engine.X));
		// case .SBC_ABX; SBC(read_data(data + cast(u16)engine.X));
		// case .SBC_ABY; SBC(read_data(data + cast(u16)engine.Y));
		case .LDX_IMM; LDX(cast,trunc(u8)data);
		// case .LDX_ABS; LDX(read_data(data));
		// case .LDX_ZPG; LDX(read_data(data));
		// case .LDX_ABY; LDX(read_data(data + cast(u16)engine.Y));
		// case .LDX_ZPY; LDX(read_data(data + cast(u16)engine.Y));
		case .LDY_IMM; LDY(cast,trunc(u8)data);
		// case .LDY_ABS; LDY(read_data(data));
		// case .LDY_ZPG; LDY(read_data(data));
		// case .LDY_ZPX; LDY(read_data(data + cast(u16)engine.X));
		// case .LDY_ABX; LDY(read_data(data + cast(u16)engine.X));
		// case .ROR_ABS; ROR(data);
		// case .ROR_ZPG; ROR(data);
		// case .ROR_ACC; RORA();
		// case .ROR_ZPX; ROR(data + cast(u16)engine.X);
		// case .ROR_ABX; ROR(data + cast(u16)engine.X);
		// case .ROL_ABS; ROL(data);
		// case .ROL_ZPG; ROL(data);
		// case .ROL_ACC; ROLA();
		// case .ROL_ZPX; ROL(data + cast(u16)engine.X);
		// case .ROL_ABX; ROL(data + cast(u16)engine.X);
		// case .LSR_ABS; LSR(data);
		// case .LSR_ZPG; LSR(data);
		// case .LSR_ACC; LSRA();
		// case .LSR_ZPX; LSR(data + cast(u16)engine.X);
		// case .LSR_ABX; LSR(data + cast(u16)engine.X);
		// case .ASL_ABS; ASL(data);
		// case .ASL_ZPG; ASL(data);
		// case .ASL_ACC; ASLA();
		// case .ASL_ZPX; ASL(data + cast(u16)engine.X);
		// case .ASL_ABX; ASL(data + cast(u16)engine.X);
	}
}
