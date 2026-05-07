package main

import "core:fmt"
import "core:math/rand"
import "core:mem"
import "core:os"
import "core:time"

MEM_SIZE :: 4096
PROGRAM_START_ADDRESS :: 0x200

FONT_SET_SIZE :: 80
FONT_SET_START_ADDRESS :: 0x50

VIDEO_WIDTH :: 64
VIDEO_HEIGHT :: 32

KEYPAD_SIZE :: 16

//odinfmt:disable
font_set : [FONT_SET_SIZE]u8 = {
    0xF0, 0x90, 0x90, 0x90, 0xF0, // 0
	0x20, 0x60, 0x20, 0x20, 0x70, // 1
	0xF0, 0x10, 0xF0, 0x80, 0xF0, // 2
	0xF0, 0x10, 0xF0, 0x10, 0xF0, // 3
	0x90, 0x90, 0xF0, 0x10, 0x10, // 4
	0xF0, 0x80, 0xF0, 0x10, 0xF0, // 5
	0xF0, 0x80, 0xF0, 0x90, 0xF0, // 6
	0xF0, 0x10, 0x20, 0x40, 0x40, // 7
	0xF0, 0x90, 0xF0, 0x90, 0xF0, // 8
	0xF0, 0x90, 0xF0, 0x10, 0xF0, // 9
	0xF0, 0x90, 0xF0, 0x90, 0x90, // A
	0xE0, 0x90, 0xE0, 0x90, 0xE0, // B
	0xF0, 0x80, 0x80, 0x80, 0xF0, // C
	0xE0, 0x90, 0x90, 0x90, 0xE0, // D
	0xF0, 0x80, 0xF0, 0x80, 0xF0, // E
	0xF0, 0x80, 0xF0, 0x80, 0x80  // F
}
//odinfmt:enable

Chip8 :: struct {
    registers:  [16]u8,
    memory:     [MEM_SIZE]u8,
    index:      u16,
    pc:         u16,
    stack:      [16]u16,
    sp:         u8,
    delayTimer: u8,
    soundTimer: u8,
    keypad:     [KEYPAD_SIZE]u8,
    video:      [VIDEO_WIDTH * VIDEO_HEIGHT]u32,
    opcode:     u16,
    _rng:       rand.Generator,
}

chip8_new :: proc() -> (chip: Chip8) {
    chip.pc = PROGRAM_START_ADDRESS
    mem.copy(&chip.memory[FONT_SET_START_ADDRESS], &font_set, FONT_SET_SIZE)
    rng_state := rand.create(cast(u64)time.to_unix_seconds(time.now()))
    chip._rng = rand.default_random_generator(&rng_state)

    return
}

chip8_load_rom :: proc(fname: string, chip: ^Chip8) -> int {
    data, success := os.read_entire_file(fname)
    if !success {
        return -1
    }
    defer delete(data)

    if len(data) > MEM_SIZE - PROGRAM_START_ADDRESS {
        return -2
    }

    mem.copy(&chip.memory[PROGRAM_START_ADDRESS], &data, len(data))

    return 0
}

chip8_random_u8 :: proc(chip: ^Chip8) -> u8 {
    return cast(u8)rand.int_max(255, chip._rng)
}


main :: proc() {
    fmt.println("Hellope!")
}

