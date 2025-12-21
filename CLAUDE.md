# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Super Platformer is a 2D platformer game built with Godot Engine 4.5 (Mobile renderer). The game features a player character with movement and jumping mechanics in a simple platform environment.

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
  player.tscn    Player character scene
scripts/         GDScript files (.gd)
  player.gd      Player movement and physics logic
assets/          Game assets
  sprites/       Sprite sheets and textures
project.godot    Godot project configuration
```

## Architecture

### Scene Hierarchy
- **main.tscn** is the entry point scene containing:
  - Player instance (from player.tscn)
  - Camera2D (attached to player for following)
  - Ground and platform StaticBody2D nodes for level geometry

### Player System
- **player.tscn**: CharacterBody2D node with CollisionShape2D and Sprite2D
- **player.gd**: Physics-based movement controller
  - Uses Godot's built-in physics (CharacterBody2D with move_and_slide)
  - Gravity is pulled from project physics settings
  - Constants: SPEED (300.0) and JUMP_VELOCITY (-600.0)
  - Input handled through Godot's Input system with action mapping

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
- Texture filtering: Nearest neighbor (pixel art style)
- Stretch mode: canvas_items
- Renderer: Mobile

## GDScript Conventions

- Scripts use `extends` to inherit from Godot node types
- Physics updates in `_physics_process(delta)` for frame-rate independent movement
- Use `ProjectSettings.get_setting()` for accessing project configuration
- Input actions defined in project settings, accessed via `Input.is_action_*()` methods

## Working with Scenes

- Scene files (.tscn) are text-based Godot resource files
- Prefer editing scenes in the Godot editor rather than directly modifying .tscn files
- Scenes can be instanced (referenced) in other scenes using ExtResource
- Node UIDs are used for scene references (e.g., `uid://ckr8qw4nf4qoj`)
