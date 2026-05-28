# Habitat Echo — Game Design Document

A tiny Eclipse Phase fan game demo built in Godot 4.

## Concept

The player is a Firewall sentinel investigating a suspect cortical stack
inside a small orbital habitat module. A dormant async threat lurks in the
station network. The player must resleeve into different morphs to bypass
obstacles, complete the mission objectives, and survive a hostile nanite
swarm before it overwhelms them.

## Setting

- **Perspective:** 2D top-down
- **Map:** A single pressurised habitat room with a resleeving pod, a
  scannable device, and roaming nanite hazard.

## Morphs

The player's ego occupies one morph at a time. Switching happens at the
resleeving pod by pressing **Interact (E)**, which opens the morph-select
UI. Stats below are as implemented in `scripts/morph_manager.gd`.

| Morph      | Speed | Max Health | Ability      | Use                          |
|------------|-------|------------|--------------|------------------------------|
| Octomorph  | 150   | 80         | Wall-cling   | Default starting morph; fast |
| Synth      | 120   | 150        | Vacuum-seal  | Durable; survive the airlock |
| Biomorph   | 170   | 100        | Cyberbrain   | Interface with the terminal  |

The starting morph is the **Octomorph**.

## Player Controls

Only two input actions are defined (`project.godot`):

| Input          | Action                                   |
|----------------|------------------------------------------|
| WASD / Arrows  | Move (8-direction)                       |
| E              | Interact — pick up, scan, resleeve, talk |

Resleeving, dialogue, and device scanning are all driven by the single
Interact action.

## Core Loop

1. Explore the room and read environmental clues.
2. Walk to the resleeving pod and switch into the morph whose ability
   fits the current obstacle.
3. Use that morph's trait to advance an objective.
4. Avoid or outrun the nanite swarm while doing so.

## Objectives

Tracked in `scripts/mission_manager.gd`:

1. **Retrieve the cortical stack** (`retrieve_stack`).
2. **Scan the stack** at the terminal (`scan_stack`) — requires the
   Biomorph's cyberbrain ability.
3. **Vent the async signal** through the airlock (`vent_signal`) —
   requires the Synth's vacuum-seal ability.

## Win Condition

Complete all three objectives. A Firewall debrief / end screen confirms
mission success.

## Fail State

The habitat is patrolled by a **nanite swarm** (`scripts/nanite_swarm.gd`)
that chases the player, deals periodic damage, and drains Moxie on contact.
If the current morph's health is depleted the player dies; the player then
respawns (a resleeve), and the swarm pauses while the player is dead.

## Moxie / Stress

The player tracks a Moxie value, reduced by nanite contact and surfaced via
a Moxie bar UI (`scripts/moxie_bar.gd`). Health is shown via an HP bar
(`scripts/hp_bar.gd`).

## Art & Audio (Placeholder)

- Morphs and the nanite swarm currently use procedurally generated
  placeholder textures (colored blobs) until real sprites exist.
- No audio yet.

## License

> Habitat Echo is a fan work set in the **Eclipse Phase** universe created
> by Posthuman Studios LLC. Eclipse Phase is released under
> **CC BY-NC-SA**.
>
> This project is **dual-licensed**: source code under the
> **PolyForm Noncommercial License 1.0.0** (`LICENSE-CODE`), and assets and
> prose under **CC BY-NC-SA 4.0** (`LICENSE-ASSETS`). See `LICENSE` for the
> full scope breakdown.
>
> Eclipse Phase is a trademark of Posthuman Studios LLC. This fan game is
> not affiliated with or endorsed by Posthuman Studios.
