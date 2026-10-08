package main

import "core:fmt"
import "core:math/linalg"

import rl "vendor:raylib"

WINDOW_WIDTH :: 800
WINDOW_HEIGHT :: 600

draw_things :: proc(things: ^Things) {
	iter := make_iterator(things)
	for ref in next_thing(&iter) {
		pos := get_pos(things^, ref)
		rl.DrawTexture(get_texture(things^, ref), i32(pos.x), i32(pos.y), rl.WHITE)
	}
}

main :: proc() {

	things := Things{}
	init_things(&things)

	rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "Definitely Not Asteroids")

	rl.SetWindowState({.WINDOW_RESIZABLE})
	rl.SetTargetFPS(60)

	// Loading sprites
	player_sprite := rl.LoadTexture("./data/sprites/player_ship.png")
	bullet_sprite := rl.LoadTexture("./data/sprites/bullet.png")

	// Player
	{
		player_ref := add_thing(&things, .Player)
		set_pos(
			&things,
			player_ref,
			{(f32(WINDOW_WIDTH) / 2) - (f32(player_sprite.width) / 2), f32(WINDOW_HEIGHT) - 100},
		)
		set_health(&things, player_ref, 100)
		set_texture(&things, player_ref, player_sprite)
	}

	for !rl.WindowShouldClose() {
		// Update
		if rl.IsKeyPressed(.CAPS_LOCK) {
			break
		}

		player_ref: Thing_Ref
		{
			iter := make_iterator(&things)
			for ref in next_thing(&iter) {
				kind := get_kind(things, ref)
				if kind == .Player {
					player_ref = ref
				}

			}
		}

		// Input
		if rl.IsKeyPressed(.SPACE) {

			bullet_ref := add_thing(&things, .Bullet)

			player_texture := get_texture(things, player_ref)
			set_pos(
				&things,
				bullet_ref,
				{
					(f32(WINDOW_WIDTH) / 2) - (f32(player_texture.width) / 2),
					f32(WINDOW_HEIGHT) - 150,
				},
			)
			set_velocity(&things, bullet_ref, {0, -600})
			set_damage(&things, bullet_ref, 10)
			set_texture(&things, bullet_ref, bullet_sprite)
		}


		// Update
		{
			iter := make_iterator(&things)
			for ref in next_thing(&iter) {
				velocity := get_velocity(things, ref)

				if linalg.length(velocity) > 0 {
					pos := get_pos(things, ref)
					new_pos := pos + velocity * rl.GetFrameTime()

					if new_pos.x > 0 &&
					   new_pos.x < WINDOW_WIDTH &&
					   new_pos.y > 0 &&
					   new_pos.y < WINDOW_HEIGHT {

						set_pos(&things, ref, new_pos)
					} else {
						remove_thing(&things, ref)
					}
				}
			}
		}

		// Draw
		rl.BeginDrawing()
		rl.ClearBackground(rl.BLACK)

		draw_things(&things)

		rl.EndDrawing()
	}

	rl.CloseWindow()
}
