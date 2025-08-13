init_window :: () {
	vp.sleep_is_granular = (timeBeginPeriod(1) == TIMERR_NOERROR);
	SetProcessDPIAware();
	
	vp.window = create_window();

	init_rendering();
	init_widgets();

	reset_input();
	
	QueryPerformanceFrequency(*vp.perf_count_frequency);
	
	vp.last_counter = read_os_timer();
	vp.init_time    = read_os_timer();
	
	vp.running = true;
}

deinit_window :: () {
	deinit_rendering();
	deinit_widgets();
	
	name := utf8_to_wide(TITLE_NAME,, temp);
	
	DestroyWindow(vp.window);
	UnregisterClassW(name, null);

	timeEndPeriod(1);
}

get_monitor_size :: () -> (w: s32, h: s32) {
	w := GetSystemMetrics(0);
	h := GetSystemMetrics(1);
	return w, h;
}

read_os_timer :: () -> s64 {
	timer: s64;
	QueryPerformanceCounter(*timer);
	return timer;
}

lock_frame_rate :: (target_fps: f32, last_counter: s64) {
    target_s: f32 = 1.0 / target_fps;
    seconds_elapsed_for_frame: f32 = (cast(f32)(read_os_timer() - last_counter)) / vp.perf_count_frequency;
    if seconds_elapsed_for_frame < target_s {
        if vp.sleep_is_granular {
            sleep_ms := cast(s32)(1000.0 * (target_s - seconds_elapsed_for_frame) - 1);
            if sleep_ms > 0 then Sleep(sleep_ms);
        }
        while seconds_elapsed_for_frame < target_s {
            seconds_elapsed_for_frame = (cast(f32)(read_os_timer() - last_counter)) / vp.perf_count_frequency;
        }
    }
}

lock_window_frame_rate :: () {
	lock_frame_rate(60, vp.last_counter);

    end_counter: s64;
    QueryPerformanceCounter(*end_counter);
    vp.dt = (cast(f32)(end_counter - vp.last_counter)) / vp.perf_count_frequency;
    vp.last_counter = end_counter;
}

ms_since_init :: () -> s64 {
	time := read_os_timer();
	delta := time - vp.init_time;
	
	return delta * 1000 / vp.perf_count_frequency;
}

create_window :: () -> *void {
	w :: START_SCREEN_WIDTH;
	h :: START_SCREEN_HEIGHT;
	
	vp.width  = w;
	vp.height = h;

	name := utf8_to_wide(TITLE_NAME,, temp);

	info: WNDCLASSEXW;
	info.cbSize        = size_of(WNDCLASSEXW);
	info.lpszClassName = name;
	info.lpfnWndProc   = xx events_manager;
	info.hInstance     = GetModuleHandleW(null);
	info.hCursor       = LoadCursorW(null, IDC_ARROW);
	info.hbrBackground = CreateSolidBrush(BLACK_BRUSH);

	RegisterClassExW(*info);

	monitor_width, monitor_height := get_monitor_size();
	x := (monitor_width  - w) / 2;
	y := (monitor_height - h) / 2;

	r := RECT.{x, y, x + w, y + h};
	AdjustWindowRect(*r, vp.window_style, xx false);

	win := CreateWindowExW(WS_EX_APPWINDOW, name, name, vp.window_style, r.left, r.top, r.right - r.left, r.bottom - r.top, null, null, null, null);
	
	DragAcceptFiles(win, xx true);  // enable drop file on window

	return win;
}

window_maximized :: () -> bool {
	placement: WINDOWPLACEMENT;
	placement.length = size_of(WINDOWPLACEMENT);
	if GetWindowPlacement(vp.window, *placement) {
		return placement.showCmd == SW_SHOWMAXIMIZED;
	}
	return false;
}

events_manager :: (hwnd: *void, msg: u32, wparam: u64, lparam: s64) -> s64 #c_call {
	push_context,defer_pop;

	if msg == {
		case WM_CLOSE; #through;
		case WM_QUIT;  vp.running = false;
		case WM_SETFOCUS; vp.reduced = false; focused_uuid = 0;
		case WM_KILLFOCUS; reset_input();
		case WM_SIZE;
			w := cast,trunc(s32)((lparam      ) & 0xFFFF);
			h := cast,trunc(s32)((lparam >> 16) & 0xFFFF);
			vp.width = w;
			vp.height = h;
			if vp.running {
				resize_viewport();
				draw_one_frame();
				reset_input();
				focused_uuid = 0;
			}
		case WM_SYSKEYDOWN; #through;
		case WM_KEYDOWN;
			if wparam <= 0xFF {
				key := cast,no_check(u8)wparam;
				input_keyboard_states[key] = .DOWN;
				if lparam & 0x40000000 then input_keyboard_states[key] |= .REPEATED;
				else                        input_keyboard_states[key] |= .PRESSED;
				last_down_key = key;
			}
		case WM_SYSKEYUP; #through;
		case WM_KEYUP;
			if wparam <= 0xFF {
				key := cast,no_check(u8, wparam);
				input_keyboard_states[key] = .UP | .RELEASED;
			}
		case WM_CHAR;
			if wparam >= 32 && wparam <= 0xFF {
				key := cast,no_check(u8, wparam);
				pressed_char = key;
			}
		case WM_LBUTTONDOWN; input_mouse_states[0] = .DOWN | .PRESSED;
		case WM_RBUTTONDOWN; input_mouse_states[1] = .DOWN | .PRESSED;
		case WM_MBUTTONDOWN; input_mouse_states[2] = .DOWN | .PRESSED;
		case WM_LBUTTONUP;   input_mouse_states[0] = .UP   | .RELEASED;
		case WM_RBUTTONUP;   input_mouse_states[1] = .UP   | .RELEASED;
		case WM_MBUTTONUP;   input_mouse_states[2] = .UP   | .RELEASED;
		case WM_MOUSEMOVE;
			mouse_x = cast(s64, (lparam      ) & 0xFFFF);
			mouse_y = cast(s64, (lparam >> 16) & 0xFFFF);
		case WM_MOUSEWHEEL;  mouse_dz = cast,trunc(s16)(wparam >> 16) / 120;
		case WM_DROPFILES;
			data := cast(HDROP)wparam;
			defer DragFinish(data);

			amt := DragQueryFileA(data, 0xFFFFFFFF, null, 0);  // fetch the dropped file amount
			if amt > 1 then return DefWindowProcW(hwnd, msg, wparam, lparam);

			engine.compilation_successful = false;

			buff: [MAX_PATH]u8;
			DragQueryFileA(data, 0, buff.data, buff.count);
			len := c_style_strlen(buff.data);
			handle_dropped_file(string.{len, buff.data});
		case WM_NCCALCSIZE;
			if !wparam then return DefWindowProcW(hwnd, msg, wparam, lparam);
			
			dpi := GetDpiForWindow(hwnd);
			
			frame_x := GetSystemMetricsForDpi(SM_CXFRAME, dpi);
			frame_y := GetSystemMetricsForDpi(SM_CYFRAME, dpi);
			padding := GetSystemMetricsForDpi(SM_CXPADDEDBORDER, dpi);
			
			params := cast(*NCCALCSIZE_PARAMS, lparam);
			requested_client_rect := params.rgrc.data;
			
			requested_client_rect.*.right  -= frame_x + padding;
			requested_client_rect.*.left   += frame_x + padding;
			requested_client_rect.*.bottom -= frame_y + padding;
			if window_maximized() requested_client_rect.*.top += frame_y + padding;
			
			return 0;
		case WM_CREATE;
			SetWindowPos(hwnd, null, 0, 0, 0, 0, SWP_FRAMECHANGED | SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER);
		case WM_NCHITTEST;
			hit := DefWindowProcW(hwnd, msg, wparam, lparam);
			if hit == {
				case HTNOWHERE;     #through;
				case HTRIGHT;       #through;
				case HTLEFT;        #through;
				case HTTOPLEFT;     #through;
				case HTTOP;         #through;
				case HTTOPRIGHT;    #through;
				case HTBOTTOMRIGHT; #through;
				case HTBOTTOM;      #through;
				case HTBOTTOMLEFT;  return hit;
			}
			
			dpi := GetDpiForWindow(hwnd);
			frame_y := GetSystemMetricsForDpi(SM_CYFRAME, dpi);
			padding := GetSystemMetricsForDpi(SM_CXPADDEDBORDER, dpi);
			
			cursor: POINT;
			cursor.x = cast,no_check(s16, (lparam      ) & 0xFFFF);
			cursor.y = cast,no_check(s16, (lparam >> 16) & 0xFFFF);
			
			ScreenToClient(hwnd, *cursor);
			
			if cursor.y < (frame_y + padding) {
				if window_maximized() {
					if cursor.y > 0 then return HTTOP;
				} else {
					if cursor.y >= 0 then return HTTOP;
				}
			}
			
			if cursor.y < HEADER_HEIGHT && cursor.x < vp.width - HEADER_HEIGHT * 3 then return HTCAPTION;
			
			return HTCLIENT;
		case WM_GETMINMAXINFO;
			info := cast(*MINMAXINFO, lparam);
			info.*.minTrackSize.x = MIN_SCREEN_WIDTH;
			info.*.minTrackSize.y = MIN_SCREEN_HEIGHT;
	}

	return DefWindowProcW(hwnd, msg, wparam, lparam);
}

Viewport :: struct {
	window: *void;
	width, height: s32;
	running: bool;
	reduced: bool;
	// maximized: bool;

	sleep_is_granular: bool;
	dt: f32;

	perf_count_frequency: s64;
	last_counter: s64;

	window_style :: WS_THICKFRAME | WS_MAXIMIZEBOX | WS_MINIMIZEBOX | WS_SYSMENU | WS_VISIBLE;

	init_time: s64;
}


WINDOWPOS :: struct {
	hwnd: *void;
	hwndInsertAfter: *void;
	x, y, cx, cy: s32;
	flags: u32;
}

NCCALCSIZE_PARAMS :: struct {
	rgrc: [3] RECT;
	lppos: *WINDOWPOS;
}

WINDOWPLACEMENT :: struct {
	length: u32;
	flags: u32;
	showCmd: u32;
	minPosition: POINT;
	maxPosition: POINT;
	normalPosition: RECT;
	device: RECT;
}

MINMAXINFO :: struct {
	reserved: POINT;
	maxSize: POINT;
	maxPos: POINT;
	minTrackSize: POINT;
	maxTrackSize: POINT;
}

GetDpiForWindow :: (hwnd: *void) -> u32 #foreign _user32;
GetSystemMetricsForDpi :: (idx: s32, dpi: u32) -> s32 #foreign _user32;
GetWindowPlacement :: (hwnd: *void, p: *WINDOWPLACEMENT) -> s32 #foreign _user32;
DragQueryFileA :: (data: *void, idx: u32, name: *u8, length: u32) -> u32 #foreign _shell32;

#scope_file
_user32  :: #system_library "User32";
_shell32 :: #system_library "Shell32";

HTNOWHERE     :: 0;
HTCLIENT      :: 1;
HTCAPTION     :: 2;
HTLEFT        :: 10;
HTRIGHT       :: 11;
HTTOP         :: 12;
HTTOPLEFT     :: 13;
HTTOPRIGHT    :: 14;
HTBOTTOM      :: 15;
HTBOTTOMLEFT  :: 16;
HTBOTTOMRIGHT :: 17;
