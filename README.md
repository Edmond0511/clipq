# clipq

clipboard history for macOS.

- **Recent**: your latest copies (text and images), kept across restarts. Keeps 25 by default, or 50 or 100.
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
| Return or click | Copy the item and close, then press Cmd+V. With Paste automatically on, it pastes for you |
| Cmd+Return | Copy only, even with Paste automatically on |
| Tab, Cmd+1 / Cmd+2 | Switch between Recent and Saved |
| Type | Search content and titles |
| Cmd+S | Save the selected Recent item |
| Cmd+Delete | Delete the selected item |
| Cmd+, | Open Settings |
| Esc | Close |

Right-click items for Save, Edit and Delete, and right-click a group header to rename or delete it. Deleting a group moves its items to Ungrouped.

The Clear button on the Recent tab removes all Recent items after asking first. Saved items are never cleared.

The menu bar icon has Pause Capturing, Clear Recent, Launch at Login and Settings.

## Settings

Open Settings from the gear icon in the popup, Cmd+, or the menu bar icon.

| Setting | Default |
|---|---|
| Open clipboard (shortcut) | Cmd+Shift+V |
| Paste automatically | Off |
| Keep in Recent (25, 50 or 100) | 25 |
| Capture images | On |
| Launch at login | Off |

Paste automatically needs Accessibility access: turn on clipq in System Settings → Privacy & Security → Accessibility. clipq isn't signed with an Apple Developer ID, so macOS may ask again after each update. Until access is granted, items are only copied.

clipq records everything you copy, including passwords from password managers. Pause capturing from the menu bar when that matters. Data is stored in `~/Library/Application Support/clipq/`.

## Development

```sh
swift test                      # core unit tests
scripts/build-app.sh --native   # build npm/dist/Clipq.app for this Mac
open npm/dist/Clipq.app
scripts/build-app.sh            # universal (arm64 + x86_64) build used for releases
```

Pushing a `v*` tag runs `.github/workflows/release.yml`, which tests, builds and publishes to npm (needs an `NPM_TOKEN` secret).
