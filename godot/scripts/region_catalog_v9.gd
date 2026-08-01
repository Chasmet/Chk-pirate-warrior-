class_name RegionCatalogV9
extends RefCounted

const REGION_COUNT := 10
const NPCS_PER_REGION := 20
const TOTAL_NPCS := REGION_COUNT * NPCS_PER_REGION

const PERSONALITIES := [
	"calme", "courageux", "prudent", "curieux", "généreux",
	"méfiant", "travailleur", "rêveur", "direct", "sociable"
]

# Chaque implantation, point d’intérêt et identité est déclarée explicitement.
# Le moteur ne choisit jamais la structure des régions de manière aléatoire.
const REGIONS := [
	{
		"id":"village_cotier", "name":"Village côtier", "subtitle":"Pêche, marché et falaises marines",
		"center":Vector3(0.0, 0.0, 0.0), "radius":345.0, "elevation":0.0,
		"color":"4f9eae", "accent":"f2cf83", "weather":["soleil", "nuages", "pluie", "brouillard marin"],
		"jobs":["pêcheur", "poissonnière", "charpentier naval", "gardienne du phare", "marchand", "marin", "cuisinière", "réparateur de filets"],
		"fauna":["mouette", "crabe", "poisson côtier", "dauphin"],
		"pois":[
			{"name":"Phare des Brisants", "kind":"phare", "offset":Vector3(-142, 18, -92)},
			{"name":"Marché aux poissons", "kind":"marche", "offset":Vector3(28, 2, 42)},
			{"name":"Quai des Pêcheurs", "kind":"quai", "offset":Vector3(176, 1, 48)},
			{"name":"Grottes de l’Écume", "kind":"grotte", "offset":Vector3(-188, -2, 126)},
			{"name":"Place du Vieux Filet", "kind":"place", "offset":Vector3(-22, 2, -18)},
			{"name":"Cabanes de la Plage", "kind":"habitation", "offset":Vector3(82, 2, -118)},
			{"name":"Falaise du Guetteur", "kind":"falaise", "offset":Vector3(-92, 24, 188)},
			{"name":"Pontons du Couchant", "kind":"ponton", "offset":Vector3(205, 1, -80)}
		]
	},
	{
		"id":"grande_foret", "name":"Grande forêt", "subtitle":"Canopée, clairières et ruines végétales",
		"center":Vector3(720.0, 0.0, -420.0), "radius":365.0, "elevation":0.0,
		"color":"2f7245", "accent":"8bc66a", "weather":["nuages", "pluie", "brouillard", "orage"],
		"jobs":["chasseur", "herboriste", "garde forestier", "cueilleuse", "apiculteur", "guide", "charbonnier", "guérisseuse"],
		"fauna":["cerf", "sanglier", "renard", "hibou", "écureuil"],
		"pois":[
			{"name":"Clairière des Lucioles", "kind":"clairiere", "offset":Vector3(-118, 1, 64)},
			{"name":"Ruines des Racines", "kind":"ruines", "offset":Vector3(146, 3, -118)},
			{"name":"Cascade de Verre", "kind":"cascade", "offset":Vector3(-174, 14, -142)},
			{"name":"Camp des Pisteurs", "kind":"camp", "offset":Vector3(38, 2, 152)},
			{"name":"Grotte du Cerf Blanc", "kind":"grotte", "offset":Vector3(198, 4, 96)},
			{"name":"Chêne des Serments", "kind":"arbre", "offset":Vector3(-18, 2, -36)},
			{"name":"Ruisseau des Mousses", "kind":"ruisseau", "offset":Vector3(-92, 0, 204)},
			{"name":"Passage des Ronces", "kind":"passage", "offset":Vector3(224, 2, -18)}
		]
	},
	{
		"id":"montagnes_rocheuses", "name":"Montagnes rocheuses", "subtitle":"Falaises, mines et villages suspendus",
		"center":Vector3(2460.0, 8.0, 260.0), "radius":355.0, "elevation":8.0,
		"color":"6e6a62", "accent":"c7ad7b", "weather":["soleil", "nuages", "vent", "orage"],
		"jobs":["mineur", "forgeron", "guide de montagne", "chevrière", "tailleur de pierre", "garde", "cartographe", "aubergiste"],
		"fauna":["chèvre", "aigle", "loup", "marmotte"],
		"pois":[
			{"name":"Mine du Marteau", "kind":"mine", "offset":Vector3(-152, 18, -82)},
			{"name":"Pont des Deux Pics", "kind":"pont", "offset":Vector3(72, 42, -166)},
			{"name":"Village de Haute-Pierre", "kind":"village", "offset":Vector3(132, 34, 76)},
			{"name":"Cascade de l’Aigle", "kind":"cascade", "offset":Vector3(-204, 54, 112)},
			{"name":"Tunnel des Mineurs", "kind":"tunnel", "offset":Vector3(202, 16, -18)},
			{"name":"Belvédère du Vent", "kind":"belvedere", "offset":Vector3(-24, 72, 182)},
			{"name":"Escalier du Col", "kind":"escalade", "offset":Vector3(-88, 28, -212)},
			{"name":"Grotte des Cristaux", "kind":"grotte", "offset":Vector3(178, 22, 174)}
		]
	},
	{
		"id":"plaines_agricoles", "name":"Plaines agricoles", "subtitle":"Fermes, moulins et cultures variées",
		"center":Vector3(3300.0, 0.0, -560.0), "radius":370.0, "elevation":0.0,
		"color":"88a94d", "accent":"e4c66d", "weather":["soleil", "nuages", "pluie", "vent"],
		"jobs":["agriculteur", "meunière", "éleveur", "maraîchère", "fromager", "marchand de grains", "vétérinaire", "charretier"],
		"fauna":["vache", "mouton", "cheval", "poule", "lapin"],
		"pois":[
			{"name":"Ferme des Trois Granges", "kind":"ferme", "offset":Vector3(-144, 2, -92)},
			{"name":"Moulin du Levant", "kind":"moulin", "offset":Vector3(126, 4, -142)},
			{"name":"Vergers de Mirabelle", "kind":"verger", "offset":Vector3(-188, 2, 118)},
			{"name":"Marché des Récoltes", "kind":"marche", "offset":Vector3(34, 2, 36)},
			{"name":"Pont de la Rivière Claire", "kind":"pont", "offset":Vector3(204, 2, 96)},
			{"name":"Écuries du Grand Pré", "kind":"ecurie", "offset":Vector3(82, 2, 194)},
			{"name":"Champs en Terrasses", "kind":"champs", "offset":Vector3(-54, 5, -206)},
			{"name":"Hameau des Moissons", "kind":"village", "offset":Vector3(218, 2, -12)}
		]
	},
	{
		"id":"region_volcanique", "name":"Région volcanique", "subtitle":"Lave, cendres et anciennes fortifications",
		"center":Vector3(1580.0, 4.0, 820.0), "radius":350.0, "elevation":4.0,
		"color":"542f2b", "accent":"ff6938", "weather":["cendres", "nuages", "vent chaud", "orage sec"],
		"jobs":["forgeron", "mineuse d’obsidienne", "garde du rempart", "géologue", "porteur d’eau", "artisan", "éclaireur", "guérisseuse"],
		"fauna":["lézard de lave", "corbeau", "sanglier noir", "salamandre"],
		"pois":[
			{"name":"Caldeira Rouge", "kind":"volcan", "offset":Vector3(-26, 58, -128)},
			{"name":"Pont des Scories", "kind":"pont", "offset":Vector3(148, 12, -42)},
			{"name":"Village du Rempart", "kind":"village", "offset":Vector3(-156, 8, 92)},
			{"name":"Geysers de Soufre", "kind":"geysers", "offset":Vector3(188, 5, 112)},
			{"name":"Temple Effondré", "kind":"ruines", "offset":Vector3(-198, 12, -86)},
			{"name":"Grotte d’Obsidienne", "kind":"grotte", "offset":Vector3(88, 18, 196)},
			{"name":"Rivière de Lave", "kind":"lave", "offset":Vector3(38, 2, 34)},
			{"name":"Tour des Cendres", "kind":"tour", "offset":Vector3(214, 24, -154)}
		]
	},
	{
		"id":"marais_brumeux", "name":"Marais brumeux", "subtitle":"Boue, brume et chemins dissimulés",
		"center":Vector3(1180.0, -1.0, -1110.0), "radius":340.0, "elevation":-1.0,
		"color":"42584c", "accent":"8fb286", "weather":["brouillard", "pluie", "nuages", "orage"],
		"jobs":["batelier", "herboriste", "pêcheuse", "guérisseur", "chasseur de grenouilles", "gardienne des pontons", "cueilleur", "ermite"],
		"fauna":["grenouille", "héron", "crocodile", "insecte", "anguille"],
		"pois":[
			{"name":"Cabanes sur Pilotis", "kind":"habitation", "offset":Vector3(-104, 3, -76)},
			{"name":"Pontons du Brouillard", "kind":"ponton", "offset":Vector3(126, 1, -132)},
			{"name":"Ruines Englouties", "kind":"ruines", "offset":Vector3(188, -1, 92)},
			{"name":"Arbre aux Lanternes", "kind":"arbre", "offset":Vector3(-164, 4, 142)},
			{"name":"Bassin des Grenouilles", "kind":"bassin", "offset":Vector3(28, -2, 44)},
			{"name":"Sentier des Racines", "kind":"passage", "offset":Vector3(-214, 1, -18)},
			{"name":"Îlot du Guérisseur", "kind":"ile", "offset":Vector3(72, 2, 198)},
			{"name":"Zone des Vapeurs Toxiques", "kind":"danger", "offset":Vector3(218, 0, -38)}
		]
	},
	{
		"id":"desert_cendres", "name":"Désert de cendres", "subtitle":"Dunes grises, canyons et tempêtes",
		"center":Vector3(700.0, 0.0, 720.0), "radius":365.0, "elevation":0.0,
		"color":"77716b", "accent":"caa77d", "weather":["cendres", "tempête de cendres", "vent", "ciel couvert"],
		"jobs":["caravanier", "chercheuse de reliques", "guide", "tailleur de pierre", "éclaireur", "marchande d’eau", "chasseur", "gardien de camp"],
		"fauna":["lézard", "scorpion", "vautour", "renard des sables"],
		"pois":[
			{"name":"Canyon des Os", "kind":"canyon", "offset":Vector3(-176, -3, -98)},
			{"name":"Camp de la Dernière Eau", "kind":"camp", "offset":Vector3(92, 2, -142)},
			{"name":"Oasis Grise", "kind":"oasis", "offset":Vector3(-118, 0, 164)},
			{"name":"Observatoire Abandonné", "kind":"ruines", "offset":Vector3(186, 16, 112)},
			{"name":"Dunes du Sifflement", "kind":"dunes", "offset":Vector3(28, 8, 32)},
			{"name":"Grotte des Vents", "kind":"grotte", "offset":Vector3(218, 6, -48)},
			{"name":"Cimetière des Caravanes", "kind":"squelettes", "offset":Vector3(-222, 1, 36)},
			{"name":"Faille des Cendres", "kind":"danger", "offset":Vector3(62, -6, 218)}
		]
	},
	{
		"id":"grand_port_commercial", "name":"Grand port commercial", "subtitle":"Quais actifs, marchés et quartiers contrastés",
		"center":Vector3(5050.0, 48.0, -220.0), "radius":370.0, "elevation":48.0,
		"color":"355d72", "accent":"e1b36a", "weather":["soleil", "nuages", "pluie", "brouillard marin"],
		"jobs":["docker", "capitaine marchand", "douanière", "tavernier", "négociante", "grutier", "garde", "cartographe marin"],
		"fauna":["mouette", "rat des quais", "chat", "poisson de port"],
		"pois":[
			{"name":"Quai des Long-Courriers", "kind":"quai", "offset":Vector3(-178, 1, -84)},
			{"name":"Halles du Monde", "kind":"marche", "offset":Vector3(38, 3, 44)},
			{"name":"Entrepôts du Levant", "kind":"entrepot", "offset":Vector3(164, 3, -118)},
			{"name":"Taverne des Sept Vents", "kind":"taverne", "offset":Vector3(-88, 3, 136)},
			{"name":"Quartier des Armateurs", "kind":"quartier_riche", "offset":Vector3(124, 8, 168)},
			{"name":"Basses-Ruelles", "kind":"quartier_pauvre", "offset":Vector3(-202, 1, 68)},
			{"name":"Égouts de la Douane", "kind":"egouts", "offset":Vector3(204, -4, 42)},
			{"name":"Grue de l’Amirauté", "kind":"grue", "offset":Vector3(72, 26, -196)}
		]
	},
	{
		"id":"ruines_antiques", "name":"Ruines antiques", "subtitle":"Temples, mécanismes et galeries souterraines",
		"center":Vector3(4140.0, 2.0, 540.0), "radius":360.0, "elevation":2.0,
		"color":"766a50", "accent":"d8c18b", "weather":["soleil", "nuages", "brouillard", "pluie"],
		"jobs":["archéologue", "historien", "guide", "gardienne des ruines", "copiste", "explorateur", "tailleur de pierre", "marchande de reliques"],
		"fauna":["serpent", "chauve-souris", "lézard", "aigle"],
		"pois":[
			{"name":"Temple des Marées", "kind":"temple", "offset":Vector3(-142, 18, -118)},
			{"name":"Colonnade des Rois", "kind":"colonnes", "offset":Vector3(118, 6, -146)},
			{"name":"Porte des Énigmes", "kind":"porte", "offset":Vector3(206, 9, 22)},
			{"name":"Galeries du Sablier", "kind":"donjon", "offset":Vector3(-186, -8, 96)},
			{"name":"Statue de l’Ancienne Reine", "kind":"statue", "offset":Vector3(8, 12, 26)},
			{"name":"Jardin Envahi", "kind":"jardin", "offset":Vector3(142, 2, 166)},
			{"name":"Crypte des Gardiens", "kind":"crypte", "offset":Vector3(-48, -10, 212)},
			{"name":"Observatoire Brisé", "kind":"tour", "offset":Vector3(222, 24, -84)}
		]
	},
	{
		"id":"montagnes_enneigees", "name":"Montagnes enneigées", "subtitle":"Glaciers, blizzards et sommet principal",
		"center":Vector3(1580.0, 10.0, -160.0), "radius":355.0, "elevation":10.0,
		"color":"a9c8d8", "accent":"e8f6ff", "weather":["neige", "blizzard", "nuages", "soleil froid"],
		"jobs":["guide polaire", "bûcheron", "éleveuse", "garde du col", "pêcheur sur glace", "médecin", "aubergiste", "chercheuse de cristaux"],
		"fauna":["loup blanc", "chèvre des neiges", "ours", "aigle", "renard polaire"],
		"pois":[
			{"name":"Village du Givre", "kind":"village", "offset":Vector3(-128, 8, -92)},
			{"name":"Lac du Miroir Gelé", "kind":"lac_gele", "offset":Vector3(116, -1, -136)},
			{"name":"Grotte de Glace Bleue", "kind":"grotte", "offset":Vector3(194, 22, 72)},
			{"name":"Pont du Blizzard", "kind":"pont", "offset":Vector3(-184, 28, 118)},
			{"name":"Chalets des Guides", "kind":"habitation", "offset":Vector3(32, 5, 42)},
			{"name":"Couloir d’Avalanche", "kind":"danger", "offset":Vector3(78, 52, 204)},
			{"name":"Glacier des Ancêtres", "kind":"glacier", "offset":Vector3(-226, 34, -18)},
			{"name":"Sommet de l’Aurore", "kind":"sommet", "offset":Vector3(18, 96, -218)}
		]
	}
]

const NPC_NAMES := [
	["Maël Kergoat", "Lina Morvan", "Yann Le Guen", "Éloïse Marin", "Noham Le Bris", "Anaïs Pêcheur", "Gabin Cormier", "Mila Goéland", "Titouan Roche", "Inès Saline", "Alban Rivage", "Léonie Keravel", "Sohan Cabestan", "Maëlys Dune", "Ewen Phare", "Clara Ponton", "Noé Brisant", "Romane Écume", "Loris Filet", "Agathe Marée"],
	["Sylvain Chêne", "Éva Fougère", "Nolan Ruisseau", "Lise Mousse", "Bastien Lierre", "Yuna Clairière", "Émile Sureau", "Soline Genêt", "Liam Écorce", "Mélissa Brume", "Robin Canopée", "Apolline Racine", "Théo Bouvreuil", "Naëlle Liane", "Jules Champignon", "Célia Source", "Mathis Noisetier", "Alix Luciole", "Gaël Piste", "Morgane Aulne"],
	["Armand Roc", "Léa Pic", "Milo Granit", "Salomé Col", "Hugo Marteau", "Nina Cristal", "Gaspard Mine", "Jade Aiguille", "Oscar Schiste", "Louna Vallée", "Antonin Forge", "Maïa Éboulis", "Rémi Tunnel", "Zoé Altitude", "Côme Balcon", "Alice Ardoise", "Valentin Corde", "Nora Sommet", "Aymeric Pierre", "Flora Cascade"],
	["Martin Sillon", "Camille Verger", "Louis Moisson", "Louise Moulin", "Paul Prairie", "Emma Grange", "Arthur Blé", "Chloé Rivière", "Victor Orge", "Juliette Pommier", "Gabriel Foin", "Manon Étable", "Raphaël Avoine", "Sarah Colza", "Maxime Berger", "Élise Charrette", "Nathan Potager", "Lucie Luzerne", "Tom Épi", "Margot Ferme"],
	["Vulkan Braise", "Doria Scorie", "Silas Obsidienne", "Mina Soufre", "Ruben Cendre", "Nadia Basalte", "Elias Magma", "Soraya Fumerolle", "Marek Caldeira", "Talia Fournaise", "Noam Geyser", "Livia Rempart", "Ilan Charbon", "Yara Pyrite", "Sami Lave", "Elena Forgefeu", "Nassim Cratère", "Iris Roche-Noire", "Kamil Étincelle", "Maya Volcan"],
	["Basile Roseau", "Mina Brumel", "Anatole Vase", "Lola Nénuphar", "Cyril Pilotis", "Édith Racine", "Sacha Bourbier", "Nell Anguille", "Marin Héron", "Luce Brouillard", "Élie Saulaie", "Rosalie Grenouille", "Malo Ponton", "Irène Tourbe", "Nino Jonc", "Adèle Lanterne", "César Marécage", "Mélina Brume", "Gwen Îlot", "Orlane Moustique"],
	["Sahir Cendre", "Leïla Sirocco", "Amar Canyon", "Noura Oasis", "Khaled Dune", "Yasmine Relique", "Samir Vautour", "Nadia Caravane", "Ilyes Faille", "Meryem Vent", "Rayan Squelette", "Aya Poussière", "Anis Obélisque", "Lina Grise", "Malik Scorpion", "Inaya Source", "Farid Roche", "Salma Camp", "Nabil Horizon", "Dalia Tempête"],
	["Amaury Dock", "Léna Manifeste", "Boris Grue", "Clémence Écaille", "Nils Douane", "Sofia Comptoir", "Hector Ancre", "Yseult Taverne", "Marius Cargaison", "Diane Vigie", "Corentin Entrepôt", "Amina Négoce", "Félix Hauban", "Ophélie Gouvernail", "Tristan Cale", "Nora Amirauté", "Lazare Quai", "Émilie Cartographe", "Joris Barrique", "Maëlle Long-Cours"],
	["Dorian Archive", "Iris Colonne", "Achille Temple", "Cassandre Sceau", "Ulysse Crypte", "Alma Fresque", "Orion Statuaire", "Thaïs Sablier", "Énée Relique", "Clio Mémoire", "Nestor Galerie", "Ariane Labyrinthe", "Hector Pierre", "Gaïa Jardin", "Lysandre Rune", "Daphné Porte", "Solon Observatoire", "Maia Inscription", "Timon Gardien", "Électre Trésor"],
	["Bjorn Givre", "Alma Neige", "Eirik Glacier", "Solveig Aurore", "Nils Blizzard", "Freya Cristal", "Sven Chalet", "Liv Col", "Ivar Avalanche", "Astrid Loup", "Leif Lac-Gelé", "Ingrid Sommet", "Odin Guide", "Sigrid Flocon", "Erik Sapin", "Maja Glace", "Knut Piste", "Linnea Boréale", "Arne Fourrure", "Elsa Crampon"]
]

static func all_regions() -> Array:
	return REGIONS.duplicate(true)

static func region(index: int) -> Dictionary:
	return (REGIONS[clampi(index, 0, REGIONS.size() - 1)] as Dictionary).duplicate(true)

static func npc_profile(region_index: int, npc_index: int) -> Dictionary:
	var r := clampi(region_index, 0, REGION_COUNT - 1)
	var n := clampi(npc_index, 0, NPCS_PER_REGION - 1)
	var region_data: Dictionary = REGIONS[r]
	var jobs: Array = region_data["jobs"]
	var pois: Array = region_data["pois"]
	return {
		"id":"r%02d_n%02d" % [r, n],
		"name":String((NPC_NAMES[r] as Array)[n]),
		"job":String(jobs[n % jobs.size()]),
		"personality":String(PERSONALITIES[(r * 3 + n) % PERSONALITIES.size()]),
		"region":r,
		"region_name":String(region_data["name"]),
		"home_poi":n % pois.size(),
		"work_poi":(n * 3 + 1) % pois.size(),
		"meal_poi":(n * 5 + 2) % pois.size(),
		"social_poi":(n * 7 + 3) % pois.size(),
		"color":String(region_data["accent"]),
		"schedule":{
			"wake":5.5 + float(n % 4) * 0.35,
			"work_start":7.0 + float(n % 3) * 0.5,
			"meal":12.0 + float(n % 4) * 0.25,
			"work_end":16.5 + float(n % 5) * 0.35,
			"sleep":21.0 + float(n % 4) * 0.45
		}
	}

static func validate() -> Array[String]:
	var errors: Array[String] = []
	if REGIONS.size() != REGION_COUNT:
		errors.append("Le catalogue doit contenir exactement dix régions.")
	if NPC_NAMES.size() != REGION_COUNT:
		errors.append("Les listes de noms doivent couvrir les dix régions.")
	var region_ids := {}
	var npc_ids := {}
	for region_index in range(REGIONS.size()):
		var data: Dictionary = REGIONS[region_index]
		var region_id := String(data.get("id", ""))
		if region_id.is_empty() or region_ids.has(region_id):
			errors.append("Identifiant de région absent ou dupliqué : " + region_id)
		region_ids[region_id] = true
		if float(data.get("radius", 0.0)) < 320.0:
			errors.append("La région %s est trop petite pour la fondation V9." % String(data.get("name", region_id)))
		var pois: Array = data.get("pois", [])
		if pois.size() < 8:
			errors.append("La région %s doit posséder au moins huit points d’intérêt conçus manuellement." % String(data.get("name", region_id)))
		if region_index >= NPC_NAMES.size() or (NPC_NAMES[region_index] as Array).size() != NPCS_PER_REGION:
			errors.append("La région %s doit posséder exactement vingt identités de PNJ." % String(data.get("name", region_id)))
			continue
		for npc_index in range(NPCS_PER_REGION):
			var profile := npc_profile(region_index, npc_index)
			var npc_id := String(profile["id"])
			if npc_ids.has(npc_id):
				errors.append("Identifiant de PNJ dupliqué : " + npc_id)
			npc_ids[npc_id] = true
	if npc_ids.size() != TOTAL_NPCS:
		errors.append("Le catalogue doit produire exactement 200 PNJ.")
	return errors
