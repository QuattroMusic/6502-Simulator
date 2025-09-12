copy :: (destination: *void, source: *void, count: s64) {
    overlapping := destination > source && destination < source + count;

    // Timings indicate this cutoff should be a little higher, probably 64, but for simplicity will leave it at this for now.
    if count > 32 {
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
            for #v2 < 0 .. remainder_byte_count - 1
                d_remainder[it] = s_remainder[it];

            for #v2 < 0 .. chunk_count - 1 {
                d_chunk := *d[it];  s_chunk := *s[it];
                d_chunk.u64s[3] = s_chunk.u64s[3];
                d_chunk.u64s[2] = s_chunk.u64s[2];
                d_chunk.u64s[1] = s_chunk.u64s[1];
                d_chunk.u64s[0] = s_chunk.u64s[0];
            }
        }

    } else if !overlapping { // Is a small copy forwards

        u64_count := count / 8;
        remainder_byte_offset := u64_count * 8;
        remainder_byte_count := count - remainder_byte_offset;

        if count >= 8 {
            d_64s : *[4]u64 = destination;  s_64s : *[4]u64 = source;
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

        u64_count := count / 8;
        remainder_byte_offset := u64_count * 8;
        remainder_byte_count := count - remainder_byte_offset;

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

        d_64s : *[4]u64 = destination;  s_64s : *[4]u64 = source;
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
