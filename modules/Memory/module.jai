// @TODO compare (memcmp), set (memset)
// @TODO look at disassembly for memcpy, see if it is faster because it isn't memmove or because something else

#module_parameters(
    with_candidates := false, // Include sample procs used to test different techniques.

    with_unwraps := false     // Include various forms of copy_256; inline vs expand vs nocall
                              // Can be used to test jai's codegen, as theoretically those three
                              // things should be the same (but are currently not in debug builds).
);

// Inside this module we're only interested in "safe" memcpy, i.e. memmove (i.e. handles overlapping regions correctly).
// Any time the name "memcpy" is referenced it refers to this always-works operation, *not* the historical problematic C behavior.

// Results for copiers on a Coffee Lake Core i7 3.7GHz.  This would be interesting to test on different CPUs; if you run the tests
// and your results indicate different behaviour you can add them here, or if they're roughly the same add a note saying so.
// For the 4 different executions, compile with and without the -release flag, for SPAM_SMALL = true / false, and run with the number of
// iterations below (100000 for big block size, 100000000 for small).
//
//                                Block size = ~1MB           Block size = 5            Block size = 32          Block size = 33
//                                Debug      Release         Debug     Release         Debug     Release         Debug     Release
//   Iterations:                 100000      100000        100000000  100000000      100000000  100000000      100000000  100000000

//   copy:                      4.122988    4.075026        4.986152   0.633592       5.604859   1.266981       5.773865   2.312199

//   copy_0:                  258.890028   30.108835        4.320567   0.941546      11.621824   1.953544      12.235222   1.799718
//   copy_1_u64:               34.723948    5.421400        5.141392   0.939739       4.858990   0.967173       5.033572   0.982109
//   copy_2_u64_128:           24.905961    5.503250        5.061464   0.927718       4.791853   0.891786       4.956998   0.956220
//   copy_3_u64_256:           18.824094    5.466732        4.993935   0.974570       4.672739   0.876344       4.838060   0.941630
//   copy_4_u64_256_asm:       27.743473    5.441724        5.218939   1.078340       5.090056   0.960698       5.167539   1.007799
//   copy_5_asm_rep:            4.066812    4.037968        4.530034   1.748581       4.414095   1.806354       5.466841   2.502498
//   copy_6_asm_rep_bytes:      9.854068    9.973524        4.161220   1.668645       4.112184   1.675045       4.107957   1.698251
//   copy_10_sse_128:          23.910240    4.316384        5.151878   0.951720       4.862976   0.900961       4.960824   0.941107
//   copy_11_sse_256:          17.858233    4.507696        4.981415   1.027413       4.666785   0.865558       4.832110   0.919914
//   copy_12_sse_512:          15.275411    4.436847        4.967967   0.991100      12.250284   1.815490      11.709695   1.854931
//   copy_13_sse_1024:         14.212567    4.122765        5.038044   0.989045      12.369618   1.990983      11.719953   1.862404
//   copy_20_avx_256:          12.859599    4.106428        5.188603   0.721868       4.704934   0.651604       4.858950   0.699024

//
// These results show that for bulk copy, REP MOVSQ is far-and-away the winner, vastly outperforming any
// SIMD operation.  Therefore, for the actual copy proc we'll use it for count > 4 u64, but provide something
// hand-coded for small counts.
// For non-X64 we'll base the bulk copy on copy_3_u64_256, which gives decent performance (but should
// subsitute in platform specific code when possible, i.e. add arm64 CPYP/M/E).


#if CPU == .X64  #load "x64.jai";
else             #load "generic.jai";

#if with_candidates  #load "supplementary/candidates.jai";
#if with_unwraps     #load "supplementary/unwraps.jai";
