class_name SimStock
extends RefCounted
## A stocked material with a reorder point. Orders that need it while it is
## out of stock wait in `waiting` until a delivery arrives.

var id: String
var name: String
var level: int
var reorder_point: int
var order_quantity: int
var lead_minutes: int
## Open purchase orders: [{at: int, quantity: int}].
var deliveries: Array[Dictionary] = []
var waiting: Array[WorkOrder] = []


func on_order() -> int:
	var total := 0
	for d in deliveries:
		total += d["quantity"]
	return total


func needs_reorder() -> bool:
	return level + on_order() <= reorder_point
