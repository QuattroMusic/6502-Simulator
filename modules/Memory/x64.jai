#assert CPU == .X64;

copy :: (destination: *void, source: *void, count: s64) {
    overlapping := destination > source && destination < source + count;

    u64_count := count / 8;
    remainder_byte_offset := u64_count * 8;
    remainder_byte_count := count - remainder_byte_offset;

    // Timings indicate this cutoff should be a little higher, probably 64, but for simplicity will leave it at this for now.
    if count > 32 {
        #asm {
            di: gpr === di;
            si: gpr === si;
            c:  gpr === c;
        }

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
					cld;
                }
            }
            if u64_count > 0 {
                #asm {
                    std;
                    lea.q di, [destination + remainder_byte_offset - 8];
                    lea.q si, [source + remainder_byte_offset - 8];
                    mov.q c, u64_count;
                    rep_movs.q di, si, c;
					cld;
                }
            }
        }

    } else if !overlapping { // Is a small copy forwards

        if count >= 8 {
            d_64s : *u64 = destination;  s_64s : *u64 = source;
            // We could Duff-lite it, but indexing into arrays gives better performance in debug mode (at time of testing);
            // since there's not many cases we'll just be verbose.
            if u64_count == {
                case 1;
                d_64s[0] = s_64s[0];

                case 2;
                d_64s[0] = s_64s[0];
                d_64s[1] = s_64s[1];

                case 3;
                d_64s[0] = s_64s[0];
                d_64s[1] = s_64s[1];
                d_64s[2] = s_64s[2];

                case 4;
                d_64s[0] = s_64s[0];
                d_64s[1] = s_64s[1];
                d_64s[2] = s_64s[2];
                d_64s[3] = s_64s[3];
            }
        }

        d_remainder : *u8 = destination + remainder_byte_offset;
        s_remainder : *u8 = source + remainder_byte_offset;
        if remainder_byte_count == {
            case 1;
            d_remainder[0] = s_remainder[0];

            case 2;
            d_remainder[0] = s_remainder[0];
            d_remainder[1] = s_remainder[1];

            case 3;
            d_remainder[0] = s_remainder[0];
            d_remainder[1] = s_remainder[1];
            d_remainder[2] = s_remainder[2];

            case 4;
            d_remainder[0] = s_remainder[0];
            d_remainder[1] = s_remainder[1];
            d_remainder[2] = s_remainder[2];
            d_remainder[3] = s_remainder[3];

            case 5;
            d_remainder[0] = s_remainder[0];
            d_remainder[1] = s_remainder[1];
            d_remainder[2] = s_remainder[2];
            d_remainder[3] = s_remainder[3];
            d_remainder[4] = s_remainder[4];

            case 6;
            d_remainder[0] = s_remainder[0];
            d_remainder[1] = s_remainder[1];
            d_remainder[2] = s_remainder[2];
            d_remainder[3] = s_remainder[3];
            d_remainder[4] = s_remainder[4];
            d_remainder[5] = s_remainder[5];

            case 7;
            d_remainder[0] = s_remainder[0];
            d_remainder[1] = s_remainder[1];
            d_remainder[2] = s_remainder[2];
            d_remainder[3] = s_remainder[3];
            d_remainder[4] = s_remainder[4];
            d_remainder[5] = s_remainder[5];
            d_remainder[6] = s_remainder[6];
        }

    } else { // Is a small copy reversed

        d_remainder : *u8 = destination + remainder_byte_offset;
        s_remainder : *u8 = source + remainder_byte_offset;
        if remainder_byte_count == {
            case 1;
            d_remainder[0] = s_remainder[0];

            case 2;
            d_remainder[1] = s_remainder[1];
            d_remainder[0] = s_remainder[0];

            case 3;
            d_remainder[2] = s_remainder[2];
            d_remainder[1] = s_remainder[1];
            d_remainder[0] = s_remainder[0];

            case 4;
            d_remainder[3] = s_remainder[3];
            d_remainder[2] = s_remainder[2];
            d_remainder[1] = s_remainder[1];
            d_remainder[0] = s_remainder[0];

            case 5;
            d_remainder[4] = s_remainder[4];
            d_remainder[3] = s_remainder[3];
            d_remainder[2] = s_remainder[2];
            d_remainder[1] = s_remainder[1];
            d_remainder[0] = s_remainder[0];

            case 6;
            d_remainder[5] = s_remainder[5];
            d_remainder[4] = s_remainder[4];
            d_remainder[3] = s_remainder[3];
            d_remainder[2] = s_remainder[2];
            d_remainder[1] = s_remainder[1];
            d_remainder[0] = s_remainder[0];

            case 7;
            d_remainder[6] = s_remainder[6];
            d_remainder[5] = s_remainder[5];
            d_remainder[4] = s_remainder[4];
            d_remainder[3] = s_remainder[3];
            d_remainder[2] = s_remainder[2];
            d_remainder[1] = s_remainder[1];
            d_remainder[0] = s_remainder[0];
        }

        d_64s : *u64 = destination;  s_64s : *u64 = source;
        if u64_count == {
            case 1;
            d_64s[0] = s_64s[0];

            case 2;
            d_64s[1] = s_64s[1];
            d_64s[0] = s_64s[0];

            case 3;
            d_64s[2] = s_64s[2];
            d_64s[1] = s_64s[1];
            d_64s[0] = s_64s[0];

            case 4;
            d_64s[3] = s_64s[3];
            d_64s[2] = s_64s[2];
            d_64s[1] = s_64s[1];
            d_64s[0] = s_64s[0];
        }
    }
}
