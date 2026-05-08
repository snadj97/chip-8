package main

import "core:c"
import "core:fmt"
import "core:math/rand"
import "core:mem"
import "core:os"
import "core:strconv"
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
    registers:   [16]u8,
    memory:      [MEM_SIZE]u8,
    index:       u16,
    pc:          u16,
    stack:       [16]u16,
    sp:          u8,
    delay_timer: u8,
    sound_timer: u8,
    keypad:      [KEYPAD_SIZE]u8,
    video:       [VIDEO_WIDTH * VIDEO_HEIGHT]u32,
    opcode:      u16,
    table:       [0xF + 1]Chip8Func,
    table0:      [0xE + 1]Chip8Func,
    table8:      [0xE + 1]Chip8Func,
    tableE:      [0xE + 1]Chip8Func,
    tableF:      [0x65 + 1]Chip8Func,
}

chip8_new :: proc() -> (chip: Chip8) {
    chip.pc = PROGRAM_START_ADDRESS
    mem.copy(&chip.memory[FONT_SET_START_ADDRESS], &font_set, FONT_SET_SIZE)
    chip8_op_table_setup(&chip)

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

    mem.copy(&chip.memory[PROGRAM_START_ADDRESS], raw_data(data), len(data))

    return 0
}

chip8_random_u8 :: proc(chip: ^Chip8) -> u8 {
    return cast(u8)rand.int_max(256)
}

chip8_cycle :: proc(chip: ^Chip8) {
    using chip

    opcode = (u16(memory[pc]) << 8) | u16(memory[pc + 1])

    pc += 2

    table[(opcode & 0xF000) >> 12](chip)

    if delay_timer > 0 do delay_timer -= 1
    if sound_timer > 0 do sound_timer -= 1
}

main :: proc() {
    args := os.args

    if len(args) < 4 {
        fmt.printfln("Usage: %v <Scale> <Delay> <ROM>", args[0])
        os.exit(1)
    }

    video_scale, ok := strconv.parse_int(args[1])
    if !ok {
        fmt.eprintfln("Invalid scale: %v", args[1])
        os.exit(1)
    }

    cycle_delay: int
    cycle_delay, ok = strconv.parse_int(args[2])
    if !ok {
        fmt.eprintfln("Invalid delay: %v", args[2])
        os.exit(1)
    }

    rom_fname := args[3]

    platform_init(
        "CHIP-8 Emulator",
        c.int(VIDEO_WIDTH * video_scale),
        c.int(VIDEO_HEIGHT * video_scale),
        VIDEO_WIDTH,
        VIDEO_HEIGHT,
    )

    chip8 := chip8_new()
    err := chip8_load_rom(rom_fname, &chip8)
    if err < 0 {
        fmt.eprintf("Failed to load ROM (err: %v)", err)
        os.exit(err)
    }

    video_pitch := size_of(chip8.video[0]) * VIDEO_WIDTH

    last_cycle_time := time.now()
    quit := false

    for !quit {
        quit = platform_process_input(chip8.keypad[:])

        current_time := time.now()
        dt := time.diff(last_cycle_time, current_time)

        if int(time.duration_milliseconds(dt)) > cycle_delay {
            last_cycle_time = current_time
            chip8_cycle(&chip8)
            platform_update(&chip8.video, c.int(video_pitch))
        }
    }

    os.exit(0)
}

