# Super Platformer - Implementation Plan

## Completed Features

- [x] Gravity, physics, jumping, falling, turning
- [x] Collision with level
- [x] Tileset
- [x] Background Images
- [x] Power-Up Boxes and Animation
- [x] Music
- [x] Block collisions
- [x] Pit dying
- [x] Sound Effects
- [x] Mushroom + Flower + Star + 1up + Coins
- [x] Mushroom Power-Up States + Animation in response to powerup collision
- [x] **Flagpole level completion** - Player collides with flag, slides down flagpole with sliding animation (different for big/small), flagpole sound plays, music stops, scene reloads
- [x] **Brick breaking for powered-up states** - Big/Fire/Invincible Mario breaks bricks into 4 fragments with physics-based parabolic motion, brick.wav sound, Small Mario bounces bricks
- [x] **Momentum-based walk/run system** - X button for running (like NES B button), gradual acceleration/deceleration, skidding when turning at high speed, reduced air control, momentum preservation for jumps
- [x] **Enemy sprites and animations** - Goomba (basic walker with squish) and Koopa Troopa (three-state FSM with shell mechanics, Green falls off ledges, Red detects ledges)
- [x] **Player-enemy collisions** - Player takes damage when colliding with enemy from left, bottom, or right sides; powered-up player shrinks to small with invulnerability, small player dies
- [x] **Enemy stomping** - Player jumps on enemy to defeat them, player bounces off slightly after stomp
- [x] **Fire flower powerup** - Powerup boxes with item_type="powerup" spawn mushroom for small Mario or animated fire flower for big Mario; flower uses 4-frame animation and stays stationary on top of box
- [x] **Fire Mario transformation and fireballs** - Big Mario collecting fire flower triggers 1-second palette swap transformation animation; Fire Mario shoots bouncing fireballs with X button (contextual: shoots when standing/jumping, runs when moving); fireballs defeat enemies on contact with poof explosion; 2-fireball limit; complete Fire Mario sprite set with throw animation
- [x] **Player lives system** - GameManager singleton tracks 3 starting lives; life screen displays before gameplay and after each death showing remaining lives with player name; game over screen on 0 lives resets game state; 1UP mushroom increases lives with 1up.wav sound; velocity-based skid animation system
- [x] **Title screen** - Title screen displays on game start with #9494FF background and title artwork; waits for jump button press before transitioning to life screen; game over returns to title screen; complete scene flow loop implemented
- [x] **HUD (Heads-Up Display)** - NES-style CanvasLayer HUD with player name (ROCCO), 6-digit score, animated coin counter, world display (1-1), and time countdown (400); manual sprite positioning with 1px letter spacing; two-line layout with labels and values; GameManager signals for real-time updates
- [x] **Points System** - Comprehensive scoring with combo multipliers: enemy stomps (100→200→400→800→1000→2000→4000→8000→1UP chain), power-ups (1000 pts), brick breaking (50 pts), height-based flagpole scoring (100-5000 pts); floating score labels spawn at action locations with upward tween and fade-out animation
- [x] **Score rewards for player actions** - Points awarded for: coins from question boxes (200 pts), enemy defeats via stomp or fireball, power-up collection, brick breaking; combo system tracks consecutive enemy stomps without touching ground; all score events update HUD in real-time via GameManager signals

## Pending Features
- [ ] Support for coin tiles (collectible coins placed in level)
- [ ] Support time left to complete level, with countdown displayed in HUD
- [ ] Use of Pipes to move to a different level
- [ ] Go to level 1-2
- [ ] Auto-create levels

## Notes

- Only implement one feature at a time for testing and bug fixing
- Always ask for sprites and tiles before implementing features that need them
- Test thoroughly after each feature implementation
- Do not push to GitHub unless explicitly prompted by the user
