package main

import "core:fmt"
import "core:math/linalg"

import rl "vendor:raylib"

WINDOW_WIDTH :: 800
WINDOW_HEIGHT :: 600

draw_things :: proc(game: ^Game) {
	iter := make_iterator(&game.things)
	for ref in next_thing(&iter) {
		sprite := get_sprite(game.things, ref)
		if sprite == .None {
			continue
		}
		pos := get_local_pos(game.things, ref)
		rl.DrawTextureRec(
			game.spritesheet,
			sprite_rect(sprite),
			{f32(i32(pos.x)), f32(i32(pos.y))},
			rl.WHITE,
		)
	}
}

Game :: struct {
	things:      Things,
	spritesheet: rl.Texture2D,
}

init_game :: proc(game: ^Game) -> bool {
	things := Things{}
	init_things(&things)
	game.things = things

	game.spritesheet = rl.LoadTexture("./data/sprites/spritesheet.png")
	if !rl.IsTextureValid(game.spritesheet) {
		fmt.eprintln("Failed to load data/sprites/spritesheet.png")
		return false
	}
	if game.spritesheet.width != i32(SPRITESHEET_COLUMNS * SPRITE_SIZE) ||
	   game.spritesheet.height != i32(SPRITESHEET_ROWS * SPRITE_SIZE) {
		fmt.eprintln("Spritesheet dimensions do not match the sprite grid")
		rl.UnloadTexture(game.spritesheet)
		game.spritesheet = {}
		return false
	}
	rl.SetTextureFilter(game.spritesheet, .POINT)

	// Add player
	{
		player_sprite := sprite_rect(.Player)
		player_ref := add_thing(&game.things, .Player)
		set_local_pos(
			&game.things,
			player_ref,
			{(f32(WINDOW_WIDTH) / 2) - (player_sprite.width / 2), f32(WINDOW_HEIGHT) - 100},
		)
		set_health(&game.things, player_ref, 100)
		set_sprite(&game.things, player_ref, .Player)
	}

	// Add initial aliens
	// Only 2 aliens to begin with
	{
		alien_ref := add_thing(&game.things, .Alien)
		set_local_pos(&game.things, alien_ref, {WINDOW_WIDTH / 4, 100})
		set_health(&game.things, alien_ref, 100)
		set_sprite(&game.things, alien_ref, .Alien)
	}

	{
		alien_ref := add_thing(&game.things, .Alien)
		set_local_pos(&game.things, alien_ref, {3 * (WINDOW_WIDTH / 4), 100})
		set_health(&game.things, alien_ref, 100)
		set_sprite(&game.things, alien_ref, .Alien)
	}

	// Add new weapon on the left side

	{
		laser_cannon_ref := add_thing(&game.things, .Laser_Cannon)
		set_local_pos(&game.things, laser_cannon_ref, {100, f32(WINDOW_HEIGHT) - 100})
		set_sprite(&game.things, laser_cannon_ref, .Laser_Cannon)
	}

	return true
}

update :: proc(game: ^Game) {

	// PLayer
	player_ref: Thing_Ref
	{
		iter := make_iterator(&game.things)
		for ref in next_thing(&iter) {
			kind := get_kind(game.things, ref)
			if kind == .Player {
				player_ref = ref
			}
		}
	}

	// Input
	if rl.IsKeyPressed(.SPACE) {

		player_sprite := sprite_rect(get_sprite(game.things, player_ref))
		bullet_sprite := sprite_rect(.Bullet)
		player_pos := get_local_pos(game.things, player_ref)

		bullet_ref := add_thing(&game.things, .Bullet)
		set_local_pos(
			&game.things,
			bullet_ref,
			{
				player_pos.x + (player_sprite.width - bullet_sprite.width) / 2,
				player_pos.y - bullet_sprite.height - 2,
			},
		)
		set_velocity(&game.things, bullet_ref, {0, -600})
		set_damage(&game.things, bullet_ref, 10)
		set_sprite(&game.things, bullet_ref, .Bullet)
	}

	if rl.IsKeyDown(.LEFT) {
		set_velocity(&game.things, player_ref, -{300, 0})
		player_velocity := get_velocity(game.things, player_ref)
	} else if rl.IsKeyDown(.RIGHT) {
		set_velocity(&game.things, player_ref, {300, 0})
	} else {
		set_velocity(&game.things, player_ref, {0, 0})
	}

	// Update entities position etc
	{
		iter := make_iterator(&game.things)
		for ref in next_thing(&iter) {

			should_be_removed := false

			// Update position
			velocity := get_velocity(game.things, ref)

			if linalg.length(velocity) > 0 {
				pos := get_local_pos(game.things, ref)
				new_pos := pos + velocity * rl.GetFrameTime()

				if new_pos.x > 0 &&
				   new_pos.x < WINDOW_WIDTH &&
				   new_pos.y > 0 &&
				   new_pos.y < WINDOW_HEIGHT {

					set_local_pos(&game.things, ref, new_pos)
				} else {
					should_be_removed = true
				}
			}

			// Check collisions
			// Check if player collids / intersects with a weapon, then it will pick it up
			ref_kind := get_kind(game.things, ref)
			ref_is_weapon :=
				ref_kind == .Laser_Cannon ||
				ref_kind == .Plasma_Cannon ||
				ref_kind == .Missile_Launcher
			if ref != player_ref && ref_is_weapon {
				player_pos := get_local_pos(game.things, player_ref)
				player_sprite_size := sprite_size(get_sprite(game.things, player_ref))
				player_rect := rl.Rectangle {
					player_pos.x,
					player_pos.y,
					player_sprite_size.x,
					player_sprite_size.y,
				}

				ref_pos := get_local_pos(game.things, ref)
				ref_sprite_size := sprite_size(get_sprite(game.things, ref))
				ref_rect := rl.Rectangle {
					ref_pos.x,
					ref_pos.y,
					ref_sprite_size.x,
					ref_sprite_size.y,
				}


				if rl.CheckCollisionRecs(player_rect, ref_rect) {

					// The player now equips the weapon
					// This means that it has to be attached to the player ref.
					// The weapon thing should not exist anymore and rather be in the
					// "weapon inventory" of the player. So the thing needs to exist,
					// but not in the world as it does now.
					// What are options here now?
					// Attach the thing to the player, move it off screen and make it
					// not visible?
					// Or is it better to remove the thing, and add a new thing off screen
					// that is the same, but is also attached to the player?

					rl.DrawRectangleRec(ref_rect, rl.LIME)

					attach_child(&game.things, player_ref, ref)
				}

			}

			// NOTE(Thomas): Important that removing a thing that should be removed happens at the end.
			if should_be_removed {
				remove_thing(&game.things, ref)
			}
		}
	}


}

main :: proc() {

	rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "Definitely Not Asteroids")
	defer rl.CloseWindow()

	rl.SetWindowState({.WINDOW_RESIZABLE})
	rl.SetTargetFPS(60)

	game: Game
	if !init_game(&game) {
		return
	}
	defer rl.UnloadTexture(game.spritesheet)

	for !rl.WindowShouldClose() {
		// Update
		if rl.IsKeyPressed(.CAPS_LOCK) {
			break
		}

		update(&game)

		// Draw
		rl.BeginDrawing()
		rl.ClearBackground(rl.BLACK)

		draw_things(&game)

		rl.EndDrawing()
	}
}
