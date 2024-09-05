main :: () {
	init_window(MIN_SCREEN_WIDTH, MIN_SCREEN_HEIGHT, "");
	while vp.running {
		fetch_window_inputs();
		
		clear_background(COLOR_BACKGROUND);
		begin_drawing();
		
		draw_rect(.{100, 0}, .{100, 100}, 0, .{0, 1, 0, 1});
		draw_rect(.{0, 0}, .{100, 100},   0, .{0, 0, 1, 1});
		for 0..40 {
			draw_rect(.{xx (20 * it), 0}, .{10, 10}, 1, .{1, 0, 0, 1});
		}
		draw_rect(.{200, 0}, .{100, 100}, 0, COLOR_BORDER_NORMAL);
		draw_rect(.{300, 0}, .{100, 100}, 0, .{1, 1, 1, 1});
		
		draw_text("Text rendering", .{100, 40}, 0, 2, COLOR_TEXT_NORMAL);
		
		finalize_drawing();
		reset_temporary_storage();
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
FONT_SIZE     :: 18;
HEADER_HEIGHT :: 35;

MEMORY_INPUT_ADDRESS  :: 0x2780;
MEMORY_YEAR_ADDRESS   :: 0x2781;
MEMORY_MONTH_ADDRESS  :: 0x2783;  
MEMORY_DAY_ADDRESS    :: 0x2784;
MEMORY_HOUR_ADDRESS   :: 0x2785;
MEMORY_MINUTE_ADDRESS :: 0x2786;
MEMORY_SECOND_ADDRESS :: 0x2787;

MIN_SCREEN_WIDTH  :: 800;
MIN_SCREEN_HEIGHT :: 600;

APP_MAJOR_VERSION :: 1;
APP_MINOR_VERSION :: 0;

Vec2 :: #type Vector2;
Vec3 :: #type Vector3;
Vec4 :: #type Vector4;
Col  :: #type Vector4;

#import "Basic";
#import "Math";
#import "File";
#import "Thread";
#import "stb_image";

#import "d3d11";
#import "d3d_compiler";
#import "dxgi";

#if OS == {
	case .WINDOWS; #import "Windows";
	case; #assert(false);
}

Input :: #import "Input";
WC    :: #import "Window_Creation";

#load "src/core.jai";
#load "src/dx11.jai";
#load "src/input.jai";
#load "src/rendering.jai";
#load "src/logging.jai";
#load "src/6502.jai";
#load "src/memory.jai";
#load "src/intrinsics.jai";

#load "tests.jai";
