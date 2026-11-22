# History

Older release notes for [Tamed](https://github.com/moody/Tamed). See [CHANGELOG.md](CHANGELOG.md) for the current and most recent release.

## [2.1.0] - 2026-11-21

### Added

- WoW Forever now has its own pet ability and tameable NPC data
- Forever abilities: Dismember, Dust Cloud, Mine!, Pinch, Savage Rend, Sonic Blast, Swipe, Tendon Rip, Trickster's Dance, and Web
- The add-on icon in the main window's title bar

### Changed

- Redesigned the rank screen. Pet level, training cost, and learnable families are shown in tiles, and the NPC list has column labels, the NPC count, and nine NPCs at a time
- Redesigned the Options screen to match, with the Clear Pins button on the `/tamed clear` command row
- Hovering a rank's heading now shows the spell tooltip, replacing the Show Tooltip button
- Learnable families are separated by dots
- The location of an NPC with no map is dimmed, and its tooltip says Map Unavailable
- Scrolling the sidebar with the mouse wheel moves in smaller steps
- The NPC list scrollbar snaps to each entry while it is dragged

### Fixed

- Fixed Tameable NPC cards not highlighting when the mouse moves onto them slowly

## [2.0.1] - 2026-10-05

### Fixed

- Fixed a Lua error when showing NPC tooltips in dungeons on WoW Forever

## [2.0.0] - 2026-10-01

### Changed

- Rebuilt the user interface
- Refactored pet data for maintainability

## [1.15.3] - 2026-07-10

- Version update

## [1.15.2] - 2026-01-17

- Support for Burning Crusade Anniversary

## [1.15.1] - 2025-03-01

- Updated TOC version

## [1.15.0] - 2023-11-28

- Fixes for Classic version 1.15.0

## [2.5.1] - 2021-06-19

- Updated for The Burning Crusade Classic

## [1.13.9] - 2021-04-25

- Added ability info for npcs to "Tameable NPCs" list and map pin tooltips

## [1.13.8] - 2021-04-08

- Replaced `/tamed icon` command with a checkbox in the user interface
- Added an option for NPC tooltips (enabled by default)

## [1.13.7] - 2021-04-06

- Added NPC classifications ('Elite', 'Rare', etc.) to level ranges

## [1.13.6] - 2021-04-06

- Initial release
