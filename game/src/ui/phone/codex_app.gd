class_name CodexApp
extends PhoneApp
## Begrippen (the phone, K): the codex (CodexPanel) with its tabs: the
## concepts, Ontdekkingen, Hoe werkt het? and Gesprekken. A concept learned
## since the player last looked badges it (it replaced the "Nieuwe begrippen"
## card over the world).

var codex := CodexPanel.new()


func _init() -> void:
	super()
	carry(codex)


func opened() -> void:
	layer.concepts_seen.append_array(unread())


func unread() -> Array[String]:
	var out: Array[String] = []
	for id in session.region.profile.concepts:
		if not id in layer.concepts_seen and session.catalog.concepts.has(id):
			out.append(id)
	return out
