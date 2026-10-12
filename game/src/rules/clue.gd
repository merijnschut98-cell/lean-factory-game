class_name Clue
extends RefCounted
## A fact the player can find with a gemba tool. Key clues point at the real
## cause; red herrings are true but not causal. A clue at depth n only shows
## once a key clue at depth n − 1 of the same problem is found (the 5 Whys as
## an investigation). `at` is the place (stream.step) where it can be found,
## which may be upstream of where the problem shows.

var id: String
var tool: String
var text: String
var key: bool
var depth: int
var at: String
## Coach reflection for the debrief.
var note: String
var teaches: PackedStringArray
