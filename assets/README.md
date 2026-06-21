# Asset sourcing guide

Drop licensed assets here. **Record every file in `ASSETS.md`** (path, author, license, URL).

## Priority order (best ROI for Frontier-like feel)

| Priority | What | Where to get it | Format |
|---|---|---|---|
| 1 | **Player ship** (detailed PBR) | [Sketchfab](https://sketchfab.com/search?q=spaceship&type=models&features=downloadable&sort_by=-likeCount) filter **Downloadable + CC0/CC-BY** | `.glb` |
| 2 | **Space HDRI** (lighting + reflections) | [Poly Haven HDRIs](https://polyhaven.com/hdri) — try *kiara*, *moonless golf*, *studio* dark variants | `.hdr` / `.exr` |
| 3 | **Debris / asteroids** | [Poly Haven models](https://polyhaven.com/models) rocks, or Quaternius [Ultimate Space Kit](https://quaternius.com/packs/ultimatespacekit.html) | `.glb` |
| 4 | **Engine / tractor VFX** | Godot built-in GPUParticles + emission; optional [Kenney particle pack](https://kenney.nl/assets) | `.png` flipbook |
| 5 | **UI chrome** | Minimal — keep custom HUD; optional Kenney UI space theme | `.png` |

## Fastest ship swap (≈30 min)

1. Download a **CC0 spaceship `.glb`** (2k–15k tris, PBR textures embedded).
2. Place at `assets/ships/player_ship.glb`.
3. In Godot: import → drag into `ShipBody` replacing `Hull` CapsuleMesh.
4. Add **OmniLight3D** at engine positions with cyan emission (see `F007` spec).
5. Run — shared environment in `resources/space_environment.tres` handles bloom/SSAO.

## HDRI optional upgrade

1. Download `.hdr` → `assets/hdri/rogland_clear_night_4k.hdr` (or similar).
2. Point `resources/space_environment.tres` at the HDRI panorama.
3. Procedural sky in `Main.tscn` remains fallback for the BH slice.

## Licenses we accept

- **CC0** — preferred, no attribution required (still credit in ASSETS.md).
- **CC-BY** — OK with attribution in ASSETS.md + game credits.
- **MIT** (shaders only, e.g. Tyler Kennedy black hole) — already in repo.

Do **not** commit Fab/Unreal marketplace assets unless license allows redistribution.

## Blender → Godot PBR checklist

1. Apply scale (Ctrl+A) before export.
2. Export **glTF 2.0 Binary (.glb)** with materials embedded.
3. In Godot import: **Meshes → Light Baking → Disabled** for dynamic ships.
4. Verify normal map + ORM; albedo uses sRGB (`source_color` on import).

See [wiki/architecture/graphics-pipeline.md](../wiki/architecture/graphics-pipeline.md).
