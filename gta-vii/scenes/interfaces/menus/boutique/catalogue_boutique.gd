extends RefCounted

# Palette partagée : les cartes tirées peuvent avoir une autre rareté que le booster.
const COULEURS = {
	&"commun": Color("f5f5f0"),
	&"rare": Color("569ccb"),
	&"epique": Color("af77c8"),
	&"legendaire": Color("efc35b"),
	&"temporaire": Color("008e5e"),
	&"synergie": Color("008e5e")
}
const NOMS = {&"commun": "Commun", &"rare": "Rare", &"epique": "Épique", &"legendaire": "Légendaire", &"temporaire": "Intervention", &"synergie": "Synergie"}
