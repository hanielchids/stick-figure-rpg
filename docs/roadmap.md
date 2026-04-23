# Game Development Roadmap — System Design & Execution Plan

**Author:** Staff PM / Technical Architect
**Date:** April 20, 2026
**Status:** Planning — Pre-Development
**Audience:** VP Engineering / Solo Developer Execution Guide

---

## Executive Summary

This document defines the product vision, system architecture, agent-based team structure, execution plan, data design, scaling strategy, and risk analysis for three progressively complex game projects:

| # | Project | Genre | Complexity | Estimated Duration |
|---|---------|-------|------------|-------------------|
| 1 | **Stick Game RPG** (Mini Militia clone) | 2D multiplayer side-scroller shooter | Medium | 5–7 months |
| 2 | **IronSight** (COD-like FPS) | 3D first-person shooter | High | 12–18 months |
| 3 | **Dominion** (Age of Empires-like RTS) | Real-time strategy | Very High | 18–24 months |

Each project is designed to build on skills and infrastructure from the previous one. By the end of Project 3, the developer will have shipped three games across two engines, built real-time multiplayer infrastructure, and developed competence across 2D, 3D, networking, AI, and large-scale game systems.

---

# PROJECT 1: STICKWARS (Mini Militia Clone)

---

## Step 1: Product Definition

### 1.1 Product Vision

A fast-paced 2D side-scrolling multiplayer shooter with jetpack-based movement, multiple weapon types, and online multiplayer. Desktop-first (Windows + Mac), with a visual style inspired by Mini Militia's stick-figure aesthetic. The game prioritizes tight controls, responsive netcode, and addictive pickup-and-play gameplay.

### 1.2 Target Users

- Casual gamers who enjoy quick matches (3–5 minutes)
- Players who enjoyed Mini Militia on mobile and want a desktop experience
- Friends looking for a lightweight LAN/online party game

### 1.3 Core Use Cases

| ID | Use Case | Priority |
|----|----------|----------|
| UC-1 | Player launches game, enters quick match against bots | P0 |
| UC-2 | Player hosts a lobby, friends join via code/LAN | P0 |
| UC-3 | Player customizes loadout (weapon preference, skin) | P1 |
| UC-4 | Player plays online matchmade game (ranked/unranked) | P1 |
| UC-5 | Player views stats/leaderboard after match | P2 |
| UC-6 | Player unlocks cosmetics through progression | P2 |

### 1.4 Functional Requirements

- **FR-1:** 2D character movement — run, jump, crouch, prone, wall-hang
- **FR-2:** Jetpack system with fuel gauge, recharge on ground
- **FR-3:** Dual-stick aiming (keyboard+mouse: WASD + mouse aim)
- **FR-4:** Weapon system: minimum 6 weapons (pistol, shotgun, SMG, sniper, rocket launcher, melee)
- **FR-5:** Weapon pickups scattered across map
- **FR-6:** Health system with health pickups
- **FR-7:** Respawn system with configurable respawn timer
- **FR-8:** Map system: minimum 3 maps with destructible elements (optional P2)
- **FR-9:** Game modes: Deathmatch, Team Deathmatch
- **FR-10:** Bot AI for solo/practice play
- **FR-11:** Lobby system: create room, share code, join room
- **FR-12:** Real-time multiplayer: 2–8 players per match
- **FR-13:** Chat system (text, pre-match and post-match)
- **FR-14:** Kill feed and scoreboard

### 1.5 Non-Functional Requirements

| Requirement | Target | Rationale |
|-------------|--------|-----------|
| Frame rate | 60 FPS stable on mid-tier hardware | Shooter gameplay demands responsiveness |
| Input latency | < 16ms (1 frame) | Tight controls are core to the experience |
| Network tick rate | 20–30 Hz client, 30–60 Hz server | Balance between responsiveness and bandwidth |
| Network latency tolerance | Playable up to 150ms RTT | Covers most domestic connections |
| Match start time | < 10 seconds from "Play" to gameplay | Respect player time |
| Binary size | < 200 MB | Lightweight game should feel lightweight |
| Supported platforms | Windows 10+, macOS 12+ | Desktop first |
| Concurrent players per server | 8 per match instance | Scope constraint |

---

## Step 2: System Design (High-Level)

### 2.1 Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        GAME CLIENT (Godot 4)                    │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────────────┐   │
│  │ Renderer │ │ Physics  │ │  Input   │ │  Network Client  │   │
│  │ (2D)     │ │ Engine   │ │ Handler  │ │  (ENet/WebSocket)│   │
│  └────┬─────┘ └────┬─────┘ └────┬─────┘ └────────┬─────────┘   │
│       └─────────────┴────────────┴────────────────┘             │
│                           │                                     │
│                    Game State Manager                           │
│                           │                                     │
│       ┌───────────────────┼───────────────────┐                 │
│       │                   │                   │                 │
│  ┌────┴─────┐  ┌──────────┴──┐  ┌─────────────┴──┐             │
│  │ Player   │  │   Weapon    │  │    UI/HUD      │             │
│  │ Controller│  │   System    │  │    System      │             │
│  └──────────┘  └─────────────┘  └────────────────┘             │
└─────────────────────────┬───────────────────────────────────────┘
                          │ UDP (ENet) / WebSocket
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│                  DEDICATED GAME SERVER (Godot headless)          │
│  ┌──────────────┐ ┌──────────────┐ ┌────────────────────────┐   │
│  │ Authoritative│ │   Physics    │ │  Anti-Cheat (basic)    │   │
│  │ Game State   │ │  Simulation  │ │  Input Validation      │   │
│  └──────┬───────┘ └──────┬───────┘ └────────────┬───────────┘   │
│         └────────────────┼──────────────────────┘               │
│                    Match Manager                                │
│         ┌────────────────┼──────────────────────┐               │
│         │                │                      │               │
│  ┌──────┴──────┐ ┌───────┴──────┐ ┌─────────────┴────┐         │
│  │  Spawn      │ │   Weapon     │ │   Score/Kill     │         │
│  │  System     │ │   Pickup Mgr │ │   Tracker        │         │
│  └─────────────┘ └──────────────┘ └──────────────────┘         │
└─────────────────────────┬───────────────────────────────────────┘
                          │ REST / WebSocket
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│                    BACKEND SERVICES (Ruby on Rails)              │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────────────┐   │
│  │ Auth     │ │ Lobby /  │ │ Player   │ │  Leaderboard /   │   │
│  │ Service  │ │ Matchmake│ │ Profile  │ │  Analytics       │   │
│  └──────────┘ └──────────┘ └──────────┘ └──────────────────┘   │
│                          │                                      │
│                    PostgreSQL + Redis                            │
└─────────────────────────────────────────────────────────────────┘
```

### 2.2 Major Services

| Service | Responsibility | Technology | Why |
|---------|---------------|------------|-----|
| **Game Client** | Rendering, input, prediction, interpolation | Godot 4 (GDScript + C++ via GDExtension) | Best 2D engine, free, cross-platform, C++ support |
| **Dedicated Game Server** | Authoritative simulation, state broadcast | Godot 4 headless | Same codebase as client, reduces duplication |
| **Auth Service** | Account creation, login, session tokens | Rails API + Devise/JWT | Leverages existing Rails skill |
| **Lobby Service** | Room creation, join codes, matchmaking queue | Rails API + Redis pub/sub + ActionCable | Real-time lobby state via WebSocket |
| **Player Profile Service** | Stats, loadout, progression, cosmetics | Rails API + PostgreSQL | CRUD-heavy, Rails excels here |
| **Leaderboard Service** | Rankings, match history | Rails API + Redis sorted sets | Redis sorted sets are purpose-built for leaderboards |

### 2.3 Data Flow

```
[Player Input] → Client predicts locally → Sends input to Server
     ↓
[Server] validates input → Steps physics → Broadcasts authoritative state
     ↓
[Client] receives state → Reconciles with prediction → Renders interpolated frame
     ↓
[Match End] → Server sends match results to Backend API
     ↓
[Backend] updates player stats, ELO, leaderboard → Stores in PostgreSQL/Redis
```

### 2.4 Networking Model Decision

| Option | Pros | Cons | Decision |
|--------|------|------|----------|
| Peer-to-peer | Simple, no server cost | Cheating, NAT traversal hell, host advantage | ❌ Rejected |
| Client-authoritative | Easy to implement | Trivially cheatable | ❌ Rejected |
| **Server-authoritative with client prediction** | Anti-cheat, fair, industry standard | More complex, requires server hosting | ✅ Selected |

**Reasoning:** For a shooter, fairness is non-negotiable. Client-side prediction with server reconciliation (the Quake/Source model) provides responsive controls while keeping the server as the source of truth. This is more work upfront but saves massive pain later.

### 2.5 External Dependencies

| Dependency | Purpose | Risk Mitigation |
|------------|---------|-----------------|
| Godot Engine 4.x | Game engine | Open source, self-hostable, no vendor lock-in |
| PostgreSQL | Persistent data | Industry standard, well-understood |
| Redis | Session cache, leaderboards, pub/sub | Can be replaced with Valkey if needed |
| ENet (UDP library) | Game networking | Bundled with Godot, battle-tested |
| Steam SDK (optional P2) | Distribution, auth, matchmaking | Wrap behind interface for portability |
| Hetzner / DigitalOcean | Game server hosting | Commodity, easily switchable |

### 2.6 Why Rails + C++ Hybrid (Not Full C++)

This is a deliberate architectural decision, not a compromise. The system has two fundamentally different workloads:

**Real-time game simulation (C++ / GDScript):**
- Physics stepping at 60Hz
- Binary packet serialization every frame
- Lag compensation requiring world-state rewind
- Hit detection with microsecond-level precision
- This MUST be fast. C++ (via GDExtension) handles the hot paths.

**Out-of-game services (Ruby on Rails):**
- User signup/login (a POST request that happens once per session)
- Saving a loadout (a PUT request that happens a few times per day)
- Leaderboard queries (a GET request with Redis sorted sets)
- Lobby management (CRUD + WebSocket push)
- Match result recording (one POST per match)

These are classic web application patterns — request/response, database CRUD, background jobs. Writing an auth system or leaderboard API in raw C++ would take 5–10x longer than Rails, produce more bugs, and gain zero meaningful performance benefit. A Rails endpoint responding in 20ms vs. a C++ endpoint responding in 2ms is irrelevant when the human doesn't notice the difference.

**The industry does this too:**

| Company | Game Engine | Backend |
|---------|------------|---------|
| Riot Games (LoL) | Custom C++ | Java microservices |
| Supercell (Clash Royale) | Custom C++ | Java / Go services |
| Epic Games (Fortnite) | Unreal C++ | Go, Java, various web services |
| Most indie studios | Unity/Godot/Unreal | Node.js, Python, Rails, or Go |

**When to replace Rails with something else:**
- If matchmaking needs to handle >10K queue operations/sec → rewrite matchmaking worker in Go or Rust
- If WebSocket connections exceed ~50K concurrent → swap ActionCable for AnyCable (Go) or a dedicated Elixir service
- If API latency becomes a bottleneck at scale → unlikely for this use case, but Go is the natural next step

**Bottom line:** Use C++ where milliseconds matter (game simulation). Use Rails where developer productivity matters (everything else). You'll ship months faster.

### 2.7 Local Play: LAN & Bluetooth

Mini Militia's iconic Bluetooth/WiFi local play is a must-have feature. Here's how each mode works:

#### WiFi LAN Play (P0 — Phase 2)

This is straightforward and highly recommended as the primary local play method, especially for desktop:

```
Player A (Host)                    Player B (Client)
┌──────────────┐                   ┌──────────────┐
│ Game Client  │                   │ Game Client  │
│ + Embedded   │◄── Same WiFi ───►│              │
│   Game Server│    UDP (ENet)     │              │
└──────────────┘                   └──────────────┘
```

- Host player starts a game server on their machine (embedded, no separate process needed)
- Server broadcasts its presence via UDP broadcast on the LAN
- Other players on the same network see the game in a "Local Games" browser
- Connection is direct — no internet required, no backend needed
- Latency is sub-5ms on LAN, so prediction/interpolation feel instant
- Implementation: Godot's built-in `UDPServer` for discovery + ENet for game traffic

#### Bluetooth Play (P2 — Post-launch, mobile port)

Bluetooth is relevant if/when you port to mobile (Android/iOS). For desktop it's unusual — players on desktops are almost always on the same WiFi network.

**Technical reality of Bluetooth for games:**

| Factor | Assessment |
|--------|-----------|
| Bandwidth | Bluetooth Classic: ~2 Mbps theoretical, ~200 KB/s practical. Sufficient for a 2D game. |
| Latency | 20–50ms typical. Acceptable for casual play, noticeable for competitive. |
| Range | ~10 meters. Fine for same-room play. |
| Godot support | Not native. Requires a plugin: `GodotBLE` (Rust-based GDExtension) for BLE, or `GodotBluetooth` for classic Bluetooth (Android only). |
| Platform | Android only (practical). macOS/Windows Bluetooth stacks are inconsistent for game networking. |
| Complexity | High. Pairing, connection management, platform-specific code. |

**Recommendation:** Implement WiFi LAN play first (works on desktop AND mobile). Add Bluetooth as an optional mobile-only feature post-launch. The networking layer is the same — only the transport changes. Design the `NetworkTransport` interface so you can swap ENet (WiFi) for Bluetooth without touching game logic:

```
NetworkTransport (interface)
├── ENetTransport        # WiFi / Internet — default
├── BluetoothTransport   # Mobile local play — plugin-based
└── WebSocketTransport   # Future: browser port
```

#### Local Play Implementation Timeline

| Feature | Phase | Platform | Priority |
|---------|-------|----------|----------|
| LAN discovery + local server | Phase 2 (Month 4) | Desktop + Mobile | P0 |
| Same-device split-screen (2 players) | Phase 3 (Month 6) | Desktop | P1 |
| Bluetooth Classic | Post-launch | Android only | P2 |

---

## Step 3: Agent-Based Team Structure

Since this is a solo developer project, "agents" represent independently developed and deployable vertical slices. Each agent has a clear boundary so work can be done in focused sprints without context-switching across the entire system.

---

### Agent 1: Player Controller Agent

**Mission:** Own everything about how a player exists and moves in the game world.

**Responsibilities:**
- Character movement (run, jump, crouch, prone, wall-hang)
- Jetpack physics (thrust, fuel consumption, fuel recharge)
- Animation state machine (idle, run, jump, fall, jetpack, death)
- Camera system (follow cam, screen shake)
- Player input mapping and rebinding
- Client-side prediction and server reconciliation for movement

**Inputs:**
- Raw input events (keyboard, mouse)
- Server authoritative position corrections
- Map collision data

**Outputs:**
- Player position, velocity, animation state (sent to server at tick rate)
- Visual representation on screen

**Internal Components:**
- `CharacterBody2D` — Godot physics body
- `PlayerStateMachine` — states: Idle, Running, Jumping, Falling, Jetpacking, WallHanging, Crouching, Dead
- `JetpackSystem` — fuel float, thrust vector, recharge timer
- `InputBuffer` — stores last N inputs for replay during reconciliation
- `PredictionSystem` — applies inputs locally, rewinds on server correction

**Tech Stack:** GDScript for state machine, C++ (GDExtension) for prediction/reconciliation hot path

**Failure Modes:**
- Desync between client prediction and server state → Rubber-banding. Mitigation: smooth correction interpolation, tolerance threshold before snap.
- Input loss over network → Input buffer with redundant sending (send last 3 inputs each packet)

**Key Metrics:**
- Prediction error rate (how often server corrects client)
- Average correction magnitude (how far off predictions are)
- Input-to-render latency

---

### Agent 2: Combat System Agent

**Mission:** Own all weapon behavior, damage, projectiles, hit detection, and health.

**Responsibilities:**
- Weapon definitions (damage, fire rate, spread, range, ammo, reload time)
- Hitscan weapons (pistol, SMG, sniper) — raycasting
- Projectile weapons (rocket launcher) — physics-based projectiles
- Melee weapons — short-range area check
- Weapon pickup spawning and cooldown
- Health system, damage application, death, respawn trigger
- Hit registration (server-authoritative with lag compensation)
- Kill feed events

**Inputs:**
- Fire input from Player Controller Agent
- Player positions from Game State (for hit detection)
- Weapon pickup collision events

**Outputs:**
- Damage events → Game State
- Kill/death events → Score Tracker
- Weapon state (current weapon, ammo, reload progress) → HUD
- Visual effects triggers (muzzle flash, hit markers, explosions) → Renderer

**Internal Components:**

```
CombatSystem/
├── WeaponManager          # Manages equipped + inventory weapons
│   ├── WeaponDefinition   # Data class: damage, fire_rate, spread, etc.
│   ├── HitscanResolver    # Raycasts with lag compensation
│   └── ProjectileSpawner  # For rockets/grenades
├── DamageProcessor        # Applies damage, checks armor, triggers death
├── HealthSystem           # HP, regen rules, pickup healing
├── WeaponPickupManager    # Spawns pickups on map, handles cooldowns
└── LagCompensator         # Server-side: rewinds world state to shooter's POV time
```

**Tech Stack:** C++ (GDExtension) for hit detection and lag compensation (performance critical). GDScript for weapon definitions and pickup logic.

**Failure Modes:**
- Hit registration disagreement (client saw a hit, server disagrees) → Lag compensation with server-side rewind up to 150ms. Beyond that, server wins.
- Weapon balance issues → Data-driven weapon definitions in JSON/resource files. Tunable without code changes.

**Key Metrics:**
- Hit registration accuracy (client-perceived vs server-confirmed)
- Average time-to-kill per weapon
- Weapon pick rates (balance indicator)

---

### Agent 3: Networking & Multiplayer Agent

**Mission:** Own all real-time game networking — serialization, transport, state sync, lobby connectivity.

**Responsibilities:**
- Network transport layer (ENet UDP)
- Packet serialization/deserialization
- State synchronization (server → client snapshot broadcasting)
- Client-side interpolation (rendering between received snapshots)
- Client-side prediction integration (coordinating with Player Controller Agent)
- Connection management (connect, disconnect, reconnect, timeout)
- Bandwidth optimization (delta compression, interest management)
- Lobby-to-game-server handoff

**Inputs:**
- Player inputs from all clients
- Authoritative game state from server simulation

**Outputs:**
- Serialized state snapshots to all clients
- Input packets to server
- Connection status events (player joined, player left, player timed out)

**Internal Components:**

```
Networking/
├── NetworkManager         # Top-level: manages connections, routes packets
├── PacketSerializer       # Binary serialization (not JSON — bandwidth matters)
│   ├── InputPacket        # Player inputs + sequence number + timestamp
│   ├── SnapshotPacket     # Full world state (positions, healths, weapons)
│   └── DeltaPacket        # Only changed state since last ack'd snapshot
├── InterpolationBuffer    # Buffers 2-3 snapshots, renders between them
├── ClientPrediction       # Coordinates with Player Controller for reconciliation
├── ConnectionHandler      # Heartbeat, timeout detection, reconnect logic
└── BandwidthMonitor       # Tracks bytes/sec, triggers quality adjustments
```

**Tech Stack:** C++ (GDExtension) for serialization and interpolation (called every frame, must be fast). ENet for transport.

**Failure Modes:**
- Packet loss → ENet provides reliable and unreliable channels. Movement uses unreliable (latest-wins). Critical events (kills, pickups) use reliable.
- High latency → Interpolation buffer absorbs jitter. Client prediction masks latency for the local player. Visual smoothing for remote players.
- Server crash mid-match → Match is lost. Mitigation: short matches (3–5 min) reduce impact. Future: snapshot-based recovery.

**Key Metrics:**
- Packets per second (in/out)
- Bandwidth per player (target: < 10 KB/s)
- Interpolation buffer health (underruns = stutter)
- Packet loss rate
- Round-trip time per player

---

### Agent 4: Map & Environment Agent

**Mission:** Own map loading, tile/level design tooling, weapon spawn points, player spawn points, and environmental physics.

**Responsibilities:**
- Map data format definition and loading
- Tilemap rendering (Godot TileMap)
- Collision geometry
- Spawn point placement (players, weapons, health pickups)
- Map selection and rotation logic
- Parallax backgrounds and visual layers
- Future: destructible terrain (P2)

**Internal Components:**

```
MapSystem/
├── MapLoader              # Loads .tscn map files
├── SpawnPointManager      # Tracks and assigns spawn points (avoids spawn-camping)
├── PickupSpawner          # Places weapon/health pickups, manages respawn timers
├── MapRotation            # Cycles maps between matches
└── MapMetadata            # Name, thumbnail, player count range, game modes supported
```

**Tech Stack:** GDScript. Maps authored in Godot editor using TileMap nodes.

**Failure Modes:**
- Spawn camping → Spawn point selection algorithm: weighted random favoring points farthest from enemies.
- Map exploits (out-of-bounds) → Collision boundary validation. Killzone below map floor.

---

### Agent 5: AI / Bot Agent

**Mission:** Own bot behavior for single-player and filling multiplayer lobbies.

**Responsibilities:**
- Bot decision-making (movement, aiming, weapon selection, engaging/retreating)
- Difficulty levels (Easy, Medium, Hard) via tunable parameters
- Pathfinding (navigation mesh or graph-based for 2D)
- Target selection logic
- Bot identity (names, skins) for immersion

**Internal Components:**

```
BotAI/
├── BehaviorTree           # Root decision tree for bot actions
│   ├── SeekTarget         # Find nearest enemy
│   ├── EngageTarget       # Move toward, aim, fire
│   ├── Retreat            # Low health → flee, find health pickup
│   ├── PickupWeapon       # Evaluate nearby weapon pickups
│   └── Patrol             # No target → roam spawn/pickup areas
├── AimSimulator           # Simulates human-like aiming (reaction time, accuracy noise)
├── DifficultyProfile      # Easy: 500ms reaction, 40% accuracy. Hard: 100ms, 85%
└── NavigationAgent        # A* or NavMesh-based pathfinding on 2D map
```

**Tech Stack:** GDScript for behavior trees, C++ for pathfinding if performance requires.

**Failure Modes:**
- Bots stuck on geometry → Navigation mesh baking must cover all walkable surfaces. Stuck detection timer → teleport to nearest spawn.
- Bots feel robotic → Aim noise, variable reaction times, occasional "mistakes" to feel human.

---

### Agent 6: Backend Services Agent

**Mission:** Own all persistent data, authentication, matchmaking, and out-of-game systems.

**Responsibilities:**
- User authentication (signup, login, JWT sessions)
- Player profiles (stats, loadout, cosmetics)
- Lobby management (create room, join room via code, room listing)
- Matchmaking queue (simple ELO-based for ranked)
- Leaderboard (global, weekly, friends)
- Match history recording
- Game server orchestration (spawn/kill server instances)

**Internal Components:**

```
Backend (Rails API)/
├── AuthController         # POST /auth/signup, POST /auth/login, POST /auth/refresh
├── ProfileController      # GET/PUT /profile, GET /profile/:id/stats
├── LobbyController        # POST /lobbies, GET /lobbies/:code, POST /lobbies/:code/join
│   └── LobbyChannel       # ActionCable WebSocket for real-time lobby state
├── MatchmakingWorker      # Sidekiq job: polls queue, pairs players by ELO ± range
├── MatchResultsController # POST /matches (server reports results)
├── LeaderboardController  # GET /leaderboard?scope=global|weekly|friends
├── ServerOrchestrator     # Spins up Godot headless instances, assigns ports
│   └── HealthChecker      # Monitors game server processes, restarts on crash
└── AdminController        # Ban player, view metrics, adjust weapon balance configs
```

**Tech Stack:**
- Ruby on Rails 7 (API mode)
- PostgreSQL (persistent data)
- Redis (sessions, leaderboard sorted sets, lobby pub/sub, Sidekiq queue)
- Sidekiq (background jobs: matchmaking, cleanup)
- ActionCable (WebSocket for lobby real-time updates)
- Docker (containerized deployment)

**APIs:**

```
Authentication:
  POST   /api/v1/auth/signup          { email, username, password }           → { token, user }
  POST   /api/v1/auth/login           { email, password }                    → { token, user }
  POST   /api/v1/auth/refresh         { refresh_token }                      → { token }

Profile:
  GET    /api/v1/profile                                                     → { user, stats, loadout }
  PUT    /api/v1/profile/loadout      { preferred_weapon, skin_id }          → { loadout }
  GET    /api/v1/players/:id/stats                                           → { kills, deaths, wins, kd_ratio }

Lobby:
  POST   /api/v1/lobbies              { map, mode, max_players }             → { lobby_id, code }
  GET    /api/v1/lobbies/:code                                               → { lobby state, players }
  POST   /api/v1/lobbies/:code/join                                          → { lobby state }
  DELETE /api/v1/lobbies/:code/leave                                         → { }
  WS     /cable → LobbyChannel        subscribe(code)                       → streams lobby updates

Matchmaking:
  POST   /api/v1/matchmaking/queue    { mode, region }                       → { queue_id }
  DELETE /api/v1/matchmaking/queue                                           → { }
  WS     /cable → MatchmakingChannel   subscribe(queue_id)                  → match_found event

Match Results (server-to-server):
  POST   /api/v1/matches              { server_key, players[], scores, duration } → { match_id }

Leaderboard:
  GET    /api/v1/leaderboard          ?scope=global&period=weekly&page=1     → { rankings[] }

Server Orchestration (internal):
  POST   /api/v1/servers/spawn        { map, mode, lobby_id }               → { server_ip, port }
  POST   /api/v1/servers/:id/heartbeat                                       → { }
```

**Failure Modes:**
- Auth token expiry mid-match → Game server validates tokens at connect time only. Match continues regardless. Re-auth on next API call.
- Matchmaking starvation (not enough players) → Timeout after 30s, offer bot backfill. Widen ELO range over time.
- Game server crash → Health checker detects within 10s, logs match as "abandoned," no stats recorded. Players returned to lobby.
- Database overload → Read replicas for leaderboard/stats queries. Write-through cache for hot data.

**Key Metrics:**
- API response times (p50, p95, p99)
- Matchmaking queue time
- Active concurrent lobbies
- Server utilization rate

---

### Agent 7: UI/HUD Agent

**Mission:** Own all user interface — menus, HUD, settings, and visual feedback.

**Responsibilities:**
- Main menu (Play, Settings, Profile, Quit)
- Lobby UI (player list, map selection, ready state, chat)
- In-game HUD (health bar, jetpack fuel, ammo, weapon icon, kill feed, scoreboard, minimap)
- Settings screen (video, audio, controls, key rebinding)
- Match results screen (scoreboard, MVP, XP earned)
- Toast notifications (kill streak, double kill, etc.)

**Internal Components:**

```
UI/
├── MainMenu/
│   ├── PlayButton         # Routes to quickplay or lobby
│   ├── ProfilePanel       # Shows stats, equipped cosmetics
│   └── SettingsPanel      # Video, audio, controls
├── LobbyUI/
│   ├── PlayerList         # Shows connected players, ready state
│   ├── MapSelector        # Dropdown or visual selector
│   └── ChatBox            # Pre-match text chat
├── HUD/
│   ├── HealthBar          # Horizontal bar, flashes red at low HP
│   ├── FuelGauge          # Vertical bar for jetpack fuel
│   ├── AmmoCounter        # Current / Max
│   ├── WeaponIcon         # Shows equipped weapon
│   ├── KillFeed           # Scrolling list: "Player A [weapon] Player B"
│   ├── Scoreboard         # Tab-held overlay
│   ├── Minimap            # Shows allies as dots (team mode)
│   └── Crosshair          # Dynamic based on weapon spread
├── MatchResults/
│   ├── FinalScoreboard    # All players ranked
│   ├── MVPCard            # Highlight top performer
│   └── XPProgress         # XP gained, level progress bar
└── Notifications/
    └── ToastSystem        # "Double Kill!", "Killing Spree!", etc.
```

**Tech Stack:** Godot Control nodes, GDScript. Custom theme resource for consistent styling.

---

### Agent 8: Orchestrator Agent (Claude-Powered Project Manager)

**Mission:** Act as an AI-driven project manager that tracks progress across all agents, guides the developer through milestones step-by-step, maintains context between sessions, and ensures nothing falls through the cracks.

**This is not a software agent deployed in the game — it's the workflow between you and Claude.**

**How It Works:**

At the start of each development session, you check in with Claude using a structured format. Claude maintains a living state of your project progress and tells you exactly what to work on next.

**Session Start Protocol:**

```
You: "Session start. Project: Stick Game RPG. Last completed: [task ID]. Blockers: [any]."

Claude responds with:
1. Progress summary (what's done, what's in progress, what % of current epic)
2. Today's task list (2-3 tasks from the execution plan, with subtask breakdown)
3. Guidance for task #1 (code structure, pseudocode, gotchas to watch for)
4. Definition of Done for each task (how you know it's complete)
```

**Session End Protocol:**

```
You: "Session end. Completed: [task IDs]. Issues: [any]. Notes: [any]."

Claude responds with:
1. Updated progress tracker
2. Preview of next session's work
3. Any re-sequencing needed based on issues encountered
```

**Orchestrator Responsibilities:**

| Responsibility | How It Works |
|---------------|-------------|
| **Task sequencing** | Follows the execution plan from Step 4. Respects dependencies. Won't suggest networking tasks before player controller is done. |
| **Scope enforcement** | If you say "I want to add vehicles" mid-Phase 1, Claude flags it as scope creep, estimates the impact, and suggests deferring to a future phase. |
| **Blocker resolution** | If you're stuck on a task, Claude helps debug, suggests alternative approaches, or recommends skipping to a parallel task and coming back. |
| **Quality gates** | At each milestone (M1, M2, M3), Claude runs through a checklist of what should be working and asks you to verify. |
| **Architecture guard** | If a shortcut you're taking will cause pain later (e.g., hardcoding player count), Claude flags the tech debt and suggests the right abstraction. |
| **Estimation updates** | If tasks are taking longer than estimated, Claude recalculates timeline and suggests scope cuts to stay on track. |

**Progress Tracking Format:**

Claude tracks your project using this structure (you can paste it at the start of a session):

```
PROJECT: Stick Game RPG
PHASE: 1 (MVP)
CURRENT EPIC: 1.2 Combat System

COMPLETED:
  [x] 1.1.1 Project setup
  [x] 1.1.2 Base character movement
  [x] 1.1.3 Jetpack system
  [x] 1.1.4 Wall-hanging
  [x] 1.1.5 Animation state machine
  [x] 1.1.6 Camera system
  [x] 1.1.7 Input system
  [x] 1.2.1 Weapon data model
  [x] 1.2.2 Weapon manager

IN PROGRESS:
  [ ] 1.2.3 Hitscan weapons (60% — raycast works, need spread cone + tracers)

BLOCKED:
  (none)

UP NEXT:
  [ ] 1.2.4 Projectile weapons
  [ ] 1.2.5 Melee weapon
  [ ] 1.2.6 Health system

TIMELINE STATUS: On track (Day 22 of estimated 90)
```

**Milestone Quality Gates:**

**M1 Gate (End of Phase 1 — Playable Offline):**
```
[ ] Can launch game from main menu
[ ] Character moves, jumps, jetpacks, wall-hangs with responsive controls
[ ] At least 6 weapons functional (hitscan + projectile + melee)
[ ] Weapon and health pickups spawn and work
[ ] Bots navigate the map and fight intelligently
[ ] HUD shows health, fuel, ammo, kill feed, scoreboard
[ ] One complete map with proper spawns
[ ] Match ends after score/time limit, shows results screen
[ ] Runs at 60 FPS on mid-tier hardware
[ ] Builds for Windows AND Mac
VERDICT: Is it fun? Get 5 people to play. If they want to play again → PASS.
```

**M2 Gate (End of Phase 2 — Online Multiplayer):**
```
[ ] Two players can connect over the internet and play a match
[ ] Client-side prediction makes local player feel responsive
[ ] Remote players move smoothly (interpolation)
[ ] Hit registration feels fair up to 150ms latency
[ ] Lobby system works (create, share code, join)
[ ] Match results save to backend, leaderboard updates
[ ] Disconnection handled gracefully (timeout, reconnect)
[ ] LAN discovery works without internet
VERDICT: Play 20 online matches. Count rage-inducing moments. If < 2 per match → PASS.
```

**M3 Gate (End of Phase 3 — Launch Ready):**
```
[ ] 3 maps, 6+ weapons, 2+ game modes
[ ] Progression system (XP, levels, unlocks)
[ ] Sound design complete (guns, jetpack, UI, ambient)
[ ] Settings screen works (video, audio, controls)
[ ] No crashes in 2-hour play sessions
[ ] Backend deployed and accessible
[ ] Game server auto-spawning works
[ ] Build downloadable from Itch.io or Steam
VERDICT: Would you pay $5 for this? Be honest.
```

**How to Use This With Claude:**

1. **Copy the progress tracker** into your first message each session
2. Say **"Session start"** and Claude picks up where you left off
3. Work through tasks — ask Claude for code help, architecture advice, debugging
4. Say **"Session end"** and Claude updates the tracker for next time
5. At milestone boundaries, run the quality gate checklist together

This turns Claude from a "ask random questions" tool into a **persistent co-pilot** that keeps your project on rails.

---

## Step 4: Deep Execution Plan

### Phase 1: MVP (Months 1–3)

**Goal:** Playable single-player prototype with core mechanics. One map, bots, no networking yet.

---

#### Epic 1.1: Project Setup & Player Controller (Weeks 1–3)

| Task | Subtasks | Est. | Dependencies |
|------|----------|------|--------------|
| **1.1.1** Set up Godot project | Create project structure, configure GDExtension for C++, set up Git repo, establish folder conventions | 2 days | None |
| **1.1.2** Implement base character movement | CharacterBody2D setup, gravity, ground detection, run (variable speed), jump (variable height), crouch | 4 days | 1.1.1 |
| **1.1.3** Implement jetpack system | Fuel system (float 0–100), thrust force application, fuel drain rate, ground recharge rate, particle effects for thrust | 3 days | 1.1.2 |
| **1.1.4** Implement wall-hanging | Wall detection raycasts, state transition (falling near wall → hanging), wall jump-off | 2 days | 1.1.2 |
| **1.1.5** Implement animation state machine | Sprite sheet integration, AnimationPlayer setup, state transitions (idle↔run↔jump↔fall↔jetpack↔crouch↔death) | 3 days | 1.1.2 |
| **1.1.6** Implement camera system | Smooth follow camera, look-ahead based on aim direction, screen bounds clamping to map, screen shake utility | 2 days | 1.1.2 |
| **1.1.7** Implement input system | Input action mapping, keyboard+mouse bindings, input rebinding support, input abstraction layer for future gamepad | 2 days | 1.1.1 |

**Parallelizable:** 1.1.5, 1.1.6, 1.1.7 can happen in parallel once 1.1.2 is done.

---

#### Epic 1.2: Combat System (Weeks 3–5)

| Task | Subtasks | Est. | Dependencies |
|------|----------|------|--------------|
| **1.2.1** Weapon data model | Define WeaponDefinition resource: name, damage, fire_rate, spread_angle, range, ammo_capacity, reload_time, projectile_speed (0 = hitscan), type enum | 2 days | 1.1.1 |
| **1.2.2** Weapon manager | Equip/swap logic, ammo tracking, reload timer, weapon switching cooldown | 3 days | 1.2.1 |
| **1.2.3** Hitscan weapons | Raycast from muzzle in aim direction with spread cone, damage application, hit effect spawning, tracer visual | 3 days | 1.2.1, 1.1.2 |
| **1.2.4** Projectile weapons | Projectile scene: RigidBody2D, speed, gravity, explosion radius, lifetime, collision handling | 3 days | 1.2.1, 1.1.2 |
| **1.2.5** Melee weapon | Short-range area overlap check in aim direction, damage application, swing animation | 1 day | 1.2.1 |
| **1.2.6** Health system | Health component: max_hp, current_hp, take_damage(), heal(), death signal, invulnerability frames on respawn | 2 days | 1.1.2 |
| **1.2.7** Weapon pickups | Pickup scene: weapon type, respawn timer, collision area, float/glow animation, interaction prompt | 2 days | 1.2.1 |
| **1.2.8** Health pickups | Same pattern as weapon pickups: heal amount, respawn timer | 1 day | 1.2.6 |
| **1.2.9** Kill feed system | Event bus: on_kill(killer, victim, weapon) → UI renders scrolling text | 1 day | 1.2.6 |

---

#### Epic 1.3: Map & Environment (Weeks 4–5)

| Task | Subtasks | Est. | Dependencies |
|------|----------|------|--------------|
| **1.3.1** Tileset creation | Design or source a 2D tileset (ground, walls, platforms, decorative). Stick-figure aesthetic. | 3 days | None (art task) |
| **1.3.2** Map 1 design & build | Design layout on paper, build in Godot TileMap, test flow, place spawn points (8), weapon pickups (6), health pickups (4) | 3 days | 1.3.1 |
| **1.3.3** Spawn system | SpawnPointManager: track occupied points, selection algorithm (farthest-from-enemies weighted random), respawn timer | 2 days | 1.3.2, 1.1.2 |
| **1.3.4** Map boundaries | Kill zone below map, invisible walls at edges, camera clamping | 1 day | 1.3.2 |

---

#### Epic 1.4: Bot AI (Weeks 5–7)

| Task | Subtasks | Est. | Dependencies |
|------|----------|------|--------------|
| **1.4.1** Navigation setup | Generate 2D navigation mesh from tilemap collision, test pathfinding | 2 days | 1.3.2 |
| **1.4.2** Basic behavior tree | Implement BT nodes: Selector, Sequence, Condition, Action. Build tree: Patrol → SeekTarget → EngageTarget | 4 days | 1.4.1 |
| **1.4.3** Aim simulation | Bot aiming: calculate angle to target, add noise based on difficulty, reaction time delay before firing | 2 days | 1.4.2, 1.2.3 |
| **1.4.4** Retreat behavior | Health threshold check → pathfind to nearest health pickup, disengage combat | 2 days | 1.4.2, 1.2.8 |
| **1.4.5** Weapon pickup behavior | Evaluate nearby weapon pickups, pathfind to preferred/better weapon | 1 day | 1.4.2, 1.2.7 |
| **1.4.6** Difficulty profiles | Define Easy/Medium/Hard: reaction_time_ms, accuracy_pct, aggression_factor, retreat_health_threshold | 1 day | 1.4.3 |

---

#### Epic 1.5: HUD & Menus (Weeks 6–7)

| Task | Subtasks | Est. | Dependencies |
|------|----------|------|--------------|
| **1.5.1** In-game HUD | Health bar, fuel gauge, ammo counter, weapon icon, crosshair — all connected to game state signals | 3 days | 1.2.6, 1.1.3, 1.2.2 |
| **1.5.2** Kill feed UI | Scrolling text list, auto-remove after 5s, weapon icon between names | 1 day | 1.2.9 |
| **1.5.3** Scoreboard (tab-hold) | Table: Player, Kills, Deaths, K/D — updates in real-time | 1 day | 1.2.9 |
| **1.5.4** Main menu | Play (vs bots), Settings, Quit. Clean minimal design. | 2 days | None |
| **1.5.5** Settings screen | Volume sliders (master, SFX, music), resolution dropdown, fullscreen toggle, key rebinding UI | 2 days | 1.1.7 |
| **1.5.6** Match results screen | Final scoreboard, highlight winner, "Play Again" / "Main Menu" buttons | 1 day | 1.5.3 |

---

**MVP Milestone Deliverable:** A complete single-player game. Launch → pick game mode (Deathmatch, Team DM) → select map → configure bot count/difficulty → play match → see results. Runs on Windows and Mac.

---

### Phase 2: Multiplayer (Months 3–5)

**Goal:** Online multiplayer with lobby system and backend services.

---

#### Epic 2.1: Networking Core (Weeks 9–12)

| Task | Subtasks | Est. | Dependencies |
|------|----------|------|--------------|
| **2.1.1** Network architecture setup | ENet integration, define client/server roles, packet types enum, connection state machine | 3 days | MVP complete |
| **2.1.2** Binary serialization | Define packet formats: InputPacket (sequence, tick, inputs), SnapshotPacket (all player states), EventPacket (kills, pickups) | 4 days | 2.1.1 |
| **2.1.3** Server-authoritative game loop | Headless Godot server: receives inputs, steps simulation, broadcasts snapshots at 30Hz | 5 days | 2.1.2 |
| **2.1.4** Client-side prediction | Apply local inputs immediately, store input history, on server snapshot: compare, rewind, replay if diverged | 5 days | 2.1.3 |
| **2.1.5** Entity interpolation | Buffer 2–3 snapshots for remote players, render interpolated positions between snapshots, handle snapshot gaps | 3 days | 2.1.3 |
| **2.1.6** Lag compensation | Server-side: on hit registration, rewind world state to shooter's timestamp, perform raycast, apply result | 4 days | 2.1.3, 1.2.3 |
| **2.1.7** Delta compression | Only send changed fields since last acknowledged snapshot. Reduces bandwidth ~60-80% | 3 days | 2.1.2 |
| **2.1.8** Connection management | Heartbeat (5s), timeout detection (15s), graceful disconnect, reconnect within 30s window | 2 days | 2.1.1 |

---

#### Epic 2.2: Backend Services (Weeks 10–13)

| Task | Subtasks | Est. | Dependencies |
|------|----------|------|--------------|
| **2.2.1** Rails project setup | Rails 7 API mode, PostgreSQL, Redis, Sidekiq, Docker Compose, CI/CD pipeline | 2 days | None |
| **2.2.2** Auth system | User model, Devise + JWT, signup/login/refresh endpoints, rate limiting on auth endpoints | 3 days | 2.2.1 |
| **2.2.3** Player profile API | Stats model, loadout model, CRUD endpoints, stat aggregation queries | 2 days | 2.2.2 |
| **2.2.4** Lobby system | Lobby model (code, host, map, mode, max_players, state), create/join/leave endpoints, ActionCable channel for real-time updates | 5 days | 2.2.2 |
| **2.2.5** Game server orchestrator | Script to spawn Godot headless process with assigned port, health monitoring, cleanup on match end | 3 days | 2.1.3, 2.2.1 |
| **2.2.6** Match results ingestion | Endpoint for game server to POST results, update player stats (kills, deaths, wins), ELO calculation | 2 days | 2.2.3 |
| **2.2.7** Leaderboard | Redis sorted set: ZADD/ZRANGE for global ranking, ZRANGEBYSCORE for weekly (TTL keys), API endpoints with pagination | 2 days | 2.2.6 |
| **2.2.8** Matchmaking | Sidekiq worker: poll queue, group by mode/region, match by ELO ± expanding range, notify via ActionCable | 3 days | 2.2.4, 2.2.5 |

**Parallelizable:** Epic 2.1 and 2.2 run in parallel. Networking (2.1) is pure game-client/server work. Backend (2.2) is pure Rails. They integrate at 2.2.5.

---

#### Epic 2.3: Integration & Polish (Weeks 13–15)

| Task | Subtasks | Est. | Dependencies |
|------|----------|------|--------------|
| **2.3.1** Client ↔ Backend integration | Auth flow in game client, lobby UI connected to API, matchmaking queue UI | 3 days | 2.2.4, 2.2.8 |
| **2.3.2** Lobby → Game Server handoff | Lobby ready → backend spawns server → sends connection details to all clients via WebSocket → clients connect to game server | 3 days | 2.2.5, 2.1.1 |
| **2.3.3** Map 2 & Map 3 | Design and build two additional maps with different layouts and themes | 4 days | 1.3.1 |
| **2.3.4** Sound design | Gun sounds, jetpack sound, footsteps, hit/death sounds, ambient music, UI sounds. Source from Freesound.org + generate. | 4 days | None |
| **2.3.5** Playtesting & netcode tuning | Test with real latency (tc netem for simulated lag), tune interpolation buffer, prediction thresholds, tick rates | 5 days | All 2.x |
| **2.3.6** Anti-cheat basics | Server-side: validate movement speed, fire rate, ammo counts. Reject impossible inputs. Log suspicious patterns. | 2 days | 2.1.3 |

---

### Phase 3: Polish & Launch (Months 5–7)

#### Epic 3.1: Progression & Cosmetics (Weeks 15–18)

| Task | Est. |
|------|------|
| XP system: earn XP per kill, assist, win. Level-up thresholds. | 2 days |
| Cosmetic unlocks: character skins, weapon skins (palette swaps). Unlocked at level milestones. | 3 days |
| Loadout persistence: save preferred weapon, skin to profile via API. | 1 day |

#### Epic 3.2: Game Modes (Weeks 16–18)

| Task | Est. |
|------|------|
| Capture the Flag mode: flag entity, carry mechanics, scoring | 4 days |
| Team spawn logic, team assignment, team-colored indicators | 2 days |

#### Epic 3.3: Distribution & Deployment (Weeks 18–20)

| Task | Est. |
|------|------|
| Build pipeline: Godot export templates for Windows (.exe) and macOS (.app) | 2 days |
| Backend deployment: Docker on DigitalOcean/Hetzner, Nginx reverse proxy, SSL | 2 days |
| Game server deployment: containerized Godot headless, auto-scaling script | 3 days |
| Steam integration (optional): Steamworks SDK, Steam auth, achievements | 5 days |
| Itch.io release (simpler alternative): upload builds, configure page | 1 day |

#### Epic 3.4: Observability (Weeks 17–19)

| Task | Est. |
|------|------|
| Backend: structured logging (Lograge), error tracking (Sentry), APM (Skylight or NewRelic free tier) | 2 days |
| Game server: log match events, player connections, errors to file, ship to central log | 2 days |
| Metrics dashboard: active players, matches in progress, avg queue time, server utilization (Grafana + Prometheus or simple Rails admin) | 2 days |
| Alerting: server crash, API error rate > 5%, matchmaking queue > 60s | 1 day |

---

## Step 5: Data Design

### 5.1 Core Entities

```
┌────────────────┐       ┌─────────────────┐       ┌──────────────────┐
│     User       │       │   PlayerStats    │       │     Loadout      │
├────────────────┤       ├─────────────────┤       ├──────────────────┤
│ id (PK)        │──1:1──│ user_id (FK)     │       │ user_id (FK)     │
│ email          │       │ kills            │       │ preferred_weapon │
│ username       │       │ deaths           │       │ skin_id          │
│ password_digest│       │ wins             │       │ crosshair_style  │
│ elo_rating     │       │ losses           │       └──────────────────┘
│ level          │       │ total_xp         │
│ xp_current     │       │ matches_played   │
│ created_at     │       │ time_played_sec  │
│ last_login_at  │       │ best_kill_streak │
└────────────────┘       └─────────────────┘

┌────────────────┐       ┌─────────────────────┐
│     Lobby      │       │   LobbyMembership   │
├────────────────┤       ├─────────────────────┤
│ id (PK)        │──1:N──│ lobby_id (FK)        │
│ code (unique)  │       │ user_id (FK)         │
│ host_user_id   │       │ ready (bool)         │
│ map            │       │ team (int, nullable) │
│ mode           │       │ joined_at            │
│ max_players    │       └─────────────────────┘
│ state (enum)   │
│ created_at     │       state: waiting → starting → in_progress → finished
└────────────────┘

┌─────────────────────┐       ┌──────────────────────┐
│       Match         │       │   MatchParticipant   │
├─────────────────────┤       ├──────────────────────┤
│ id (PK)             │──1:N──│ match_id (FK)         │
│ lobby_id (FK, null) │       │ user_id (FK, null)    │
│ map                 │       │ bot_name (nullable)   │
│ mode                │       │ kills                 │
│ duration_sec        │       │ deaths                │
│ server_id           │       │ damage_dealt          │
│ started_at          │       │ damage_taken          │
│ ended_at            │       │ team                  │
│ state               │       │ placement             │
└─────────────────────┘       │ xp_earned             │
                              └──────────────────────┘

┌──────────────────┐
│   GameServer     │
├──────────────────┤
│ id (PK)          │
│ host             │
│ port             │
│ match_id (FK)    │
│ state (enum)     │    state: provisioning → ready → in_match → shutting_down
│ pid              │
│ region           │
│ last_heartbeat   │
│ created_at       │
└──────────────────┘
```

### 5.2 Data Ownership Per Agent

| Entity | Owner Agent | Access Pattern |
|--------|-------------|---------------|
| User, PlayerStats, Loadout | Backend Services Agent | Strong consistency (PostgreSQL) |
| Lobby, LobbyMembership | Backend Services Agent | Strong consistency + real-time pub/sub (ActionCable + Redis) |
| Match, MatchParticipant | Backend Services Agent (write), Leaderboard (read) | Write: strong (POST from game server). Read: eventually consistent (Redis cache) |
| GameServer | Backend Services Agent | Strong consistency. Health checks update last_heartbeat. |
| Leaderboard rankings | Backend Services Agent | Eventually consistent (Redis sorted sets, rebuilt from MatchParticipant data) |
| In-match game state | Networking Agent (server) | Ephemeral. Lives only in memory during match. Not persisted until match end. |

### 5.3 Consistency Model

| Data | Model | Rationale |
|------|-------|-----------|
| Auth/User | Strong (PostgreSQL) | Security-critical. Cannot tolerate stale reads. |
| Player stats | Strong write, eventually consistent read | Stats update on match end (infrequent write). Leaderboard can lag by seconds. |
| Lobby state | Strong + real-time push | Players must see consistent lobby state. ActionCable pushes changes immediately. |
| In-match game state | Ephemeral, not persisted | 30–60 snapshots/sec. Only final results persisted. |
| Leaderboard | Eventually consistent (< 5s lag) | Redis sorted set updated on match end. Acceptable to be a few seconds behind. |

---

## Step 6: Scaling Strategy

### 6.1 Scaling Tiers

#### Tier 1: 1K Concurrent Users (~125 active matches)

| Component | Sizing | Notes |
|-----------|--------|-------|
| Game servers | 1 VPS (8-core, 16GB RAM) | Each Godot headless instance uses ~200MB. 125 instances = ~25GB → split across 2 VPS |
| Rails backend | 1 VPS (4-core, 8GB) with Puma (8 workers) | Handles ~500 req/s easily |
| PostgreSQL | Single instance, same or separate VPS | < 1M rows. No scaling needed. |
| Redis | Single instance (1GB) | Trivial load |
| **Monthly cost estimate** | ~$80–120 | 3-4 cheap VPS instances |

#### Tier 2: 100K Concurrent Users (~12,500 active matches)

| Component | Change | Reasoning |
|-----------|--------|-----------|
| Game servers | 20–30 VPS across 3 regions (US-East, EU-West, Asia) | Latency-sensitive. Must be close to players. |
| Rails backend | 3 app servers behind load balancer | Stateless Rails scales horizontally. |
| PostgreSQL | Primary + 2 read replicas | Leaderboard/stats reads hit replicas. |
| Redis | Redis Cluster (3 nodes) | Leaderboard sorted sets grow. Pub/sub for lobbies. |
| CDN | Add CDN for game client downloads | Reduce bandwidth costs. |
| **Monthly cost estimate** | ~$2,000–4,000 | Significant but manageable at this scale |

**Bottlenecks at this tier:**
- Game server orchestration: Simple script won't cut it. Need container orchestration (Docker Swarm or lightweight K8s). Mitigation: Kubernetes with custom operator or Nomad.
- Matchmaking: Sidekiq single-threaded matching becomes slow. Mitigation: Partition queues by region, run dedicated matchmaking workers per region.
- Lobby WebSockets: ActionCable on single server limits connections (~10K). Mitigation: AnyCable (Go-based ActionCable server, handles 100K+ connections).

#### Tier 3: 10M Concurrent Users (~1.25M active matches)

This tier requires significant re-architecture:

| Component | Change |
|-----------|--------|
| Game servers | Kubernetes clusters in 10+ regions, auto-scaling based on queue depth |
| Backend | Microservices split: Auth, Profile, Matchmaking, Leaderboard as separate services |
| Database | Sharded PostgreSQL (by user_id hash) or move to CockroachDB. Separate DB per service. |
| Matchmaking | Dedicated service (likely rewritten in Go/Rust for performance). Regional partitioning. |
| Leaderboard | Dedicated Redis Cluster, pre-computed rollups, approximate rankings |
| Real-time | Dedicated WebSocket service (Go or Elixir) replacing ActionCable |
| Observability | Full Datadog/Grafana stack, distributed tracing |

**Honest note:** A solo developer should not plan for 10M users from day one. This tier is documented for architectural awareness. If the game reaches 100K users, you have revenue to hire a team.

---

## Step 7: Risks & Tradeoffs

### 7.1 Technical Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Netcode feels bad (rubber-banding, hit reg issues) | High | Critical — players quit if it feels unfair | Invest heavily in Phase 2 playtesting. Use proven algorithms (Quake model). Budget extra time. |
| Godot GDExtension C++ debugging is painful | Medium | Slows development | Use GDScript for everything except hot paths. Only drop to C++ when profiling proves necessity. |
| Cross-platform build issues (Mac) | Medium | Blocks half the user base | Test Mac builds weekly in CI. Godot's Mac export is mature but needs code signing ($99/yr Apple Developer). |
| Game server hosting costs grow unexpectedly | Low (at MVP scale) | Financial | Start with on-demand VPS. Implement match time limits (5 min) and server recycling. |
| Cheat/exploit discovery | High (if game gets popular) | Erodes player trust | Server-authoritative model prevents most cheats. Basic validation in MVP. Invest more in Phase 3. |

### 7.2 Product Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Game isn't fun | Medium | Fatal | Playtest the MVP (Phase 1) with real humans before investing in multiplayer. Iterate on game feel. |
| Can't find players for matches | High (at launch) | Players churn immediately | Bot backfill for small lobbies. Focus on friend-invite (lobby codes) over random matchmaking initially. |
| Weapon balance is bad | High | Players frustrate, quit | Data-driven weapon definitions. Collect kill-by-weapon stats. Iterate balance with patches. |
| Market saturation (many 2D shooters exist) | Medium | Low player acquisition | Differentiate on PC (Mini Militia is mobile-only). Focus on tight controls and community. |

### 7.3 Operational Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Solo developer burnout | High | Project abandoned | Phase the work. Ship MVP and get feedback. Don't gold-plate. Take breaks. |
| Scope creep ("just one more feature") | Very High | Delays everything | This document is the scope contract. Anything not listed requires explicit re-prioritization. |
| Data loss (no backups) | Low (but catastrophic) | Lose all player data | Automated daily PostgreSQL backups to S3. Test restore quarterly. |
| Server security (DDoS, injection) | Medium | Downtime, data breach | Rate limiting on all APIs. Parameterized queries (Rails does this by default). Cloudflare for DDoS. |

### 7.4 Key Design Tradeoffs

| Decision | Chosen | Alternative | Why |
|----------|--------|-------------|-----|
| Engine | Godot 4 | Unreal, Unity | Godot excels at 2D, is free/open-source, supports C++, lightweight. Unreal is overkill for 2D. Unity has licensing concerns. |
| Networking model | Server-authoritative + client prediction | Peer-to-peer, client-authoritative | Fairness is non-negotiable for a shooter. More complex but prevents cheating. |
| Backend language | Ruby on Rails | Node.js, Go, Elixir | Developer already knows Rails. Productivity matters more than raw performance at this scale. Go/Elixir considered for real-time services at scale. |
| Database | PostgreSQL + Redis | MongoDB, DynamoDB | Relational model fits structured game data. Redis handles real-time leaderboard/cache perfectly. |
| Transport | ENet (UDP) | WebSocket, TCP, WebRTC | UDP is required for real-time game state (order doesn't matter, latest wins). ENet adds reliability layer for critical events. WebSocket adds HTTP overhead. |
| Art style | Stick-figure / minimalist | Pixel art, hand-drawn | Achievable by a solo developer. Avoids art bottleneck. Can be upgraded later. |
| Matchmaking | Simple ELO | Glicko-2, TrueSkill | ELO is well-understood and sufficient for 1v1 and small team modes. Upgrade to Glicko-2 at scale if needed. |

---

## Step 8: Execution Timeline

```
Month 1        Month 2        Month 3        Month 4        Month 5        Month 6        Month 7
┌──────────────┬──────────────┬──────────────┬──────────────┬──────────────┬──────────────┬──────────────┐
│▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓            │              │              │              │
│ PHASE 1: MVP (Single-player)                              │              │              │              │
│ - Player controller          ████████                     │              │              │              │
│ - Combat system                     ████████              │              │              │              │
│ - Map & environment                   ██████              │              │              │              │
│ - Bot AI                                 ████████         │              │              │              │
│ - HUD & menus                              ██████         │              │              │              │
│                              │              │              │              │              │              │
│ MILESTONE: Playable offline game ─────────────── ◆ M1     │              │              │              │
│                              │              │              │              │              │              │
│              │              │▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓│              │              │
│              │              │ PHASE 2: Multiplayer                       │              │              │
│              │              │ - Networking core     ████████████████     │              │              │
│              │              │ - Backend services    ████████████████     │              │              │
│              │              │ - Integration            ██████████████    │              │              │
│              │              │              │              │              │              │              │
│              │              │ MILESTONE: Online multiplayer ──── ◆ M2    │              │              │
│              │              │              │              │              │              │              │
│              │              │              │              │▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓│
│              │              │              │              │ PHASE 3: Polish & Launch                   │
│              │              │              │              │ - Progression/cosmetics ██████             │
│              │              │              │              │ - Extra game modes      ██████             │
│              │              │              │              │ - Deployment/CI         ████████           │
│              │              │              │              │ - Observability         ██████             │
│              │              │              │              │ - Playtesting/bugfix          ████████████ │
│              │              │              │              │              │              │              │
│              │              │              │              │ MILESTONE: Public launch ──────────── ◆ M3 │
└──────────────┴──────────────┴──────────────┴──────────────┴──────────────┴──────────────┴──────────────┘
```

### Key Milestones

| Milestone | Target | Deliverable | Go/No-Go Criteria |
|-----------|--------|-------------|-------------------|
| **M1: Playable Offline** | End of Month 3 | Single-player game with bots, 1 map, full combat | Is it fun? Do controls feel tight? Get 5 people to play and give feedback. |
| **M2: Online Multiplayer** | End of Month 5 | 2–8 player online matches, lobby system, backend | Can two players across the internet play a smooth match? |
| **M3: Public Launch** | End of Month 7 | Polished game on Itch.io / Steam | 3 maps, 6 weapons, progression, leaderboard, stable servers. |

### Post-Launch

| Month | Focus |
|-------|-------|
| 8–9 | Community feedback, balance patches, bug fixes |
| 9–10 | New maps, new weapons, seasonal events |
| 10–12 | Mobile port consideration (Godot supports Android/iOS export) |

---

---

# PROJECT 2: IRONSIGHT (COD-like FPS) — High-Level Roadmap

> **Prerequisite:** Complete Project 1. Skills gained: networking, game architecture, backend services, multiplayer.

### What Changes From Project 1

| Dimension | Stick Game RPG | IronSight |
|-----------|-----------|-----------|
| Engine | Godot 4 | Unreal Engine 5 (C++) |
| Perspective | 2D side-scroller | 3D first-person |
| Art complexity | Stick figures, tilemaps | 3D models, textures, animations |
| Physics | Simple 2D | Full 3D: raycasting, projectile physics, ballistics |
| Networking | 8 players, 2D state | 12–16 players, 3D state (positions, rotations, animations) |
| AI | 2D behavior trees | 3D navigation mesh, cover system, tactical AI |
| Audio | Simple SFX | 3D spatial audio, directional sound |

### Phased Approach

**Phase 1 (Months 1–4): FPS Prototype**
- Learn Unreal Engine 5 fundamentals (Blueprint + C++)
- First-person camera, character controller, basic movement (walk, sprint, crouch, jump)
- One hitscan weapon (assault rifle): ADS (aim down sights), recoil pattern, spread
- One small map (e.g., a warehouse)
- AI bots using Unreal's built-in behavior tree + navigation system
- Basic HUD (crosshair, health, ammo, kill feed)

**Phase 2 (Months 4–8): Multiplayer & Content**
- Unreal's built-in replication system for networking (much of the netcode is handled by the engine)
- Dedicated server (Unreal supports this natively)
- 4–6 weapon types (AR, SMG, shotgun, sniper, pistol, launcher)
- Class/loadout system
- 3 maps
- Game modes: TDM, Free-for-all, Search & Destroy
- Killstreaks (UAV, airstrike — simple versions)

**Phase 3 (Months 8–12): Polish**
- Backend services (reuse and adapt Rails backend from Project 1)
- Progression, unlocks, leaderboard
- Sound design, visual polish (UE5 Lumen lighting, Nanite for asset detail)
- Steam release

**Phase 4 (Months 12–18): Advanced Features**
- Battle Royale mode (large map, shrinking zone, looting)
- Ranked matchmaking with anti-cheat (EasyAntiCheat integrates with UE5)
- Seasonal content cadence

### Key New Skills Acquired
- Unreal Engine 5 (C++ and Blueprints)
- 3D mathematics (vectors, quaternions, matrix transforms)
- 3D asset pipeline (Blender → Unreal)
- Unreal networking/replication model
- 3D level design and lighting
- Spatial audio implementation

---

---

# PROJECT 3: DOMINION (Age of Empires-like RTS) — High-Level Roadmap

> **Prerequisite:** Complete Project 2. Skills gained: Unreal Engine, 3D rendering, complex AI, large-scale multiplayer.

### What Changes From Previous Projects

| Dimension | IronSight (FPS) | Dominion (RTS) |
|-----------|-----------------|----------------|
| Camera | First-person | Isometric/top-down with zoom |
| Unit count | 1 player character | 200+ units per player on screen |
| AI | Single agent behavior trees | Multi-agent coordination, economic AI, army composition AI |
| Networking | Player inputs (few) | Unit commands for hundreds of units (lockstep or command-based) |
| Core loop | Aim and shoot | Gather → Build → Train → Fight |
| Economy | None | Multi-resource economy (food, wood, gold, stone) |
| Tech tree | None | Branching tech tree with age advancement |

### Phased Approach

**Phase 1 (Months 1–5): RTS Foundation**
- Engine: Unreal Engine 5 (reuse knowledge) or Godot 4 (if 2D/isometric approach preferred)
- Isometric camera with pan, zoom, rotate
- Tilemap-based terrain (grass, forest, water, mountains)
- Villager unit: move, gather resource, build structure, pathfinding (A* or flow fields for mass units)
- Resource system: food, wood, gold, stone
- Basic structures: town center, house (population cap), farm, barracks
- Military unit: one infantry type, move and attack commands
- Selection system: click-select, box-select, control groups
- Minimap

**Phase 2 (Months 5–10): Gameplay Depth**
- Tech tree / Age advancement (4 ages with visual building upgrades)
- 3 civilizations with unique units and bonuses
- Full military roster: infantry, archers, cavalry, siege weapons
- Building roster: walls, towers, markets, monasteries, castles
- Fog of war
- Advanced AI opponent (economic planning, army composition, attack timing, difficulty levels)
- Formation system for military units

**Phase 3 (Months 10–15): Multiplayer**
- Deterministic lockstep networking (RTS standard — send commands, not state)
- 2–4 player matches
- Replay system (trivial with lockstep — just record commands)
- Lobby and matchmaking (reuse backend from Projects 1/2)
- Spectator mode

**Phase 4 (Months 15–24): Content & Polish**
- Campaign / scenario editor
- 6+ civilizations
- Map editor (share custom maps)
- Ranked multiplayer with ELO
- Steam release with Workshop support for mods

### Key Technical Challenges

| Challenge | Approach |
|-----------|----------|
| Pathfinding for 200+ units | Flow field pathfinding (not A* per unit — doesn't scale). Pre-compute flow fields per destination. |
| Unit selection and command processing | Spatial hashing for efficient box-select. Command queue per unit with priority system. |
| Fog of war | Per-tile visibility grid updated each tick. GPU-based fog rendering. |
| Deterministic lockstep networking | Fixed-point math (no floats — floating point is non-deterministic across platforms). Deterministic RNG seeded per match. |
| Economic AI | Influence maps + utility-based decision making. Score possible actions (build farm vs. train soldier vs. advance age) and pick highest utility. |
| Performance at 500+ units | Entity Component System (ECS) architecture. Batch rendering. LOD for distant units. |

---

---

# Appendix A: Skill Progression Map

```
Project 1: Stick Game RPG (2D Shooter)
├── 2D game development fundamentals
├── Game physics (platformer movement, projectiles)
├── Client-server networking (ENet, UDP)
├── Client-side prediction & interpolation
├── Behavior tree AI
├── Rails backend for game services
├── Multiplayer infrastructure (lobbies, matchmaking)
└── Shipping a complete game

        ↓ Skills carry forward + new skills added

Project 2: IronSight (3D FPS)
├── Unreal Engine 5 (C++ and Blueprints)
├── 3D mathematics and rendering
├── 3D asset pipeline (Blender → UE5)
├── Unreal replication / networking model
├── Advanced AI (cover system, tactical)
├── 3D spatial audio
├── Anti-cheat integration
└── Console/platform considerations

        ↓ Skills carry forward + new skills added

Project 3: Dominion (RTS)
├── Large-scale simulation (hundreds of entities)
├── Deterministic lockstep networking
├── Economic/strategic AI
├── Flow field pathfinding
├── Entity Component System architecture
├── Mod support and content pipeline
├── Map/scenario editor tooling
└── Full game production expertise
```

---

# Appendix B: Tool & Resource Recommendations

| Category | Tool | Cost |
|----------|------|------|
| Game Engine (2D) | Godot 4 | Free |
| Game Engine (3D) | Unreal Engine 5 | Free (5% royalty > $1M) |
| 3D Modeling | Blender | Free |
| 2D Art | Aseprite (pixel art), Krita (painting) | $20 / Free |
| Sound Effects | Freesound.org, BFXR (generator) | Free |
| Music | Incompetech, Kevin MacLeod (CC) | Free w/ attribution |
| Version Control | Git + GitHub | Free |
| CI/CD | GitHub Actions | Free for public repos |
| Backend Hosting | DigitalOcean / Hetzner | $5–40/mo |
| Database | PostgreSQL | Free (self-hosted) |
| Cache | Redis | Free (self-hosted) |
| Distribution | Itch.io (free), Steam ($100 one-time) | $0–100 |
| AI Assistant | Claude | Existing subscription |

---

# Appendix C: Free Asset Sources — Complete Guide

This is your cheat sheet for never paying for assets during prototyping and early development. Organized by project phase and asset type.

---

## Project 1: Stick Game RPG (2D Assets)

### Character Sprites & Animations

| Source | URL | What You Get | License |
|--------|-----|-------------|---------|
| **Itch.io (2D Free)** | https://itch.io/game-assets/free/tag-2d | Massive library of free 2D sprites, characters, weapons, tilesets. Best single source. | Varies per asset (check each — many are CC0 or CC-BY) |
| **Kenney.nl** | https://kenney.nl/assets | The gold standard for free game assets. Clean, consistent style. Character packs, platformer kits, weapon sprites, UI elements. All CC0 (public domain). | CC0 (use for anything, no attribution needed) |
| **OpenGameArt.org** | https://opengameart.org | Community-contributed sprites, tilesets, and animations. Search "platformer" or "shooter" for relevant packs. | CC0, CC-BY, CC-BY-SA (check each) |
| **CraftPix Freebies** | https://craftpix.net/freebies/ | Professional-quality free sample packs. Platformer characters, weapons, tilesets. | Free for commercial use |
| **GameArt2D** | https://www.gameart2d.com/freebies.html | Cute character sprites, platformer tilesets, GUI elements. Good for prototyping. | Free for commercial use |
| **GDQuest** | https://github.com/gdquest-demos | Godot-specific free assets. Sorted into characters, weapons, grid folders. Perfect for rapid prototyping. | CC0 |

### Tilesets & Maps

| Source | URL | Best For |
|--------|-----|---------|
| **Kenney Platformer Packs** | https://kenney.nl/assets/category:2D | Complete platformer tilesets with ground, walls, platforms, decorations |
| **Itch.io Tilesets** | https://itch.io/game-assets/free/tag-tileset | Search "platformer tileset" — hundreds of free options |
| **LPC (Liberated Pixel Cup)** | https://opengameart.org/content/lpc-collection | Huge community tileset collection, modular and combinable |

### Weapons & Projectiles

| Source | URL | Notes |
|--------|-----|-------|
| **Itch.io 2D Weapons** | https://itch.io/game-assets/free/tag-2d/tag-weapons | Gun sprites, sword sprites, projectile effects, crosshairs |
| **Kenney Weapon Pack** | https://kenney.nl/assets/weapon-pack | Clean weapon icons and sprites |

### UI / HUD Elements

| Source | URL | Notes |
|--------|-----|-------|
| **Kenney UI Pack** | https://kenney.nl/assets/ui-pack | Buttons, bars, panels, icons — everything for menus and HUD |
| **Itch.io GUI** | https://itch.io/game-assets/free/tag-gui | Health bars, inventory panels, crosshairs, scoreboards |

### How to Make Maps (Stick Game RPG)

You'll build maps directly in **Godot's TileMap editor**. Here's the workflow:

```
1. GET A TILESET
   └── Download a free platformer tileset from Kenney or Itch.io
       (e.g., "Kenney Abstract Platformer" or "Kenney Pixel Platformer")

2. IMPORT INTO GODOT
   └── Drag tileset PNG into your Godot project
   └── Create a TileSet resource → assign the PNG → define tile regions
   └── Set collision shapes on each tile (which tiles are solid ground, which are platforms)

3. BUILD THE MAP
   └── Create a TileMap node in your scene
   └── Paint tiles visually in the editor — like MS Paint but for game levels
   └── Layer 1: Background (decorative, no collision)
   └── Layer 2: Foreground (solid ground, walls, platforms — has collision)
   └── Layer 3: Decorations on top (vines, signs, etc.)

4. PLACE SPAWN POINTS
   └── Add Marker2D nodes where players spawn
   └── Add Marker2D nodes where weapon pickups appear
   └── Add Marker2D nodes where health pickups appear

5. TEST & ITERATE
   └── Run the game, walk around the map
   └── Check: Can players reach all areas? Are there camping spots? Is there vertical variety?
   └── Adjust and repeat
```

**Map design tips for a Mini Militia-style game:**
- Include plenty of vertical space (jetpacks need room)
- Mix tight corridors (shotgun/melee territory) with open areas (sniper/rifle territory)
- Place weapon pickups in risky locations (incentivizes movement)
- Have at least 8 spawn points spread across the map to prevent spawn camping
- Add visual landmarks so players orient themselves quickly

---

## Project 2: IronSight (3D Assets)

### 3D Models — Characters, Weapons, Environment

| Source | URL | What You Get | License |
|--------|-----|-------------|---------|
| **Quixel Megascans** | https://quixel.com/megascans | Photoscanned 3D assets — rocks, ground, foliage, surfaces. FREE when used in Unreal Engine. Thousands of AAA-quality assets. | Free in UE5 only |
| **Sketchfab (Free)** | https://sketchfab.com/features/free-3d-models | Huge library of free 3D models. Search "FPS weapon", "soldier character", "military props". | Varies (filter by Creative Commons) |
| **Kenney 3D** | https://kenney.nl/assets/category:3D | Low-poly 3D assets: characters, buildings, vehicles, weapons. Great for prototyping. | CC0 |
| **Quaternius** | https://quaternius.com | Beautiful free low-poly 3D packs: nature, characters, buildings, weapons. Very popular in indie community. | CC0 |
| **Mixamo** | https://www.mixamo.com | Free character rigging and animations. Upload a 3D character → get it rigged and animated automatically. Hundreds of free animations (walk, run, shoot, die). | Free (Adobe account required) |
| **Unreal Marketplace (Free)** | https://www.unrealengine.com/marketplace/en-US/free | Free assets curated by Epic. Monthly free asset giveaways. Starter packs, environments, characters. | Free for UE5 projects |
| **Poly Haven** | https://polyhaven.com | Free HDRIs, textures, and 3D models. All CC0. Perfect for environment lighting and materials. | CC0 |

### How to Make 3D Maps (IronSight)

```
1. BLOCK OUT with BSP/Basic Shapes
   └── In Unreal Editor, use BSP brushes or basic cubes to rough out the map layout
   └── Test sightlines, cover positions, and movement flow with placeholder geometry
   └── This takes hours, not days — iterate fast

2. REPLACE with Real Assets
   └── Swap BSP blocks with Megascans/Marketplace assets
   └── Add walls, floors, crates, barrels, vehicles as cover
   └── Apply materials and textures from Quixel

3. LIGHTING
   └── UE5 Lumen handles global illumination automatically
   └── Place point lights, spotlights, and a directional sun
   └── Adjust time of day for mood

4. NAVIGATION MESH
   └── Add a NavMesh Bounds Volume covering the play area
   └── Build navigation mesh — this tells bots where they can walk
   └── Test bot pathfinding

5. GAMEPLAY ELEMENTS
   └── Place player starts, weapon spawns, health pickups
   └── Define team spawn zones
   └── Set up kill boundaries (out-of-map death zones)
```

---

## Project 3: Dominion (RTS Assets)

| Source | URL | Best For |
|--------|-----|---------|
| **Kenney RTS Assets** | https://kenney.nl/assets (search "RTS", "medieval") | Low-poly buildings, units, terrain |
| **Quaternius Medieval/Fantasy** | https://quaternius.com | Free medieval buildings, characters, nature packs |
| **OpenGameArt RTS** | https://opengameart.org (search "RTS", "strategy") | Top-down unit sprites, building sprites, terrain tiles |
| **Unreal Marketplace** | Free monthly packs | Environment assets, foliage, architecture |

---

## Sound & Music (All Projects)

| Source | URL | What You Get | License |
|--------|-----|-------------|---------|
| **Freesound.org** | https://freesound.org | Huge library of sound effects — gunshots, explosions, footsteps, UI clicks, ambient. Community contributed. | CC0, CC-BY (check each) |
| **Kenney Audio** | https://kenney.nl/assets/category:Audio | UI sounds, impact sounds, game sound effects. | CC0 |
| **BFXR / SFXR** | https://www.bfxr.net | Generate retro-style sound effects procedurally. Great for prototype placeholder sounds. | Generated (yours to use) |
| **Incompetech** | https://incompetech.com/music/ | Royalty-free music by Kevin MacLeod. Huge library of game-appropriate tracks. | CC-BY (attribution required) |
| **Freepd.com** | https://freepd.com | Public domain music. No attribution needed. | CC0 / Public Domain |
| **Itch.io Music** | https://itch.io/game-assets/free/tag-music | Free music loops and tracks. | Varies |

---

## Art Creation Tools (When You Need Custom Assets)

| Tool | URL | Cost | Best For |
|------|-----|------|---------|
| **Aseprite** | https://www.aseprite.org | $20 (or compile free from source) | Pixel art sprites and animations |
| **Krita** | https://krita.org | Free | Digital painting, concept art |
| **GIMP** | https://gimp.org | Free | Image editing, sprite sheets |
| **Blender** | https://blender.org | Free | 3D modeling, rigging, animation (Projects 2 & 3) |
| **Piskel** | https://www.piskelapp.com | Free (browser-based) | Quick pixel art, animated sprites |
| **Tiled** | https://www.mapeditor.org | Free | 2D map editor (alternative to Godot's built-in TileMap) |

---

## Asset Workflow Recommendations

**Phase 1 (Prototype):** Use Kenney assets exclusively. They're CC0, consistent in style, and comprehensive. Don't waste time hunting for perfect art — get gameplay working first.

**Phase 2 (Multiplayer):** Still use placeholder/free assets. Focus engineering effort on netcode, not art. Consider commissioning a small set of custom character sprites on Fiverr/ArtStation ($50–200) to establish your game's visual identity.

**Phase 3 (Launch):** Either commission a cohesive art set from a freelance artist, or curate a consistent set from free sources. Visual consistency matters more than visual quality — a game with a unified stick-figure style looks better than a game with mismatched "premium" assets.

---

*This document is a living artifact. Update it as decisions change, scope adjusts, and lessons are learned. The plan is the compass, not the terrain.*