# clipq

Clipboard history for macOS. Press **Cmd+Shift+V** to see what you copied, then pick it again.

- **Recent**: your latest copies (text and images), kept across restarts.
- **Saved**: items you want to keep, in groups, with optional titles.

## Install

```sh
npm install -g @hamster0511/clipq
clipq start
```

Requires macOS 13 or later.

| Command | |
|---|---|
| `clipq start` / `stop` / `status` | Run or stop the background app |
| `clipq enable-login` / `disable-login` | Start automatically when you log in |

## Use it

| Key | Action |
|---|---|
| ↑ ↓ | Move selection |
| Return or click | Copy the item and close, then press Cmd+V |
| Cmd+Return | Copy only, even with Paste automatically on |
| Tab, Cmd+1 / Cmd+2 | Switch between Recent and Saved |
| Type | Search content and titles |
| Cmd+S | Save the selected Recent item |
| Cmd+Delete | Delete the selected item |
| Cmd+, | Open Settings |
| Esc | Close |

- Hover or select a long text, an image or a titled item to see its full contents in a preview card.
- Right-click an item for Save, Edit and Delete. Right-click a group header to rename or delete it. Deleting a group moves its items to Ungrouped.
- Clear on the Recent tab deletes all Recent items after asking. Saved items are never cleared.
- The menu bar icon has Pause Capturing, Clear Recent, Launch at Login and Settings.

## Settings

Open from the gear in the popup, Cmd+, or the menu bar icon.

| Setting | Default |
|---|---|
| Open clipboard (shortcut) | Cmd+Shift+V |
| Paste automatically | Off |
| Keep in Recent (25, 50 or 100) | 25 |
| Capture images | On |
| Launch at login | Off |

**Paste automatically** needs Accessibility access. Turn on clipq in System Settings → Privacy & Security → Accessibility. Until then, items are only copied. clipq isn't signed with an Apple Developer ID, so macOS may ask again after an update.

## Privacy

clipq records everything you copy, including passwords from password managers. Use Pause Capturing in the menu bar when that matters. Everything stays on your Mac in `~/Library/Application Support/clipq/`. Delete that folder to start fresh.

## Development

```sh
swift test                      # core unit tests
scripts/build-app.sh --native   # build npm/dist/Clipq.app for this Mac
open npm/dist/Clipq.app
scripts/build-app.sh            # universal (arm64 + x86_64) build used for releases
```

Pushing a `v*` tag runs `.github/workflows/release.yml`, which tests, builds and publishes to npm. It needs an `NPM_TOKEN` secret, and the version in `npm/package.json` must be bumped first.
