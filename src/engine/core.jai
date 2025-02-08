init_window :: (width: s32, height: s32) {
	vp.sleep_is_granular = (timeBeginPeriod(1) == TIMERR_NOERROR);
	SetProcessDPIAware();

	vp.window = create_window(width, height);
	vp.width  = width;
	vp.height = height;

	init_rendering();
	init_widgets();

	QueryPerformanceFrequency(*vp.perf_count_frequency);
	QueryPerformanceCounter(*vp.last_counter);
	vp.running = true;
}

deinit_window :: () {
	deinit_rendering();
	deinit_widgets();
	destroy_window();
	
	timeEndPeriod(1);
}

destroy_window :: () {
	DestroyWindow(vp.window);
	
	t := to_c_string(TITLE_NAME,, temp);
	UnregisterClassA(t, null);
}

resize_window :: (w: s32, h: s32) {
	r: RECT;
	GetWindowRect(vp.window, *r);

	MoveWindow(vp.window, r.left, r.top, w, h, xx true);
}

set_window_pos :: (x: s32, y: s32) {
	MoveWindow(vp.window, x, y, vp.width, vp.height, xx true);
}

get_monitor_size :: () -> (w: s32, h: s32) {
	w := GetSystemMetrics(0);
	h := GetSystemMetrics(1);
	return w, h;
}

lock_frame_rate :: () {
    target_s: f32 = 1.0 / settings.platform.fps_lock;
    seconds_elapsed_for_frame: f32 = (cast(f32)(read_os_timer() - vp.last_counter)) / vp.perf_count_frequency;
    if seconds_elapsed_for_frame < target_s {
        if vp.sleep_is_granular {
            sleep_ms := cast(s32)(1000.0 * (target_s - seconds_elapsed_for_frame));
            if sleep_ms > 0 then Sleep(sleep_ms);
        }
        while seconds_elapsed_for_frame < target_s {
            seconds_elapsed_for_frame = (cast(f32)(read_os_timer() - vp.last_counter)) / vp.perf_count_frequency;
        }
    }
    end_counter: s64;
    QueryPerformanceCounter(*end_counter);
    vp.dt = (cast(f32)(end_counter - vp.last_counter)) / vp.perf_count_frequency;
    vp.last_counter = end_counter;
}

read_os_timer :: () -> s64 {
	timer: s64;
	QueryPerformanceCounter(*timer);
	return timer;
}

create_window :: (width: s32, height: s32) -> *void {
	_ole32 :: #system_library "Ole32";
	_user32 :: #system_library "user32";

	WNDCLASSEXA :: struct {
		cbSize:        u32;
		style:         u32;
		lpfnWndProc:   *void;
		cbClsExtra:    s32;
		cbWndExtra:    s32;
		hInstance:     *void;
		hIcon:         *void;
		hCursor:       *void;
		hbrBackground: *void;
		lpszMenuName:  *u8;
		lpszClassName: *u8;
		hIconSm:       *void;
	}

	CoInitialize :: (reserved: *void) -> s32 #foreign _ole32;
	RegisterClassExA :: (lpwcx: *WNDCLASSEXA) -> s16 #foreign _user32;

	CoInitialize(null);

	class_name := to_c_string(TITLE_NAME,, temp);

	info: WNDCLASSEXA;
	info.cbSize        = size_of(WNDCLASSEXA);
	info.lpfnWndProc   = xx events_manager;
	info.hInstance     = GetModuleHandleA(null);
	info.lpszClassName = class_name;
	info.hCursor       = LoadCursorA(null, IDC_ARROW);
	info.hbrBackground = CreateSolidBrush(0);

	RegisterClassExA(*info);

	monitor_width := GetSystemMetrics(0);
	monitor_height := GetSystemMetrics(1);
	x := (monitor_width - width) / 2;
	y := (monitor_height - height) / 2;

	r := RECT.{x, y, x + width, y + height};
	AdjustWindowRect(*r, vp.window_style, xx false);

	t := to_c_string(TITLE_NAME,, temp);
	win := CreateWindowExA(0, class_name, t, vp.window_style, r.left, r.top, r.right - r.left, r.bottom - r.top, null, null, null, null);

	DragAcceptFiles(win, xx true);  // enable drop file on window

	ShowWindow(win, SW_SHOW);

	return win;
}

events_manager :: (hwnd: *void, msg: u32, wparam: u64, lparam: s64) -> s64 #c_call {
	ctx: #Context;
	push_context,defer_pop ctx;

	if msg == {
		case WM_CLOSE; #through;
		case WM_QUIT;  vp.running = false;
		case WM_SETFOCUS; vp.reduced = false; focused_uuid = 0;
		case WM_KILLFOCUS; reset_input();
		case WM_SIZE;
			w := cast,trunc(s32)(lparam & 0xFFFF);
			h := cast,trunc(s32)((lparam >> 16) & 0xFFFF);
			vp.width = w;
			vp.height = h;
			if vp.running then resize_viewport();
		case WM_SYSKEYDOWN; #through;
		case WM_KEYFIRST;
			if wparam <= 0xFF {
				key := cast,no_check(u8)wparam;
				input_keyboard_states[key] = true;
				last_down_char      = key;
				pressed_char        = key;
			}
		case WM_SYSKEYUP; #through;
		case WM_KEYUP;
			if wparam <= 0xFF {
				key := cast,no_check(u8)wparam;
				input_keyboard_states[key] = false;
			}
		case WM_MOUSEMOVE;
			mouse_x =  lparam        & 0xFFFF;
			mouse_y = (lparam >> 16) & 0xFFFF;
		case WM_LBUTTONDOWN; input_button_states[0] = true;
		case WM_LBUTTONUP;   input_button_states[0] = false;
		case WM_RBUTTONDOWN; input_button_states[1] = true;
		case WM_RBUTTONUP;   input_button_states[1] = false;
		case WM_MBUTTONDOWN; input_button_states[2] = true;
		case WM_MBUTTONUP;   input_button_states[2] = false;
		case WM_MOUSEWHEEL;  mouse_dz = cast,trunc(s16)(wparam >> 16) / 120;
		case WM_DROPFILES;
			_shell32 :: #system_library "Shell32";
			DragQueryFileA :: (data: *void, idx: u32, name: *u8, length: u32) -> u32 #foreign _shell32;

			data := cast(HDROP)wparam;
			defer DragFinish(data);

			amt := DragQueryFileA(data, 0xFFFFFFFF, null, 0);  // fetch the dropped file amount
			if amt > 1 then return DefWindowProcA(hwnd, msg, wparam, lparam);

			engine.compilation_successful = false;

			buff: [MAX_PATH]u8;
			DragQueryFileA(data, 0, buff.data, buff.count);
			len := string_length(buff.data);
			handle_dropped_file(string.{len, buff.data});
	}

	return DefWindowProcA(hwnd, msg, wparam, lparam);
}

handle_viewport_movement :: () {
	if is_mouse_pressed(0) {
		// minus 3 * HEIGHT because a button has the size of that, so, 3 buttons
		if is_mouse_inside_rect(.{0, 0}, .{vp.width - HEADER_HEIGHT * 3.0, HEADER_HEIGHT}) {
			vp.pressed_pos.x = xx mouse_x;
			if vp.maximized {
				w := vp.width;
				ShowWindow(vp.window, SW_RESTORE);
				vp.maximized = false;
				vp.pressed_pos.x = cast(f32)mouse_x / (w + 3 * HEADER_HEIGHT) * vp.width;
			}
			vp.pressed_pos.y = xx mouse_y;
			vp.enable_movement = true;
		}
	}
	if vp.enable_movement {
		r: RECT = ---;
		pos: POINT = ---;
		GetWindowRect(vp.window, *r);
		GetCursorPos(*pos);

		delta := Vec2.{xx (pos.x - r.left), xx (pos.y - r.top)} - vp.pressed_pos;
		
		set_window_pos(xx (r.left + delta.x), xx (r.top + delta.y));
	}
	if is_mouse_released(0) {
		vp.enable_movement = false;
	}
}

handle_viewport_resize :: () {
	s :: 15;
	
	if is_mouse_pressed(0) {
		if is_mouse_inside_rect(.{xx (vp.width - s), xx (vp.height - s)}, .{s, s}) {
			r: RECT;
			GetWindowRect(vp.window, *r);
			vp.pressed_pos.x = xx mouse_x;
			vp.pressed_pos.y = xx mouse_y;
			vp.pressed_size.x = xx (r.right - r.left);
			vp.pressed_size.y = xx (r.bottom - r.top);
			vp.enable_resizing = true;
		}
	}
	if vp.enable_resizing {
		if vp.maximized {
			ShowWindow(vp.window, SW_RESTORE);
			vp.maximized = false;
		}

		r: RECT = ---;
		pos: POINT = ---;
		GetWindowRect(vp.window, *r);
		GetCursorPos(*pos);

		dx := pos.x - vp.pressed_pos.x - r.left;
		dy := pos.y - vp.pressed_pos.y - r.top;

		vx := dx + vp.pressed_size.x;
		vy := dy + vp.pressed_size.y;

		vx = max(vx, MIN_SCREEN_WIDTH);
		vy = max(vy, MIN_SCREEN_HEIGHT);

		MoveWindow(vp.window, r.left, r.top, xx vx, xx vy, xx true);
	}
	if is_mouse_released(0) then vp.enable_resizing = false;
}

Viewport :: struct {
	window: *void;
	width, height: s32;
	running: bool;
	reduced: bool;
	maximized: bool;
	
	sleep_is_granular: bool;
	dt: f32;
	
	perf_count_frequency: s64;
	last_counter: s64;
	
	window_style :: WS_POPUP;
	
	// used when moving / resizing the window
	pressed_pos: Vec2;
	pressed_size: Vec2;
	enable_movement := false;
	enable_resizing := false;
}

_user32 :: #system_library "User32";
MoveWindow :: (hWnd: *void, x: s32, y: s32, nWidth: s32, nHeight: s32, bRepaint: s32) #foreign _user32;

vp: Viewport;
engine: Emulator;
