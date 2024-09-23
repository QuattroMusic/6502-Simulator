fetch_window_inputs :: () {
	memcpy(input_button_states_old.data, input_button_states.data, size_of(type_of(input_button_states)));
	mouse_dz = 0;
	
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
	
	memset(input_button_states.data, 0, size_of(type_of(input_button_states)));
	memset(input_button_states_old.data, 0, size_of(type_of(input_button_states_old)));
}

is_mouse_pressed  :: (key: int) -> bool { return  input_button_states[key] && !input_button_states_old[key]; }
is_mouse_down     :: (key: int) -> bool { return  input_button_states[key] &&  input_button_states_old[key]; }
is_mouse_released :: (key: int) -> bool { return !input_button_states[key] &&  input_button_states_old[key]; }

mouse_x: int;
mouse_y: int;
mouse_dz: int;

input_button_states: [3]bool;
input_button_states_old: [3]bool;
