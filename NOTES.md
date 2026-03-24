# BagBattler — Design Notes

Living document for open questions, design direction, and balance state.

---

## Core loop (current)

Draw tokens from bag → place in slots → execute → ATK × PRSR deals damage to entity → entity attacks back (reduced by DEF) → repeat until entity dies or player dies.

**Resources in play:** ATK, DEF, PRSR, HP, Salt, Depth

---

## Open design questions

### DEF × PRSR
PRSR multiplying DEF feels thematically weak ("pressure makes you tankier?"). Options:
- PRSR only multiplies ATK, DEF stays flat → simpler mental model
- Remove DEF entirely (see below)

**Status:** Not changed yet. Low-risk to test PRSR-ATK-only first (one line in Phase C).

### Remove DEF + Entity ATK entirely?
Would produce: **ATK × PRSR vs Entity HP over N turns** — structurally close to Balatro.
What stays original: bag/draw/crash, HZD, shells, moon phases, echo combos.

Concrete direction if pursued:
- DEF tokens removed from roster
- Entity ATK removed
- HP → turn counter ("X turns to kill")
- Heal tokens → +1 turn
- HZD → -1 turn (or costs a turn when drawn)
- Depth scaling → fewer turns + higher entity HP

**Status:** Ideating. Worth prototyping on a branch.

---

## Balance state (post S015)

- Echo combos (Depth Count + Streak Master + Tidal Mass) can snowball hard — entity mutations needed as counterweight
- HZD base count (2) not adjusted yet
- DEF tokens feel weak / unexciting compared to ATK/PRSR stack
- Moon phases cost 8 Salt each — not calibrated against echo costs yet

---

## Systems status

| System | Status |
|---|---|
| Token draw / bag / crash | Stable |
| Slot resolution (Phase A/B/C) | Stable |
| Echoes (14 implemented) | 9 need real icons · need review one-by-one |
| Shells (Dark/Striped/Nacre/Broken) | Broken Shell logic pending |
| Moon phases | Stable |
| Entity mutations | Not started |
| Jobs | Skeleton only |
| Corruption (token → HZD) | Not started |

---

## Echoes needing icons

Currently using `fortress.png` placeholder:
depth_charge, depth_count, tidal_mass, dead_weight, salt_merchant, predator, void_barrier, collector, salvage (9 total)
