# Habitat Echo — Game Design Document

An Eclipse Phase fan game built in Godot 4.6. A **mission-hub** survival-horror:
you are a Firewall sentinel who egocasts into morphs at compromised sites to
contain async/exsurgent threats, returning to a safehouse between self-contained
ops.

_This doc is the snapshot of what's **implemented**. The forward-looking plan is
in `DESIGN_OUTLINE.md`; session continuity in `HANDOFF.md`._

## Structure

A persistent **hub** (safehouse) you mesh into between **ops** (self-contained
missions at distinct sites). Scene flow:

```
title → (New Game) → Op 0 (KE-7) → debrief → hub ⇄ deploy op ⇄ debrief → hub
        (Continue) → load save → hub
```

Boot scene is `scenes/title.tscn` (New Game / Continue / Quit).

## Autoloads (`project.godot`)

| Autoload       | Role |
|----------------|------|
| `GameState`    | Persistent cross-op state: moxie, trauma, reputation, credits, morph roster, gear, intel, op progress/flags, difficulty. JSON save/load, op-start checkpoint, ego-death fork. |
| `SceneFlow`    | hub⇄op⇄debrief transitions; `go_to_hub` / `deploy_op` / `begin_op` / `ego_death_fork`; checkpoint-on-deploy. |
| `OpCatalog`    | Registry of ops (`Op` resources): id, scene, objectives, briefing/debrief, credit reward. |
| `GearCatalog`  | Registry of buyable consumable gear. |
| `MorphManager` | Morph data + current morph. |
| `MissionManager` | Objectives for the op in progress, armed from the current `Op`. |

## Morphs (`scripts/morph_manager.gd`)

Switching happens at a resleeving pod (E → morph-select UI), costing 15 Moxie in
the field; free at the hub's resleeving bay.

| Morph      | Speed | HP  | Ability     | Field use                         |
|------------|-------|-----|-------------|-----------------------------------|
| Octomorph  | 150   | 80  | Wall-cling  | Reach tight/hidden spaces; fast   |
| Synth      | 120   | 150 | Vacuum-seal | Survive vacuum/fire/cryo sections |
| Worker Pod | 170   | 100 | Cyberbrain  | Hack / interface terminals        |

Default starting morph: **octomorph**. Each morph's **Moxie burn** (F, −30)
differs: octomorph scramble (2× speed + i-frames), synth EMP (clears swarms,
staggers the hunter 4s), worker pod medichine surge (full heal). (The
cyberbrain sleeve is a pod, not a biomorph — EP2e biomorphs run on wet
neurons; internal id stays `biomorph` for save compatibility.)

## Controls (`project.godot`)

| Input         | Action                                       |
|---------------|----------------------------------------------|
| WASD / Arrows | Move (8-direction)                           |
| E             | Interact — pick up, scan, resleeve, talk     |
| F             | Moxie burn (morph-dependent power, −30)       |
| G             | Use field gear (carried consumables)          |

## Ego / Moxie / trauma

Moxie is the real health bar — it **persists between ops** (the morph body is
disposable). Below the derangement threshold (35) control slows and a red glitch
wash flickers (`glitch_overlay.gd`). At Moxie 0 on death, ego death triggers the
**lose-continuity fork**: restore an older backup (op restarts), keep mechanical
progress (roster/gear/intel), gain a persistent **trauma** and a continuity
break. **Each carried trauma caps max Moxie by 10** until psychosurgery (paid)
cuts it out — culling Okafor, venting Halcyon, and dying all leave marks that
cost something to remove.

## The hub (`scenes/hub.tscn`)

Six interactable stations:

- **Op board** — pick an op → deploy (lists all `OpCatalog` ops, marks resolved).
- **Resleeving bay** — set morph loadout (free, no stress cost).
- **Quartermaster** — buy consumable gear with credits (slots: 4).
- **Psychosurgery** — restore Moxie, clear one trauma. **Costs 25 cr** (pay
  what you have if broke) — the bill is how the cull choice keeps its weight.
- **Handler** — branching dialogue / lore.
- **Debrief terminal** — recap rep, credits, ops resolved, continuity breaks, trauma.

## Gear (`scripts/gear_catalog.gd`, `field_gear.gd`)

Consumables bought at the quartermaster (max 4 carried), used in the field with
**G**:

| Gear            | Cost | Effect                                   |
|-----------------|------|------------------------------------------|
| Medichine Dose  | 20   | Heal HP + restore Moxie                  |
| EMP Charge      | 25   | Disperse all nanite swarms on the site   |
| Panic Farcaster | 40   | Emergency egocast back to the safehouse  |

Credits are awarded once per op on first completion (`Op.reward_credits`);
replays pay a flat 15 cr salvage so the economy can't zero out. Psychosurgery
(25 cr) is the recurring sink.

## Ops (sites)

Each op is a hand-built scene assembled on the shared template (briefing →
deploy/resleeve → infiltrate → investigate → complicate → contain → extract →
debrief). Registered in `OpCatalog`; objectives armed via `MissionManager`.

### Op 0 — KE-7 habitat (`scenes/main.tscn`, onboarding)

Retrieve a hidden cortical stack (Octomorph wall-cling) → scan it at a terminal
(Biomorph cyberbrain → hacking minigame, or skip via a crew NPC override) → vent
the async signal through the airlock (Synth vacuum-seal). A nanite swarm threatens
throughout. Reward: 40 cr.

### Op 1 — Derelict hauler (`scenes/op_hauler.tscn`)

Board a powerless, hull-breached freighter. Read the data log → resleeve to Synth
→ cross the **vacuum-breached hold** (`vacuum_zone.gd` drains HP/Moxie unless
vacuum-sealed) → recover a stranded ego (`recover_ego`) → reach the egocast point
(`extract`). Light async swarm. Reward: 55 cr. Unlocks after KE-7.

### Op 2 — Aphelion research lab (`scenes/op_lab.tscn`)

A lab gone dark; its own archive turned info-hazardous. The archive is a
**choice**: three partitions, one safe. Clues point to the right one (a hidden
note via Octomorph crawlspace, or a partial hint in the personnel records at a
small Moxie sting); the primary archive is a **basilisk hazard** — a heavy Moxie
hit, and containment drones wake on STANDARD+. Cold storage leaks cryo (the
vacuum-zone hazard, tuned mild) and holds **Dr. Okafor**, async-infected — the
first ethics fork:

- **Rehabilitate** (requires the recovered protocol): costs a Moxie backlash now,
  +1 Firewall rep, `researcher_saved` persists.
- **Cull**: instant and free — but a sticky **trauma** (`executioners_echo`)
  comes home with you, and `researcher_culled` persists.

Either way the lab notices, and pressure rises for the walk back to the relay.
The handler remembers your choice in later hub visits. Reward: 70 cr. Unlocks
after the hauler.

### Op 3 — Halcyon Station (`scenes/op_halcyon.tscn`, Act 2)

Three stacked decks joined by a maintenance **spine**: crawlway vents
(octomorph, silent) and an elevator (needs power, fast, **loud** — it tells the
hunter where you went). Deck A: arrival, a blacked-out concourse, the egocast
relay (dark until the end). Deck B: the info-hazard **vault** (cyberbrain,
Moxie bleed), harvested crew quarters, an automed. Deck C: vacuum-breached
hydroponics (with a medichine cache), fire-walled reactor, the backup
generator (cyberbrain → lights up the station, wakes the elevator… and is
heard), and the **containment core**.

**The Skriker** (`hunter.gd`): an exsurgent that hunts the decks. It cannot be
killed — only outrun, EMP-staggered (Synth burn or an EMP charge, 4s), or cut
off behind **sealable bulkheads** (it leaves, and finds another way). You hear
its **heartbeat** through the deck before you see it (distance-attenuated,
quickens to 1.45× when it has you); being near it with line of sight bleeds
Moxie. Speed 70/105/130 by difficulty.

**The climax** (needs power + payload): three ways to end Halcyon —
- **Vent the station**: +1 rep, but you read the manifest (Moxie toll now +
  the sticky `hundred_names` trauma).
- **Run Sava's counter-script**: works either way — but if you saved Okafor at
  Aphelion, her pattern guides it (+2 rep, clean); without her it costs a heavy
  Moxie spike and `network_exposed`.
- **Burn the payload**: nobody else dies, but Firewall docks the bounty
  (100 → 60 cr) and −1 rep.

Then the relay lights, the Skriker goes **berserk** (faster, near-instant
bulkhead patience, relocates toward you), and you run three decks home.
Reward: 100 cr. Unlocks after the lab.

## Threats & dread

Nanite swarms (`nanite_swarm.gd`) chase the player, dealing periodic damage and
Moxie drain; EMP-able and cleared on death. Vacuum/cryo sections damage
non-sealed morphs over time. Threat budget per op is deliberately scarce — fear
comes from limited Moxie/medichines and morph constraints, not enemy count.

**Difficulty scales pacing** (`GameState.swarm_count()`,
`hazard_moxie_mult()`): STORY halves psychic damage and skips retaliation
spawns; RELENTLESS doubles swarms and amplifies info-hazards.

**Whispers** (`whispers.gd`): while deranged (Moxie below 35), intrusive lines
fade in at irregular intervals — the async, or your own fraying ego; the game
never says which.

## Save model

Hub + op-start checkpoint: GameState is saved on hub entry and on deploy. Death
restarts the op (no mid-op saves). Continue loads the save and resumes at the hub.

## Art & Audio

- Original pixel sprites for morphs, the crew NPC, the swarm, and interactable
  objects (`art/`, generated by the `gen_*.py` scripts). Hub/hauler stations and
  a few objects use colored-square placeholders.
- A procedural resleeve SFX; otherwise no audio yet.

## License

> Habitat Echo is a fan work set in the **Eclipse Phase** universe created by
> Posthuman Studios LLC, released under **CC BY-NC-SA**.
>
> Dual-licensed: source code under the **PolyForm Noncommercial License 1.0.0**
> (`LICENSE-CODE`), assets and prose under **CC BY-NC-SA 4.0** (`LICENSE-ASSETS`).
> See `LICENSE` for the full scope breakdown.
>
> Eclipse Phase is a trademark of Posthuman Studios LLC. This fan game is not
> affiliated with or endorsed by Posthuman Studios.
