# Site Layout — Halcyon Station (Act 2 escalation op)

_Design artifact for the bigger multi-deck site in `DESIGN_OUTLINE.md §3 (Act 2)`.
**BUILT (2026-06-11)** as `scenes/op_halcyon.tscn` + `op_halcyon.gd` +
`hunter.gd` + `bulkhead.gd` — the shipped op follows this blueprint with minor
deviations (the climax needs power + the vault payload rather than a separate
reach_core objective; the hunter is named the Skriker; deck rooms are two per
deck). Kept as the design reference._

## Premise

**Halcyon** is a derelict orbital research station that went dark mid-async
outbreak. Firewall lost a contact aboard — and the contact may now be
compromised. You egocast in to recover what they learned, contain the async
core, and get out. The station is **decaying live**: blackouts, fires, and
hull breaches spread as you move. Something intelligent is hunting you through
the maintenance spine.

## Vertical structure — three decks + a spine

The station is laid out as three stacked decks joined by a central **maintenance
spine** (a vertical shaft running A→B→C). The spine has two route types:

- **Elevator car** — fast, but only works where the deck has power. Blackouts
  lock it.
- **Crawlways** — narrow shafts paralleling the elevator; passable only by the
  **Octomorph (wall-cling)**. Always open, but slow and exposed to the hunter.

```
            ┌──────────────────── DECK A · Docking & Command ────────────────────┐
            │  Airlock/Arrival → Concourse(blackout) → Command Bridge            │
            │                         ↑ Egocast Relay (EXTRACT)                  │
            └───────────────┬───────────────────────────────┬───────────────────┘
                            │            SPINE               │
                       [elevator]                       [crawlway]   ← Octomorph
            ┌───────────────┴───────────────────────────────┴───────────────────┐
            │  DECK B · Habitation & Med                                         │
            │  Crew Quarters → Med Bay(autodoc/psycho) → Data Vault(sealed)      │
            │              (info-hazard)  ·  infected researcher NPC             │
            └───────────────┬───────────────────────────────┬───────────────────┘
                            │            SPINE               │
                       [elevator]                       [crawlway]
            ┌───────────────┴───────────────────────────────┴───────────────────┐
            │  DECK C · Reactor & Hydroponics                                    │
            │  Hydroponics(VACUUM breach) → Reactor(fire/timer) → Containment    │
            │                                       Core  ← the climax           │
            └────────────────────────────────────────────────────────────────────┘
```

## Decks

### Deck A — Docking & Command
- **Arrival / Airlock** — egocast-in point; a resleeving pod (your loadout swap).
- **Concourse** — a **blackout** zone: lights dead, visibility cut, the hunter
  ambushes here. A backup generator (Biomorph cyberbrain) can restore power and
  unlock the elevator.
- **Command Bridge** — station logs reveal the **twist**: your Firewall contact's
  last transmission is compromised (info-hazard flagged). 
- **Egocast Relay** — the **extract** zone. Only powered after the climax.

### Deck B — Habitation & Med
- **Crew Quarters** — scattered ego backups; an NPC researcher, async-infected,
  who pleads/threatens. Branch: **rehabilitate vs. cull** (first big rep fork).
- **Med Bay** — an **autodoc** (Moxie restore) and a psychosurgery cradle —
  a rare in-field safe spot to shed a trauma, at a cost.
- **Data Vault** — sealed (Biomorph cyberbrain hack). Holds the **info-hazard**:
  reading the wrong record sears Moxie / can trigger a derangement. The objective
  is to extract it *without* burning yourself out.

### Deck C — Reactor & Hydroponics
- **Hydroponics** — a hull **breach**: a depressurized **vacuum** section
  (Synth vacuum-seal), reusing `vacuum_zone.gd`. A shortcut to Containment.
- **Reactor** — **fire** damage zones; on higher difficulty a **breach timer**
  starts here (the difficulty-scaled pacing from §9: STORY = no timer, STANDARD =
  escalating fires, RELENTLESS = hard countdown).
- **Containment Core** — the climax. The async core is here.

## Morph-gating summary

| Route / obstacle            | Required morph        |
|-----------------------------|-----------------------|
| Crawlways (spine alt-route) | Octomorph (wall-cling)|
| Vacuum breach (hydroponics, hull) | Synth (vacuum-seal) |
| Data vault, reactor console, generator | Biomorph (cyberbrain) |

No single morph clears the station — you resleeve at pods on each deck, paying
Moxie each time, which is the core tension against the hunter and the timer.

## The Hunter (new threat)

Unlike the dumb nanite swarm, the **hunter** is a stalking exsurgent:

- Patrols the **spine**; investigates noise and high-Moxie-burn events.
- Hunts by **line-of-sight** in lit areas and by proximity in blackouts.
- Cannot be killed outright — only **evaded, blinded (EMP), or sealed away**
  (close a bulkhead behind you). It re-acquires after a cooldown.
- Forces stealth/route choices: the fast elevator is loud and lit; the crawlways
  are slow but quiet.

## Climax — the containment decision

At the Containment Core, with the hunter closing and (on RELENTLESS) the reactor
counting down, you choose how to contain the async. Each branch shifts reputation
and seeds an ending:

1. **Vent the habitat** — flush the decks to vacuum. Contains the async for
   certain, but kills the sleeved egos still aboard (incl. the researcher if
   spared). Cold, decisive, rep with hard-liners up.
2. **Trust the suspect ally** — let the compromised contact run a counter-script.
   It might work and save everyone — or the info-hazard takes the network. High
   risk, high reward, rep with your contact's faction.
3. **Burn the asset** — sacrifice the data vault (and what you came for) to
   starve the async. You contain it but go home empty-handed; Firewall is
   displeased, but no one dies by your hand.

After the choice, the Egocast Relay powers up → reach Deck A → extract → debrief.
The choice persists in `GameState` (a flag + rep delta) and gates later ops/endings.

## Build notes (reuse map)

- **Scene**: one `scenes/op_halcyon.tscn` + `op_halcyon.gd` on the Op template,
  registered in `OpCatalog`. Three deck "rooms" stacked vertically; follow camera
  with larger limits.
- **Reuse**: `vacuum_zone.gd` (hydroponics), `nanite_swarm.gd` (minor swarms),
  resleeving pods, dialogue + choices (NPC fork, climax), `field_gear.gd` (EMP to
  blind the hunter, panic farcaster to bail).
- **New**: `spine.gd` (elevator power-gating + crawlway routing), `hunter.gd`
  (stalk/seek/evade AI + bulkhead sealing), a fire `hazard_zone.gd` (generalize
  `vacuum_zone.gd`), and an optional `breach_timer` driven by `GameState.difficulty`.
- **Objectives**: `restore_power`, `extract_infohazard`, `reach_core`,
  `contain` (the decision), `egocast_out`.
