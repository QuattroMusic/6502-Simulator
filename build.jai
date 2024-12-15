CompileFlag :: enum_flags {
    DEBUG;
    RELEASE;
}

// configs
app_name :: "6502 Simulator";

compile_type := CompileFlag.DEBUG;

#run {
    set_build_options_dc(.{do_output=false});
    make_directory_if_it_does_not_exist("out");
    
    args := get_build_options().compile_time_command_line;
    
    if args.count == 0 {
        print("Unprovided build option. Compiling with debug\n");
    } else {
        for arg: args {
            if arg == {
                case "R";
                    compile_type = .RELEASE;
                case;
                    print("Unrecognized option %\n", arg);
            }
        }
    }
    
	game_ws := setup_game_workspace();

	wait_until_workspace_has_finished(game_ws);

    reset_temporary_storage();  // just for good practice, even if it's not necessary!
}

setup_game_workspace :: () -> Workspace {
    w := compiler_create_workspace();
	compiler_begin_intercept(w);
    options := get_build_options(w);
    options.output_executable_name = app_name;
    options.output_path            = "out";
	if compile_type & .DEBUG then options.text_output_flags = 0;
	
    if       compile_type & .DEBUG    { options.backend = .X64;  set_optimization(*options, .DEBUG); }
    else if (compile_type & .RELEASE) { options.backend = .LLVM; set_optimization(*options, .OPTIMIZED); }
    else { assert(false); }

    set_build_options(options, w);
    add_build_file("first.jai", w);
    add_build_string(tprint("DEBUG :: %;", cast(bool)(compile_type & .DEBUG)), w);
    return w;
}

wait_until_workspace_has_finished :: (w: Workspace) {
    can_start := true;
    while can_start {
        message := compiler_wait_for_message();
        if message.workspace != w continue;
        if message.kind == .COMPLETE then break;
        if message.kind == .ERROR    then can_start = false;
    }
    compiler_end_intercept(w);
	if(!can_start) then exit(1);
}

#import "Compiler";
#import "Basic";
#import "File";
