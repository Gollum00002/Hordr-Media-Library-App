<img width="1280" height="640" alt="hordr-mashup-1280x640" src="https://github.com/user-attachments/assets/6c16dcfa-06ab-4c15-8556-454e3e1d10de" />

# Hordr

Hordr is a self-hosted media library server for video and image
collections. It scans your folders, organizes everything into scenes,
galleries, performers, studios and tags, and serves a fast web interface
for browsing and playback — with direct streaming, live HLS transcoding
and optional GPU acceleration.

It is an independent Rust implementation of the concepts behind
[Stash](https://github.com/stashapp/stash) (Go), focused on Linux: a
single binary with the web UI and SQLite database compiled in — no
application server, no external services, nothing to assemble.

```
Rust · Axum · async-GraphQL · SQLite (sqlx) · ffmpeg · HLS · gRPC plugins
```

## Features

| Area | What you get |
|---|---|
| Library | Parallel, incremental scanning of video and image folders, OSHash content hashing, ffprobe metadata, folder-based galleries |
| Organization | Filename and folder conventions (`Studio - Performer - Title [tags]`), performer-name and studio-folder auto-tagging, full CRUD for performers, studios and tags |
| Playback | Direct streaming with HTTP Range, or live HLS transcoding at 2K / 1080p / 720p, capped at 60 fps or at the original frame rate, with NVENC, VAAPI or software encoding |
| Player | Prev/next scene, ±10 s seek, speed 0.25x–3x, autoplay-next, keyboard shortcuts, scene markers, hover thumbnail seeking |
| Images | Original-file serving, lightbox with zoom and pan, animated GIFs on hover |
| Search | Live search on every list page and on performer/studio/tag tabs, plus filter chips and sorting |
| Web UI | Embedded single-page app, customizable home page, 32 themes plus a custom theme editor, dedicated mobile layout |
| Access control | Optional username/password protection with cookie sessions |
| API | Stash-style GraphQL (queries, mutations, live subscriptions) with an interactive playground |
| Extensibility | gRPC plugin system: external processes in any language, crash-isolated, hooked into scan events |
| Migration | One-way import from an existing Stash installation |

## Requirements

The release is a single self-contained binary for **Linux on x86-64**.
The web UI, SQLite and the plugin host are all compiled in. The only
external requirement is:

| Requirement | Purpose | Install |
|---|---|---|
| `ffmpeg` and `ffprobe` | probing, thumbnails, previews, sprite sheets, live transcoding, the demo library | `apt install ffmpeg` (Debian/Ubuntu), `dnf install ffmpeg` (Fedora), `pacman -S ffmpeg` (Arch) |

Both must be on the `PATH`.

Optional, picked up automatically:

- `xdg-open` — opens the UI in your default browser on startup (headless
  sessions are detected; `--no-browser` disables it).
- An NVIDIA GPU (NVENC) or an Intel/AMD GPU with `/dev/dri` (VAAPI) —
  hardware-accelerated transcoding when your ffmpeg build supports it.
  Software x264 always works as the fallback.

No Rust toolchain, protoc, C compiler, web server or database server is
needed to run the release.

Check your system with:

```bash
hordr doctor
```

It prints the app folder, config and database locations, the
ffmpeg/ffprobe versions and the VAAPI/NVENC probe results.

## Installation

### Install or update with install-update.sh

The `install-update.sh` script, available on the project's GitHub page,
installs Hordr and keeps it current:

```bash
./install-update.sh
```

- On a system without Hordr it installs the latest release.
- On a system that already has Hordr it updates to the latest release.
- It is safe to re-run at any time.

### Manual installation

Download the latest release, extract it to a folder and run
`./hordr`. To update, extract the new release over the existing
folder and replace all files.

### Docker

```bash
docker compose up -d
```

The container listens on port 9998. State persists in the `stashrs-data`
volume; mount your library at `/library` (set `HORDR_LIBRARY` or edit the
compose file) and add `/library` as a library path in the UI. For NVIDIA
transcoding (requires the NVIDIA Container Toolkit):

```bash
docker compose -f docker-compose.yml -f docker-compose.nvidia.yml up -d
```

Your media files are never moved, modified or deleted — Hordr only reads
them. Database changes are applied automatically on the next start.

## First start

Run `./hordr` (or double-click the executable). The server listens
on `0.0.0.0:9999` and opens <http://127.0.0.1:9999/>. The startup banner
prints the LAN address so phones and tablets can connect; use
`--host localhost` for a loopback-only server.

On a fresh install you are asked once whether to set up a username and
password. Skipping is a full answer — it never asks again, and you can
enable protection any time under **Settings → Security**.

To try it out, generate a demo library, then use **Settings → Scan
library**, **Tag** and **Generate**:

```bash
hordr demo
```

## Command line

| Command | Purpose |
|---|---|
| `hordr serve` | run the HTTP/GraphQL server (default) |
| `hordr scan` | headless library scan (registers files only) |
| `hordr demo` | generate a demo library of sample videos and images |
| `hordr doctor` | system report: ffmpeg, hardware encoders, paths |
| `hordr doctor --transcode-test` | benchmark every transcode pipeline on synthetic 1080p |
| `hordr doctor --transcode-file <video>` | benchmark transcoding on one of your own files |

```bash
hordr serve --host localhost --port 8080   # loopback-only on port 8080
hordr serve --no-browser                   # do not open a browser
hordr serve --config /path/config.toml     # use a specific config file
hordr scan --tag --generate                # scan, then tag, then generate
```

## Managing the library

Library work is three independent, cancellable tasks (Settings page),
run through a job queue with live progress:

1. **Scan** — registers new or changed files. Nothing is tagged or
   generated yet.
2. **Tag** — applies metadata from filename/folder conventions,
   performer names and aliases, and studio-named folders.
3. **Generate** — creates scene thumbnails, hover previews and
   seek-preview sprite sheets. Transcodes are never pre-generated;
   playback encodes them on demand.

All three are incremental. Scan fingerprints each folder and skips
unchanged ones without opening a single file, Tag only visits files not
yet tagged, and Generate only creates what is missing. Options in
Settings force a re-probe or a full re-tag when you want one.

### Filename conventions

```
Studio - Performer1 & Performer2 - Title [tag1, tag2].ext
```

- Segments are separated by ` - `; all parts are optional.
- Three segments: `Studio - Performers - Title`. With two, the first is
  a studio if it ends in a studio-like word (Studio, Films, Media,
  Pictures, Productions, Entertainment, TV, Network, Group, …),
  otherwise a performer.
- Multiple performers: `A & B`, `A, B`, `A and B`.
- A trailing `[a, b]` list becomes tags.
- Dots and underscores in the title become spaces.

**Galleries** are folder-based: every folder containing images becomes a
gallery. Folder-level studio, performers and tags apply to every image
inside. Everything can be edited afterwards in the UI or via GraphQL.

## The web interface

- **Home** — customizable dashboard of section presets (recently added,
  top rated, random, longest, favorites, biggest studios, library
  statistics, …); the layout is stored on the server.
- **Scenes** — grid with live search, filter chips, sorting (path,
  title, date, rating, O count, size, duration, added, updated) and
  seeded Random. Hovering a card plays its preview clip.
- **Scene page** — player with prev/next, ±10 s seek, speed 0.25x–3x,
  autoplay-next, markers, rating, O counter, edit and delete.
- **Galleries / Images** — cover grids and a lightbox with zoom, pan and
  auto-hiding controls; GIFs animate on hover.
- **Performers / Studios / Tags** — searchable entity pages with
  create/edit dialogs. Each page has Scenes, Galleries and Images tabs
  with their own search, sort and shuffle.
- **Settings** — library paths and tasks, playback defaults, interface,
  themes, security, migration, plugins, stats and system info.

**Seeking and markers.** Generate tiles about a hundred frames into one
sprite sheet. On desktop, hovering the seek bar previews the frame; on
phones, dragging on the video scrubs. The flag button drops a titled
marker at the current position, shown as ticks on the seek bar.

**Mobile.** Phones get a dedicated layout with a bottom navigation bar,
a bottom-sheet page menu, two-stage player taps (first tap shows the
controls, second pauses) and a floating task-progress pill. The player's
playback-settings menu opens as a scrollable bottom sheet.

## Playback and transcoding

Pick a quality in the player's gear menu (per tab) or set a default in
**Settings → Playback**. A preset is a resolution plus a frame-rate
policy:

| Preset | Short edge | Frame rate |
|---|---|---|
| **2K 60** | up to 1440 | at most 60 fps |
| **1080p 60** | up to 1080 | at most 60 fps |
| **720p 60** | up to 720 | at most 60 fps |
| **2K OFR** | up to 1440 | original frame rate |
| **1080p OFR** | up to 1080 | original frame rate |
| **720p OFR** | up to 720 | original frame rate |
| **Direct** | original | original file |

- Video is never upscaled and the frame rate is never raised. A 24 or
  30 fps source keeps its own rate under every preset; a 120 fps source
  becomes 60 fps under the `60` presets and stays 120 fps under `OFR`.
  Sources with an unknown frame rate are left untouched, so nothing
  fails because of an unusual rate.
- Direct serves the original file and falls back to HLS when the browser
  cannot decode it.

**How it works.** The HLS playlist covers the whole file instantly, so
you can seek anywhere. Video is encoded in 2-second segments by
short-lived encoder sessions that stay a few segments ahead of the
player. Seeking pre-empts background work, and hovering a scene card
prewarms its first seconds so playback starts from the cache. Segments
are kept in a bounded disk cache (default 25 GiB, configurable or
unlimited; **Settings → Tasks → Transcode cache** can empty it).

**Hardware encoding.** `hw_accel` selects the encoder:

| Mode | Behavior |
|---|---|
| `auto` | NVENC when usable, else VAAPI, else software x264 |
| `vaapi` | force VAAPI (Intel/AMD, `/dev/dri/renderD128`) |
| `nvenc` | force NVIDIA NVENC |
| `off` | always software x264 |

Hardware encoders pass a test encode first and fall back gracefully
(NVENC: full-GPU → hybrid → software; VAAPI → software), so a file the
GPU cannot handle degrades instead of failing.

**GPU and CPU work together.** Each stream is split into sessions. New
sessions take a GPU lane first (`gpu_parallel`, default 2) and spill
onto the CPU when the GPU lanes are busy (`cpu_parallel`, default 1;
`0` = GPU only). Both counts are editable in Settings → Playback and
apply immediately. Hordr also measures how fast each lane type is
running and prefers the faster one.

**Very high-resolution sources.** A GPU video decoder tops out at roughly
1.6 Gpixel/s, which limits 4K 120 fps sources to about 1.6x on the GPU
alone. For such sources Hordr gives the GPU one session and runs the
rest on the CPU, which decodes in software but still encodes on NVENC,
with at least two CPU lanes while the stream plays.

**Bandwidth.** Every encoder is capped with a bitrate ceiling (about
14 Mbit/s at 1080p, 6 at 720p, 40 at 4K; higher above 62 fps) so a phone
on wifi never needs more than it has.

**Encoder tuning.** `encode_speed = "fast"` (default) favors speed;
`"quality"` uses slower, higher-quality x264 settings.

**Check your hardware.** `hordr doctor --transcode-test` encodes
synthetic 1080p through every pipeline your machine supports and prints
the speed of each as "x realtime"; 2x or more means 1080p plays smoothly
at 2x speed. `hordr doctor --transcode-file <video>` does the same with
your own file, which is the better test for 4K or high-frame-rate
sources. The server log also reports `transcode session finished …
realtime_x=…` for every session.

## Themes

**Settings → Theme → Set Theme** opens the picker:

- **32 preset themes**, dark and light — Hordr Dark, OLED Black, Nord,
  Dracula, Tokyo Night, Gruvbox, Catppuccin, Rosé Pine, One Dark,
  Solarized, Synthwave, Monokai, GitHub Dark, Everforest, Kanagawa and
  more.
- Live miniature previews of the main pages recolor as you hover.
- A **custom theme editor** (12 palette slots) seeded from any theme.
- Custom themes can be exported as `.json` and imported on any install.

Themes are stored on the server, so every device shares the same look.

## Access control

Optional username/password protection:

- Set, change or remove credentials in **Settings → Security**, or log a
  device out.
- Usernames and passwords use letters and digits only (username up to
  20 characters, password 4 to 64). Passwords are stored as salted,
  iterated hashes.
- With protection on, every device must sign in: pages redirect to
  `/login` and media/API requests return 401. Sessions are 30-day
  HttpOnly cookies.
- Lost the password? Remove the `[auth]` section from `config.toml` and
  restart, then set new credentials in Settings → Security.

## Migrating from Stash

**Settings → Migration** imports an existing Stash installation. Point it
at the Stash folder (the one with `config.yml`, `stash-go.sqlite` and
`generated/`), run **Analyze** for a dry-run report, then start the
import. Scenes, images, galleries, performers, studios, tags, ratings,
relations, O counters and gallery covers come over; posters, previews
and sprite sheets are adopted from Stash's generated files. Media files
are never moved or copied, and re-running the import refreshes rather
than duplicates. See [MIGRATION.md](MIGRATION.md) for details.

## Where your files live

Everything Hordr writes stays in the folder containing the executable:
`config.toml`, the database (`hordr.sqlite3`), the `generated/` folder
and the demo library. Deleting that folder removes every trace of the
app; your media is only ever read.

- `$HORDR_HOME` stores data elsewhere (used by the Docker image).
- `--config /path/to/config.toml` keeps data next to that file.
- If the executable folder is read-only, Hordr falls back to
  `~/.local/share/hordr` and says so on startup.

`hordr doctor` and Settings → System always show the live location.

## Configuration

`config.toml` is created on first run. The main settings:

```toml
host = "0.0.0.0"              # bind address ("localhost" = loopback only)
port = 9999
open_browser = true
database_path = "hordr.sqlite3"
generated_path = "generated"   # thumbnails, previews, HLS segments
playground = true              # GraphQL IDE at /playground

[tasks.scan]
rescan = false                 # re-probe already-registered files
parallel = 2

[tasks.tag]
from_filenames = true
by_performer_name = true
by_studio_folder = true
retag = false
parallel = 2

[tasks.generate]
scene_thumbnails = true
scene_previews = true
scene_sprites = true
parallel = 2

[playback]
speed = 1.0                    # default playback speed (0.25-3)
quality = "direct"             # 2k60 | 1080p60 | 720p60 | 2kofr | 1080pofr | 720pofr | direct
autoplay_next = true
volume = 1.0

[transcode]
hw_accel = "auto"              # auto | vaapi | nvenc | off
gpu_parallel = 2               # concurrent GPU lanes (1-8)
cpu_parallel = 1               # concurrent CPU lanes (0-8)
encode_speed = "fast"          # fast | quality
cache_limit_gb = 25.0          # transcode cache ceiling (0 = unlimited)

[plugins]
enabled = true
paths = ["plugins"]

[[stashes]]
path = "/path/to/videos"
exclude = [".git", "samples"]
```

The `[auth]` and `[theme]` sections are managed by the app. Task
parallelism, playback defaults and transcode lanes are also editable in
the UI.

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
| `GET /scene/{id}/screenshot` | poster thumbnail |
| `GET /scene/{id}/preview` | hover-preview clip |
| `GET /scene/{id}/sprite`, `/scene/{id}/sprite.vtt` | seek-preview sprite sheet and index |
| `GET /scene/{id}/hls/master.m3u8` | full-duration HLS playlist (`?quality=` picks the preset) |
| `GET /scene/{id}/hls/prewarm` | hint to encode the scene's first segments in the background |
| `GET /scene/{id}/hls/{quality}/{segment}` | one 2 s segment, encoded on demand and cached |
| `GET /image/{id}/image` | the original image file (Range supported) |

## GraphQL API

Naming mirrors Stash: snake_case fields (`rating100`, `o_counter`,
`per_page`) and camelCase operations (`findScenes`, `metadataScan`).

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
`findImages`, `findGalleries`, `homeSections`, `stats`, `version`,
`systemStatus`, `jobQueue`, `plugins` and `configuration`. Mutations
cover entity CRUD, the library tasks, home layout, themes and settings.
Explore interactively at `/playground`.

## Plugins

Plugins are external processes speaking gRPC over a Unix socket — any
language works, crashes are isolated from the server, and they can be
reloaded from the UI. A plugin folder contains a `plugin.toml`:

```toml
name = "demo-tagger"
description = "Tags scenes based on filename keywords"
version = "0.1.0"
exec = ["stash-plugin-demo"]     # absolute path | ./relative | PATH lookup
hooks = ["scene.created", "scan.completed"]
```

The host starts the process with `STASH_PLUGIN_SOCKET=<socket path>`. The
process implements `stash.plugin.v1.Plugin` (`GetManifest`, `OnEvent`)
and returns actions (`add_tag`, `set_studio`) that Hordr applies. See
`crates/stash-plugin-demo` for a reference implementation and
`proto/stash/plugin/v1/plugin.proto` for the contract. Place plugin
folders under `<app folder>/plugins/` or add paths in `[plugins] paths`.

## Building from source

Requires Rust ≥ 1.75, `protoc` ≥ 3 and a C compiler:

```bash
./build.sh          # verifies prerequisites, builds the release binary
```

Options: `--debug`, `--check-only`, `--skip-checks`, `--install`
(installs to `~/.local/bin`). To test:

```bash
cargo test --workspace
```

```
crates/
  stash-core       domain models, config, auth, themes, filters, event bus
  stash-db         SQLite layer: migrations + repositories
  stash-scanner    library walking, filename parsing, ffprobe, thumbnails
  stash-stream     direct streaming + on-demand HLS transcoding and cache
  stash-plugins    gRPC plugin host
  stash-plugin-demo reference plugin
  stash-migrate    Stash import
  stash-server     HTTP + GraphQL + CLI + embedded UI
ui/                embedded web UI (compiled into the binary)
```

## Previews

<img width="1600" height="900" alt="home" src="https://github.com/user-attachments/assets/dc54a318-0130-471f-accb-85213d3d7e87" />
<img width="1600" height="900" alt="scenes" src="https://github.com/user-attachments/assets/5f2f66f0-bba1-4126-a276-22579f909576" />
<img width="1600" height="900" alt="studios" src="https://github.com/user-attachments/assets/a32b0e38-3fe2-4178-bb48-52d49a87a182" />
<img width="1600" height="900" alt="performers" src="https://github.com/user-attachments/assets/97667496-5cd6-48fd-b445-dfb12732c311" />
<img width="1600" height="900" alt="galleries" src="https://github.com/user-attachments/assets/76543d78-fed0-4949-b56c-2360757c877b" />
<img width="1600" height="900" alt="images" src="https://github.com/user-attachments/assets/e957927c-d640-4643-b3d6-cfe8bd4d9ac6" />
<img width="1600" height="900" alt="themes" src="https://github.com/user-attachments/assets/da1bd6a7-1868-423a-971a-1c5ace8090e1" />

## License

AGPL-3.0-only, matching upstream Stash.
