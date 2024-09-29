General_UI :: struct {
	memory_scrollbar_selected: bool;
	memory_scrollbar_pos: f32;

	show_popup: bool;
	popup_title: string;
	error_message: string;
	popup_error_type: Error_Type;

	display_pressed_pos: Vec2;
	display_pos: Vec2;
	display_selected: bool;
	display_visible: bool;
}

Error_Type :: enum {
	FAILED_COMPILATION;
	UNABLE_TO_OPEN_BINARY;
	INCOMPATIBLE_ROM_SIZE;
}

Color_Tokens :: enum u8 {
	INSTRUCTION;
	COMMENT;
	NUMBER;
	DOTDIR;
	LABEL;
	STRING;
	TEXT;
}

Code_Viewer :: struct {
	pos: Vec2;
	size: Vec2;

	scrollbar_selected: bool;
	scrollbar_pos: f32;
	row_digits: u32;

	content:     [..] u8;
	rows_length: [..] u32;
	file_path:   string;
	file_name:   string;  // this is a view

	// coloring, stored as SoA
	text_index:  [..] u32;
	text_length: [..] u32;
	text_line:   [..] u32;
	text_column: [..] u32;
	text_color:  [..] Color_Tokens;
}

Status_Flags :: struct {
	N, V, B, D, I, Z, C: bool;
}

Metrics :: struct {
	update_rate: int = 1_000;
	last_counter: s64;

	unlock: bool;
}

Emulator :: struct {
	ROM: [ROM_SIZE] u8 = ---;
	RAM: [RAM_SIZE] u8 = ---;
	A:  u8;
	X:  u8;
	Y:  u8;
	S:  u8;
	PC: u16;

	compilation_successful: bool;
	current_instruction: Opcode;

	flags: Status_Flags;

	cpu_thread: Thread;
	metrics: Metrics;

	running: bool;
	debug: bool;
	thread_running: bool;  // could be `true` when 6502 is paused
}

ui: General_UI;
viewer: Code_Viewer;

Hz  :: (f: type_of(engine.metrics.update_rate)) -> type_of(engine.metrics.update_rate) { return f; }
kHz :: (f: type_of(engine.metrics.update_rate)) -> type_of(engine.metrics.update_rate) { return f * 1_000; }
MHz :: (f: type_of(engine.metrics.update_rate)) -> type_of(engine.metrics.update_rate) { return f * 1_000_000; }
GHz :: (f: type_of(engine.metrics.update_rate)) -> type_of(engine.metrics.update_rate) { return f * 1_000_000_000; }

bit :: (n: int, i: int) -> u8 { return cast(u8)((n >> i) & 1); }

set_overflow :: (n1: u8, n2: u8, res: u16) { engine.flags.V = (bit(n1, 7) == bit(n2, 7)) && (bit(n2, 7) != bit(res, 7)); }

branch_if :: (relative: s8, cond: bool) {
	PC_advance(1);
	addr := cast,no_check(u16)(cast(s32)engine.PC + relative);
	if cond then PC_jump(addr);
}

stack_push :: (data: u8) {
	write_data(0x0100 + cast(u16)engine.S, data);
	engine.S -= 1;
}

stack_pop :: () -> u8 {
	engine.S += 1;
	data := read_data(cast(u16)0x0100 + cast(u16)engine.S);
	return data;
}

update_N_and_Z :: (data: u8) {
	engine.flags.N = cast(bool)bit(data, 7);
	engine.flags.Z = (data == 0);
}

pack_P :: () -> u8 {
	n1 := (cast(u8)engine.flags.C);
	n2 := (cast(u8)engine.flags.Z) << 1;
	n3 := (cast(u8)engine.flags.I) << 2;
	n4 := (cast(u8)engine.flags.D) << 3;
	n5 := (cast(u8)engine.flags.B) << 4;
	n6 := (cast(u8)engine.flags.V) << 6;
	n7 := (cast(u8)engine.flags.N) << 7;

	return n1 | n2 | n3 | n4 | n5 | n6 | n7;
}

unpack_P :: (data: u8) {
	engine.flags.N = cast(bool)((data >> 7)    );
	engine.flags.V = cast(bool)((data >> 6) & 1);
	engine.flags.B = cast(bool)((data >> 4) & 1);
	engine.flags.D = cast(bool)((data >> 3) & 1);
	engine.flags.I = cast(bool)((data >> 2) & 1);
	engine.flags.Z = cast(bool)((data >> 1) & 1);
	engine.flags.C = cast(bool)((data     ) & 1);
}

cpu_stop :: () {
	engine.running = false;
	engine.thread_running = false;

	log_info("CPU Stop");
}

cpu_reset :: () {
	memset(engine.RAM.data, 0, RAM_SIZE);
	memset(*engine.flags, 0, size_of(Status_Flags));
	engine.PC = 0xFFFC;
	engine.S = 0xFF;
	engine.A = 0;
	engine.X = 0;
	engine.Y = 0;
	log_info("CPU Reset");
}

cpu_init :: () {
	memset(engine.ROM.data, 0, ROM_SIZE);
	memset(engine.RAM.data, 0, RAM_SIZE);
	memset(*engine.flags, 0, size_of(Status_Flags));
	engine.PC = 0xFFFC;
	engine.S = 0xFF;
	engine.A = 0;
	engine.X = 0;
	engine.Y = 0;
	log_info("CPU Init");
}

virtual_cpu_reset :: () {
	memset(engine.RAM.data, 0, RAM_SIZE);
	memset(*engine.flags, 0, size_of(Status_Flags));
	engine.PC = 0x8000;
	engine.S = 0xFF;
	engine.A = 0;
	engine.X = 0;
	engine.Y = 0;
	log_info("Virtual CPU Reset");
}

virtual_cpu_init :: () {
	memset(engine.ROM.data, 0, ROM_SIZE);
	memset(engine.RAM.data, 0, RAM_SIZE);
	memset(*engine.flags, 0, size_of(Status_Flags));
	engine.PC = 0x8000;
	engine.S = 0xFF;
	engine.A = 0;
	engine.X = 0;
	engine.Y = 0;
	log_info("Virtual CPU Init");
}

next_instruction :: () {
	intrinsic := read_data(engine.PC);
	PC_advance(1);
	exec_operation(xx intrinsic);
}

cpu_start :: () {
	threaded_func :: (t: *Thread) -> s64 {
		PC_jump(read_address(engine.PC));
		while engine.thread_running {
			if !engine.metrics.unlock then lock_frame_rate_6502();
			if engine.running && !engine.debug then next_instruction();
		}
		return 0;
	}

	if !engine.thread_running {
		engine.thread_running = true;
		engine.running = true;
		thread_init(*engine.cpu_thread, threaded_func);
		thread_start(*engine.cpu_thread);
	}
}

lock_frame_rate_6502 :: () {
    target_s: f32 = 1.0 / engine.metrics.update_rate;
    seconds_elapsed_for_frame: f32 = (cast(f32)(read_os_timer() - engine.metrics.last_counter)) / vp.perf_count_frequency;
    if seconds_elapsed_for_frame < target_s {
        if vp.sleep_is_granular {
			sleep_ms := cast(s32)(1000.0 * (target_s - seconds_elapsed_for_frame));
            if sleep_ms > 0 then Sleep(sleep_ms);
        }
        while seconds_elapsed_for_frame < target_s {
            seconds_elapsed_for_frame = (cast(f32)(read_os_timer() - engine.metrics.last_counter)) / vp.perf_count_frequency;
        }
    }
    end_counter: s64;
    QueryPerformanceCounter(*end_counter);
    engine.metrics.last_counter = end_counter;
}

compile_program :: () {
	path := get_absolute_path(viewer.file_path,, temp);
	fmt := tprint("vasm6502_oldstyle.exe -Fbin -o \"out.bin\" -dotdir \"%\"", path);

	res, output_string, error_string := run_command(..break_command_into_strings(fmt), capture_and_return_output = true);
	defer free(output_string);
	
	engine.compilation_successful = false;
	
	if res.exit_code != 0 {
		ui.show_popup = true;
		ui.popup_title = "Compilation failed";
		ui.error_message = error_string;
		ui.popup_error_type = .FAILED_COMPILATION;
		return;
	}
	
	free(error_string);

	engine.compilation_successful = true;
}

indirect_X :: (addr: u16) -> u16 {
	return read_address(cast(u16)read_data(addr) + cast(u16)engine.X);
}

indirect_Y :: (addr: u16) -> u16 {
	return read_address(read_data(addr)) + cast(u16)engine.Y;
}

compact_immediate :: (func: (u8)) {
	func(read_data(engine.PC));
	PC_advance(1);
}

compact_absolute_data :: (func: (u8)) {
	func(read_data(read_address(engine.PC)));
	PC_advance(2);
}

compact_zero_page_data :: (func: (u8)) {
	func(read_data(cast(u16)read_data(engine.PC)));
	PC_advance(1);
}

compact_ind_X_data :: (func: (u8)) {
	func(read_data(indirect_X(engine.PC)));
	PC_advance(1);
}

compact_ind_Y_data :: (func: (u8)) {
	func(read_data(indirect_Y(engine.PC)));
	PC_advance(1);
}

compact_zero_page_X_data :: (func: (u8)) {
	func(read_data(cast(u16)read_data(engine.PC) + cast(u16)engine.X));
	PC_advance(1);
}

compact_zero_page_Y_data :: (func: (u8)) {
	func(read_data(cast(u16)read_data(engine.PC) + cast(u16)engine.Y));
	PC_advance(1);
}

compact_absolute_X_data :: (func: (u8)) {
	func(read_data(read_address(engine.PC) + cast(u16)engine.X));
	PC_advance(2);
}

compact_absolute_Y_data :: (func: (u8)) {
	func(read_data(read_address(engine.PC) + cast(u16)engine.Y));
	PC_advance(2);
}

compact_absolute_address :: (func: (u16)) {
	func(read_address(engine.PC));
	PC_advance(2);
}

compact_zero_page_address :: (func: (u16)) {
	func(cast(u16)read_data(engine.PC));
	PC_advance(1);
}

compact_indirect_address :: (func: (u16)) {
	func(read_address(read_address(engine.PC)));
	PC_advance(2);
}

compact_ind_X_address :: (func: (u16)) {
	func(indirect_X(engine.PC));
	PC_advance(1);
}

compact_ind_Y_address :: (func: (u16)) {
	func(indirect_Y(engine.PC));
	PC_advance(1);
}

compact_zero_page_X_address :: (func: (u16)) {
	func(cast(u16)read_data(engine.PC) + cast(u16)engine.X);
	PC_advance(1);
}

compact_zero_page_Y_address :: (func: (u16)) {
	func(cast(u16)read_data(engine.PC) + cast(u16)engine.Y);
	PC_advance(1);
}

compact_absolute_X_address :: (func: (u16)) {
	func(read_address(engine.PC) + cast(u16)engine.X);
	PC_advance(2);
}

compact_absolute_Y_address :: (func: (u16)) {
	func(read_address(engine.PC) + cast(u16)engine.Y);
	PC_advance(2);
}

intrinsic_to_string :: (code: Opcode) -> string {
	// This function is used to not increase the load size of the 6502 engine
	info :: type_info(Opcode);
	c := cast(u8)code;
	s: string;

	for info.values if it == c then s = info.names[it_index];
	
	if s.count == 3 then return s;
	else {
		t := s;
		t.data += 4;
		t.count -= 4;
		s.count = 3;
		if t == {
			case "IMM"; return tprint("% #n",    s);
			case "ZPG"; return tprint("% n",     s);
			case "ZPX"; return tprint("% n, X",  s);
			case "ZPY"; return tprint("% n, Y",  s);
			case "ABS"; return tprint("% nn",    s);
			case "ABX"; return tprint("% nn, X", s);
			case "ABY"; return tprint("% nn, Y", s);
			case "INX"; return tprint("% (n, X)",  s);
			case "INY"; return tprint("% (n), Y",  s);
			case "ACC"; return tprint("% A",     s);
		}
	}
	return "";
}

Opcode :: enum u8 {
	BRK :: 0X00;
	NOP :: 0XEA;

	CLC :: 0X18; CLD :: 0XD8; CLI :: 0X58; CLV :: 0XB8;
	SEC :: 0X38; SED :: 0XF8; SEI :: 0X78;

	DEX :: 0XCA; DEY :: 0X88;
	INX :: 0XE8; INY :: 0XC8;

	PHA :: 0X48; PHP :: 0X08; PLA :: 0X68; PLP :: 0X28;

	RTI :: 0X40; RTS :: 0X60;

	TAX :: 0XAA; TAY :: 0XA8; TSX :: 0XBA; TXA :: 0X8A; TXS :: 0X9A; TYA :: 0X98;

	BIT_ABS :: 0X2C; BIT_ZPG :: 0X24;

	JMP_ABS :: 0X4C; JMP_IND :: 0X6C;
	JSR_ABS :: 0X20;

	BCC :: 0X90; BCS :: 0XB0; BEQ :: 0XF0; BNE :: 0XD0; BMI :: 0X30; BPL :: 0X10; BVC :: 0X50; BVS :: 0X70;

	INC_ABS :: 0XEE; INC_ZPG :: 0XE6; INC_ZPX :: 0XF6; INC_ABX :: 0XFE;
	DEC_ABS :: 0XCE; DEC_ZPG :: 0XC6; DEC_ZPX :: 0XD6; DEC_ABX :: 0XDE;

	STA_ABS :: 0X8D; STA_ZPG :: 0X85; STA_INX :: 0X81; STA_INY :: 0X91; STA_ZPX :: 0x95; STA_ABX :: 0X9D; STA_ABY :: 0X99;
	STX_ABS :: 0X8E; STX_ZPG :: 0X86; STX_ZPY :: 0X96;
	STY_ABS :: 0X8C; STY_ZPG :: 0X84; STY_ZPX :: 0X94;

	ADC_IMM :: 0x69; ADC_ABS :: 0x6D; ADC_ZPG :: 0x65; ADC_INX :: 0x61; ADC_INY :: 0x71; ADC_ZPX :: 0x75; ADC_ABX :: 0x7D; ADC_ABY :: 0x79;
	AND_IMM :: 0x29; AND_ABS :: 0x2D; AND_ZPG :: 0X25; AND_INX :: 0X21; AND_INY :: 0X31; AND_ZPX :: 0X35; AND_ABX :: 0X3D; AND_ABY :: 0X39;
	CMP_IMM :: 0XC9; CMP_ABS :: 0XCD; CMP_ZPG :: 0XC5; CMP_INX :: 0XC1; CMP_INY :: 0XD1; CMP_ABX :: 0XDD; CMP_ABY :: 0XD9;
	CPX_IMM :: 0XE0; CPX_ABS :: 0XEC; CPX_ZPG :: 0XE4;
	CPY_IMM :: 0XC0; CPY_ABS :: 0XCC; CPY_ZPG :: 0XC4;
	EOR_IMM :: 0X49; EOR_ABS :: 0X4D; EOR_ZPG :: 0X45; EOR_INX :: 0X41; EOR_INY :: 0X51; EOR_ZPX :: 0X55; EOR_ABX :: 0X5D; EOR_ABY :: 0X59;
	LDA_IMM :: 0XA9; LDA_ABS :: 0XAD; LDA_ZPG :: 0XA5; LDA_INX :: 0XA1; LDA_INY :: 0XB1; LDA_ZPX :: 0XB5; LDA_ABX :: 0XBD; LDA_ABY :: 0XB9;
	ORA_IMM :: 0X09; ORA_ABS :: 0X0D; ORA_ZPG :: 0X05; ORA_INX :: 0X01; ORA_INY :: 0X11; ORA_ZPX :: 0X15; ORA_ABX :: 0X1D; ORA_ABY :: 0X19;
	SBC_IMM :: 0XE9; SBC_ABS :: 0XED; SBC_ZPG :: 0XE5; SBC_INX :: 0XE1; SBC_INY :: 0XF1; SBC_ZPX :: 0XF5; SBC_ABX :: 0XFD; SBC_ABY :: 0XF9;

	LDX_IMM :: 0XA2; LDX_ABS :: 0XAE; LDX_ZPG :: 0XA6; LDX_ABY :: 0XBE; LDX_ZPY :: 0XB6;
	LDY_IMM :: 0XA0; LDY_ABS :: 0XAC; LDY_ZPG :: 0XA4; LDY_ZPX :: 0XB4; LDY_ABX :: 0XBC;

	ROR_ABS :: 0X6E; ROR_ZPG :: 0X66; ROR_ACC :: 0X6A; ROR_ZPX :: 0X76; ROR_ABX :: 0X7E;
	ROL_ABS :: 0X2E; ROL_ZPG :: 0X26; ROL_ACC :: 0X2A; ROL_ZPX :: 0X36; ROL_ABX :: 0XE3;
	LSR_ABS :: 0X4E; LSR_ZPG :: 0X46; LSR_ACC :: 0X4A; LSR_ZPX :: 0X56; LSR_ABX :: 0X5E;
	ASL_ABS :: 0X0E; ASL_ZPG :: 0X06; ASL_ACC :: 0X0A; ASL_ZPX :: 0X16; ASL_ABX :: 0X1E;
}
