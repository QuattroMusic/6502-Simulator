fetch_window_inputs :: () {
	Input.update_window_events();
	for Input.events_this_frame if it.type == .QUIT then vp.running = false;
	
	// if condition only because it's also called when moving the window
	for Input.get_window_resizes() if it.width != vp.width || it.height != vp.height {
		vp.width  = it.width;
		vp.height = it.height;
		resize_viewport();
	}

	mouse_x, mouse_y = WC.get_mouse_pointer_position(vp.window, right_handed = false);
}

is_mouse_pressed :: ($key: int) -> bool {
	     #if key == 0 state := Input.input_button_states[Input.Key_Code.MOUSE_BUTTON_LEFT];
	else #if key == 1 state := Input.input_button_states[Input.Key_Code.MOUSE_BUTTON_RIGHT];
	else #if key == 2 state := Input.input_button_states[Input.Key_Code.MOUSE_BUTTON_MIDDLE];
	else #assert(false);
	
	comb :: (Input.Key_Current_State.DOWN | Input.Key_Current_State.START);
	
	return state == comb;
}

is_mouse_down :: ($key: int) -> bool {
	     #if key == 0 state := Input.input_button_states[Input.Key_Code.MOUSE_BUTTON_LEFT];
	else #if key == 1 state := Input.input_button_states[Input.Key_Code.MOUSE_BUTTON_RIGHT];
	else #if key == 2 state := Input.input_button_states[Input.Key_Code.MOUSE_BUTTON_MIDDLE];
	else #assert(false);
	
	comb :: Input.Key_Current_State.DOWN;
	
	return state == comb;
}

is_mouse_released :: ($key: int) -> bool {
	     #if key == 0 state := Input.input_button_states[Input.Key_Code.MOUSE_BUTTON_LEFT];
	else #if key == 1 state := Input.input_button_states[Input.Key_Code.MOUSE_BUTTON_RIGHT];
	else #if key == 2 state := Input.input_button_states[Input.Key_Code.MOUSE_BUTTON_MIDDLE];
	else #assert(false);
	
	comb :: (Input.Key_Current_State.DOWN | Input.Key_Current_State.END);
	
	return state == comb;
}

mouse_x: int;
mouse_y: int;
