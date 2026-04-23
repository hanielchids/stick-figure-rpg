# Stick Game RPG — 2D Multiplayer Shooter (Mini Militia Clone)

## Project Overview
Stick Game RPG is a fast-paced 2D side-scrolling multiplayer shooter with jetpack movement, multiple weapons, and online multiplayer. Built in Godot 4 with a Rails API backend. Desktop-first (Windows + Mac).

## Tech Stack
- **Game Client/Server:** Godot 4.x (GDScript + C++ via GDExtension for hot paths)
- **Backend API:** Ruby on Rails 7 (API mode) + PostgreSQL + Redis + Sidekiq
- **Networking:** ENet (UDP), server-authoritative with client-side prediction
- **Lobby Real-time:** ActionCable (WebSocket)

## Architecture Rules
- Game simulation code (physics, hit detection, netcode) → C++ via GDExtension when performance-critical, GDScript otherwise
- Backend services (auth, lobbies, stats, leaderboard) → Rails. Do NOT write these in C++.
- Server is authoritative. Client predicts locally, server reconciles. Never trust the client.
- Weapon definitions are data-driven (JSON/Resource files). No hardcoded weapon stats in code.
- All networking packets use binary serialization, NOT JSON.

## Project Structure
```
stick-game-rpg/
├── CLAUDE.md              # This file (loaded every session)
├── .claude/rules/
│   └── gdscript-standards.md  # GDScript typing & quality rules (auto-loaded for .gd files)
├── docs/
│   ├── architecture.md    # Full system design & data flow
│   ├── progress.md        # Task tracker with checkboxes
│   ├── roadmap.md         # Full 3-project roadmap
│   └── assets.md          # Free asset sources guide
├── game/                  # Godot project
│   ├── project.godot
│   ├── src/
│   │   ├── player/        # Player controller, jetpack, input
│   │   ├── combat/        # Weapons, health, damage, pickups
│   │   ├── ai/            # Bot behavior trees
│   │   ├── networking/    # Client/server, packets, prediction, interpolation
│   │   ├── maps/          # Map scenes, spawn points, pickup spawners
│   │   ├── ui/            # HUD, menus, scoreboard, settings
│   │   └── core/          # Game state manager, event bus, constants
│   ├── assets/            # Sprites, sounds, tilesets
│   ├── addons/            # GDExtension C++ modules
│   └── export/            # Export presets for Win/Mac
├── backend/               # Rails API
│   ├── app/
│   │   ├── controllers/api/v1/
│   │   ├── models/
│   │   ├── channels/      # ActionCable (lobby, matchmaking)
│   │   └── jobs/          # Sidekiq (matchmaking worker)
│   ├── db/
│   │   └── migrate/
│   └── config/
└── server/                # Godot headless server config & scripts
```

## Code Style
- GDScript: Follow official GDScript style guide. snake_case for functions/variables, PascalCase for classes.
- **CRITICAL: All GDScript code MUST use explicit static types.** NEVER use `:=` with function calls, math ops, or method returns. Write `var x: float = atan2(y, x)` NOT `var x := atan2(y, x)`. See `.claude/rules/gdscript-standards.md` for full rules.
- C++ (GDExtension): Google C++ style guide. Use smart pointers. Header guards with #pragma once.
- Rails: Standard Rails conventions. Rubocop with default config. Thin controllers, fat models.
- Naming: All networking packets prefixed with `Pkt` (e.g., `PktInput`, `PktSnapshot`).
- Signals: Use Godot signals for decoupled communication. Name pattern: `noun_verbed` (e.g., `player_died`, `weapon_picked_up`).

## Current Phase
Check `@docs/progress.md` for exact task status.

## Commands
- Run game: `cd game && godot --path .`
- Run server headless: `cd game && godot --path . --headless --server`
- Run backend: `cd backend && bin/rails server`
- Run tests (game): `cd game && godot --headless --script res://tests/run_tests.gd`
- Run tests (backend): `cd backend && bin/rails test`
- Export Windows: `cd game && godot --headless --export-release "Windows Desktop"`
- Export Mac: `cd game && godot --headless --export-release "macOS"`

## Session Protocol
When I say "session start":
1. Read `@docs/progress.md` for current status
2. Tell me what's done, what's next, and what to work on today (2-3 tasks)
3. Give me guidance for the first task

When I say "session end":
1. Update `@docs/progress.md` with what was completed
2. Note any issues or blockers
3. Preview next session's work