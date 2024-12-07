fetch_window_inputs :: () {
	memcpy(input_button_states_old.data, input_button_states.data, size_of(type_of(input_button_states)));
	memcpy(input_keyboard_states_old.data, input_keyboard_states.data, size_of(type_of(input_keyboard_states)));
	mouse_dz = 0;
	pressed_char = 0;
	
	while true {
		msg: MSG;
		if !PeekMessageA(*msg, null, 0, 0, 1) then break;
		
		TranslateMessage(*msg);
		DispatchMessageA(*msg);
	}
}

reset_input :: () {
	vp.enable_movement = false;
	vp.enable_resizing = false;
	
	mouse_dz = 0;
	
	memset(input_button_states.data,       0, size_of(type_of(input_button_states)));
	memset(input_button_states_old.data,   0, size_of(type_of(input_button_states_old)));
	memset(input_keyboard_states.data,     0, size_of(type_of(input_keyboard_states)));
	memset(input_keyboard_states_old.data, 0, size_of(type_of(input_keyboard_states_old)));
}

is_mouse_pressed  :: (key: int) -> bool { return  input_button_states[key] && !input_button_states_old[key]; }
is_mouse_down     :: (key: int) -> bool { return  input_button_states[key]; }
is_mouse_released :: (key: int) -> bool { return !input_button_states[key] &&  input_button_states_old[key]; }
is_mouse_up       :: (key: int) -> bool { return !input_button_states[key]; }

is_key_pressed  :: (key: int) -> bool { return  input_keyboard_states[key] && !input_keyboard_states_old[key]; }
is_key_down     :: (key: int) -> bool { return  input_keyboard_states[key]; }
is_key_released :: (key: int) -> bool { return !input_keyboard_states[key] &&  input_keyboard_states_old[key]; }

mouse_x: int;
mouse_y: int;
mouse_dz: int;

last_down_char: u8;
pressed_char: u8;

input_button_states: [3]bool;
input_button_states_old: [3]bool;

input_keyboard_states: [0xFF]bool;
input_keyboard_states_old: [0xFF]bool;

KEY_DELETE :: 8;
KEY_ENTER  :: 13;
KEY_SHIFT  :: 16;
KEY_CTRL   :: 17;
KEY_ALT    :: 18;
KEY_ESC    :: 27;
KEY_SPACE  :: 32;
KEY_LEFT   :: 37;
KEY_UP     :: 38;
KEY_RIGHT  :: 39;
KEY_DOWN   :: 40;
KEY_F1     :: 112;
KEY_F2     :: 113;
KEY_F3     :: 114;
KEY_F4     :: 115;
KEY_F5     :: 116;
KEY_F6     :: 117;
KEY_F7     :: 118;
KEY_F8     :: 119;
KEY_F9     :: 120;
KEY_F10    :: 121;
KEY_F11    :: 122;
KEY_F12    :: 123;
