# Platform Branding Readiness

Updated: 2026-10-08

This record supports the roadmap item "Approve the final Nestarium logo and
regenerate platform branding assets." The owner approved the final three-style
Nestarium logo source in the 2026-10-08 project thread and requested that it be
implemented as the new logo. Commit `99bd909` regenerates the platform branding
assets from that approved source.

## Source artwork

- Approved source: `assets/branding/nestarium_source.png`
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

## Verification evidence

The final logo implementation ran:

- `dart run tool/generate_brand_assets.dart`
- `node tool/audit_platform_branding.mjs`
- `node tool/audit_brand.mjs`
- `flutter test --no-pub test/ui_asset_test.dart test/platform_branding_audit_tool_test.dart test/platform_branding_readiness_test.dart`
- `flutter analyze --no-pub`
- `flutter test --no-pub`
- `flutter build web --release --no-pub`

## Remaining release-candidate work

- Platform-specific visual inspection for the selected launch targets.
- Store screenshots and branding materials for selected stores.

