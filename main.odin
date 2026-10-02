package main

import "core:fmt"

MAX_THINGS :: 8

Thing_Idx :: int

things := [MAX_THINGS]Thing{}

Vec2 :: [2]f32

Trait :: enum {
	Positionable,
	Enemy,
	Holdable,
}

Trait_Set :: bit_set[Trait]

Thing :: struct {
	traits: Trait_Set,
	pos:    Vec2,
	health: f32,
	damage: f32,
}

main :: proc() {

	thing := Thing {
		pos    = {2, 4},
		health = 3.14,
		damage = 6.9,
		traits = {.Holdable},
	}

	fmt.println("thing: ", thing)

	things[0] = thing

	fmt.println("things: ", things)

}
