#if DEBUG {
	log_info      :: inline (fmt: string, vars: ..Any) { #if LOG_INFO       then _log_internal("[INFO]   ", .HI_GREEN); }
	log_error     :: inline (fmt: string, vars: ..Any) {                         _log_internal("[ERROR]  ", .HI_RED);   }
	log_warn      :: inline (fmt: string, vars: ..Any) {                         _log_internal("[WARN]   ", .YELLOW);   }
	log_editor    :: inline (fmt: string, vars: ..Any) { #if LOG_EDITOR     then _log_internal("[EDITOR] ", .HI_BLUE);  }

	#scope_file
	_log_internal :: (header: string, color: Print_Col.Console_Color) #expand {
		Print_Col.print_color(header, color = color);
		print(`fmt, ..`vars);
		write_string("\n");
	}

	Print_Col :: #import "Print_Color"()(USE_ANSI_CODES_ON_WINDOWS = false);
} else {
	log_info      :: inline (fmt: string, vars: ..Any) {}
	log_error     :: inline (fmt: string, vars: ..Any) {}
	log_warn      :: inline (fmt: string, vars: ..Any) {}
	log_editor    :: inline (fmt: string, vars: ..Any) {}
}
