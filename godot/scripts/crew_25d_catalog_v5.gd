class_name Crew25DCatalogV5
extends RefCounted

# Deux équipages entièrement originaux. Ils reprennent uniquement des rôles
# classiques d'aventure pirate et ne copient aucun personnage sous licence.
const CREWS := [
	{
		"id":"aurore",
		"name":"Équipage de l’Aurore",
		"ship":"L’Aurore Boréale",
		"primary":"2f8ec9",
		"secondary":"f2c34b",
		"members":[
			{"id":"kael","name":"Kaël Vagueclaire","role":"capitaine","body":"d84a35","accent":"f2c34b","weapon":"poings"},
			{"id":"doran","name":"Doran Trois-Lames","role":"sabreur","body":"2d7c55","accent":"d9e3c7","weapon":"sabres"},
			{"id":"mira","name":"Mira l’Étincelle","role":"navigatrice","body":"c86c33","accent":"f5e4b5","weapon":"bâton"},
			{"id":"selya","name":"Selya Vent-Roux","role":"tireuse","body":"b33f57","accent":"f0c991","weapon":"fusil"},
			{"id":"bronn","name":"Bronn Acier-Rire","role":"charpentier","body":"2687a8","accent":"d44c3f","weapon":"gantelets"},
			{"id":"yara","name":"Yara des Marées","role":"médecin","body":"6f59a8","accent":"e8e6ef","weapon":"lames"},
			{"id":"nilo","name":"Nilo le Masqué","role":"cuisinier","body":"262b36","accent":"e2c157","weapon":"jambes"},
			{"id":"tiko","name":"Tiko le Guetteur","role":"éclaireur","body":"b68435","accent":"77c9e8","weapon":"fronde"},
			{"id":"orko","name":"Orko Tambour","role":"musicien","body":"6f3c8d","accent":"f0dfcc","weapon":"canne"},
			{"id":"venn","name":"Venn Brume","role":"historien","body":"354967","accent":"b8d8ef","weapon":"chaînes"}
		]
	},
	{
		"id":"ecarlate",
		"name":"Flotte Écarlate",
		"ship":"Le Souverain Écarlate",
		"primary":"9f2532",
		"secondary":"1d2028",
		"members":[
			{"id":"rakhun","name":"Rakhun Rouge-Sang","role":"capitaine","body":"8f2631","accent":"eee3d5","weapon":"sabre"},
			{"id":"voren","name":"Voren Main-Forte","role":"second","body":"493b36","accent":"c99a72","weapon":"poings"},
			{"id":"garr","name":"Garr le Colosse","role":"briseur","body":"6c453a","accent":"d8c5a1","weapon":"masse"},
			{"id":"selk","name":"Selk Œil-Noir","role":"canonnier","body":"33404e","accent":"b33a2d","weapon":"canon"},
			{"id":"maela","name":"Maela Croc-Sombre","role":"duelliste","body":"4d2a4f","accent":"d3b7d7","weapon":"rapière"},
			{"id":"krann","name":"Krann des Tempêtes","role":"navigateur","body":"445b6c","accent":"a5d6ea","weapon":"hache"},
			{"id":"ulmar","name":"Ulmar le Mur","role":"gardien","body":"5a4d44","accent":"d0b087","weapon":"bouclier"},
			{"id":"issra","name":"Issra la Cendre","role":"éclaireuse","body":"553443","accent":"e0734e","weapon":"arbalète"},
			{"id":"borek","name":"Borek Barbe-Grise","role":"artificier","body":"4f555e","accent":"d7b55a","weapon":"bombes"},
			{"id":"nyx","name":"Nyx du Silence","role":"espion","body":"242735","accent":"a83d4d","weapon":"doubles lames"}
		]
	}
]

static func crew(index: int) -> Dictionary:
	return CREWS[clampi(index, 0, CREWS.size() - 1)].duplicate(true)

static func members(crew_index: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var source: Array = CREWS[clampi(crew_index, 0, CREWS.size() - 1)]["members"]
	for member in source:
		var profile: Dictionary = (member as Dictionary).duplicate(true)
		profile["crew_id"] = CREWS[crew_index]["id"]
		profile["crew_name"] = CREWS[crew_index]["name"]
		profile["crew_primary"] = CREWS[crew_index]["primary"]
		profile["crew_secondary"] = CREWS[crew_index]["secondary"]
		result.append(profile)
	return result
