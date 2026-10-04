extends RefCounted

# Palette partagée : un booster et les cartes qu'il contient ont la même rareté.
const COULEURS = {
	&"commun": Color("c6ac86"),
	&"rare": Color("569ccb"),
	&"epique": Color("af77c8"),
	&"temporaire": Color("55b5a5")
}
const NOMS = {&"commun": "Commun", &"rare": "Rare", &"epique": "Épique", &"temporaire": "Intervention"}
