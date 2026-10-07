# Platform Branding Readiness

Updated: 2026-10-07

This record supports the roadmap item "Approve the final Nestarium logo and
regenerate platform branding assets." The approval gate remains open until the
owner approves the final logo, but the repository now has a repeatable path for
turning the approved source into platform artwork.

## Source artwork

- Approved-source candidate: `assets/branding/nestarium_source.png`
- Source record and prompt: `assets/branding/README.md`
- In-app logo target: `assets/images/ui/app_logo.png`
- Generator: `tool/generate_brand_assets.dart`

The generator is deterministic and resizes the square source into the existing
platform image dimensions. It also keeps the PWA maskable icons inside a central
safe area.

## Generated target groups

`tool/generate_brand_assets.dart` writes or refreshes:

- Flutter in-app logo: `assets/images/ui/app_logo.png`
- Web favicon and PWA icons: `web/favicon.png`, `web/icons/*.png`
- Android launch and launcher art:
  `android/app/src/main/res/drawable-nodpi/launch_image.png` and
  `android/app/src/main/res/mipmap-*/ic_launcher.png`
- iOS app icon and launch images:
  `ios/Runner/Assets.xcassets/AppIcon.appiconset/*.png` and
  `ios/Runner/Assets.xcassets/LaunchImage.imageset/*.png`
- macOS app icons: `macos/Runner/Assets.xcassets/AppIcon.appiconset/*.png`
- Windows icon: `windows/runner/resources/app_icon.ico`

## Verification path

After final logo approval:

1. Run `dart run tool/generate_brand_assets.dart`.
2. Run `flutter test --no-pub test/ui_asset_test.dart`.
3. Run `flutter test --no-pub test/platform_branding_readiness_test.dart`.
4. Inspect generated icons on each selected release platform.
5. Record approval in the release candidate record.

## Remaining release-candidate work

- Owner approval for the exact final logo image.
- Re-run the generator after approval.
- Platform-specific visual inspection for the selected launch targets.
- Store screenshots and branding materials for selected stores.

