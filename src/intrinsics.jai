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

	engine.flags.V = cast(bool)bit(data, 6);
	engine.flags.N = cast(bool)bit(data, 7);
	engine.flags.Z = (temp == 0);
}

CMP :: (data: u8) {
	temp: u16 = cast(u16)engine.A - cast(u16)data;

	engine.flags.C = (engine.A >= data);
	update_N_and_Z(cast,trunc(u8)temp);
}

CPX :: (data: u8) {
	temp: u16 = cast(u16)engine.X - cast(u16)data;

	engine.flags.C = (engine.X >= data);
	update_N_and_Z(cast,trunc(u8)temp);
}

CPY :: (data: u8) {
	temp: u16 = cast(u16)engine.Y - cast(u16)data;

	engine.flags.C = (engine.Y >= data);
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
		case .BRK;     engine.flags.B = true;  cpu_stop();
		case .NOP;     update_PC(1);
		case .CLC;     engine.flags.C = false;
		case .CLD;     engine.flags.D = false;
		case .CLI;     engine.flags.I = false;
		case .CLV;     engine.flags.V = false;
		case .SEC;     engine.flags.C = true;
		case .SED;     engine.flags.D = true;
		case .SEI;     engine.flags.I = true;
		case .DEX;     engine.X -= 1;  update_N_and_Z(engine.X);
		case .DEY;     engine.Y -= 1;  update_N_and_Z(engine.Y);
		case .INX;     engine.X += 1;  update_N_and_Z(engine.X);
		case .INY;     engine.Y += 1;  update_N_and_Z(engine.Y);
		case .PHA;     stack_push(engine.A);
		case .PHP;     stack_push(pack_P());
		case .PLA;     engine.A = stack_pop();  update_N_and_Z(engine.A);
		case .PLP;     unpack_P(stack_pop());
		case .RTI;     log_warn("RTI not supported at the moment");  cpu_stop();
		case .RTS;     RTS();
		case .TAX;     engine.X = engine.A;  update_N_and_Z(engine.X);
		case .TAY;     engine.Y = engine.A;  update_N_and_Z(engine.Y);
		case .TSX;     engine.X = engine.S;  update_N_and_Z(engine.X);
		case .TXA;     engine.A = engine.X;  update_N_and_Z(engine.A);
		case .TXS;     engine.S = engine.X;
		case .TYA;     engine.A = engine.Y;  update_N_and_Z(engine.A);
		case .BCS;     branch_if(cast,no_check(s8)read_data(engine.PC),  engine.flags.C);
		case .BCC;     branch_if(cast,no_check(s8)read_data(engine.PC), !engine.flags.C);
		case .BEQ;     branch_if(cast,no_check(s8)read_data(engine.PC),  engine.flags.Z);
		case .BNE;     branch_if(cast,no_check(s8)read_data(engine.PC), !engine.flags.Z);
		case .BMI;     branch_if(cast,no_check(s8)read_data(engine.PC),  engine.flags.N);
		case .BPL;     branch_if(cast,no_check(s8)read_data(engine.PC), !engine.flags.N);
		case .BVS;     branch_if(cast,no_check(s8)read_data(engine.PC),  engine.flags.V);
		case .BVC;     branch_if(cast,no_check(s8)read_data(engine.PC), !engine.flags.V);
		case .BIT_ABS; BIT(read_data(read_address(engine.PC)));  update_PC(2);
		case .BIT_ZPG; BIT(read_data(cast(u16)read_data(engine.PC)));  update_PC(1);
		case .JMP_ABS; JMP(read_address(engine.PC));
		case .JMP_IND; JMP(read_address(read_address(engine.PC)));
		case .JSR_ABS; JSR(read_address(engine.PC));
		case .INC_ABS; compact_absolute_address(INC);
		case .INC_ZPG; compact_zero_page_address(INC);
		case .INC_ZPX; compact_zero_page_X_address(INC);
		case .INC_ABX; compact_absolute_X_address(INC);
		case .DEC_ABS; compact_absolute_address(DEC);
		case .DEC_ZPG; compact_zero_page_address(DEC);
		case .DEC_ZPX; compact_zero_page_X_address(DEC);
		case .DEC_ABX; compact_absolute_X_address(DEC);
		case .STA_ABS; compact_absolute_address(STA);
		case .STA_ZPG; compact_zero_page_address(STA);
		case .STA_INX; compact_ind_X_address(STA);
		case .STA_INY; compact_ind_Y_address(STA);
		case .STA_ZPX; compact_zero_page_X_address(STA);
		case .STA_ABX; compact_absolute_X_address(STA);
		case .STA_ABY; compact_absolute_Y_address(STA);
		case .STX_ABS; compact_absolute_address(STX);
		case .STX_ZPG; compact_zero_page_address(STX);
		case .STX_ZPY; compact_zero_page_Y_address(STX);
		case .STY_ABS; compact_absolute_address(STY);
		case .STY_ZPG; compact_zero_page_address(STY);
		case .STY_ZPX; compact_zero_page_X_address(STY);
		case .ADC_IMM; compact_immediate(ADC);
		case .ADC_ABS; compact_absolute_data(ADC);
		case .ADC_ZPG; compact_zero_page_data(ADC);
		case .ADC_INX; compact_ind_X_data(ADC);
		case .ADC_INY; compact_ind_Y_data(ADC);
		case .ADC_ZPX; compact_zero_page_X_data(ADC);
		case .ADC_ABX; compact_absolute_X_data(ADC);
		case .ADC_ABY; compact_absolute_Y_data(ADC);
		case .AND_IMM; compact_immediate(AND);
		case .AND_ABS; compact_absolute_data(AND);
		case .AND_ZPG; compact_zero_page_data(AND);
		case .AND_INX; compact_ind_X_data(AND);
		case .AND_INY; compact_ind_Y_data(AND);
		case .AND_ZPX; compact_zero_page_X_data(AND);
		case .AND_ABX; compact_absolute_X_data(AND);
		case .AND_ABY; compact_absolute_Y_data(AND);
		case .CMP_IMM; compact_immediate(CMP);
		case .CMP_ABS; compact_absolute_data(CMP);
		case .CMP_ZPG; compact_zero_page_data(CMP);
		case .CMP_INX; compact_ind_X_data(CMP);
		case .CMP_INY; compact_ind_Y_data(CMP);
		case .CMP_ABX; compact_absolute_X_data(CMP);
		case .CMP_ABY; compact_absolute_Y_data(CMP);
		case .CPX_IMM; compact_immediate(CPX);
		case .CPX_ABS; compact_absolute_data(CPX);
		case .CPX_ZPG; compact_zero_page_data(CPX);
		case .CPY_IMM; compact_immediate(CPY);
		case .CPY_ABS; compact_absolute_data(CPY);
		case .CPY_ZPG; compact_zero_page_data(CPY);
		case .EOR_IMM; compact_immediate(EOR);
		case .EOR_ABS; compact_absolute_data(EOR);
		case .EOR_ZPG; compact_zero_page_data(EOR);
		case .EOR_INX; compact_ind_X_data(EOR);
		case .EOR_INY; compact_ind_Y_data(EOR);
		case .EOR_ZPX; compact_zero_page_X_data(EOR);
		case .EOR_ABX; compact_absolute_X_data(EOR);
		case .EOR_ABY; compact_absolute_Y_data(EOR);
		case .LDA_IMM; compact_immediate(LDA);
		case .LDA_ABS; compact_absolute_data(LDA);
		case .LDA_ZPG; compact_zero_page_data(LDA);
		case .LDA_INX; compact_ind_X_data(LDA);
		case .LDA_INY; compact_ind_Y_data(LDA);
		case .LDA_ZPX; compact_zero_page_X_data(LDA);
		case .LDA_ABX; compact_absolute_X_data(LDA);
		case .LDA_ABY; compact_absolute_Y_data(LDA);
		case .ORA_IMM; compact_immediate(ORA);
		case .ORA_ABS; compact_absolute_data(ORA);
		case .ORA_ZPG; compact_zero_page_data(ORA);
		case .ORA_INX; compact_ind_X_data(ORA);
		case .ORA_INY; compact_ind_Y_data(ORA);
		case .ORA_ZPX; compact_zero_page_X_data(ORA);
		case .ORA_ABX; compact_absolute_X_data(ORA);
		case .ORA_ABY; compact_absolute_Y_data(ORA);
		case .SBC_IMM; compact_immediate(SBC);
		case .SBC_ABS; compact_absolute_data(SBC);
		case .SBC_ZPG; compact_zero_page_data(SBC);
		case .SBC_INX; compact_ind_X_data(SBC);
		case .SBC_INY; compact_ind_Y_data(SBC);
		case .SBC_ZPX; compact_zero_page_X_data(SBC);
		case .SBC_ABX; compact_absolute_X_data(SBC);
		case .SBC_ABY; compact_absolute_Y_data(SBC);
		case .LDX_IMM; compact_immediate(LDX);
		case .LDX_ABS; compact_absolute_data(LDX);
		case .LDX_ZPG; compact_zero_page_data(LDX);
		case .LDX_ABY; compact_absolute_Y_data(LDX);
		case .LDX_ZPY; compact_zero_page_Y_data(LDX);
		case .LDY_IMM; compact_immediate(LDY);
		case .LDY_ABS; compact_absolute_data(LDY);
		case .LDY_ZPG; compact_zero_page_data(LDY);
		case .LDY_ZPX; compact_zero_page_X_data(LDY);
		case .LDY_ABX; compact_absolute_X_data(LDY);
		case .ROR_ABS; compact_absolute_address(ROR);
		case .ROR_ZPG; compact_zero_page_address(ROR);
		case .ROR_ACC; RORA();
		case .ROR_ZPX; compact_zero_page_X_address(ROR);
		case .ROR_ABX; compact_absolute_X_address(ROR);
		case .ROL_ABS; compact_absolute_address(ROL);
		case .ROL_ZPG; compact_zero_page_address(ROL);
		case .ROL_ACC; ROLA();
		case .ROL_ZPX; compact_zero_page_X_address(ROL);
		case .ROL_ABX; compact_absolute_X_address(ROL);
		case .LSR_ABS; compact_absolute_address(LSR);
		case .LSR_ZPG; compact_zero_page_address(LSR);
		case .LSR_ACC; LSRA();
		case .LSR_ZPX; compact_zero_page_X_address(LSR);
		case .LSR_ABX; compact_absolute_X_address(LSR);
		case .ASL_ABS; compact_absolute_address(ASL);
		case .ASL_ZPG; compact_zero_page_address(ASL);
		case .ASL_ACC; ASLA();
		case .ASL_ZPX; compact_zero_page_X_address(ASL);
		case .ASL_ABX; compact_absolute_X_address(ASL);
	}
}

virtual_exec_operation :: (opcode: Opcode, data: u16 = 0) {
	engine.ROM[engine.PC & 0x7FFF] = xx opcode;
	update_PC(1);

	defer exec_operation(opcode);
	
	if opcode == {
		case .BCS;     #through; case .BCC;     #through; case .BEQ;     #through; case .BNE;     #through;
		case .BMI;     #through; case .BPL;     #through; case .BVS;     #through; case .BVC;     #through;
		case .BIT_ZPG; #through; case .INC_ZPG; #through; case .INC_ZPX; #through; case .DEC_ZPG; #through;
		case .DEC_ZPX; #through; case .STA_ZPG; #through; case .STA_INX; #through; case .STA_INY; #through;
		case .STA_ZPX; #through; case .STX_ZPG; #through; case .STX_ZPY; #through; case .STY_ZPG; #through;
		case .STY_ZPX; #through; case .ADC_ZPG; #through; case .ADC_INX; #through; case .ADC_INY; #through;
		case .ADC_ZPX; #through; case .ADC_IMM; #through; case .AND_IMM; #through; case .AND_ZPG; #through;
		case .AND_INX; #through; case .AND_INY; #through; case .AND_ZPX; #through; case .CMP_IMM; #through;
		case .CMP_ZPG; #through; case .CMP_INX; #through; case .CMP_INY; #through; case .CPX_IMM; #through;
		case .CPX_ZPG; #through; case .CPY_IMM; #through; case .ASL_ZPX; #through; case .ASL_ZPG; #through;
		case .LSR_ZPX; #through; case .LSR_ZPG; #through; case .ROL_ZPX; #through; case .ROL_ZPG; #through;
		case .ROR_ZPX; #through; case .ROR_ZPG; #through; case .LDY_ZPX; #through; case .LDY_ZPG; #through;
		case .LDY_IMM; #through; case .LDX_ZPY; #through; case .LDX_ZPG; #through; case .LDX_IMM; #through;
		case .SBC_ZPX; #through; case .SBC_INY; #through; case .SBC_INX; #through; case .SBC_ZPG; #through;
		case .SBC_IMM; #through; case .ORA_ZPX; #through; case .ORA_INY; #through; case .ORA_INX; #through;
		case .ORA_ZPG; #through; case .ORA_IMM; #through; case .CPY_ZPG; #through; case .EOR_IMM; #through;
		case .EOR_ZPG; #through; case .EOR_INX; #through; case .EOR_INY; #through; case .EOR_ZPX; #through;
		case .LDA_IMM; #through; case .LDA_ZPG; #through; case .LDA_INX; #through; case .LDA_INY; #through;
		case .LDA_ZPX; engine.ROM[engine.PC & 0x7FFF] = cast,trunc(u8)data;
		
		case .BIT_ABS; #through;
		case .JMP_ABS; #through; case .JMP_IND; #through; case .JSR_ABS; #through; case .INC_ABS; #through;
		case .INC_ABX; #through; case .DEC_ABS; #through; case .DEC_ABX; #through; case .STA_ABX; #through;
		case .STA_ABY; #through; case .STX_ABS; #through; case .STY_ABS; #through; case .ADC_ABX; #through;
		case .ADC_ABY; #through; case .ADC_ABS; #through; case .AND_ABS; #through; case .AND_ABX; #through;
		case .AND_ABY; #through; case .STA_ABS; #through; case .CMP_ABS; #through; case .CMP_ABX; #through;
		case .CMP_ABY; #through; case .CPX_ABS; #through; case .CPY_ABS; #through; case .EOR_ABS; #through;
		case .EOR_ABX; #through; case .EOR_ABY; #through; case .LDA_ABS; #through; case .LDA_ABX; #through;
		case .LDA_ABY; #through; case .ORA_ABS; #through; case .ORA_ABX; #through; case .ORA_ABY; #through;
		case .SBC_ABS; #through; case .SBC_ABX; #through; case .SBC_ABY; #through; case .LDX_ABS; #through;
		case .LDX_ABY; #through; case .LDY_ABS; #through; case .LDY_ABX; #through; case .ROR_ABS; #through;
		case .ROR_ABX; #through; case .ROL_ABS; #through; case .ROL_ABX; #through; case .LSR_ABS; #through;
		case .LSR_ABX; #through; case .ASL_ABS; #through;
		case .ASL_ABX;
			engine.ROM[ engine.PC      & 0x7FFF] = cast,trunc(u8) data;
			engine.ROM[(engine.PC + 1) & 0x7FFF] = cast,trunc(u8)(data >> 8);
	}
}
