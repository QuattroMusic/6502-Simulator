init_window :: (width: int, height: int, title: string) {
	sleep_is_granular = (timeBeginPeriod(1) == TIMERR_NOERROR);
	SetProcessDPIAware();

	vp.window = WC.create_window(width, height, title, background_color_rgb = .[0, 0, 0]);
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

Viewport :: struct {
	window: WC.Window_Type;
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
