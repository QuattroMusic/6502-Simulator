update_6502 :: () {
	handle_displayed_file();

	handle_code_editor_events();
	
	handle_input_and_time();

	draw_header();
	draw_buttons_controls();
	draw_code_editor();
	draw_program_memory();
	draw_program_registers();
	draw_program_debug();
	draw_program_frequency();
	draw_current_instruction();
	draw_input();

	if is_key_pressed(KEY_ESC) then toggle_panel(ui.settings_panel, centered = true);
}

draw_one_frame :: () {
	if !vp.reduced {  // Todo - I should find a way to entirely disable this until it's not reduced anymore
		begin_drawing();

		clear_background(settings.themes.platform_deep_background);

		update_6502();

		draw_panels();
		finalize_drawing();
	}
	reset_temporary_storage();
}

setup_windows :: () {
	modal_on_close :: () {  // Todo - Temporary!
		// there's a silly bug about this that I cannot explain
		// the Basic()(MEMORY_DEBUGGER = true) sometimes shows an allocation and sometimes it doesn't
		// even if I free the memory, the bytes aren't decreasing (?)
		// with my good sense, I'm stil free-ing the memory, you know
		// I absolutely need to throw away the vasm compiler and build one
		// ~ Quattro 2024 / 10 / 11
		if ui.modal_error_type == .FAILED_COMPILATION then free(ui.modal_error_message);
	}
	ui.modal_panel = create_new_panel(draw_modal, "", .{800, 600}, on_close = modal_on_close);
	
	padding :: 4;
	w :: DISPLAY_WIDTH  * 8 + padding * 2;
	h :: DISPLAY_HEIGHT * 8 + padding * 2 + 24;
	ui.display_panel = create_new_panel(draw_display, "display", .{w, h});

	ui.settings_panel = create_new_panel(draw_settings, "settings", .{SETTINGS_WIDTH, SETTINGS_HEIGHT});

	ui.internal_selected             = *settings.themes.general_text;
	ui.internal_selected_saved_state = *settings.themes_saved_state.general_text;
}

main :: () {
	#if !DEBUG {
		WR :: #import "Windows_Resources";
		#run WR.disable_runtime_console();
	}

	cpu_init();
	init_window();

	init_settings();

	// init_code_editor("examples\\paint.s");

	setup_windows();

	while vp.running {
		lock_frame_rate();
		fetch_window_inputs();
		
		draw_one_frame();
	}
	deinit_window();

	// run_all_tests();
}

ui: General_UI;
settings: Settings = ---;
editor: Code_Editor;

vp: Viewport;
engine: Emulator;

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

MIN_SCREEN_WIDTH  :: 940;
MIN_SCREEN_HEIGHT :: 470;

START_SCREEN_WIDTH  :: 1400;
START_SCREEN_HEIGHT :: 800;

FONT_SIZE_GRANULARITY :: 8.0;
FONT_SIZE_SMALL  :: 1 * FONT_SIZE_GRANULARITY;
FONT_SIZE_NORMAL :: 2 * FONT_SIZE_GRANULARITY;
FONT_SIZE_LARGE  :: 3 * FONT_SIZE_GRANULARITY;

DISPLAY_WIDTH  :: 120;  // in rects, whose size are 8x8 (FONT_SIZE_GRANULARITY x FONT_SIZE_GRANULARITY)
DISPLAY_HEIGHT :: 80;   // so it's a [960 x 640] screen (without padding)

MODAL_WIDTH  :: 800;
MODAL_HEIGHT :: 600;

SETTINGS_WIDTH  :: 700;
SETTINGS_HEIGHT :: 450;

APP_MAJOR_VERSION :: 2;
APP_MINOR_VERSION :: 1;

DATA_FOLDER_NAME   :: "data";
THEME_FILE_NAME    :: "theme";
SETTINGS_FILE_NAME :: "settings";

CURSOR_SCROLLBAR_MIN_VALUE :: 1;
CURSOR_SCROLLBAR_MAX_VALUE :: 20;

TITLE_NAME :: "6502 Simulator";

Vec2 :: Vector2;
Vec3 :: Vector3;
Vec4 :: Vector4;
f32  :: float32;
f64  :: float64;

Col :: struct {
	r, g, b, a: u8;
	#place r; data: u32;
}

#import "Basic";
#import "Math";
#import "File";
#import "File_Utilities";
#import "Thread";
#import "Process";
#import "Hash";
#import "Hash_Table";

#import "DX11";
#import "d3d_compiler";
#import "dxgi";

#if OS == {
	case .WINDOWS;
		#import "Windows";
		#import "Windows_Utf8";
	case; #assert(false);
}

#load "src/engine/core.jai";
#load "src/engine/dx11.jai";
#load "src/engine/input.jai";
#load "src/engine/rendering.jai";
#load "src/engine/widgets.jai";

#load "src/code_editor/editor.jai";
#load "src/code_editor/coloring.jai";
#load "src/code_editor/events.jai";

#load "src/6502.jai";
#load "src/memory.jai";
#load "src/intrinsics.jai";
#load "src/gui.jai";
#load "src/utils.jai";
#load "src/files.jai";

// #load "tests.jai";
