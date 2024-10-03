draw_line_count_bar :: () {
	w := get_width_of_line_count_bar();
	off := viewer.pos;
	
	draw_rect(off, .{w, viewer.size.y}, 1, COLOR_WIDGET_BG);
	
	start: int = xx viewer.scrollbar_pos / 16;
	end: int = xx (viewer.scrollbar_pos + viewer.size.y + 10) / 16;
	
	for start..end - 1 {
		if it == viewer.rows_length.count then return;
		
		y := off.y + 10 + it * 16 - viewer.scrollbar_pos;
		fmt := formatInt(it + 1, minimum_digits = viewer.row_digits, padding = #char " ");
		draw_text(tprint("%", fmt), .{off.x + 8, y}, 2, 1, COLOR_TEXT_NORMAL);
	}
}

draw_scrollbars :: () {
	amt := viewer.rows_length.count;
	if amt == 0 then return;
	
	pos := viewer.pos;
	size := viewer.size;
	scr_pos := viewer.scrollbar_pos;
	
	draw_rect(.{pos.x + size.x - 12, pos.y}, .{12, size.y}, 1, COLOR_WIDGET_BG);
	
	aspect_ratio := size.y / (size.y + (amt - 1) * 16);
	bar_height := aspect_ratio * size.y;
	
	scroll_pos := pos + .{size.x - 12, scr_pos * aspect_ratio};
	state := scrollbar_interaction(scroll_pos, .{12, size.y}, 2);
	col: Col = ---;
	if state == {
		case .NORMAL;  col = COLOR_WIDGET_BORDER;
		case .HOVER;   col = COLOR_WIDGET_BG_HOVERED;
		case .PRESSED; col = COLOR_WIDGET_BG_PRESSED;
	}
	
	draw_rect(scroll_pos, .{12, bar_height}, 2, col);
}

draw_colored_text :: () {
	off := viewer.pos;
	off.x += get_width_of_line_count_bar() + 4;
	off.y += 5 - viewer.scrollbar_pos;
	
	start: int = xx viewer.scrollbar_pos / 16;
	end: int = xx (viewer.scrollbar_pos + viewer.size.y + 10) / 16;
	
	for viewer.text_line {
		if it == end then break;  // no need to check forward
		if start <= it && it <= end {
			index  := viewer.text_index[it_index];
			length := viewer.text_length[it_index];
			column := viewer.text_column[it_index];
			color  := parse_token(viewer.text_color[it_index]);
			
			y := off.y + it * 16;
			x := off.x + column * 16;
			str := string.{length, viewer.content.data + index};
			draw_text(str, .{x, y}, 1, 2, color);
		}
	}
}

parse_token :: (t: Color_Tokens) -> Col {
	if #complete t == {
		case .INSTRUCTION; return PURPLE;
		case .COMMENT;     return GRAY;
		case .NUMBER;      return BLUE;
		case .DOTDIR;      return ORANGE;
		case .LABEL;       return AMBER;
		case .STRING;      return GREEN;
		case .TEXT;        return WHITE;
	}
}

init_code_viewer_coloring :: () {
	idx: u32;
	for viewer.rows_length {
		code_viewer_coloring_parse_line(it_index, idx, it);
		idx += it + 1;
	}
}

deinit_code_viewer_coloring :: () {
	array_reset(*viewer.text_index);
	array_reset(*viewer.text_length);
	array_reset(*viewer.text_line);
	array_reset(*viewer.text_column);
	array_reset(*viewer.text_color);
}

code_viewer_coloring_parse_line :: (line: s64, idx: u32, len: s64) {
	add_new_color_token :: (idx: s64, len: s64, line: s64, col: s64, tok: Color_Tokens) {
		array_add(*viewer.text_index,  xx idx);
		array_add(*viewer.text_length, xx len);
		array_add(*viewer.text_line,   xx line);
		array_add(*viewer.text_column, xx col);
		array_add(*viewer.text_color,  tok);
	}
	
	label_len: u32;
	it := 0;
	tab_size := 0;
	
	while it < len {
		defer it += 1;
		c := viewer.content[idx + it];
		if c == #char " " then continue;
		if c == #char "\t" {
			tab_size += 3;
			continue;
		}
		else if (it + 2) < len && is_an_instruction(viewer.content.data + idx + it) {
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
			it += tok_length;
		} else if is_word_a_label(xx idx, xx it, xx len, *label_len) {
			add_new_color_token(idx + it, label_len + 1, line, it + tab_size, .LABEL);
			it += label_len;
			label_len = 0;
		} else {
			tok_length := eat_until_whitespace(idx, xx it, xx len);
			add_new_color_token(idx + it, tok_length, line, it + tab_size, .TEXT);
			it += tok_length;
		}
	}
}

eat_until_whitespace :: (idx: u32, i: u32, len: u32) -> u32 {
	c: u8;
	length: u32;
	while i < len {
		c = viewer.content[idx + i];
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
		c = viewer.content[idx + it + off];
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
	
	make_u24 :: (c1: u32, c2: u32, c3: u32) -> u32 {
		return c1 | (c2 << 8) | (c3 << 16);
	}
	
	// peak performance moment
	str := string.{3, buff};
	
	str[0] = to_lower(str[0]);
	str[1] = to_lower(str[1]);
	str[2] = to_lower(str[2]);
	
	if str == {
		case "adc"; return true;
		case "and"; return true;
		case "asl"; return true;
		case "bcc"; return true;
		case "bcs"; return true;
		case "beq"; return true;
		case "bne"; return true;
		case "bmi"; return true;
		case "bpl"; return true;
		case "bvc"; return true;
		case "bvs"; return true;
		case "bit"; return true;
		case "brk"; return true;
		case "clc"; return true;
		case "cld"; return true;
		case "cli"; return true;
		case "clv"; return true;
		case "cmp"; return true;
		case "cpx"; return true;
		case "cpy"; return true;
		case "dec"; return true;
		case "dex"; return true;
		case "dey"; return true;
		case "eor"; return true;
		case "inc"; return true;
		case "inx"; return true;
		case "iny"; return true;
		case "jmp"; return true;
		case "jsr"; return true;
		case "lda"; return true;
		case "ldx"; return true;
		case "ldy"; return true;
		case "lsr"; return true;
		case "nop"; return true;
		case "ora"; return true;
		case "pha"; return true;
		case "php"; return true;
		case "pla"; return true;
		case "plp"; return true;
		case "rol"; return true;
		case "ror"; return true;
		case "rti"; return true;
		case "rts"; return true;
		case "sbc"; return true;
		case "sec"; return true;
		case "sed"; return true;
		case "sei"; return true;
		case "sta"; return true;
		case "stx"; return true;
		case "sty"; return true;
		case "tax"; return true;
		case "tay"; return true;
		case "tsx"; return true;
		case "txa"; return true;
		case "txs"; return true;
		case "tya"; return true;
	}
	return false;
}
