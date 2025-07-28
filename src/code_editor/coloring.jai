init_code_editor_coloring :: () {
	idx: u32;
	for editor.rows_length {
		code_editor_coloring_parse_line(it_index, idx, it);
		idx += it + 1;
	}
}

deinit_code_editor_coloring :: () {
	array_reset(*editor.text_index);
	array_reset(*editor.text_length);
	array_reset(*editor.text_line);
	array_reset(*editor.text_column);
	array_reset(*editor.text_color);
}

update_code_editor_coloring :: () {
	deinit_code_editor_coloring();
	init_code_editor_coloring();
}

code_editor_coloring_parse_line :: (line: s64, idx: u32, len: s64) {
	add_new_color_token :: (idx: s64, len: s64, line: s64, col: s64, tok: Color_Tokens) {
		array_add(*editor.text_index,  xx idx);
		array_add(*editor.text_length, xx len);
		array_add(*editor.text_line,   xx line);
		array_add(*editor.text_column, xx col);
		array_add(*editor.text_color,  tok);
	}

	label_len: u32;
	it := 0;
	tab_size := 0;

	while it < len {
		defer it += 1;
		c := editor.content[idx + it];
		
		if c == #char " " then continue;
		if c == #char "\t" {
			tab_size += 3;
			continue;
		}
		else if (it + 2) < len && is_an_instruction(editor.content.data + idx + it) {
			add_new_color_token(idx + it, 3, line, it + tab_size, .INSTRUCTION);
			it += 3;
		} else if c == #char ";" {
			add_new_color_token(idx + it, len - it, line, it + tab_size, .COMMENT);
			return;
		} else if c == #char "." {
			tok_length := eat_until_whitespace(idx, xx it, xx len);
			add_new_color_token(idx + it, tok_length, line, it + tab_size, .DOTDIR);
			it += tok_length - 1;
		} else if c == #char "$" || c == #char "#" || c == #char "%" || (#char "0" <= c && c <= #char "9") {
			tok_length := eat_until_whitespace(idx, xx it, xx len);
			add_new_color_token(idx + it, tok_length, line, it + tab_size, .NUMBER);
			it += tok_length - 1;
		} else if is_word_a_label(xx idx, xx it, xx len, *label_len) {
			add_new_color_token(idx + it, label_len + 1, line, it + tab_size, .LABEL);
			it += label_len;
			label_len = 0;
		} else {
			tok_length := eat_until_whitespace(idx, xx it, xx len);
			add_new_color_token(idx + it, tok_length, line, it + tab_size, .TEXT);
			it += tok_length - 1;
		}
	}
}

draw_line_count_bar :: (x_visible: bool) {
	w := get_width_of_line_count_bar();
	off := editor.pos;

	draw_rect(off, .{w, editor.size.y}, settings.themes.platform_widget_bg_normal);

	start: int = xx editor.scrollbar_pos.y / 16;
	end: int = xx (editor.scrollbar_pos.y + editor.size.y - 8) / 16;

	for start..end - 1 {
		if it == editor.rows_length.count then return;

		y := off.y + 10 + it * 16 - editor.scrollbar_pos.y;
		fmt := formatInt(it + 1, minimum_digits = editor.row_digits, padding = #char " ");
		// Todo - Quattro - benchmark this?
		draw_text(tprint("%", fmt), .{off.x + 8, y}, 1, settings.themes.platform_text_normal);
	}
}

draw_colored_text :: (x_visible: bool) {
	off := editor.pos;
	off.x += get_width_of_line_count_bar() + 4 - editor.scrollbar_pos.x;
	off.y += 5 - editor.scrollbar_pos.y;

	start: int = xx editor.scrollbar_pos.y / 16;
	end: int = xx (editor.scrollbar_pos.y + editor.size.y - 8) / 16;

	w := get_width_of_line_count_bar();

	for editor.text_line {
		if it == end then break;  // no need to check forward
		
		if start <= it && it < end {
			index  := editor.text_index[it_index];
			length := editor.text_length[it_index];
			column := editor.text_column[it_index];
			color  := parse_token(editor.text_color[it_index]);

			y := off.y + it * 16;
			x := off.x + column * 16;
			str := string.{length, editor.content.data + index};

			for cast([]u8)str {
				p := x + it_index * 16.0;
				if (p <= editor.pos.x + w) || (p >= editor.pos.x + editor.size.x - 16) then continue;

				draw_character(it, .{x + it_index * 16.0, y}, scale = 2, color);
			}
		}
	}
}

parse_token :: (t: Color_Tokens) -> Col {
	if #complete t == {
		case .INSTRUCTION; return settings.themes.viewer_instruction;
		case .COMMENT;     return settings.themes.viewer_comment;
		case .NUMBER;      return settings.themes.viewer_number;
		case .DOTDIR;      return settings.themes.viewer_dotdir;
		case .LABEL;       return settings.themes.viewer_label;
		case .STRING;      return settings.themes.viewer_string;
		case .TEXT;        return settings.themes.viewer_text;
	}
}

eat_until_whitespace :: (idx: u32, i: u32, len: u32) -> u32 {
	c: u8;
	length: u32;
	while i < len {
		c = editor.content[idx + i];
		if c == #char " " then break;
		if c == #char ";" then break;
		i += 1;
		length += 1;
	}
	return length;
}

is_word_a_label :: (idx: u32, it: u32, len: u32, label_len: *u32) -> bool {
	c: u8;
	off: u32;
	while it + off < len && c != #char " " && c != #char "\n" && c != #char "\r" {
		c = editor.content[idx + it + off];
		off += 1;
		if c == #char ":" {
			label_len.* = off - 1;
			return true;
		}
	}
	return false;
}

is_an_instruction :: (buff: *u8) -> bool {
	if !(buff[3] == #char " " || buff[3] == #char "\n" || buff[3] == #char "\r") {
		// check if instruction is 3 char long
		return false;
	}

	make_u24 :: ($$s: string) -> u32 {
		#if is_constant(s) {
			c1 :: cast(u32, s[0]);
			c2 :: cast(u32, s[1]);
			c3 :: cast(u32, s[2]);
		} else {
			c1 := cast(u32, s[0]);
			c2 := cast(u32, s[1]);
			c3 := cast(u32, s[2]);
		}
		
		return c1 | (c2 << 8) | (c3 << 16);
	}

	value := make_u24(string.{3, buff});

	if value == {
		case #run make_u24("adc"); return true;
		case #run make_u24("and"); return true;
		case #run make_u24("asl"); return true;
		case #run make_u24("bcc"); return true;
		case #run make_u24("bcs"); return true;
		case #run make_u24("beq"); return true;
		case #run make_u24("bne"); return true;
		case #run make_u24("bmi"); return true;
		case #run make_u24("bpl"); return true;
		case #run make_u24("bvc"); return true;
		case #run make_u24("bvs"); return true;
		case #run make_u24("bit"); return true;
		case #run make_u24("brk"); return true;
		case #run make_u24("clc"); return true;
		case #run make_u24("cld"); return true;
		case #run make_u24("cli"); return true;
		case #run make_u24("clv"); return true;
		case #run make_u24("cmp"); return true;
		case #run make_u24("cpx"); return true;
		case #run make_u24("cpy"); return true;
		case #run make_u24("dec"); return true;
		case #run make_u24("dex"); return true;
		case #run make_u24("dey"); return true;
		case #run make_u24("eor"); return true;
		case #run make_u24("inc"); return true;
		case #run make_u24("inx"); return true;
		case #run make_u24("iny"); return true;
		case #run make_u24("jmp"); return true;
		case #run make_u24("jsr"); return true;
		case #run make_u24("lda"); return true;
		case #run make_u24("ldx"); return true;
		case #run make_u24("ldy"); return true;
		case #run make_u24("lsr"); return true;
		case #run make_u24("nop"); return true;
		case #run make_u24("ora"); return true;
		case #run make_u24("pha"); return true;
		case #run make_u24("php"); return true;
		case #run make_u24("pla"); return true;
		case #run make_u24("plp"); return true;
		case #run make_u24("rol"); return true;
		case #run make_u24("ror"); return true;
		case #run make_u24("rti"); return true;
		case #run make_u24("rts"); return true;
		case #run make_u24("sbc"); return true;
		case #run make_u24("sec"); return true;
		case #run make_u24("sed"); return true;
		case #run make_u24("sei"); return true;
		case #run make_u24("sta"); return true;
		case #run make_u24("stx"); return true;
		case #run make_u24("sty"); return true;
		case #run make_u24("tax"); return true;
		case #run make_u24("tay"); return true;
		case #run make_u24("tsx"); return true;
		case #run make_u24("txa"); return true;
		case #run make_u24("txs"); return true;
		case #run make_u24("tya"); return true;
	}
	return false;
}
