# Stick Game RPG

A fast-paced 2D multiplayer side-scrolling shooter inspired by Mini Militia. Built with Godot 4 and Ruby on Rails.

## Quick Start

### Prerequisites
- [Godot 4.x](https://godotengine.org/download) (standard build for GDScript, .NET build NOT needed)
- [Ruby 3.x](https://www.ruby-lang.org/) + [Rails 7](https://rubyonrails.org/) (for backend, needed in Phase 2)
- [Git](https://git-scm.com/)
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code/overview) (your AI co-pilot)

### Getting Started
```bash
# Clone the repo
git clone <your-repo-url>
cd stick-game-rpg

# Open in Claude Code
claude

# Start your first session
# Type: "session start"
# Claude will read CLAUDE.md + docs/progress.md and guide you through Task 1.1.1
```

### Project Structure
```
stick-game-rpg/
├── CLAUDE.md          # Claude Code project memory (read automatically)
├── docs/              # Reference docs (load with @docs/filename.md)
│   ├── progress.md    # Task tracker — the single source of truth
│   ├── roadmap.md     # Full 3-project system design document
│   └── assets.md      # Free asset sources (future)
├── game/              # Godot project (created in Task 1.1.1)
├── backend/           # Rails API (created in Phase 2)
└── server/            # Headless server config (created in Phase 2)
```

## Development with Claude Code

This project is designed to be built with Claude Code as an AI pair programmer and project manager.

**Start a session:**
```
session start
```
Claude reads your progress, tells you what to work on, and provides implementation guidance.

**End a session:**
```
session end
```
Claude updates progress.md and previews next session's work.

**Get help on a specific task:**
```
Help me implement the jetpack system (task 1.1.3)
```

**Check progress:**
```
Show me current progress and timeline status
```

## License
TBD