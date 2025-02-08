#assert(OS == .WINDOWS);

// Since compile-time debugging is still tricky, it can sometimes be useful to compile this script into a binary and run that instead of generating the bindings at compile-time.
AT_COMPILE_TIME :: true;

PREFIXES_FOR_TYPES_TO_OMIT :: string.[
    "__REQUIRED_",
    "LP",
    // Omit all the COM garbage
    "IID_",
    "__MIDL_",
];

TYPES_TO_OMIT :: string.[
    "WKPDID_D3DDebugObjectName", // Defined manually
    "INTERFACE", // Frequently re-declared macro

     // We want these to be part of module "d3d_compiler" instead.
    "ID3D10Blob",
    "ID3D11Linker",
    "ID3D11Module",
    "ID3D11ModuleInstance",
    "ID3DBlob",
    "ID3DInclude",
    "_D3D_INCLUDE_TYPE",
    "_D3D_SHADER_MACRO",
];

ENUM_FLAGS :: string.[
    "D3D_COMPONENT_MASK",
    "D3D_SHADER_REQUIRES",
];

#if AT_COMPILE_TIME {
    #run,stallable {
        set_build_options_dc(.{do_output=false});
        if !generate_all_bindings() {
            compiler_set_workspace_status(.FAILED);
        }
    }
} else {
    #import "System";

    main :: () {
        set_working_directory(path_strip_filename(get_path_of_running_executable()));
        if !generate_all_bindings() {
            exit(1);
        }
    }
}

generate_all_bindings :: () -> bool {
    success := generate_bindings_variant("d3d11_bindings.jai", .["d3d11.h", "d3d11_1.h", "d3d11shader.h", "d3dcommon.h"]);
    success &&= generate_bindings_variant("d3d11_debug_bindings.jai", .["d3d11sdklayers.h"]);
    return success;
}

generate_bindings_variant :: (output_filename: string, system_paths: [] string) -> bool {
    opts: Generate_Bindings_Options;
    {
        using opts;

        array_add(*libnames, "d3d11.dll");

        array_add(*source_files, "d3d11.h");
        array_add(*source_files, "d3d11_1.h");
        array_add(*source_files, "d3d11shader.h");

        array_add(*path_fragments_to_treat_as_non_system_paths, ..system_paths);

        array_add(*extra_clang_arguments, "-x", "c++", "-DWIN32_LEAN_AND_MEAN");

        mimic_spacing_flags &= ~Mimic_Spacing_Flags.VTABLE;
        log_stripped_declarations = false;
        generate_compile_time_struct_checks = false;
        array_add(*generate_enums_from_macros_with_prefixes,
            "D3D_COMPONENT_MASK",
            "D3D_SHADER_REQUIRES",
        );

        visitor = d3d_visitor;
    }

    return generate_bindings(opts, output_filename);
}

#scope_file

d3d_visitor :: (decl: *Declaration, parent_decl: *Declaration) -> Declaration_Visit_Result {
    // Make unnecessary typedefs for enums and structs disappear
    if (decl.kind == .STRUCT || decl.kind == .ENUM) && decl.output_name.count > 2 && decl.output_name[0] == #char "_" && decl.output_name[1] !=  #char "_" {
        advance(*decl.output_name);
    }

    if !parent_decl {
        if array_find(TYPES_TO_OMIT, decl.name) {
            decl.decl_flags |= .OMIT_FROM_OUTPUT;
            return .STOP;
        }
        for PREFIXES_FOR_TYPES_TO_OMIT {
            if begins_with(decl.name, it) {
                decl.decl_flags |= .OMIT_FROM_OUTPUT;
                return .STOP;
            }
        }
    }

    if decl.kind == .ENUM {
        if ends_with(decl.name, "FLAG") || ends_with(decl.name, "FLAGS") || array_find(ENUM_FLAGS, decl.name) {
            en := cast(*Enum)decl;
            en.flags |= .IS_ENUM_FLAGS;
            en.flags |= .VALUES_IN_HEX;

            if en.type {
                // Clang on Windows claims that all enums are signed, but MS function declarations expects at least the flags to be unsigned
                if en.type.size == {
                    case 1;
                        en.type = context.generator.type_def_u8;
                    case 2;
                        en.type = context.generator.type_def_u16;
                    case 4;
                        en.type = context.generator.type_def_u32;
                    case 8;
                        en.type = context.generator.type_def_u64;
                }
            }
        }
    }

    // Replace integers with their corresponding enum flags, where possible
    if parent_decl && (parent_decl.kind == .FUNCTION || parent_decl.kind == .STRUCT) && decl.kind == .DECLARATION && decl.type.number_flags {
        new_name := get_enum_name(decl.name, parent_decl.name);
        if !new_name    return .RECURSE;

        // log("% -> %\n", decl.name, new_name);
        change_type_to_enum(decl, new_name);
    }

    return .RECURSE;
}

get_enum_name :: (argument_name: string, parent_name: string) -> string {
    if argument_name == {
        case "BindFlags";
            return "D3D11_BIND_FLAG";
        case "CPUAccessFlags";
            return "D3D11_CPU_ACCESS_FLAG";
        case "MiscFlags";
            return "D3D11_RESOURCE_MISC_FLAG";
        case "Flags";
            if parent_name == {
                case "D3D11CreateDevice";
                    return "D3D11_CREATE_DEVICE_FLAG";
            }
    }

    return "";
}

#import "Basic";
#import "Bindings_Generator";
#import "Compiler";
#import "File";
#import "String";

