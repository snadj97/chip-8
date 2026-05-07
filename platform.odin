package main

import "core:c"
import "core:fmt"
import sdl "vendor:sdl2"

Platform :: struct {
    window:      ^sdl.Window,
    renderer:    ^sdl.Renderer,
    texture:     ^sdl.Texture,
    initialized: bool,
}

g_plat: Platform

platform_init :: proc(
    title: cstring,
    wWidth, wHeight, tWidth, tHeight: c.int,
) {
    sdl.Init({.VIDEO})

    g_plat.window = sdl.CreateWindow(title, 0, 0, wWidth, wHeight, {.SHOWN})
    g_plat.renderer = sdl.CreateRenderer(g_plat.window, -1, {.ACCELERATED})
    g_plat.texture = sdl.CreateTexture(
        g_plat.renderer,
        sdl.PixelFormatEnum.RGBA8888,
        sdl.TextureAccess.STREAMING,
        tWidth,
        tHeight,
    )

    g_plat.initialized = true
}

platform_destroy :: proc() {
    sdl.DestroyTexture(g_plat.texture)
    sdl.DestroyRenderer(g_plat.renderer)
    sdl.DestroyWindow(g_plat.window)
    sdl.Quit()

    g_plat.initialized = false
}

platform_update :: proc(buffer: rawptr, pitch: c.int) {
    if !g_plat.initialized {
        fmt.panicf("Platform not initialized")
    }

    sdl.UpdateTexture(g_plat.texture, nil, buffer, pitch)
    sdl.RenderClear(g_plat.renderer)
    sdl.RenderCopy(g_plat.renderer, g_plat.texture, nil, nil)
    sdl.RenderPresent(g_plat.renderer)
}

platform_process_input :: proc(keys: []u8) -> (quit: bool = false) {
    if !g_plat.initialized {
        fmt.panicf("Platform not initialized")
    }

    event: sdl.Event
    for sdl.PollEvent(&event) {
        #partial switch event.type {
        case .QUIT:
            quit = true
        case .KEYDOWN:
            #partial switch (event.key.keysym.sym) {
            case .ESCAPE:
                quit = true
            case .x:
                keys[0x0] = 1
            case .NUM1:
                keys[0x1] = 1
            case .NUM2:
                keys[0x2] = 1
            case .NUM3:
                keys[0x3] = 1
            case .q:
                keys[0x4] = 1
            case .w:
                keys[0x5] = 1
            case .e:
                keys[0x6] = 1
            case .a:
                keys[0x7] = 1
            case .s:
                keys[0x8] = 1
            case .d:
                keys[0x9] = 1
            case .z:
                keys[0xA] = 1
            case .c:
                keys[0xB] = 1
            case .NUM4:
                keys[0xC] = 1
            case .r:
                keys[0xD] = 1
            case .f:
                keys[0xE] = 1
            case .v:
                keys[0xF] = 1
            }
        case .KEYUP:
            #partial switch (event.key.keysym.sym) {
            case .x:
                keys[0x0] = 0
            case .NUM1:
                keys[0x1] = 0
            case .NUM2:
                keys[0x2] = 0
            case .NUM3:
                keys[0x3] = 0
            case .q:
                keys[0x4] = 0
            case .w:
                keys[0x5] = 0
            case .e:
                keys[0x6] = 0
            case .a:
                keys[0x7] = 0
            case .s:
                keys[0x8] = 0
            case .d:
                keys[0x9] = 0
            case .z:
                keys[0xA] = 0
            case .c:
                keys[0xB] = 0
            case .NUM4:
                keys[0xC] = 0
            case .r:
                keys[0xD] = 0
            case .f:
                keys[0xE] = 0
            case .v:
                keys[0xF] = 0
            }
        }
    }


    return
}

