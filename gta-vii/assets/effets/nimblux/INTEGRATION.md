# Éclaboussures du hydrant

Source : NIMBLUX Lite v1.0.2, gennai, https://gennai.itch.io/free-rain-vfx-godot-4 . Licence conservée dans LICENSE.txt.

Seuls le générateur de quads et les fonctions de hasard sont repris ici. Le shader `scenes/armes/bouche_incendie/eclaboussures_nimblux.gdshader` adapte les éclaboussures du pack à un impact unique : pas de pluie ni de boucle, origine au hydrant et expansion radiale pendant sa durée d'onde.

Les petites gouttes utilisent des plans orientés vers la caméra. La grande couronne reste une géométrie 3D indépendante. Les deux effets sont regroupés dans `couronne_eau.tscn` et disparaissent ensemble.
