# Complementary Reimagined for Horizon — v1.1

A native Horizon shader pack (WGSL) that brings the *look* of
[Complementary Reimagined](https://www.complementary.dev/) by EminGT — plus a few
Complementary Unbound touches — to [Horizon](https://github.com/horizon-ecosystem/horizon),
the Rust reimplementation of Minecraft Java Edition. Written from scratch in WGSL;
no GLSL from the original pack is used. Not made or endorsed by EminGT or the
Complementary team.

## Assets

| Asset | API | Pack version | Notes |
|-------|-----|--------------|-------|
| `complementary_reimagined-1.1.0.hshader` | **0.2** | `2.1.0` | Current release — all settings maxed, plus the v1.1 features below |
| `complementary_reimagined-1.0.0.hshader` | **0.2** | `2.0.0` | Previous v1 release, kept for comparison |
| `complementary_reimagined_01-1.0.0.hshader` | **0.1** | `1.0.0` | Legacy build for older native Horizon builds that only serve API 0.1 |

`v1.1` is the release tag; pack versions are internal to the `.hshader`.

## What's new in v1.1

- **Silhouette outlines** — dark rims on depth discontinuities so terrain, entities
  and items stand out from what is behind them. Tunable thickness and strength.
  *Limitation:* shader API 0.2 exposes no entity-ID or outline mask, so these are
  depth-based silhouettes rather than per-entity coloured outlines. Horizon draws
  its own entity glow outlines separately, after the pack's post chain.
- **Coloured light** — stronger, tunable tinting from `[[lights]]` blocks, particle
  lights and mod lights through `colored_light` and `block_light_color`.
- **Pixelated shadows** — a new `Shadow softness` choice that snaps the shadow map
  to chunky 4×4 texel blocks for crisp, classic blocky shadows. Sharp, Soft and
  Very soft remain available.
- **Unbound-style water** — refraction of the world behind the surface (via
  `opaque_color`), animated shore/obstacle foam, stronger wave normals and a
  tunable wave strength, on top of the existing depth tint, reflections and glint.

All options live in the pack's settings screen, in four pages: Lighting, Shadows,
World and Picture.

## Install

Copy the `.hshader` for your Horizon build into the `shaderpacks/` folder beside
`options.txt` and select it under Options → Video Settings → Shaders → Shader Packs.

- **0.2 assets:** need `HORIZON_HDR_FRAME=float` on older Horizon builds; newer
  builds draw them without it. Every setting is maxed — if frames drop, lower
  shadow quality/distance, reflections or refraction in-game.
- **0.1 asset:** for native builds that only serve API 0.1; no HDR frame switch.

The pack is selected by id (`complementary_reimagined`), so switching between the
0.2 assets does not require changing your settings. The 0.1 pack has id
`complementary_reimagined_01` and appears as a separate entry.

## Source layout

| File | Purpose |
|------|---------|
| `horizon-shaders.toml` | Metadata, stages, materials, lights, options and pages |
| `common.wgsl` | Shared helpers and the sky gradient |
| `sky.wgsl`, `vertex.wgsl`, `material.wgsl`, `weather.wgsl` | Main render stages |
| `post/*.wgsl` | AO, light shafts, composite, bloom, final grade **and outlines** |
| `tonemap.wgsl` | Lottes filmic tone curve |
| `complementary_reimagined-1.1.0.hshader` | Packaged v1.1 artifact |

Rebuild and validate with:

```bash
horizon-shader pack . --out complementary_reimagined-1.1.0.hshader
horizon-shader check . complementary_reimagined-1.1.0.hshader
```

## License

Original WGSL work inspired by the look of Complementary Reimagined
(Complementary License Agreement 1.7); no GLSL from the original pack is used.
