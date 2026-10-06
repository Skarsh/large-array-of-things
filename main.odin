package main

import "core:fmt"

import rl "vendor:raylib"

WINDOW_WIDTH :: 800
WINDOW_HEIGHT :: 600

// TODO(Thomas): Should not directly access things[i] like this, should
// probably go through a ref and get?
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

	// Loading sprites
	player_sprite := rl.LoadTexture("./data/sprites/player_ship.png")
	bullet_sprite := rl.LoadTexture("./data/sprites/bullet.png")

	{
		// Player
		player_ref := add_thing(&things, .Player)
		player := get_thing(&things, player_ref)
		player.pos = {
			(f32(WINDOW_WIDTH) / 2) - (f32(player_sprite.width) / 2),
			f32(WINDOW_HEIGHT) - 100,
		}
		player.health = 100
		player.texture = player_sprite

	}

	for !rl.WindowShouldClose() {
		// Update
		if rl.IsKeyPressed(.CAPS_LOCK) {
			break
		}

		// TODO(Thomas): Very bad, but it does the trick.
		// This pattern seems to appear over and over, and for input
		// stuff, like shooting a bullet the player thing, or at least a way
		// to retrieve properties from the player is needed, .e.g the position of the player
		// so that we can know where to spawn bullets etc.
		// TODO(Thomas): Should not directly access things[i] like this, should
		// probably go through a ref and get?
		player: Thing
		for i in 1 ..< MAX_THINGS {
			if things.used[i] {
				thing := things.things[i]
				if thing.kind == .Player {
					player = thing
				}
			}
		}


		// Input
		if rl.IsKeyPressed(.SPACE) {
			bullet_ref := add_thing(&things, .Bullet)
			bullet := get_thing(&things, bullet_ref)
			bullet.pos = {
				(f32(WINDOW_WIDTH) / 2) - (f32(player.texture.width) / 2),
				f32(WINDOW_HEIGHT) - 150,
			}
			bullet.velocity = {0, -600}
			bullet.damage = 10
			bullet.texture = bullet_sprite
		}


		// Update
		// TODO(Thomas): Should not directly access things[i] like this, should
		// probably go through a ref and get?
		for i in 1 ..< MAX_THINGS {
			if things.used[i] {

				things.things[i].pos += things.things[i].velocity * rl.GetFrameTime()


				// Remove the thing from the things array here, since it is out of bounds.
				if things.things[i].pos.y < 0 || things.things[i].pos.y > WINDOW_HEIGHT {

				}

			}
		}

		// Draw
		rl.BeginDrawing()
		rl.ClearBackground(rl.BLACK)

		draw_things(things)

		rl.EndDrawing()
	}

	rl.CloseWindow()


}
