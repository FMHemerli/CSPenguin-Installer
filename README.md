> [!IMPORTANT]
> **This is a personal fork.** The original project is [parka6060/CSPenguin-Installer](https://github.com/parka6060/CSPenguin-Installer); use it unless you specifically want the change below. Everything else in this README is the upstream documentation, and its `curl` one-liners install the **upstream** version, without this fork's patch.

## Why this fork exists

DXVK 3.0.1 emulates `IDXGIOutput::WaitForVBlank` by sleeping until the estimated next refresh, then finishing with a busy-wait sized for Windows timers (4x the 1 ms timer granularity plus 1/6 of the refresh interval). CLIP STUDIO PAINT calls it in a loop on a dedicated thread, so with the primary monitor at 144 Hz, CSP burned about 74% of a CPU core while idle (about 40% at 60 Hz). The rate that matters is the primary monitor's, not the one CSP's window is on.

This fork ships a patched DXVK 3.0.1 set in `patches/dxvk-3.0.1/`: a patched `dxgi.dll`, plus `d3d11.dll` and `d3d10core.dll` rebuilt with the same toolchain (they must match, since DXVK passes C++ objects between them). Under Wine, `WaitForVBlank` does a single `NtDelayExecution` instead of the busy-wait, because Wine's sleep is select()-based and precise enough. Windows behaviour is unchanged.

Result: idle CSP went from about 75% of a core to about 0.8% (CSP 5.0 and 5.1.5). Pen response felt better in use, but stroke latency itself was not measured.

To get it, clone **this** repository and run the installer from the clone (or `./install.sh --update` on an existing install):

```bash
git clone https://github.com/FMHemerli/CSPenguin-Installer.git
cd CSPenguin-Installer
./install.sh
```

The installer copies the set into the prefix's `system32` only when DXVK was installed via winetricks, and only after all three DLLs match the SHA-256 hashes pinned in `install.sh`. `./debug.sh` reports whether the patch is active. To rebuild the DLLs, run `patches/dxvk-3.0.1/build.sh` (needs meson, ninja, mingw64-gcc-c++ and glslang; a toolbox works) and update the hashes it prints.

Caveats: this pins D3D11/DXGI to DXVK 3.0.1 even if winetricks installs a newer DXVK (d3d9 and the 32-bit DLLs stay at winetricks' version). Assets the installer downloads still come from the upstream repo, which does not have these DLLs, so running this fork's `install.sh` without a full clone warns and continues without the patch.

---

![CSP running on Linux](assets/Screenshot_20260318_041049.png)

# video tutorial 👇

[![Watch the tutorial](https://img.youtube.com/vi/iYhEm32Lr4Y/maxresdefault.jpg)](https://www.youtube.com/watch?v=iYhEm32Lr4Y)

**CSPenguin-Installer** is an install script and patch set for CLIP STUDIO PAINT. It fixes the **asset store, login panels, file thumbnails, and timelapse/animation export** all while being very easy to install.

The current project is **functional**! Thank you for those who reported issues when testing the script. If you have any issues during install please submit a report under the issues tab of the project.

Supports CSP 4.x & 5.x at the moment.

## Requirements

- A **Vulkan-capable GPU**
- A little bit of patience

Everything else (Wine, Winetricks, GStreamer plugins) is detected and installed automatically by the script.

## Install

One-liner via curl:

```bash
curl -fsSL https://raw.githubusercontent.com/parka6060/CSPenguin-Installer/main/install.sh | bash
```

Or clone the repo via:

```bash
git clone https://github.com/parka6060/CSPenguin-Installer.git
cd CSPenguin-Installer
./install.sh
```

The script downloads CSP and WebView2, sets up a Wine prefix, installs dependencies, applies patches, and creates desktop entries. You'll walk through the CSP installer when it pops up and pick a version (5.0.4 or 4.1.0) You can also bring your own installer via link or file.

## Updating

To refresh your existing installation (reapplies config, patches, and fonts without re-downloading Wine or CSP):

```bash
./install.sh --update
```

Or via curl:

```bash
curl -fsSL https://raw.githubusercontent.com/parka6060/CSPenguin-Installer/main/install.sh | bash -s -- --update
```

This requires Wine and CSP to already be installed.

## Updating Wine

To install or repair the supported bundled Wine runtime without reinstalling CSP:

```bash
./install.sh --update-wine
```

_Note: this installs the exact Wine version tested together with its matching patches. It does not automatically select the latest upstream Wine release._

or

```bash
curl -fsSL https://raw.githubusercontent.com/parka6060/CSPenguin-Installer/main/install.sh | bash -s -- --update-wine
```


## Updating KWin Rules

If you're on KDE and the window rules aren't working properly (subwindows/menus appearing behind CSP), or you're not a fan of the main CSP window being forced underneath everything, you can update the KDE Window rules:

```bash
./kwin-rules.sh
```

This will migrate any old rules previous versions created and apply the current configuration.

## What gets installed

1. Wine (bundled, portable) at `~/.local/share/cspenguin/wine-<VERSION>/`
2. Wine prefix at `~/.wine-csp`
3. Corefonts, vcrun2022, and dotnet48 as runtime dependencies, plus a lightweight CJK font (WenQuanYi Micro Hei) for the asset store and brushes.
4. DXVK + VKD3D, with a patched DXVK 3.0.1 `dxgi`/`d3d11`/`d3d10core` set that stops CSP from busy-waiting a CPU core in `WaitForVBlank` (this fork only, see [Why this fork exists](#why-this-fork-exists))
5. WebView2 Runtime (standalone installer)
6. Wine Gecko (the MSHTML/IE engine) installed into the prefix, so any IE-based UI renders instead of showing a blank/grey page
7. dcomp.dll + libwinpthread-1.dll, a DirectComposition shim + dependency so WebView2 panels render correctly
8. mfplat/mfreadwrite/winegstreamer patches for timelapse/video export
9. `.clip` file thumbnails via a native thumbnailer binary (must be enabled in your file manager — on Dolphin/KDE: _Configure Dolphin → Interface → Previews_ → tick "Clip Studio Paint File", then restart Dolphin)
10. `.clip` file association so double-clicking opens CSP
11. KDE window rules (KDE only) so ribbon bar dropdowns appear on top of CSP instead of behind it. If this doesn't apply properly you can right click your CSP icon in your taskbar or set up window rules yourself!
12. A wineserver pre-warm service so CSP launches a bit faster

> **Note:** `.clip` file thumbnails need to be **enabled in your file manager's preview settings** — on Dolphin/KDE, open _Configure Dolphin → Interface → Previews_ and tick the "Clip Studio Paint File" entry (after running the installer, restart your file manager).

## Running wine/winetricks manually

The bundled Wine is not in your system PATH. To run wine or winetricks against the CSP prefix:

```bash
export PATH="$HOME/.local/share/cspenguin/wine-<VERSION>/bin:$PATH"
export WINEPREFIX="$HOME/.wine-csp"
wine --version
winetricks <package>
```

Find the installed version with `ls ~/.local/share/cspenguin/wine-*/`.

## Known issues

- Timelapse should work 100%, but animation export at non-default framerates could break encoding; not thoroughly tested.
- Wine updates require an exact matching timelapse patch set; newer upstream Wine releases are not selected automatically.
- The installer can take a while, especially if downloading dotnet files.

## Support

Before opening an issue, please search the existing issues and run debug.sh. Include its output along with your distribution, desktop environment, GPU, and what you were doing when the problem occurred.

I (eninabox) maintain this project on a best-effort basis. I'm not actively developing new features or able to investigate every system specific problem, but I'll still help when the answer is clear, review contributions, and update the supported Wine ver when it brings significant improvements to CSP.

There are also some lovely people who have contributed to answering questions and may be able to help when I can't. Pull requests, community-tested fixes, and people helping each other in the issues are always very welcome!

## Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/parka6060/CSPenguin-Installer/main/uninstall.sh | bash
```

Or if you cloned the repo:

```bash
./uninstall.sh
```

---

Brought to you by <https://eninabox.art/>

Maybe I'll go use krita instead...
