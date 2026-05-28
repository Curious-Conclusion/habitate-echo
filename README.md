# Habitat Echo

A fan game set in the Eclipse Phase universe.

You are an agent of **Firewall** aboard a small habitat station. Take control of an octomorph, resleeve into new bodies, complete your mission — and don't let the nanite swarm catch you.

Built with Godot 4.6 by a first-time game developer using Claude AI + the godot-ai MCP plugin.

---

## How to Play

**Movement:** WASD or arrow keys  
**Interact:** E (near objects, resleeving pods, terminals)  
**Goal:** Scan the suspicious device before the nanite swarm reaches you

### Morphs
You can resleeve into different bodies at resleeving pods, each with different stats:
- **Octomorph** — fast and flexible
- **Synth** — durable, mechanical
- **Biomorph** — balanced, organic

---

## Play in Browser

A web build is available — open `exports/web/HabitatEcho.html` via a local HTTP server:

```bash
cd exports/web
python -m http.server 8080
```

Then visit `http://localhost:8080/HabitatEcho.html`

---

## Run from Source

1. Download [Godot 4.6+](https://godotengine.org/download/) (Standard, not .NET)
2. Clone this repo
3. Open Godot → Import → select the `project.godot` file inside `habitate-echo/`
4. Press F5 to run

---

## Built With

- [Godot Engine 4.6](https://godotengine.org/) — MIT License
- [godot-ai](https://github.com/hi-godot/godot-ai) — MCP plugin for AI-assisted development
- [Claude AI](https://claude.ai) — Anthropic (used for development assistance)

---

## License & Attribution

This is a non-commercial fan work based on **Eclipse Phase** by Posthuman Studios LLC.  
Eclipse Phase is licensed under [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/).

Habitat Echo is **dual-licensed**:
- **Source code** — [PolyForm Noncommercial License 1.0.0](LICENSE-CODE)
- **Assets & prose** — [CC BY-NC-SA 4.0](LICENSE-ASSETS) (ShareAlike, to match Eclipse Phase)

See [LICENSE](LICENSE) for the full scope and file-pattern breakdown. The bundled
`addons/godot_ai` plugin is third-party and licensed separately.

> *Eclipse Phase and all related content is copyright Posthuman Studios LLC.*  
> *This fan game is not affiliated with or endorsed by Posthuman Studios.*

---

## Project Status

- [x] Player movement (8-direction, 3 morphs)
- [x] Resleeving mechanic
- [x] Firewall mission — device scan objective
- [x] Nanite swarm enemy
- [x] Moxie / stress system
- [x] Win and game over screens
- [x] Web export
- [ ] Pixel art sprites
- [ ] Sound and music
- [ ] Additional rooms
- [ ] More missions
