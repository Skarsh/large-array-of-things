package main

import "core:fmt"

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
