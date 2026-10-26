package main

import "core:fmt"
import "core:math/linalg"

import rl "vendor:raylib"

WINDOW_WIDTH :: 800
WINDOW_HEIGHT :: 600

WEAPON_OFFSET :: Vec2{0, -8}

Weapon_Kind :: enum {
	Machine_Gun,
	Laser_Cannon,
	Plasma_Cannon,
	Missile_Launcher,
	Count,
}

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

Game :: struct {
	things:                   Things,
	spritesheet:              rl.Texture2D,
	player_ref:               Thing_Ref,
	player_active_weapon_ref: Thing_Ref,
	weapon_sounds:            [Weapon_Kind.Count]rl.Sound,
}


switch_weapon :: proc(game: ^Game, weapon_ref: Thing_Ref) {
	weapon_ref_parent := get_parent(game.things, weapon_ref)

	// The player is the parent, so this is a valid ref
	assert(weapon_ref_parent == game.player_ref)

	add_flag(&game.things, game.player_active_weapon_ref, .Hidden)
	game.player_active_weapon_ref = weapon_ref
	remove_flag(&game.things, game.player_active_weapon_ref, .Hidden)
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
	game.weapon_sounds[Weapon_Kind.Machine_Gun] = rl.LoadSound(
		"data/sounds/weapons/machine_gun_fire.wav",
	)
	game.weapon_sounds[Weapon_Kind.Laser_Cannon] = rl.LoadSound(
		"data/sounds/weapons/laser_cannon_fire.wav",
	)
	game.weapon_sounds[Weapon_Kind.Plasma_Cannon] = rl.LoadSound(
		"data/sounds/weapons/plasma_cannon_fire.wav",
	)
	game.weapon_sounds[Weapon_Kind.Missile_Launcher] = rl.LoadSound(
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
	player_ref := game.player_ref

	// Input
	if rl.IsKeyPressed(.SPACE) {

		weapon_kind := get_kind(game.things, game.player_active_weapon_ref)

		projectile_sprite_rect: rl.Rectangle
		projectile_ref: Thing_Ref
		projectile_sprite: Sprite_ID
		projectile_velocity: Vec2
		projectile_damage: f32

		// TODO(Thomas): All of this could be table driven I think
		#partial switch weapon_kind {
		case .Machine_Gun:
			projectile_sprite_rect = sprite_rect(.Bullet)
			projectile_ref = add_thing(&game.things, .Bullet)
			projectile_sprite = .Bullet
			projectile_velocity = BULLET_VELOCITY
			projectile_damage = BULLET_DAMAGE

			rl.PlaySound(game.weapon_sounds[Weapon_Kind.Machine_Gun])

		case .Laser_Cannon:
			projectile_sprite_rect = sprite_rect(.Laser_Bolt)
			projectile_ref = add_thing(&game.things, .Laser_Bolt)
			projectile_sprite = .Laser_Bolt
			projectile_velocity = LASER_VELOCITY
			projectile_damage = LASER_DAMAGE

			rl.PlaySound(game.weapon_sounds[Weapon_Kind.Laser_Cannon])

		case .Plasma_Cannon:
			projectile_sprite_rect = sprite_rect(.Plasma_Orb)
			projectile_ref = add_thing(&game.things, .Plasma_Orb)
			projectile_sprite = .Plasma_Orb
			projectile_velocity = PLASMA_VELOCITY
			projectile_damage = PLASMA_DAMAGE

			rl.PlaySound(game.weapon_sounds[Weapon_Kind.Plasma_Cannon])

		case .Missile_Launcher:
			projectile_sprite_rect = sprite_rect(.Missile)
			projectile_ref = add_thing(&game.things, .Missile)
			projectile_sprite = .Missile
			projectile_velocity = MISSILE_VELOCITY
			projectile_damage = MISSILE_DAMAGE

			rl.PlaySound(game.weapon_sounds[Weapon_Kind.Missile_Launcher])

		case:
			panic("illegal weapon kind")
		}

		player_sprite := sprite_rect(get_sprite(game.things, player_ref))
		player_pos := get_world_pos(game.things, player_ref)

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
