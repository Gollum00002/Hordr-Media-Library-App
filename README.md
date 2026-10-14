<img width="1280" height="640" alt="hordr-mashup-1280x640" src="https://github.com/user-attachments/assets/6c16dcfa-06ab-4c15-8556-454e3e1d10de" />
# Hordr

Hordr is a self-hosted media library server for video and image
collections. It scans your folders, organizes everything into scenes,
galleries, performers, studios and tags, and serves a fast web interface
for browsing and playback — with direct streaming, on-the-fly HLS
transcoding and optional GPU acceleration.

It is an independent Rust implementation of the concepts behind
[Stash](https://github.com/stashapp/stash) (Go), focused on the Linux
experience: a single binary with the web UI and SQLite database
compiled in — no application server, no external services, nothing to
assemble.

```
Rust · Axum · async-GraphQL · SQLite (sqlx) · ffmpeg · HLS · gRPC plugins
```

## Feature overview

| Area | What you get |
|---|---|
| Library | Parallel scanning of scene and image folders, OSHash content hashing, ffprobe metadata, folder-based galleries |
| Organization | Filename and folder conventions (`Studio - Performer - Title [tags]`), performer-name and studio-folder auto-tagging, full CRUD for performers, studios and tags |
| Playback | Direct streaming with HTTP Range, pre-generated H.264 transcodes, live HLS transcode sessions with an adaptive quality ladder, four quality presets, hardware encoding via VAAPI or NVENC |
| Player | Prev/next scene, ±10s seek, playback speed, autoplay-next, keyboard shortcuts, scene markers, hover thumbnail seeking via sprite sheets |
| Images | Original-file serving (no scaled copies), lightbox with zoom and pan, animated GIFs on hover |
| Web UI | Embedded single-page app, customizable home page with 24 section presets, theme system with 32 presets and a custom theme editor, dedicated mobile layout |
| Access control | Opt-in username/password protection with cookie sessions |
| API | Stash-flavored GraphQL (queries, mutations, live subscriptions) plus an interactive playground |
| Extensibility | gRPC plugin system — external processes in any language, crash-isolated, hooked into scan events |
| Migration | One-way import from an existing Stash installation (metadata, relations, ratings, generated artifacts) |

## Requirements (pre-built release)

The release is a single self-contained binary for **Linux on x86-64**.
Everything the program itself needs is compiled in — the web UI, the
SQLite database engine, the gRPC plugin host. There is exactly one
external requirement:

| Requirement | Purpose | Install |
|---|---|---|
| `ffmpeg` and `ffprobe` | media probing, scene thumbnails, hover previews, sprite sheets, transcodes, live HLS, the demo library | `apt install ffmpeg` (Debian/Ubuntu), `dnf install ffmpeg` (Fedora), `pacman -S ffmpeg` (Arch) |

Both programs must be on the `PATH`. Hordr works without them for
browsing an already-scanned library, but scanning, generating and
streaming transcodes all need them, so a normal installation should
always include ffmpeg.

Optional, picked up automatically when present:

- `xdg-open` — lets Hordr open the UI in your default browser on
  startup. Headless sessions (no `DISPLAY`/`WAYLAND_DISPLAY`) are
  detected and skipped; use `--no-browser` to suppress it entirely.
- A GPU with `/dev/dri` (Intel/AMD) or an NVIDIA card — enables
  hardware-accelerated encoding through VAAPI or NVENC when your ffmpeg
  build supports it. Software x264 always works as the fallback.

You do **not** need a Rust toolchain, protoc, a C compiler, a web server
or a database server to run the release — those are only needed to
build from source.

## Installation

### Install or update with install-update.sh

The `install-update.sh` script, available on the project's GitHub page,
installs Hordr and keeps it current:

```bash
./install-update.sh
```

- On a system without Hordr, the script installs the latest release.
- On a system that already has Hordr, it updates the program to the
  latest release.
- It is safe to re-run at any time.

Your media files are never moved, modified or deleted — Hordr only
reads them. Database schema changes are applied automatically the next
time the program starts.

## First start

Double click the Hordr executable file

The server listens on `0.0.0.0:9999` by default and opens the UI at
<http://127.0.0.1:9999/> in your browser. The startup banner also
prints the LAN address so other devices (phones, tablets) can connect;
set `host = "localhost"` in the config or use `--host localhost` for a
loopback-only server.

On a **fresh install** you are asked once whether you want to set up a
username and password for the server. Answering "skip" is a full answer
— it never asks again, and you can enable protection at any time from
**Settings → Security**. Installations upgraded from earlier versions
are never prompted; they can opt in from Settings → Security as well.

## Command line

Running `hordr` with no subcommand starts the server (`serve`).

| Command | Purpose |
|---|---|
| `hordr serve` | run the HTTP/GraphQL server (default) |
| `hordr scan` | headless library scan (register files only) |
| `hordr demo` | generate a demo library of sample videos and images |
| `hordr doctor` | print a system report (ffmpeg, hardware encoders, paths) |

Useful flags:

```bash
hordr serve --host localhost --port 8080   # loopback-only bind on port 8080
hordr serve --no-browser                   # do not open a browser
hordr serve --config /path/config.toml     # use a specific config file
hordr scan --tag --generate                # scan, then tag, then generate
hordr demo --dir /somewhere/else           # place the demo library elsewhere
```

## Managing the library

Library work is split into three independent tasks, each with its own
options on the Settings page (and each cancellable while running — a
cancelled task finishes only the items already in flight, so no artifact
is ever left half-written):

1. **Scan** — walks the configured folders and registers new or changed
   files. Nothing is tagged and nothing is generated yet.
2. **Tag** — applies metadata: the filename/folder conventions,
   performer name/alias matching (any file whose path mentions a
   performer gets them attached) and studio-folder matching (any folder
   named after a studio tags its contents).
3. **Generate** — produces the ffmpeg artifacts: scene thumbnails,
   hover previews, seek-preview sprite sheets and full H.264 transcodes
   for playback (each toggleable).

Tasks run sequentially through a job queue with live progress in the UI
(a floating pill shows the running task and its progress on every page).

### Filename conventions

The tag task parses metadata from file and folder names (all parts
optional):

```
Studio - Performer1 & Performer2 - Title [tag1, tag2].ext
```

- Segments are separated by ` - `.
- Three segments: `Studio - Performers - Title`.
- Two segments: the first is a studio if it ends in a studio-like word
  (Studio(s), Films, Media, Pictures, Productions, Entertainment, TV,
  Network(s), Group, ...), otherwise a performer.
- Multiple performers: `A & B`, `A, B`, `A and B`.
- A trailing `[a, b]` bracket list becomes tags.
- Dots and underscores in the remaining title normalize to spaces.

**Galleries** are folder-based: every directory containing images
becomes a gallery titled by the folder's "Title" segment. Folder-level
studio, performers and tags apply to every image inside; individual
file names can add more. Everything can be edited afterwards through
the UI or the GraphQL API.

## The web interface

- **Home** — a customizable dashboard built from 24 section presets
  (recently added, top rated, most O-counter, random, longest, latest
  from a studio, scenes with a tag, favorites, biggest studios, most
  used tags, library statistics, and more). Add, rename, reorder and
  remove sections; the layout is stored server-side.
- **Scenes** — grid with search, tag/performer/studio filter chips, all
  the sorts (path, title, date, rating, O count, size, duration,
  added, updated) plus seeded Random with a Shuffle button. Hovering a
  card plays the generated preview clip.
- **Scene page** — player with prev/next scene, ±10s seek, playback
  speed (0.25x to 3x), autoplay-next and keyboard shortcuts; rating,
  O counter, edit and delete. (The O counter is a per-scene tally with
  a droplet icon — increment it from the scene page, the image
  lightbox or the card chips; images carry one too.)
- **Galleries** — cover grids with a chosen cover image, and a lightbox
  viewer with per-image counters.
- **Images** — every image in the library regardless of gallery, with
  search, sort, shuffle, filter chips and the lightbox. GIFs animate on
  hover.
- **Performers / Studios / Tags** — searchable entity pages with
  create/edit dialogs (full Stash-style field set). Saving a performer
  or studio immediately auto-tags files and folders that mention it.
- **Settings** — library paths, the three library tasks with live
  progress, playback defaults, interface options, theme management,
  security, migration, plugins, stats and system info.

### Seeking and markers

The Generate task tiles roughly a hundred small frames across the whole
video into one JPEG plus a WebVTT index. On desktops, hovering the seek
bar shows a thumbnail preview of the frame you would land on; on
phones, dragging horizontally on the video scrubs with a live
seconds-offset indicator. Scene markers are titled points in time — the
flag button in the player drops one at the current position; markers
render as ticks on the seek bar (click to jump) and as a list in the
scene's sidebar.

### Playback quality

Playback uses one of four presets, selectable in the player's gear menu
per tab and as a default in Settings → Playback. The gear menu shows
each preset's realized target for the current scene (for example
"Quality · 2K", "Fast · 720p").

| Preset | Delivery | On 2K+ sources | On smaller sources | x264 | Audio |
|---|---|---|---|---|---|
| **Quality** | pre-generated file (up to 1080p sources), else HLS | 2K live | 1080p | CRF 18, `faster` | 192 kbps |
| **Balanced** | pre-generated file (up to 1080p sources), else HLS | 1080p live | 720p | CRF 21, `veryfast` | 160 kbps |
| **Fast** | pre-generated file (up to 1080p sources), else HLS | 720p live | 480p | CRF 26, `ultrafast` | 128 kbps |
| **Direct** | original file | — | — | — | — |

The resolution ladder is adaptive and never upscales: a source whose
short display edge is 1440 pixels or more transcodes at
2K → 1080p → 720p; smaller sources keep the classic
1080p → 720p → 480p ladder. Sample aspect ratios are handled correctly
— portrait, square and anamorphic sources are judged on what they
display, and encoded with square pixels.

The Generate task bakes a full H.264 copy of every scene up to 1080p at
the default preset's ladder entry, so playback at that preset serves a
finished file over plain HTTP: zero live transcoding, instant start,
instant seeking. Sources above 1080p are never baked — they play
directly or through a live session, so no giant copies of
high-resolution masters pile up on disk. "Direct" serves the original
file, falling back to the best pre-generated transcode when the browser
cannot decode the original codec.

### Hardware encoding

Both the Generate-time bake and the live HLS sessions can use the GPU.
`hw_accel` (Settings → Playback, or `config.toml`) selects the mode:

| Mode | Behavior |
|---|---|
| `auto` | NVENC when usable, else VAAPI, else software x264 |
| `vaapi` | force VAAPI (Intel/AMD GPUs via `/dev/dri/renderD128`) |
| `nvenc` | force NVIDIA NVENC |
| `off` | always software x264 (best quality per bit) |

Hardware encoders pass a test encode before use. The Generate task runs
a few GPU jobs plus an x264 job on the otherwise idle CPU
(`gpu_parallel` / `cpu_parallel` in `[transcode]`, or the Settings →
Tasks → Generate inputs), so a single consumer NVENC engine is not
time-sliced to death by parallel jobs.

### Image viewer

Every lightbox (images page, galleries, entity image tabs) supports
zoom and pan: on the desktop, Ctrl+scroll zooms toward the cursor and
the arrow keys pan; on phones, +/− buttons zoom, a drag pans and a
double-tap toggles between fit and the last zoom level. The zoom level
persists while paging through images.

### Mobile

Mobile browsers get a dedicated layout: the top navigation collapses
and a three-button bottom bar (Home / Pages / Settings) takes over. The
Pages button opens a bottom sheet of links — long-press any of them for
your browser's "open in new tab" option. A floating pill on every page
shows the running task and its progress. Player taps are two-stage on
touch devices (first tap shows the controls, second pauses), and the
control bar hides after a few idle seconds.

## Themes

Settings → Theme → Set Theme opens the theme picker:

- **32 preset themes** shown as gradient cards of the colors they paint
  with — Hordr Dark, OLED Black, Nord, Dracula, Tokyo Night, Gruvbox,
  Catppuccin, Rosé Pine, One Dark, Solarized, Synthwave, Monokai, GitHub
  Dark, Everforest, Kanagawa and more, including light themes.
- Five **live miniature previews** of the Scenes / Images / Studios /
  Performers / Galleries pages recolor as you hover a theme.
- A **custom theme editor** seeded from any theme — 12 palette slots
  (surfaces, text, accent, status colors) with live previews. Saved
  custom themes appear as their own cards and can be edited or deleted;
  presets are built in.
- Clicking a card applies the theme instantly, with an undo toast.

Themes are stored server-side, so every device sees the same look, and
the active theme ships as CSS variables from `/theme.css` — the first
paint is already themed. Custom themes can be **exported** as `.json`
files and **imported** back on any install; missing slots fill from the
defaults and non-Hordr files are rejected with a clear message.

## Access control

Username/password protection is opt-in:

- On a **fresh install** you are asked once whether to set it up;
  skipping is a full answer and the prompt never returns. Installs
  upgraded from earlier versions are never prompted.
- At any time, **Settings → Security** can set, change or remove
  credentials (changing requires the current password), or log a device
  out.
- Usernames and passwords are letters and digits only; the username is
  up to 20 characters, the password 4 to 64. The password is stored as
  a salted, iterated hash — never in plain text.
- With protection on, every device must sign in before anything is
  served: pages redirect to a self-contained `/login`, and media and
  API requests return 401. Sessions are 30-day HttpOnly,
  SameSite=Lax cookies.
- Lost the password? Remove the `[auth]` section from `config.toml`
  and restart — then set new credentials from Settings → Security.

## Migrating from Stash

Settings → Migration imports an existing Stash installation. Point
Hordr at the Stash app folder (the one with `config.yml`,
`stash-go.sqlite` and `generated/`), press **Analyze** for a dry-run
report, then start the migration. Scenes, images, galleries,
performers, studios, tags, ratings, relations, O counters and
gallery covers come over; scene posters, hover previews and seek-sprite
sheets are adopted from Stash's generated tree; zip-based galleries are
extracted into a folder you choose. Media files are never moved or
copied — after the import you can delete the Stash app directory. The
import is idempotent: re-runs refresh, never duplicate. See
[MIGRATION.md](MIGRATION.md) for the full design and mapping tables.

## Where your files live

Everything Hordr writes stays inside the folder containing the `hordr`
executable — `config.toml`, the database (`hordr.sqlite3`), the
`generated/` artifact tree and the demo library. Deleting that one
folder removes every trace of the app; nothing is scattered around your
filesystem, and your media library is only ever read.

Two overrides exist for special setups:

- `$HORDR_HOME` — store data elsewhere (used by the Docker image).
- `--config /path/to/config.toml` — data lives next to that file.

If the executable folder is read-only (for example a system-wide
install under `/usr/local/bin`), Hordr falls back to
`~/.local/share/hordr` and says so on startup. `hordr doctor` and
Settings → System always show the live location.

## Configuration

`config.toml` is created on first run in the app folder (see above).
The interesting sections:

```toml
host = "0.0.0.0"              # bind address ("localhost" = loopback only)
port = 9999
open_browser = true            # open the UI on startup
database_path = "hordr.sqlite3"
generated_path = "generated"   # thumbnails, previews, HLS sessions
playground = true              # GraphQL IDE at /playground

[tasks.scan]
rescan = false                 # re-probe already-registered files
parallel = 2                   # parallel probe workers (1-32)

[tasks.tag]
from_filenames = true          # "Studio - Performer - Title [tags]" parsing
by_performer_name = true       # files mentioning a performer's name/alias
by_studio_folder = true        # folders named after a studio
parallel = 2

[tasks.generate]
scene_thumbnails = true        # poster screenshots
scene_previews = true          # hover video clips (native fps, max 60)
scene_sprites = true           # seek-preview sprite sheets
transcodes = true              # full H.264 copies (scenes up to 1080p)
parallel = 2

[playback]
speed = 1.0                    # default playback speed (0.25-3)
quality = "direct"             # quality | balanced | fast | direct
autoplay_next = true
volume = 1.0

[transcode]
hw_accel = "auto"              # auto | vaapi | nvenc | off
gpu_parallel = 2               # concurrent GPU transcodes (1-8)
cpu_parallel = 1               # concurrent CPU x264 transcodes (0-8)

[plugins]
enabled = true
paths = ["plugins"]

[[stashes]]
path = "/path/to/videos"
exclude = [".git", "samples"]
```

The `[auth]` and `[theme]` sections are managed by the app (Settings →
Security and Settings → Theme) and rarely need hand-editing. Every
per-task parallelism, the playback defaults and the transcode lanes are
also editable in the UI.

## HTTP endpoints

| Route | Purpose |
|---|---|
| `GET /` | the web UI |
| `POST /graphql`, `WS /graphql` | API and subscriptions |
| `GET /playground` | interactive GraphQL IDE |
| `GET /healthz` | liveness probe |
| `GET /login` | sign-in page (only with protection enabled) |
| `GET /theme.css` | the active theme as CSS variables |
| `GET /scene/{id}/stream` | direct stream (Range supported) |
| `GET /scene/{id}/transcode/{preset}` | pre-generated transcode (404 = not baked; the player falls back to HLS) |
| `GET /scene/{id}/screenshot` | poster thumbnail |
| `GET /scene/{id}/preview` | hover-preview clip |
| `GET /scene/{id}/sprite`, `/scene/{id}/sprite.vtt` | seek-preview sprite sheet and index |
| `GET /scene/{id}/hls/master.m3u8` | start/reuse an HLS session (`?start=123.4` seeks, `?quality=` picks the preset) |
| `GET /scene/{id}/hls/{session}/{seg}` | validated segment proxy |
| `GET /image/{id}/image` | the original image file (Range supported) |
| `GET /asset/migrated/{entity}/{file}` | performer/studio images imported from a Stash blob store |

## GraphQL API

The API mirrors Stash naming: entity fields are snake_case
(`rating100`, `o_counter`, `per_page`), operations are camelCase
(`findScenes`, `metadataScan`).

```graphql
query {
  findScenes(
    filter: { q: "", page: 1, per_page: 25, sort: "path", direction: ASC }
    scene_filter: { title: { value: "Duet", modifier: INCLUDES } }
  ) {
    count
    scenes {
      id title rating100 o_counter
      files { path duration width height }
      studio { name }
      performers { name }
      tags { name }
    }
  }
}

# The three library tasks (queued; progress via subscription or jobQueue)
mutation { metadataScan(input: {}) }
mutation { metadataTag(input: { by_performer_name: true }) }
mutation { metadataGenerate(input: { scene_previews: true }) }

# Live task events over graphql-transport-ws at /graphql
subscription { scanEvents { type message progress done total level } }
```

Other roots include `findPerformers`, `findStudios`, `findTags`,
`findImages`, `findGalleries`, `allPerformers`, `allStudios`, `allTags`,
`homeSections`, `stats`, `version`, `systemStatus`, `jobQueue`,
`plugins` and `configuration`; mutations cover entity CRUD
(`sceneUpdate`, `performerCreate`, `galleryUpdate`, ...), the library
tasks, home-section layout, theme management and general configuration.
Explore interactively at `/playground`.

## Plugins

Plugins are external processes speaking gRPC over a Unix socket — any
language works, crashes are isolated from the server, and they can be
hot-reloaded from the UI. A plugin directory contains a `plugin.toml`:

```toml
name = "demo-tagger"
description = "Tags scenes based on filename keywords"
version = "0.1.0"
exec = ["stash-plugin-demo"]     # absolute path | ./relative | PATH lookup
hooks = ["scene.created", "scan.completed"]
```

The host spawns the process with `STASH_PLUGIN_SOCKET=<uds path>`; the
process implements `stash.plugin.v1.Plugin` (`GetManifest`, `OnEvent`)
and returns actions (`add_tag`, `set_studio`) that the host applies to
the database. See `crates/stash-plugin-demo` for a complete reference
implementation and `proto/stash/plugin/v1/plugin.proto` for the
contract. Enable by placing plugin directories under `<home>/plugins/`
(or add paths to `[plugins] paths`).

## License

AGPL-3.0-only, matching upstream Stash.
