class_name AmbientFleetV5
extends Node3D

var zones: Array = []
var ships: Array[AmbientShipV5] = []

func configure(zone_definitions: Array) -> void:
	zones = zone_definitions
	_build_crew_ships()
	_build_small_vessels()
	print("CHK_V5_FLEET_READY ships=%d" % ships.size())

func _build_crew_ships() -> void:
	var sunny_route := _route_for_indices([0, 1, 3, 6, 2])
	var sunny := AmbientShipV5.new()
	add_child(sunny)
	sunny.configure(sunny_route, "Thousand Sunny", Color("8b4f27"), Color("f2c537"), 1.46, 5.6, 701)
	sunny.set_meta("crew_id", "strawhat")
	sunny.set_meta("ship_style", "sunny")
	ships.append(sunny)

	var red_force_route := _route_for_indices([5, 7, 4, 8, 6])
	var red_force := AmbientShipV5.new()
	add_child(red_force)
	red_force.configure(red_force_route, "Red Force", Color("7f252d"), Color("191a20"), 1.58, 5.1, 1702)
	red_force.set_meta("crew_id", "redhair")
	red_force.set_meta("ship_style", "red_force")
	ships.append(red_force)

func _build_small_vessels() -> void:
	var palettes := [
		[Color("75513a"), Color("e8d7a7")],
		[Color("4c6170"), Color("d9e7ed")],
		[Color("6e4934"), Color("c8a86b")],
		[Color("3e6656"), Color("d9cf94")]
	]
	for index in range(10):
		var a := index % zones.size()
		var b := (index * 2 + 3) % zones.size()
		if b == a:
			b = (b + 1) % zones.size()
		var c := (index * 3 + 5) % zones.size()
		var route := _route_for_indices([a, b, c])
		var ship := AmbientShipV5.new()
		add_child(ship)
		var palette: Array = palettes[index % palettes.size()]
		ship.configure(route, "Navire libre %02d" % (index + 1), palette[0], palette[1], 0.58 + float(index % 3) * 0.12, 3.2 + float(index % 4) * 0.45, 3000 + index)
		ships.append(ship)

func _route_for_indices(indices: Array) -> Array[Vector3]:
	var result: Array[Vector3] = []
	for raw_index in indices:
		var zone_index := clampi(int(raw_index), 0, zones.size() - 1)
		var zone: Dictionary = zones[zone_index]
		var center: Vector3 = zone["center"]
		var direction: Vector3 = Vector3(zone["dock_dir"]).normalized()
		var radius := float(zone["radius"])
		var point := Vector3(center.x, PlayerController.BOAT_WATERLINE, center.z) + direction * (radius + 66.0)
		result.append(point)
	return result
