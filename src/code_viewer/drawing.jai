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
	pos := viewer.pos;
	size := viewer.size;
	scr_pos := viewer.scrollbar_pos;
	amt := viewer.rows_length.count;
	
	draw_rect(.{pos.x + size.x - 12, pos.y}, .{12, size.y}, 1, COLOR_WIDGET_BG);
	
	aspect_ratio := size.y / (size.y + (amt - 1) * 16);
	bar_height := aspect_ratio * size.y;
	
	scroll_pos := pos + .{size.x - 12, scr_pos * aspect_ratio};
	state := scrollbar_interaction(scroll_pos, .{12, size.y});
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
	if t == {
		case .INSTRUCTION; return PURPLE2;
		case .COMMENT;     return GRAY;
		case .NUMBER;      return BLUE2;
		case .DOTDIR;      return ORANGE;
		case .LABEL;       return AMBER;
		case .STRING;      return GREEN;
		case .TEXT;        return WHITE;
	}
	assert(false);
	return .{};
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
	while it < len {
		defer it += 1;
		c := viewer.content[idx + it];
		if c == #char " " then continue;
		else if (it + 2) < len && is_an_instruction(viewer.content.data + idx + it) {
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
		c = viewer.content[idx + i];
		length += 1;
	}
	return length;
}

is_word_a_label :: (idx: u32, label_len: *u32) -> bool {
	c: u8;
	off: u32;
	while c != #char " " && c != #char "\n" {
		c = viewer.content[idx + off];
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
