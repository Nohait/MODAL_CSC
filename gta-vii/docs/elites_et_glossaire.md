# Élites et glossaire

B ouvre le Carnet du pompier sur Bonus. L'onglet Glossaire est à sa droite. L'ouverture, la pause, l'animation et le retour à la boutique restent ceux du menu existant. Le bouton du HUD s'appelle désormais CARNET. Le nom technique de l'action `menu_bonus` est conservé pour respecter les touches déjà configurées.

## Probabilités et équilibrage

Ouvrir `scenes/systemes/ennemis/equilibrage_elites.tres` dans l'inspecteur. La chance commence à 5 %, augmente de 1,5 point par vague (ou salle dans le mode classique), puis plafonne à 30 %. Ainsi la vague 11 donne 20 %. Les élites restent minoritaires, même si le plafond est augmenté : la limite est 49 %.

Seuls le sbire, le chien et le kamikaze peuvent actuellement devenir élites : ils coûtent un point dans le pool zombie. Cela ne rajoute pas d'ennemis : une variante remplace le mobile normal, avec un seul modificateur. L'intégration commune fonctionne dans les deux modes, sans introduire les nouveaux types dans les compositions classiques.

Les six fichiers de `scenes/systemes/ennemis/modificateurs/` sont modifiables dans l'inspecteur : titre, description, couleur, symbole, poids de tirage et effets. Le poids sert au choix de la variante après la réussite du tirage élite. Chaque variante a initialement le même poids.

- Colosse : taille ×1,3, vie ×1,6 ; orange et ▲.
- Véloce : vitesse ×1,35 ; bleu et ».
- Enragé : sous 30 % PV, vitesse ×1,5 et dégâts ×1,4 ; rouge et !, pulsations renforcées.
- Meneur : aura de vitesse +25 %, rayon 5 m ; vert et ≋.
- Gardien : aura de résistance de 25 %, rayon 5 m ; violet et ◇.
- Ravageur : aura de dégâts +25 %, rayon 5 m ; jaune et +.

Les auras concernent les ennemis mobiles, source comprise. Deux auras identiques ne s'additionnent pas ; des auras différentes peuvent coexister. Les bonus sont recalculés toutes les 0,2 s et disparaissent lorsque l'ennemi sort du rayon ou que la source meurt. Le gel continue de se multiplier avec la vitesse obtenue. Le Colosse modifie aussi la collision et le rayon de navigation ; le scaling normal des PV selon l'étage reste désactivé.

## Fonctionnement et fichiers

`catalogue_ennemis.gd` est l'autoload CatalogueEnnemis. Il repère les véritables ennemis lors de leur ajout, choisit éventuellement leur modificateur, gère les auras et mémorise les découvertes. Les copies d'arrivée et les modèles du glossaire sont exclus : ils ne comptent pas comme des rencontres et ne participent pas au combat.

`elite_ennemi.gd` est un petit enfant de l'ennemi. Il applique ses valeurs de départ et construit le halo, le symbole et le contour coloré. `habillage_elite.gdshader` dessine le contour lumineux sans remplacer les matériaux du modèle. Le halo et le symbole restent visibles lorsque le gel remplace temporairement l'overlay.

Le sbire expose trois valeurs d'aura et les fonctions `multiplicateur_vitesse()` et `multiplicateur_degats()`. Le chien et le kamikaze utilisent ces fonctions pour leurs propres attaques. La résistance est appliquée à l'entrée de `prendre_degats()`.

`scenes/interfaces/menus/glossaire/glossaire.gd` construit la liste, les boutons de variantes et l'aperçu 3D dans un SubViewport avec son propre éclairage. `apercu_ennemi.gd` récupère le modèle préparé puis enlève les comportements de combat et les collisions. Le modèle tourne lentement pendant la pause.

## Découvertes et debug

Une rencontre est enregistrée lorsque l'ennemi est dans le champ de la caméra, à moins de 24 m du joueur, sans mur entre eux. Découvrir une élite révèle sa fiche et sa variante, mais pas automatiquement la version classique. Les autres boutons restent des ?. Les découvertes sont stockées dans `user://glossaire.cfg` et conservées entre les parties.

Le bouton DEBUG — Tout débloquer, en bas à gauche du glossaire, révèle les huit fiches et les six variantes des trois mobiles éligibles. Il enregistre ce déblocage pour les prochaines parties. Il ne donne aucun bonus au joueur.

La liste commune des ennemis est dans `definitions_ennemis.gd` : nom, description, scène et option `elite_possible`. Le menu de debug reprend cette même liste. Ajouter un ennemi au glossaire n'ajoute donc pas automatiquement ce type aux vagues.

Les onglets Bonus et Glossaire sont des marque-pages de papier brûlé au-dessus du panneau. Le papier s’éclaircit progressivement au survol et sur l’onglet actif. La seule mention de pause est en bas à gauche.
