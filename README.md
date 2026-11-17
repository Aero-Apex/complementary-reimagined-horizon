# Complementary Reimagined for Horizon — v1.2.1

A native Horizon shader pack (WGSL) that brings the *look* of
[Complementary Reimagined](https://www.complementary.dev/) by EminGT — plus a few
Complementary Unbound touches — to [Horizon](https://github.com/horizon-ecosystem/horizon),
the Rust reimplementation of Minecraft Java Edition. Written from scratch in WGSL;
no GLSL from the original pack is used. Not made or endorsed by EminGT or the
Complementary team.

**v1.2.1** keeps every **quality/feature** setting at its maximum (4096 shadows at
192 blocks, pixelated shadows, all effects on) but restores sane **intensity** and
colour defaults, so the picture is no longer blown out or neon. The white
block-edge lines are gone: outlines are off by default, and the effect is clamped
so it can only darken, never produce bright rims. Those settings can still be
changed in-game.

## Assets

| Asset | API | Pack version | Notes |
|-------|-----|--------------|-------|
| `complementary_reimagined-1.2.1.hshader` | **0.2** | `2.2.1` | Current — max quality, sane image |
| `complementary_reimagined-1.2.0.hshader` | **0.2** | `2.2.0` | Fully maxed (blown-out) build |
| `complementary_reimagined-1.1.1.hshader` | **0.2** | `2.1.1` | Sane-default build without pixelated-shadow focus |
| `complementary_reimagined-1.0.0.hshader` | **0.2** | `2.0.0` | Original v1 release |
| `complementary_reimagined_01-1.0.0.hshader` | **0.1** | `1.0.0` | Legacy build for older native Horizon builds that only serve API 0.1 |

Release tags are not the packs' internal versions.

## Features

- **Silhouette outlines** — optional dark rims on depth discontinuities. Off by
  default because API 0.2 has no entity-ID mask and depth-only edges can trace
  every block. Horizon's own entity glow outlines are separate, engine-side.
- **Coloured light** — `Coloured light` strength scales `colored_light` from blocks,
  particle lights and mods; torch colour blends toward `block_light_color`.
- **Pixelated shadows** — `Shadow softness` snaps the shadow map to 4×4 texel
  blocks. Sharp, Soft and Very soft remain available.
- **Unbound-style water** — refraction via `opaque_color`, animated shore foam,
  wave-strength option, depth tint, reflections and glint.
- Two-layer clouds, light shafts, AO, puddles, glowing ores, LabPBR, rain, filmic
  tonemap and the full in-game options screen.

## Install

Copy the `.hshader` for your Horizon build into `shaderpacks/` beside
`options.txt` and select it under Options → Video Settings → Shaders → Shader Packs.

- **0.2 assets:** need `HORIZON_HDR_FRAME=float` on older Horizon builds. The
  asteroid-test instance runs a 9f42064 native build with HDR on and that env var.
- **0.1 asset:** for native builds that only serve API 0.1; no HDR frame switch.

Packs are selected by id (`complementary_reimagined`), so switching between the
0.2 assets needs no settings change. The 0.1 pack has id
`complementary_reimagined_01` and appears separately.

## Rebuild

```bash
horizon-shader pack . --out complementary_reimagined-1.2.1.hshader
horizon-shader check . complementary_reimagined-1.2.1.hshader
```

## License

Original WGSL work inspired by the look of Complementary Reimagined
(Complementary License Agreement 1.7); no GLSL from the original pack is used.
