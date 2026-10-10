package main

import "core:fmt"
import "core:math/linalg"

import rl "vendor:raylib"

WINDOW_WIDTH :: 800
WINDOW_HEIGHT :: 600

MAX_SPRITES :: 8

draw_things :: proc(things: ^Things) {
	iter := make_iterator(things)
	for ref in next_thing(&iter) {
		pos := get_pos(things^, ref)
		rl.DrawTexture(get_texture(things^, ref), i32(pos.x), i32(pos.y), rl.WHITE)
	}
}

Game :: struct {
	things:  Things,
	sprites: [MAX_SPRITES]rl.Texture2D,
}

PLAYER_SPRITE_IDX :: 0
BULLET_SPRITE_IDX :: 1
ALIEN_SPRITE_IDX :: 2

init_game :: proc(game: ^Game) {
	things := Things{}
	init_things(&things)
	game.things = things

	// Loading sprites
	game.sprites[PLAYER_SPRITE_IDX] = rl.LoadTexture("./data/sprites/player_ship.png")
	game.sprites[BULLET_SPRITE_IDX] = rl.LoadTexture("./data/sprites/bullet.png")
	game.sprites[ALIEN_SPRITE_IDX] = rl.LoadTexture("./data/sprites/alien.png")

	// Add player
	{
		player_ref := add_thing(&game.things, .Player)
		set_pos(
			&game.things,
			player_ref,
			{
				(f32(WINDOW_WIDTH) / 2) - (f32(game.sprites[PLAYER_SPRITE_IDX].width) / 2),
				f32(WINDOW_HEIGHT) - 100,
			},
		)
		set_health(&game.things, player_ref, 100)
		set_texture(&game.things, player_ref, game.sprites[PLAYER_SPRITE_IDX])
	}

	// Add initial aliens
	// Only 2 aliens to begin with
	{
		alien_ref := add_thing(&game.things, .Alien)
		set_pos(&game.things, alien_ref, {WINDOW_WIDTH / 4, 100})
		set_health(&game.things, alien_ref, 100)
		set_texture(&game.things, alien_ref, game.sprites[ALIEN_SPRITE_IDX])
	}

	{
		alien_ref := add_thing(&game.things, .Alien)
		set_pos(&game.things, alien_ref, {3 * (WINDOW_WIDTH / 4), 100})
		set_health(&game.things, alien_ref, 100)
		set_texture(&game.things, alien_ref, game.sprites[ALIEN_SPRITE_IDX])
	}


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

		player_texture := get_texture(game.things, player_ref)
		player_pos := get_pos(game.things, player_ref)

		bullet_ref := add_thing(&game.things, .Bullet)
		set_pos(
			&game.things,
			bullet_ref,
			{player_pos.x, player_pos.y - (f32(player_texture.height) / 2 + 10)},
		)
		set_velocity(&game.things, bullet_ref, {0, -600})
		set_damage(&game.things, bullet_ref, 10)
		set_texture(&game.things, bullet_ref, game.sprites[BULLET_SPRITE_IDX])
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

	rl.SetWindowState({.WINDOW_RESIZABLE})
	rl.SetTargetFPS(60)

	game: Game
	init_game(&game)

	for !rl.WindowShouldClose() {
		// Update
		if rl.IsKeyPressed(.CAPS_LOCK) {
			break
		}

		update(&game)

		// Draw
		rl.BeginDrawing()
		rl.ClearBackground(rl.BLACK)

		draw_things(&game.things)

		rl.EndDrawing()
	}

	rl.CloseWindow()
}
