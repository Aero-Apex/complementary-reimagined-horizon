# Complementary Reimagined for Horizon — v1 release

A native Horizon shader pack (WGSL, shader API 0.2) that brings the *look* of
[Complementary Reimagined](https://www.complementary.dev/) by EminGT to
[Horizon](https://github.com/horizon-ecosystem/horizon), the Rust
reimplementation of Minecraft Java Edition. Written from scratch in WGSL — no
GLSL from the original pack is used. Not made or endorsed by EminGT or the
Complementary team.

This is the first public release, tagged **v1**. Both shader API variants are
included:

| Asset | API | Source | Notes |
|-------|-----|--------|-------|
| `complementary_reimagined-1.0.0.hshader` | **0.2** | completely re-imagined 2.0 source | Every setting maxed out: shadow resolution 4096, shadow distance 192 blocks, very soft shadows, all effects enabled, every numeric option at its maximum. Internal version `2.0.0`. |
| `complementary_reimagined_01-1.0.0.hshader` | **0.1** | original 1.0.0 build | For older native Horizon builds that only serve API 0.1 (e.g. `66f3981`). Internal version `1.0.0`. |

`v1` is the release tag, not the pack's internal version.

## Install

Download the asset for your Horizon build from the **v1** release, copy it into
the `shaderpacks/` folder beside your `options.txt`, and select it under
Options → Video Settings → Shaders → Shader Packs.

- **0.2 asset:** needs `HORIZON_HDR_FRAME=float` on older Horizon builds; newer
  builds draw it without it. Max settings are demanding — if frames drop, lower
  shadow quality/distance and reflections in the pack's in-game settings screen.
- **0.1 asset:** for native builds that only serve API 0.1; no HDR frame switch
  needed.

## What it does

- **Sky:** a gradient that deepens at the zenith and burns orange at sunrise and
  sunset, with glare around the sun and moon, two layers of its own clouds, and
  a dark violet End sky.
- **Light:** sun and moon light through a softly filtered shadow map, tinted by
  water and stained glass; a sky ambient that follows the time of day; warm
  torch light, coloured near soul fire, redstone, amethyst, sea lanterns and
  other light sources; light through leaves and plants; glowing blocks and
  glowing ores; LabPBR normal and specular maps where a resource pack ships
  them.
- **World:** waving leaves, plants and water; water with depth colour, waves,
  a fresnel mirror and a sun glint; churning lava; rain that darkens and glosses
  open ground and fills puddles.
- **Picture:** ambient occlusion, light shafts, distance haze, bloom, an edge
  smoother, a colour grade and Lottes' filmic tone curve with eye adjustment in
  caves. On an HDR display highlights reach the display's headroom.

All options live in the pack's settings screen, in four pages: Lighting,
Shadows, World and Picture.

## Source layout

| File | Purpose |
|------|---------|
| `horizon-shaders.toml` | Pack metadata, stages, materials, lights, options and pages (all maxed) |
| `common.wgsl` | Shared helpers and the sky gradient |
| `sky.wgsl`, `vertex.wgsl`, `material.wgsl`, `weather.wgsl` | Main render stages |
| `post/*.wgsl` | Ambient occlusion, light shafts, composite, bloom and final grade |
| `tonemap.wgsl` | Lottes filmic tone curve |
| `complementary_reimagined-1.0.0.hshader` | Packaged API 0.2 pack, all settings maxed (v1 release artifact) |
| `complementary_reimagined_01-1.0.0.hshader` | Packaged API 0.1 pack for older native builds (v1 release artifact) |

Rebuild the package with:

```bash
horizon-shader pack . --out complementary_reimagined-1.0.0.hshader
horizon-shader check . complementary_reimagined-1.0.0.hshader
```

## License

Original WGSL work inspired by the look of Complementary Reimagined
(Complementary License Agreement 1.7); no GLSL from the original pack is used.
