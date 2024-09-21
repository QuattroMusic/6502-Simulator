// pressed_pos: Vec2;
// enable_movement := false;

handle_viewport_movement :: () {
	// Todo - use this only after disabling windows header
	/*_user32 :: #system_library "User32";
	MoveWindow :: (hWnd: WC.Window_Type, x: s32, y: s32, nWidth: s32, nHeight: s32, bRepaint: s32) #foreign _user32;
	RECT :: struct { left, top, right, bottom: s32; };
	GetWindowRect :: (hwnd: WC.Window_Type, rect: *RECT) -> s32 #foreign _user32;

	if is_mouse_pressed(0) {
		if is_mouse_over_rect(.{0, 0}, .{vp.width - HEADER_HEIGHT * 3.0, HEADER_HEIGHT}) {
			pressed_pos.x = xx mouse_x;
			// Todo - if maximized
			pressed_pos.y = xx mouse_y;
			enable_movement = true;
		}
	}
	if enable_movement {
		r: RECT;
		GetWindowRect(vp.window, *r);
		delta := Vec2.{xx mouse_x, xx mouse_y} - pressed_pos;
		w := r.right - r.left;
		h := r.bottom - r.top;
		
		MoveWindow(vp.window, xx (r.left + delta.x), xx (r.top + delta.y), w, h, xx true);
	}
	if is_mouse_released(0) {
		enable_movement = false;
	}*/
}

update_6502 :: () {
	handle_viewport_movement();

	draw_header();
	draw_buttons_controls();
	draw_code_viewer();
	draw_program_memory();
	draw_program_registers();
	draw_program_debug();
	draw_program_frequency();
}

draw_one_frame :: () {
	begin_drawing();
	clear_background(COLOR_DEEP_BACKGROUND);
	
	update_6502();

	finalize_drawing();
	reset_temporary_storage();
}

main :: () {
	init_window(MIN_SCREEN_WIDTH, MIN_SCREEN_HEIGHT);
	
	init_code_viewer("Random number.s");
	
	col: Col;
	
	while vp.running {
		fetch_window_events();
		
		draw_one_frame();
	}
	deinit_window();

	// read_ROM("Random number.bin");
	
	// cpu_reset();
	// cpu_start();
	
	// while engine.running {}
	// for 0..255 {
		// print("% ", engine.RAM[it]);
	// }
	// while true {}

	// run_all_tests();
}

LOG_INFO       :: true;
LOG_EDITOR     :: true;
LOG_VERBOSE    :: true;
LOG_INTRINSICS :: false;

ROM_SIZE      :: 32 * 1024;
RAM_SIZE      :: 32 * 1024;
HEADER_HEIGHT :: 35;

MEMORY_INPUT_ADDRESS  :: 0x2780;
MEMORY_YEAR_ADDRESS   :: 0x2781;
MEMORY_MONTH_ADDRESS  :: 0x2783;  
MEMORY_DAY_ADDRESS    :: 0x2784;
MEMORY_HOUR_ADDRESS   :: 0x2785;
MEMORY_MINUTE_ADDRESS :: 0x2786;
MEMORY_SECOND_ADDRESS :: 0x2787;

MIN_SCREEN_WIDTH  :: 1400;
MIN_SCREEN_HEIGHT :: 800;

APP_MAJOR_VERSION :: 0;
APP_MINOR_VERSION :: 1;

Vec2 :: Vector2;
Vec3 :: Vector3;
Vec4 :: Vector4;
Col  :: Vector4;
f32  :: float32;
f64  :: float64;

#import "Basic";
#import "Math";
#import "File";
#import "Thread";
#import "stb_image";
#import "Process";

#import "d3d11";
#import "d3d_compiler";
#import "dxgi";

#if OS == {
	// Todo - still not platform dependent
	case .WINDOWS; #import "Windows";
	case; #assert(false);
}

#load "src/engine/core.jai";
#load "src/engine/dx11.jai";
#load "src/engine/input.jai";
#load "src/engine/rendering.jai";
#load "src/engine/logging.jai";

#load "src/code_viewer/drawing.jai";
#load "src/code_viewer/code_viewer.jai";

#load "src/6502.jai";
#load "src/memory.jai";
#load "src/intrinsics.jai";
#load "src/gui.jai";
#load "src/utils.jai";

#load "tests.jai";
