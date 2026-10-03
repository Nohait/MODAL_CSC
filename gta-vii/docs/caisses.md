# Caisses embrasées

caisse.tscn contient un corps en retrait, douze traverses/montants aux arêtes et deux diagonales. Les BoxMesh ajoutent un vrai relief ; la collision reste un cube d’un mètre englobant les renforts.

caisse_bois.tres utilise caisse_embrasee.gdshader et les trois textures Wooden Planks de Poly Haven. Le shader projette le bois sur chaque face, utilise la normale pour les fibres, puis ajoute des taches de charbon et des fissures émissives. Le bruit dépend de la position dans le monde pour varier d’une caisse à l’autre. TIME anime uniquement la luminosité des braises.

Dans le matériau, relief ajuste la normale, brulure la carbonisation et intensite_braises la luminosité. FeuGauche et FeuDroite réutilisent flames.tscn à petite échelle. Lueur est une lumière orange de portée courte, sans ombres. Ces effets sont décoratifs : la caisse n’inflige pas de dégâts.
