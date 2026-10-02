# Boutique, cartes et défis

## Essayer

Lancer main : après avoir éliminé tous les ennemis, franchir la porte ouvre la
boutique et met le jeu en pause. Un achat ouvre trois cartes ; en choisir une
applique son effet puis ramène à la boutique. Le bouton Continuer change de salle.
La dernière porte mène à la victoire sans boutique intermédiaire.

F6 sur prototype_boutique.tscn reste une démonstration indépendante. La vraie partie
réutilise cette interface avec mode_demonstration désactivé par l'UpgradeManager.
Les exports du prototype ne règlent donc pas l'équilibrage réel de la partie.

## Réglages dans l'inspecteur

Dans main, sélectionner UpgradeManager : prix des boosters, puissance des trois
raretés et bonus de base. Les puissances par défaut sont 50 %, 100 %, 150 %.
Pour des dégâts de base à +20 %, elles donnent +10 %, +20 %, +30 %.
Les trois cartes existantes sont proposées à chaque achat, dans un ordre aléatoire.
On choisit une seule carte par booster. Tous les gains s'additionnent sur la base.
Le récapitulatif conserve chaque carte acquise avec sa rareté et son vrai gain.

Pour les défis, ouvrir upgrade_manager.tscn, puis sélectionner son enfant DefiManager.
On peut régler les prix, les PV de la victime fragile, sa contribution aux points,
et les quantités de population supplémentaires. Le prix Sans une égratignure est
limité au lancement pour rester inférieur à celui du booster rare.

## Points

Chaque ouverture recompte les victimes vivantes de l'escorte : une normale vaut 1,
une fragile vaut 2 par défaut. Aucun point n'est conservé d'une boutique à l'autre.
Acheter la fragile ne rembourse pas des points immédiatement : sa contribution
apparaît à la prochaine boutique si elle est vivante. Les PV ne sont jamais remis
à zéro au changement de salle. Aucun bonus d'escorte n'est activé par les nouveaux
défis. Le code des anciens types de victimes reste conservé.

## Responsabilités et signaux

- prototype_boutique.gd affiche les offres et émet achat_demande, defi_demande,
  continuer_demande. Elle n'applique pas les récompenses en jeu.
- upgrade_manager.gd contrôle les points, les achats, le choix des cartes et la pause.
- defi_manager.gd conserve les objectifs et suit les événements de la partie.
- ligne_defi_apercu.gd construit une ligne et son dépliage, sans règles de combat.
- catalogue_boutique.gd partage les noms et couleurs de rareté entre cartes et boosters.

Le RoomManager annonce salle_preparee avant le démarrage : les victimes et mobiles
supplémentaires sont ajoutés sur des emplacements libres des salles préexistantes.
Ils suivent les règles habituelles du timer, des vagues et de l'ouverture de porte.
Il annonce salle_commencee lorsque le joueur reprend le contrôle, puis salle_terminee
lorsqu'il franchit la porte. La réussite Sans une égratignure est vérifiée à la porte,
et non au dernier ennemi tué. player.degats_recus n'est émis que pour une vraie perte
de PV : les impacts en mode invincible ne font pas échouer le défi.

Une vie précieuse crée immédiatement une victime violette plus petite, avec 20 PV,
via la libération habituelle du VictimManager. Sa mort retire le défi actif. Seul
le visuel est réduit : la collision habituelle est conservée.
Sans une égratignure rapporte un booster rare gratuit dans la boutique suivante.
Sauvetage sous pression ajoute jusqu'à 2 mobiles et 1 victime dans la prochaine
salle, selon les emplacements disponibles. Il est gratuit par défaut.
Un même défi ne peut être accepté deux fois simultanément. Un objectif terminé
peut être repris pour une autre salle. Une salle revisitée par le debug ne valide
pas deux fois la même récompense. Les tickets rares offerts restent disponibles
jusqu'à utilisation pendant cette partie ; ce ne sont pas des points économisés.

## Ajouter un vrai défi

Dans defi_manager.gd, ajouter une entrée à propositions avec id, titre, prix,
description et objectif. objectif = 1 affiche 0/1 ; objectif = 0 signifie un défi
sans durée limite et affiche les salles survécues. Le filtre retire automatiquement
les identifiants déjà actifs des propositions de la boutique.

Ajouter ensuite sa règle aux fonctions concernées : accepter pour un effet immédiat,
_preparer_salle pour modifier sa population, _commencer_salle pour initialiser l'objectif,
_recevoir_degats pour un défi lié aux PV, _terminer_salle pour décider du résultat.
Décrire explicitement sa récompense et retirer l'objectif des actifs lorsqu'il finit.
Pour un objectif sur plusieurs salles, incrémenter progression dans _terminer_salle
et ne le retirer que lorsqu'il atteint objectif. La boutique reconstruira alors
la barre avec le nouvel avancement à son ouverture.

Ajouter uniquement une description crée une offre, pas la logique de son objectif.
Les nouveaux types de récompenses demanderont aussi un traitement côté gestionnaire.

## Points de test

Appuyer sur I avant de franchir une porte, puis activer « Points abondants
(999 par boutique) ». Chaque prochaine boutique démarre avec 999 points,
indépendamment de l'escorte. Les achats déduisent toujours leur prix normalement.
Désactiver l'option remet le calcul habituel à la prochaine ouverture de boutique.
Le mode est désactivé par défaut et n'est pas conservé après une nouvelle partie.
Le menu de debug reste inaccessible lorsqu'un autre menu possède déjà la pause.
