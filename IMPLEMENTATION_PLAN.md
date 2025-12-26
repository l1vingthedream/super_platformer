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

## Pending Features

- [ ] Support brick tiles breaking apart when Player is big, fire, or invincible
- [ ] Support for player moving at a regular speed, and then speeding up when pressing a "speedup" button, like the B button on NES
- [ ] Create enemy sprites and their animation
- [ ] Support Player dying when colliding with enemy from enemy's left, bottom, and right sides
- [ ] Support Player killing enemy sprite when player jumps on top of enemy sprite. When player hops on enemy, player should bounce off slightly
- [ ] Support for powerup box containing animated fire-flower when player is already big
- [ ] Support for Fireball Power-Up Animation
- [ ] Support for Player Fireball when pressing the same "speedup" button, like B button on NES
- [ ] Support for Player killing Enemies when fireball collides with enemy
- [ ] Support for Points System
- [ ] Support for increasing Points when Player earns coins through coin-containing box, or collides with coin tiles, or enemy kills
- [ ] Player lives system, starting with 3 lives, and increasing lives
- [ ] Support HUD that contains points, lives
- [ ] Support time left to complete level, with countdown displayed in HUD
- [ ] Title screen
- [ ] Use of Pipes to move to a different level
- [ ] Go to level 1-2
- [ ] Auto-create levels

## Notes

- Only implement one feature at a time for testing and bug fixing
- Always ask for sprites and tiles before implementing features that need them
- Test thoroughly after each feature implementation
