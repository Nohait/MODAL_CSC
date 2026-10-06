extends RefCounted

# Palette partagée : les cartes tirées peuvent avoir une autre rareté que le booster.
const COULEURS = {
	&"commun": Color("c6ac86"),
	&"rare": Color("569ccb"),
	&"epique": Color("af77c8"),
	&"legendaire": Color("efc35b"),
	&"temporaire": Color("55b5a5"),
	&"synergie": Color("8ff4ef")
}
const NOMS = {&"commun": "Commun", &"rare": "Rare", &"epique": "Épique", &"legendaire": "Légendaire", &"temporaire": "Intervention", &"synergie": "Synergie"}
