# Habitat Echo — Game Design Outline

_Forward-looking design doc. Status snapshot of the actual code lives in
`game_design.md`; session continuity in `HANDOFF.md`. This doc is the "where
we're going" plan — iterate freely._

---

## 1. Vision & core fantasy

You are a **Firewall sentinel** — a deniable, off-the-books operative who
**egocasts into morphs at compromised sites** to contain existential threats:
async/exsurgent outbreaks, rogue TITAN tech, info-hazards, runaway nanoswarms.
You are not a soldier. You are a scalpel: infiltrate, understand what went
wrong, contain it, get your ego out. Death is cheap (you have backups) but never
clean — every resleeve frays you, and some things can't be backed up.

**Pillars**
1. **Transhuman puzzle-survival** — your *morph* is your toolkit; swapping
   sleeves is the core verb. Areas/threats are gated by morph abilities.
2. **Tension, not combat** — stealth, evasion, resource scarcity, dread. The
   nanoswarm/async hunts you; you rarely fight it head-on.
3. **Ego as the real health bar** — Moxie/stress/trauma persist and degrade you;
   bodies are disposable, the *self* is not.
4. **Consequence** — choices shift reputation, branch outcomes, and stick.

**Structure:** mission-hub. A persistent **safehouse** between **self-contained
ops** across **multiple sites**. Target for this build: **~2–4 hours**, designed
to extend indefinitely (more ops/sites/factions/metaplot) later.

---

## 2. The core loop

```
HUB (safehouse)                         FIELD (an op, at a site)
  briefing / pick op            ───►      deploy (egocast + resleeve)
  manage morph loadout                    infiltrate (explore, morph-gated)
  buy gear / intel / rep                  investigate (logs, NPCs, scans)
  psychosurgery (heal ego)                complicate (threats escalate; stress)
  talk to handler/contacts                contain (the objective)
            ▲                             extract (reach egocast point / survive)
            └──────── debrief ◄───────────  (rep, rewards, consequences, trauma)
```

Each op is a tight 15–30 min survival-horror vignette. The hub is the
progression and breathing space between them.

---

## 3. Progression outline (~3 acts, ~6–8 ops)

Pacing escalates threat, introduces one new wrinkle per op, and deepens the hub
between acts. The **current KE-7 build is Op 0**.

### Act 0 — Onboarding · "Echo" (KE-7 habitat) — *built*
The existing mission, reframed as your first contract. Teaches: move/interact,
resleeving + morph abilities, Moxie/stress + derangement, hacking, the swarm,
NPC/dialogue/rep, contain (vent the async). Ends → you're extracted to the hub.
~15–25 min.

### Act 1 — The loop · safehouse + 2 ops
- **Hub introduced.** Meet your **proxy handler**; the op board, morph roster,
  gear, rep, psychosurgery all come online.
- **Op 1 · derelict hauler** — board a powerless drifting freighter to recover a
  stranded ego (a cortical stack). Teaches **vacuum sections** (Synth/sealed
  morph required), no-power navigation, salvage. Light async traces.
- **Op 2 · research lab** — an async-infected researcher and an **info-hazard**
  (reading the wrong data sears your Moxie / can trigger derangement). Branch:
  rehabilitate vs. cull the infected ego → first big rep/ethics fork.
- Between ops: unlock a new morph + first gear tier.

### Act 2 — Escalation · 2–3 ops, rising dread
- Bigger multi-deck site; environmental decay (blackouts, depressurization,
  fire), a **hunter** exsurgent that stalks you (not just the dumb swarm).
- **Twist:** a Firewall contact is compromised / an info-hazard reaches the
  network. Trust fractures; rep and earlier choices gate options.
- Climax: a **containment decision** (vent a hab full of egos? trust a suspect
  ally? burn an asset?) with multiple resolutions → seeds the endings.

### Going further (post–few-hours)
New sites & biomes (Martian sublevels, a Titanian commune, a brinker rock),
factions & rep networks (@-rep, c-rep, g-rep), exotic morphs, an async metaplot,
roguelike-ish op generation, NG+. The hub + op template scale cleanly.

---

## 4. The hub (Safehouse)

A small persistent scene you mesh into between ops. Stations (interactables):
- **Op board** — pick the next op; shows site, threat level, intel, rewards.
- **Resleeving bay** — choose/preview your morph loadout for the op (your build).
- **Quartermaster / fabber** — buy gear & medichines with op rewards.
- **Psychosurgery suite** — spend resources/time to clear trauma & restore Moxie;
  some derangements are sticky and costly.
- **Handler & contacts** — story beats, lore, branching dialogue, rep, side intel.
- **Debrief terminal** — recap consequences, rep deltas, unlocks.

The hub reuses existing systems wholesale (interactables, dialogue+choices, rep,
Moxie, resleeving UI).

---

## 5. Op (mission) template — repeatable spec

Every op is assembled from the same beats so they're fast to author:

| Beat | Content | Reuses |
|------|---------|--------|
| Briefing | handler dialogue, objective, constraints (allowed morphs) | dialogue, rep |
| Deploy | egocast cutscene → resleeve into starting morph at the site | resleeve transition |
| Infiltrate | rooms gated by morph ability / hacking / hazards | walls+doors, morph gating, hack |
| Investigate | logs, NPC testimony, scans reveal "what happened" | data pads, dialogue, scannable |
| Complicate | threat escalates (swarm/hunter), stress spikes, choices | swarm, Moxie/derangement |
| Contain | the objective (retrieve / scan / vent / purge / extract an ego) | mission objectives |
| Extract | reach the egocast point or survive a timer | new (extract zone) |
| Debrief | rewards, rep, trauma carried home | end screen → hub |

**Threat budget per op:** scarce. A few swarms, one optional hunter, environmental
hazards. The fear comes from limited Moxie/medichines and morph constraints, not
enemy count.

---

## 6. Progression systems (what carries between ops)

- **Morph roster** *(extends current 3)* — you gain access to more sleeves; each
  is a build with ability + stats + flavor. Ops may force/allow specific morphs.
  Future: Ghost (stealth), Reaper (durable), Flexbot (shape), exotic uplifts.
- **Gear loadout** — limited slots you fill before deploying: hacking tools,
  medichine doses, a sensor/ping, a panic farcaster (emergency extract), a
  last-resort weapon. Bought with op rewards.
- **Reputation** *(extends override-rep)* — Firewall standing + faction nets.
  Choices shift it; it gates ops, gear, NPC aid, and endings.
- **Ego / Moxie / trauma** *(extends current)* — **persists between ops.** Stress
  accrues; derangements can carry home; psychosurgery clears them at a cost.
  Hitting ego-death = restore from backup: lose continuity & some progress
  (narrative + mechanical stakes), not a hard game-over.
- **Intel / knowledge** — unlock site maps, threat data, and new op options.

---

## 7. Action tree hierarchy

Player verbs, organized by mode. `[built]` exists today, `[planned]` is new.

```
PLAYER
├── HUB MODE (between ops)
│   ├── Select op            [planned]  (op board → briefing dialogue)
│   ├── Set morph loadout    [planned]  (resleeving bay, reuses morph select)
│   ├── Acquire              [planned]
│   │   ├── Buy gear / medichines
│   │   └── Buy intel / unlock op
│   ├── Recover ego          [planned]  (psychosurgery: clear trauma, restore Moxie)
│   ├── Converse             [built*]   (handler/contacts; branching dialogue + rep)
│   └── Deploy               [planned]  (commit loadout → egocast to site)
│
└── FIELD MODE (in an op)
    ├── Locomotion
    │   ├── Move (WASD/arrows)              [built]
    │   ├── Sprint / dash                   [planned]
    │   └── Ability traversal               [planned] (e.g. wall-cling crawlways)
    ├── Interact [E]  → context action      [built]
    │   ├── Open / retrieve (hatch, locker)         [built]
    │   ├── Scan / analyze (device, body, log)      [built/extend]
    │   ├── Read (data pad, info-hazard risk)       [built/extend]
    │   ├── Operate (terminal, airlock, console)    [built]
    │   └── Talk (NPC)                               [built]
    ├── Resleeve (at a pod) → pick morph → gain ability   [built]
    │   ├── WALL_CLING  → reach hidden/tight spaces       [built]
    │   ├── VACUUM_SEAL → survive vacuum/depressurized     [built]
    │   ├── CYBERBRAIN  → hack / mesh access               [built]
    │   └── (new morph abilities)                          [planned]
    ├── Moxie burn [F] → morph-dependent power            [built]
    │   ├── Octomorph: scramble (speed + i-frames)        [built]
    │   ├── Synth: EMP (disperse swarm)                    [built]
    │   ├── Biomorph: medichine surge (heal)               [built]
    │   └── (per-morph powers for new sleeves)             [planned]
    ├── Hacking minigame (pattern-trace)                  [built]
    │   ├── Trace route (arrows + confirm / digits)        [built]
    │   ├── Cyberbrain assist (spend Moxie)                [built]
    │   └── Fail → async strikes back (swarm + Moxie)      [built]
    ├── Stealth / evasion                                  [partial]
    │   ├── Flee threats (swarm chase)                     [built]
    │   ├── Use cover / line-of-sight                      [planned]
    │   └── Distract / lure                                [planned]
    ├── Stress management
    │   ├── Suffer derangement at low Moxie (slow+glitch)  [built]
    │   ├── Recover Moxie (autodoc / safe rooms)           [built]
    │   └── Spend Moxie deliberately (burn / assist)       [built]
    ├── Gear use                                            [planned]
    │   ├── Medichine dose / sensor ping / etc.
    │   └── Panic farcaster (emergency extract)
    ├── Social                                              [built]
    │   └── Dialogue choices → rep, intel, branch outcomes
    └── Objective / containment                             [built/extend]
        ├── Retrieve · Scan · Vent · Purge · Extract-ego
        └── Reach extract point / survive  [planned]

* hub conversations reuse the field dialogue system.
```

---

## 8. Current build → roadmap

**Already built (the slice):** movement/interact/Moxie-burn; 3 morphs + resleeving;
Moxie stress + derangement + ego-death; objectives + mission manager; hacking
minigame; NPC + branching dialogue + Firewall rep + override shortcut; nanoswarm
threat; rooms with walls/doors + follow camera; sprites; win/lose end screen.

**Build order to reach ~a few hours (proposed phases):**

1. **Hub scene** + scene-flow manager (hub ⇄ op ⇄ debrief), and a `GameState`
   autoload (persistent Moxie/trauma, rep, morph roster, gear, intel, op
   progress). *Foundational — everything else hangs off this.*
2. **Op framework**: generalize the current mission into a reusable `Op`
   (objective list, briefing/debrief, extract zone) so sites are data-driven.
3. **Op 1 (hauler)** — vacuum sections, salvage, extract. Validates the template.
4. **Gear + loadout** system (slots, shop, use in field).
5. **Op 2 (lab)** — info-hazard + first ethics/rep branch; psychosurgery at hub.
6. **New morph(s)** + their burn powers; morph-gated content across ops.
7. **Act 2 site** — multi-deck, hunter enemy, environmental hazards.
8. **Endings** driven by rep + key choices; trauma persistence payoff.
9. Polish pass: set dressing (per the rooms discussion), audio, title/menu.

Each phase stays shippable/verifiable in isolation, matching how we've worked.

---

## 9. Design decisions (resolved 2026-05-29)

These constrain the Phase 1 architecture (`GameState`, scene-flow, ego-death):

- **Save model — hub + op-start checkpoint.** Persist GameState at the hub and
  autosave once when deploying into an op. A crash never loses hub progress, but
  death still restarts the op (no mid-op saves → rogue-lite tension preserved).
- **Ego-death stakes — lose continuity (fork).** Moxie 0 / body destroyed =
  restore from an *older* backup: keep mechanical progress (roster, gear, intel)
  but lose narrative continuity + a resource, and accrue **persistent trauma**.
  The most thematic option; trauma is the recurring cost that psychosurgery
  clears. GameState tracks a `backup` snapshot + a `continuity_breaks` counter.
- **Threat pacing — tied to a difficulty setting.** A `difficulty` field in
  GameState scales per-op pressure: lower = pure exploration / static threats,
  mid = escalating threat (swarms multiply, hunter wakes as you linger), high =
  adds a hard timer (egocast window / reactor breach). Ops read difficulty to
  configure their threat budget rather than hard-coding pacing.
- **Op authoring — hand-built sites.** Each op is a bespoke authored scene built
  on the shared `Op` framework (objective list, briefing/debrief, extract zone).
  No procedural assembly for now; quality over scale for the ~2–4 hr target.
