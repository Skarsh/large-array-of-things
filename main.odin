package main

import "core:fmt"
import "core:math/linalg"

import rl "vendor:raylib"

WINDOW_WIDTH :: 800
WINDOW_HEIGHT :: 600

WEAPON_OFFSET :: Vec2{0, -8}

MAX_SOUNDS :: 16

draw_things :: proc(game: ^Game) {
	iter := make_iterator(&game.things)
	for ref in next_thing(&iter) {
		sprite := get_sprite(game.things, ref)
		if sprite == .None {
			continue
		}
		pos := get_world_pos(game.things, ref)
		flags := get_flags(game.things, ref)
		if .Hidden not_in flags {
			rl.DrawTextureRec(
				game.spritesheet,
				sprite_rect(sprite),
				{f32(i32(pos.x)), f32(i32(pos.y))},
				rl.WHITE,
			)
		}
	}
}

Weapon_Def :: struct {
	sprite_id:       Sprite_ID,
	sound_idx:       int,
	projectile_kind: Kind,
}

weapon_defs: [Kind]Weapon_Def = #partial {
	.Machine_Gun = {sprite_id = .Machine_Gun, sound_idx = 0, projectile_kind = .Bullet},
	.Laser_Cannon = {sprite_id = .Laser_Cannon, sound_idx = 1, projectile_kind = .Laser_Bolt},
	.Plasma_Cannon = {sprite_id = .Plasma_Cannon, sound_idx = 2, projectile_kind = .Plasma_Orb},
	.Missile_Launcher = {sprite_id = .Missile_Launcher, sound_idx = 3, projectile_kind = .Missile},
}

Projectile_Def :: struct {
	velocity:  Vec2,
	sprite_id: Sprite_ID,
	damage:    f32,
}

projectile_defs: [Kind]Projectile_Def = #partial {
	.Bullet = {velocity = {0, -600}, sprite_id = .Bullet, damage = 10},
	.Laser_Bolt = {velocity = {0, -1200}, sprite_id = .Laser_Bolt, damage = 15},
	.Plasma_Orb = {velocity = {0, -400}, sprite_id = .Plasma_Orb, damage = 20},
	.Missile = {velocity = {0, -800}, sprite_id = .Missile, damage = 30},
}

Game :: struct {
	things:                   Things,
	spritesheet:              rl.Texture2D,
	player_ref:               Thing_Ref,
	player_active_weapon_ref: Thing_Ref,
	weapon_sounds:            [MAX_SOUNDS]rl.Sound,
}

cycle_weapon :: proc(game: ^Game) {
	// Next weapon is just the next sibling of the current active weapon
	next_sib := get_next_sibling(game.things, game.player_active_weapon_ref)
	switch_weapon(game, next_sib)
}

switch_weapon :: proc(game: ^Game, weapon_ref: Thing_Ref) {
	weapon_ref_parent := get_parent(game.things, weapon_ref)

	// The player is the parent, so this is a valid ref
	assert(weapon_ref_parent == game.player_ref)

	add_flag(&game.things, game.player_active_weapon_ref, .Hidden)
	game.player_active_weapon_ref = weapon_ref
	remove_flag(&game.things, game.player_active_weapon_ref, .Hidden)
}

spawn_alien :: proc(game: ^Game, pos: Vec2) {
	alien_ref := add_thing(&game.things, .Alien)
	set_local_pos(&game.things, alien_ref, pos)
	set_health(&game.things, alien_ref, 100)
	set_sprite(&game.things, alien_ref, .Alien)
}

spawn_weapon :: proc(game: ^Game, kind: Kind, pos: Vec2) {
	assert(is_weapon(kind))

	weapon_ref := add_thing(&game.things, kind)
	set_local_pos(&game.things, weapon_ref, pos)
	set_sprite(&game.things, weapon_ref, weapon_defs[kind].sprite_id)
}

spawn_projectile :: proc(game: ^Game) {
	weapon_kind := get_kind(game.things, game.player_active_weapon_ref)

	projectile_kind := weapon_defs[weapon_kind].projectile_kind
	projectile_sprite_rect := sprite_rect(projectile_defs[projectile_kind].sprite_id)
	projectile_ref := add_thing(&game.things, projectile_kind)
	projectile_sprite := projectile_defs[projectile_kind].sprite_id
	projectile_velocity := projectile_defs[projectile_kind].velocity
	projectile_damage := projectile_defs[projectile_kind].damage
	rl.PlaySound(game.weapon_sounds[weapon_defs[weapon_kind].sound_idx])

	player_sprite := sprite_rect(get_sprite(game.things, game.player_ref))
	player_pos := get_world_pos(game.things, game.player_ref)

	set_local_pos(
		&game.things,
		projectile_ref,
		{
			player_pos.x + (player_sprite.width - projectile_sprite_rect.width) / 2,
			player_pos.y - projectile_sprite_rect.height - 2,
		},
	)
	set_velocity(&game.things, projectile_ref, projectile_velocity)
	set_damage(&game.things, projectile_ref, projectile_damage)
	set_sprite(&game.things, projectile_ref, projectile_sprite)

}

is_weapon :: proc(kind: Kind) -> bool {
	return(
		kind == .Machine_Gun ||
		kind == .Laser_Cannon ||
		kind == .Plasma_Cannon ||
		kind == .Missile_Launcher \
	)
}

init_game :: proc(game: ^Game) -> bool {
	things := Things{}
	init_things(&things)
	game.things = things


	// Textures
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


	// Sounds
	game.weapon_sounds[weapon_defs[.Machine_Gun].sound_idx] = rl.LoadSound(
		"data/sounds/weapons/machine_gun_fire.wav",
	)
	game.weapon_sounds[weapon_defs[.Laser_Cannon].sound_idx] = rl.LoadSound(
		"data/sounds/weapons/laser_cannon_fire.wav",
	)
	game.weapon_sounds[weapon_defs[.Plasma_Cannon].sound_idx] = rl.LoadSound(
		"data/sounds/weapons/plasma_cannon_fire.wav",
	)
	game.weapon_sounds[weapon_defs[.Missile_Launcher].sound_idx] = rl.LoadSound(
		"data/sounds/weapons/missile_launcher_fire.wav",
	)


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

		game.player_ref = player_ref

		// Machine gun
		machine_gun_sprite := sprite_rect(.Machine_Gun)
		machine_gun_ref := add_thing(&game.things, .Machine_Gun)
		set_sprite(&game.things, machine_gun_ref, .Machine_Gun)

		attach_child(&game.things, player_ref, machine_gun_ref)
		set_local_pos(&game.things, machine_gun_ref, WEAPON_OFFSET)
		game.player_active_weapon_ref = machine_gun_ref
	}

	// Add initial aliens
	// Only 2 aliens to begin with
	spawn_alien(game, {WINDOW_WIDTH / 4, 100})
	spawn_alien(game, {3 * (WINDOW_WIDTH / 4), 100})

	// Add new weapon on the left side
	spawn_weapon(game, .Laser_Cannon, {100, f32(WINDOW_HEIGHT) - 100})

	return true
}

update :: proc(game: ^Game) {

	// PLayer
	player_ref := game.player_ref

	// Input
	if rl.IsKeyPressed(.SPACE) {
		spawn_projectile(game)
	}

	if rl.IsKeyPressed(.F) {
		cycle_weapon(game)
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
				pos := get_world_pos(game.things, ref)
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
			// Check if player collides / intersects with a weapon, then it will pick it up
			ref_kind := get_kind(game.things, ref)
			if ref != player_ref && is_weapon(ref_kind) {
				player_pos := get_local_pos(game.things, player_ref)
				player_sprite_size := sprite_size(get_sprite(game.things, player_ref))
				player_rect := rl.Rectangle {
					player_pos.x,
					player_pos.y,
					player_sprite_size.x,
					player_sprite_size.y,
				}

				ref_pos := get_world_pos(game.things, ref)
				ref_sprite_size := sprite_size(get_sprite(game.things, ref))
				ref_rect := rl.Rectangle {
					ref_pos.x,
					ref_pos.y,
					ref_sprite_size.x,
					ref_sprite_size.y,
				}

				// Do not check collision if the thing is already a child,
				// meaning player_ref is already the parent.
				// Specifically weapon pick up collision check
				parent_ref := get_parent(game.things, ref)
				if rl.CheckCollisionRecs(player_rect, ref_rect) && parent_ref != player_ref {
					attach_child(&game.things, player_ref, ref)
					set_local_pos(&game.things, ref, WEAPON_OFFSET)
					switch_weapon(game, ref)
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

	rl.InitAudioDevice()

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
