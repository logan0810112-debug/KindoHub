# KindoHub - Universal Roblox Executor

KindoHub is a modular, production-grade Roblox executor script featuring a dynamic game detection engine, a local cryptographic key system, and a cyberpunk-themed UI.

## Features
- **Modular Architecture:** Clean separation of Core, UI, Detection, and Features.
- **Local Key System:** Generates unique keys based on Device ID and Daily Rotation.
- **Game Detection:** Identifies 100+ popular games and auto-loads relevant features.
- **Universal Aimbot:** CFrame-based target locking with FOV and Triggerbot.
- **Cyberpunk UI:** Dark mode, neon accents, draggable, and responsive.

## Project Structure
- `src/main.lua`: Entry point and initialization.
- `src/core.lua`: Global state, utilities, and logging.
- `src/database.lua`: Game profiles and feature metadata.
- `src/engine.lua`: Combat logic (Aimbot, Triggerbot) and movement.
- `src/ui.lua`: The Cyberpunk-themed interface.
- `src/key_system.lua`: Cryptographic key generation and validation.
- `assets/keys.json`: Master keys and premium tier definitions.

## How to Run
1. Open your preferred executor (Delta, Synapse, RoProxy).
2. Load `src/main.lua`.
3. Execute.
4. Enter the generated key when prompted.