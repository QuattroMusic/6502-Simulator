update_6502 :: () {
	// those two should be put before the drawing, see `EventsManager` - `WM_SIZE`
	handle_viewport_movement();
	handle_viewport_resize();

	handle_displayed_file();

	draw_header();
	draw_buttons_controls();
	draw_code_viewer();
	draw_program_memory();
	draw_program_registers();
	draw_program_debug();
	draw_program_frequency();
	draw_current_instruction();
	draw_input();

	if is_key_pressed(KEY_ESC) then toggle_panel(ui.settings_panel, centered = true);

	widgets_draw_panels();
}

draw_one_frame :: () {
	if !vp.reduced {  // Todo - I should find a way to entirely disable this until it's not reduced anymore
		// begin_widgets();
		begin_drawing();
		clear_background(COLOR_DEEP_BACKGROUND);

		// update_6502();
		// draw_rect2(.{20, 20}, .{200, 100}, 1, RED);
		draw_character2(#char "a", .{0, 0}, z = 1, scale = 50, RED);

		// finalize_widgets();
		finalize_drawing();
	}
	reset_temporary_storage();
}

setup_windows :: () {
	padding :: 4;
	w :: DISPLAY_WIDTH  * 8 + padding * 2;
	h :: DISPLAY_HEIGHT * 8 + padding * 2 + 24;
	ui.display_panel = create_new_panel(draw_display, "display", .{w, h});

	modal_on_close :: () {  // Todo - Temporary!
		// there's a silly bug about this that I cannot explaint
		// the Basic()(MEMORY_DEBUG = true) sometimes shows an allocation and sometimes it doesn't
		// even if I free the memory, the bytes aren't decreasing (?)
		// with my good sense, I'm stil free-ing the memory, you know
		// I absolutely need to throw away the vasm compiler and build one
		// ~ Quattro 2024 / 10 / 11
		if ui.modal_error_type == .FAILED_COMPILATION then free(ui.modal_error_message);
	}

	ui.modal_panel = create_new_panel(draw_modal, "", .{800, 600}, on_close = modal_on_close, modal = true);

	ui.settings_panel = create_new_panel(draw_settings, "settings", .{SETTINGS_WIDTH, SETTINGS_HEIGHT});
}

main :: () {
	#if !DEBUG {
		WR :: #import "Windows_Resources";
		#run WR.disable_runtime_console();
	}

	cpu_init();
	init_window(MIN_SCREEN_WIDTH, MIN_SCREEN_HEIGHT);

	init_code_viewer("examples\\paint.s");

	setup_windows();

	while vp.running {
		lock_frame_rate();
		fetch_window_inputs();

		if is_key_pressed(KEY_ESC) then break;

		if is_mouse_pressed(2) then report_memory_leaks();

		draw_one_frame();
	}
	deinit_window();

	// run_all_tests();
}

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

DISPLAY_WIDTH  :: 120;
DISPLAY_HEIGHT :: 80;

MODAL_WIDTH  :: 800;
MODAL_HEIGHT :: 600;

SETTINGS_WIDTH  :: 800;
SETTINGS_HEIGHT :: 600;

APP_MAJOR_VERSION :: 1;
APP_MINOR_VERSION :: 0;

Vec2 :: Vector2;
Vec3 :: Vector3;
Vec4 :: Vector4;
f32  :: float32;
f64  :: float64;

Col :: struct {
	r, g, b, a: u8;
	#place r; data: u32;
}

operator * :: (col: Col, s: f32) -> Col #symmetric {
	out: Col = ---;
	out.r = cast(u8)(col.r * s);
	out.g = cast(u8)(col.g * s);
	out.b = cast(u8)(col.b * s);
	out.a = col.a;
	return out;
}

operator + :: (a: Col, b: Col) -> Col {
	out: Col = ---;
	out.r = a.r + b.r;
	out.g = a.g + b.g;
	out.b = a.b + b.b;
	out.a = a.a + b.a;
	return out;
}

#import "Basic"()(MEMORY_DEBUGGER = true);
#import "Math";
#import "File";
#import "Thread";
#import "Process";
#import "File_Utilities";
#import "Hash";
#import "Hash_Table";
#import "Sort";

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

#load "src/code_viewer/drawing.jai";
#load "src/code_viewer/code_viewer.jai";

#load "src/6502.jai";
#load "src/memory.jai";
#load "src/intrinsics.jai";
#load "src/gui.jai";
#load "src/utils.jai";

#load "tests.jai";
