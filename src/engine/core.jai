init_window :: (width: s32, height: s32) {
	sleep_is_granular = (timeBeginPeriod(1) == TIMERR_NOERROR);
	SetProcessDPIAware();

	// vp.window = WC.create_window(width, height, title, background_color_rgb = .[0, 0, 0]);
	vp.window = create_window(width, height);
	vp.width  = width;
	vp.height = height;
	
	init_rendering();

	QueryPerformanceFrequency(*perf_count_frequency);
	QueryPerformanceCounter(*last_counter);
	vp.running = true;
}

fetch_window_events :: () {
	fetch_window_inputs();

	lock_frame_rate();
}

deinit_window :: () {
	deinit_rendering();
	timeEndPeriod(1);
}

lock_frame_rate :: () {
    target_s: f32 = 1.0 / target_frame_rate;
    seconds_elapsed_for_frame: f32 = (cast(f32)(read_os_timer() - last_counter)) / perf_count_frequency;
    if seconds_elapsed_for_frame < target_s {
        if sleep_is_granular {
            sleep_ms := 1000.0 * target_s - seconds_elapsed_for_frame - 1;
            if sleep_ms > 0 then Sleep(xx sleep_ms);
        }
        while seconds_elapsed_for_frame < target_s {
            seconds_elapsed_for_frame = (cast(f32)(read_os_timer() - last_counter)) / perf_count_frequency;
        }
    }
    end_counter: s64;
    QueryPerformanceCounter(*end_counter);
    dt = (cast(f32)(end_counter - last_counter)) / perf_count_frequency;
    last_counter = end_counter;
	// Todo - maybe clamp delta_time if it's too high?
}

read_os_timer :: () -> s64 {
	timer: s64;
	QueryPerformanceCounter(*timer);
	return timer;
}

is_mouse_inside_rect :: (pos: Vec2, size: Vec2) -> bool {
	return (xx pos.x <= mouse_x) && (mouse_x < xx (pos.x + size.x)) && (xx pos.y <= mouse_y) && (mouse_y < xx (pos.y + size.y));
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
	
	class_name := to_c_string("6502 Window",, temp);
	
	info: WNDCLASSEXA;
	info.cbSize = size_of(WNDCLASSEXA);
	info.lpfnWndProc = xx EventsManager;
	info.hInstance = GetModuleHandleA(null);
	info.lpszClassName = class_name;
	info.hCursor = LoadCursorA(null, IDC_ARROW);
	info.hbrBackground = CreateSolidBrush(0);
	
	RegisterClassExA(*info);
	
	monitor_width := GetSystemMetrics(0);
	monitor_height := GetSystemMetrics(1);
	x := (monitor_width - width) / 2;
	y := (monitor_height - height) / 2;
	
	r := RECT.{x, y, x + width, y + height};
	AdjustWindowRect(*r, WS_OVERLAPPEDWINDOW, xx false);
	
	t := to_c_string("",, temp);
	win := CreateWindowExA(0, class_name, t, WS_OVERLAPPEDWINDOW, r.left, r.top, r.right - r.left, r.bottom - r.top, null, null, null, null);
	
	ShowWindow(win, SW_SHOW);
	
	return win;
}

EventsManager :: (hwnd: *void, msg: u32, wparam: u64, lparam: s64) -> s64 #c_call {
	if msg == {
		case WM_CLOSE; #through;
		case WM_QUIT;  vp.running = false;
		case WM_SIZE;
			w := lparam & 0xFFFF;
			h := (lparam >> 16) & 0xFFFF;
			vp.width = w;
			vp.height = h;
			// Todo - hande restore, minimize and maximize
			ctx: Context;
			push_context,defer_pop ctx;
			if vp.running {
				resize_viewport();
				draw_one_frame();
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
	}

	return DefWindowProcA(hwnd, msg, wparam, lparam);
}

Viewport :: struct {
	window: *void;
	width, height: int;
	running: bool;
}

vp: Viewport;
engine: Emulator;

sleep_is_granular: bool;
perf_count_frequency: s64;
last_counter: s64;
target_frame_rate := 120;
dt: f32;
