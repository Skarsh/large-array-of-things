package main

import "core:fmt"
import "core:testing"

MAX_THINGS :: 16

Vec2 :: [2]f32

Kind :: enum {
	Nil,
	Asteroid,
	Alien,
	Player,

	// Weapons
	Laser_Cannon,
	Plasma_Cannon,
	Missile_Launcher,

	// Projectiles
	Bullet,
	Laser_Bolt,
	Plasma_Orb,
	Missle,
}

Thing :: struct {
	kind:             Kind,
	pos:              Vec2,
	velocity:         Vec2,
	health:           f32,
	damage:           f32,
	sprite:           Sprite_ID,

	// Child stuff, should these be able to get and set??
	parent_idx:       int,
	first_child_idx:  int,
	next_sibling_idx: int,
	prev_sibling_idx: int,
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
		things.used[slot] = false

		if b32(things.first_free) {
			things.next_free[slot] = things.first_free
		}

		things.first_free = slot
	}
}

attach_child :: proc(things: ^Things, parent_ref: Thing_Ref, child_ref: Thing_Ref) {
	parent_idx := deref(things^, parent_ref)
	parent := &things.things[parent_idx]

	child_idx := deref(things^, child_ref)
	child := &things.things[child_idx]
	child.parent_idx = parent_idx

	if parent.first_child_idx == 0 {
		// First child
		parent.first_child_idx = child_idx
		child.next_sibling_idx = child_idx
		child.prev_sibling_idx = child_idx
	} else {
		// Append sibling
		first_child_idx := parent.first_child_idx
		first_child := &things.things[first_child_idx]

		last_child_idx := first_child.prev_sibling_idx
		last_child := &things.things[last_child_idx]

		child.next_sibling_idx = first_child_idx
		child.prev_sibling_idx = last_child_idx

		last_child.next_sibling_idx = child_idx
		first_child.prev_sibling_idx = child_idx
	}

}

find_empty :: proc(things: ^Things) -> int {
	return things.first_free
}

is_valid_ref :: proc(things: Things, ref: Thing_Ref) -> bool {
	return(
		ref.idx > 0 &&
		ref.idx < MAX_THINGS &&
		things.used[ref.idx] &&
		things.gen[ref.idx] == ref.gen \
	)
}

deref :: proc(things: Things, ref: Thing_Ref) -> int {
	if is_valid_ref(things, ref) {
		return ref.idx
	} else {
		assert(false, "Trying to deref a nil instance")
		return 0
	}
}

make_ref :: proc(things: Things, slot: int) -> Thing_Ref {
	return {idx = slot, gen = things.gen[slot]}
}


nil_ref :: proc() -> Thing_Ref {
	return {}
}

Thing_Iterator :: struct {
	things: ^Things,
	idx:    int,
}

make_iterator :: proc(things: ^Things) -> Thing_Iterator {
	return {things = things, idx = 1}
}

next_thing :: proc(iter: ^Thing_Iterator) -> (Thing_Ref, bool) {
	for iter.idx < len(iter.things.things) {
		current_idx := iter.idx
		iter.idx += 1

		if iter.things.used[current_idx] {
			return make_ref(iter.things^, current_idx), true
		}
	}

	return nil_ref(), false
}

Child_Iterator :: struct {
	things:          ^Things,
	idx:             int,
	first_child_idx: int,
	has_next:        bool,
}

make_child_iterator :: proc(things: ^Things, ref: Thing_Ref) -> Child_Iterator {
	first_child_ref := get_first_child(things^, ref)
	has_next: bool

	if first_child_ref != nil_ref() {
		has_next = true
	}

	return {things, first_child_ref.idx, first_child_ref.idx, has_next}
}

next_child :: proc(iter: ^Child_Iterator) -> (Thing_Ref, bool) {
	if iter.has_next {
		child_ref := make_ref(iter.things^, iter.idx)
		assert(is_valid_ref(iter.things^, child_ref))
		sib_idx := get_next_sibling(iter.things^, child_ref).idx

		// Next sibling idx is the same as first child, so we would wrap around on next.
		if sib_idx == iter.first_child_idx {
			iter.has_next = false
		} else {
			iter.idx = sib_idx
		}

		return child_ref, true
	} else {
		return nil_ref(), false
	}
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

get_local_pos :: proc(things: Things, ref: Thing_Ref) -> Vec2 {
	return things.things[deref(things, ref)].pos
}

set_local_pos :: proc(things: ^Things, ref: Thing_Ref, pos: Vec2) {
	if slot := deref(things^, ref); b32(slot) {
		things.things[slot].pos = pos
	}
}

get_world_pos :: proc(things: ^Things, ref: Thing_Ref) -> Vec2 {
	return {}
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

get_sprite :: proc(things: Things, ref: Thing_Ref) -> Sprite_ID {
	return things.things[deref(things, ref)].sprite
}

set_sprite :: proc(things: ^Things, ref: Thing_Ref, sprite: Sprite_ID) {
	if slot := deref(things^, ref); b32(slot) {
		things.things[slot].sprite = sprite
	}
}

// ----- Getters for child and parent fields ----- //

get_parent :: proc(things: Things, ref: Thing_Ref) -> Thing_Ref {
	slot := deref(things, ref)
	if (things.things[slot].parent_idx == 0) {
		return {}
	} else {
		return make_ref(things, things.things[slot].parent_idx)
	}
}

get_first_child :: proc(things: Things, ref: Thing_Ref) -> Thing_Ref {
	slot := deref(things, ref)
	if (things.things[slot].first_child_idx == 0) {
		return {}
	} else {
		return make_ref(things, things.things[slot].first_child_idx)
	}
}

get_next_sibling :: proc(things: Things, ref: Thing_Ref) -> Thing_Ref {
	slot := deref(things, ref)
	if (things.things[slot].next_sibling_idx == 0) {
		return {}
	} else {
		return make_ref(things, things.things[slot].next_sibling_idx)
	}
}

get_prev_sibling :: proc(things: Things, ref: Thing_Ref) -> Thing_Ref {
	slot := deref(things, ref)
	if (things.things[slot].prev_sibling_idx == 0) {
		return {}
	} else {
		return make_ref(things, things.things[slot].prev_sibling_idx)
	}
}

// ----- Tests ----- //

check_thing :: proc(
	t: ^testing.T,
	things: Things,
	ref: Thing_Ref,
	expected: Thing,
	loc := #caller_location,
) {
	actual := Thing {
		kind     = get_kind(things, ref),
		pos      = get_local_pos(things, ref),
		velocity = get_velocity(things, ref),
		health   = get_health(things, ref),
		damage   = get_damage(things, ref),
		sprite   = get_sprite(things, ref),
	}
	testing.expect_value(t, actual, expected, loc = loc)
}

check_live_things :: proc(
	t: ^testing.T,
	things: ^Things,
	expected: []Thing_Ref,
	loc := #caller_location,
) {
	counts := make(map[Thing_Ref]int)
	defer delete(counts)

	iter := make_iterator(things)

	for _ in expected {
		ref, ok := next_thing(&iter)
		if !testing.expect(t, ok, "iterator ended early", loc = loc) {
			return
		}
		counts[ref] += 1
	}

	_, ok := next_thing(&iter)
	testing.expect(t, !ok, "iterator turned extra things", loc = loc)

	for ref in expected {
		testing.expect_value(t, counts[ref], 1, loc = loc)
	}
}

check_valid_ref :: proc(
	t: ^testing.T,
	things: Things,
	ref: Thing_Ref,
	expected: bool,
	loc := #caller_location,
) {
	testing.expect_value(t, is_valid_ref(things, ref), expected, loc = loc)
}

check_parent :: proc(
	t: ^testing.T,
	things: Things,
	child: Thing_Ref,
	expected: Thing_Ref,
	loc := #caller_location,
) {
	parent := get_parent(things, child)
	testing.expect_value(t, parent, expected, loc = loc)
}

check_first_child :: proc(
	t: ^testing.T,
	things: Things,
	parent: Thing_Ref,
	expected: Thing_Ref,
	loc := #caller_location,
) {
	child := get_first_child(things, parent)
	testing.expect_value(t, child, expected, loc = loc)
}

check_next_sibling :: proc(
	t: ^testing.T,
	things: Things,
	child: Thing_Ref,
	expected: Thing_Ref,
	loc := #caller_location,
) {
	next_sibling := get_next_sibling(things, child)
	testing.expect_value(t, next_sibling, expected, loc = loc)
}

check_prev_sibling :: proc(
	t: ^testing.T,
	things: Things,
	child: Thing_Ref,
	expected: Thing_Ref,
	loc := #caller_location,
) {
	prev_sibling := get_prev_sibling(things, child)
	testing.expect_value(t, prev_sibling, expected, loc = loc)
}

check_children :: proc(
	t: ^testing.T,
	things: ^Things,
	parent: Thing_Ref,
	expected: []Thing_Ref,
	loc := #caller_location,
) {

	iter := make_child_iterator(things, parent)

	for expected_child in expected {
		child, ok := next_child(&iter)
		testing.expect_value(t, ok, true, loc = loc)
		testing.expect_value(t, child, expected_child, loc = loc)
	}

	// Call next_child once more to assure that it reports false, meaning it's empty
	{
		child, ok := next_child(&iter)
		testing.expect_value(t, ok, false, loc = loc)
		testing.expect_value(t, child, nil_ref(), loc = loc)
	}

	// Call next_child even once more to assure that it keeps reproting false
	{
		child, ok := next_child(&iter)
		testing.expect_value(t, ok, false, loc = loc)
		testing.expect_value(t, child, nil_ref(), loc = loc)
	}
}

@(test)
test_things_lifecycle :: proc(t: ^testing.T) {
	things: Things
	init_things(&things)

	check_live_things(t, &things, nil)

	player := add_thing(&things, .Player)
	alien := add_thing(&things, .Alien)
	bullet := add_thing(&things, .Bullet)
	check_live_things(t, &things, {player, alien, bullet})

	set_health(&things, player, 100)
	set_kind(&things, bullet, .Asteroid)

	// Removing the middle element must preserve its neighbours
	remove_thing(&things, alien)
	check_live_things(t, &things, {player, bullet})
	check_thing(t, things, player, {kind = .Player, health = 100})
	check_thing(t, things, bullet, {kind = .Asteroid})

	remove_thing(&things, player)
	check_live_things(t, &things, {bullet})

	remove_thing(&things, bullet)
	check_live_things(t, &things, nil)
}

@(test)
test_removed_thing_ref_is_rejected :: proc(t: ^testing.T) {
	things: Things
	init_things(&things)

	ref := add_thing(&things, .Player)
	check_valid_ref(t, things, ref, expected = true)

	remove_thing(&things, ref)
	check_valid_ref(t, things, ref, expected = false)
}

@(test)
test_attach_single_child_to_parent :: proc(t: ^testing.T) {
	things: Things
	init_things(&things)

	player := add_thing(&things, .Player)
	bullet := add_thing(&things, .Bullet)
	check_parent(t, things, bullet, expected = nil_ref())
	check_first_child(t, things, player, expected = nil_ref())
	check_next_sibling(t, things, bullet, expected = nil_ref())
	check_prev_sibling(t, things, bullet, expected = nil_ref())

	attach_child(&things, player, bullet)
	check_parent(t, things, bullet, expected = player)
	check_first_child(t, things, player, expected = bullet)
	check_next_sibling(t, things, bullet, expected = bullet)
	check_prev_sibling(t, things, bullet, expected = bullet)
}

@(test)
test_attach_two_children_to_parent :: proc(t: ^testing.T) {
	things: Things
	init_things(&things)

	player := add_thing(&things, .Player)
	bullet := add_thing(&things, .Bullet)
	alien := add_thing(&things, .Alien)

	attach_child(&things, player, bullet)
	check_parent(t, things, bullet, expected = player)

	attach_child(&things, player, alien)
	check_parent(t, things, alien, expected = player)

	check_first_child(t, things, player, expected = bullet)

	check_next_sibling(t, things, bullet, expected = alien)
	check_prev_sibling(t, things, bullet, expected = alien)

	check_next_sibling(t, things, alien, expected = bullet)
	check_prev_sibling(t, things, alien, expected = bullet)
}

@(test)
test_attach_three_children_to_parent :: proc(t: ^testing.T) {
	things: Things
	init_things(&things)

	player := add_thing(&things, .Player)
	bullet := add_thing(&things, .Bullet)
	alien := add_thing(&things, .Alien)
	asteroid := add_thing(&things, .Asteroid)

	attach_child(&things, player, bullet)
	attach_child(&things, player, alien)
	attach_child(&things, player, asteroid)

	check_parent(t, things, bullet, expected = player)
	check_parent(t, things, alien, expected = player)
	check_parent(t, things, asteroid, expected = player)

	check_first_child(t, things, player, expected = bullet)

	check_next_sibling(t, things, bullet, expected = alien)
	check_prev_sibling(t, things, bullet, expected = asteroid)

	check_next_sibling(t, things, alien, expected = asteroid)
	check_prev_sibling(t, things, alien, expected = bullet)

	check_next_sibling(t, things, asteroid, expected = bullet)
	check_prev_sibling(t, things, asteroid, expected = alien)
}

@(test)
test_iterate_parent_with_no_children :: proc(t: ^testing.T) {

	things: Things
	init_things(&things)

	player := add_thing(&things, .Player)

	check_children(t, &things, player, nil)
}

@(test)
test_iterate_parent_with_one_child :: proc(t: ^testing.T) {
	things: Things
	init_things(&things)

	player := add_thing(&things, .Player)
	bullet := add_thing(&things, .Bullet)

	attach_child(&things, player, bullet)
	check_children(t, &things, player, {bullet})
}

@(test)
test_iterate_with_reversed_attach_order :: proc(t: ^testing.T) {
	things: Things
	init_things(&things)

	player := add_thing(&things, .Player)
	bullet := add_thing(&things, .Bullet)
	alien := add_thing(&things, .Alien)
	asteroid := add_thing(&things, .Asteroid)

	// Attach in reverse order of adding
	attach_child(&things, player, asteroid)

	// Checking a single child, because that covers
	// the case where the first child is also the last.
	check_children(t, &things, player, {asteroid})

	attach_child(&things, player, alien)
	attach_child(&things, player, bullet)

	check_children(t, &things, player, {asteroid, alien, bullet})
}
