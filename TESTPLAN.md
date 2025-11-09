# Cassette Manual Test Plan

This document covers an end-to-end manual regression suite for the Cassette desktop client. Every step maps to at least one debug log message with the `[TEST]` prefix so results can be verified from the terminal (stdout, `journalctl`, or log files).

## Prerequisites

- Build with the default Meson `debug` configuration (or any build that preserves debug symbols).
- Launch the app with full debug logging, e.g.:
  - `G_MESSAGES_DEBUG=all ./build/space.rirusha.Cassette.Devel`
  - Keep the terminal open; all assertions below assume you can tail the log stream.
- Sign in with a test Yandex Music account that has playlists, liked content, and history data.
- Ensure stable network connectivity; cached paths are covered where applicable.
- Optional but recommended: start with an empty cache directory to exercise cache-management flows.

> **Log verification rule:** treat the _Expected Logs_ column as substring matches. All relevant messages begin with `[TEST]`.

---

### 1. Session & Authentication

| Step | Action | Expected UI | Expected Logs |
|------|--------|-------------|---------------|
| A1 | Launch the application. | Splash/auth stack appears. | `[TEST] Application startup complete`, `[TEST] Auth construct: initiating auto login` |
| A2 | Allow automatic login to complete. | Main window loads (or auth form if token missing). | Success path: `[TEST] Auth success`, `[TEST] Auth transitioned to main content`<br>Failure path: `[TEST] Auth failed: ...`, `[TEST] Auth transitioned to login form` |
| A3 | From the hamburger menu choose “Log out”. | Logout dialog appears. | `[TEST] Log out action triggered`, `[TEST] Auth logout dialog opened` |
| A4 | Confirm the logout dialog. | App quits after data wipe. | `[TEST] Auth logout confirmed`, `[TEST] Auth force logout initiated`, `[TEST] Auth user data cleared and application quit` |
| A5 | Relaunch and submit an invalid token. | Error toast (“Failed to login…”) shown. | `[TEST] Auth token submit clicked`, `[TEST] Auth failed: init returned false` |
| A6 | Open the token documentation link. | Browser opens documentation page. | `[TEST] Auth token help link opened` |
| A7 | (If built with WebKit) open Yandex login dialog. | WebView dialog appears. | `[TEST] Auth WebKit dialog opened` |
| A8 | Provide a valid token and authenticate. | Main view displayed; player bar ready. | `[TEST] Auth token submit clicked`, `[TEST] Auth success`, `[TEST] Auth transitioned to main content` |

### 2. Global UI & Navigation

| Step | Action | Expected UI | Expected Logs |
|------|--------|-------------|---------------|
| B1 | Toggle the search button in the header. | Search entry replaces title. | `[TEST] Search toggle changed: active=true` |
| B2 | Type a single letter. | Empty state displayed. | `[TEST] Search entry changed: ...`, `[TEST] SearchView query too short:` |
| B3 | Enter a full query (≥2 chars). | Track results list shows. | `[TEST] SearchView executing query:`, `[TEST] SearchView result count:`, `[TEST] SearchView populated results` |
| B4 | Clear the search field and toggle off. | Return to previous page title. | `[TEST] Search toggle changed: active=false` |
| B5 | Open preferences from the menu. | Preferences dialog opens. | `[TEST] Preferences dialog opened`, `[TEST] Preferences dialog constructed` |
| B6 | Launch the help overlay. | GNOME help overlay shows. | `[TEST] Help overlay opened` |
| B7 | Open the about dialog. | About window appears. | `[TEST] About dialog opened` |
| B8 | Trigger “Show authentication” (developer menu). | Auth stack pushes on top. | `[TEST] Window show_auth invoked`, `[TEST] Auth transitioned to login form` |

### 3. Home View & Discovery

| Step | Action | Expected UI | Expected Logs |
|------|--------|-------------|---------------|
| C1 | Wait for the home page to load after login. | Content sections render. | `[TEST] MainView set_values_async start`, `[TEST] MainView added liked quick access card`, `[TEST] MainView added history quick access card`, `[TEST] MainView show_ready emitted` |
| C2 | Press the “Моя волна” play button. | Player switches to My Wave. | `[TEST] My Wave play button clicked: starting station flow`, `[TEST] PlayerBar mode initialized: mode=...` |
| C3 | Press “Настроить”. | Stations view opens. | `[TEST] My Wave settings button clicked: navigating to StationsView`, `[TEST] PageRoot add_view: view=Cassette.StationsView` |
| C4 | Activate the History quick access card. | Playlist view opens. | `[TEST] History card clicked: playlist=...`, `[TEST] PageRoot add_view: view=Cassette.PlaylistView` |
| C5 | Activate the Liked quick access card. | Playlist view opens (API fetch). | `[TEST] Liked card clicked: uid=...`, `[TEST] PlaylistView construct start: ...` |
| C6 | Switch between Waves tabs. | Carousel updates. | `[TEST] Waves tab toggled: group_id=` |
| C7 | Switch between In-Style tabs. | Carousel updates. | `[TEST] In-style tab toggled: tab_id=` |

### 4. Stations & Search Flows

| Step | Action | Expected UI | Expected Logs |
|------|--------|-------------|---------------|
| D1 | Back from Stations view. | Return to previous stack. | `[TEST] StationsView back button clicked`, `[TEST] PageRoot backward triggered` |
| D2 | Use the Stations search box with a matching query. | Search results list appears. | `[TEST] StationsView search changed: query=...`, `[TEST] StationsView search results visible: count=` |
| D3 | Search for an unknown station. | “No results” pane shown. | `[TEST] StationsView search no results` |
| D4 | Start any station tile. | Station starts playing. | `[TEST] Station card trigger: station_id=` |
| D5 | In the header search box, submit a known track query. | Search results update live. | `[TEST] SearchView update completed` |

### 5. Library Views (Playlists, Albums, Collection)

| Step | Action | Expected UI | Expected Logs |
|------|--------|-------------|---------------|
| E1 | From History playlist, press Back. | Return to previous view. | `[TEST] PlaylistView back button clicked`, `[TEST] PageRoot backward triggered` |
| E2 | Toggle playlist visibility. | Notification toast shown. | `[TEST] PlaylistView visibility toggle clicked`, `[TEST] PlaylistView visibility set to ...` |
| E3 | Press the playlist play button. | Player starts playlist queue. | `[TEST] PlaylistView play button clicked`, `[TEST] PlayerBar mode initialized:` |
| E4 | Start saving a playlist, then abort. | Save progress starts then cancels. | `[TEST] PlaylistView save button clicked`, `[TEST] PlaylistView abort saving clicked` |
| E5 | Delete cached playlist data (delete icon). | Playlist cache cleared. | `[TEST] PlaylistView delete from cache clicked` |
| E6 | Delete a playlist (if allowed). | Playlist removed; navigation pops. | `[TEST] PlaylistView remove button clicked`, `[TEST] PlaylistView delete confirmed`, `[TEST] PlaylistView delete completed` |
| E7 | Open an album from any album tile. | Album view appears. | `[TEST] AlbumMicro clicked: album_id=...`, `[TEST] PageRoot add_view: view=Cassette.AlbumView`, `[TEST] AlbumView set_values applied` |
| E8 | Start album playback. | Player switches to album tracklist. | `[TEST] AlbumView play button clicked`, `[TEST] AlbumView start playing: tracks=` |
| E9 | Open the Collection section (sidebar). | Collection view with sections. | `[TEST] CollectionView load complete`, `[TEST] CollectionView set_values` |
| E10 | Open a liked playlist from Collection. | Playlist view opens. | `[TEST] LikedPlaylistMicro clicked: uid=..., kind=...` |

### 6. Player Controls, Sidebar & Sharing

| Step | Action | Expected UI | Expected Logs |
|------|--------|-------------|---------------|
| F1 | Tap Play/Pause shortcut (space). | Playback toggles. | `[TEST] Play/Pause action toggled` |
| F2 | Tap Next/Previous (Alt+→ / Alt+←). | Player moves to adjacent tracks. | `[TEST] Next track action triggered`, `[TEST] Previous track action triggered` |
| F3 | Toggle Shuffle/Repeat from player bar. | Buttons reflect new mode. | `[TEST] Shuffle action triggered`, `[TEST] PlayerBar shuffle mode: ...`, `[TEST] Repeat action triggered`, `[TEST] PlayerBar repeat mode: ...` |
| F4 | Open queue sidebar. | Sidebar displays queue. | `[TEST] PlayerBar queue panel requested`, `[TEST] Sidebar showing queue` |
| F5 | Close queue sidebar. | Sidebar hidden. | `[TEST] PlayerBar queue panel toggled off`, `[TEST] Sidebar close invoked` |
| F6 | Open track details sidebar. | Track info appears. | `[TEST] PlayerBar track details requested`, `[TEST] Sidebar showing track info:` |
| F7 | Toggle wave settings (during My Wave playback). | Wave panel opens/closes. | `[TEST] PlayerBar wave settings requested`, `[TEST] Sidebar showing wave settings` |
| F8 | Drag the playback slider. | Seek to new position. | `[TEST] PlayerBar slider moved: value=` |
| F9 | Adjust volume via button popover. | Volume/mute updates. | `[TEST] VolumeButton scale change:`, `[TEST] VolumeButton volume setter:` |
| F10 | Toggle mute (`Ctrl+M` or button). | Mute icon changes. | `[TEST] Mute action toggled: mute=` or `[TEST] VolumeButton mute toggled:` |
| F11 | Trigger “Share current track”. | Success toast (if non-UGC). | `[TEST] Share current track action triggered:` _or_ `[TEST] Share current track action blocked: current track is UGC` |
| F12 | Parse clipboard URL via shortcut (`Ctrl+Shift+V`). | Album/playlist opens. | `[TEST] Parse URL action triggered`, follow-up lines for success or failures |

### 7. Preferences & Cache Management

| Step | Action | Expected UI | Expected Logs |
|------|--------|-------------|---------------|
| G1 | Toggle “Show save stack”. | Sub-switch enabled/disabled. | `[TEST] Preferences toggle: show_save_stack=` |
| G2 | Toggle “Use HQ audio”. | HQ indicator updates. | `[TEST] Preferences toggle: HQ switch changed`, `[TEST] Preferences toggle: HQ enabled/disabled` |
| G3 | Disable caching (confirm deletion). | Cache cleared. | `[TEST] Preferences toggle: can_cache enabled/disabled`, `[TEST] Preferences cache deletion dialog opened`, `[TEST] Preferences cache deletion confirmed` |
| G4 | Re-enable caching. | Switch remains on. | `[TEST] Preferences toggle: can_cache enabled` |
| G5 | Open Cache Deletion section, refresh sizes. | Sizes populate. | `[TEST] CacheDeletionPreferences update_data triggered`, `[TEST] CacheDeletionPreferences temp size loaded` |
| G6 | Delete temporary cache. | Progress dialog then size refresh. | `[TEST] CacheDeletionPreferences temp delete button clicked`, `[TEST] CacheDeletionPreferences deletion confirmed: is_tmp=true`, `[TEST] CacheDeletionPreferences temp cache deleted` |
| G7 | Move saved content to cache. | Progress dialog then refresh. | `[TEST] CacheDeletionPreferences perm delete button clicked`, `[TEST] CacheDeletionPreferences deletion confirmed: is_tmp=false`, `[TEST] CacheDeletionPreferences saved content moved` |

### 8. External Links & Account Shortcuts

| Step | Action | Expected UI | Expected Logs |
|------|--------|-------------|---------------|
| H1 | Trigger “Open account” action. | Default browser opens id.yandex.ru. | `[TEST] Open account action triggered` |
| H2 | Trigger “Open Plus” action. | Browser opens plus.yandex.ru. | `[TEST] Open plus action triggered` |
| H3 | Trigger “Get Plus” action. | Browser opens plus subscription page. | `[TEST] Get plus action triggered` |

---

## Postconditions

- Leave Cassette running for exploratory tests unless a scenario explicitly quits the app.
- Capture screenshots or screen recordings alongside the log excerpts for defect reports.
- Reset the test account (logout, clear cache) if additional suites will run afterwards.*** End Patch
*** Begin Patch
*** Add File: /home/dmitriy/sources/Cassette/TESTPLAN.md
# Cassette Manual Test Plan

This plan verifies that the main view populates and that the History playlist opens using the preloaded data path. Run the application in debug mode so every `[TEST]` log appears on stdout.

## Prerequisites
- Environment variable `G_MESSAGES_DEBUG=all` exported for the session.
- Application launched from the project root with `make run` (or `meson compile ...` + `src/cassette`) so logs are visible in the terminal.

## Test Steps
1. **Launch Cassette**  
   Command: `G_MESSAGES_DEBUG=all make run`  
   _Expected log:_ `[TEST] Application startup complete`

2. **Wait for main view population**  
   Observe the loading spinner until logs show the fetch cycle.  
   _Expected logs:_
   - `[TEST] MainView set_values_async start`
   - `[TEST] MainView added liked quick access card: tracks=...`
   - `[TEST] MainView added history quick access card: title=...`
   - `[TEST] MainView show_ready emitted`

3. **Open the History playlist**  
   Click the “History” quick access card.  
   _Expected log:_ `[TEST] History card clicked: playlist=...`

4. **Verify playlist view loads from preloaded data**  
   After the view transition, confirm the playlist contents render.  
   _Expected logs:_
   - `[TEST] PlaylistView.with_playlist constructed: title=...`
   - `[TEST] PlaylistView initial playlist applied: uid=...`

5. **(Optional) Verify fallback path**  
   Trigger a playlist view using the regular constructor (e.g., open “Liked”).  
   _Expected log:_ `[TEST] PlaylistView first_show without preload`

Record any deviations from the expected log messages or UI behaviour.
*** End Patch
