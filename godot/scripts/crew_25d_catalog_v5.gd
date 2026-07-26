class_name Crew25DCatalogV5
extends RefCounted

# Ces deux rosters correspondent directement aux équipages montrés dans les
# références fournies par Cheikh. Les sprites utilisent les atlas découpés
# depuis ces images et non des silhouettes procédurales inventées.
const CREWS := [
	{
		"id":"strawhat",
		"name":"Équipage du Chapeau de Paille",
		"ship":"Thousand Sunny",
		"atlas":"res://assets/crew25d/reference/strawhat_atlas_48.webp.b64",
		"primary":"d73b2f",
		"secondary":"f4cf45",
		"members":[
			{"id":"luffy","name":"Luffy","role":"capitaine","weapon":"poings","atlas_index":0},
			{"id":"zoro","name":"Zoro","role":"sabreur","weapon":"trois sabres","atlas_index":1},
			{"id":"sanji","name":"Sanji","role":"cuisinier","weapon":"jambes","atlas_index":2},
			{"id":"franky","name":"Franky","role":"charpentier","weapon":"gantelets","atlas_index":3},
			{"id":"chopper","name":"Chopper","role":"médecin","weapon":"transformation","atlas_index":4},
			{"id":"robin","name":"Robin","role":"archéologue","weapon":"pouvoir","atlas_index":5},
			{"id":"nami","name":"Nami","role":"navigatrice","weapon":"bâton climatique","atlas_index":6},
			{"id":"usopp","name":"Usopp","role":"tireur","weapon":"lance-pierre","atlas_index":7},
			{"id":"brook","name":"Brook","role":"musicien","weapon":"canne-épée","atlas_index":8},
			{"id":"jinbe","name":"Jinbe","role":"timonier","weapon":"karaté marin","atlas_index":9}
		]
	},
	{
		"id":"redhair",
		"name":"Équipage du Roux",
		"ship":"Red Force",
		"atlas":"res://assets/crew25d/reference/redhair_atlas_48.webp.b64",
		"primary":"9f2532",
		"secondary":"1d2028",
		"members":[
			{"id":"shanks","name":"Shanks","role":"capitaine","weapon":"sabre","atlas_index":0},
			{"id":"benn_beckman","name":"Benn Beckman","role":"second","weapon":"fusil","atlas_index":1},
			{"id":"lucky_roux","name":"Lucky Roux","role":"combattant","weapon":"pistolet","atlas_index":2},
			{"id":"yasopp","name":"Yasopp","role":"tireur","weapon":"fusil","atlas_index":3},
			{"id":"limejuice","name":"Limejuice","role":"combattant","weapon":"bâton","atlas_index":4},
			{"id":"bonk_punch","name":"Bonk Punch","role":"combattant","weapon":"poings","atlas_index":5},
			{"id":"monster","name":"Monster","role":"combattant","weapon":"agilité","atlas_index":6},
			{"id":"building_snake","name":"Building Snake","role":"navigateur","weapon":"sabres","atlas_index":7},
			{"id":"hongo","name":"Hongo","role":"médecin","weapon":"fusil","atlas_index":8},
			{"id":"gab","name":"Gab","role":"combattant","weapon":"crocs","atlas_index":9}
		]
	}
]

static func crew(index: int) -> Dictionary:
	return CREWS[clampi(index, 0, CREWS.size() - 1)].duplicate(true)

static func members(crew_index: int) -> Array[Dictionary]:
	var resolved := clampi(crew_index, 0, CREWS.size() - 1)
	var result: Array[Dictionary] = []
	var source: Array = CREWS[resolved]["members"]
	for member in source:
		var profile: Dictionary = (member as Dictionary).duplicate(true)
		profile["crew_id"] = CREWS[resolved]["id"]
		profile["crew_name"] = CREWS[resolved]["name"]
		profile["crew_primary"] = CREWS[resolved]["primary"]
		profile["crew_secondary"] = CREWS[resolved]["secondary"]
		profile["atlas"] = CREWS[resolved]["atlas"]
		result.append(profile)
	return result
