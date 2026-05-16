# Habitat Echo — Game Design Document

A tiny Eclipse Phase fan game demo built in Godot 4.

## Concept

The player is a Firewall sentinel investigating a suspect cortical stack
inside a small orbital habitat module. A dormant async threat lurks in the
station network. The player must resleeve into different morphs to bypass
obstacles, gather evidence, and neutralise the threat before it escapes
into the mesh.

## Setting

- **Perspective:** 2D top-down
- **Map:** A single pressurised habitat room (~640 × 480 playable area)
  divided into four zones:
  - **Lounge** — starting area, body bank with two spare morphs
  - **Server Alcove** — locked terminal; requires a morph with cyberbrain
    interface
  - **Med Bay** — resleeving pod, evidence sample
  - **Airlock Corridor** — final objective; requires a morph with vacuum
    sealing

## Morphs

The player's ego can occupy one morph at a time. Switching happens at the
resleeving pod in the Med Bay.

| Morph    | Trait              | Use                          |
|----------|--------------------|------------------------------|
| Splicer  | Standard mobility  | Default starting morph       |
| Infomorph| Cyberbrain access  | Interface with the server    |
| Synth    | Vacuum sealed      | Survive the airlock corridor |

Unoccupied morphs remain where they were left and can be retrieved later.

## Player Controls

| Input          | Action                |
|----------------|-----------------------|
| WASD / Arrows  | Move                  |
| E              | Interact / Pick up    |
| R              | Resleeve (at pod)     |
| Tab            | Open inventory        |
| Esc            | Pause menu            |

## Core Loop

1. Explore the room and read environmental clues.
2. Walk to the Med Bay pod and resleeve into the morph that fits the
   current obstacle.
3. Use that morph's trait to access a locked zone and collect evidence or
   advance the objective.
4. Return to the pod, resleeve again if needed, and repeat.

## Objectives

1. **Retrieve the cortical stack** from the Med Bay sample locker (any
   morph).
2. **Scan the stack** at the Server Alcove terminal (requires Infomorph).
3. **Vent the async signal** by opening the outer airlock (requires
   Synth).

## Win Condition

Complete all three objectives. A short Firewall debrief screen confirms
mission success.

## Fail State

None for this demo — the player can explore freely. A future version may
add a timer representing the async signal propagating through the mesh.

## Art & Audio (Placeholder)

- 16 × 16 px tile set, simple coloured sprites for morphs.
- Minimal ambient hum; UI blip on interact.

## License

> This is a fan work set in the **Eclipse Phase** universe created by
> Posthuman Studios. Eclipse Phase is released under the
> **Creative Commons Attribution-NonCommercial-ShareAlike 4.0
> International (CC BY-NC-SA 4.0)** license.
>
> This project is licensed under the same terms:
> **CC BY-NC-SA 4.0** — https://creativecommons.org/licenses/by-nc-sa/4.0/
>
> Eclipse Phase is a trademark of Posthuman Studios LLC. Some content
> used under the terms of the Creative Commons license is the property
> of Posthuman Studios LLC. https://eclipsephase.com
