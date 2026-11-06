extends RefCounted

# Palette partagée : les cartes tirées peuvent avoir une autre rareté que le booster.
const COULEURS = {
	&"commun": Color("969696"),
	&"rare": Color("f5f5f0"),
	&"epique": Color("c52d2f"),
	&"legendaire": Color("ff7779"),
	&"temporaire": Color("008e5e"),
	&"synergie": Color("008e5e")
}
const NOMS = {&"commun": "Commun", &"rare": "Rare", &"epique": "Épique", &"legendaire": "Légendaire", &"temporaire": "Intervention", &"synergie": "Synergie"}
