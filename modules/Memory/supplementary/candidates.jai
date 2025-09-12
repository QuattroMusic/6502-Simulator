


// Simplest possible memcpy.
copy_0 :: (destination: *void, source: *void, count: s64) {
    d := cast(*u8) destination;  s := cast(*u8) source;

    overlapping := destination > source && destination < source + count;
    if !overlapping {
        for 0 .. count - 1
            d[it] = s[it];
    } else {
        for < count - 1 .. 0
            d[it] = s[it];
    }
}


// Use u64 for bulk.
copy_1_u64 :: (destination: *void, source: *void, count: s64) {
    d : *u64 = destination;  s : *u64 = source;
    chunk_count := count / 8;

    remainder_byte_offset := chunk_count * 8;
    remainder_byte_count := count - remainder_byte_offset;
    d_remainder : *u8 = destination + remainder_byte_offset;
    s_remainder : *u8 = source + remainder_byte_offset;

    overlapping := destination > source && destination < source + count;
    if !overlapping {
        for 0 .. chunk_count - 1
            d[it] = s[it];

        for 0 .. remainder_byte_count - 1
            d_remainder[it] = s_remainder[it];

    } else {
        for < remainder_byte_count - 1 .. 0
            d_remainder[it] = s_remainder[it];

        for < chunk_count - 1 .. 0
            d[it] = s[it];
    }
}


// Use u64 for bulk, unwrapped to do two copies at a time.
copy_2_u64_128 :: (destination: *void, source: *void, count: s64) {
    Chunk :: struct { u64s: [2] u64; };
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
            d_chunk.u64s[0] = s_chunk.u64s[0];
            d_chunk.u64s[1] = s_chunk.u64s[1];
        }

        for 0 .. remainder_byte_count - 1
            d_remainder[it] = s_remainder[it];

    } else {
        for < remainder_byte_count - 1 .. 0
            d_remainder[it] = s_remainder[it];

        for < chunk_count - 1 .. 0 {
            d_chunk := *d[it];  s_chunk := *s[it];
            d_chunk.u64s[1] = s_chunk.u64s[1];
            d_chunk.u64s[0] = s_chunk.u64s[0];
        }
    }
}


// Use u64 for bulk, unwrapped to do four copies at a time.
copy_3_u64_256 :: (destination: *void, source: *void, count: s64) {
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
            d_chunk.u64s[0] = s_chunk.u64s[0];
            d_chunk.u64s[1] = s_chunk.u64s[1];
            d_chunk.u64s[2] = s_chunk.u64s[2];
            d_chunk.u64s[3] = s_chunk.u64s[3];
        }

        for 0 .. remainder_byte_count - 1
            d_remainder[it] = s_remainder[it];

    } else {
        for < remainder_byte_count - 1 .. 0
            d_remainder[it] = s_remainder[it];

        for < chunk_count - 1 .. 0 {
            d_chunk := *d[it];  s_chunk := *s[it];
            d_chunk.u64s[3] = s_chunk.u64s[3];
            d_chunk.u64s[2] = s_chunk.u64s[2];
            d_chunk.u64s[1] = s_chunk.u64s[1];
            d_chunk.u64s[0] = s_chunk.u64s[0];
        }
    }
}


// Use u64 for bulk, unwrapped to do four copies at a time. Copy using #asm
copy_4_u64_256_asm :: (destination: *void, source: *void, count: s64) {
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
            #if CPU == .X64 {
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
            } else {
                d_chunk.u64s[0] = s_chunk.u64s[0];
                d_chunk.u64s[1] = s_chunk.u64s[1];
                d_chunk.u64s[2] = s_chunk.u64s[2];
                d_chunk.u64s[3] = s_chunk.u64s[3];
            }
        }

        for 0 .. remainder_byte_count - 1
            d_remainder[it] = s_remainder[it];

    } else {
        for < remainder_byte_count - 1 .. 0
            d_remainder[it] = s_remainder[it];

        for < chunk_count - 1 .. 0 {
            d_chunk := *d[it];  s_chunk := *s[it];
            #if CPU == .X64 {
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
            } else {
                d_chunk.u64s[3] = s_chunk.u64s[3];
                d_chunk.u64s[2] = s_chunk.u64s[2];
                d_chunk.u64s[1] = s_chunk.u64s[1];
                d_chunk.u64s[0] = s_chunk.u64s[0];
            }
        }
    }
}


// Use rep_movs for bulk
copy_5_asm_rep :: (destination: *void, source: *void, count: s64) {
    #if CPU != .X64 {
        copy_3_u64_256(destination, source, count);
    }
    else {
        u64_count := count / 8;
        remainder_byte_offset := u64_count * 8;
        remainder_byte_count := count - remainder_byte_offset;

        #asm {
            di: gpr === di;
            si: gpr === si;
            c:  gpr === c;
        }

        overlapping := destination > source && destination < source + count;
        if !overlapping {
            if u64_count > 0 {
                #asm {
                    cld;
                    mov.q di, destination;
                    mov.q si, source;
                    mov.q c, u64_count;
                    rep_movs.q di, si, c;
                }
            }
            if remainder_byte_count > 0 {
                #asm {
                    cld;
                    lea.q di, [destination + remainder_byte_offset];
                    lea.q si, [source + remainder_byte_offset];
                    mov.q c, remainder_byte_count;
                    rep_movs.b di, si, c;
                }
            }

        } else {
            if remainder_byte_count > 0 {
                #asm {
                    std;
                    lea.q di, [destination + count - 1];
                    lea.q si, [source + count - 1];
                    mov.q c, remainder_byte_count;
                    rep_movs.b di, si, c;
                }
            }
            if u64_count > 0 {
                #asm {
                    std;
                    lea.q di, [destination + remainder_byte_offset - 8];
                    lea.q si, [source + remainder_byte_offset - 8];
                    mov.q c, u64_count;
                    rep_movs.q di, si, c;
                }
            }
        }
    }
}


// Use single rep_movs.b to copy everything (wouldn't it be nice if this was as fast...)
copy_6_asm_rep_bytes :: (destination: *void, source: *void, count: s64) {
    #if CPU != .X64 {
        copy_3_u64_256(destination, source, count);
    }
    else {
        #asm {
            di: gpr === di;
            si: gpr === si;
            c:  gpr === c;
        }

        overlapping := destination > source && destination < source + count;
        if !overlapping {
            #asm {
                cld;
                mov.q di, destination;
                mov.q si, source;
                mov.q c, count;
                rep_movs.b di, si, c;
            }

        } else {
            #asm {
                std;
                lea.q di, [destination + count - 1];
                lea.q si, [source + count - 1];
                mov.q c, count;
                rep_movs.b di, si, c;
            }
        }
    }
}


// Use SSE for bulk.  SSE has been around since 1999... we're gonna assume it's universal on x64!
// To use movdqa (i.e. aligned move) source and destination would have to be aligned with each other,
// on top of which (from uops.info/table.html):
//    MOVDQA (M128, XMM)    [≤4;≤12]    0.50 / 0.50    1 / 2    1*p49+1*p78    [≤7;≤11]    0.50    1
//    MOVDQU (M128, XMM)    [≤4;≤12]    0.50 / 0.50    1 / 2    1*p49+1*p78    [≤7;≤11]    0.50    1
//    MOVDQA (XMM, M128)    [≤4;≤7]     0.33 / 0.33    1 / 1    1*p23A         [≤7;≤9]     0.50    1
//    MOVDQU (XMM, M128)    [≤4;≤7]     0.33 / 0.33    1 / 1    1*p23A         [≤7;≤9]     0.50    1
// ...there is no performance difference between movdqa and movdqu.  Therefor we're not going to worry about aligning.
copy_10_sse_128 :: (destination: *void, source: *void, count: s64) {
    Chunk :: struct { u64s: [2] u64; };
    d : *Chunk = destination;  s : *Chunk = source;
    chunk_count := count / size_of(Chunk);

    remainder_byte_offset := chunk_count * size_of(Chunk);
    remainder_byte_count := count - remainder_byte_offset;
    d_remainder : *u8 = destination + remainder_byte_offset;
    s_remainder : *u8 = source + remainder_byte_offset;

    copy_chunk :: #code {
    }

    overlapping := destination > source && destination < source + count;
    if !overlapping {
        for 0 .. chunk_count - 1 {
            d_chunk := *d[it];  s_chunk := *s[it];
            #if CPU == .X64 {
                #asm SSE {
                    movdqu.x t0:, [s_chunk];
                    movdqu.x [d_chunk], t0;
                }
            } else {
                d_chunk.u64s[0] = s_chunk.u64s[0];
                d_chunk.u64s[1] = s_chunk.u64s[1];
            }
        }

        for 0 .. remainder_byte_count - 1
            d_remainder[it] = s_remainder[it];

    } else {
        for < remainder_byte_count - 1 .. 0
            d_remainder[it] = s_remainder[it];

        for < chunk_count - 1 .. 0 {
            d_chunk := *d[it];  s_chunk := *s[it];
            #if CPU == .X64 {
                #asm SSE {
                    movdqu.x t0:, [s_chunk];
                    movdqu.x [d_chunk], t0;
                }
            } else {
                d_chunk.u64s[1] = s_chunk.u64s[1];
                d_chunk.u64s[0] = s_chunk.u64s[0];
            }
        }
    }
}


// Use SSE for bulk, unwrapped to do two mov at a time.
copy_11_sse_256 :: (destination: *void, source: *void, count: s64) {
    Chunk :: struct { u64s: [4] u64; };
    d : *Chunk = destination;  s : *Chunk = source;
    chunk_count := count / size_of(Chunk);

    remainder_byte_offset := chunk_count * size_of(Chunk);
    remainder_byte_count := count - remainder_byte_offset;
    d_remainder : *u8 = destination + remainder_byte_offset;
    s_remainder : *u8 = source + remainder_byte_offset;

    copy_chunk :: #code {
    }

    overlapping := destination > source && destination < source + count;
    if !overlapping {
        for 0 .. chunk_count - 1 {
            d_chunk := *d[it];  s_chunk := *s[it];
            #if CPU == .X64 {
                #asm SSE {
                    movdqu.x t0:, [s_chunk +  0];
                    movdqu.x t1:, [s_chunk + 16];
                    movdqu.x [d_chunk +  0], t0;
                    movdqu.x [d_chunk + 16], t1;
                }
            } else {
                d_chunk.u64s[0] = s_chunk.u64s[0];
                d_chunk.u64s[1] = s_chunk.u64s[1];
                d_chunk.u64s[2] = s_chunk.u64s[2];
                d_chunk.u64s[3] = s_chunk.u64s[3];
            }
        }

        for 0 .. remainder_byte_count - 1
            d_remainder[it] = s_remainder[it];

    } else {
        for < remainder_byte_count - 1 .. 0
            d_remainder[it] = s_remainder[it];

        for < chunk_count - 1 .. 0 {
            d_chunk := *d[it];  s_chunk := *s[it];
            #if CPU == .X64 {
                #asm SSE {
                    movdqu.x t0:, [s_chunk +  0];
                    movdqu.x t1:, [s_chunk + 16];
                    movdqu.x [d_chunk +  0], t0;
                    movdqu.x [d_chunk + 16], t1;
                }
            } else {
                d_chunk.u64s[3] = s_chunk.u64s[3];
                d_chunk.u64s[2] = s_chunk.u64s[2];
                d_chunk.u64s[1] = s_chunk.u64s[1];
                d_chunk.u64s[0] = s_chunk.u64s[0];
            }
        }
    }
}


// Use SSE for bulk, unwrapped to do four mov at a time.
copy_12_sse_512 :: (destination: *void, source: *void, count: s64) {
    Chunk :: struct { u64s: [8] u64; };
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
            #if CPU == .X64 {
                #asm SSE {
                    movdqu.x t0:, [s_chunk +  0];
                    movdqu.x t1:, [s_chunk + 16];
                    movdqu.x t2:, [s_chunk + 32];
                    movdqu.x t3:, [s_chunk + 48];
                    movdqu.x [d_chunk +  0], t0;
                    movdqu.x [d_chunk + 16], t1;
                    movdqu.x [d_chunk + 32], t2;
                    movdqu.x [d_chunk + 48], t3;
                }
            } else {
                d_chunk.u64s[0] = s_chunk.u64s[0];
                d_chunk.u64s[1] = s_chunk.u64s[1];
                d_chunk.u64s[2] = s_chunk.u64s[2];
                d_chunk.u64s[3] = s_chunk.u64s[3];
                d_chunk.u64s[4] = s_chunk.u64s[4];
                d_chunk.u64s[5] = s_chunk.u64s[5];
                d_chunk.u64s[6] = s_chunk.u64s[6];
                d_chunk.u64s[7] = s_chunk.u64s[7];
            }
        }

        for 0 .. remainder_byte_count - 1
            d_remainder[it] = s_remainder[it];

    } else {
        for < remainder_byte_count - 1 .. 0
            d_remainder[it] = s_remainder[it];

        for < chunk_count - 1 .. 0 {
            d_chunk := *d[it];  s_chunk := *s[it];
            #if CPU == .X64 {
                #asm SSE {
                    movdqu.x t0:, [s_chunk +  0];
                    movdqu.x t1:, [s_chunk + 16];
                    movdqu.x t2:, [s_chunk + 32];
                    movdqu.x t3:, [s_chunk + 48];
                    movdqu.x [d_chunk +  0], t0;
                    movdqu.x [d_chunk + 16], t1;
                    movdqu.x [d_chunk + 32], t2;
                    movdqu.x [d_chunk + 48], t3;
                }
            } else {
                d_chunk.u64s[7] = s_chunk.u64s[7];
                d_chunk.u64s[6] = s_chunk.u64s[6];
                d_chunk.u64s[5] = s_chunk.u64s[5];
                d_chunk.u64s[4] = s_chunk.u64s[4];
                d_chunk.u64s[3] = s_chunk.u64s[3];
                d_chunk.u64s[2] = s_chunk.u64s[2];
                d_chunk.u64s[1] = s_chunk.u64s[1];
                d_chunk.u64s[0] = s_chunk.u64s[0];
            }
        }
    }
}


// Use SSE for bulk, unwrapped to do four mov at a time.
copy_13_sse_1024 :: (destination: *void, source: *void, count: s64) {
    Chunk :: struct { u64s: [16] u64; };
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
            #if CPU == .X64 {
                #asm SSE {
                    movdqu.x t0:, [s_chunk +   0];
                    movdqu.x t1:, [s_chunk +  16];
                    movdqu.x t2:, [s_chunk +  32];
                    movdqu.x t3:, [s_chunk +  48];
                    movdqu.x t4:, [s_chunk +  64];
                    movdqu.x t5:, [s_chunk +  80];
                    movdqu.x t6:, [s_chunk +  96];
                    movdqu.x t7:, [s_chunk + 112];
                    movdqu.x [d_chunk +   0], t0;
                    movdqu.x [d_chunk +  16], t1;
                    movdqu.x [d_chunk +  32], t2;
                    movdqu.x [d_chunk +  48], t3;
                    movdqu.x [d_chunk +  64], t4;
                    movdqu.x [d_chunk +  80], t5;
                    movdqu.x [d_chunk +  96], t6;
                    movdqu.x [d_chunk + 112], t7;
                }
            }
        }

        for 0 .. remainder_byte_count - 1
            d_remainder[it] = s_remainder[it];

    } else {
        for < remainder_byte_count - 1 .. 0
            d_remainder[it] = s_remainder[it];

        for < chunk_count - 1 .. 0 {
            d_chunk := *d[it];  s_chunk := *s[it];
            #if CPU == .X64 {
                #asm SSE {
                    movdqu.x t0:, [s_chunk +   0];
                    movdqu.x t1:, [s_chunk +  16];
                    movdqu.x t2:, [s_chunk +  32];
                    movdqu.x t3:, [s_chunk +  48];
                    movdqu.x t4:, [s_chunk +  64];
                    movdqu.x t5:, [s_chunk +  80];
                    movdqu.x t6:, [s_chunk +  96];
                    movdqu.x t7:, [s_chunk + 112];
                    movdqu.x [d_chunk +   0], t0;
                    movdqu.x [d_chunk +  16], t1;
                    movdqu.x [d_chunk +  32], t2;
                    movdqu.x [d_chunk +  48], t3;
                    movdqu.x [d_chunk +  64], t4;
                    movdqu.x [d_chunk +  80], t5;
                    movdqu.x [d_chunk +  96], t6;
                    movdqu.x [d_chunk + 112], t7;
                }
            }
        }
    }
}


has_avx : enum { UNDETERMINED :: -1; NO; YES; } = .UNDETERMINED;


// Use AVX for bulk.  Not universal, need to check for it.  Requires an import, not so good.
copy_20_avx_256 :: (destination: *void, source: *void, count: s64) {
    machine :: #import "Machine_X64";
    if has_avx == .UNDETERMINED {
        info := machine.get_cpu_info();
        has_avx = ifx machine.check_feature(info.feature_leaves, .AVX)
                  then .YES
                  else .NO;
    }
    if !has_avx {
        // fallback to SSE
        copy_11_sse_256(destination, source, count);
        return;
    }

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
            d_chunk := *d[it];  s_chunk := *s[it];
            #asm AVX {
                movdqu.y t0:, [s_chunk +  0];
                movdqu.y [d_chunk +  0], t0;
            }
        }

        for 0 .. remainder_byte_count - 1
            d_remainder[it] = s_remainder[it];

    } else {
        for < remainder_byte_count - 1 .. 0
            d_remainder[it] = s_remainder[it];

        for < chunk_count - 1 .. 0 {
            d_chunk := *d[it];  s_chunk := *s[it];
            #asm AVX {
                movdqu.y t0:, [s_chunk +  0];
                movdqu.y [d_chunk +  0], t0;
            }
        }
    }
}




#scope_file




print_u64_bytes :: (n: *u64) {
    basic :: #import "Basic";
    b := cast(*u8) n;
    basic.print("%: ", basic.formatInt(cast(u64) b, base=16));
    for 0 .. 7
        basic.print("%", basic.formatInt(b[it], base=16));
    basic.print("\n");
}

print_256_bytes :: (n: *void) {
    basic :: #import "Basic";
    b := cast(*u8) n;
    basic.print("%: ", basic.formatInt(cast(u64) b, base=16));
    for 0 .. 31
        basic.print("%", basic.formatInt(b[it], base=16));
    basic.print("\n");
}

//memcpy :: (dest: *void, source: *void, count: s64) #intrinsic;

//compare :: (a: *void, b: *void, count: s64) -> s16  #intrinsic;  //
// @Incomplete: Do we want to tell people how many bytes in the first difference is?
// @Incomplete: The C spec for this routine sucks; we should probably return the actual byte difference.
//              But the bytecode_runner version uses the C library version which just returns <=>0.
//              I don't really want to inherit this ill-defined version. Unless we think it really doesn't matter. I dunno.

// set :: (dest: *void, value: u8, count: s64)     #intrinsic;


