update_6502 :: () {
	// those two should be put before the drawing, see `EventsManager` - `WM_SIZE`
	handle_viewport_movement();
	handle_viewport_resize();

	handle_widget_layering();

	handle_input_and_time();
	
	handle_displayed_file();

	if ui.show_popup then draw_popup(800, 400);

	draw_header();
	draw_buttons_controls();
	draw_code_viewer();
	draw_program_memory();
	draw_program_registers();
	draw_program_debug();
	draw_program_frequency();
	draw_current_instruction();
	draw_input();

	draw_display();
}

draw_one_frame :: () {
	if !vp.reduced {  // I should find a way to entirely disable this until it's not reduced anymore
		begin_drawing();
		clear_background(COLOR_DEEP_BACKGROUND);

		update_6502();

		finalize_widgets();
		finalize_drawing();
	}
	reset_temporary_storage();
}

main :: () {
	#if !DEBUG {
		WR :: #import "Windows_Resources";
		#run WR.disable_runtime_console();
	}
	
	cpu_init();
	init_window(MIN_SCREEN_WIDTH, MIN_SCREEN_HEIGHT);

	// init_code_viewer("examples/Random number.s");

	while vp.running {
		lock_frame_rate();
		fetch_window_inputs();

		draw_one_frame();
	}
	deinit_window();
	
	// run_all_tests();
}

LOG_INFO       :: false;
LOG_EDITOR     :: false;
LOG_VERBOSE    :: false;

ROM_SIZE      :: 0x8000;
RAM_SIZE      :: 0x8000;
HEADER_HEIGHT :: 35;

MEMORY_INPUT_ADDRESS       :: 0x2780;
MEMORY_YEAR_ADDRESS        :: 0x2781;  // 2 bytes
MEMORY_MONTH_ADDRESS       :: 0x2783;
MEMORY_DAY_ADDRESS         :: 0x2784;
MEMORY_HOUR_ADDRESS        :: 0x2785;
MEMORY_MINUTE_ADDRESS      :: 0x2786;
MEMORY_SECOND_ADDRESS      :: 0x2787;
MEMORY_MILLISECOND_ADDRESS :: 0x2788;  // 2 bytes

MIN_SCREEN_WIDTH  :: 1400;
MIN_SCREEN_HEIGHT :: 800;

DISPLAY_WIDTH :: 120;
DISPLAY_HEIGHT :: 80;

APP_MAJOR_VERSION :: 1;
APP_MINOR_VERSION :: 0;

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
#import "Process";
#import "File_Utilities";

#import "d3d11";
#import "d3d_compiler";
#import "dxgi";

#if OS == {
	case .WINDOWS; #import "Windows";
	case; #assert(false);
}

#load "src/engine/core.jai";
#load "src/engine/dx11.jai";
#load "src/engine/input.jai";
#load "src/engine/rendering.jai";
#load "src/engine/widgets.jai";
#load "src/engine/logging.jai";

#load "src/code_viewer/drawing.jai";
#load "src/code_viewer/code_viewer.jai";

#load "src/6502.jai";
#load "src/memory.jai";
#load "src/intrinsics.jai";
#load "src/gui.jai";
#load "src/utils.jai";

#load "tests.jai";
