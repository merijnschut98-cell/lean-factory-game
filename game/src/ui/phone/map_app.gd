class_name MapApp
extends PhoneApp
## Kaart (the phone, M): the player map (OfficeMap) with its floor switch,
## the phone turned sideways so a floor fits. At the lift the same map is the
## floor switch that takes you there (OfficeMap.lift).

## The map's drawing area on the sideways phone.
const VIEW := Vector2(900, 400)

var map := OfficeMap.new()


func _init() -> void:
	super()
	landscape = true
	carry(map)
	map.set_view_size(VIEW)


## Lowering the phone ends the lift's choice: M next time is the plain map.
func closed() -> void:
	map.lift = false
