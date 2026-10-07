# Fissures et graffitis

Les scènes réutilisables se trouvent dans `scenes/decors/decals/`. Les fissures utilisent un nœud `Decal`, sans script. Les graffitis utilisent un petit plan transparent et le script `graffiti_mural.gd`, pour éviter les défauts observés avec leur projection dans le Parking. Les images PNG 1K et leurs crédits se trouvent dans `assets/textures/decors/decals/`.

Les archives originales ont une image de couleur et un masque d'opacité séparés. Le masque est intégré au canal alpha du PNG : seul le dessin est visible, pas un rectangle autour. Les fissures utilisent aussi leur texture de normales pour simuler du relief ; cela ne creuse pas réellement le sol. Les graffitis sont des peintures mates, sans reflet spéculaire. Leur ordre de dessin permet de superposer proprement les anciennes peintures et les tags récents.

Les placements sont regroupés dans `TracesLocales`, à la racine des scènes `hall.tscn` et `parking.tscn`. Le Hall contient six nouvelles fissures (trois au sol, trois aux murs) et quatre graffitis ; le Parking sept fissures (cinq au sol, deux aux murs) et cinq graffitis. Les deux anciennes fissures procédurales du Hall sont conservées. Les tags se regroupent par endroits, se chevauchent légèrement et sont inclinés dans le plan du mur. Leur couleur et leur opacité varient pour évoquer des couches de peinture plus anciennes. Les autres modèles restent disponibles sans être placés pour éviter la surcharge.

## Placer une trace

1. Glisser une scène `fissure_*.tscn` ou `graffiti_*.tscn` dans la map.
2. Déplacer le decal pour que sa boîte traverse légèrement la surface. Par défaut, il projette vers le bas, sur le sol. Pour un mur nord, sa rotation X est de 90°.
3. Régler `Size` : X et Z donnent la largeur et la hauteur du dessin dans son plan ; Y donne la profondeur de projection (0,14 m ici). Garder une faible profondeur évite de toucher les surfaces voisines.
4. Régler `Albedo Mix` pour atténuer la couleur. Les textures ne sont ni lumineuses ni animées.

Pour les graffitis, régler `Taille`, `Teinte` (dont le canal alpha pour l’usure) et `Ordre` dans l’Inspector. Leur plan doit rester quelques millimètres devant le mur. Les fissures seules utilisent les réglages de Decal ci-dessus.

Les récepteurs des fissures utilisent la couche **visuelle 20**, en plus de leur couche habituelle 1. Le `Cull Mask` des decals ne vise que cette couche 20. Pour un nouveau mur ou sol, cocher la couche 20 dans `VisualInstance3D > Layers` du MeshInstance3D, en gardant la couche 1. Cela concerne le rendu, pas les couches de collision.

Les decals sont hors de la branche de navigation et ne possèdent aucune collision. Ils disparaissent progressivement au-delà de 45 m de la caméra. Ils nécessitent le rendu Forward+ ou Mobile de Godot, comme prévu par le projet ; Compatibility ne les affiche pas.

Le collage de tags est utilisé seulement dans le local technique du Hall, sous le « BURN ZONE ». Sa teinte atténuée suggère une ancienne accumulation de peintures.
