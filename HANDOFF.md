# Habitat Echo — Session Handoff

_Last updated: 2026-05-29. **Read this first.** You are picking up a Godot 4.6
Eclipse Phase fan game turning a working vertical slice into a fleshed-out,
multi-hour, mission-hub game. The full design is in `DESIGN_OUTLINE.md` — read it
after this._

---

## 0. Where things stand

**Phase 1 (the keystone hub + persistence layer) is built.** Decided shape: a
Firewall safehouse **hub** between **self-contained ops** at **multiple sites**,
**tension/evasion survival-horror**. KE-7 is now **Op 0 (onboarding)**.

The §9 design questions are resolved (see `DESIGN_OUTLINE.md §9`): hub + op-start
**checkpoint** saves; ego-death = **lose-continuity fork** (restart op, +trauma,
+continuity break — not a game-over); threat pacing **scales with difficulty**;
ops are **hand-built sites**.

**Phase 1 deliverables (done):**
1. **`GameState` autoload** (`scripts/game_state.gd`) — persistent moxie/trauma,
   rep, morph roster, gear, intel, op progress/flags, difficulty; save/load;
   `snapshot_checkpoint()` + `fork_from_checkpoint()` (ego-death fork).
2. **`SceneFlow` autoload** (`scripts/scene_flow.gd`) — `go_to_hub` / `deploy_op`
   / `begin_op` / `ego_death_fork`; checkpoint-on-deploy.
3. **`OpCatalog` autoload + `Op` resource** (`op_catalog.gd`, `op.gd`) —
   data-driven op registry; KE-7 registered with objectives/briefing/debrief.
   `MissionManager` generalized to arm objectives from the current Op via
   `start_op()` (fixes the replay bug — objectives now reset on deploy).
4. **`scenes/hub.tscn` + `hub.gd`** — safehouse, six working stations (op board
   → deploy, resleeving bay, quartermaster, psychosurgery, handler, debrief).
5. KE-7 win → debrief → `go_to_hub`; ego-death → `ego_death_fork`.

**Verified live (full loop):** GameState/save, psychosurgery (restore + clear
trauma), objective re-arm on deploy, Op 0 bootstrap, and **both** transitions —
main→hub and hub→op (deploy) — swap scenes, render, and keep frames advancing.
Hub renders with all six stations. (A long detour chasing a phantom "capture
wedge" turned out to be a single bug: the hub's `MoxieBar` was missing its
`MoxieFlavor` sibling label, so `moxie_bar.gd:setup` null-crashed and **broke the
debugger** — which freezes `frames_drawn` and looks exactly like a runtime wedge.
Fixed by adding `MoxieFlavor` to `hub.tscn`. Lesson in §3.)

**Op 1 (derelict hauler) is built and verified live** — it validated the Op
template on a 2nd hand-built site. New reusable pieces: `vacuum_zone.gd` (a hazard
Area2D that drains HP/Moxie unless the morph has VACUUM_SEAL) and a generalized
`morph_select_ui.gd` (resolves `TransitionLayer` via `current_scene`, so resleeving
now works in any op scene — was hard-coded to `/root/Main`). Op 1 flow: read the
data log → resleeve to Synth → cross the vacuum-breached hold → recover Petrov's
stranded stack (`recover_ego`) → reach the egocast point (`extract`) → debrief →
hub. A light async swarm spawns on stack retrieval. Verified: morph-gating (Synth
required), vacuum damage (8/tick non-sealed, 0 sealed), extract gating, full
hub→Op1→hub loop, both ops listed on the board.

**Built engine-free (code-complete, ⚠️ NOT yet verified live — the engine was
in use with another game). Verify these first next engine session:**

- **Gear/loadout system.** `GameState` gained `credits` + a 4-slot `gear`
  loadout (`award_credits` / `buy_gear` / `consume_gear`, persisted in the
  save). Ops award `Op.reward_credits` once on first completion (KE-7: 40,
  hauler: 55). New `GearCatalog` autoload (medichine 20cr = heal+Moxie,
  emp_charge 25cr = clear swarms, panic_farcaster 40cr = bail to hub). The hub
  quartermaster is a working shop; `scenes/field_gear.tscn` (+`field_gear.gd`)
  is instanced in both op scenes — **[G]** (new `use_gear` input) opens the
  quick-use panel.
- **Title screen** (`scenes/title.tscn` + `title.gd`) is now the **project main
  scene**: New Game → `reset_new_game()` → deploy Op 0; Continue →
  `GameState.load_game()` → hub (disabled with no save). Saves finally load.
- **Save/load bug fixed:** JSON stringifies dict keys, and Godot 4 treats
  String vs StringName keys as distinct — `op_flags` lookups would silently
  miss after `load_game()`. `_deserialize` now rebuilds the dict with
  StringName keys.
- **Sprite art pass** (pure-Python, `art/gen_station_objects.py` → 9 new PNGs
  in `art/objects/`): pod, device, op_board, fabber, psycho, comm, debrief,
  stack, relay. Wired via `sprite_path` into the 6 hub stations, the 3 hauler
  objects, `resleeving_pod.tscn`, and `scannable_device.tscn` (those two
  scripts gained the same optional sprite loader `interactable.gd` has). No
  colored-square interactables remain.
- **Docs:** `game_design.md` rewritten to the current architecture;
  `site_halcyon_layout.md` added — the Act 2 multi-deck station design
  (3 decks + spine, hunter, containment-decision climax).

**Verification checklist for next engine session:** title → New Game → KE-7
deploys; complete an op → credits awarded (debrief shows them); quartermaster
buy; [G] panel + each gear effect (heal / EMP / farcaster mid-op); title →
Continue resumes at hub with flags intact (exercises the op_flags fix); new
sprites render everywhere. Note: invented uids in new .tscn files get
rewritten by the editor on first import — expected churn, references resolve
by path.

**Next (roadmap in `DESIGN_OUTLINE.md §8`):** the info-hazard + ethics branch
op (Act 1 Op 2); difficulty actually scaling threat pacing
(`GameState.difficulty` exists but isn't read by ops yet); then the Act 2
Halcyon site per `site_halcyon_layout.md` (needs `hunter.gd`, a generalized
`hazard_zone.gd`, spine elevator/crawlway gating).

---

## 1. Project facts

- **Path:** `C:\GodotProjects\HabitatEcho\habitate-echo` (the git repo is this
  inner folder — note the missing 2nd "t"). Godot 4.6.2, renderer "Mobile",
  default window 1152×648.
- **GitHub remote:** `Curious-Conclusion/habitate-echo`, branch `main`.
- **Eclipse Phase 2nd edition** fan game. License is dual: code = PolyForm
  Noncommercial 1.0.0, assets/prose = **CC BY-NC-SA 4.0** (ShareAlike kept to
  honor EP). Any new assets must be original; never drop ShareAlike.
- **Autoloads** (`project.godot`, in order): `GameState`, `SceneFlow`,
  `OpCatalog`, `GearCatalog`, `MorphManager`, `MissionManager`,
  `_mcp_game_helper` (godot-ai). Inputs: `move_up/down/left/right`
  (WASD+arrows), `interact` (E), `moxie_burn` (F), `use_gear` (G).
  **Main scene is now `scenes/title.tscn`.**
- **Git state:** commits on `main` = `1227c1c` (license) → `6720b19` (core
  gameplay) → `f7f3de5` (sprites). **Uncommitted:** interior walls
  (`interior_walls.gd` + wiring), `DESIGN_OUTLINE.md`, this handoff. Commit only
  when the user asks; they prefer the `addons/godot_ai/` plugin churn kept out.

---

## 2. What already works (the slice = future Op 0)

- Top-down movement (WASD/arrows), interact (E), Moxie burn (F).
- **3 morphs** (`morph_manager.gd`): Octomorph (WALL_CLING, spd150/hp80), Synth
  (VACUUM_SEAL, 120/150), Biomorph (CYBERBRAIN, 170/100). Resleeve at the pod
  (`morph_select_ui.gd` + `resleeve_transition.gd`); resleeving costs 15 Moxie.
- **Mission chain** (`mission_manager.gd`): retrieve_stack (Octomorph → hidden
  maintenance hatch) → scan_stack (Biomorph at terminal → hacking minigame, or
  skip via crew override) → vent_signal (Synth at airlock). All done → win screen.
- **Moxie / stress** (`player.gd`): morph-dependent burn (F, −30): Octo scramble
  (2× speed + 3s invuln), Synth EMP (clears swarms), Biomorph medichine (full
  heal). Med Bay **autodoc** restores +40 (2 doses). **Derangement** below Moxie
  35: movement slows toward 0.5×, red screen glitch (`glitch_overlay.gd`). Moxie 0
  on death = EGO DEATH (lose screen); else respawn at pod.
- **Hacking minigame** (`hacking_minigame.gd`): 4×4 node grid, reveal a route,
  retrace with **arrow cursor + E** (F = cyberbrain assist, −20 Moxie). Route
  length escalates per failed hack (4→7). Fail = async strikes back (spawns a
  nanoswarm, −15 Moxie).
- **Crew NPC** (Crew Quarters, huddled in a crate): branching dialogue
  (reassure/intimidate/ask) shifts `firewall_rep` (a var in `main.gd`); earning
  trust grants an **override code** that lets you skip the hack at the terminal.
- **Nanoswarm** (`nanite_swarm.gd`): chases, 10 dmg + 3 Moxie/tick, respects the
  player `invulnerable` flag, EMP-able. Spawns on: scanning the Suspicious
  Device, failing the hack, or respawn-after-death (if device already scanned).
- **Station**: Lounge / Server Alcove / Med Bay / Airlock Corridor + a Crew
  Quarters extension, now divided by **interior walls with doorways**
  (`interior_walls.gd`, procedural `SEGMENTS` table — easy to edit). **Follow
  camera** (zoom 1.5, limits; `main.gd._process` trails the player). Map ~984 wide.
- **Art**: original pixel sprites in `art/` — Octomorph (cyborg octopus), Synth
  (robot), Biomorph (augmented transhuman), crew NPC (in a crate), nanoswarm, and
  6 interactable objects. Generated by `art/gen_octomorph.py`,
  `gen_characters.py`, `gen_objects.py` (re-run to regenerate).

---

## 3. ⚠️ godot-ai MCP workflow — hard-won gotchas (saves hours)

You drive/verify the game live via the **godot-ai MCP**. These quirks are real;
trust them:

- **You can't set Vector2/Color via `node_set_property`.** Object values get
  stringified in transit (`WRONG_TYPE`). Workarounds: **hand-edit the `.tscn`**
  for positions/sizes/anchors; Color accepts a **hex string** (`"#737f8c"`);
  scalar sub-props (ints/floats/strings) transport fine. Best practice: build
  geometry by editing `.tscn` directly, or build it procedurally in GDScript.
- **Run with `project_run` `autosave=false`** so the game loads the on-disk scene
  (your hand-edits) and never clobbers it with the editor's stale in-memory copy.
- **The editor tab goes stale** after you hand-edit a `.tscn` on disk. The game
  (autosave=false) still loads disk correctly. To reconcile the editor, reload
  the scene; **never Ctrl+S the stale tab** (it overwrites your disk edits).
- **Verify gameplay by reading node properties at runtime** via `game_manage`
  `get_node_info` / `get_scene_tree` (script vars aren't exposed, but UI labels,
  bar `value`, sprite `modulate`, node existence, colors are). Use a node's
  PromptLabel `visible` as an "in range" sensor.
- **Input-sim navigation is imprecise** (`game_manage input_key` holds for a
  non-deterministic ~1–3s). To position precisely, **temporarily lower the
  morph's `move_speed`** in source (e.g. 150→15), drive, then revert. Or set the
  player's start `position` in the `.tscn` next to the thing you're testing.
- **The standard verify pattern used all session:** temporarily edit start morph
  / objective flags / player spawn / enemy damage to set up a scenario, run with
  autosave=false, drive + read nodes, then **revert every temp edit and
  grep-confirm clean**. Be disciplined about reverting.
- **Sprites:** loaders (`player.gd`, `interactable.gd`, `nanite_swarm.gd`) use
  `ResourceLoader.exists() ? load() : Image.load()` so fresh PNGs work even before
  Godot imports them. New PNGs may serve stale until reimport — the Image.load
  fallback covers in-editor runs.
- **Bash tool cwd resets** to the OUTER folder between calls — always
  `cd /c/GodotProjects/HabitatEcho/habitate-echo && ...`.
- **The bridge can wedge** (a `game_manage` timeout can stick `game_capture_ready`
  false across runs). Recovery needs the user to restart the editor / re-enable
  the godot-ai server. Only one Godot+Claude session should hold the connection
  (a parallel gOrb project once stole it).
- **A runtime error freezes `frames_drawn` and mimics a "wedge" (2026-05-29).**
  When the game hits a GDScript runtime error under the godot-ai debugger, the
  debugger **breaks/pauses** → `Engine.get_frames_drawn()` stops incrementing, no
  movement/transitions/render, and `editor_screenshot` returns flat grey — yet
  synchronous `game_eval` still answers (debugger is alive). This looks identical
  to a capture wedge but is just a paused breakpoint. **Always check for a runtime
  error first:** `logs_read(source="game")`, the editor's Errors tab, or an
  `editor_screenshot` (the debugger panel shows the stack). A whole session was
  lost mis-attributing this to "`mode=custom` wedges" and "`change_scene` into a
  big scene wedges" — both false; the real cause was a null-access crash in
  `hub.tscn`'s `MoxieBar`. `mode="custom"` and runtime `change_scene_to_file` both
  work fine. Screenshots are reliable when the game isn't paused on an error.
- **Reusing a scripted node across scenes carries its sibling/child deps.**
  `moxie_bar.gd` hard-references `$"../MoxieFlavor"`; the hub crashed until that
  sibling was added. When you drop a slice node (MoxieBar, etc.) into a new scene,
  replicate the nodes its `@onready`/`get_node` paths expect.
- **Don't thrash eval scene-changes / don't `await` across one.** Two
  `change_scene_to_file` calls back-to-back via `game_eval` left `current_scene`
  null; and `await`-ing a frame *after* a scene change in one eval times out (the
  coroutine's node is freed). Call deferred, return, then query in a separate eval.
- **Editor parse errors after adding an autoload are stale** until the editor
  reloads `project.godot` — "Identifier X not declared" for a new autoload clears
  on editor restart; the running game (reads disk fresh) resolves it fine.
- More detail in the memory note **`feedback-godot-ai-mcp-quirks`**.

---

## 4. File map

```
project.godot                  autoloads + input actions
scenes/
  title.tscn                   boot scene: New Game / Continue / Quit
  main.tscn                    KE-7 op scene (= Op 0)
  op_hauler.tscn               Op 1 — derelict hauler (vacuum hold, extract point)
  hub.tscn                     the Firewall safehouse (6 stations)
  field_gear.tscn              [G] gear quick-use panel (instanced in op scenes)
  player.tscn, resleeving_pod.tscn, dialogue_box.tscn, interactable.tscn,
  scannable_device.tscn, end_screen.tscn (end_screen now unused — kept for a
                               possible future hard-fail; win→hub, death→fork)
scripts/
  game_state.gd (autoload)     persistent cross-op state + credits/gear, save/load,
                               ego-death fork
  scene_flow.gd (autoload)     hub⇄op transitions, checkpoint-on-deploy
  op.gd (class_name Op)         op metadata resource (id/scene/objectives/reward)
  op_catalog.gd (autoload)     registers all ops; KE-7 = Op 0, hauler = Op 1
  gear_catalog.gd (autoload)   buyable consumables (medichine/EMP/farcaster)
  field_gear.gd                the [G] panel: list carried gear, consume, apply
  title.gd                     New Game / Continue wiring
  hub.gd                       safehouse station logic (incl. quartermaster shop)
  main.gd                      orchestrates KE-7; reads GameState/SceneFlow/OpCatalog
  op_hauler.gd                 orchestrates Op 1 (hauler); same patterns as main.gd
  vacuum_zone.gd               breach hazard: drains HP/Moxie unless VACUUM_SEAL
  morph_manager.gd (autoload)  morph data + current_morph_id
  mission_manager.gd (autoload) objectives for current op (armed via start_op(Op))
  player.gd                    movement, Moxie/stress/burn, sprite loading
  interactable.gd              generic E-interactable (+ optional sprite_path)
  scannable_device.gd          hold-E scan (spawns swarm)
  hacking_minigame.gd          pattern-trace minigame
  dialogue_box.gd              show_lines / show_lines_with_choices (+ choice_made)
  glitch_overlay.gd            derangement screen effect
  nanite_swarm.gd              the threat
  interior_walls.gd            procedural walls+doors (SEGMENTS table)
  resleeve_transition.gd, morph_select_ui.gd, hp_bar.gd, moxie_bar.gd, end_screen.gd
art/
  gen_octomorph.py, gen_characters.py, gen_objects.py,
  gen_station_objects.py                                sprite generators
  octomorph/ synth/ biomorph/ npc/ swarm/ objects/      generated PNGs
DESIGN_OUTLINE.md              the full plan (progression + action tree)
game_design.md                 snapshot of current code (keep in sync)
site_halcyon_layout.md         Act 2 multi-deck site design (not built yet)
```

---

## 5. Start-of-session checklist

1. Open the project in Godot from `C:\GodotProjects\HabitatEcho\habitate-echo`;
   restart the editor if continuing from a wedged session.
2. Start the **godot-ai MCP server** in the addon dock; launch Claude from
   `C:\GodotProjects\HabitatEcho` so tools register and the memory key matches.
3. Confirm tools work: `editor_state` should report `HabitateEcho` /
   `res://scenes/main.tscn`.
4. Read `DESIGN_OUTLINE.md` (§9 decisions are resolved). 
5. Phase 1 (hub + persistence) is done and the full hub⇄op loop is verified live
   — see §0. Start Phase 2: **Op 1 (derelict hauler)** to validate the Op template
   on a 2nd site. Roadmap in `DESIGN_OUTLINE.md §8`.

---

## 6. Notes / cautions

- Don't rebuild the slice — reuse it. The field systems (interactables, dialogue,
  morphs, Moxie, hacking, swarm, walls, sprites) are done and verified; Phase 1 is
  mostly the **hub + meta/persistence layer** wrapping them.
- Commit only when asked; keep `addons/godot_ai/` churn out of game commits.
- The `sprite_path` pattern now covers `interactable.gd`, `resleeving_pod.gd`,
  and `scannable_device.gd` — no colored-square interactables remain. New objects:
  add a function to `art/gen_station_objects.py`, run it, set `sprite_path`.
