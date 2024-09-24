read_ROM :: (name: string) {
	file, res := file_open(name);
	if !res then log_error("Unable to open file \"%\"", name);
	
	file_seek(file, 0, .END);
	result, size := file_tell(file);
	// Todo - at the moment we're handling only 32kB ROM files
	if size != ROM_SIZE then log_error("Incompatible file, it must to be a 32kB ROM");
	file_seek(file, 0, .START);
	
	res = file_read(file, engine.ROM.data, ROM_SIZE);
	if !res then log_error("huh?");
	
	file_close(*file);
}

update_PC :: ($steps: u8, addr: u16 = 0) {
	#if !steps then engine.PC = addr;
	else            engine.PC += steps;
}

read_data :: (addr: u16) -> u8 {
	if addr < 0x8000 {
		return engine.RAM[addr];
	}
	return engine.ROM[addr & 0x7FFF];
}

write_data :: (addr: u16, data: u8) {
	if addr < 0x8000 {
		engine.RAM[addr] = data;
		return;
	}
	
	log_error("Cannot write in ROM space");
}

read_address :: (addr: u16) -> u16 {
	d1 := read_data(addr);
	d2 := read_data(addr + 1);
	return ((cast(u16)d2) << 8) | cast(u16)d1;
}
