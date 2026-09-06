# Nestarium artwork source

`nestarium_source.png` is the reviewed square source generated using the built-in
image-generation tool on 2026-09-06. `tool/generate_brand_assets.dart` produces
all platform versions with the existing pixel dimensions; PWA maskable versions
include a central safe area. The generation retained the game's existing
magical eggs, nest, jewel colors and dark background while replacing the old
two-line wordmark with the exact single word NESTARIUM.

Final prompt:

> Use case: text-localization. Edit target: the supplied square game logo.
> This project is being renamed to Nestarium. Replace the entire old lettering
> with the exact single word NESTARIUM (N E S T A R I U M), large, highly legible
> polished dimensional lettering across the lower part. Preserve the illustrated
> magical eggs, nest, dark blue background, lighting, jewel colors and existing
> high quality playful fantasy style. Adapt the gold-edged name plaque to fit
> the single word without cramping or cropping. No old text, no additional
> words, no trademark symbols, no watermark. Square 1024 by 1024 or higher
> suitable as the source for game loading artwork and launcher icons. All
> essential artwork and lettering should have reasonable edge padding.

The prompt above omits only the repeated former wordmark spelling from the
generation request. The generated source is 1254×1254. This rebrand does not
change gameplay animal/egg illustrations or their identifiers.
