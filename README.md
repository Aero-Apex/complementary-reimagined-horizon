# Complementary Reimagined for Horizon — v1.2 (fully maxed)

A native Horizon shader pack (WGSL) that brings the *look* of
[Complementary Reimagined](https://www.complementary.dev/) by EminGT — plus a few
Complementary Unbound touches — to [Horizon](https://github.com/horizon-ecosystem/horizon),
the Rust reimplementation of Minecraft Java Edition. Written from scratch in WGSL;
no GLSL from the original pack is used. Not made or endorsed by EminGT or the
Complementary team.

**v1.2 is the "fully maxed" build:** every option's default is set to its maximum
value — 4096 shadows at 192 blocks, pixelated shadows, every effect on, and all
intensity/colour sliders at their max. The rendering fixes from v1.1.1 (clean
one-sided outlines, subtle foam and refraction) are kept. Expect a very bright,
very saturated picture and a heavy GPU cost; all sliders can be lowered in-game.

## Assets

| Asset | API | Pack version | Notes |
|-------|-----|--------------|-------|
| `complementary_reimagined-1.2.0.hshader` | **0.2** | `2.2.0` | Current — fully maxed, with v1.1 features and v1.1.1 fixes |
| `complementary_reimagined-1.1.1.hshader` | **0.2** | `2.1.1` | Sane-default version with the rendering fixes |
| `complementary_reimagined-1.1.0.hshader` | **0.2** | `2.1.0` | First v1.1 build |
| `complementary_reimagined-1.0.0.hshader` | **0.2** | `2.0.0` | Original v1 release |
| `complementary_reimagined_01-1.0.0.hshader` | **0.1** | `1.0.0` | Legacy build for older native Horizon builds that only serve API 0.1 |

Release tags (`v1`, `v1.1`, `v1.1.1`, `v1.2`) are not the packs' internal versions.

## Features

- **Silhouette outlines** — dark rims on depth discontinuities, tunable thickness
  and strength. *Limitation:* shader API 0.2 exposes no entity-ID or outline mask,
  so these are depth-based silhouettes, not per-entity coloured outlines. Horizon
  draws its own entity glow outlines separately, after the pack's post chain.
- **Coloured light** — `Coloured light` strength scales `colored_light` from blocks,
  particle lights and mods; torch colour blends toward `block_light_color`.
- **Pixelated shadows** — `Shadow softness` snaps the shadow map to 4×4 texel
  blocks for crisp blocky shadows. Sharp, Soft and Very soft remain available.
- **Unbound-style water** — refraction via `opaque_color`, animated shore foam,
  stronger wave normals and wave-strength option, depth tint, reflections and glint.
- Plus the original v1/v1.1 feature set: two-layer clouds, light shafts, AO,
  puddles, glowing ores, LabPBR, rain, filmic tonemap and the full options screen.

## Install

Copy the `.hshader` for your Horizon build into the `shaderpacks/` folder beside
`options.txt` and select it under Options → Video Settings → Shaders → Shader Packs.

- **0.2 assets:** need `HORIZON_HDR_FRAME=float` on older Horizon builds; newer
  builds draw them without it. The asteroid-test instance is already configured
  with a 9f42064 native build, HDR on and that env var set.
- **0.1 asset:** for native builds that only serve API 0.1; no HDR frame switch.

The pack is selected by id (`complementary_reimagined`), so switching between the
0.2 assets needs no settings change. The 0.1 pack has id
`complementary_reimagined_01` and appears as a separate entry.

## Rebuild

```bash
horizon-shader pack . --out complementary_reimagined-1.2.0.hshader
horizon-shader check . complementary_reimagined-1.2.0.hshader
```

## License

Original WGSL work inspired by the look of Complementary Reimagined
(Complementary License Agreement 1.7); no GLSL from the original pack is used.
