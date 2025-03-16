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

	draw_rect(off, .{w, editor.size.y}, 1, settings.themes.platform_widget_bg_normal);

	start: int = xx editor.scrollbar_pos.y / 16;
	end: int = xx (editor.scrollbar_pos.y + editor.size.y - 8) / 16;

	for start..end - 1 {
		if it == editor.rows_length.count then return;

		y := off.y + 10 + it * 16 - editor.scrollbar_pos.y;
		fmt := formatInt(it + 1, minimum_digits = editor.row_digits, padding = #char " ");
		// Todo - Quattro - benchmark this?
		draw_text(tprint("%", fmt), .{off.x + 8, y}, 2, 1, settings.themes.platform_text_normal);
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

				draw_character(it, .{x + it_index * 16.0, y}, layer = 1, scale = 2, color);
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

	// Todo - Quattro - make `make_u24` accepts a string instead of three characters
	make_u24 :: (c1: u32, c2: u32, c3: u32) -> u32 {
		return c1 | (c2 << 8) | (c3 << 16);
	}

	value := make_u24(buff[0], buff[1], buff[2]);

	if value == {
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
