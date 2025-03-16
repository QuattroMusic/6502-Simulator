fetch_window_inputs :: () {
	for input_keyboard_states {
		if      it & .PRESSED || it & .REPEATED then input_keyboard_states[it_index] = .DOWN;
		else if it & .RELEASED                  then input_keyboard_states[it_index] = .UP;
	}
	
	for input_button_states {
		if      it & .PRESSED  then input_button_states[it_index] = .DOWN;
		else if it & .RELEASED then input_button_states[it_index] = .UP;
	}
	
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
	
	memset(input_keyboard_states.data, xx Button_State.UP, size_of(type_of(input_keyboard_states)));
	memset(input_button_states.data,   xx Button_State.UP, size_of(type_of(input_button_states)));
}

is_mouse_down     :: (key: u8) -> bool { return cast(bool, input_button_states[key] & .DOWN);     }
is_mouse_up       :: (key: u8) -> bool { return cast(bool, input_button_states[key] & .UP);       }
is_mouse_pressed  :: (key: u8) -> bool { return cast(bool, input_button_states[key] & .PRESSED);  }
is_mouse_released :: (key: u8) -> bool { return cast(bool, input_button_states[key] & .RELEASED); }

is_key_down     :: (key: u8) -> bool { return cast(bool, input_keyboard_states[key] & .DOWN);     }
is_key_up       :: (key: u8) -> bool { return cast(bool, input_keyboard_states[key] & .UP);       }
is_key_pressed  :: (key: u8) -> bool { return cast(bool, input_keyboard_states[key] & .PRESSED);  }
is_key_released :: (key: u8) -> bool { return cast(bool, input_keyboard_states[key] & .RELEASED); }
is_key_pressed_or_repeated :: (key: u8) -> bool {
	return cast(bool, input_keyboard_states[key] & .PRESSED || input_keyboard_states[key] & .REPEATED);
}

mouse_x:  int;
mouse_y:  int;
mouse_dz: int;

last_down_char: u8;
pressed_char:   u8;

input_button_states:     [3] Button_State;
input_button_states_old: [3] Button_State;

input_keyboard_states:     [0xFF] Button_State;
input_keyboard_states_old: [0xFF] Button_State;

Button_State :: enum_flags u8 {
	UP;
	DOWN;
	PRESSED;
	RELEASED;
	REPEATED;
}

KEY_DELETE :: 8;
KEY_TAB    :: 9;
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
