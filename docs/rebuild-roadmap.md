# Irdeni Web Rebuild Roadmap

## Vision

Bring the original QuickBasic game back to life on the web without rewriting the content by hand.
The web version should preserve:

- the original sprite sheets
- the original map layouts
- the original event logic and branching
- the original battle flow and stat formulas

The web version should also feel native in a browser:

- fullscreen-friendly on desktop and tablet
- landscape-first on mobile
- wide mobile presentation with touch controls
- deployable as a static site on GitHub Pages

## Source Of Truth

Use these files as the canonical baseline:

- `d_irdeni/IRDENI.BAS`
- `d_irdeni/map/`
- `d_irdeni/event.dat`
- `d_irdeni/save/`

Fallback content can be recovered from:

- `d_irdeni/Sicherheitsordner/`

Known rescued asset so far:

- `wueste.map`

## Architecture

### 1. Content Pipeline

Build-time scripts should extract and normalize original content into web-friendly JSON and copied assets:

- maps from `d_irdeni/map/*.MAP`
- recovered maps from `d_irdeni/Sicherheitsordner/*.MAP`
- event blocks from `d_irdeni/event.dat`
- BMP sprite sheets and screens from `d_irdeni/*.bmp`

This keeps the React app tied to the real original content instead of duplicated data files.

### 2. Game Core

The gameplay runtime should be framework-agnostic and deterministic.
It should own:

- player state
- map state
- inventory and equipment
- event execution
- combat formulas
- save/load serialization

### 3. Renderer

Canvas should render a fixed 320x200 virtual frame and scale it with integer zoom when possible.
Renderer responsibilities:

- tile and sprite drawing
- camera centering
- animation frames
- HUD framing
- fullscreen scaling
- touch-friendly layout adaptation

### 4. React Shell

React should own browser-facing UI:

- title and load screens
- dialogue shell
- inventory and shops
- save slot management
- fullscreen toggle
- mobile touch controls
- orientation prompts

## Milestones

### Milestone 1: Foundation

- Scaffold Vite + React + TypeScript app
- Add GitHub Pages build config
- Add content extraction script
- Render original `HEIMAP` with original BMP sheets
- Support keyboard movement
- Add fullscreen button
- Add mobile landscape shell and touch movement

### Milestone 2: Exploration Parity

- Port movement rules from `IRDENI.BAS`
- Add event tile detection
- Add text boxes and multi-page text flow
- Add map transitions
- Preserve outside-tile rendering
- Add start screen and avatar selection

### Milestone 3: Systems Parity

- Port inventory and equipment logic
- Port item use rules
- Port shop and sell events
- Port journal/almanac behavior
- Add IndexedDB save slots

### Milestone 4: Combat Parity

- Port battle map loading
- Port enemy spawning and turn pacing
- Port combat formulas and rewards
- Preserve post-battle terrain/event mutation

### Milestone 5: Release Readiness

- Add regression fixtures for maps and events
- Add content validation checks
- Add responsive polish for landscape phones
- Tune fullscreen and safe-area handling
- Prepare GitHub Pages deployment workflow

## Mobile And Fullscreen Rules

These are hard requirements for the rebuild:

- gameplay remains on a fixed virtual canvas
- art is never stretched non-uniformly
- mobile portrait shows a rotate prompt
- mobile landscape is the primary phone experience
- touch controls remain outside the core canvas when space allows
- browser UI and notches are handled with `safe-area-inset-*`

## Current Status

The first implementation slice now includes:

- a React app scaffold in `web/`
- a build-time extractor for maps, events, and BMP assets
- a retro canvas viewport that renders the original `HEIMAP`
- fullscreen-ready and mobile-landscape-aware shell styling
