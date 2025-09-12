fetch_window_inputs :: () {
	keyboard_mask :: ~(Button_State.PRESSED | .REPEATED | .RELEASED);
	mouse_mask    :: ~(Button_State.PRESSED | .RELEASED);
	
	for * input_keyboard_states it.* &= keyboard_mask;
	for * input_mouse_states    it.* &= mouse_mask;
	
	mouse_dz = 0;
	pressed_char = 0;
	
	while true {
		msg: MSG;
		if !PeekMessageA(*msg, vp.window, 0, 0, 1) then break;
		
		TranslateMessage(*msg);
		DispatchMessageA(*msg);
	}
}

reset_input :: () {
	mouse_dz = 0;
	
	memset(input_keyboard_states.data, xx Button_State.UP, size_of(type_of(input_keyboard_states)));
	memset(input_mouse_states.data,    xx Button_State.UP, size_of(type_of(input_mouse_states)));
}

is_mouse_down     :: (key: u8) -> bool { return cast(bool, input_mouse_states[key] & .DOWN);     }
is_mouse_pressed  :: (key: u8) -> bool { return cast(bool, input_mouse_states[key] & .PRESSED);  }
is_mouse_released :: (key: u8) -> bool { return cast(bool, input_mouse_states[key] & .RELEASED); }

is_key_down     :: (key: u8) -> bool { return cast(bool, input_keyboard_states[key] & .DOWN);     }
is_key_pressed  :: (key: u8) -> bool { return cast(bool, input_keyboard_states[key] & .PRESSED);  }
is_key_released :: (key: u8) -> bool { return cast(bool, input_keyboard_states[key] & .RELEASED); }
is_key_pressed_or_repeated :: (key: u8) -> bool {
	return cast(bool, input_keyboard_states[key] & .PRESSED || input_keyboard_states[key] & .REPEATED);
}

mouse_x:  s64;
mouse_y:  s64;
mouse_dz: s64;

last_down_key: u8;
pressed_char:  u8;

input_mouse_states:    [  3] Button_State;
input_keyboard_states: [256] Button_State;

Button_State :: enum_flags u8 {
	UP;
	DOWN;
	PRESSED;
	RELEASED;
	REPEATED;
}

KEY_CANC  :: 8;
KEY_TAB   :: 9;
KEY_ENTER :: 13;
KEY_SHIFT :: 16;
KEY_CTRL  :: 17;
KEY_ALT   :: 18;
KEY_ESC   :: 27;
KEY_SPACE :: 32;
KEY_END   :: 35;
KEY_LEFT  :: 37;
KEY_UP    :: 38;
KEY_RIGHT :: 39;
KEY_DOWN  :: 40;
KEY_DEL   :: 46;
KEY_C     :: 67;
KEY_S     :: 83;
KEY_V     :: 86;
