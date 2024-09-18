draw_line_count_bar :: () {
	
}

draw_scrollbars :: () {
	pos := engine.cv.pos;
	size := engine.cv.size;
	scr_pos := engine.cv.scrollbar_pos;
	amt := engine.cv.rows_length.count;
	
	draw_rect(.{pos.x + size.x - 12, pos.y}, .{12, size.y}, 1, COLOR_BASE_NORMAL);
	
	aspect_ratio := size.y / (size.y + (amt - 1) * 16);
	bar_height := aspect_ratio * size.y;
	
	draw_rect(.{pos.x + size.x - 12, pos.y + scr_pos * aspect_ratio}, .{12, bar_height}, 2, COLOR_BASE_FOCUSED);
}

draw_colored_text :: () {
	off := engine.cv.pos;
	off.x += get_width_of_line_count_bar() + 1;
	off.y += 10 - engine.cv.scrollbar_pos;
	
	start: int = xx (engine.cv.scrollbar_pos - 10) / 16;
	end: int = xx (engine.cv.scrollbar_pos + engine.cv.size.y + 10) / 16;
	
	for engine.cv.text_line {
		if it == end then break;  // no need to check forward
		if start <= it && it <= end {
			index  := engine.cv.text_index[it_index];
			length := engine.cv.text_length[it_index];
			column := engine.cv.text_column[it_index];
			color  := parse_token(engine.cv.text_color[it_index]);
			
			y := off.y + it * 16;
			x := off.x + column * 16;
			str := string.{length, engine.cv.content.data + index};
			draw_text(str, .{x, y}, 2, 2, color);
			// text: string, pos: Vec2, layer: float, scale: float, color: Col
		}
	}
}

parse_token :: (t: Color_Tokens) -> Col {
	if t == {
		case .INSTRUCTION; return PURPLE;
		case .COMMENT;     return GRAY;
		case .NUMBER;      return BLUE;
		case .DOTDIR;      return ORANGE;
		case .LABEL;       return YELLOW;
		case .STRING;      return GREEN;
		case .TEXT;        return WHITE;
	}
	assert(false);  // Todo - better errors handling
	return .{};
}

init_code_viewer_coloring :: () {
	idx: u32;
	for engine.cv.rows_length {
		code_viewer_coloring_parse_line(it_index, idx, it);
		idx += it + 1;
	}
}

code_viewer_coloring_parse_line :: (line: s64, idx: u32, len: s64) {
	add_new_color_token :: (idx: s64, len: s64, line: s64, col: s64, tok: Color_Tokens) {
		array_add(*engine.cv.text_index,  xx idx);
		array_add(*engine.cv.text_length, xx len);
		array_add(*engine.cv.text_line,   xx line);
		array_add(*engine.cv.text_column, xx col);
		array_add(*engine.cv.text_color,  tok);
	}
	
	label_len: u32;
	it := 0;
	while it < len {
		defer it += 1;
		c := engine.cv.content[idx + it];
		if c == #char " " then continue;
		else if (it + 2) < len && is_an_instruction(engine.cv.content.data + idx + it) {
			add_new_color_token(idx + it, 3, line, it, .INSTRUCTION);
			it += 3;
		} else if c == #char ";" {
			add_new_color_token(idx + it, len - it, line, it, .COMMENT);
			return;
		} else if c == #char "." {
			tok_length := eat_until_whitespace(idx, xx it, xx len);
			add_new_color_token(idx + it, tok_length, line, it, .DOTDIR);
			it += tok_length;
		} else if c == #char "$" || c == #char "#" || c == #char "%" || (#char "0" <= c && c <= #char "9") {
			tok_length := eat_until_whitespace(idx, xx it, xx len);
			add_new_color_token(idx + it, tok_length, line, it, .NUMBER);
			it += tok_length;
		} else if is_word_a_label(xx (idx + it), *label_len) {
			add_new_color_token(idx + it, label_len + 1, line, it, .LABEL);
			it += label_len;
			label_len = 0;
		} else {
			tok_length := eat_until_whitespace(idx, xx it, xx len);
			add_new_color_token(idx + it, tok_length, line, it, .TEXT);
			it += tok_length;
		}
	}
}

eat_until_whitespace :: (idx: u32, i: u32, len: u32) -> u32 {
	c: u8;
	length: u32;
	while i < len && c != #char " " {
		i += 1;
		c = engine.cv.content[idx + i];
		length += 1;
	}
	return length;
}

is_word_a_label :: (idx: u32, label_len: *u32) -> bool {
	c: u8;
	off: u32;
	while c != #char " " && c != #char "\n" {
		c = engine.cv.content[idx + off];
		off += 1;
		if c == #char ":" {
			label_len.* = off - 1;
			return true;
		}
	}
	return false;
}

is_an_instruction :: (buff: *u8) -> bool {
	if !(buff[3] == #char " " || buff[3] == #char "\n") {
		// check if instruction is 3 char long
		return false;
	}
	
	make_u24 :: (c1: u32, c2: u32, c3: u32) -> u32 {
		return c1 | (c2 << 8) | (c3 << 16);
	}
	
	// peak performance moment
	val: u32 = buff[0] | ((cast(u32)buff[1]) << 8) | ((cast(u32)buff[2]) << 16);
	if val == {
		case #run make_u24(#char "a", #char "d", #char "c"); return true;
		case #run make_u24(#char "a", #char "n", #char "d"); return true;
		case #run make_u24(#char "a", #char "s", #char "l"); return true;
		case #run make_u24(#char "b", #char "c", #char "c"); return true;
		case #run make_u24(#char "b", #char "c", #char "s"); return true;
		case #run make_u24(#char "b", #char "e", #char "q"); return true;
		case #run make_u24(#char "b", #char "n", #char "e"); return true;
		case #run make_u24(#char "b", #char "m", #char "i"); return true;
		case #run make_u24(#char "b", #char "p", #char "l"); return true;
		case #run make_u24(#char "b", #char "v", #char "c"); return true;
		case #run make_u24(#char "b", #char "v", #char "s"); return true;
		case #run make_u24(#char "b", #char "i", #char "t"); return true;
		case #run make_u24(#char "b", #char "r", #char "k"); return true;
		case #run make_u24(#char "c", #char "l", #char "c"); return true;
		case #run make_u24(#char "c", #char "l", #char "d"); return true;
		case #run make_u24(#char "c", #char "l", #char "i"); return true;
		case #run make_u24(#char "c", #char "l", #char "v"); return true;
		case #run make_u24(#char "c", #char "m", #char "p"); return true;
		case #run make_u24(#char "c", #char "p", #char "x"); return true;
		case #run make_u24(#char "c", #char "p", #char "y"); return true;
		case #run make_u24(#char "d", #char "e", #char "c"); return true;
		case #run make_u24(#char "d", #char "e", #char "x"); return true;
		case #run make_u24(#char "d", #char "e", #char "y"); return true;
		case #run make_u24(#char "e", #char "o", #char "r"); return true;
		case #run make_u24(#char "i", #char "n", #char "c"); return true;
		case #run make_u24(#char "i", #char "n", #char "x"); return true;
		case #run make_u24(#char "i", #char "n", #char "y"); return true;
		case #run make_u24(#char "j", #char "m", #char "p"); return true;
		case #run make_u24(#char "j", #char "s", #char "r"); return true;
		case #run make_u24(#char "l", #char "d", #char "a"); return true;
		case #run make_u24(#char "l", #char "d", #char "x"); return true;
		case #run make_u24(#char "l", #char "d", #char "y"); return true;
		case #run make_u24(#char "l", #char "s", #char "r"); return true;
		case #run make_u24(#char "n", #char "o", #char "p"); return true;
		case #run make_u24(#char "o", #char "r", #char "a"); return true;
		case #run make_u24(#char "p", #char "h", #char "a"); return true;
		case #run make_u24(#char "p", #char "h", #char "p"); return true;
		case #run make_u24(#char "p", #char "l", #char "a"); return true;
		case #run make_u24(#char "p", #char "l", #char "p"); return true;
		case #run make_u24(#char "r", #char "o", #char "l"); return true;
		case #run make_u24(#char "r", #char "o", #char "r"); return true;
		case #run make_u24(#char "r", #char "t", #char "i"); return true;
		case #run make_u24(#char "r", #char "t", #char "s"); return true;
		case #run make_u24(#char "s", #char "b", #char "c"); return true;
		case #run make_u24(#char "s", #char "e", #char "c"); return true;
		case #run make_u24(#char "s", #char "e", #char "d"); return true;
		case #run make_u24(#char "s", #char "e", #char "i"); return true;
		case #run make_u24(#char "s", #char "t", #char "a"); return true;
		case #run make_u24(#char "s", #char "t", #char "x"); return true;
		case #run make_u24(#char "s", #char "t", #char "y"); return true;
		case #run make_u24(#char "t", #char "a", #char "x"); return true;
		case #run make_u24(#char "t", #char "a", #char "y"); return true;
		case #run make_u24(#char "t", #char "s", #char "x"); return true;
		case #run make_u24(#char "t", #char "x", #char "a"); return true;
		case #run make_u24(#char "t", #char "x", #char "s"); return true;
		case #run make_u24(#char "t", #char "y", #char "a"); return true;
	}
	return false;
}
