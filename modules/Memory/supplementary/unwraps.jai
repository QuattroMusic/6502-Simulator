    // Results for unwrapping u64 copies 4 times
//                                              Release         Debug
//  Iterations:                                  54700          10000
//
//  copy_1_u64:                                3.520019       3.530780
//
//  copy_u64_unwrap_nocall_assign:             3.043285       3.269025
//  copy_u64_unwrap_inline_assign:             3.034988       4.013193
//  copy_u64_unwrap_expand_assign:             3.040267       3.974446
//
//  copy_u64_unwrap_nocall_index:              3.031852       3.274672
//  copy_u64_unwrap_inline_index:              3.036169       3.546539
//  copy_u64_unwrap_expand_index:              3.042943       3.505168
//
//  copy_u64_unwrap_nocall_array:              3.032380       2.177410
//  copy_u64_unwrap_inline_array:              3.028305       2.385768
//  copy_u64_unwrap_expand_array:              3.042297       2.377192
//
// N.B. Further testing seems to indicate that #insert,scope() does not suffer the same performance hit


// unwrap proc that takes in it's 256-bit copy method
copy_u64_unwrap :: (destination: *void, source: *void, count: s64, $call: type_of(copy_256)) {
    Chunk :: struct { bytes: [32] u8; };
    d : *Chunk = destination;  s : *Chunk = source;
    chunk_count := count / size_of(Chunk);

    remainder_byte_offset := chunk_count * size_of(Chunk);
    remainder_byte_count := count - remainder_byte_offset;
    d_remainder : *u8 = destination + remainder_byte_offset;
    s_remainder : *u8 = source + remainder_byte_offset;

    overlapping := destination > source && destination < source + count;
    if !overlapping {
        for 0 .. chunk_count - 1
            call(*d[it], *s[it]);

        for 0 .. remainder_byte_count - 1
            d_remainder[it] = s_remainder[it];

    } else {
        for < remainder_byte_count - 1 .. 0
            d_remainder[it] = s_remainder[it];

        for < chunk_count - 1 .. 0
            call(*d[it], *s[it]);
    }
}



// unwrap without calling out to something else, by assigning via 4 *u64
copy_u64_unwrap_nocall_assign :: (destination: *void, source: *void, count: s64) {
    Chunk :: struct { bytes: [32] u8; };
    d : *Chunk = destination;  s : *Chunk = source;
    chunk_count := count / size_of(Chunk);

    remainder_byte_offset := chunk_count * size_of(Chunk);
    remainder_byte_count := count - remainder_byte_offset;
    d_remainder : *u8 = destination + remainder_byte_offset;
    s_remainder : *u8 = source + remainder_byte_offset;

    overlapping := destination > source && destination < source + count;
    if !overlapping {
        for 0 .. chunk_count - 1 {
            d_64 := cast(*u64) *d[it];
            s_64 := cast(*u64) *s[it];
            d_64[0] = s_64[0];
            d_64[1] = s_64[1];
            d_64[2] = s_64[2];
            d_64[3] = s_64[3];
        }

        for 0 .. remainder_byte_count - 1
            d_remainder[it] = s_remainder[it];

    } else {
        for < remainder_byte_count - 1 .. 0
            d_remainder[it] = s_remainder[it];

        for < chunk_count - 1 .. 0 {
            d_64 := cast(*u64) *d[it];
            s_64 := cast(*u64) *s[it];
            d_64[3] = s_64[3];
            d_64[2] = s_64[2];
            d_64[1] = s_64[1];
            d_64[0] = s_64[0];
        }
    }
}

// unwrap without calling out to something else, by assigning via an array of 4 u64
copy_u64_unwrap_nocall_index :: (destination: *void, source: *void, count: s64) {
    Chunk :: struct { bytes: [32] u8; };
    d : *Chunk = destination;  s : *Chunk = source;
    chunk_count := count / size_of(Chunk);

    remainder_byte_offset := chunk_count * size_of(Chunk);
    remainder_byte_count := count - remainder_byte_offset;
    d_remainder : *u8 = destination + remainder_byte_offset;
    s_remainder : *u8 = source + remainder_byte_offset;

    overlapping := destination > source && destination < source + count;
    if !overlapping {
        for 0 .. chunk_count - 1 {
            d_64 := cast(*u64) *d[it];
            s_64 := cast(*u64) *s[it];
            d_64[0] = s_64[0];
            d_64[1] = s_64[1];
            d_64[2] = s_64[2];
            d_64[3] = s_64[3];
        }

        for 0 .. remainder_byte_count - 1
            d_remainder[it] = s_remainder[it];

    } else {
        for < remainder_byte_count - 1 .. 0
            d_remainder[it] = s_remainder[it];

        for < chunk_count - 1 .. 0 {
            d_64 := cast(*u64) *d[it];
            s_64 := cast(*u64) *s[it];
            d_64[3] = s_64[3];
            d_64[2] = s_64[2];
            d_64[1] = s_64[1];
            d_64[0] = s_64[0];
        }
    }
}

// unwrap without calling out to something else, by assigning via an array of 4 u64, manually dereferenced
copy_u64_unwrap_nocall_array :: (destination: *void, source: *void, count: s64) {
    Chunk :: struct { bytes: [32] u8; };
    d : *Chunk = destination;  s : *Chunk = source;
    chunk_count := count / size_of(Chunk);

    remainder_byte_offset := chunk_count * size_of(Chunk);
    remainder_byte_count := count - remainder_byte_offset;
    d_remainder : *u8 = destination + remainder_byte_offset;
    s_remainder : *u8 = source + remainder_byte_offset;

    overlapping := destination > source && destination < source + count;
    if !overlapping {
        for 0 .. chunk_count - 1 {
            d_64 := cast(*[4]u64) *d[it];
            s_64 := cast(*[4]u64) *s[it];
            d_64.*[0] = s_64.*[0];
            d_64.*[1] = s_64.*[1];
            d_64.*[2] = s_64.*[2];
            d_64.*[3] = s_64.*[3];
        }

        for 0 .. remainder_byte_count - 1
            d_remainder[it] = s_remainder[it];

    } else {
        for < remainder_byte_count - 1 .. 0
            d_remainder[it] = s_remainder[it];

        for < chunk_count - 1 .. 0 {
            d_64 := cast(*[4]u64) *d[it];
            s_64 := cast(*[4]u64) *s[it];
            d_64.*[3] = s_64.*[3];
            d_64.*[2] = s_64.*[2];
            d_64.*[1] = s_64.*[1];
            d_64.*[0] = s_64.*[0];
        }
    }
}

// unwrap using asm
copy_u64_unwrap_nocall_asm :: (destination: *void, source: *void, count: s64) {
    Chunk :: struct { u64s: [4] u64; };
    d : *Chunk = destination;  s : *Chunk = source;
    chunk_count := count / size_of(Chunk);

    remainder_byte_offset := chunk_count * size_of(Chunk);
    remainder_byte_count := count - remainder_byte_offset;
    d_remainder : *u8 = destination + remainder_byte_offset;
    s_remainder : *u8 = source + remainder_byte_offset;

    overlapping := destination > source && destination < source + count;
    if !overlapping {
        for 0 .. chunk_count - 1 {
            d_chunk := *d[it];  s_chunk := *s[it];
            #asm {
                mov.q t0:, [s_chunk +  0];
                mov.q t1:, [s_chunk +  8];
                mov.q t2:, [s_chunk + 16];
                mov.q t3:, [s_chunk + 24];
                mov.q [d_chunk +  0], t0;
                mov.q [d_chunk +  8], t1;
                mov.q [d_chunk + 16], t2;
                mov.q [d_chunk + 24], t3;
            }
        }

        for 0 .. remainder_byte_count - 1
            d_remainder[it] = s_remainder[it];

    } else {
        for < remainder_byte_count - 1 .. 0
            d_remainder[it] = s_remainder[it];

        for < chunk_count - 1 .. 0 {
            d_chunk := *d[it];  s_chunk := *s[it];
            #asm {
                mov.q t3:, [s_chunk + 24];
                mov.q t2:, [s_chunk + 16];
                mov.q t1:, [s_chunk +  8];
                mov.q t0:, [s_chunk +  0];
                mov.q [d_chunk +  0], t0;
                mov.q [d_chunk +  8], t1;
                mov.q [d_chunk + 16], t2;
                mov.q [d_chunk + 24], t3;
            }
        }
    }
}


copy_256_inline_assign ::      inline (destination: *void, source: *void) {
    (cast(*u64)(destination +  0)).* = (cast(*u64)(source +  0)).*;
    (cast(*u64)(destination +  8)).* = (cast(*u64)(source +  8)).*;
    (cast(*u64)(destination + 16)).* = (cast(*u64)(source + 16)).*;
    (cast(*u64)(destination + 24)).* = (cast(*u64)(source + 24)).*;
}

copy_256_expand_assign :: (destination: *void, source: *void) #expand {
    (cast(*u64)(destination +  0)).* = (cast(*u64)(source +  0)).*;
    (cast(*u64)(destination +  8)).* = (cast(*u64)(source +  8)).*;
    (cast(*u64)(destination + 16)).* = (cast(*u64)(source + 16)).*;
    (cast(*u64)(destination + 24)).* = (cast(*u64)(source + 24)).*;
}

copy_256_inline_index :: inline (destination: *void, source: *void) {
    d_64 := cast(*u64) destination;
    s_64 := cast(*u64) source;
    d_64[0] = s_64[0];
    d_64[1] = s_64[1];
    d_64[2] = s_64[2];
    d_64[3] = s_64[3];
}

copy_256_expand_index :: (destination: *void, source: *void) #expand {
    d_64 := cast(*u64) destination;
    s_64 := cast(*u64) source;
    d_64[0] = s_64[0];
    d_64[1] = s_64[1];
    d_64[2] = s_64[2];
    d_64[3] = s_64[3];
}

copy_256_inline_array :: inline (destination: *void, source: *void) {
    d_64 := cast(*[4]u64) destination;
    s_64 := cast(*[4]u64) source;
    d_64.*[0] = s_64.*[0];
    d_64.*[1] = s_64.*[1];
    d_64.*[2] = s_64.*[2];
    d_64.*[3] = s_64.*[3];
}

copy_256_expand_array :: (destination: *void, source: *void) #expand {
    d_64 := cast(*[4]u64) destination;
    s_64 := cast(*[4]u64) source;
    d_64.*[0] = s_64.*[0];
    d_64.*[1] = s_64.*[1];
    d_64.*[2] = s_64.*[2];
    d_64.*[3] = s_64.*[3];
}


copy_128 :: inline (destination: *void, source: *void) {
    (cast(*u64)(destination + 0)).* = (cast(*u64)(source + 0)).*;
    (cast(*u64)(destination + 8)).* = (cast(*u64)(source + 8)).*;
}


copy_256 :: inline (destination: *void, source: *void) {
    //d : *u64 = destination;  s : *u64 = destination;
    //d[0] = s[0];
    //d[1] = s[1];
    //d[2] = s[2];
    //d[3] = s[3];
    (cast(*u64)(destination +  0)).* = (cast(*u64)(source +  0)).*;
    (cast(*u64)(destination +  8)).* = (cast(*u64)(source +  8)).*;
    (cast(*u64)(destination + 16)).* = (cast(*u64)(source + 16)).*;
    (cast(*u64)(destination + 24)).* = (cast(*u64)(source + 24)).*;
}


sse_copy_128 :: inline (destination: *void, source: *void) {
    #if CPU == .X64 {
        #asm SSE {
            movdqu.x t0:, [source];
            movdqu.x [destination], t0;
        }
    } else {
        copy_128(destination, source);
    }
}


sse_copy_256 :: inline (destination: *void, source: *void) {
    #if CPU == .X64 {
        #asm SSE {
            movdqu.x t0:, [source +  0];
            movdqu.x t1:, [source + 16];
            movdqu.x [destination +  0], t0;
            movdqu.x [destination + 16], t1;
        }
    } else {
        copy_256(destination +  0, source +  0);
    }
}


sse_copy_512 :: inline (destination: *void, source: *void) {
    #if CPU == .X64 {
        #asm SSE {
            movdqu.x t0:, [source +  0];
            movdqu.x t1:, [source + 16];
            movdqu.x t2:, [source + 32];
            movdqu.x t3:, [source + 48];
            movdqu.x [destination +  0], t0;
            movdqu.x [destination + 16], t1;
            movdqu.x [destination + 32], t2;
            movdqu.x [destination + 48], t3;
        }
    } else {
        copy_128(destination +  0, source +  0);
        copy_128(destination + 16, source + 16);
        copy_128(destination + 32, source + 32);
        copy_128(destination + 48, source + 48);
    }
}


sse_copy_1024 :: inline (destination: *void, source: *void) {
    #if CPU == .X64 {
        #asm SSE {
            movdqu.x t0:, [source +   0];
            movdqu.x t1:, [source +  16];
            movdqu.x t2:, [source +  32];
            movdqu.x t3:, [source +  48];
            movdqu.x t4:, [source +  64];
            movdqu.x t5:, [source +  80];
            movdqu.x t6:, [source +  96];
            movdqu.x t7:, [source + 112];
            movdqu.x [destination +   0], t0;
            movdqu.x [destination +  16], t1;
            movdqu.x [destination +  32], t2;
            movdqu.x [destination +  48], t3;
            movdqu.x [destination +  64], t4;
            movdqu.x [destination +  80], t5;
            movdqu.x [destination +  96], t6;
            movdqu.x [destination + 112], t7;
        }
    } else {
        copy_128(destination +   0, source +   0);
        copy_128(destination +  16, source +  16);
        copy_128(destination +  32, source +  32);
        copy_128(destination +  48, source +  48);
        copy_128(destination +  64, source +  64);
        copy_128(destination +  80, source +  80);
        copy_128(destination +  96, source +  96);
        copy_128(destination + 112, source + 112);
    }
}


avx_copy_256 :: inline (destination: *void, source: *void) {
    #assert CPU == .X64;
    #asm AVX {
        movdqu.y t0:, [source +  0];
        movdqu.y [destination +  0], t0;
    }
}
