<div align="center">

# LiveNiro

**Your desktop project, running in its README.**

LiveNiro is a GitHub Action that builds your game or desktop app, runs it on a
virtual screen, plays a short input script, and puts a GIF of the real app in
your README. Every push, automatically. No server, no hosting bill.

<img src="docs/media/bounce-classic.gif" alt="Bounce Classic, a C++ iGraphics game, recorded by LiveNiro on a headless Linux runner: the menu, a click on New Game, then gameplay" width="760">

<sub>A C++ / OpenGL iGraphics game, built and played by LiveNiro on a GitHub runner. No Windows, no MinGW, no human.</sub>

</div>

## Why

Every CS student has a project like this: a game for the first-year graphics
course, a JavaFX app for the OOP lab, a pygame weekend project. It's the most
interesting thing in their GitHub, and nobody ever sees it run. Recruiters
don't clone repos, install a toolchain and run a `.bat` file. So the project
lives and dies as two screenshots in a README.

LiveNiro makes the README show the app actually running, and keeps that demo
up to date every time you push.

## Quick start

Add one file to your project, `.github/workflows/liveniro.yml`:

```yaml
name: LiveNiro demo
on:
  push:
    branches: [main]
    paths-ignore: [".liveniro/**"]
permissions:
  contents: write
jobs:
  demo:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: Kairo-2081/LiveNiro@v0
```

Push. A minute or two later your README has a live demo at the top, and
`.liveniro/` holds a GIF, an MP4 and a poster PNG.

## What it recognizes on its own

| Stack | Detected by | Built with |
|---|---|---|
| **iGraphics** (C++ / OpenGL / GLUT) | `iGraphics.h` in the repo | the project's `build.sh`, or `g++` with GLUT, SDL2_mixer and FreeType |
| **JavaFX** | `openjfx` / `javafx` in `build.gradle(.kts)` or `pom.xml` | `./gradlew run` or `mvn javafx:run`, with the Java version read from your build file |
| **pygame** | `pygame` in `requirements.txt` / `pyproject.toml`, or `import pygame` | a fresh virtualenv; runs `main.py`, `game.py`, `app.py` … or the script that opens the window |
| **Anything else** | `stack: custom` | your own `setup`, `build` and `run` commands |

"Anything else" really means anything that opens a window on Linux: Qt, SFML,
raylib, SDL, Swing, Tkinter, Electron. See [`examples/custom-qt.yml`](examples/custom-qt.yml).

<p align="center">
  <img src="docs/media/pygame-bouncer.gif" alt="A small pygame game recorded by LiveNiro, with the paddle steered by an input script" width="520">
  <br><sub>The pygame fixture from <a href="test/fixtures/pygame-bouncer">test/fixtures</a>, with the paddle steered by an input script.</sub>
</p>

## Make it play your game

A static menu screen is boring. Give LiveNiro an input script and it plays
while it records. Coordinates are pixels from the top-left of your window.

```yaml
      - uses: Kairo-2081/LiveNiro@v0
        with:
          duration: "14"
          actions: |
            wait 1.5
            click 1000 80     # the "New Game" button
            wait 1
            hold Right 2.5    # run right
            key Up            # jump
            hold Right 3
```

| Command | Does |
|---|---|
| `wait <sec>` | pause |
| `click <x> <y> [button]` | click (1 = left, 3 = right) |
| `move <x> <y>` | move the mouse |
| `key <name>` | press a key: `space`, `Return`, `Up`, `Left`, `Tab`, `ctrl+s`, `a` … (X11 key names, as used by xdotool) |
| `hold <key> <sec>` | hold a key down |
| `type <text>` | type text |
| `focus <title>` | send the next keys to another window, such as a login dialog (title is a regex) |

The mouse pointer only appears in the recording when the script uses it.

Dialogs and popups are separate windows, and nothing gives them keyboard focus
on a bare virtual screen. Use `focus` before typing into one:

```yaml
          actions: |
            click 519 409            # "Log In" opens a dialog
            wait 1.5
            focus Bookverse Login    # the dialog's title
            click 468 227
            type demo@example.com
```

## Options

| Input | Default | |
|---|---|---|
| `path` | `.` | project folder inside the repo |
| `stack` | `auto` | `auto`, `igraphics`, `javafx`, `pygame`, `custom` |
| `setup` / `build` / `run` | detected | override any step with shell commands |
| `window` | largest window | regex for the title of the window to record |
| `wait-timeout` | `300` | seconds to wait for the window (first Gradle builds are slow) |
| `warmup` | `2` | seconds between the window appearing and recording |
| `duration` | `12` | length of the clip in seconds |
| `actions` | none | input script (above) |
| `screen` | `1600x900` | virtual screen size |
| `fps` / `gif-width` | `15` / `800` | trade smoothness for file size |
| `output-dir` / `name` | `.liveniro` / `demo` | where files go |
| `readme` | `README.md` | README to update; `""` to leave it alone |
| `commit` | `true` | commit the demo back (push events only) |
| `upload-artifact` | `true` | also attach the files to the workflow run |

Outputs: `stack`, `gif`, `mp4`, `poster`.

### Where the demo goes in your README

LiveNiro owns whatever is between these two markers and leaves the rest of the
file alone:

```html
<!-- liveniro:start -->
<!-- liveniro:end -->
```

If they aren't there yet, it adds them under your first heading.

## Run it locally

LiveNiro is plain Bash on top of Xvfb, ffmpeg and xdotool, so it runs on any
Ubuntu/Debian machine or in WSL:

```bash
sudo apt-get install xvfb ffmpeg xdotool x11-utils
git clone https://github.com/Kairo-2081/LiveNiro ~/liveniro
cd your-project
LN_DURATION=10 LN_ACTIONS=$'wait 1\nkey space' bash ~/liveniro/src/liveniro.sh
```

Every input has an `LN_` environment variable (`LN_STACK`, `LN_RUN`, `LN_WINDOW` …).

## How it works

1. **Detect** the stack from files in the repo (or use the one you set).
2. **Install and build** with the stack's toolchain on the Ubuntu runner.
3. **Start a virtual screen** (Xvfb) with software OpenGL and a dummy audio driver.
4. **Launch the app** and wait for its window to appear.
5. **Record** just that window with ffmpeg while xdotool plays your input script.
6. **Encode** a palette-optimized GIF, an MP4 and a poster frame, update the README and commit.

## Limits, honestly

- **Linux only.** If your project only builds on Windows (for example an old
  `iGraphics.h` that includes `<windows.h>` unconditionally), LiveNiro tells
  you so instead of failing silently. The newer cross-platform iGraphics
  template works out of the box.
- **Software rendering.** Runners have no GPU, so heavy 3D scenes will record
  at a low frame rate.
- **No sound** in the recording.
- **The GIF is a recording, not the live app.** A "▶ Run live" launcher you
  can self-host is on the roadmap.

## Roadmap

- [x] v0.1: iGraphics, JavaFX, pygame, custom; input scripts; README updates
- [ ] v0.2: zero-config SFML, Qt, Swing, raylib, CMake and Makefile projects
- [ ] v0.3: "▶ Run live" badge backed by a self-hostable noVNC launcher

Have a project LiveNiro doesn't recognize yet? [Open an issue](https://github.com/Kairo-2081/LiveNiro/issues) with a link and it becomes the next detector.

## License

MIT
