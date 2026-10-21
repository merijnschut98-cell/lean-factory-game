class_name NotesApp
extends PhoneApp
## Notities (the phone, J): the player's own notes (ClueJournal): the clues by
## place, what the gemba tools showed, the journal's other entries (a talk's
## summary) by kind, the fixes in use, the followed dossier.

var journal := ClueJournal.new()


func _init() -> void:
	super()
	carry(journal)
