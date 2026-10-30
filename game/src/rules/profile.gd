class_name Profile
extends RefCounted
## The player across regions: improvement budget, XP (belts) and the
## concepts they have met.

## Improvement budget in euros.
var budget := 50000
var xp := 0
var concepts := PackedStringArray()


func learn(tags: PackedStringArray) -> void:
	for tag in tags:
		if not tag in concepts:
			concepts.append(tag)
