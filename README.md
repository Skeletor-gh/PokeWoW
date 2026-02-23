# PokeWoW
A World of Warcraft addon focused on QoL and UX for Pet Battles. Gotta catch'em all!

## Latest Patch Notes
- Initial addon scaffolding (TOC + core + options).
- Added a welcome options pane and dedicated sub-options pane for Pet Battle Music.
- Added Pet Battle music replacement with modes: no music, single track loop, sequential, and random.
- Added configurable user playlist declaration in `MusicTracks.lua`.
- Added BattleFrames integration and a dedicated BattleFrames sub-panel in options.
- Added a set of soundtracks for the player's enjoyment.

## Default Setup & Usage
1. Install the addon in your WoW addons folder:
   - `_retail_/Interface/AddOns/PokeWoW`
2. Make sure these files/folders are present:
   - `PokeWoW.toc`
   - `PokeWoW.lua`
   - `Options.lua`
   - `MusicTracks.lua`
   - `Tracks/`
3. Launch WoW and enable **PokeWoW** from the AddOns menu at character select.
4. In-game, open **Settings → AddOns → PokeWoW** and choose a sub-panel (**Pet Battle Music** or **BattleFrames**).
5. Pick a music mode:
   - **No Music**: disables pet battle background music replacement.
   - **Single Track Loop**: repeats one selected track.
   - **Sequential**: plays your playlist in order.
   - **Random**: chooses a random track each cycle.
6. (Optional) Customize your playlist in `MusicTracks.lua`:
   - Add a `name`, file `path`, and `length` (seconds) for each track.
   - Keep all music files inside `PokeWoW/Tracks/`.

## Included Soundtracks
PokeWoW comes with a set of pre-built soundtracks. 
