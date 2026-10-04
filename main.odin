package main

import "core:fmt"

MAX_THINGS :: 8

Thing_Idx :: int

Vec2 :: [2]f32

Kind :: enum {
	Nil,
	Asteroid,
	Alien,
	Player,
}

Thing :: struct {
	kind:   Kind,
	pos:    Vec2,
	health: f32,
	damage: f32,
}

Thing_Ref :: struct {
	idx: Thing_Idx,
	gen: int,
}

Things :: struct {
	things: [MAX_THINGS]Thing,
	used:   [MAX_THINGS]bool,
	gen:    [MAX_THINGS]int,
}

add_thing :: proc(things: ^Things, kind: Kind) -> Thing_Ref {

	slot := find_empty(things)

	if b32(slot) {
		// slot is the non-nil slot so we can use it
		things.things[slot] = {}
		things.things[slot].kind = kind
		things.used[slot] = true
		things.gen[slot] += 1
		return {slot, things.gen[slot]}
	} else {
		return {}
	}
}

find_empty :: proc(things: ^Things) -> Thing_Idx {
	for i in 1 ..< MAX_THINGS {
		if !things.used[i] {
			return i
		}
	}

	return {}
}

deref :: proc(things: Things, thing_ref: Thing_Ref) -> Thing_Idx {
	if thing_ref.idx > 0 &&
	   thing_ref.idx < MAX_THINGS &&
	   things.used[thing_ref.idx] &&
	   things.gen[thing_ref.idx] == thing_ref.gen {
		return thing_ref.idx
	} else {
		return 0
	}
}

main :: proc() {

	things: Things

	player_ref := add_thing(&things, .Player)

	another_player_ref := add_thing(&things, .Player)

	fmt.println("player_ref: ", player_ref)
	fmt.println("another_player_ref: ", another_player_ref)

	fmt.println("things before mutating: ", things)


	// Mutating the things behind player_ref
	things.things[deref(things, player_ref)].health = 4

	fmt.println("things after mutating: ", things)


}
