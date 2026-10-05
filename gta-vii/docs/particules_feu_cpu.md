# Flammes et erreur de rendu

L'erreur `draw_list_bind_uniform_set: uniform_set is null` vient du moteur de
rendu de Godot. Un bug confirmé des particules GPU peut libérer leur jeu de
données de transformation lors de la première émission, alors que le rendu
garde encore une référence vers ces données. Des affichages incorrects et une
répétition du message peuvent alors apparaître.

Référence : https://github.com/godotengine/godot/issues/122005

La capture du collègue correspond à ce message, mais le problème n'a pas été
reproduit sur cette machine. Les textures de l'étage 2 ne sont donc pas modifiées
sur la seule base de la capture. Le contournement cible les petits feux GPU
communs aux ennemis, qui utilisent ce mécanisme lors de l'activation d'une salle.

`scenes/effets/feu/flames.tscn` utilise maintenant CPUParticles3D. La conversion
conserve les maillages, shaders visuels, couleurs, durée, émission et courbe de
taille. Le processeur calcule la simulation ; la carte graphique dessine toujours
les flammes. Chaque feu utilise 20 particules, les flaques 30.

Les réglages des sbires, flaques et kamikazes sont adaptés : les paramètres se
trouvent directement sur l'émetteur CPU, sans ParticleProcessMaterial.
L'animation des mains du sbire anime sa couleur ; les versions dorées restent
dorées. Aucun PV, dégât, timing d'attaque ou comportement n'est changé.
Cette scène étant partagée, le contournement concerne les deux modes.
Le jet de l'extincteur reste en particules GPU ; ce n'est pas une conversion
générale de tous les effets.

Validation : six téléportations entre les étages 1, 2 et 3, avec tirs de
l'extincteur, sans erreur uniform_set pendant ce scénario. Cela ne confirme
pas à lui seul que ce bug était la cause exacte des flashs du collègue : il
faudra refaire son test sur sa machine.

## Flash pendant la visée de la tourelle

Le flash couvre tout l'écran et persiste après la conversion des flammes CPU.
Cette conversion n'a donc pas résolu le symptôme signalé. La cause exacte reste
à confirmer : les tests de cinq tirs à l'étage 1 et dix tirs après téléportation
à l'étage 2 n'ont pas reproduit le flash avec Direct3D 12.

Le test Vulkan n'a pas résolu le flash sur la machine du joueur. Le projet
revient donc à Direct3D 12 ; ce changement nécessite de redémarrer l'éditeur.

Le joueur décrit maintenant une grande image de flamme rouge, verte ou bleue.
Une nouvelle correction cible uniquement les flammes de la tourelle :
scenes/effets/feu/flammes_simples.tscn remplace le VisualShader partagé par un StandardMaterial3D
avec le mode Billboard Particles, prévu pour les particules CPU. La texture
existante est conservée, avec une couleur orange et un mélange additif. Les
particules grandissent puis rétrécissent grâce à une courbe de taille.

L'œil et le projectile utilisent cette scène, avec une échelle uniforme.
Le projectile avait une échelle X de 4,19, Y de 0,42 et Z de 3,01 : sa silhouette
était fortement étirée avant même l'orientation des sprites vers la caméra.
La nouvelle scène règle la taille directement sur les particules. Le laser,
les délais, dégâts, collisions et flaques créées à l'impact restent identiques.
Les flammes des sbires, kamikazes et du décor ne sont pas modifiées par ce correctif.

Ces réglages suspects sont supprimés, mais la cause des couleurs incorrectes
reste à confirmer par un nouveau test sur la machine où le flash apparaît.

Le déclenchement a ensuite été précisé : le flash survient quand un projectile
crée sa flaque, et non pendant la visée. La flaque utilisait encore flames.tscn.
Elle utilise désormais flammes_simples.tscn également, en conservant ses réglages
de petites flammes réparties sur la surface. L'effet simple est rangé dans les
effets partagés plutôt que dans le dossier de la tourelle.

projectile_tour.gd règle l'emplacement et la taille avant add_child : _ready et
l'émission des particules démarrent ainsi avec leur position définitive.
Le test crée douze projectiles dirigés vers le sol, puis vérifie qu'une flaque
est effectivement ajoutée après chaque impact. Les précédents tests de tirs
ne garantissaient pas un impact au sol : un mur peut supprimer le projectile.

Le flash est aussi signalé pendant les apparitions d'autres ennemis, dans les
deux modes. Le VisualShader partagé vfx_fire.tres utilisait encore le billboard
générique (1) ; son nœud Billboard utilise désormais le mode particules (3).
Cette correction conserve les textures, la dissolution, les couleurs et les
paramètres des émetteurs. Elle concerne les utilisateurs de flames.tscn,
notamment sbires, artilleurs, kamikazes et mini-boss.

Un test graphique de 64 apparitions couvre les huit types du catalogue, avec
leurs scripts _ready mais sans déplacement ni attaque. Aucun flash observé ni
erreur uniform_set pendant le test ; les avertissements de textures à la sortie
du moteur restent présents. Le flash intermittent n'ayant pas été reproduit
localement, cette validation ne confirme toujours pas sa disparition chez le joueur.

## Initialisation des flaques après un tir esquivé

La flaque changeait amount de 20 à 30 dans son _ready, après le démarrage de
l'enfant CPUParticles3D. Le code Godot de set_amount réalloue le MultiMesh et
agrandit particle_data. Le premier calcul peut donc précéder ce redimensionnement,
alors que le transfert des données a lieu ensuite dans frame_pre_draw.
Cette séquence est suspecte pour un affichage intermittent de taille/couleur
incorrecte ; le lien avec le flash signalé reste à confirmer sur la machine concernée.

Les 30 particules sont maintenant définies dans flaque_de_feu.tscn, avant
l'entrée dans l'arbre. Le script ne redimensionne plus leur allocation. Après
les réglages de rayon, couleur et mouvement, restart recalcule immédiatement
l'émetteur avec ses paramètres définitifs. Le preprocess existant de 0,65 s
permet de conserver de petites flammes déjà présentes à l'apparition.

Référence du fonctionnement CPU :
https://github.com/godotengine/godot/blob/4.7-stable/scene/3d/cpu_particles_3d.cpp

Validation : 100 impacts au sol, en supprimant les anciennes flaques entre
les impacts, avec vérification de leur création et du nombre de 30 particules.
Pas d'erreur uniform_set pendant le test ; avertissements de textures à la
sortie du moteur inchangés. Dégâts, collisions et absence de pièces sont conservés.

## Premier affichage des flammes partagées

Un flash est encore signalé au spawn du sbire. L'émetteur commun flames.tscn
avait fixed_fps = 30 et preprocess = 0. Dans CPUParticles3D::_update_internal,
Godot active le dessin avant de vérifier si une simulation a été effectuée.
Si le delta initial est inférieur à 1/30 s, il peut ne calculer aucune étape et
ne pas appeler _update_particle_data_buffer lors de cette première mise à jour.
Cela laisse une séquence de premier affichage fragile, indépendante du shader.

Les deux émetteurs de flames.tscn ont désormais preprocess = 0.05 : cette petite
avance déclenche un calcul et la préparation des données dès leur démarrage,
même si le jeu tourne à plus de 30 FPS. Les textures, shaders, nombre, taille,
couleur et comportement des flammes sont conservés. L'effet commence simplement
avec 50 ms de simulation déjà effectuées. Cela concerne tous les utilisateurs
de cette scène, notamment les deux mains du sbire.

Validation : 160 apparitions rapides des huit types d'ennemis à 120 FPS maximum.
Vérification que chaque émetteur CPU visible à cadence fixe possède au moins
une étape de preprocess. Aucune erreur uniform_set pendant ce test ; les
avertissements de textures à la fermeture du moteur restent présents.
Le flash n'ayant pas été reproduit localement, la disparition du symptôme doit
encore être confirmée en partie sur la machine concernée.
