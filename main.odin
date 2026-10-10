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
		pos := get_pos(game.things, ref)
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
		set_pos(
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
		set_pos(&game.things, alien_ref, {WINDOW_WIDTH / 4, 100})
		set_health(&game.things, alien_ref, 100)
		set_sprite(&game.things, alien_ref, .Alien)
	}

	{
		alien_ref := add_thing(&game.things, .Alien)
		set_pos(&game.things, alien_ref, {3 * (WINDOW_WIDTH / 4), 100})
		set_health(&game.things, alien_ref, 100)
		set_sprite(&game.things, alien_ref, .Alien)
	}
	return true
}

update :: proc(game: ^Game) {
	// Update entities position etc
	{
		iter := make_iterator(&game.things)
		for ref in next_thing(&iter) {
			velocity := get_velocity(game.things, ref)

			if linalg.length(velocity) > 0 {
				pos := get_pos(game.things, ref)
				new_pos := pos + velocity * rl.GetFrameTime()

				if new_pos.x > 0 &&
				   new_pos.x < WINDOW_WIDTH &&
				   new_pos.y > 0 &&
				   new_pos.y < WINDOW_HEIGHT {

					set_pos(&game.things, ref, new_pos)
				} else {
					remove_thing(&game.things, ref)
				}
			}
		}
	}

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
		player_pos := get_pos(game.things, player_ref)

		bullet_ref := add_thing(&game.things, .Bullet)
		set_pos(
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
