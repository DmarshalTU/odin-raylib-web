# Odin + Raylib on the web



https://github.com/user-attachments/assets/d007dca3-e2dc-494c-8b04-ad42e337ac5a



Make games using Odin + Raylib that works in browser and on desktop. Suitable for small games such as gamejam creations.

Live example: https://zylinski.se/odin-raylib-web/

## Requirements

- Emscripten. Download and install somewhere on your computer. Follow the instructions here: https://emscripten.org/docs/getting_started/downloads.html (follow the stuff under "Installation instructions using the emsdk (recommended)").
- Recent Odin compiler: This uses Raylib binding changes that were done on January 1, 2025.

## Getting started

1. Change `EMSCRIPTEN_SDK_DIR` in `build_web.bat/sh` to point to your emscripten setup.
2. Run `build_web.bat/sh`.
3. Web game is in the `build/web` folder.

> [!NOTE]
> `build_web.bat` is for windows, `build_web.sh` is for Linux / macOS.

> [!WARNING]
> You may not be able to start `build/web/index.html` directly, because you'll get "CORS policy" javascript errors. You can get around that by starting a local web server using python. Go into `build/web` and run:
> 
> `python -m http.server`
>
> Open `localhost:8000` in your browser to play the game.
>
> _If you don't have python, then emscripten actually comes with it. Look in the `python` folder of where you installed emscripten._

You can also build a desktop executable using `build_desktop.bat/sh`. It will end up in the `build/desktop` folder.

Put any assets (textures, sounds etc) you want into the `assets` folder. It will be merged into the web build when the emscripten compiler runs. It is also copied to the `build/desktop` folder when you make a desktop build.

## What works

- raylib, raygui, rlgl using the default `vendor:raylib` bindings.
- Allocator that works with maps and SIMD.
- Temp allocator.
- Logger.
- There's a wrapper for `read_entire_file` and `write_entire_file` from `core:os` that works on web as well. See `source/os` package. It's used in `source/game.odin` to load a file.
- You can load any file in the `assets` folder.

> [!NOTE]
> The files written using `write_entire_file` don't really exist outside the browser. They don't survive closing the tab. But you can write a file and load it within the same session. You can use it to make your old desktop code run, even though it won't be possible to _really_ save anything.

## What won't work

- Anything from `core:os` that isn't in the `source/os` package.
- `fmt.print` and similar procs. Instead, use `log.info` and `log.infof`. Note: `fmt.tprintf` (temp string formatting) still works!

## Debugging

I recommend debugging the desktop build when you can (add `-debug` inside `build_desktop.bat/sh` and use for example [RAD Debugger](https://github.com/EpicGamesExt/raddebugger)). But if you get web-only bugs then you can add `-g` to the the `emcc` line in the build script. This will give you crash stack traces with useful information. It works in Chrome, but I didn't get it to work in Firefox.

## Sublime Text

There is a Sublime project file: `project.sublime-project`. It has a build system pre-setup that lets you run the build scripts for both web and desktop.

## How it works

The contents of the `main_web` folder is built in `freestanding_wasm32` build mode. That package also imports the `game` package. So it's the whole game. `freestanding` means that no OS-specific stuff at all is included. `wasm32` means that the output is possible to run in a web browser.

Odin supports compiling to a `js_wasm32` target that has less limitations. However, we cannot use that because `raylib` requires _emscripten_ in order to translate its OpenGL calls into WebGL. Emscripten has some hacks to pull in its own C standard library stuff, so that's sort-of the "OS layer" you have in emscripten: Strange libc-in-a-web-browser. The Odin core libs don't support emscripten and never will. So that's why we use `freestanding`.

When `main_web` has been compiled into an object file called `game.wasm.o`, then the emscripten compiler `emcc` is run. It is fed both the `game.wasm.o` file and also compiles the `main_web/main_web.c` file. That C file says what will happen when our game is run in a web browser: It'll call our Odin code! (we also feed `emcc` the prebuilt raylib and raygui wasm libs).

Since our odin code is compiled using `freestanding`, no allocators or anything is set up. That's why `source/main_web/main_web_entry.odin` sets up an allocator, temp allocator and logger in the `web_init` proc.

The allocator uses the libc procedures `malloc`, `calloc`, `free` and `realloc` that emscripten exposes.

There's also a logger that uses the `puts` procedure that emscripten exposes, in order to print to the web browser console.

Like I said, we can't use `core:os` at all. Therefore I've made a tiny wrapper in `source/os` that implements `read_entire_file` and `write_entire_file` that both work in web and desktop mode. The web mode once again uses emscripten things to read from the data that is baked into the built web app (the stuff in the `assets` folder). The desktop mode just runs the normal `core:os` code.

## Web build in my Hot Reload template

I have updated my Odin + Raylib + Hot Reload template with similar capabilities: https://github.com/karl-zylinski/odin-raylib-hot-reload-game-template -- Note that it's just for making a _release web build_, no hot reloading is supported with the web version!

## Questions?

Ask questions in my gamedev Discord: https://discord.gg/4FsHgtBmFK

## Acknowledgements
[Caedo's repository](https://github.com/Caedo/raylib_wasm_odin) and [Aronicu's repository](https://github.com/Aronicu/Raylib-WASM) helped me with:
- The initial emscripten setup
- The logger setup
- The idea of using python to host a server
