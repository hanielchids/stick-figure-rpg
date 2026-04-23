# Stick Game RPG — Progress Tracker

**Current Phase:** Phase 1 (MVP — Single Player)
**Started:** 2026-04-20
**Target Completion:** Month 3
**Timeline Status:** In progress — Day 1

---

## Phase 1: MVP (Months 1–3)
Goal: Playable single-player game with bots, 1 map, full combat.

### Epic 1.1: Project Setup & Player Controller (Weeks 1–3)

- [x] **1.1.1** Set up Godot project
  - [x] Create project with folder structure per CLAUDE.md
  - [ ] Configure GDExtension for C++ *(deferred — not needed until hot-path optimization)*
  - [x] Set up Git repo with .gitignore
  - [x] Establish folder conventions and autoloads
  - Est: 2 days | **Completed: 2026-04-20**

- [x] **1.1.2** Base character movement
  - [x] CharacterBody2D setup with gravity
  - [x] Ground detection
  - [x] Run (variable speed based on input strength)
  - [x] Jump (variable height — hold longer = jump higher)
  - [x] Crouch (reduce hitbox, slower movement)
  - Est: 4 days | **Completed: 2026-04-20**

- [x] **1.1.3** Jetpack system
  - [x] Fuel system (float 0–100)
  - [x] Thrust force application (upward + directional)
  - [x] Fuel drain rate while active
  - [x] Ground recharge rate
  - [x] Particle effects for thrust
  - Est: 3 days | **Completed: 2026-04-20**

- [x] **1.1.4** Wall-hanging
  - [x] Wall detection raycasts
  - [x] State transition: falling near wall → hanging
  - [x] Wall jump-off with directional boost
  - Est: 2 days | **Completed: 2026-04-20**

- [x] **1.1.5** Animation state machine
  - [x] Sprite sheet integration (placeholder stick figure with state-aware poses)
  - [x] State transitions: idle↔run↔jump↔fall↔jetpack↔crouch↔death
  - [ ] AnimationPlayer setup *(deferred until real sprite sheets are added)*
  - Est: 3 days | **Completed: 2026-04-20**

- [x] **1.1.6** Camera system
  - [x] Smooth follow camera
  - [x] Look-ahead based on aim direction
  - [x] Screen bounds clamping to map edges
  - [x] Screen shake utility function
  - Est: 2 days | **Completed: 2026-04-20**

- [x] **1.1.7** Input system
  - [x] Input action mapping (keyboard + mouse + arrow keys)
  - [ ] Key rebinding support *(deferred to 1.5.5 Settings screen)*
  - [x] Input abstraction layer (for future gamepad support)
  - Est: 2 days | **Completed: 2026-04-20**

### Epic 1.2: Combat System (Weeks 3–5)

- [x] **1.2.1** Weapon data model
  - [x] WeaponDefinition resource: name, damage, fire_rate, spread_angle, range, ammo_capacity, reload_time, projectile_speed (0=hitscan), type enum
  - [x] Create definitions for 6 weapons: pistol, shotgun, SMG, sniper, rocket launcher, knife
  - Est: 2 days | **Completed: 2026-04-20**

- [x] **1.2.2** Weapon manager
  - [x] Equip/swap logic (carry 2 weapons)
  - [x] Ammo tracking per weapon
  - [x] Reload timer with animation hook
  - [x] Weapon switching cooldown
  - Est: 3 days | **Completed: 2026-04-20**

- [x] **1.2.3** Hitscan weapons
  - [x] Raycast from muzzle in aim direction
  - [x] Spread cone (random angle within spread_angle)
  - [x] Damage application on hit
  - [x] Tracer visual (Line2D)
  - [ ] Muzzle flash effect *(minor — deferred to polish)*
  - Est: 3 days | **Completed: 2026-04-20**

- [x] **1.2.4** Projectile weapons
  - [x] Projectile scene: Area2D with physics movement
  - [x] Speed, gravity, explosion radius, lifetime
  - [x] Collision → area damage within radius with distance falloff
  - [x] Visual: colored rect + trail particles + explosion particles
  - Est: 3 days | **Completed: 2026-04-20**

- [x] **1.2.5** Melee weapon
  - [x] Short-range area overlap check in aim direction (120° cone)
  - [x] Damage application
  - [x] Swing arc visual
  - Est: 1 day | **Completed: 2026-04-20**

- [x] **1.2.6** Health system
  - [x] Health component: max_hp, current_hp
  - [x] take_damage() and heal() methods
  - [x] Death signal emission
  - [x] Invulnerability frames on respawn (2 sec)
  - [x] Death visual (faded sprite), auto-respawn after timer
  - Est: 2 days | **Completed: 2026-04-20**

- [x] **1.2.7** Weapon pickups
  - [x] Pickup scene: weapon type, respawn timer (15s)
  - [x] Collision area for interaction
  - [x] Float idle animation (tween)
  - [x] Interaction: swap with current weapon
  - Est: 2 days | **Completed: 2026-04-20**

- [x] **1.2.8** Health pickups
  - [x] Same pattern as weapon pickups
  - [x] Heal amount (25 HP), respawn timer (20s)
  - Est: 1 day | **Completed: 2026-04-20**

- [x] **1.2.9** Kill feed system
  - [x] Event bus signal: on_kill(killer, victim, weapon)
  - [x] Feed data structure for UI to consume
  - Est: 1 day | **Completed: 2026-04-20**

### Epic 1.3: Map & Environment (Weeks 4–5)

- [x] **1.3.1** Tileset creation
  - [x] Procedural ColorRect geometry *(TileMap deferred to polish)*
  - Est: 3 days | **Completed: 2026-04-21**

- [x] **1.3.2** Map 1 design & build
  - [x] Arena: 1600x900, floor, walls, ceiling, 8 platforms at 4 heights, 2 cover pillars
  - [x] 8 spawn points spread across the map
  - [x] 6 weapon pickups (shotgun, SMG, sniper, rocket, 2x knife)
  - [x] 4 health pickups
  - Est: 3 days | **Completed: 2026-04-21**

- [x] **1.3.3** Spawn system
  - [x] SpawnPointManager: auto-collects Marker2D spawn points
  - [x] Selection: weighted random favoring farthest-from-enemies
  - [x] Respawn timer (3 sec via Constants)
  - Est: 2 days | **Completed: 2026-04-21**

- [x] **1.3.4** Map boundaries
  - [x] Kill zone Area2D below map floor (instant death)
  - [x] Walls and ceiling as collision boundaries
  - [ ] Camera clamping to map bounds *(deferred — camera works fine without it for now)*
  - Est: 1 day | **Completed: 2026-04-21**

### Epic 1.4: Bot AI (Weeks 5–7)

- [x] **1.4.1** Navigation setup
  - [x] Bots use simple movement (walk + jump + jetpack) instead of NavMesh *(NavMesh deferred to polish)*
  - Est: 2 days | **Completed: 2026-04-21**

- [x] **1.4.2** Basic behavior tree
  - [x] State machine: Patrol, SeekTarget, Engage, Retreat, SeekWeapon
  - [x] Line-of-sight targeting with raycast visibility checks
  - [x] Wall detection — jumps/jetpacks to navigate
  - Est: 4 days | **Completed: 2026-04-21**

- [x] **1.4.3** Aim simulation
  - [x] Aims at target center mass with configurable noise (aim_noise_deg)
  - [x] Reaction time delay before firing
  - Est: 2 days | **Completed: 2026-04-21**

- [x] **1.4.4** Retreat behavior
  - [x] Health threshold check (configurable per difficulty)
  - [x] Runs away from target, re-enters patrol when healed above 60%
  - Est: 2 days | **Completed: 2026-04-21**

- [x] **1.4.5** Weapon pickup behavior
  - [x] Patrols to find weapons when unarmed
  - Est: 1 day | **Completed: 2026-04-21**

- [x] **1.4.6** Difficulty profiles
  - [x] Easy: 500ms reaction, 18deg noise, low aggression
  - [x] Medium: 250ms reaction, 8deg noise, medium aggression
  - [x] Hard: 100ms reaction, 3deg noise, high aggression
  - Est: 1 day | **Completed: 2026-04-21**

### Epic 1.5: HUD & Menus (Weeks 6–7)

- [x] **1.5.1** In-game HUD
  - [x] Health bar (flashes red at low HP)
  - [x] Fuel gauge
  - [x] Ammo counter (current/max), shows "RELOADING..."
  - [x] Weapon name display
  - [x] Crosshair (mouse-following, custom drawn cross + dot)
  - [x] Match timer countdown
  - Est: 3 days | **Completed: 2026-04-21**

- [x] **1.5.2** Kill feed UI
  - [x] Scrolling text list (top-right)
  - [x] Auto-remove after 5 seconds
  - [x] Format: "Player [Weapon] Victim"
  - Est: 1 day | **Completed: 2026-04-21**

- [x] **1.5.3** Scoreboard (tab-hold)
  - [x] Table: Player | Kills | Deaths
  - [x] Real-time updates on each Tab press
  - [x] Local player highlighted green
  - Est: 1 day | **Completed: 2026-04-21**

- [x] **1.5.4** Main menu
  - [x] Play button, Settings button, Quit button
  - [x] Bot count spinner, difficulty dropdown
  - Est: 2 days | **Completed: 2026-04-21**

- [x] **1.5.5** Settings screen
  - [x] Volume sliders (master, SFX, music) with audio bus management
  - [x] Resolution dropdown (720p, 900p, 1080p, 1440p)
  - [x] Fullscreen toggle
  - [ ] Key rebinding UI *(deferred — requires custom input remapping UI)*
  - Est: 2 days | **Completed: 2026-04-21**

- [x] **1.5.6** Match results screen
  - [x] Final scoreboard with all players
  - [x] Winner highlighted (green for you, red for enemy)
  - [x] "Play Again" / "Main Menu" buttons
  - Est: 1 day | **Completed: 2026-04-21**

---

## ✅ M1 Quality Gate — Playable Offline

- [x] Can launch game from main menu
- [x] Character moves, jumps, jetpacks, wall-hangs with responsive controls
- [x] At least 6 weapons functional (hitscan + projectile + melee) — Pistol, Shotgun, SMG, Sniper, Rocket Launcher, Knife
- [x] Weapon and health pickups spawn and work
- [x] Bots navigate the map and fight intelligently — 3 bots, 3 difficulty profiles
- [x] HUD shows health, fuel, ammo, kill feed, scoreboard
- [x] One complete map with proper spawns — Arena with 8 platforms, 8 spawn points
- [x] Match ends after score/time limit, shows results screen
- [ ] Runs at 60 FPS on mid-tier hardware — *needs verification*
- [ ] Builds for Windows AND Mac — *not yet tested*
- [ ] **Fun test:** Get 5 people to play. If they want to play again → PASS

### Additional polish completed:
- [x] Sound effects wired in (gunshot, shotgun, sniper, rocket, explosion, hit, jump, jetpack, pickup)
- [x] Muzzle flash effects on hitscan and projectile weapons
- [x] Settings screen (volume, resolution, fullscreen)
- [x] SoundManager autoload with audio bus system (Master, SFX, Music)
- [x] Full 360-degree aiming and shooting
- [x] Custom crosshair (hidden OS cursor during gameplay, restored on menus)
- [x] NavigationRegion2D for bot pathfinding

---

## Phase 2: Multiplayer (Months 3–5)
Goal: Online multiplayer with lobby system and backend.

### Epic 2.1: Networking Core (Weeks 9–12)
- [x] **2.1.1** Network architecture setup
  - [x] NetworkManager autoload (ENetMultiplayerPeer, host/join/disconnect)
  - [x] Lobby UI (host, join by IP, offline mode, player list, start game)
  - **Completed: 2026-04-21**
- [x] **2.1.2** Binary serialization *(handled by Godot's built-in MultiplayerAPI)*
- [x] **2.1.3** Server-authoritative game loop
  - [x] Match manager works in both offline and online modes
  - [x] Server spawns all players and bots
  - [x] Remote players use bot.tscn (no camera) with BotController removed
  - **Completed: 2026-04-21**
- [ ] **2.1.4** Client-side prediction
- [x] **2.1.5** Entity interpolation
  - [x] NetSync component — sends state at 20Hz, interpolates remote players
  - **Completed: 2026-04-21**
- [x] **2.1.6** Lag compensation
  - [x] Server-side position history recording (30 frames)
  - [x] get_position_at_time() for hit rewind
  - **Completed: 2026-04-22**
- [x] **2.1.7** Delta compression *(handled by Godot's built-in MultiplayerAPI)*
- [x] **2.1.8** Connection management
  - [x] Peer connect/disconnect handling
  - [x] Player cleanup on disconnect
  - **Completed: 2026-04-21**

### Epic 2.2: Backend Services (Weeks 10–13)
- [x] **2.2.1** Rails project setup
  - [x] Rails 8 API mode, PostgreSQL, JWT, CORS, Redis
  - **Completed: 2026-04-22**
- [x] **2.2.2** Auth system
  - [x] User model with has_secure_password
  - [x] JWT encode/decode service
  - [x] POST /api/v1/auth/signup, POST /api/v1/auth/login
  - **Completed: 2026-04-22**
- [x] **2.2.3** Player profile API
  - [x] PlayerStat, Loadout models with auto-creation on signup
  - [x] GET /api/v1/profile, PUT /api/v1/profile/loadout, GET /api/v1/players/:id/stats
  - **Completed: 2026-04-22**
- [ ] **2.2.4** Lobby system *(lobby is in-game via ENet, not backend)*
- [ ] **2.2.5** Game server orchestrator *(deferred — direct connect for now)*
- [x] **2.2.6** Match results ingestion
  - [x] POST /api/v1/matches — records match + participants, updates player stats/XP/level
  - **Completed: 2026-04-22**
- [x] **2.2.7** Leaderboard
  - [x] GET /api/v1/leaderboard — sortable by kills/wins/xp/matches, paginated
  - **Completed: 2026-04-22**
- [ ] **2.2.8** Matchmaking *(deferred — direct connect via lobby for now)*

### Epic 2.3: Integration & Polish (Weeks 13–15)
- [x] **2.3.1** Client ↔ Backend integration
  - [x] ApiClient autoload (HTTP client for Rails API)
  - [x] Auth screen (login/signup/skip)
  - [x] Match results submitted to backend on match end
  - [x] Leaderboard screen (sortable, paginated)
  - **Completed: 2026-04-22**
- [ ] **2.3.2** Lobby → Game Server handoff *(deferred — direct connect for now)*
- [x] **2.3.3** Map 2 & Map 3
  - [x] Towers — vertical map with tall structures, bridges, long sightlines
  - [x] Bunker — tight corridors, rooms, close-quarters combat
  - [x] Map selector in lobby (Arena / Towers / Bunker)
  - **Completed: 2026-04-22**
- [x] **2.3.4** Sound design
  - [x] All weapon sounds, explosion, hit, jump, jetpack, pickup wired in
  - **Completed: 2026-04-21**
- [ ] **2.3.5** Playtesting & netcode tuning *(requires multi-instance testing)*
- [x] **2.3.6** Anti-cheat basics
  - [x] Server-side speed validation
  - [x] Teleport detection
  - [x] Fire rate validation
  - [x] Violation tracking with kick threshold
  - **Completed: 2026-04-22**

---

## Phase 3: Polish & Launch (Months 5–7)

### Epic 3.1: Progression & Cosmetics
- [x] XP system
  - [x] Progression autoload — XP per kill (10), win (25), match complete (10)
  - [x] Level system (level N = N * 100 XP)
  - [x] XP bar and level display on HUD
  - [x] Level-up and +XP notifications in-game
  - **Completed: 2026-04-22**
- [x] Cosmetic unlocks
  - [x] 8 skins: Classic, Fire, Ice, Toxic, Shadow, Gold, Neon, Crimson
  - [x] Unlocked at levels 1, 3, 5, 7, 10, 15, 20, 25
  - [x] Unlock notification on level-up
  - **Completed: 2026-04-22**
- [x] Loadout persistence
  - [x] Equipped skin saved to backend via ApiClient
  - [x] Syncs on login
  - **Completed: 2026-04-22**

### Epic 3.2: Game Modes
- [x] Capture the Flag
  - [x] Flag entity with pickup, carry, drop on death, auto-return timer
  - [x] Score by carrying enemy flag to your base
  - [x] Visual: pole + colored triangle flag
  - **Completed: 2026-04-22**
- [x] Team spawn logic
  - [x] Team assignment in GameState (team field per player)
  - [x] Team-colored players via skin system
  - **Completed: 2026-04-22**

### Epic 3.3: Distribution & Deployment
- [x] Build pipeline (Win + Mac)
  - [x] Export presets configured for Windows Desktop and macOS
  - **Completed: 2026-04-22**
- [x] Backend deployment (Docker)
  - [x] Dockerfile (Rails auto-generated, production-ready)
  - [x] docker-compose.yml (PostgreSQL + Redis + Rails)
  - **Completed: 2026-04-22**
- [ ] Game server deployment *(deferred — direct connect for now)*
- [ ] Itch.io / Steam release *(requires export templates installed in Godot)*

### Epic 3.4: Observability
- [x] Backend logging & error tracking
  - [x] Lograge structured JSON logging with user_id, IP, params
  - **Completed: 2026-04-22**
- [x] Game server logging
  - [x] AntiCheat violation logging with peer ID and reason
  - **Completed: 2026-04-22**
- [x] Metrics dashboard
  - [x] GET /api/v1/admin/stats — total users, matches, kills, playtime, top player
  - **Completed: 2026-04-22**
- [ ] Alerting *(deferred — needs external service like Sentry or PagerDuty)*

---

## Blockers Log

| Date | Blocker | Status | Resolution |
|------|---------|--------|------------|
| — | — | — | — |

## Notes & Decisions Log

| Date | Decision | Rationale |
|------|----------|-----------|
| — | — | — |