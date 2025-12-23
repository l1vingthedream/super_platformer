# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Super Platformer is a 2D platformer game built with Godot Engine 4.5 (Mobile renderer). The game features a player character with movement, jumping, and animation mechanics in a platform environment.

## Running the Project

The project is opened and run through the Godot Engine editor:
- Open the project in Godot 4.5+
- The main scene is `res://scenes/main.tscn`
- Run the project using F5 or the Play button in the Godot editor

There are no command-line build/test/lint commands - all development is done through the Godot editor.

## Project Structure

```
scenes/           Scene files (.tscn)
  main.tscn      Main game scene with level layout
  player.tscn    Player character scene with animations
scripts/         GDScript files (.gd)
  player.gd      Player movement, physics, and animation logic
  camera.gd      Camera controller (horizontal follow, fixed vertical)
assets/sprites/  Sprite sheets and textures
  Playable_Characters_1P_2P.png  Player sprite sheet
  Tileset.png                    Ground/platform tile textures
```

## Architecture

### Scene Hierarchy
- **main.tscn** is the entry point containing:
  - Player instance (from player.tscn)
  - Camera2D with camera.gd script (sibling of Player, not child)
  - Ground and platform StaticBody2D nodes with shader-based tiled textures

### Player System
- **player.tscn**: CharacterBody2D with CollisionShape2D and AnimatedSprite2D
- **player.gd**: Physics-based movement controller with animation state machine
  - Constants: SPEED (300.0), JUMP_VELOCITY (-350.0), TURN_FRAMES (20)
  - Animations: idle, walk (4 frames), jump, turn
  - Turn detection uses persistent `last_move_direction` tracking (not velocity-based)
  - Sprite regions extracted via AtlasTexture from sprite sheet

### Camera System
- **camera.gd**: Follows player horizontally, locks ground to bottom of display
  - Calculates fixed Y position based on ground_bottom and viewport/zoom
  - Ground bottom locked at y=1032

### Tile Rendering
- Ground and platforms use ColorRect with ShaderMaterial for tiled textures
- Custom shader samples from Tileset.png atlas regions and tiles across rect size
- Shader uniforms: tile_offset, tile_size, rect_size, tileset

### Input Actions
Configured in project.godot under `[input]`:
- `move_left`: A, Left Arrow
- `move_right`: D, Right Arrow
- `jump`: Space, W, Up Arrow

### Physics Layers
Defined in project.godot under `[layer_names]`:
1. player
2. world
3. enemies
4. collectibles

### Rendering
- Viewport: 1280x720
- Camera zoom: 3.0
- Texture filtering: Nearest neighbor (pixel art style)
- Stretch mode: canvas_items
- Renderer: Mobile

## GDScript Conventions

- Scripts use `extends` to inherit from Godot node types
- Physics updates in `_physics_process(delta)` for frame-rate independent movement
- Use `ProjectSettings.get_setting()` for accessing project configuration
- Input actions accessed via `Input.is_action_*()` and `Input.get_axis()`
- Use `@onready` for node references that need scene tree access

## Working with Scenes

- Scene files (.tscn) are text-based Godot resource files
- Can edit .tscn directly for simple changes (positions, properties)
- Scenes can be instanced in other scenes using ExtResource
- Node UIDs are used for scene references (e.g., `uid://ckr8qw4nf4qoj`)
- AtlasTexture sub-resources define sprite regions from sprite sheets
