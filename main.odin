package main

import "core:fmt"

import rl "vendor:raylib"

WINDOW_WIDTH :: 800
WINDOW_HEIGHT :: 600

draw_things :: proc(things: Things) {
	for i in 1 ..< MAX_THINGS {
		if things.used[i] {
			rl.DrawTexture(
				things.things[i].texture,
				i32(things.things[i].pos.x),
				i32(things.things[i].pos.y),
				rl.WHITE,
			)
		}
	}
}

main :: proc() {

	things := Things{}
	init_things(&things)

	rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "Definitely Not Asteroids")

	rl.SetWindowState({.WINDOW_RESIZABLE})
	rl.SetTargetFPS(60)

	// Player
	player_sprite := rl.LoadTexture("./data/sprites/player_ship.png")
	player_ref := add_thing(&things, .Player)
	player := get_thing(&things, player_ref)
	player.pos = {
		(f32(WINDOW_WIDTH) / 2) - (f32(player_sprite.width) / 2),
		f32(WINDOW_HEIGHT) - 100,
	}
	player.health = 100
	player.texture = player_sprite

	// Bullet
	bullet_sprite := rl.LoadTexture("./data/sprites/bullet.png")
	bullet_ref := add_thing(&things, .Bullet)
	bullet := get_thing(&things, bullet_ref)
	bullet.pos = {
		(f32(WINDOW_WIDTH) / 2) - (f32(player_sprite.width) / 2),
		f32(WINDOW_HEIGHT) - 150,
	}
	bullet.damage = 10
	bullet.texture = bullet_sprite

	for !rl.WindowShouldClose() {
		// Update
		if rl.IsKeyPressed(.CAPS_LOCK) {
			break
		}

		// Draw
		rl.BeginDrawing()
		rl.ClearBackground(rl.BLACK)

		draw_things(things)

		rl.EndDrawing()
	}

	rl.CloseWindow()


}
