# ⛏️ Mine Brainrot (Roblox)

## Le but du jeu

1. **Tu apparais dans ta base**, un bâtiment style *Steal a Brainrot* avec ton nom sur le panneau, des lasers rouges à l'entrée (toi seul peux passer) et 10 podiums.
2. **Tu vas à la zone de minage** au milieu de la map : c'est un grand trou rempli de blocs, comme dans Minecraft. Tu casses le sol avec ta pioche et **tu descends couche par couche** sous la terre.
3. Chaque bloc cassé donne un peu de **Cash**. Certains blocs contiennent des **cristaux brillants** : ce sont des **minerais brainrot** qui te donnent une **carte**. La couleur des cristaux indique quel brainrot est dedans.
4. **Plus tu descends, plus les cartes sont rares**, mais les blocs deviennent plus durs. Certaines couches demandent une meilleure pioche.
5. Tes cartes apparaissent **en 3D sur les podiums de ta base** et **rapportent du Cash chaque seconde**.
6. Avec le Cash, tu **achètes une meilleure pioche** (Bois → Pierre → Fer → Or → Diamant), mais chacune est **verrouillée derrière un Rebirth**.
7. **Rebirth = 1000 Cash + 1 carte Tung Tung Tung Sahur**. Ton Cash repart à 0, mais tu gagnes **+50 % de revenu pour toujours** et tu débloques la pioche suivante.
8. La mine **se régénère toutes les 8 minutes** (tu es remonté à la surface automatiquement).

### Les couches de la mine

| Profondeur | Bloc | PV | Cash | Pioche minimum |
|---|---|---|---|---|
| 1 | Herbe | 2 | 1 | Bois |
| 2-4 | Terre | 2 | 1 | Bois |
| 5-10 | Pierre | 5 | 3 | Bois |
| 11-17 | Roche profonde | 12 | 8 | Pierre |
| 18-24 | Magma | 30 | 20 | Fer |
| 25-30 | Obsidienne | 70 | 50 | Or |

### Les brainrots

| Carte | Rareté | $/s |
|---|---|---|
| Tralalero Tralala | Commune | 1 |
| Lirilì Larilà | Commune | 2 |
| Boneca Ambalabu | Rare | 4 |
| Bombardiro Crocodilo | Rare | 6 |
| **Tung Tung Tung Sahur** | Épique | 12 |
| Cappuccino Assassino | Épique | 18 |
| Brr Brr Patapim | Légendaire | 40 |
| Ballerina Cappuccina | Légendaire | 60 |
| Chimpanzini Bananini | Mythique | 150 |
| La Vaca Saturno Saturnita | Secret | 500 |

Tous les chiffres (prix, PV, chances, vitesse des pioches...) se modifient dans **un seul fichier** : `src/ReplicatedStorage/GameConfig.lua`.

## Contrôles

- **Maintiens le clic gauche** sur un bloc avec la pioche en main pour miner (contour noir = bloc visé, barre de vie au-dessus).
- Boutons **🏠 Base** / **⛏️ Mine** pour te téléporter, **📦 Cartes** pour voir ta collection en 3D.
- Si tu es coincé au fond de la mine, clique sur **⛏️ Mine** pour remonter.

## Installation avec Rojo (recommandé)

1. Dans le dossier du projet : `.\rojo.exe serve`
2. Dans Roblox Studio : onglet **Plugins** → **Rojo** → **Connect**.
3. **Supprime les anciens scripts copiés-collés** (anciens `BrainrotServer`, `BrainrotClient`, le ScreenGui `BrainrotUI` dans StarterGui, et le dossier `RemoteEvents`) pour éviter les doublons.
4. Clique sur **Play**.

La map (sol, mine, bases) est **construite automatiquement par le script** quand le jeu démarre. La `Baseplate` et le `SpawnLocation` du template Roblox sont supprimés au lancement (sinon ils boucheraient la mine). Tu peux désactiver ça avec `CleanTemplate = false` dans `GameConfig`.

## Installation à la main (sans Rojo)

| Fichier du repo | Où le créer dans Studio | Type d'objet |
|---|---|---|
| `src/ReplicatedStorage/GameConfig.lua` | `ReplicatedStorage` → `GameConfig` | ModuleScript |
| `src/ReplicatedStorage/BrainrotModels.lua` | `ReplicatedStorage` → `BrainrotModels` | ModuleScript |
| `src/ServerScriptService/BrainrotServer.server.lua` | `ServerScriptService` → `BrainrotServer` | Script |
| `src/ServerScriptService/MineManager.lua` | `ServerScriptService` → `MineManager` | ModuleScript |
| `src/ServerScriptService/BaseManager.lua` | `ServerScriptService` → `BaseManager` | ModuleScript |
| `src/ServerScriptService/PickaxeBuilder.lua` | `ServerScriptService` → `PickaxeBuilder` | ModuleScript |
| `src/StarterPlayer/StarterPlayerScripts/BrainrotClient.client.lua` | `StarterPlayer > StarterPlayerScripts` → `BrainrotClient` | LocalScript |

## Comment c'est organisé

- `GameConfig` : tous les réglages du jeu.
- `BrainrotModels` : les personnages brainrot en 3D construits avec des Parts (utilisés sur les podiums et dans l'UI).
- `MineManager` : le trou de minage, les blocs couche par couche, les minerais, la régénération.
- `BaseManager` : les bases style Steal a Brainrot (piliers, panneau, lasers, podiums).
- `PickaxeBuilder` : la pioche pixel-art façon Minecraft (chaque pixel = un petit cube).
- `BrainrotServer` : argent, cartes, achats, rebirth, anti-triche du minage.
- `BrainrotClient` : l'interface, l'animation de coup de pioche, les particules, les sons.
