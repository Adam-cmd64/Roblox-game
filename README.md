# ⛏️ Mine Brainrot (Roblox)

## Le but du jeu

1. **Mine** dans la grande mine au centre (32 x 32 blocs, 60 couches : Terre, Pierre... jusqu'au Cristal, au Néant, au Cœur cosmique et au Noyau tout au fond). Il n'y a pas de minerai dans les 2 premières couches : il faut creuser ! La mine se **régénère toutes les 5 minutes**. Les blocs se fissurent quand tu les tapes (ils sont durs : il faut une bonne pioche pour descendre vite).
2. Les blocs avec des **cristaux brillants** contiennent une **carte brainrot** (35 cartes, toutes différentes, 14 raretés). Elle va dans ton **sac**.
   - Chaque carte a un **numéro de tirage** : **#1** = la toute première carte de ce brainrot trouvée dans le jeu (tous serveurs confondus), puis #2, #3...
   - Les cartes **Mythiques et +** sont **holographiques**, les Secret et OG ont un bord arc-en-ciel.
   - **Mutations** (Or, Diamant, Arc-en-ciel, Lave, Galaxie, Radioactif) : effets animés sur la carte (étincelles, lueur, bord qui tourne) et revenu x1,5 à x8. Plus tu as de chance (meilleure pioche, plus profond, potion), plus tu as de mutations.
3. Dans **ta base** : ouvre le sac, **PRENDRE**, puis **E** devant un emplacement libre. La grande carte apparaît debout sur le podium.
4. Chaque carte posée produit de l'argent sur son bouton **COLLECTER**.
5. **Verrouille ta base** : le bouton rond au sol, juste devant toi quand tu apparais dans ta base (marche dessus ou touche E). Les lasers bloquent les autres pendant **40 s + 10 s par rebirth**, au rez-de-chaussée **et à chaque étage** : impossible de passer (ni entre les lasers, ni par le toit, ni au grappin), seul le propriétaire entre. Les ascenseurs marchent pour tout le monde quand la base est ouverte. Quand ta base est ouverte, les autres peuvent **voler** tes cartes (maintenir E) et doivent les ramener chez eux. Quand on te vole, **une alarme rouge** s'affiche avec un son. Le voleur tient la carte dans sa main levée, entouré de rouge avec « 🚨 VOLEUR 🚨 » au-dessus de la tête (pas d'outil en main tant qu'il la porte).
   - **Alt+F4** : si le voleur quitte le jeu en portant ta carte, **il la garde** (quitter ne sert pas à y échapper).
6. **La boutique** (à l'ouest de la mine) : au comptoir, **E = les pioches** (10 pioches, de Bois jusqu'à la Pioche du Vide : il faut le rebirth ET l'argent), **F = les battes et les grappins** (eux aussi demandent des rebirths : battes en métal 1, or 3, diamant 5, cosmique 7 ; grappin 1, renforcé 3, laser 6).
   - **Prix des rebirths** : $15K, $150K, $1,5M, $12M, $100M, $800M, $6B, $50B, $400B, $3T (puis x8 à chaque fois).
   - **Grappin** : prends-le en main, vise un mur, un toit ou un arbre et clique : tu t'envoles jusque là (Grappin 60 studs, renforcé 90, laser 130). Pas possible en portant une carte volée, et **pas de téléportation (boutons MINE / BASE) avec une carte volée** : il faut la ramener à pied. Un coup de batte fait **tomber le joueur 2 secondes** et lui fait **lâcher la carte volée**.
7. **La roue de la fortune** (à l'est de la mine) : **E = tourner** (1 tour gratuit toutes les 24 h), **F = acheter des tours** (1, 3 ou 10). Tout le monde voit la roue tourner : ampoules qui défilent, halo de rayons, flèche qui claque sur les picots, et au gain tout clignote dans la couleur du lot avec une colonne de lumière. Gains : argent, carte Épique/Légendaire, potion, Booster Galaxie.
   - **Coup de batte** sur un voleur : la carte **tombe par terre** 30 secondes. **N'importe qui** peut la ramasser (touche E) : le propriétaire la récupère direct, les autres doivent la ramener chez eux. Personne ? Elle rentre chez son propriétaire.
   - **Pirater une base verrouillée** : au panneau vert à droite de l'entrée, mini-jeu des fils : **4 fils à couper dans l'ordre**, l'ordre **reste affiché**, et tu as **10 secondes**. Réussi : les lasers **restent allumés** mais on enlève **un quart du temps de verrouillage** (s'il en restait moins, ils s'éteignent), puis 1 minute d'attente avant de repirater cette base. Raté : tu es repoussé, l'alarme prévient le propriétaire, et tu dois attendre 2 minutes.
8. **Rebirth** : de l'argent + 3 cartes précises. Revenu +50 %, verrou plus long, nouveaux étages dans la base, pioche suivante.
9. **Index** : découvre toutes les cartes d'une rareté pour gagner un **bonus d'argent permanent** (+5 % pour les Communs... jusqu'à +50 % pour les OG). À gauche, un onglet par **mutation** (Normal, Or, Diamant, Arc-en-ciel, Lave, Galaxie, Radioactif) : chaque carte doit être trouvée dans chaque mutation, sinon on ne voit que sa silhouette.
   Paliers de l'Index : 5, 10, 20, 30 et 35 brainrots découverts = argent, tours de roue et potion (réglages : `GameConfig.DEX_REWARDS`).
10. Dans le **Sac** : **💰 VENDRE** ouvre un menu pour vendre toute une rareté (de Commun jusqu'à OG, seulement les cartes du sac), **⭐ ÉQUIPER LES MEILLEURS** pose automatiquement tes brainrots qui rapportent le plus.
    - **Carte en main** : touche **G** (ou le bouton RANGER sur téléphone) pour la remettre dans le sac. **Maintiens E 3 secondes** sur un autre joueur pour **lui donner la carte** (3 rebirths d'écart maximum). **Échange** avec les autres joueurs (3 rebirths d'écart max).
11. **Tapis roulants** entre les 8 bases, la mine, la boutique et la roue.
12. **Classements** : 2 grands panneaux entre la mine et la roue : **💰 les 10 plus riches** et **⚡ les 10 meilleures bases** (argent par seconde). Top 10 de tous les serveurs, mis à jour chaque minute.
13. **Récompenses quotidiennes** : un **pop-up s'ouvre tout seul** quand tu arrives dans le jeu (et le bouton **🎁 Cadeaux** du menu). Une récompense toutes les 24 h, 7 jours d'affilée (argent, tours de roue, minerais, potion, carte Légendaire, et le **jour 7 = minerai de diamant**). Plus de 48 h sans venir : la série repart au jour 1.
    - **Cadeau de départ** (une seule fois) : le **coffre doré** sur la dalle en pierre à côté de la roue. Entre dans la **zone jaune** (ou touche E), mets le jeu en **favori ⭐** et un **like 👍** : **une carte Très Rare au hasard + $15 000**. (Roblox permet de vérifier le favori, mais pas le like : le bouton « J'ai mis un like » fait confiance au joueur.)
14. **Minerais** : Argent (+25 %), Or (+50 %), Émeraude (+80 %), Diamant (+120 %), Netherite (+200 %). Sac → **◆ MINERAIS** → choisis un minerai puis le brainrot qui le reçoit : il gagne plus d'argent **pour toujours** (un minerai par brainrot, on peut le remplacer par un meilleur).
    - **Coffres dans la mine** : des blocs-coffres en bois cerclés de fer, **très rares** : à chaque régénération de la mine, il y a **1 coffre au maximum**, et 55 % de chances qu'il n'y en ait **aucun**, à partir de la couche 4. En les cassant tu gagnes **toujours** un minerai : Argent 56 %, Or 30 %, Émeraude 11 %, Diamant 2,7 %, Netherite 0,3 %.
15. **Le portail mystère** : un grand anneau lumineux du côté de la roue. Il sera fonctionnel bientôt.

## ⚠️ À faire une fois : importer les images des cartes et les sons

Les images et les sons doivent être envoyés sur Roblox (Rojo ne peut pas le faire). Il y a seulement **6 fichiers** :

| Fichier | Où coller l'ID dans `src/ReplicatedStorage/GameConfig.lua` |
|---|---|
| `assets/cards/cartes1.png` | `GameConfig.CARD_ATLASES`, 1re ligne |
| `assets/cards/cartes2.png` | `GameConfig.CARD_ATLASES`, 2e ligne |
| `assets/cards/cartes3.png` | `GameConfig.CARD_ATLASES`, 3e ligne |
| `assets/sounds/sons.ogg` | `GameConfig.SOUND_FILE` |
| `assets/icons/roue.png` | `GameConfig.WHEEL_ICONS` (les icônes de la roue) |
| `assets/sounds/musique.ogg` | `GameConfig.MUSIC_FILE` (la musique de fond) |

1. Dans Studio : **Fenêtre → Gestionnaire de ressources** (Asset Manager), puis le bouton **Importer** (Bulk Import).
2. Choisis les 5 fichiers ci-dessus.
3. Dans le Gestionnaire de ressources, dossier **Images** : clic droit sur `cartes1` → **Copier l'ID**, puis colle-le entre les guillemets de la 1re ligne de `CARD_ATLASES`. Pareil pour `cartes2` et `cartes3`.
4. Dossier **Audio** : clic droit sur `sons` → **Copier l'ID** → colle-le dans `SOUND_FILE`.
5. Dossier **Images** : `roue` → **Copier l'ID** → colle-le dans `WHEEL_ICONS`.
6. Dossier **Audio** : `musique` → **Copier l'ID** → colle-le dans `MUSIC_FILE`.

Exemple :

```lua
GameConfig.CARD_ATLASES = {
	"rbxassetid://123456789", -- ID de cartes1.png
	"rbxassetid://123456790", -- ID de cartes2.png
	"rbxassetid://123456791", -- ID de cartes3.png
}
GameConfig.SOUND_FILE = "rbxassetid://123456792"
GameConfig.WHEEL_ICONS = "rbxassetid://123456793"
```

Tant que les ID sont vides, les cartes affichent une étoile, la roue affiche des emojis et le jeu utilise des **sons de base de Roblox** (moins beaux que ceux de `sons.ogg`). (Roblox vérifie les fichiers envoyés : ils peuvent mettre quelques minutes à s'afficher.)

- **Les cartes** : chaque image contient 12 personnages détourés (fond transparent), avec un contour blanc façon autocollant. Ce sont uniquement des personnages en blocs (pas de personnages humains). L'ordre des cartes dans `GameConfig.CARDS` = l'ordre dans les images, donc **ne change pas l'ordre**. Pour ajouter une carte : mets-la à la fin de la liste avec sa propre image (`Image = "rbxassetid://..."`).
- **Les sons** : tous les bruitages sont dans `sons.ogg` (casse de bloc style Minecraft, coup de pioche, carte trouvée, pièce, roue...). Pour remplacer un son par un son du Creator Store, ajoute `Id = "rbxassetid://..."` à ce son dans `GameConfig.SOUNDS`.

## Raretés

Commun, Rare, Très Rare, Épique, Légendaire, Mythique, Abyssal, Enfer, Cosmique, God, Eternal, Angel, Secret, **OG** (OG : dans le Booster Céleste, ou 1 chance sur 8 000 avec la Pioche du Vide tout au fond de la mine).
Quand quelqu'un obtient une carte **Abyssal ou plus**, tout le serveur le voit dans le chat, en couleur (réglage : `GameConfig.ANNOUNCE_FROM_RARITY`).

Chances quand tu casses un bloc qui contient un brainrot (« 1 / 500 » = une fois sur 500) :

| Rareté | Bois, surface | Fer, couche 20 | Diamant, couche 30 | Émeraude, couche 45 | Vide, tout au fond | Vide, fond + potion |
|---|---|---|---|---|---|---|
| Commun | 92,3 % | 88,9 % | 84,4 % | 78,2 % | 64,9 % | 48,0 % |
| Rare | 6,5 % | 8,6 % | 10,7 % | 12,8 % | 14,4 % | 21,3 % |
| Très Rare | 1,0 % | 1,9 % | 3,1 % | 4,7 % | 7,1 % | 10,6 % |
| Épique | 1 / 493 | 1 / 196 | 1,1 % | 2,2 % | 4,5 % | 6,7 % |
| Légendaire | 1 / 2 408 | 1 / 694 | 1 / 242 | 1,1 % | 2,9 % | 4,3 % |
| Mythique | 1 / 12 042 | 1 / 2 520 | 1 / 667 | 1 / 202 | 1,8 % | 2,7 % |
| Abyssal | 1 / 60 209 | 1 / 9 145 | 1 / 1 837 | 1 / 431 | 1,2 % | 1,7 % |
| Enfer | 1 / 285 201 | 1 / 31 442 | 1 / 4 793 | 1 / 872 | 1 / 129 | 1,2 % |
| Cosmique | 1 / 903 136 | 1 / 72 272 | 1 / 8 359 | 1 / 1 179 | 1 / 129 | 1,1 % |
| God | 1 / 2,7 millions | 1 / 157 381 | 1 / 13 813 | 1 / 1 511 | 1 / 122 | 1,2 % |
| Eternal | 1 / 10,8 millions | 1 / 456 953 | 1 / 30 432 | 1 / 2 581 | 1 / 155 | 1 / 105 |
| Angel | 1 / 221,2 millions | 1 / 6,8 millions | 1 / 342 070 | 1 / 22 491 | 1 / 1 000 | 1 / 676 |
| Secret | 1 / 1,4 milliards | 1 / 30,9 millions | 1 / 1,2 millions | 1 / 60 337 | 1 / 1 988 | 1 / 1 343 |
| OG | 1 / 17,7 milliards | 1 / 285,1 millions | 1 / 8,3 millions | 1 / 327 862 | 1 / 8 003 | 1 / 5 406 |

La potion **Chance x2** rend toutes les raretés au-dessus de Commun 2 fois plus probables.

## Boutique Robux

| Produit | Prix |
|---|---|
| Booster Commun / Épique / Légendaire / Divin | 49 / 129 / 299 / 649 R$ |
| Booster Galaxie (exclusif, Mythique à Angel) | 999 R$ |
| **🌟 Pack Limited** (1 carte Limited par pack : Cappuccina Principessa 50 % • Gattino Smeraldino 35 % • Ranapesce Gigante 14,5 % • Gorillo Avocadillo 0,5 %) | 1 pack 80 R$ • 5 packs 450 R$ • 10 packs 699 R$ (au lieu de 800) |
| Booster Céleste (1 carte : 69,8 % Angel, 29,95 % Secret, 0,25 % OG) | 1499 R$ |
| **Argent x2 à vie** (Game Pass) | 30 R$ |
| **Tapis volant** (Game Pass) : prends-le en main pour voler (Espace = monter, Ctrl/Shift = descendre) | 349 R$ |
| **🤖 Collecte auto** (Game Pass) : l'argent des brainrots de ta base arrive tout seul, plus besoin des boutons COLLECTER | 149 R$ |
| **👑 Pack VIP** (Game Pass) : tag VIP au-dessus de la tête, [VIP] + messages en vert dans le chat, tapis volant, argent x2, collecte auto, 1 minerai de diamant + 1 de netherite. Le shop affiche la valeur si on achète tout séparément (976 R$, barrée) | **499 R$** |
| Minerai de Diamant / Netherite | 149 / 299 R$ |
| Potion Chance x2 (15 min) | 50 R$ |
| 1 / 3 / 10 tours de roue | 40 / 100 / 299 R$ |

### Brancher la boutique Robux (pour que les joueurs puissent VRAIMENT acheter)

Tant qu'un article a l'ID `0`, il est **gratuit dans Studio** (pour tester) et affiche **« Bientôt disponible ! »** dans le vrai jeu. Pour le rendre achetable, il faut le créer sur Roblox et coller son ID dans `src/ReplicatedStorage/GameConfig.lua` :

1. Va sur **create.roblox.com** → **Créations** → clique sur ton jeu.
2. Menu de gauche → **Monétisation** :
   - **Produits développeur** (on peut les acheter plusieurs fois) : boosters, potion, tours de roue, minerais.
   - **Passes** (achetés une seule fois, gardés à vie) : Argent x2, Tapis volant, Pack VIP.
3. **Créer** : mets le nom, une image, et **le même prix que dans le jeu** (c'est le prix du Dashboard que Roblox fait payer ; celui de `GameConfig` est juste affiché).
4. Copie l'**ID** (le nombre dans la page de l'article ou dans le lien, via « ⋯ → Copier l'ID »).
5. Colle-le dans `GameConfig.lua` à la place du `0` :

| Article | Type à créer | Où coller l'ID dans GameConfig |
|---|---|---|
| Booster Commun / Épique / Légendaire / Divin / Galaxie / Céleste | Produit développeur | `GameConfig.BOOSTERS` → `ProductId = ...` (une ligne par booster) |
| Pack Limited x1 / x5 / x10 | Produit développeur | `GameConfig.LIMITED_PACK.Offers` → `ProductId` (Limited1, Limited5, Limited10) |
| Potion Chance x2, tours de roue (1, 3, 10) | Produit développeur | `GameConfig.PRODUCTS` → `LuckPotion`, `Spin1`, `Spin3`, `Spin10` → `ProductId` |
| Minerai de Diamant / Netherite | Produit développeur | `GameConfig.PRODUCTS` → `MineralDiamant`, `MineralNetherite` → `ProductId` |
| Argent x2, Tapis volant, Collecte auto, Pack VIP | **Pass** | `GameConfig.GAMEPASSES` → `DoubleCash`, `FlyingCarpet`, `AutoCollect`, `VIP` → `GamePassId` |

Exemple : `{Id = "Commun", Name = "Booster Commun", Price = 75, ProductId = 1234567890, ...}`

6. Relance `rojo serve`, synchronise dans Studio, puis **Fichier → Publier sur Roblox**. Dans Studio, les achats avec un vrai ID sont des **achats de test** (aucun Robux n'est dépensé) : parfait pour vérifier que ça marche.

Pour un **Pass**, c'est aussi reconnu si le joueur l'achète sur la page du jeu (hors du jeu) : il l'a dès qu'il rejoint.

## Réglages à faire dans Roblox

- **8 joueurs maximum par serveur** : ça ne se règle pas dans le code. Creator Dashboard → ton jeu → **Places** → ta place → **Configure** (ou dans Studio : Paramètres du jeu → Places) → **Server Size / Taille max du serveur = 8**. (Il y a 8 bases, donc 8 joueurs.)

## Paramètres (bouton ⚙️ en haut à droite)

- 🎵 **Musique** oui / non
- 🖥️ **Graphismes allégés** : coupe les ombres, les particules, les traînées et les lumières (plus fluide sur les petits PC et les téléphones)
- 🤝 **Mes amis passent mes lasers** : quand ta base est verrouillée, tes **amis Roblox** peuvent entrer (pas les inconnus). Ils ne peuvent pas voler tant que la base est verrouillée.

Les choix sont sauvegardés.

## Autres nouveautés

- **Rebirth MAX = 10** (`GameConfig.MAX_REBIRTHS`) : ceux qui sont déjà au-dessus le gardent. Le **portail** demande **Rebirth 10** (`WORLDS[2].RequiredRebirths`), c'est écrit sur le panneau du portail.
- **💎 CRISTALLERIE** (monde 2, à l'est de la mine de cristal) : pavillon de verre bleu nuit, colonnes de cristal, dôme lumineux, marchand-hologramme, vitrines. Elle vend **8 PIOCHES DE CRISTAL** (Cristal, Aurore, Saphir, Néon, Nébuleuse, Prismatique, Supernova, Astrale) : il faut Rebirth 10 + la pioche d'avant. Tête en cristal transparent, bagues de néon, grosse lueur, éclats de cristal et poussière d'étoiles qui s'échappent, traînée lumineuse quand on frappe. Une grande animation « NOUVELLE PIOCHE ! » s'affiche à chaque achat.
  - **Équilibrage** : dans le monde 2, les blocs sont 4500x plus solides (il faut au moins la Pioche du Vide, puis les pioches de cristal pour descendre) et la chance de la pioche est divisée par 22 : c'est **aussi dur que le monde 1**. Dans le monde 1, les pioches de cristal sont énormes (chance jusqu'à x352).
  - Les brainrots du monde 2 sont **beaucoup plus forts** (de 5 000/s pour le Commun à 500 000 000/s pour le Secret, plus que l'OG du monde 1), et toujours aussi durs à trouver. Dans le monde 2, on ne trouve que des brainrots du monde 2.
- **Fusion** : une carte déjà fusionnée ne peut plus retourner dans la machine.
- **Mine du monde 2 refaite** : 72 couches à elle (`GameConfig.LAYERS_W2`), aucune comme dans le monde 1 : Poussière d'étoiles, Quartz bleu, Glace lunaire, Améthyste, Saphir des abysses, Néon fossile, Nébuleuse, Prisme, Cœur de supernova, Voile astral, Singularité. Chaque nouvelle couche demande la pioche de cristal suivante.
- **Rebirths jusqu'à 18** : les rebirths 11 à 18 demandent des brainrots du monde 2, et chacun débloque une pioche de cristal (Cristal = rebirth 11 ... Astrale = rebirth 18).
- **Fusion** : les 3 brainrots doivent être de la **même rareté** (pas 2 Secret + 1 God). Le sac de la machine ne propose que les cartes de la bonne rareté.
- **OG : chance FIXE** en minant : 1 minerai brainrot sur 12000, la même avec toutes les pioches (bois comme Astrale), à toutes les profondeurs, avec ou sans potion (`RARITIES.OG.FixedChance`). Le Booster Céleste garde ses 0,25 %.
- **Téléphone / tablette** : la zone en bas à gauche (joystick) et celle du saut (bas droite) ne cassent jamais de bloc, et faire glisser le doigt pour tourner la caméra non plus. On mine en appuyant sans bouger (un tap = un coup, doigt posé = on continue). Le HUD est plus petit et rangé : argent + minuteur en haut à gauche, menu en 3 x 2 à droite au-dessus du saut (réglages dans `Pointer.lua`).
- **Cartes plus belles** : ombre portée du personnage + ombre au sol, reflets de lumière en diagonale, nom sur un ruban de la couleur de la rareté, revenu dans un « billet » vert, pierres aux coins dès Rare, étoiles qui scintillent dès Épique.
- **Podiums des bases** : la carte éclaire son podium de la couleur de sa rareté (Très Rare et +) et un faisceau de lumière monte vers le ciel (Légendaire et +).
- **Bouton ⛏️ Pioches** (à la place de 🎁 Cadeaux, les récompenses du jour s'ouvrent toutes seules à la connexion) : il téléporte à la boutique de pioches du monde où tu es (la Cristallerie dans le monde 2). La carte trouvée en minant s'affiche en bas au milieu, en petit (elle ne cache plus l'écran), et le rebirth est dans une pastille sous l'argent.
- **HUD** : en haut au milieu, le grand badge du **monde** où tu es (entre MINE et BASE) ; le **minuteur de la mine** est en bas à droite ; le **guide des débutants** est en haut à droite (sous ⚙️) et ne s'affiche que pour les nouveaux (pas de rebirth, moins de 5 min de jeu).
- **Ciel du monde 2** tout nouveau : une galaxie spirale géante qui tourne, de grands anneaux de cristal, des piliers de lumière à l'horizon, un énorme cristal violet à la place de la lune, des météores cyan et de la neige de cristal.
- **🌌 MONDE 2 : la NUIT DE CRISTAL** (le Portail Mystère est ouvert : touche **E** devant le portail, animation de voyage « hyper-espace »). Un 2e monde complet, construit loin du premier dans la même map :
  - dalles bleu nuit avec quadrillage néon, arbres et flèches de cristal, lampadaires, îles flottantes, cristaux géants qui tournent dans le ciel, et un **autre ciel** (aurores cyan, lune de cristal géante) ;
  - sa **mine de cristal** : l'argent des blocs est **x2** et la chance **x1,5** ;
  - **8 bases** comme dans le monde 1 : quand tu passes le portail, **ta base déménage avec toi** (mêmes cartes, mêmes podiums). Le monde où est ta base est sauvegardé ;
  - **11 statues hologrammes** des brainrots du monde 2 ;
  - un **portail de retour** (touche E) vers le monde 1. Les boutons MINE et BASE t'emmènent dans la mine / la base de ton monde.
- **Brainrots du monde 2** (image : `assets/cards/cartes5.png`, déjà branchée : ID 94929535403110) : Bidone Zebrato, Cubotto Rossiccio, Bananito Lunare, Orsetto Galeotto, Aranciotto Baffuto, Maialino Mattoncino, Granchiobot Arancino, Tartina Zuccherina, Cactusello Fiorito, Bombardino Grigio et **Rana Pneumatica (SECRET)**. On les trouve **seulement en minant dans le monde 2**. Leur carte a un design à part : fond bleu nuit, quadrillage néon, cristaux, contour cyan qui tourne, « ✦ NUIT DE CRISTAL ✦ ». (Pesciolone Panciuto a aussi une nouvelle image : avant, c'était la même que la Limited Ranapesce Gigante.)
- **Mutations** : **Galaxie** ne sort plus que dans le **monde 2** ; **Lave** ne sort plus nulle part (elle reste dans l'Index et les cartes Lave déjà trouvées gardent leur bonus).
- **HUD plus beau** : panneau d'argent en verre avec contour animé, compteur qui défile, revenu par seconde (+$X/s) ; minuteur de la mine dans un cadre néon ; pastille du **monde** où tu es ; messages en pastilles colorées ; reflets qui passent sur les boutons du menu ; rayons de lumière derrière les cartes trouvées + « NOUVEAU BRAINROT ! ».
- **⚗️ Machine de Fusion** (à l'ouest de la mine, entre la boutique et les bases, touche **E** devant le pupitre) : on met **3 brainrots du sac** dans les 3 cases **+** (chaque + ouvre le sac en grand, trié par rareté). Le **meilleur des 3** est gardé (nom, mutation, numéro #) et devient **FUSIONNÉ** : il rapporte **l'argent des 3 cartes + 10 %** (ex : 3 Rares à 15/s → 45/s + 10 % = 49/s). Les minerais des 3 cartes sont comptés dedans. On peut refusionner une carte fusionnée (FUSION ++, +++...). Les cartes fusionnées ont un badge violet **⚡ FUSION** et un cadre électrique, se revendent plus cher, restent fusionnées quand on les échange, les pose ou se les fait voler, et sont sauvegardées. Réglages : `GameConfig.FUSION` (nombre de cartes, bonus, position).
- **Sac trié par rareté** partout (Sac, Machine de Fusion, Échange, Minerais) : la plus haute rareté d'abord, puis la carte qui rapporte le plus.
- **Échanges** : les 2 colonnes sont plus grandes, et la case **➕ AJOUTER** ouvre ton sac en grand (trié par rareté) pour choisir la carte à proposer.
- **Cartes LIMITED** : une nouvelle rareté, seulement dans le **Pack Limited** (boutique Robux), jamais dans la mine. Design à part : cadre doré irisé qui tourne, fond nuit étoilé, « LIMITED » en filigrane, rayons et étincelles dorés, diamants aux coins, numéro de tirage #. Elles sont rangées à part dans l'Index, dans l'onglet **🌟 LIMITED** (+30 % d'argent quand on a les 4) et ne se vendent pas en lot. Leur image est `assets/cards/cartes4.png` : importe-la dans Studio et colle son ID en 4e ligne de `GameConfig.CARD_ATLASES`.
- **Anglais / français** : le jeu est écrit en français, et il s'affiche **en anglais** pour tous les joueurs dont la langue Roblox n'est pas le français (menus, messages, panneaux dans le monde, boutons E, annonces dans le chat). Les traductions sont dans `src/ReplicatedStorage/Translator.lua` : pour en ajouter une, ajoute une ligne `{"texte français", "english text"}`.
- **Guide des débutants** : il disparaît pour toujours après **5 minutes de jeu au total** (temps sauvegardé).
- **Textes dans le monde** (Cadeau de départ, Portail mystère, Roue, Mine) : petits de loin, ils grossissent un peu quand on s'approche et disparaissent quand on est trop loin.
- **HUD** : en haut au milieu, **[⛏️ MINE] minuteur de la mine [🏠 BASE]** ; à gauche, 6 boutons (Sac, Index, Rebirth, Échange, Shop, Cadeaux) ; ⚙️ tout en haut à droite. Les boutons restent cliquables quand une fenêtre est ouverte : on passe directement du Sac à l'Index (pas besoin de la croix).
- **Téléphones** : toutes les fenêtres (Sac, Échange, Shop, Index...) et le HUD rétrécissent automatiquement pour rentrer dans l'écran : le bouton X est toujours visible.
  Sur téléphone, l'argent est en haut à gauche et le menu à droite (pour ne pas être sous le joystick), on mine et on vise le grappin là où on touche l'écran, un bouton ⬇ permet de descendre en tapis volant, et le bouton RANGER remplace la touche G.

- **Index** : les brainrots pas encore trouvés sont des **silhouettes noires** (pas de nom, pas de couleur), et 5 cartes **BIENTÔT** montrent qu'il y aura des mises à jour.
- **Gains hors-ligne** : quand tu reviens, ta base t'a rapporté 25 % de son argent par seconde pendant ton absence (3 h maximum).
- **Guide des débutants** : une bannière en haut dit quoi faire (miner → poser sa carte → collecter → acheter une pioche). Elle disparaît après la 2e pioche.

## Commandes admin (dans le chat)

Dans Roblox Studio tout le monde est admin. En jeu, seuls les UserId dans `GameConfig.ADMINS` le sont (ridaadam34 y est déjà), plus ceux à qui tu donnes `/admin @pseudo`.
Tape **`/aide`** (ou `/commandes`) dans le chat : une fenêtre montre toute la liste.

**Viser un autre joueur** : mets son pseudo juste après la commande, avec ou sans `@` (`/vip @Bob` ou `/vip Bob`, le début du pseudo suffit : 3 lettres minimum). `@all` (ou `@tous`) = tout le serveur. Sans pseudo, c'est pour toi.
**Montants** : `1k` = 1 000, `1m` = 1 million, `1b` = 1 milliard, `1t` = 1 000 milliards.

| Commande | Ce que ça fait |
|---|---|
| `/aide` | la liste des commandes dans le jeu |
| `/all [@joueur]` | TOUT : argent, rebirths max, meilleurs outils, tapis, VIP, une carte de chaque |
| `/give [@joueur] <brainrot> [mutation] [nombre]` | donne des cartes (ex : `/give @Bob sahur galaxie 3`) |
| `/cash [@joueur] <montant>` | ajoute de l'argent (ex : `/cash 10m`) |
| `/setcash [@joueur] <montant>` | met l'argent à ce montant (ex : `/setcash 0`) |
| `/rebirths [@joueur] <nombre>` | change les rebirths (`/rebirths 0` = les enlever) |
| `/pickaxe [@joueur] <1-10>` | change la pioche |
| `/pioche [@joueur]` | ✨ **Pioche Divine** : casse tout en 1 coup, même les couches ajoutées plus tard |
| `/unpioche [@joueur]` | enlève la Pioche Divine |
| `/bat [@joueur] <1-5>` | change la batte |
| `/grapple [@joueur] <0-3>` | change le grappin |
| `/mutation [@joueur] <mutation>` | mutation sur la carte tenue en main |
| `/mineral [@joueur] <argent/or/emeraude/diamant/netherite> [nombre]` | donne des minerais |
| `/spins [@joueur] <nombre>` | tours de roue |
| `/potion [@joueur] <minutes>` | potion Chance x2 |
| `/vip [@joueur]` / `/unvip [@joueur]` | donne / enlève le Pack VIP |
| `/carpet [@joueur]` | tapis volant |
| `/x2 [@joueur]` | argent x2 |
| `/autocollect [@joueur]` | collecte auto |
| `/dex [@joueur]` | débloque tout l'Index (cartes + mutations) |
| `/daily [@joueur]` | récompense quotidienne dispo tout de suite |
| `/starter [@joueur]` | le cadeau de départ peut être repris |
| `/speed [@joueur] <vitesse>` | vitesse de marche (16 = normal) |
| `/tp @joueur` | te téléporte sur lui |
| `/bring @joueur` | le téléporte sur toi |
| `/lock [@joueur]` / `/unlock [@joueur]` | verrouille / ouvre la base |
| `/resetmine` | régénère la mine tout de suite |
| `/announce <message>` | message pour tout le serveur |
| `/kick @joueur [raison]` | expulse un joueur |
| `/admin @joueur` / `/unadmin @joueur` | donne / enlève les commandes admin (jusqu'à la fin du serveur, seul le créateur peut) |

## Sauvegarde

Argent, rebirths, pioche, batte, cartes (avec leur numéro de tirage), index, tours de roue et potion sont sauvegardés.
Les numéros de tirage sont comptés dans un DataStore séparé (`BrainrotSerials_v1`).
Dans Studio : **Paramètres du jeu → Sécurité → Enable Studio Access to API Services**.
(Les anciennes cartes qui n'existent plus sont retirées automatiquement des sauvegardes.)

## Installation avec Rojo

1. `git pull`, puis `.\rojo.exe serve`
2. Studio : **Plugins → Rojo → Connect**
3. Supprime les vieux objets s'il en reste (`StarterGui > ScreenGui`, anciens scripts à la racine de `ServerScriptService`, `ReplicatedStorage > BrainrotModels`)
4. **Play** : toute la map est construite automatiquement (sol, mur, bases, mine, boutique, roue).

## Tester sans Roblox Studio

`tests/run.sh` lance un simulateur de Roblox qui joue une partie complète à 2 joueurs (minage, poser une carte, collecter, rebirth, étages, ascenseur, boutique E/F, booster, échange, sauvegarde, vente, verrou, vol, batte, roue dans le monde, potion, index) et affiche toutes les erreurs de script. Chaque propriété et méthode est vérifiée avec l'API officielle de Roblox.

## Organisation du code

- `src/ReplicatedStorage/GameConfig.lua` : **tous les réglages** (cartes, images, sons, prix...)
- `src/ReplicatedStorage/CardRenderer.lua` : le design des cartes
- `src/ServerScriptService/BrainrotServer/` : le serveur (mine, bases, vol, battes, roue, boutique, Robux, échanges, sauvegarde, admin, décor)
- `src/StarterPlayer/StarterPlayerScripts/BrainrotClient/` : l'interface et les effets
- `assets/cards/` : les 3 images des cartes, `assets/sounds/` : le fichier de sons
