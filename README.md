# 6502-Simulator
A simple to use 6502 simulator, featuring a code viewer, keyboard input and a display!

![[image]](_data/6502.png)

![[video]](_data/hello_6502.gif)

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
│               │ 0x7FFF
├───────────────┤
│               │ 0x8000
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

The Zero Page is considered as RAM, it's just an optimized way for the memory operations (less cycles).

The RAM is then subdivided as below:
```
┌───────────────┐
│               │ 0x0200
│    Display    │
│               │ 0x277F
├───────────────┤
│    Keyboard   │ 0x2780
│     Input     │
├───────────────┤
│     Year      │ 0x2781 & 0x2782
├───────────────┤
│     Month     │ 0x2783
├───────────────┤
│      Day      │ 0x2784
├───────────────┤
│     Hours     │ 0x2785
├───────────────┤
│    Minutes    │ 0x2786
├───────────────┤
│    Seconds    │ 0x2787
├───────────────┤
│ Milliseconds  │ 0x2788 & 0x2789
├───────────────┤
│               │ 0x278A
│      RAM      │
│               │ 0x7FFF
└───────────────┘
```

The Year and the Milliseconds section is stored as little-endian (see programmers model)

Note: you can use the display space as RAM storage without any problem, but not the input and date space.
The keyboard input only works when the display is open

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
2. Download the [Vasm compiler](http://www.compilers.de/vasm.html) (`vasm6502_oldstyle.exe`) and add it to the same folder of the executable, or setup environment variables
3. Enjoy!

## How to use

1. Open the simulator
2. Create a file on your pc
3. Drag and drop the file on the simulator
4. Open your favourite IDE and edit the file
5. Enjoy!

Note: every time you save the file, the program automatically reload it

### Minimal Code
```
    .org $8000
init:
    ; your code here!

    .org $FFFC
    .word init
    .word $0000
```

## Roadmap

### Version 1.0
- [x] display
- [x] keyboard input
- [x] date in memory
- [x] fix / improve 6502 engine

### Version 2.0
- [x] render and gui revamp
- [x] options panel + save configurations to file

### Version 3.0
- [ ] code editor instead of code viewer
- [ ] error handling

### Version 4.0
- [ ] panel for the 6502 instruction set
- [ ] use an internal 6502 compiler


# License

I don't like the way the license system works, so instead of searching for a license that satisfies me, I'm making my own version.

#### What this software allows you to do
You can keep the source code on your devices; you may compile it and use it for private or public use.

#### What this software doesn't allow you to do
Even if you've modified it, I don't want you to use this product for commercial use or to distribute under your name;
I put a lot of effort on this project, for learning purposes, and to make it possible for everyone to use a 6502 simulator to learn assembly in the easiest possible way.

#### In short
Use it wherever you want, but please do not use this project for commercial purposes; it's an educational tool that I want accessible to everyone.

## Contact me

Questions? Bugs? Ideas? Feel free to contact me on Discord `@quattromusic`!

Join [my server](https://discord.gg/wXECkMJb6V) for the latest news.
