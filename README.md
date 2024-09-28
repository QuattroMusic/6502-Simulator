# 6502-Simulator
A simple to use 6502 simulator, featuring a code viewer, registers viewers
and an input display!

![[image]](_data/6502.png)

## Technical specifications
- 32kB RAM and ROM
- 120x80 display
- Date and time in RAM
- Keyboard input
- Frequency selector in the range of 1Hz to 1GHz

### Address Space
```
┌───────────────┐
│               │ 0x0000
│   Zero Page   │
│               │ 0x00FF
├───────────────┤
│               │ 0x0100
│     Stack     │
│               │ 0x01FF
├───────────────┤
│               │ 0x0200
│      RAM      │
│               │ 0x8000
├───────────────┤
│               │ 0x8001
│      ROM      │
│               │ 0xFFF9
├───────────────┤
│   NMI Vector  │ 0xFFFA
│    (unused)   │ 0xFFFB
├───────────────┤
│   RES Vector  │ 0xFFFC & 0xFFFD
├───────────────┤
│   IRQ Vector  │ 0xFFFE
│    (unused)   │ 0xFFFF
└───────────────┘
```

### Programmers Model
At the beginning of the exectution, the 6502 will read the data at the address `0xFFFC` and `0xFFFD` (RES Vector).
The resulted address will give the entry point of your program (see examples or the minimal code).

Multiple byte data is stored in little-endian, so, the address `0x1234` will be stored the RAM as `0x34` and `0x12`

The 6502 features 3 general purpose 8b registers, called `A` (accumulator), `X` and `Y`.
Then there's the 16b `PC` (Program Counter) used to point at the instruction in the ROM,
an 8b register `S`, which points to the next free slot in the stack (0xFF at startup, downwards)
and the 8b `P` reg, which includes the flags used for comparisons and branching.

```
   MSB                             LSB
    ┌───┬───┬───┬───┬───┬───┬───┬───┐
P = │ N │ V │ - │ B │ D │ I │ Z │ C │
    └───┴───┴───┴───┴───┴───┴───┴───┘
```
- `N`: Negative result
- `V`: Overflow
- `B`: BRK instruction
- `D`: Decimal mode
- `I`: IRQ disable (unused)
- `Z`: zero result
- `C`: Carry = !Borrow

For a complete list of the implemented intrinsics, you may look at this [cheatsheet](https://www.atarimania.com/documents/6502%20(65xx)%20Microprocessor%20Instant%20Reference%20Card.pdf)

## Installation

1. Download the simulator from this repository
2. Download the [Vasm compiler](http://www.compilers.de/vasm.html) and add it to the same folder of the executable, or setup environment variables
3. Enjoy!

## Minimal Code
```
    .org $8000
init:
    ; your code here!

    .org $FFFC
    .word init
    .word $0000
```

## Long term features

### Version 1.0
- [x] display
- [x] keyboard input
- [x] date in memory
- [x] fix / improve 6502 engine

### Version 2.0
- [ ] render revamp
- [ ] calculator / conversion panel
- [ ] options panel + save configurations to file
- [ ] use an internal 6502 compiler

### Version 3.0
- [ ] error handling
- [ ] browser panel

### Version 4.0
- [ ] code editor instead of code viewer

---

Questions? Bugs? Ideas? Feel free to contact me on Discord `@quattromusic`!

Join [my server](https://discord.gg/wXECkMJb6V) for the latest news.
