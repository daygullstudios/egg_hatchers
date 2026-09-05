import '../navigation/app_page_route.dart';

/// Tutorial v2 guided spotlight step definitions.
class TutorialData {
  TutorialData._();

  static const currentVersion = 2;

  static const welcomeTitle = 'Tutorial';

  static const startButtonLabel = 'Start Tutorial';
  static const exitButtonLabel = 'Exit Tutorial';

  static const finishText =
      "You're ready! Keep hatching, upgrading, battling, and discovering secrets.";

  static const finishButtonLabel = 'Start Hatching!';

  static const returnToHatcheryText = 'Tap back to return to the Hatchery!';
  static const returnToHatcheryFallbackLabel = 'Return to Hatchery';

  static const advancedSecretWelcomeTitle = 'Secret Hatchery Guide';
  static const advancedSecretStartButtonLabel = 'Start Advanced Tutorial';

  static const advancedSecretFinishButtonLabel = 'Got It';

  static const advancedSecretFinishText =
      'You have the late-game map now. Push rebirths, climb boss modes, and come back to the Secret Hatchery when you need the path again.';

  static const steps = <GuidedTutorialStep>[
    GuidedTutorialStep(
      id: 'shop',
      text: 'Click the Egg Shop button!',
      targetId: TutorialTargetIds.shopButton,
      requiresTargetTap: true,
      advanceOnRoute: kShopRouteName,
      requiredRoute: kHatcheryRouteName,
    ),
    GuidedTutorialStep(
      id: 'buyEgg',
      text: 'Buy your first egg!',
      targetId: TutorialTargetIds.basicEggBuyButton,
      fallbackText: 'This is where you buy eggs.',
      requiresTargetTap: true,
      advanceOnAction: TutorialAction.eggPurchased,
      requiredRoute: kShopRouteName,
    ),
    GuidedTutorialStep(
      id: 'shopBack',
      text: returnToHatcheryText,
      targetId: TutorialTargetIds.screenBackButton,
      fallbackText: returnToHatcheryText,
      requiresTargetTap: true,
      advanceOnRoute: kHatcheryRouteName,
      requiredRoute: kShopRouteName,
      isBackStep: true,
    ),
    GuidedTutorialStep(
      id: 'hatch',
      text: 'Now hatch your egg!',
      fallbackText: 'Eggs hatch into animals that earn coins.',
      manualNext: true,
      requiredRoute: kHatcheryRouteName,
    ),
    GuidedTutorialStep(
      id: 'animalIncome',
      text: 'Animals earn coins over time!',
      targetId: TutorialTargetIds.animalsSection,
      manualNext: true,
      requiredRoute: kHatcheryRouteName,
    ),
    GuidedTutorialStep(
      id: 'upgrade',
      text: 'Upgrade animals to make more coins!',
      targetId: TutorialTargetIds.upgradeButton,
      fallbackText:
          'Upgrade buttons appear on your animals when you have enough coins.',
      requiresTargetTap: true,
      advanceOnAction: TutorialAction.animalUpgraded,
      requiredRoute: kHatcheryRouteName,
    ),
    GuidedTutorialStep(
      id: 'collection',
      text: "Open your Collection to see what you've found!",
      targetId: TutorialTargetIds.collectionButton,
      requiresTargetTap: true,
      advanceOnRoute: kCollectionRouteName,
      requiredRoute: kHatcheryRouteName,
    ),
    GuidedTutorialStep(
      id: 'fusion',
      text:
          'Fusion lets you combine 2 matching animals with the same mutation to make a stronger mutation!\n\n'
          'Fusion has an 80% success chance. If it fails, both animals are lost.\n\n'
          'Try collecting duplicates, then come back here to fuse them.',
      targetId: TutorialTargetIds.fusionSection,
      fallbackText:
          'Fusion lets you combine 2 matching animals with the same mutation to make a stronger mutation! '
          'Fusion has an 80% success chance, and failed fusions lose both animals. '
          'Try collecting duplicates, then come back here to fuse them.',
      manualNext: true,
      requiredRoute: kCollectionRouteName,
    ),
    GuidedTutorialStep(
      id: 'collectionBack',
      text: returnToHatcheryText,
      targetId: TutorialTargetIds.screenBackButton,
      fallbackText: returnToHatcheryText,
      requiresTargetTap: true,
      advanceOnRoute: kHatcheryRouteName,
      requiredRoute: kCollectionRouteName,
      isBackStep: true,
    ),
    GuidedTutorialStep(
      id: 'quests',
      text: 'Open Quests for extra rewards!',
      targetId: TutorialTargetIds.questsButton,
      requiresTargetTap: true,
      advanceOnRoute: kQuestsRouteName,
      requiredRoute: kHatcheryRouteName,
    ),
    GuidedTutorialStep(
      id: 'questsBack',
      text: returnToHatcheryText,
      targetId: TutorialTargetIds.screenBackButton,
      fallbackText: returnToHatcheryText,
      requiresTargetTap: true,
      advanceOnRoute: kHatcheryRouteName,
      requiredRoute: kQuestsRouteName,
      isBackStep: true,
    ),
    GuidedTutorialStep(
      id: 'battles',
      text: 'Open Battles to fight bosses!',
      targetId: TutorialTargetIds.battlesButton,
      requiresTargetTap: true,
      advanceOnRoute: kBattlesRouteName,
      requiredRoute: kHatcheryRouteName,
    ),
    GuidedTutorialStep(
      id: 'battlesExplain',
      text:
          'Auto Battle fights over time. Battle lets you dodge rotten eggs yourself!',
      targetId: TutorialTargetIds.battlesExplainSection,
      manualNext: true,
      requiredRoute: kBattlesRouteName,
    ),
    GuidedTutorialStep(
      id: 'battlesBack',
      text: returnToHatcheryText,
      targetId: TutorialTargetIds.screenBackButton,
      fallbackText: returnToHatcheryText,
      requiresTargetTap: true,
      advanceOnRoute: kHatcheryRouteName,
      requiredRoute: kBattlesRouteName,
      isBackStep: true,
    ),
    GuidedTutorialStep(
      id: 'rebirth',
      text: 'Later, Rebirth gives a permanent income boost!',
      targetId: TutorialTargetIds.rebirthPanel,
      fallbackText: 'Rebirth unlocks after earning enough lifetime coins.',
      manualNext: true,
      requiredRoute: kHatcheryRouteName,
    ),
    GuidedTutorialStep(
      id: 'finish',
      text: finishText,
      manualNext: true,
      isFinish: true,
      requiredRoute: kHatcheryRouteName,
    ),
  ];

  static const advancedSecretSteps = <GuidedTutorialStep>[
    GuidedTutorialStep(
      id: 'secretStats',
      text:
          'This secret panel tracks your late-game basics: Rebirth Level and Collection progress.',
      targetId: TutorialTargetIds.secretStatsSection,
      manualNext: true,
      requiredRoute: kSecretToolsRouteName,
    ),
    GuidedTutorialStep(
      id: 'secretLateGameGuide',
      text:
          'Higher rebirths unlock the deepest eggs. Ancient starts at Rebirth 1, Royal at 2, Celestial at 3, and Void at 5.',
      targetId: TutorialTargetIds.secretLateGameGuide,
      manualNext: true,
      requiredRoute: kSecretToolsRouteName,
    ),
    GuidedTutorialStep(
      id: 'secretRottenShellGuide',
      text:
          'The Rotten Shell unlocks after every earlier boss has been defeated at least once and Shadow Phoenix has been beaten flawlessly.',
      targetId: TutorialTargetIds.secretRottenShellGuide,
      manualNext: true,
      requiredRoute: kSecretToolsRouteName,
    ),
    GuidedTutorialStep(
      id: 'advancedSecretFinish',
      text: advancedSecretFinishText,
      manualNext: true,
      isFinish: true,
      requiredRoute: kSecretToolsRouteName,
    ),
  ];
}

/// Global tutorial target identifiers.
class TutorialTargetIds {
  TutorialTargetIds._();

  static const shopButton = 'shopButton';
  static const basicEggBuyButton = 'basicEggBuyButton';
  static const screenBackButton = 'screenBackButton';
  static const animalsSection = 'animalsSection';
  static const upgradeButton = 'upgradeButton';
  static const collectionButton = 'collectionButton';
  static const fusionSection = 'fusionSection';
  static const questsButton = 'questsButton';
  static const battlesButton = 'battlesButton';
  static const battlesExplainSection = 'battlesExplainSection';
  static const rebirthPanel = 'rebirthPanel';
  static const secretStatsSection = 'secretStatsSection';
  static const secretLateGameGuide = 'secretLateGameGuide';
  static const secretRottenShellGuide = 'secretRottenShellGuide';
}

enum TutorialFlow { basics, advancedSecret }

enum TutorialAction { eggPurchased, animalUpgraded }

class GuidedTutorialStep {
  const GuidedTutorialStep({
    required this.id,
    required this.text,
    this.targetId,
    this.fallbackText,
    this.manualNext = false,
    this.requiresTargetTap = false,
    this.advanceOnRoute,
    this.advanceOnAction,
    this.requiredRoute,
    this.isFinish = false,
    this.isBackStep = false,
  });

  final String id;
  final String text;
  final String? targetId;
  final String? fallbackText;
  final bool manualNext;
  final bool requiresTargetTap;
  final String? advanceOnRoute;
  final TutorialAction? advanceOnAction;
  final String? requiredRoute;
  final bool isFinish;
  final bool isBackStep;

  bool get allowsManualNext =>
      manualNext || fallbackText != null || targetId == null;
}
