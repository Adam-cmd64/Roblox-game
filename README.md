# ⛏️ Mine Brainrot (Roblox)

## Le but du jeu

1. **Mine** dans la grande mine au centre (26 x 26 blocs, 38 couches). Il n'y a pas de minerai dans les 2 premières couches : il faut creuser !
2. Les blocs avec des **cristaux brillants** contiennent un **brainrot** (46 brainrots, 14 raretés). Il va dans ton **sac**.
3. Dans **ta base** : ouvre le sac, **PRENDRE**, puis **E** devant un emplacement libre. Le brainrot apparaît en 3D sur le podium, avec sa carte derrière lui.
4. Chaque brainrot posé produit de l'argent sur son bouton **COLLECTER**.
5. **Verrouille ta base** avec le bouton rouge près de l'entrée : les lasers bloquent les autres pendant **40 s + 10 s par rebirth**. Quand ta base est ouverte, les autres peuvent **voler** tes brainrots (maintenir E) et doivent les ramener chez eux.
6. **Armurerie** (à l'est) : des battes. Un coup de batte fait **tomber le joueur 2 secondes** et lui fait **lâcher le brainrot volé**.
7. **Boutique** (à l'ouest) : les pioches de Bois à **Netherite** (il faut le rebirth ET l'argent).
8. **Rebirth** : de l'argent + 3 brainrots précis. Revenu +50 %, verrou plus long, nouveaux étages dans la base, pioche suivante.
9. **Index** : découvre tous les brainrots d'une rareté pour gagner un **bonus d'argent permanent** (+5 % pour les Communs... jusqu'à +50 % pour les OG).
10. **Roue de la fortune** : 1 tour gratuit toutes les 24 h (argent, brainrot Épique/Légendaire, potion, Booster OG).
11. **Vends** les cartes inutiles depuis le sac, **échange** avec les autres joueurs (3 rebirths d'écart max).
12. **Tapis roulants** entre les bases, la mine, la boutique et l'armurerie.

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
| Potion Chance x2 (15 min) | 50 R$ |
| 1 / 3 / 10 tours de roue | 100 / 250 / 850 R$ |

Pour les activer : **Creator Dashboard → ton jeu → Monétisation → Produits développeur**, crée chaque produit et copie son ID dans `GameConfig` (`BOOSTERS` et `PRODUCTS`, champ `ProductId`). Tant que l'ID vaut 0, c'est **gratuit dans Studio** (pour tester) et **désactivé en jeu**.

## Commandes admin (dans le chat)

Dans Roblox Studio tout le monde est admin. En jeu, ajoute ton UserId dans `GameConfig.ADMINS`.

- `/give sahur` ou `/give graipuss arc-en-ciel` : donne un brainrot (mutation optionnelle)
- `/cash 1000000`, `/rebirths 3`, `/pickaxe 6`, `/spins 5`, `/potion 15`
- `/mutation lave` : met une mutation sur la carte que tu tiens en main

## Images et sons

- **Vraies images des brainrots** : Studio → **Fenêtre → Gestionnaire de ressources → Images → Importer**, puis clic droit → **Copier l'ID** et colle-le dans le champ `Image` du brainrot dans `GameConfig.CARDS` (`Image = "rbxassetid://123456"`). Sans image, la carte affiche le modèle 3D.
- **Sons** : ils sont tous dans `GameConfig.SOUNDS`. Remplace les `Id` par des sons du Creator Store (`"rbxassetid://..."`) si tu veux d'autres bruitages.

## Sauvegarde

Argent, rebirths, pioche, batte, brainrots, index, tours de roue et potion sont sauvegardés.
Dans Studio : **Paramètres du jeu → Sécurité → Enable Studio Access to API Services**.

## Installation avec Rojo

1. `git pull`, puis `.\rojo.exe serve`
2. Studio : **Plugins → Rojo → Connect**
3. Supprime les vieux objets s'il en reste (`StarterGui > ScreenGui`, anciens scripts à la racine de `ServerScriptService`)
4. **Play** : toute la map est construite automatiquement.

## Tester sans Roblox Studio

`tests/run.sh` lance un simulateur de Roblox qui joue une partie complète à 2 joueurs (minage, poser une carte, collecter, rebirth, étages, ascenseur, boutique, booster, échange, sauvegarde, vente, verrou, vol, batte, roue, potion, index, armurerie) et affiche toutes les erreurs de script. Chaque propriété et méthode est vérifiée avec l'API officielle de Roblox.

## Organisation du code

- `src/ReplicatedStorage/GameConfig.lua` : **tous les réglages**
- `src/ReplicatedStorage/CardRenderer.lua` : le design des cartes
- `src/ReplicatedStorage/BrainrotModels.lua` : les 46 brainrots en 3D
- `src/ServerScriptService/BrainrotServer/` : le serveur (mine, bases, vol, battes, roue, boutiques, Robux, échanges, sauvegarde, admin, décor)
- `src/StarterPlayer/StarterPlayerScripts/BrainrotClient/` : l'interface et les effets
