# ⛏️ Mine Brainrot (Roblox)

## Le but du jeu

1. **Mine** dans la grande mine au centre (26 x 26 blocs, 38 couches). Il n'y a pas de minerai dans les 2 premières couches : il faut creuser !
2. Les blocs avec des **cristaux brillants** contiennent une **carte brainrot** (35 cartes, toutes différentes, 14 raretés). Elle va dans ton **sac**.
   - Chaque carte a un **numéro de tirage** : **#1** = la toute première carte de ce brainrot trouvée dans le jeu (tous serveurs confondus), puis #2, #3...
   - Les cartes **Mythiques et +** sont **holographiques**, les Secret et OG ont un bord arc-en-ciel.
   - **Mutations** (Or, Diamant, Arc-en-ciel, Lave, Galaxie, Radioactif) : effets animés sur la carte (étincelles, lueur, bord qui tourne) et revenu x1,5 à x8. Plus tu as de chance (meilleure pioche, plus profond, potion), plus tu as de mutations.
3. Dans **ta base** : ouvre le sac, **PRENDRE**, puis **E** devant un emplacement libre. La grande carte apparaît debout sur le podium.
4. Chaque carte posée produit de l'argent sur son bouton **COLLECTER**.
5. **Verrouille ta base** : le bouton rond au sol, juste devant toi quand tu apparais dans ta base (marche dessus ou touche E). Les lasers bloquent les autres pendant **40 s + 10 s par rebirth**. Quand ta base est ouverte, les autres peuvent **voler** tes cartes (maintenir E) et doivent les ramener chez eux.
6. **La boutique** (à l'ouest de la mine) : au comptoir, **E = les pioches** (de Bois à Netherite, il faut le rebirth ET l'argent), **F = les battes**. Un coup de batte fait **tomber le joueur 2 secondes** et lui fait **lâcher la carte volée**.
7. **La roue de la fortune** (à l'est de la mine) : **E = tourner** (1 tour gratuit toutes les 24 h), **F = acheter des tours** (1, 3 ou 10). Tout le monde voit la roue tourner. Gains : argent, carte Épique/Légendaire, potion, Booster OG.
8. **Rebirth** : de l'argent + 3 cartes précises. Revenu +50 %, verrou plus long, nouveaux étages dans la base, pioche suivante.
9. **Index** : découvre toutes les cartes d'une rareté pour gagner un **bonus d'argent permanent** (+5 % pour les Communs... jusqu'à +50 % pour les OG).
10. **Vends** les cartes inutiles depuis le sac, **échange** avec les autres joueurs (3 rebirths d'écart max).
11. **Tapis roulants** entre les 8 bases, la mine, la boutique et la roue.

## ⚠️ À faire une fois : importer les images des cartes et les sons

Les images et les sons doivent être envoyés sur Roblox (Rojo ne peut pas le faire). Il y a seulement **4 fichiers** :

| Fichier | Où coller l'ID dans `src/ReplicatedStorage/GameConfig.lua` |
|---|---|
| `assets/cards/cartes1.png` | `GameConfig.CARD_ATLASES`, 1re ligne |
| `assets/cards/cartes2.png` | `GameConfig.CARD_ATLASES`, 2e ligne |
| `assets/cards/cartes3.png` | `GameConfig.CARD_ATLASES`, 3e ligne |
| `assets/sounds/sons.ogg` | `GameConfig.SOUND_FILE` |

1. Dans Studio : **Fenêtre → Gestionnaire de ressources** (Asset Manager), puis le bouton **Importer** (Bulk Import).
2. Choisis les 4 fichiers ci-dessus.
3. Dans le Gestionnaire de ressources, dossier **Images** : clic droit sur `cartes1` → **Copier l'ID**, puis colle-le entre les guillemets de la 1re ligne de `CARD_ATLASES`. Pareil pour `cartes2` et `cartes3`.
4. Dossier **Audio** : clic droit sur `sons` → **Copier l'ID** → colle-le dans `SOUND_FILE`.

Exemple :

```lua
GameConfig.CARD_ATLASES = {
	"rbxassetid://123456789", -- ID de cartes1.png
	"rbxassetid://123456790", -- ID de cartes2.png
	"rbxassetid://123456791", -- ID de cartes3.png
}
GameConfig.SOUND_FILE = "rbxassetid://123456792"
```

Tant que les ID sont vides, les cartes affichent une étoile et le jeu est silencieux. (Roblox vérifie les fichiers envoyés : ils peuvent mettre quelques minutes à s'afficher.)

- **Les cartes** : chaque image contient 12 personnages détourés (fond transparent), avec un contour blanc façon autocollant. Ce sont uniquement des personnages en blocs (pas de personnages humains). L'ordre des cartes dans `GameConfig.CARDS` = l'ordre dans les images, donc **ne change pas l'ordre**. Pour ajouter une carte : mets-la à la fin de la liste avec sa propre image (`Image = "rbxassetid://..."`).
- **Les sons** : tous les bruitages sont dans `sons.ogg` (casse de bloc style Minecraft, coup de pioche, carte trouvée, pièce, roue...). Pour remplacer un son par un son du Creator Store, ajoute `Id = "rbxassetid://..."` à ce son dans `GameConfig.SOUNDS`.

## Raretés

Commun, Rare, Très Rare, Épique, Légendaire, Mythique, Abyssal, Enfer, Cosmique, God, Eternal, Angel, Secret, **OG** (OG : uniquement dans le Booster OG et la roue).

| Situation | Commun | Rare | Très Rare | Épique | Légendaire et + |
|---|---|---|---|---|---|
| Pioche en bois, couche 3 | 91 % | 7,4 % | 1,3 % | 0,3 % | ~0,09 % |
| Pioche en fer, couche 20 | 84 % | 11 % | 3 % | 1 % | ~0,6 % |
| Netherite, tout au fond | 65 % | 15 % | 7 % | 4 % | ~9 % |

La potion **Chance x2** rend toutes les raretés au-dessus de Commun 2 fois plus probables.

## Boutique Robux

| Produit | Prix |
|---|---|
| Booster Commun / Épique / Légendaire / Divin | 149 / 399 / 999 / 2499 R$ |
| Booster OG (exclusif) | 4999 R$ |
| Booster Céleste (1 carte : 70 % Angel, 29,9999 % Secret, 0,0001 % OG) | 2999 R$ |
| **Argent x2 à vie** (Game Pass) | 30 R$ |
| Potion Chance x2 (15 min) | 50 R$ |
| 1 / 3 / 10 tours de roue | 100 / 250 / 850 R$ |

Pour les activer : **Creator Dashboard → ton jeu → Monétisation → Produits développeur**, crée chaque produit et copie son ID dans `GameConfig` (`BOOSTERS` et `PRODUCTS`, champ `ProductId`).
Pour **Argent x2** : c'est un **Game Pass** (Monétisation → Passes), copie son ID dans `GameConfig.GAMEPASSES.DoubleCash.GamePassId`. Tant que l'ID vaut 0, c'est **gratuit dans Studio** (pour tester) et **désactivé en jeu**.

## Commandes admin (dans le chat)

Dans Roblox Studio tout le monde est admin. En jeu, ajoute ton UserId dans `GameConfig.ADMINS`.

- `/give sahur` ou `/give pandaccini arc-en-ciel` : donne une carte (mutation optionnelle)
- `/cash 1000000`, `/rebirths 3`, `/pickaxe 6`, `/spins 5`, `/potion 15`
- `/mutation lave` : met une mutation sur la carte que tu tiens en main

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
