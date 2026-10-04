package main

import "core:fmt"

MAX_THINGS :: 8

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
	idx: int,
	gen: int,
}

Things :: struct {
	things:     [MAX_THINGS]Thing,
	used:       [MAX_THINGS]bool,
	gen:        [MAX_THINGS]int,
	first_free: int,
	next_free:  [MAX_THINGS]int,
}

init_things :: proc(things: ^Things) {
	// Init the free list, starting at idx 1, since the 0th index is the nil instance.
	things.first_free = 1
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

remove_thing :: proc(things: ^Things, thing_ref: Thing_Ref) {
	if slot := deref(things^, thing_ref); b32(slot) {
		things.used[deref(things^, thing_ref)] = false

		if b32(things.first_free) {
			things.next_free[slot] = things.first_free
		}

		things.first_free = slot
	}
}

find_empty :: proc(things: ^Things) -> int {
	return things.first_free
}

deref :: proc(things: Things, thing_ref: Thing_Ref) -> int {
	if thing_ref.idx > 0 &&
	   thing_ref.idx < MAX_THINGS &&
	   things.used[thing_ref.idx] &&
	   things.gen[thing_ref.idx] == thing_ref.gen {
		return thing_ref.idx
	} else {
		return 0
	}
}

// TODO(Thomas): This has an issue where if the deref(thing_ref) return 0 (the nil instance)
// we'll return a pointer to that nil, which the caller might change. This should not crash,
// but it is most likely not what the caller intended. Better approach might bet get and set helper
// as shown by Anton here: https://youtu.be/-m7lhJ_Mzdg?t=2032
get_thing :: proc(things: ^Things, thing_ref: Thing_Ref) -> ^Thing {
	idx := deref(things^, thing_ref)
	// NOTE(Thomas): This assert helps catch bugs that is related to the TODO above.
	// I Still think it's a good idea to do something like the set / get helper since that has
	// some more benefits too potentially.
	assert(idx != 0)
	return &things.things[idx]
}

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

}
