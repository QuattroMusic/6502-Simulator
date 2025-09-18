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
    
	plugins_index := -1;
	
    if args.count == 0 {
        print("Unprovided build options. Compiling in debug\n");
    } else {
        for arg: args {
			if !arg then continue;
			
			if arg[0] == #char "-" {
				if arg == {
					case "-release";
						compile_type = .RELEASE;
					case;
						print("Unrecognized option %\n", arg);
				}
			} else if arg[0] == #char "+" {
				plugins_index = it_index;
				break;
			}
        }
    }
    
	// setup workspace
    w := compiler_create_workspace();
    options := get_build_options(w);
    options.output_executable_name = app_name;
    options.output_path            = "out";
	options.additional_linker_arguments = .["/NOIMPLIB", "/NOEXP"];
	if compile_type & .DEBUG then options.text_output_flags = 0;
	
    if       compile_type & .DEBUG    { options.backend = .X64;  set_optimization(*options, .DEBUG); }
    else if (compile_type & .RELEASE) { options.backend = .LLVM; set_optimization(*options, .OPTIMIZED); }

    set_build_options(options, w);
	
	// setup plugins
	plugins_to_create: [..]  Plugin_To_Create;
	plugins:           [..] *Metaprogram_Plugin;

    if plugins_index >= 0 {
        success:, plugins_to_create = parse_plugin_arguments(args, plugins_index);
		if !success {
			compiler_set_workspace_status(.FAILED);
		}
    }
	
	if compile_type & .DEBUG {
		p := array_add(*plugins_to_create);
		p.name = "Check";
	}
	
	init_plugins(plugins_to_create, *plugins, w);
	
	intercept_flags: Intercept_Flags;
	for plugins if it.before_intercept then it.before_intercept(it, *intercept_flags);
	
	compiler_begin_intercept(w, intercept_flags);
	
	for plugins if it.add_source then it.add_source(it);
	
	// add build files
    add_build_file("first.jai", w);
    add_build_string(tprint("DEBUG :: %;", cast(bool)(compile_type & .DEBUG)), w);

	// wait untile workspace has finished
    can_start := true;
    while can_start {
        message := compiler_wait_for_message();
		
		for plugins if it.message then it.message(it, message);
		
        if      message.kind == .COMPLETE then break;
        else if message.kind == .ERROR    then can_start = false;
    }
	
    compiler_end_intercept(w);
	
	for plugins if it.finish   then it.finish  (it);
    for plugins if it.shutdown then it.shutdown(it);
	
	if(!can_start) then compiler_set_workspace_status(.FAILED);
}

#import "Metaprogram_Plugins";
#import "Compiler";
#import "Basic";
#import "File";
