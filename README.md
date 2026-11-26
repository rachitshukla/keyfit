<p align="center"><img src="assets/KeyFit.png" width="144" height="144" alt="KeyFit, a blue keycap with a split window"></p>

# KeyFit

Snap the focused Mac window with three global keyboard shortcuts. KeyFit waits for macOS to deliver a shortcut and stays out of the Dock and menu bar.

| Shortcut | Action |
| --- | --- |
| **⌘ ←** | Fill the left half of the display |
| **⌘ →** | Fill the right half of the display |
| **⌘ ↑** | Maximize within the space available above the Dock and below the menu bar |

A window spanning two displays snaps to the one containing more of it. Native full-screen windows and fixed-size windows are skipped. Some apps enforce a minimum size or resize in steps. While KeyFit is running, these three shortcuts take precedence over app shortcuts, including text navigation.

## Install from source

Build on a Mac with macOS 12 Monterey or later and the Xcode Command Line Tools. To install the tools, run `xcode-select --install` and let the installation finish.

```sh
git clone https://github.com/rachitshukla/keyfit.git
cd keyfit
make
open -R KeyFit.app
```

Drag the app Finder selected into **Applications**, then open the installed copy. Quit any other window manager that has claimed these shortcuts.

1. In **System Settings → Privacy & Security → Accessibility**, enable **KeyFit**. On Monterey, use **System Preferences → Security & Privacy → Privacy → Accessibility**.
2. Open KeyFit again. Focus a resizable window and press **⌘ ←** to try it.
3. To start it at sign-in, add the installed app under **General → Login Items → Open at Login** (called **Login Items & Extensions** on newer systems). On Monterey, use **Users & Groups → Login Items**.

KeyFit requests Accessibility access to read and resize the focused window. The app has no network code, telemetry, or polling timer. [Apple’s guide to Accessibility permissions](https://support.apple.com/guide/mac-help/allow-accessibility-apps-to-access-your-mac-mh43185/mac)

## Build and test

`make` creates a universal app with native **arm64** and **x86_64** executables. It also generates the Finder icon from the PNG in `assets/`. All build tools ship with macOS or the Xcode Command Line Tools.

```sh
make test       # Check both slices, the app signature, and window layout calculations
make package    # Create build/KeyFit-universal.zip
```

GitHub Actions runs the build and layout tests on Intel and Apple silicon. To check end-to-end behavior on your Mac, open a resizable Finder window and try left, right, and maximize in sequence. On a second display, repeat with a window on that display.

## Updates and removal

Builds use a local, ad-hoc signature. macOS may ask for Accessibility approval again after an update. If KeyFit appears checked but exits at launch, quit KeyFit in Activity Monitor if it is running, remove the old Accessibility entry with **−**, add the installed app with **+**, enable it, then reopen it.

To uninstall, quit **KeyFit** in Activity Monitor, remove its login item, and move the app to the Trash.

## License

[MIT](LICENSE) © 2026 Rachit Shukla.
