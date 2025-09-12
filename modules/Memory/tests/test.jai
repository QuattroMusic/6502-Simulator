TESTING : enum { MODULE; UNWRAPS; } : .MODULE;

#import "Memory"(
    with_candidates = true,
    with_unwraps = TESTING == .UNWRAPS
);

#import "Basic";
#import "Compiler";
#import "Print_Color";
#import "Random";
#import "String";


SPAM_SMALL :: true;
STOP_ON_FAIL :: true;
VERBOSE :: false;

#if VERBOSE          BLOCK_SIZE :: 48;
else #if SPAM_SMALL  BLOCK_SIZE :: 33;
else                 BLOCK_SIZE :: 1024 * 1024 + 11;

#if SPAM_SMALL  ARENA_SIZE :: 4 * 1024 * 1024 + 11;
else            ARENA_SIZE :: BLOCK_SIZE * 4;

PROFILE_SKIP_TO :: 7;
PROFILE_VALIDATE_COPY :: false;
profile_iterations := 10000;

arena : [] u8;
sample : [] u8;

Copier :: struct {
    proc: #type (destination: *void, source: *void, count: s64);
    name: string;
};

#if TESTING == .MODULE {
    copiers :: Copier.[
        .{ copy,                 "copy"  },
        .{ copy_0,               "copy_0" },
        .{ copy_1_u64,           "copy_1_u64" },
        .{ copy_2_u64_128,       "copy_2_u64_128" },
        .{ copy_3_u64_256,       "copy_3_u64_256" },
        .{ copy_4_u64_256_asm,   "copy_4_u64_256_asm" },
        .{ copy_5_asm_rep,       "copy_5_asm_rep" },
        .{ copy_6_asm_rep_bytes, "copy_6_asm_rep_bytes" },
        .{ copy_10_sse_128,      "copy_10_sse_128" },
        .{ copy_11_sse_256,      "copy_11_sse_256" },
        .{ copy_12_sse_512,      "copy_12_sse_512" },
        .{ copy_13_sse_1024,     "copy_13_sse_1024" },
        .{ copy_20_avx_256,      "copy_20_avx_256" },
    ];
}
else {
    copiers :: Copier.[
        .{                                        copy_1_u64,                     "copy_1_u64" },
        .{                                        copy_3_u64_256,                 "copy_3_u64_256" },

        .{                                        copy_u64_unwrap_nocall_asm,     "copy_u64_unwrap_nocall_asm" },
        .{                                        copy_5_asm_rep,                 "copy_5_asm_rep" },

        .{                                        copy_u64_unwrap_nocall_assign,  "copy_u64_unwrap_nocall_assign" },
        .{ #bake_arguments copy_u64_unwrap(call = copy_256_inline_assign),        "copy_u64_unwrap_inline_assign" },
        .{ #bake_arguments copy_u64_unwrap(call = copy_256_expand_assign),        "copy_u64_unwrap_expand_assign" },

        .{                                        copy_u64_unwrap_nocall_index,   "copy_u64_unwrap_nocall_index" },
        .{ #bake_arguments copy_u64_unwrap(call = copy_256_inline_index),         "copy_u64_unwrap_inline_index" },
        .{ #bake_arguments copy_u64_unwrap(call = copy_256_expand_index),         "copy_u64_unwrap_expand_index" },

        .{                                        copy_u64_unwrap_nocall_array,   "copy_u64_unwrap_nocall_array" },
        .{ #bake_arguments copy_u64_unwrap(call = copy_256_inline_array),         "copy_u64_unwrap_inline_array" },
        .{ #bake_arguments copy_u64_unwrap(call = copy_256_expand_array),         "copy_u64_unwrap_expand_array" },
    ];
}


main :: () {
    mode : enum {CHECK; PROFILE;} = .CHECK;
    args := get_command_line_arguments();
    args.data += 1; args.count -= 1;
    for arg: args {
        if !arg  continue;

        i, ok := parse_int(*arg);
        if !ok {
            print("Options: Provide a number to enter profile mode and set iterations (0 for default)");
            exit(1);
        }

        if i  profile_iterations = i;
        mode = .PROFILE;
    }

    arena = NewArray(ARENA_SIZE, u8);

    sample = NewArray(BLOCK_SIZE, u8);
    #if VERBOSE {
        for 0 .. sample.count - 1
            sample[it] = cast,trunc(u8) (it % 15 + 1);
        verbose_print(sample);
    }
    else {
        random_seed(cast(u64) sample.data);
        for 0 .. sample.count - 1
            sample[it] = cast,trunc(u8) (it % 256);//random_get();
    }

    if mode == {
        case .CHECK;
        fails := 0;
        for copiers {
            fails += test_copy(it.name, it.proc);
            if STOP_ON_FAIL && fails
                break;
        }
        print(ifx fails then "\nFail!\n" else "\nAll OK!\n");

        case .PROFILE;
        print("Profiling % iterations:\n", profile_iterations);
        #if PROFILE_VALIDATE_COPY
            print("PROFILE_VALIDATE_COPY is ON!\n");
        for copiers {
            if it_index < PROFILE_SKIP_TO  continue;
            profile_copy(it.name, it.proc);
        }
    }
}


profile_copy :: (title: string, _copy: type_of(copy)) {
    print("%: ", title);

    destination := arena.data + random_get() % (ARENA_SIZE - BLOCK_SIZE);
    _copy(destination, sample.data, BLOCK_SIZE);

    start_time := seconds_since_init();
    for 1 .. profile_iterations {
        old_destination := destination;
        destination = arena.data + random_get() % (ARENA_SIZE - BLOCK_SIZE);
        _copy(destination, old_destination, BLOCK_SIZE);
        #if PROFILE_VALIDATE_COPY
            assert(is_sample(destination));
    }
    end_time := seconds_since_init();

    for < 40 .. title.count  print(" ");
    print("%\n", end_time - start_time);
}


test_copy :: (title: string, _copy: type_of(copy)) -> int {
    fails := 0;
    for 0 .. arena.count - 1
        arena[it] = 0;

    #if VERBOSE print("\n");
    print("\n");
    header := tprint("% | Intital |", title);
    destination := arena.data + BLOCK_SIZE + 3;
    _copy(destination, sample.data, BLOCK_SIZE);
    verbose_print(arena, "After initial copy:");
    fails += test(is_sample(destination), header, "Sample");
    fails += test(is_empty(arena.data, destination - arena.data), header, "Empty Before");
    fails += test(is_empty(destination + BLOCK_SIZE, arena.count - (destination + BLOCK_SIZE - arena.data)), header, "Empty After");

    header = tprint("% | Overlap |", title);
    old_destination := destination;
    destination += BLOCK_SIZE / 2 - 1;
    _copy(destination, old_destination, BLOCK_SIZE);
    verbose_print(arena, "After overlap copy:");
    fails += test(is_sample(destination), header, "Sample");
    fails += test(is_empty(arena.data, old_destination - arena.data), header, "Empty Before");
    fails += test(is_sample(old_destination, destination - old_destination), header, "Source Sample");
    fails += test(is_empty(destination + BLOCK_SIZE, arena.count - (destination + BLOCK_SIZE - arena.data)), header, "Empty After");

    return fails;
}


test :: (condition: bool, header: string, message: string) -> result: int {
    print("% %: ", header, message);
    if condition {
        print_color("OK\n", color = .GREEN);
        return 0;
    } else {
        print_color("FAIL\n", color = .RED);
        verbose_print(arena);
        return 1;
    }
}


is_empty :: (data: *u8, count: s64) -> bool {
    for 0 .. count - 1
        if data[it]  return false;
    return true;
}


is_sample :: (data: *u8, count := BLOCK_SIZE) -> bool {
    for 0 .. count - 1 {
        if data[it] != sample[it] {
            print("  <Sample mismatch at index %>\n", it);
            return false;
        }
    }
    return true;
}


verbose_print :: (buffer: []u8, title := "") #expand {
    #if VERBOSE {
        if title  print("%\n", title);
        for 0 .. buffer.count - 1 {
            if buffer[it]
                print("%", formatInt(buffer[it] % 16, base=16));
            else
                print(".");
            if (it + 1) % BLOCK_SIZE == 0
                print("\n");
        }
        for 0 .. BLOCK_SIZE - 1 {
            if it % 8 == 0
                print("|");
            else
                print(" ");
        }
        print("\n");
    }
}