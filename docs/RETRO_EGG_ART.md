# Retro Pixel egg refresh

Generated on 2026-10-24 with the built-in image generation tool, one image
per egg. References were the corresponding project-owned Realistic egg and
the approved Retro Pixel Royal egg (Royal initially referenced Boba Bazooka).
No external stock images were used.

## Prompt direction

One upright egg, centered and fully visible, transparent background with
clear margins. Handcrafted 16-bit pixel art, square pixel clusters, stepped
contours, dark colored outlines, and discrete shade ramps. No text, scenery,
pedestals, blur, or photorealistic microtexture. Preserve each egg's identity:

- Basic: ivory shell with sparse tan speckles.
- Forest: green leaf veins with bark and moss edges.
- Farm: golden shell, red-orange bands and wheat.
- Magic: purple amethyst with gold rune circles.
- Jungle: emerald shell, curling lime vines and tropical leaves.
- Ocean: turquoise shell and white-cyan wave curls.
- Arctic: ice-blue shell, white snowflake and sapphire shadows.
- Dino: ochre/olive shell, fossil spiral and stone cracks.
- Space: indigo shell, cyan/violet nebula bands and stars.
- Ancient: sandstone and gold with a winged sun disk and engraved bands.
- Royal: purple shell, golden crown band, ruby and sapphire jewels.
- Celestial: sky-blue/ivory, golden sun, stars and cloud curls.
- Void: obsidian/violet, angular glowing cracks and an eclipse.
- DayGull: cobalt/purple, cyan fractures and offset glitch slices; no wings.
- Boss: charcoal armor, branching blood-red emblem and silver highlights.

## Integration

Final PNGs are in `assets/images/egg_themes/retro_pixel/`. Generated art was
mechanically resized to 128 x 128 using nearest-neighbor sampling and lossless
PNG encoding with `tool/resize_transparent_asset.dart ... 128 pixel`.
The existing sprite resolver and DayGull glitch animation remain unchanged.
Asset tests verify the complete set, transparency and a 64 KiB per-image budget.
