# clipq

clipboard history for macOS.

- **Recent**: your last 25 copies (text and images), kept across restarts.
- **Saved**: items you want to keep, organized into groups, with optional titles.

## Install

```sh
npm install -g clipq
clipq start
```

Press **Cmd+Shift+V** to open the popup. Requires macOS 13 or later.

| Command | |
|---|---|
| `clipq start` / `stop` / `status` | Run or stop the background app |
| `clipq enable-login` / `disable-login` | Start automatically when you log in |

## Using it

| Key | Action |
|---|---|
| ↑ ↓ | Move selection |
| Return or click | Copy the item and close (then Cmd+V to paste) |
| Tab, Cmd+1 / Cmd+2 | Switch between Recent and Saved |
| Type | Search content and titles |
| Cmd+S | Save the selected Recent item |
| Cmd+Delete | Delete the selected item |
| Esc | Close |

Right-click items for Save, Edit and Delete, and right-click a group header to rename or delete it. Deleting a group moves its items to Ungrouped.

The menu bar icon has Pause Capturing, Clear Recent, Launch at Login and Settings (where you can change the hotkey).

clipq records everything you copy, including passwords from password managers. Pause capturing from the menu bar when that matters. Data is stored in `~/Library/Application Support/clipq/`.

## Development

```sh
swift test                      # core unit tests
scripts/build-app.sh --native   # build npm/dist/Clipq.app for this Mac
open npm/dist/Clipq.app
scripts/build-app.sh            # universal (arm64 + x86_64) build used for releases
```

Pushing a `v*` tag runs `.github/workflows/release.yml`, which tests, builds and publishes to npm (needs an `NPM_TOKEN` secret).
