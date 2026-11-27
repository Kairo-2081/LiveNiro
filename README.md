<div align="center">

<img src="./.github/assets/readme/liveniro-logo.svg" alt="LiveNiro" width="88" />

# LiveNiro

**Your desktop project, running in its README.**

A GitHub Action that builds your game or desktop app, runs it on a virtual
screen, plays it with a short input script, and puts a GIF of the real thing at
the top of your README. On every push. No server, no hosting bill.

[![Self-test](https://github.com/Kairo-2081/LiveNiro/actions/workflows/self-test.yml/badge.svg)](https://github.com/Kairo-2081/LiveNiro/actions/workflows/self-test.yml)
[![Version](https://img.shields.io/github/v/tag/Kairo-2081/LiveNiro?sort=semver&label=version&color=7c3aed)](https://github.com/Kairo-2081/LiveNiro/tags)
[![License: MIT](https://img.shields.io/badge/license-MIT-green.svg)](./LICENSE)
![Runs on](https://img.shields.io/badge/runs%20on-GitHub%20Actions-2088ff?logo=githubactions&logoColor=white)
![Stacks](https://img.shields.io/badge/zero--config-C%2FC%2B%2B%20%7C%20Java%20%7C%20Python%20%7C%20iGraphics-db2777)
![Written in](https://img.shields.io/badge/written%20in-Bash-4eaa25?logo=gnubash&logoColor=white)

[Quick start](#quick-start) ·
[Showcase](#showcase) ·
[Examples](./examples) ·
[Request a stack](https://github.com/Kairo-2081/LiveNiro/issues/new)

<img src="./docs/media/bounce-classic.gif" alt="Bounce Classic, a C++ iGraphics game, recorded by LiveNiro on a GitHub runner: the main menu, a click on New Game, then the ball rolling and jumping through the first level" width="860" />

<sub>A C++ / OpenGL game, built and played by LiveNiro on a headless Linux runner. No Windows, no MinGW, no human.</sub>

</div>

<div align="center">

[At a glance](#at-a-glance) · [Showcase](#showcase) · [Found by LiveNiro](#found-by-liveniro) ·
[Quick start](#quick-start) · [How it works](#how-it-works) · [Stacks](#supported-stacks) ·
[Input scripts](#input-scripts) · [Tours](#tours-every-screen-every-level) · [Options](#options) · [Recipes](#recipes) ·
[Engineering](#engineering) · [Status](#project-status-and-roadmap)

</div>

Every CS student has a project like this: a game for the first-year graphics
course, a JavaFX app for the OOP lab, a pygame weekend build. It's the most
interesting thing on their GitHub, and nobody ever sees it run. Recruiters
don't clone a repo, install a toolchain and double-click a `.bat` file, so the
project lives and dies as two screenshots.

LiveNiro makes the README show the app actually running, and re-records it
every time you push, so the demo never goes stale.

## At a glance

| | |
| --- | --- |
| **One file to add** | A short workflow file. No Dockerfile, no config file, no account anywhere. |
| **Zero-config stacks** | C and C++ (CMake, Make, qmake or plain sources with SFML, SDL2, raylib, GLFW, GLUT or Qt), Java (JavaFX, Swing, AWT), Python (pygame, tkinter, Qt, pyglet, arcade) and iGraphics are detected and built automatically. |
| **Anything else** | Any app that opens a window on Linux, with your own `setup`, `build` and `run` commands: Rust, Go, Zig, Electron, Godot exports. |
| **It plays, not just opens** | An input script clicks, types, holds keys and switches to dialogs while it records. |
| **Whole-app tours** | Split one run into named scenes (menu, every page, every level): a GIF per scene in a README gallery, plus a full MP4 with chapters. |
| **Outputs** | A palette-optimised GIF for the README, a sharp MP4, and a poster PNG, all in `.liveniro/`. |
| **Stays current** | Runs on every push and rewrites only its own block in your README. |
| **Fast after the first run** | Gradle, Maven and pip downloads are cached; rate-limited downloads are retried. |
| **Verified** | Every change is tested in CI against three real projects, one per stack. |

## Showcase

Real projects, recorded by the same action you'd add to yours.

<table>
<tr>
<td width="50%" valign="top">

**Bounce Classic** · C++ · iGraphics / OpenGL

<img src="./docs/media/bounce-classic.gif" alt="Bounce Classic gameplay recorded by LiveNiro" width="100%" />

Menu → click **New Game** → run and jump.
[Repo](https://github.com/Kairo-2081/Bounce-Classic) · [workflow](https://github.com/Kairo-2081/Bounce-Classic/blob/main/.github/workflows/liveniro.yml)

</td>
<td width="50%" valign="top">

**BookVerse** · Java 21 · JavaFX / Gradle

<img src="./docs/media/bookverse-javafx.gif" alt="BookVerse library manager recorded by LiveNiro: the welcome screen, the login dialog, then the dashboard" width="100%" />

Welcome screen → login dialog → dashboard.
[Repo](https://github.com/Kairo-2081/LibraryManager) · [workflow](https://github.com/Kairo-2081/LibraryManager/blob/master/.github/workflows/liveniro.yml)

</td>
</tr>
<tr>
<td width="50%" valign="top">

**Bouncer** · Python · pygame

<img src="./docs/media/pygame-bouncer.gif" alt="A small pygame game recorded by LiveNiro, with the paddle steered by an input script" width="100%" />

The paddle is steered by `hold Left` / `hold Right`.
[Source](./test/fixtures/pygame-bouncer)

</td>
<td width="50%" valign="top">

**Your project here**

Add the workflow from [Quick start](#quick-start), push, and open a PR adding
your GIF to this table.

Stack LiveNiro doesn't recognise yet?
[Open an issue](https://github.com/Kairo-2081/LiveNiro/issues/new) with a link:
it becomes the next detector.

</td>
</tr>
</table>


### More stacks, zero config

Each of these is a small project in [`test/fixtures`](./test/fixtures), recorded by
the self-test on every change with no `build:` or `run:` given: LiveNiro finds the
build system, installs the libraries and starts the app by itself.

<table>
<tr>
<td width="33%" align="center"><img src="./docs/media/stacks/sfml-cmake.gif" alt="SFML orbits demo recorded by LiveNiro" width="100%"><br><b>C++ · SFML · CMake</b><br><sub>arrow keys steer the ship</sub></td>
<td width="33%" align="center"><img src="./docs/media/stacks/sdl2-make.gif" alt="SDL2 falling blocks demo recorded by LiveNiro" width="100%"><br><b>C · SDL2 · Makefile</b><br><sub>catch the blocks</sub></td>
<td width="33%" align="center"><img src="./docs/media/stacks/raylib-plain.gif" alt="raylib comet demo recorded by LiveNiro" width="100%"><br><b>C · raylib · one file</b><br><sub>no build system at all</sub></td>
</tr>
<tr>
<td width="33%" align="center"><img src="./docs/media/stacks/qt-widgets.gif" alt="Qt task board recorded by LiveNiro, a task being typed and added" width="100%"><br><b>C++ · Qt 6 Widgets</b><br><sub>types a task, presses Enter</sub></td>
<td width="33%" align="center"><img src="./docs/media/stacks/swing-plain.gif" alt="Java Swing equalizer recorded by LiveNiro, the Add bar button clicked three times" width="100%"><br><b>Java · Swing · plain sources</b><br><sub>clicks "Add bar" three times</sub></td>
<td width="33%" align="center"><img src="./docs/media/stacks/tkinter-app.gif" alt="tkinter reading list recorded by LiveNiro, a book being added" width="100%"><br><b>Python · tkinter</b><br><sub>adds a book to the list</sub></td>
</tr>
</table>

## Found by LiveNiro

Running a project somewhere other than the machine it was written on is a
test in itself. On their first recordings, LiveNiro surfaced four real bugs in
the showcase projects, none of which ever showed up on the author's Windows
machine:

| Project | What the recording showed | Cause | Fix |
| --- | --- | --- | --- |
| Bounce Classic | Every level drawn on black | Code loads `bg.jpg`, the file is `Bg.jpg`; Windows ignores case, Linux doesn't | [#4](https://github.com/Kairo-2081/Bounce-Classic/pull/4) |
| Bounce Classic | In-game text in the wrong font | Same mismatch: `game.ttf` vs `Game.ttf` | [#4](https://github.com/Kairo-2081/Bounce-Classic/pull/4) |
| Bounce Classic | HUD read *"Health: 100Score: 5"* | `"Health: 100"` needs 12 bytes, the buffer had 11: an overflow into the score text | [#5](https://github.com/Kairo-2081/Bounce-Classic/pull/5) |
| BookVerse | *"Reimagin…"*, *"Version 1.0 Now …"* | Fixed-width labels sized for Office-only fonts; any other font overflows them | [#7](https://github.com/Kairo-2081/LibraryManager/pull/7) |

## Quick start

Add `.github/workflows/liveniro.yml` to your project:

```yaml
name: LiveNiro demo

on:
  push:
    branches: [main]
    paths-ignore: [".liveniro/**"]
  workflow_dispatch:

permissions:
  contents: write   # lets LiveNiro commit the GIF back

jobs:
  demo:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: Kairo-2081/LiveNiro@v0
```

Push. A minute or two later your README has a live demo under its first
heading, and `.liveniro/` holds `demo.gif`, `demo.mp4` and `demo.png`.

To choose where the demo goes, put these two markers anywhere in your README.
LiveNiro owns what's between them and never touches the rest of the file:

```html
<!-- liveniro:start -->
<!-- liveniro:end -->
```

> [!TIP]
> Wrap your existing screenshot in the markers. It stays until the first
> recording replaces it, so the README never has an empty gap.

## How it works

```mermaid
flowchart LR
    A([git push]) --> B[Detect the stack]
    B --> C[Install toolchain<br/>restore cache]
    C --> D[Build<br/>retry on 429 / timeouts]
    D --> E[Start a virtual screen<br/>Xvfb + software OpenGL]
    E --> F[Launch the app,<br/>wait for its window]
    F --> G[Record the window<br/>while the input script plays]
    G --> H[GIF + MP4 + poster]
    H --> I[Update the README block,<br/>commit with skip ci]
```

```mermaid
sequenceDiagram
    autonumber
    participant R as GitHub runner
    participant X as Xvfb screen
    participant App as Your app
    participant F as ffmpeg
    participant S as Input script

    R->>X: Start a 1600×900 virtual screen
    R->>App: Run (./gradlew run, bin/opengl, python main.py …)
    App->>X: Opens its window
    R->>X: Find the largest window (or the one whose title you named)
    R->>F: Record just that window for N seconds
    par while recording
        S->>App: click, key, hold, type, focus
    end
    F-->>R: raw.mp4
    R->>R: Encode GIF with a palette built from the clip
    R->>R: Rewrite the README block, git commit [skip ci]
```

The app is started in its own process group and the whole tree is stopped
afterwards, so Gradle daemons and child processes never outlive the run.

## Supported stacks

| Stack | Detected by | Build | Run |
| --- | --- | --- | --- |
| **iGraphics**<br/><sub>C++ / OpenGL / GLUT</sub> | `iGraphics.h` in the repo | The project's own `build.sh` if it has a Linux branch, otherwise `g++` with GLUT, SDL2_mixer and FreeType | The built binary, from the project folder so relative asset paths work |
| **JavaFX** | `openjfx` / `javafx` in `build.gradle(.kts)` or `pom.xml` | `./gradlew classes` or `mvn compile`, with the Java version read from your build file | `./gradlew run` or `mvn javafx:run` |
| **java**<br/><sub>Swing / AWT</sub> | `.java` files that use `javax.swing` or `java.awt` | A Gradle `application`, `mvn compile`, or plain `javac` when there's no build tool | `./gradlew run`, `mvn exec:java`, or `java` on the class with `main()` (a Swing file and a class called `Main` win) |
| **pygame** / **python**<br/><sub>pygame, tkinter, turtle, PyQt, PySide, pyglet, arcade, kivy, Dear PyGui</sub> | The library in `requirements.txt` / `pyproject.toml`, or an `import` of it | A fresh virtualenv on the distro Python; `requirements.txt` if there is one, plus anything the code imports that's missing; Tk and Qt system libraries when needed | `main.py`, `game.py`, `app.py` … or the script that opens a window or starts an event loop |
| **cpp**<br/><sub>C / C++</sub> | `CMakeLists.txt`, a `.pro` file, a Makefile next to C/C++ sources, or sources that include SFML, SDL2, raylib, GLFW, GLUT or Qt | CMake, qmake or `make`; with no build system, `g++`/`gcc` on the sources with the detected libraries linked. Libraries come from Ubuntu, except raylib, and SFML when the code needs the other major version (2 vs 3); those are built from source | The `add_executable()` target, or the newest executable the build produced; `make run` as a last resort |
| **custom** | `stack: custom` | Your `setup` and `build` | Your `run` |

Old iGraphics templates that include `<windows.h>` unconditionally can't build
on Linux; LiveNiro says so in one clear error instead of a page of compiler
output.

## Input scripts

A menu screen sitting still is not a demo. Give LiveNiro a script and it plays
while it records. Coordinates are pixels from the top-left of your app's window.

```yaml
      - uses: Kairo-2081/LiveNiro@v0
        with:
          duration: "14"
          actions: |
            wait 1.5
            click 1000 80            # the "New Game" button
            move 1278 718            # park the pointer in a corner
            hold Right 2.5           # run right
            key Up                   # jump
            hold Right 3
```

| Command | Does |
| --- | --- |
| `wait <sec>` | Pause |
| `click <x> <y> [button]` | Click (1 = left, 3 = right) |
| `move <x> <y>` | Move the pointer |
| `key <name>` | Press a key: `space`, `Return`, `Up`, `Left`, `Tab`, `ctrl+s`, `a` … (X11 key names) |
| `hold <key> <sec>` | Hold a key down |
| `type <text>` | Type text |
| `focus <title>` | Send the next keys to another window, such as a login dialog (the title is a regex) |

The pointer only appears in the recording when the script uses the mouse.

> [!NOTE]
> Dialogs and popups are separate windows, and nothing gives them keyboard
> focus on a bare virtual screen. Use `focus` before typing into one:
>
> ```yaml
>           actions: |
>             click 537 403            # "Log In" opens a dialog
>             wait 1.5
>             focus Bookverse Login    # the dialog's title
>             click 468 227
>             type demo@example.com
> ```

**Finding coordinates:** run the app at its normal size, take a screenshot,
and read the pixel position of the button relative to the window's top-left
corner. Any image viewer that shows the cursor position will do.

## Tours: every screen, every level

One GIF shows one moment. A **tour** shows the whole app: one run, split into
named scenes. Each scene becomes its own short GIF in a README gallery, and the
whole run becomes one MP4 with a title card and a chapter for every scene.

<table>
<tr>
<td width="33%" align="center"><img src="./docs/media/tour-bounce/01-main-menu.gif" alt="Tour scene 1: main menu" width="100%"><br><b>1 · Main menu</b></td>
<td width="33%" align="center"><img src="./docs/media/tour-bounce/02-leaderboard.gif" alt="Tour scene 2: leaderboard" width="100%"><br><b>2 · Leaderboard</b></td>
<td width="33%" align="center"><img src="./docs/media/tour-bounce/03-help.gif" alt="Tour scene 3: help screen" width="100%"><br><b>3 · Help</b></td>
</tr>
<tr>
<td width="33%" align="center"><img src="./docs/media/tour-bounce/04-level-1.gif" alt="Tour scene 4: level 1" width="100%"><br><b>4 · Level 1</b></td>
<td width="33%" align="center"><img src="./docs/media/tour-bounce/05-level-2.gif" alt="Tour scene 5: level 2" width="100%"><br><b>5 · Level 2</b></td>
<td width="33%" align="center"><img src="./docs/media/tour-bounce/06-level-3.gif" alt="Tour scene 6: level 3" width="100%"><br><b>6 · Level 3</b></td>
</tr>
</table>

<p align="center"><sub>Bounce Classic, toured in one run: every menu screen and all three levels.</sub></p>

Write `scenes:` instead of `actions:`. A line starting with `## ` begins a new
scene and names it; everything under it is an ordinary input script:

```yaml
      - uses: Kairo-2081/LiveNiro@v0
        with:
          scenes: |
            ## Main menu
            wait 2.5

            ## Leaderboard
            click 1000 338
            wait 3
            key c                    # back to the menu

            ## Level 1
            click 1000 80            # New Game
            hold Right 3
            key Up

            ## Level 2
            sh printf '2 0 65 100 0' > saved.txt   # a save file that starts on level 2
            restart                                # relaunch the game
            click 1000 213                         # Load Game
            hold Right 3
```

Two commands exist for tours:

| Command | Does |
| --- | --- |
| `restart` | Close the app and start it again. For screens with no way back, or to start a scene fresh. |
| `sh <command>` | Run a shell command in the project folder: write a save file, seed a database, reset state. |

What you get, for `name: demo`:

| File | What it is |
| --- | --- |
| `demo-01-main-menu.gif`, `demo-02-leaderboard.gif` … | One GIF per scene, named after the scene |
| `demo-01-main-menu.png` … | A poster frame per scene |
| `demo-tour.mp4` | The whole run with chapters and a title card per scene. Restarts are cut out, so it plays as one smooth walkthrough |

The README block becomes a two-column gallery of the scenes, followed by a
**▶ Watch the full walkthrough** link to the MP4.

> [!TIP]
> Keep scenes short (3–8 s each). Visitors scan a gallery; they don't watch a
> two-minute GIF. Anything long belongs in the MP4, which costs far less space.

**Reaching every level of a game.** LiveNiro presses the keys you give it; it
can't win a level by itself. If your game saves its progress, write a save file
with `sh` and load it after a `restart`, like the Level 2 scene above. Many
games also accept a level number on the command line or an environment
variable; `restart` re-runs your `run:` command, so either works.

## Options

| Input | Default | What it does |
| --- | --- | --- |
| `path` | `.` | Project folder inside the repo |
| `stack` | `auto` | `auto`, `igraphics`, `javafx`, `pygame` or `custom` |
| `setup` | | Extra shell commands before the build (install packages, fetch assets) |
| `build` | detected | Override the build command |
| `run` | detected | Override the run command (required for `custom`) |
| `window` | largest window | Regex for the title of the window to record |
| `wait-timeout` | `300` | Seconds to wait for the window (first Gradle builds are slow) |
| `warmup` | `2` | Seconds between the window appearing and recording |
| `duration` | `12` | Length of the clip in seconds |
| `actions` | | [Input script](#input-scripts) |
| `scenes` | | A [tour](#tours-every-screen-every-level); replaces `actions` and `duration` |
| `scene-gif-width` | `560` | Width of each scene's GIF in a tour |
| `screen` | `1600x900` | Virtual screen size |
| `fps` | `15` | Recording frame rate (the GIF is capped at 12) |
| `gif-width` | `800` | GIF width in pixels |
| `output-dir` | `.liveniro` | Where the files go |
| `name` | `demo` | Base file name |
| `readme` | `README.md` | README to update; `""` leaves it alone |
| `commit` | `true` | Commit the demo back (push events only) |
| `commit-message` | `docs: update LiveNiro demo [skip ci]` | Message for that commit |
| `upload-artifact` | `true` | Also attach the files to the workflow run |
| `cache` | `true` | Keep Gradle, Maven and pip downloads between runs |

**Outputs:** `stack`, `gif`, `mp4`, `poster` (paths relative to the repo root); for tours also `scenes`, the number of scenes, with `gif` and `poster` pointing at the first scene and `mp4` at the full tour.

## Recipes

<details>
<summary><b>A game that needs a click and some play</b> (iGraphics, SDL, pygame)</summary>

See [`examples/igraphics-game.yml`](./examples/igraphics-game.yml). Keep the
clip short (10–15 s) and end on the most interesting moment: the GIF loops.

</details>

<details>
<summary><b>An app with a login dialog</b> (JavaFX, Swing, Qt)</summary>

See [`examples/javafx-app.yml`](./examples/javafx-app.yml): click the button that
opens the dialog, `focus` the dialog by title, click each field and `type`.
Use a throwaway demo account, never real credentials: the workflow file is public.

</details>

<details>
<summary><b>Any other stack</b> (Rust, Go, Zig, Electron, Godot exports …)</summary>

```yaml
      - uses: Kairo-2081/LiveNiro@v0
        with:
          stack: custom
          setup: sudo apt-get install -y libxkbcommon-x11-0 libgl1-mesa-dri
          build: cargo build --release
          run: ./target/release/myapp
```

Full file: [`examples/custom-rust.yml`](./examples/custom-rust.yml).

</details>

<details>
<summary><b>A monorepo, or several demos from one repo</b></summary>

Point each step at a folder and give it its own name. Let only one of them own
the README block:

```yaml
      - uses: Kairo-2081/LiveNiro@v0
        with: { path: games/snake, name: snake }
      - uses: Kairo-2081/LiveNiro@v0
        with: { path: games/pong, name: pong, readme: "" }
```

</details>

<details>
<summary><b>Record on pull requests without committing</b></summary>

On `pull_request` events LiveNiro never commits; the GIF and MP4 are attached
to the run as an artifact instead. Add `pull_request:` to the workflow's `on:`
to preview a change's demo before merging.

</details>

## Engineering

### Decisions and trade-offs

| Decision | Why | Cost |
| --- | --- | --- |
| **Plain Bash** on Xvfb, ffmpeg and xdotool | Runs on any Ubuntu runner with no image to build, starts in seconds, and anyone can read it | Bash needs care; every script is linted with ShellCheck |
| **Windows found with `xwininfo`**, not `xdotool search` | `xdotool search` misses SDL windows when no window manager is running | One extra call per window while waiting |
| **Software OpenGL** and a **dummy audio driver** | Runners have no GPU and no sound card; apps must not crash for lack of either | Heavy 3D records at a low frame rate; no sound |
| **GIF with a per-clip palette**, plus an MP4 | GIFs play inline in every README; a palette built from the clip itself keeps them small and clean | GIFs are still larger than video, so keep clips short |
| **Commit the files** instead of only uploading an artifact | A README image needs a stable path in the repo | The repo grows by roughly 0.3–2 MB each time the demo changes |
| **Distro Python** for pygame | Runner images put a very new Python first, and pygame often has no wheel for it yet | Your project runs on the distro Python, not the newest one |
| **Tours are one run, cut afterwards** | The app keeps its state from scene to scene, like a real user's session, and launches only once unless you `restart` | A scene can't be re-recorded alone; a broken step means re-running the tour |
| **The full tour is the scene clips joined**, not the raw recording | Restarts and pauses between scenes are cut out, and chapters line up exactly with scenes | Anything between two scenes never appears in the video |
| **Retry only network-looking failures** | 429s and timeouts from package servers are transient; compile errors are not | A real outage still fails, after about 80 s of retries |

### Project layout

```text
action.yml              composite action: tools, cache, run, artifact, commit
src/
  liveniro.sh           the pipeline: detect → set up → build → run → record → encode → README
  lib/
    common.sh           logging, Action outputs, apt installs, retry_network
    detect.sh           zero-config stack detection
    java.sh             Java version detection and setup (JavaFX and Swing)
    display.sh          Xvfb, window discovery, window geometry
    input.sh            the input-script player and tour scenes
    record.sh           ffmpeg recording; GIF / MP4 / poster and tour encoding
    readme.sh           the README marker block and tour gallery
  stacks/
    igraphics.sh        each stack: stack_setup, stack_build, stack_run_command
    javafx.sh
    java.sh             Swing / AWT
    python.sh           pygame, tkinter, Qt, pyglet, arcade … (pygame.sh is an alias)
    cpp.sh              CMake, qmake, Make or plain C/C++ sources
    custom.sh
test/fixtures/          small projects the self-test records
examples/               copy-paste workflows
```

### Testing

[`self-test.yml`](./.github/workflows/self-test.yml) runs on every push and pull
request. It records one real project per stack, with an input script, on a
fresh runner:

| Job | Project | Script |
| --- | --- | --- |
| pygame | [`test/fixtures/pygame-bouncer`](./test/fixtures/pygame-bouncer) | Steer the paddle left and right |
| iGraphics | [Bounce Classic](https://github.com/Kairo-2081/Bounce-Classic) | A full tour: menu, leaderboard, help and all three levels, using `restart` and `sh` |
| JavaFX | [BookVerse](https://github.com/Kairo-2081/LibraryManager) | Welcome → login dialog → dashboard |
| C/C++, Java, Python | Six fixtures: SFML + CMake, SDL2 + Make, raylib, Qt 6, Swing, tkinter | Steer, click and type; the job also checks LiveNiro detected the right stack |

The log ends with the windows that were open when recording stopped, so a
scripted flow that went wrong (a dialog still open, an error alert) is visible
without downloading the GIF.

## Run it locally

LiveNiro is plain Bash, so it runs on any Ubuntu or Debian machine, or in WSL
on Windows:

```bash
sudo apt-get install xvfb ffmpeg xdotool x11-utils
git clone https://github.com/Kairo-2081/LiveNiro ~/liveniro
cd your-project
LN_DURATION=10 LN_ACTIONS=$'wait 1\nkey space' bash ~/liveniro/src/liveniro.sh
```

Every input has an `LN_` environment variable: `LN_STACK`, `LN_RUN`,
`LN_WINDOW`, `LN_README` and so on.

## Limits

- **Linux only.** The project has to build and run on Ubuntu. Windows-only code
  gets a clear error, not a silent failure.
- **Software rendering.** No GPU on runners, so heavy 3D scenes record slowly.
- **Some libraries are built from source**, adding about a minute: raylib always (Ubuntu doesn't package it), and SFML when your code targets a different major version than Ubuntu ships (current runners have SFML 3; most existing projects use SFML 2).
- **No sound** in the recording.
- **A recording, not the live app.** Visitors watch a GIF; they can't play it.
  A self-hostable "▶ Run live" launcher is on the roadmap.
- **Coordinates are pixels.** If your layout moves, update the script (or click
  a point that stays inside the button in both layouts).

## Project status and roadmap

LiveNiro is at **v0.3.0** and records the showcase projects above on every push. Pin
`@v0` to get fixes automatically, or a full tag such as `@v0.3.0` to stay on
one version.

- [x] **v0.1** · iGraphics, JavaFX, pygame and custom stacks; input scripts; README block; self-test on real projects
- [x] **v0.1.1** · `focus` for dialogs and popups; end-of-run window log
- [x] **v0.1.2** · dependency cache; retry on rate limits and timeouts
- [x] **v0.2.0** · tours: named scenes, a GIF per scene, a gallery in the README, a full MP4 with chapters; `restart` and `sh`
- [x] **v0.3.0** · zero-config C/C++ (CMake, Make, qmake, plain sources; SFML, SDL2, raylib, GLFW, GLUT, Qt), Java Swing/AWT, and Python GUIs beyond pygame
- [ ] **v0.4** · "▶ Run live" badge backed by a self-hostable noVNC launcher

### Contributing a stack

A stack is one file in [`src/stacks/`](./src/stacks) with three functions,
`stack_setup`, `stack_build` and `stack_run_command`, plus a detection rule in
[`detect.sh`](./src/lib/detect.sh) and a small fixture with a self-test job.
[`custom.sh`](./src/stacks/custom.sh) shows the interface; [`java.sh`](./src/stacks/java.sh) is a short real one to copy.

## License

[MIT](./LICENSE) © Raian Rashid Mayel
