# Disassembler for CHIP-8 roms

A [CHIP-8](https://en.wikipedia.org/wiki/CHIP-8) disassembler written in [Zig](https://ziglang.org/).

The produced assembly code format is taken from [Cowgod's Chip-8 Technical Reference](http://devernay.free.fr/hacks/chip8/C8TECH10.HTM).

## Algorithm

CHIP-8 executables don't have any metadata associated and hence don't have data and code sections clearly separated within the executable. So me must first decide if each two-bytes datum is an instruction or data blob. We do this traversing the [control flow graph](https://en.wikipedia.org/wiki/Control-flow_graph) of the ROM by branching on jump and call instructions. Everything that is not reached during this traversal is considered to be data.

## Sources

- [CHIP-8 on Wikipedia](https://en.wikipedia.org/wiki/CHIP-8)
- [Chip-8 Technical Reference v1.0 bt Cowgod](http://devernay.free.fr/hacks/chip8/C8TECH10.HTM)
- [How to write an emulator (CHIP-8 interpreter) by Laurence Muller](https://multigesture.net/articles/how-to-write-an-emulator-chip-8-interpreter/)
- [Writing a Chip-8 emulator by Ayman Bagabas (2018)](https://aymanbagabas.com/blog/2018/09/17/chip-8-emulator.html)
