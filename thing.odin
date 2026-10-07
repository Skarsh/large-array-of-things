package main

import rl "vendor:raylib"

MAX_THINGS :: 8

Vec2 :: [2]f32

Kind :: enum {
	Nil,
	Asteroid,
	Alien,
	Player,
	Bullet,
}

Thing :: struct {
	kind:     Kind,
	pos:      Vec2,
	velocity: Vec2,
	health:   f32,
	damage:   f32,
	texture:  rl.Texture2D,
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

	// Initializing the free list
	for i in 1 ..< MAX_THINGS {
		if i + 1 < MAX_THINGS {
			things.next_free[i] = i + 1
		} else {
			// This is the free element when initializing the free list.
			// This one points to the nil element because there are no
			// more free elements.
			things.next_free[i] = 0
		}
	}
}

add_thing :: proc(things: ^Things, kind: Kind) -> Thing_Ref {
	slot := find_empty(things)

	if b32(slot) {
		// slot is the non-nil slot so we can use it
		things.things[slot] = {}
		things.things[slot].kind = kind
		things.used[slot] = true
		things.gen[slot] += 1

		// The first_free needs to point to the next free at it's index.
		things.first_free = things.next_free[slot]

		// This slot is now taken, so the next_free for this slot / idx
		// should be updated to point to nil.
		things.next_free[slot] = 0

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
		assert(false, "Trying to deref a nil instance")
		return 0
	}
}

make_ref :: proc(things: Things, slot: int) -> Thing_Ref {
	return {idx = slot, gen = things.gen[slot]}
}


// ------- Getters and Setters ------- //

get_kind :: proc(things: Things, ref: Thing_Ref) -> Kind {
	return things.things[deref(things, ref)].kind
}

set_kind :: proc(things: ^Things, ref: Thing_Ref, kind: Kind) {
	if slot := deref(things^, ref); b32(slot) {
		things.things[slot].kind = kind
	}
}

get_pos :: proc(things: Things, ref: Thing_Ref) -> Vec2 {
	return things.things[deref(things, ref)].pos
}

set_pos :: proc(things: ^Things, ref: Thing_Ref, pos: Vec2) {
	if slot := deref(things^, ref); b32(slot) {
		things.things[slot].pos = pos
	}
}

get_velocity :: proc(things: Things, ref: Thing_Ref) -> Vec2 {
	return things.things[deref(things, ref)].velocity
}

set_velocity :: proc(things: ^Things, ref: Thing_Ref, velocity: Vec2) {
	if slot := deref(things^, ref); b32(slot) {
		things.things[slot].velocity = velocity
	}
}

get_health :: proc(things: Things, ref: Thing_Ref) -> f32 {
	return things.things[deref(things, ref)].health
}

set_health :: proc(things: ^Things, ref: Thing_Ref, health: f32) {
	if slot := deref(things^, ref); b32(slot) {
		things.things[slot].health = health
	}
}

get_damage :: proc(things: Things, ref: Thing_Ref) -> f32 {
	return things.things[deref(things, ref)].damage
}

set_damage :: proc(things: ^Things, ref: Thing_Ref, damage: f32) {
	if slot := deref(things^, ref); b32(slot) {
		things.things[slot].damage = damage
	}
}

get_texture :: proc(things: Things, ref: Thing_Ref) -> rl.Texture2D {
	return things.things[deref(things, ref)].texture
}

set_texture :: proc(things: ^Things, ref: Thing_Ref, texture: rl.Texture2D) {
	if slot := deref(things^, ref); b32(slot) {
		things.things[slot].texture = texture
	}
}
