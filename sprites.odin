package main

import rl "vendor:raylib"

SPRITE_SIZE :: 32
BULLET_WIDTH :: 6
BULLET_HEIGHT :: 12
SPRITESHEET_COLUMNS :: 3
SPRITE_COUNT :: int(Sprite_ID.Missile)
SPRITESHEET_ROWS :: (SPRITE_COUNT + SPRITESHEET_COLUMNS - 1) / SPRITESHEET_COLUMNS

// Row order matches scripts/build_spritesheet.lua.
Sprite_ID :: enum {
	None,
	Player,
	Bullet,
	Alien,
	Laser_Cannon,
	Plasma_Cannon,
	Missile_Launcher,
	Laser_Bolt,
	Plasma_Orb,
	Missile,
}

sprite_rect :: proc(sprite: Sprite_ID) -> rl.Rectangle {
	assert(sprite != .None, "Cannot draw an unset sprite")
	index := int(sprite) - 1
	rect := rl.Rectangle {
		f32((index % SPRITESHEET_COLUMNS) * SPRITE_SIZE),
		f32((index / SPRITESHEET_COLUMNS) * SPRITE_SIZE),
		SPRITE_SIZE,
		SPRITE_SIZE,
	}
	// The bullet is centered in its cell, crop to its named Aseprite slice.
	if sprite == .Bullet {
		rect.x += (SPRITE_SIZE - BULLET_WIDTH) / 2
		rect.y += (SPRITE_SIZE - BULLET_HEIGHT) / 2
		rect.width = BULLET_WIDTH
		rect.height = BULLET_HEIGHT
	}
	return rect
}
