package main

import "core:fmt"

import rl "vendor:raylib"

WINDOW_WIDTH :: 800
WINDOW_HEIGHT :: 600

main :: proc() {

	things := Things{}
	init_things(&things)

	player_ref := add_thing(&things, .Player)

	fmt.println("player_ref: ", player_ref)

	remove_thing(&things, player_ref)

	player_ref = add_thing(&things, .Player)

	fmt.println("player_ref: ", player_ref)

	// Mutating the things behind player_ref
	get_thing(&things, player_ref).health = 4

	fmt.println("things after mutating: ", things)


	rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "Definititely Not Asteroids")

	rl.SetWindowState({.WINDOW_RESIZABLE})
	rl.SetTargetFPS(60)

	for !rl.WindowShouldClose() {
		// Update
		if rl.IsKeyPressed(.CAPS_LOCK) {
			break
		}

		// Draw
		rl.BeginDrawing()
		rl.ClearBackground(rl.BLACK)

		rl.EndDrawing()
	}

	rl.CloseWindow()


}
