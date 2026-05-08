package main

import "core:mem"

Chip8Func :: proc(_: ^Chip8)

chip8_op_table_setup :: proc(chip: ^Chip8) {
    using chip

    table[0x0] = chip8_table0
    table[0x1] = chip8_op_JMP_nnn
    table[0x2] = chip8_op_CALL_nnn
    table[0x3] = chip8_op_SE_xkk
    table[0x4] = chip8_op_SNE_xkk
    table[0x5] = chip8_op_SE_xy
    table[0x6] = chip8_op_LD_xkk
    table[0x7] = chip8_op_ADD_xkk
    table[0x8] = chip8_table8
    table[0x9] = chip8_op_SNE_xy
    table[0xA] = chip8_op_LDI_nnn
    table[0xB] = chip8_op_JPV0_nnn
    table[0xC] = chip8_op_RND_xkk
    table[0xD] = chip8_op_DRW_xy
    table[0xE] = chip8_tableE
    table[0xF] = chip8_tableF

    for i := 0; i <= 0xE; i += 1 {
        table0[i] = chip8_op_NOP
        table8[i] = chip8_op_NOP
        tableE[i] = chip8_op_NOP
    }

    table0[0x0] = chip8_op_CLS
    table0[0xE] = chip8_op_RET

    table8[0x0] = chip8_op_LD_xy
    table8[0x1] = chip8_op_OR_xy
    table8[0x2] = chip8_op_AND_xy
    table8[0x3] = chip8_op_XOR_xy
    table8[0x4] = chip8_op_ADD_xy
    table8[0x5] = chip8_op_SUB_xy
    table8[0x6] = chip8_op_SHR_x
    table8[0x7] = chip8_op_SUBN_xy
    table8[0xE] = chip8_op_SHL_x

    tableE[0x1] = chip8_op_SKNP_x
    tableE[0xE] = chip8_op_SKP_x

    for i := 0; i <= 0x65; i += 1 {
        tableF[i] = chip8_op_NOP
    }

    tableF[0x07] = chip8_op_LD_x_DT
    tableF[0x0A] = chip8_op_LDK_x
    tableF[0x15] = chip8_op_LDDT_x
    tableF[0x18] = chip8_op_LDST_x
    tableF[0x1E] = chip8_op_ADDI_x
    tableF[0x29] = chip8_op_LDF_x
    tableF[0x33] = chip8_op_LDB_x
    tableF[0x55] = chip8_op_LDI_0x
    tableF[0x65] = chip8_op_LD_0x_I
}

chip8_table0 :: proc(chip: ^Chip8) {
    chip.table0[chip.opcode & 0x000F](chip)
}

chip8_table8 :: proc(chip: ^Chip8) {
    chip.table8[chip.opcode & 0x000F](chip)
}

chip8_tableE :: proc(chip: ^Chip8) {
    chip.tableE[chip.opcode & 0x000F](chip)
}

chip8_tableF :: proc(chip: ^Chip8) {
    chip.tableF[chip.opcode & 0x00FF](chip)
}

chip8_op_NOP :: proc(_: ^Chip8) {}

// Clear screen
// Opcode: $00E0
// Set video memory to 0
chip8_op_CLS :: proc(chip: ^Chip8) {
    using chip

    mem.set(&video, 0, len(video) * size_of(u32))
}

// Return
// Opcode: $00EE
// Set PC back to last address pushed to SP
chip8_op_RET :: proc(chip: ^Chip8) {
    using chip

    sp -= 1
    pc = stack[sp]
}

// Jump
// Opcode: $1nnn
// Set PC to provided address without saving PC to stack
chip8_op_JMP_nnn :: proc(chip: ^Chip8) {
    using chip
    address := opcode & 0x0FFF

    pc = address
}

// Call
// Opcode: $2nnn
// Save PC to stack, then set PC to provided address
chip8_op_CALL_nnn :: proc(chip: ^Chip8) {
    using chip
    address := opcode & 0x0FFF

    stack[sp] = pc
    sp += 1
    pc = address
}

// Skip if Equal Byte
// Opcode: $3xkk
// If value at register x is equal to kk, increment PC by 2,
// effectively skipping an instruction.
chip8_op_SE_xkk :: proc(chip: ^Chip8) {
    using chip
    vx := (opcode & 0x0F00) >> 8
    kk := u8(opcode & 0x00FF)

    if registers[vx] == kk {
        pc += 2
    }
}


// Skip if Not Equal Byte
// Opcode: $4xkk
// If value at register x is NOT equal to kk, increment PC by 2,
// effectively skipping an instruction.
chip8_op_SNE_xkk :: proc(chip: ^Chip8) {
    using chip
    vx := (opcode & 0x0F00) >> 8
    kk := u8(opcode & 0x00FF)

    if registers[vx] != kk {
        pc += 2
    }
}

// Skip if Equal Register
// Opcode: $5xy0
// If value at register x is equal to value at register y,
// increment PC by 2, effectively skipping an instruction.
chip8_op_SE_xy :: proc(chip: ^Chip8) {
    using chip
    vx := (opcode & 0x0F00) >> 8
    vy := (opcode & 0x00F0) >> 4

    if registers[vx] == registers[vy] {
        pc += 2
    }
}

// Load byte
// Opcode: $6xkk
// Store byte in register x
chip8_op_LD_xkk :: proc(chip: ^Chip8) {
    using chip
    vx := (opcode & 0x0F00) >> 8
    kk := u8(opcode) & 0x00FF

    registers[vx] = kk
}

// Add byte
// Opcode: $7xkk
// Add byte to register x
chip8_op_ADD_xkk :: proc(chip: ^Chip8) {
    using chip
    vx := (opcode & 0x0F00) >> 8
    kk := u8(opcode) & 0x00FF

    registers[vx] += kk
}

// Load register
// Opcode: $8xy0
// Store value of register y in register x
chip8_op_LD_xy :: proc(chip: ^Chip8) {
    using chip
    vx := (opcode & 0x0F00) >> 8
    vy := (opcode & 0x00F0) >> 4

    registers[vx] = registers[vy]
}

// Bitwise OR register
// Opcode: $8xy1
// Bitwise OR value of register x with value of register y
chip8_op_OR_xy :: proc(chip: ^Chip8) {
    using chip
    vx := (opcode & 0x0F00) >> 8
    vy := (opcode & 0x00F0) >> 4

    registers[vx] |= registers[vy]
}

// Bitwise AND register
// Opcode: $8xy2
// Bitwise AND value of register x with value of register y
chip8_op_AND_xy :: proc(chip: ^Chip8) {
    using chip
    vx := (opcode & 0x0F00) >> 8
    vy := (opcode & 0x00F0) >> 4

    registers[vx] &= registers[vy]
}

// Bitwise XOR register
// Opcode: $8xy3
// Bitwise XOR value of register x with value of register y
chip8_op_XOR_xy :: proc(chip: ^Chip8) {
    using chip
    vx := (opcode & 0x0F00) >> 8
    vy := (opcode & 0x00F0) >> 4

    registers[vx] ~= registers[vy]
}

// Add register
// Opcode: $8xy4
// Add value of register y to register x
chip8_op_ADD_xy :: proc(chip: ^Chip8) {
    using chip
    vx := (opcode & 0x0F00) >> 8
    vy := (opcode & 0x00F0) >> 4

    sum := u16(registers[vx]) + u16(registers[vy])

    if sum > 255 {
        registers[0xF] = 1
    } else {
        registers[0xF] = 0
    }

    registers[vx] = u8(sum & 0xFF)
}

// Subtract register
// Opcode: $8xy5
// Subtract value of register y from register x,
// then store in x. VF is set if no borrow happened
chip8_op_SUB_xy :: proc(chip: ^Chip8) {
    using chip
    vx := (opcode & 0x0F00) >> 8
    vy := (opcode & 0x00F0) >> 4

    if registers[vx] > registers[vy] {
        registers[0xF] = 1
    } else {
        registers[0xF] = 0
    }

    registers[vx] -= registers[vy]
}

// Shift Register Right
// Opcode: $8xy6
// Store LSB in VF, then shift x to the right, essentially
// dividing by 2
chip8_op_SHR_x :: proc(chip: ^Chip8) {
    using chip
    vx := (opcode & 0x0F00) >> 8

    registers[0xF] = (registers[vx] & 0x1)

    registers[vx] >>= 1
}

// Subtract register inverted
// Opcode: $8xy7
// Subtract value of register x from register y,
// then store in x. VF is set if no borrow happened
chip8_op_SUBN_xy :: proc(chip: ^Chip8) {
    using chip
    vx := (opcode & 0x0F00) >> 8
    vy := (opcode & 0x00F0) >> 4


    if registers[vy] > registers[vx] {
        registers[0xF] = 1
    } else {
        registers[0xF] = 0
    }

    registers[vx] = registers[vy] - registers[vx]
}

// Shift Register Right
// Opcode: $8xyE
// Store MSB in VF, then shift x to the left, essentially
// multiplying by 2
chip8_op_SHL_x :: proc(chip: ^Chip8) {
    using chip
    vx := (opcode & 0x0F00) >> 8

    registers[0xF] = (registers[vx] & 0x80) >> 7

    registers[vx] <<= 1
}
// Skip if Not Equal Register
// Opcode: $9xy0
// If value at register x is NOT equal to value at register y,
// increment PC by 2, effectively skipping an instruction.
chip8_op_SNE_xy :: proc(chip: ^Chip8) {
    using chip
    vx := (opcode & 0x0F00) >> 8
    vy := (opcode & 0x00F0) >> 4

    if registers[vx] != registers[vy] {
        pc += 2
    }
}

// Load to Index Register
// Opcode: $Annn
// Store value at address nnn in the index register
chip8_op_LDI_nnn :: proc(chip: ^Chip8) {
    using chip
    address := opcode & 0x0FFF

    index = address
}

// Jump to address + V0
// Opcode: $Bnnn
// Jump to address + value in V0 register without saving
// PC to stack
chip8_op_JPV0_nnn :: proc(chip: ^Chip8) {
    using chip
    address := opcode & 0x0FFF

    pc = u16(registers[0]) + address
}

// Load Random
// Opcode: $Cxkk
// Store random byte AND'ed with kk in register x
chip8_op_RND_xkk :: proc(chip: ^Chip8) {
    using chip
    vx := (opcode & 0x0F00) >> 8
    kk := u8(opcode & 0x00FF)

    registers[vx] = chip8_random_u8(chip) & kk
}

// Display n-byte sprite at location I(ndex)
// Opcode: $Dxyn
// Draw sprite to video memory, pixel by pixel, utilizing
// the Index register for tracking position in video
// memory. Set VF on collisions.
chip8_op_DRW_xy :: proc(chip: ^Chip8) {
    using chip
    vx := u8((opcode & 0x0F00) >> 8)
    vy := u8((opcode & 0x00F0) >> 4)
    height := opcode & 0x000F

    xPos := registers[vx] % VIDEO_WIDTH
    yPos := registers[vy] % VIDEO_HEIGHT

    registers[0xF] = 0

    outer: for row: u16 = 0; row < height; row += 1 {
        spriteByte := memory[index + row]

        for col: u16 = 0; col < 8; col += 1 {
            if (u16(yPos) + row) >= VIDEO_HEIGHT || (u16(xPos) + col) >= VIDEO_WIDTH do break outer

            screenPixel := &video[(u16(yPos) + row) * VIDEO_WIDTH + (u16(xPos) + col)]

            if 0 != spriteByte & (0x80 >> col) {
                if screenPixel^ == 0xFFFFFFFF {
                    registers[0xF] = 1
                }
                screenPixel^ ~= 0xFFFFFFFF
            }
        }
    }
}

// Skip on Key Press
// Opcode: $Ex9E
// Skip instruction if key with value stored in register x
// is pressed.
chip8_op_SKP_x :: proc(chip: ^Chip8) {
    using chip
    vx := u8((opcode & 0x0F00) >> 8)
    key := registers[vx]

    if 0 != keypad[key] {
        pc += 2
    }
}


// Skip on Key Not Press
// Opcode: $ExA1
// Skip instruction if key with value stored in register x
// is NOT pressed.
chip8_op_SKNP_x :: proc(chip: ^Chip8) {
    using chip
    vx := u8((opcode & 0x0F00) >> 8)
    key := registers[vx]

    if 0 == keypad[key] {
        pc += 2
    }
}

// Load Delay Timer to Register
// Opcode: $Fx07
// Load register x with value in delay timer
chip8_op_LD_x_DT :: proc(chip: ^Chip8) {
    using chip
    vx := u8((opcode & 0x0F00) >> 8)

    registers[vx] = delay_timer
}

// Wait Keypress and Store
// Opcode: $Fx0A
// Repeat instruction until a key is pressed, then store
// the key ID in register x
chip8_op_LDK_x :: proc(chip: ^Chip8) {
    using chip
    vx := u8((opcode & 0x0F00) >> 8)

    for i: u8 = 0; i < KEYPAD_SIZE; i += 1 {
        if 0 != keypad[i] {
            registers[vx] = i
            return
        }
    }

    pc -= 2
}

// Load Delay Timer
// Opcode: $Fx15
// Load value of register x to the delay timer
chip8_op_LDDT_x :: proc(chip: ^Chip8) {
    using chip
    vx := u8((opcode & 0x0F00) >> 8)

    delay_timer = registers[vx]
}

// Load Sound Timer
// Opcode: $Fx18
// Load value of register x to the sound timer
chip8_op_LDST_x :: proc(chip: ^Chip8) {
    using chip
    vx := u8((opcode & 0x0F00) >> 8)

    sound_timer = registers[vx]
}

// Add Index
// Opcode: $Fx1E
// Add value of register x to the index register
chip8_op_ADDI_x :: proc(chip: ^Chip8) {
    using chip
    vx := u8((opcode & 0x0F00) >> 8)

    if index + u16(registers[vx]) > 0xFFF {
        registers[0xF] = 1
    } else {
        registers[0xF] = 0
    }

    index += u16(registers[vx])
}

// Load Font
// Opcode: $Fx29
// Load index register with of font sprite for the
// digit corrosponding to the value in register x
chip8_op_LDF_x :: proc(chip: ^Chip8) {
    using chip
    vx := u8((opcode & 0x0F00) >> 8)
    digit := registers[vx]

    index = FONT_SET_START_ADDRESS + (5 * u16(digit))
}

// Load BCD
// Opcode: $Fx33
// Store Binary Coded Decimal representation of value in
// register x in video memory at locations I, I+1 and I+2.
// E.g. '156' -> I = '1', I+1 = '5', I+2 = '6'
chip8_op_LDB_x :: proc(chip: ^Chip8) {
    using chip
    vx := u8((opcode & 0x0F00) >> 8)
    val := registers[vx]

    memory[index + 2] = val % 10
    val /= 10

    memory[index + 1] = val % 10
    val /= 10

    memory[index] = val % 10
}

// Load Registers to Memory
// Opcode: $Fx55
// Store registers 0 through x in memory at location
// stored in index register
chip8_op_LDI_0x :: proc(chip: ^Chip8) {
    using chip
    vx := (opcode & 0x0F00) >> 8

    for i: u16 = 0; i <= vx; i += 1 {
        memory[index + i] = registers[i]
    }
}

// Load to Registers from Memory
// Opcode: $Fx65
// Load memory from location stored in index register
// into registers 0 through x
chip8_op_LD_0x_I :: proc(chip: ^Chip8) {
    using chip

    vx := (opcode & 0x0F00) >> 8

    for i: u16 = 0; i <= vx; i += 1 {
        registers[i] = memory[index + i]
    }
}

