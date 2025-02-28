# Trophy Case

Trophy Case is an app for viewing and sharing your achievements on Playdate.

## Getting started

To build Trophy Case:
1. Install a recent nightly [Swift toolchain](https://www.swift.org/install/macos/). For reference, releases are currently built with *Swift 6.1 Development Snapshot 2025-01-12 (a)*.
2. Clone this repo.
3. Run **swift package pdc** to build and run in the Simulator.

Some features can be enabled by building with the **-DDEBUG** flag set, but the underlying build plugin from PlaydateKit doesn't support customised build settings.

To enable debug builds:
1. Add `"-DDEBUG"` to the unsafe flags array in Package.swift.
2. Clone the [PlaydateKit](https://github.com/finnvoor/PlaydateKit) repo.
3. In the PlaydateKit repo, modify PDCPlugin.swift to add `"-DDEBUG"` to the list of flags passed to Swift.
4. In Trophy Case, modify Package.swift to use your local version of PlaydateKit instead of the remote version.
5. Optionally, prevent PlaydateKit from removing debug symbols by removing the body of the **removeDebugSymbols** function.
