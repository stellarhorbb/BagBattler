# Bag Battler - Journal de Développement

## 3 Février 2026

**1. Création du système de jetons**
- Créé `TokenResource` (script de base pour les jetons)
- Ajouté 3 types : ATTACK, DEFENSE, HAZARD
- Créé 3 jetons concrets :
  - `basic-sword.tres` (ATTACK, valeur 3)
  - `shield.tres` (DEFENSE, valeur 5)
  - `hazard.tres` (HAZARD, valeur 0)

**2. Création du BagManager**
- Script `bag_manager.gd` avec les fonctions :
  - `add_tokens()` - Ajouter plusieurs jetons identiques
  - `draw_token()` - Tirer un jeton au hasard (et le retirer du sac)
  - `print_bag()` - Afficher le contenu du sac
  - `shuffle()` - Mélanger le sac
  - `reset_bag()` - Remettre tous les jetons dans le sac
- Testé en console, tout fonctionne ✅

**3. Création de l'interface UI**
- Scène `bag_ui.tscn` avec :
  - Titre du jeu
  - Affichage du nombre de jetons (par type)
  - Bouton "Tirer un jeton"
  - Bouton "Reset"
  - Affichage du dernier jeton tiré
- Script `bag_ui.gd` pour connecter tout ça

**4. Création de la ligne de combat visuelle**
- Scène `token_card.tscn` - Carte visuelle pour un jeton
- Script `token_card.gd` - Affiche icône, nom, valeur
- Couleurs différentes selon le type (rouge/bleu/gris)
- Les cartes s'alignent de gauche à droite
- Disparaissent au reset ✅

**5. Ajout de l'affichage des totaux de combat (Session du soir - 3 février)**
- Ajouté trois labels distincts dans `bag_ui.tscn` : `LabelAttackTotal` (rouge, gauche), `LabelDefenseTotal` (bleu, droite), `LabelHazardWarning` (orange, centre)
- Créé la fonction `update_combat_line_totals()` qui calcule et affiche les totaux d'attaque et défense de la ligne de combat
- Système d'avertissement pour les hazards : vide si aucun, "⚠️ 1 Hazard - Attention!" si un seul, "💀 CRASH!" si deux ou plus
- Correction bug reset : utilisation de `free()` au lieu de `queue_free()` pour remettre immédiatement les totaux à zéro
- Les totaux se mettent à jour automatiquement après chaque tirage ✅

## 9 Février 2026

**Système de combat complet ✅**
- Créé `EnemyResource.gd` et `Enemy.gd` pour gérer les ennemis
- Ajouté le bouton "EXÉCUTER" pour résoudre le combat
- Logique de combat fonctionnelle :
  - Calcul ATTACK et DEFENSE
  - Système de Crash (2 Hazards = 0 dégâts)
  - Dégâts infligés à l'ennemi
  - Réduction des dégâts par la défense
  - Les jetons retournent dans le sac après chaque tour
- Premier ennemi créé : Gobelin (20 HP, 5 ATK)
- Combat testé et fonctionnel !

## 9 Février 2026 (suite)

**Ajout du système de vie du joueur ✅**
- HP du joueur : 30 HP de base
- Affichage des HP avec changement de couleur selon l'état
- Dégâts ennemis appliqués au joueur
- Système de défaite (Game Over quand HP = 0)

**Amélioration du système de Crash ✅**
- Le Crash se déclenche IMMÉDIATEMENT au tirage du 2ème Hazard
- Plus besoin de cliquer sur EXÉCUTER
- Le joueur prend tous les dégâts sans défense
- La ligne se vide automatiquement
- Le tour passe directement à l'ennemi

**Le cœur du gameplay est fonctionnel ! 🎮**

**Système de sélection d'arme et navigation complète ✅**

- Créé `WeaponResource.gd` pour définir les armes (stats, sac de départ, passif)
- Créé l'arme "Sword" avec : 4 Attack, 3 Defense, 2 Hazards
- Passif Sword : "Steady Hand - 1er tirage sans Hazard"
- Renommé les jetons de base pour plus de clarté :
  - `basic-sword.tres` → `attack.tres`
  - `shield.tres` → `defense.tres`
  - `hazard.tres` reste tel quel

**Navigation entre les scènes ✅**
- Créé `main_menu.tscn` : écran titre avec "Démarrer" et "Options" (disabled)
- Créé `weapon_selection.tscn` : choix d'arme avec Sword (actif), Mage et Archer (grisés)
- Créé `game_manager.gd` (autoload) pour stocker l'arme sélectionnée et la progression
- Flow complet : Menu → Sélection Arme → Combat

**Adaptation du combat ✅**
- `bag_ui.gd` utilise maintenant l'arme choisie via GameManager
- Le sac se remplit automatiquement selon les stats de l'arme sélectionnée
- Définition du menu comme scène principale du projet

## 9 Février 2026 (Session 3 - Soir)

**Système de progression et transitions de combat ✅**

- Créé 3 ennemis avec difficulté croissante :
  - Goblin (20 HP, 5 ATK)
  - Goblin Elite (30 HP, 8 ATK)
  - Orc (40 HP, 10 ATK)
- Ajouté système de progression dans GameManager avec liste d'ennemis
- Battle_scene utilise maintenant l'ennemi actuel via GameManager
- Bouton "SUITE" après victoire → Charge le prochain ennemi
- Bouton "RETOUR AU MENU" après défaite → Retour au menu principal
- Fix z-index : boutons dessinés au-dessus de la CombatLine
- Renommé bag_ui → battle_scene pour meilleure sémantique

**La boucle complète fonctionne ! 🎮**
Menu → Sélection Arme → Combat → Victoire/Défaite → Progression/Retour

## 2 Mars 2026 — Session 1 : Refactor Architecture & Système d'Antes

**Refactoring terminologie : Weapon → Job ✅**
- `WeaponResource.gd` renommé/remplacé par `JobResource.gd`
- Tous les fichiers `.tres` et références mis à jour
- Terminologie cohérente avec le GDD (Knight, Mage, Assassin)

**Système de progression Antes & Rounds ✅**
- Créé `RoundStatsResource.gd` : stats par round (HP entité, ATK entité)
- Créé `EntityProgressionResource.gd` : liste de rounds pour la progression complète
- Numérotation des rounds : continu 1 → N (Ante calculé automatiquement : `(round - 1) / 4 + 1`)
- `GameManager` mis à jour : `current_round`, `advance_to_next_round()`, `get_current_round_stats()`
- Affichage UI : "Ante 1 — Round 1" ✅

**Refactoring sac de départ (JobResource) ✅**
- Créé `StartingTokenEntry` (inner class) : `token: TokenResource` + `count: int`
- `JobResource.starting_bag` = Array de `StartingTokenEntry`
- Remplacement du remplissage hardcodé dans `battle_scene.gd` par une boucle sur `starting_bag`
- Knight configuré : Strike ×3, Guard ×2, Provocation ×1, Rampart ×1, Hazard ×2

**Extension des types de jetons ✅**
- Ajout des types : `MODIFIER` (🟣), `UTILITY` (🟡), `CLEANSER` (⬜)
- `token_card.gd` mis à jour avec les couleurs et icônes correspondantes

**Écran de sélection de Job dynamique ✅**
- `job_selection.gd` : affichage dynamique de la composition du sac depuis `selected_job.starting_bag`
- Plus de texte hardcodé dans la scène

---

## 2 Mars 2026 — Session 2 : Système d'Effets Modulaire

**Architecture d'effets modulaire ✅**

Problème résolu : éviter le code spaghetti dans `battle_scene.gd` pour les effets de jetons.

Structure mise en place :
```
scripts/effects/BaseEffect.gd        → Classe parent, méthode apply() vide
scripts/effects/CombatContext.gd     → Contexte passé à chaque effet (cards, index, is_first, is_last, result)
scripts/effects/ResolveResult.gd     → Résultat modifié par les effets (total_attack, total_defense, damage_multiplier, rampart_active)
scripts/effects/EffectProvocation.gd → Logique Provocation isolée
scripts/effects/EffectRampart.gd     → Logique Rampart isolée
scripts/TokenEffectResolver.gd       → Orchestre la résolution, mappe enum → classes d'effet
```

**TokenEffect enum ajouté à TokenResource ✅**
- `TokenEffect` : NONE, PROVOCATION, RAMPART
- `@export var effect: TokenEffect` sur chaque jeton

**Effets implémentés ✅**

*Provocation :*
- Position 1 (premier tiré) : `damage_multiplier = 0.25` → ennemi inflige 25% de ses dégâts
- Autre position : `damage_multiplier = 0.75` → ennemi inflige 75% de ses dégâts

*Rampart :*
- Actif seulement si dernier jeton de la ligne au moment d'Exécuter
- Double toute la défense accumulée sur la ligne (résolution en deux passes)

**Preview dynamique des dégâts ennemis ✅**
- `update_combat_line_totals()` appelle `TokenEffectResolver.resolve()` en temps réel
- `label_enemy_intention` se met à jour à chaque tirage
- Si Provocation active : affichage `⚔️ 10 → 3 🟣` en vert
- Sans effet : affichage normal en rouge

## 2 Mars 2026 — Session 3 : Bag Inspector UI

**Système d'inspection du sac ✅**

Remplacement du `LabelBagInfo` statique par un système d'inspection dynamique en deux états :

- **Vue compacte** (toujours visible) : cercles colorés par type avec count ×N, ordre fixe, affiche ×0 quand un type est épuisé pendant le round
- **Modal au clic** : tableau détaillé groupé par type → nom → count → % de tirage (calculé avec les poids)

Architecture mise en place :
- `BagManager.get_bag_composition()` : construit un dictionnaire `{ type → { nom → { count, percent } } }` tenant compte des poids
- `bag_inspector.tscn` : scène dédiée instanciée dans `battle_scene`
- `bag_inspector.gd` : génère les deux vues dynamiquement, `refresh()` appelé après chaque tirage/exécution/reset

**Fix bug Crash ✅**
- Les jetons Modifier (Provocation) ne revenaient pas dans le sac après un Crash
- Remplacement du matching par icône par `child.token_data` directement — universel pour tous les types

**Reste à améliorer (backlog) :**
- Zone de clic CompactView encore imprécise
- Position du modal à repositionner
- Fermeture du modal au clic extérieur

## 12 Mars 2026 — Session : Économie, Coffres & HP Persistants

**Système d'économie (Gold) ✅**
- Ajout de `gold` et `turns_played_last_combat` dans `GameManager`
- Calcul automatique post-combat : base 5 gold, +2 si < 5 tours, -3 si > 10 tours, minimum 0
- Affichage gold + compteur de tours en temps réel dans `battle_scene`

**Stats upgradables depuis le Job ✅**
- `JobResource` : ajout des exports `base_damage`, `base_defense`, `base_hp`
- `knight.tres` mis à jour : 3 / 10 / 80
- `GameManager` : `init_run_stats(job)` copie les stats du job au démarrage de la run
- `TokenEffectResolver` : utilise `GameManager.base_damage` / `GameManager.base_defense` au lieu de `token.value`
- `token_card.gd` : n'affiche plus la valeur pour les tokens ATTACK et DEFENSE

**Système de récompenses post-combat (Coffre) ✅**
- Créé `RewardResource.gd` : enum `RewardType` (GOLD, HP_MAX, UPGRADE_DAMAGE, UPGRADE_DEFENSE, HEAL), enum `Rarity` (5 paliers)
- Génération aléatoire pondérée : Common 50%, Uncommon 30%, Rare 12%, Epic 5%, Legendary 3%
- Valeurs équilibrées pour ne pas casser l'économie dès l'Ante 1
- `reward_screen` : affiche gold gagné + efficacité + 3 cartes de récompense cliquables
- Transition : Victoire → Reward Screen → Shop → Combat

**Shop ✅**
- Créé `shop_screen.gd` + `shop_screen.tscn`
- 2 tokens achetables tirés aléatoirement via `shop_drop_weight`
- Prix calculé depuis le poids : rarer = plus cher
- Système de Reroll avec coût croissant (+2 gold par reroll)
- `shop_drop_weight` ajouté sur `TokenResource` (séparé du `weight` de tirage en combat)
- Tokens achetés conservés dans `GameManager.purchased_tokens`, ajoutés au sac au début de chaque combat

**VFX Combat ✅**
- Créé `scripts/vfx/battle_vfx.gd` : architecture extensible pour les effets visuels
- Flash rouge au tirage d'un Hazard
- Vignette rouge persistante tant qu'un Hazard est sur la ligne
- Gros flash + label "💀 CRASH !" pendant 2 secondes au Crash
- Suppression du `LabelHazardWarning` remplacé par les effets visuels

**HP Persistants sur toute la run ✅**
- `player_current_hp` stocké dans `GameManager`, persiste entre les rounds
- Reset uniquement au Game Over via `reset_run()`
- Soin de fin d'Ante : +25% HP Max automatique
- Récompense HEAL ajoutée au coffre (5 / 10 / 18 / 28 / 40 HP selon rareté)
- Upgrade HP Max : reste full si full life, sinon +50% de la valeur ajoutée

---

## 13 Mars 2026 — Session : Refonte & Système de Reliques

**Refonte de l'architecture du projet ✅**
- Nouvelle base propre avec les systèmes fondamentaux stabilisés
- Séparation claire des responsabilités entre scripts et scènes

**Système de Reliques ✅**
- Créé `RelicResource.gd` : reliques avec nom, description, rareté, passif
- Reliques affichées dans une ligne dédiée en bas de l'écran de combat (`RelicLine`)
- Shop : achat de reliques disponibles entre les rounds
- Raccourcis clavier pour accélérer la navigation en combat

---

## 18 Mars 2026 — Session 1 : Refonte du Combat (Draw/Place/Execute)

**Nouveau modèle de combat ✅**

Remplacement du système "tirer → auto-placer" par un flux en trois phases :
1. **Draw** : le joueur tire un jeton depuis le sac (carte révélée)
2. **Place** : le joueur fait glisser la carte sur un slot de la ligne de combat
3. **Execute** : résolution du tour une fois la ligne prête

**Drag & drop physique ✅**
- `DragController.gd` : gestion du drag, snap sur les slots, retour si slot occupé
- Les cartes suivent le curseur avec un léger décalage (physique d'inertie)
- Carte "fantôme" visible sur le slot cible pendant le drag

**Slots de combat ✅**
- 5 slots numérotés, chacun avec état vide/occupé
- Anneau de wave par slot : s'allume si le token est actif à l'exécution
- Bouton DRAW grisé quand la main est pleine ou un token en attente de placement

---

## 18 Mars 2026 — Session 2 : Tooltips Reliques, Sacrifice & Musique

**Tooltip Reliques ✅**
- `relic_tooltip.tscn` : panel noir, bordure blanche, header coloré par rareté
- `TooltipManager.gd` (autoload) : affiche/masque les tooltips, repositionnement intelligent (évite les débordements d'écran)
- Correction bug "tooltip vide au premier survol" : deux frames d'attente avant `reset_size()`

**Écran de Sacrifice ✅**
- Le joueur peut sacrifier des tokens du sac en échange d'une relique
- Affichage de la composition du sac, sélection du token à sacrifier, confirmation

**Musique & polish ✅**
- Musique de fond en combat et dans les menus
- Polish visuel du Shop et de l'écran de récompense
- Nouveaux assets d'icônes pour les reliques

---

## 18 Mars 2026 — Session 3 : Système de Pression & Refactoring

**Système de Pression ✅**
- Multiplicateur de pression qui s'applique sur l'ATK et la DEF à l'exécution
- Affiché dans la HUD, anime visuellement les valeurs avant la résolution
- La pression augmente au fil des rounds pour corser la difficulté

**Effets de slots visuels ✅**
- L'anneau autour de chaque slot s'allume en couleur selon le type de token actif (rouge ATK, bleu DEF…)
- Provocation et Rampart ont leurs propres indicateurs visuels

**Refactoring `battle_scene.gd` ✅**
- Scène découpée en trois classes séparées :
  - `DragController` : toute la logique de drag & drop
  - `BattleHUD` : mise à jour des labels, barres HP, annimations
  - `battle_scene.gd` : orchestration du flux de combat uniquement
- Code plus lisible et maintenable

---

## 18 Mars 2026 — Session 4 : Token Tooltips & QoL

**Tooltips pour les tokens ✅**
- `token_tooltip.tscn` : même shell que relic tooltip (noir, bordure blanche), sans header de rareté
- Affiche : nom, type coloré, description, effet de position (points de slots), règles de combo
- Points de slots : cercles colorés indiquant la/les positions actives — connecteurs uniquement entre positions adjacentes actives
- Déclenché au survol de toute carte (draw, shop, sac, ligne de combat)

**Click-to-place ✅**
- Cliquer sur un slot vide place directement le token en attente (en plus du drag)

**Polish & corrections ✅**
- Bouton DRAW désactivé (fond noir, texte gris) quand tous les slots sont remplis
- Tooltips désactivés pendant les banners de Crash et Saved
- Délai de 0.5s + screen shake avant l'écran de Crash au 2ème Hazard

---

## 19 Mars 2026 — Session : Refonte Data-Driven des Tokens & Polish Combat

**Suppression des tokens instables ✅**
- Supprimés : Gamble, Resonance, Reckless, Frenzy (+ effets GDScript associés)
- Conservé : Heal avec nouvelle mécanique (15% HP de base, +5% par token adjacent, 25% si premier slot)

**Refonte complète du système de tokens — architecture data-driven ✅**

Remplacement du système `TokenEffect` enum + code hardcodé par deux types d'effets composables directement dans les `.tres` :

- **Placement** : se déclenche quand le token est au bon slot (FIRST ou LAST)
- **Streak** : bonus par token dans un run (CONSECUTIVE = même type adjacent / ADJACENT = voisins quelconques)

Nouveau schéma `TokenResource` :
```
Placement : placement_slot, placement_target, placement_value, placement_count_scale, placement_count_type
Streak    : streak_target, streak_scope, streak_min, streak_value_per_token
Base      : base_target, base_value  (toujours actif)
```

Mapping des tokens existants :
- **Strike / Guard** : streak CONSECUTIVE ≥2 → +0.05 Pressure/token
- **Provocation** : base DAMAGE_MULT −20% + placement FIRST −10% supplémentaire
- **Rampart** : placement LAST → +0.05 Pressure × nb tokens DEF sur la ligne
- **Heal** : base HP 15% + placement FIRST +10% + streak ADJACENT ≥1 +5%/voisin

**Fichiers supprimés ✅**
- `BaseEffect.gd`, `CombatContext.gd`, `EffectProvocation.gd`, `EffectRampart.gd`, `EffectHeal.gd`
- `EffectFrenzy.gd`, `EffectGamble.gd`, `EffectReckless.gd`, `EffectResonance.gd`

**Resolver entièrement data-driven ✅**
- `TokenEffectResolver` lit directement les champs du resource, zéro `match token.effect`
- Ajouter un token = créer un `.tres`, aucun code à toucher
- `ResolveResult` : `placement_active_slots`, `streak_active_slots`, `inactive_slots`, `heal_events`

**Tooltip auto-généré ✅**
- `token_tooltip.gd` génère les labels d'effet et le bloc streak depuis les champs du resource
- Plus de `_set_effect_label()` avec match hardcodé

**Visuels de slots ✅**
- **Wave ring** : slot avec placement actif (Provocation, Rampart en position, Heal en premier)
- **Bordure colorée du slot** : streak actif ≥ streak_min (rouge ATK, bleu DEF)
- **Pulse heartbeat** : token card pulse à ~10% de taille quand streak actif
- Rampart grisé (token card) quand pas sur le dernier slot
- Provocation reste coloré même hors premier slot (base effect toujours actif)

**Décomposition du combat en étapes distinctes ✅**
- Tous les events (pressure + heal) résolus dans une seule boucle left-to-right, même timing 0.75s/carte
- **Étape 3** : Pressure × ATK/DEF labels animent
- **Étape 4** : ATK label tilt hard → Entity HP drop + SFX damage
- **Étape 5** : DEF label tilt hard → IntentionBox met à jour le DMG restant
- **Étape 6** : IntentionBox label tilt hard → Player HP drop + SFX damage ou safe
- Intention affiche directement la valeur finale (plus de "X → Y")

**SFX ✅**
- `damage.wav` : joueur frappe entité + entité frappe joueur (si dégâts > 0)
- `safe.wav` : DEF réduit les dégâts entité à 0
- `saved.wav` : banner Saved (relic protection), `crash.wav` uniquement sur vrai crash
- Musique en combat mise en sourdine temporairement

---

## 18 Mars 2026 — Session 5 : Système de Combo & Death Blow

**Système de Combo ✅**

Résolution en deux passes dans `TokenEffectResolver` :
- Passe 1 : effets spéciaux (Provocation, Rampart) + tokens sans combo
- Passe 2 : runs adjacents de même type → applique le meilleur multiplicateur

Combos implémentés :
- **Strike** : 2 adjacents → ×1.5 ATK / 3 adjacents → ×2.0 ATK
- **Guard** : 2 adjacents → ×1.5 DEF / 3 adjacents → ×2.0 DEF
- `active_combo_slots: Array[int]` dans `ResolveResult` → les slots concernés s'allument
- Les règles de combo sont lisibles dans le tooltip du token (section COMBO avec dots colorés)

**Death Blow ✅**

Quand le joueur tue l'ennemi mais aurait subi des dégâts :
- L'ennemi inflige quand même 50% de ses dégâts (calculés avant sa mort)
- Animation dans l'IntentionBox : "DEATH BLOW" pop avec tilt (spring), puis "−X HP" en contre-tilt
- Barre de vie du joueur s'anime pendant l'affichage
- 1s de pause puis transition vers l'écran de récompense

---

## 20 Mars 2026 — Session 6 : Slot scalable · Bugfixes resolver · Simplification visuelle

**Tooltip anti-spam au placement ✅**
- `TooltipManager.suppress_briefly()` : bloque le tooltip 0.5s après un drop (timestamp)
- Appelé dans `DragController.end_drag()` et `battle_scene._on_slot_clicked()`
- Hover intentionnel reste instantané

**Slot count scalable ✅**
- `GameManager.slot_count` (défaut 5) + `JobResource.slot_count` field exporté
- `battle_scene._ready` instancie les slots dynamiquement selon `GameManager.slot_count`
- `token_tooltip.gd` lit `GameManager.slot_count` au lieu d'une `const N_SLOTS`

**Bugfixes TokenEffectResolver ✅**
- `_placement_met` FIRST : `card_index == 0` → `slot_index == 0` (slot physique, cohérent avec LAST)
- `_apply_adjacent` : voisins filtrés par slot physique adjacent (abs distance == 1) ET même `token_type`
- Base effects (`DAMAGE_MULT`, `PRESSURE`) retirés de `placement_active_slots` — wave ring réservé au bonus de placement conditionnel

**Règle visuelle simplifiée ✅**
- Wave ring (`set_effect_state`) = placement bonus actif (bon slot)
- Pulse (`set_streak_pulse`) = streak bonus actif
- Bordure colorée slot (`set_streak_active`) supprimée — état redondant

**Poids récompenses post-combat ✅**
- `RewardResource._weighted_type()` : 40% Salt · 20% Heal · 20% Max HP · 10% Base ATK · 10% Base DEF

---

## 23 Mars 2026 — Session : Phases de Lune & Système de Shells

**Moon Phases — data-driven ✅**
- `MoonPhaseResource` refactorisé : `value: float` remplacé par 4 champs explicites : `atk_bonus: int`, `prsr_bonus: float`, `def_bonus: int`, `hp_bonus: int`
- `GameManager.apply_moon_phase()` simplifié : applique les 4 champs directement, plus de `match`
- `purchased_moon_phases: Array[MoonPhaseResource]` ajouté à GameManager, resetté au Game Over
- 5 phases créées en `.tres` : New Moon (ATK+1), First Quarter (PRSR+0.05), Full Moon (DEF+1), Last Quarter (HP+5), Blood Moon (toutes les stats)

**Blood Moon légendaire ✅**
- 5% de chance de drop depuis le Shell Nacré au lieu des phases normales
- Overlay spécial : pas de choix, titre "A GIFT FROM THE DEPTHS" — carte unique, moment mémorable
- Coût 0, accordé directement

**Système de Shells ✅**
- `ShellResource.gd` : `shell_type`, `shell_name`, `flavor_text`, `cost`
- 4 shells en `.tres` : Dark (Echo, 6 Salt), Striped (Token, 6 Salt), Nacre (Phase de Lune, 7 Salt), Broken (Sacrifice, 9 Salt)
- Shop redessiné : section Shells remplace les Items verrouillés, 2 shells aléatoires par visite, pas de reroll sur les shells
- Flow d'achat : survol → tooltip · achat → vibration 0.8s → overlay de choix
- Tooltip shell : même template que token/echo (fond noir, bordure blanche 4px, radius 12, marges 32/24, nom 52px, divider, description 26px)
- Flavor text stocké dans chaque `.tres`, zéro hardcodé dans le code

**Corrections GDScript (warnings) ✅**
- `BaseRelic.gd` : paramètres inutilisés prefixés `_`
- `bag_inspector.gd` : division entière `TOKEN_SIZE / 2` → `/ 2.0`, `ICON_SIZE / 2` → `/ 2.0`
- `TokenEffectResolver.gd` : `card_index` → `_card_index`
- `battle_hud.gd` : `atk_col`/`def_col` → `_atk_col`/`_def_col`
- `battle_scene.gd` : variable `s` renommée `style` (shadowing lambda param)
