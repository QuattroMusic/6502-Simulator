# 6502-Simulator
A simple to use 6502 simulator, featuring a code editor, keyboard input and a display!

![[image]](_data/6502.png)

![[video]](_data/hello_6502.gif)

## Technical specifications
- 32kiB of RAM and ROM
- 120x80 display
- Date and time in RAM
- Keyboard and mouse input
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
│      RES      │ 0xFFFC
│     Vector    │ 0xFFFD
├───────────────┤
│   IRQ Vector  │ 0xFFFE
│    (unused)   │ 0xFFFF
└───────────────┘
```

The Zero Page is still considered as RAM.
The main difference between the two is that the zero page
uses less cycles to compute memory read and/or write operations.

The RAM is then subdivided as below:
```
┌───────────────┐
│               │ 0x0200
│    Display    │
│               │ 0x277F
├───────────────┤
│ Time Control  │ 0x2780
├───────────────┤
│   Year (LO)   │ 0x2781
│   Year (HI)   │ 0x2782
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
│   Milli (LO)  │ 0x2788
│   Milli (HI)  │ 0x2789
├───────────────┤
│    Keyboard   │ 0x278A
├───────────────┤
│    Mouse X    │ 0x278B
├───────────────┤
│    Mouse Y    │ 0x278C
├───────────────┤
│  Mouse Input  │ 0x278D
├───────────────┤
│               │ 0x278E
│      RAM      │
│               │ 0x7FFF
└───────────────┘
```

The year and the milliseconds data is stored as little-endian,
as stated in the picture above.

If more RAM is needed, the display space could be used without any problem.
The date and the input section cannot be used for this purpose.

The keyboard input only works when the code editor is not focused.

The time control byte is used to precisely read the time.
When that byte is set to 0x02, the data is ready to be read.
The user must then write 0x01 to that address, so, the engine won't
update the data.
After reading it, the user must to clear the first bit (write 0x00 is
suggested), so, the engine will update the data and write 0x02 again.

### Programmers Model
When the play button is pressed, the 6502 will read the data in the address `0xFFFC` and `0xFFFD` (RES Vector).
The resulted address will give the entry point of your program (see examples or the minimal code).

Multiple byte data is stored in little-endian, so, the address `0x1234` will be stored the RAM as `0x34` and `0x12`

The 6502 features 3 general purpose 8 bit registers, called `A` (accumulator), `X` and `Y`.
The Program Counter is a 16 bit register, called `PC`, used to point at the instruction in the ROM.
There are also two more 8 bit registers, the `S` and `P` registers, which they are used to
point to the next free slot in the stack (0xFF at startup, downwards) and to contain
the flags used for comparisongs and branching, respectively.

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

1. Download the most recent version from [this repository](https://github.com/QuattroMusic/6502-Simulator/releases/latest)
2. Enjoy!

## How to use

1. Open the simulator
2. Create a file on your pc
3. Drag and drop the file on the simulator
4. Start editing and compiling the file

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
- [x] code editor instead of code viewer
- [x] panel for the 6502 instruction set

### Version 4.0
- [ ] use an internal 6502 compiler
- [ ] error handling


# License

I don't like the way the license system works, so instead of searching
for a license that satisfies me, I'm making my own version.

#### What this software allows you to do
You can keep the source code on your devices; you may compile it and use it
for private or public use.
If you modify it, you have to explicitly state that you possess an
altered version of the software.

#### What this software doesn't allow you to do
Even if you've modified it, I don't want you to use this product for
commercial use or to distribute it under your name;
I put a lot of effort on this project, for learning purposes
and to allow everyone to use a 6502 simulator to learn assembly
in the easiest possible way.

## Contact me

Questions? Bugs? Ideas? Something is not clear? Feel free to contact me on Discord `@quattromusic`!

Join [my server](https://discord.gg/wXECkMJb6V) for the latest news.
