import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/game_data.dart';
import '../models/animal.dart';
import '../models/background_theme.dart';
import '../models/mutation.dart';
import '../models/forced_hatch_result.dart';
import '../data/retro_pixel_animal_sprites.dart';
import '../models/retro_pixel_sprite_source.dart';
import '../navigation/app_page_route.dart';
import '../services/custom_sprite_service.dart';
import '../services/developer_tools_preferences.dart';
import '../services/game_service.dart';
import '../services/tutorial_service.dart';
import '../utils/luck_logic.dart';
import '../utils/format_utils.dart';
import '../utils/rebirth_logic.dart';
import '../theme/game_theme.dart';
import '../utils/snackbar_utils.dart';
import '../widgets/game_sprite.dart';
import '../widgets/daygull_discovery_sequence.dart';
import '../widgets/daygull_unlock_cinematic.dart';
import '../widgets/phone_width_layout.dart';

/// Max content width for the phone-sized dev tools column on wide screens.
const double _kDevToolsMaxContentWidth = 430;

/// Hidden developer tools — always green-on-black, never follows player theme.
class DeveloperScreen extends StatefulWidget {
  const DeveloperScreen({
    super.key,
    required this.game,
    required this.customSprites,
    this.returnTheme,
  });

  final GameService game;
  final CustomSpriteService customSprites;
  final BackgroundTheme? returnTheme;

  @override
  State<DeveloperScreen> createState() => _DeveloperScreenState();
}

class _DeveloperScreenState extends State<DeveloperScreen> {
  final _coinController = TextEditingController();
  final _lifetimeController = TextEditingController();
  final _luckController = TextEditingController();
  final _rebirthController = TextEditingController();
  DevForceSlotSelections _slots = DevForceSlotSelections(
    slot1: DevForceSlotSelection(
      animalId: DeveloperToolsPreferences.defaultAnimalId,
      mutationId: DeveloperToolsPreferences.defaultMutationId,
    ),
    slot2: DevForceSlotSelection(
      animalId: DeveloperToolsPreferences.defaultAnimalId,
      mutationId: DeveloperToolsPreferences.defaultMutationId,
    ),
    slot3: DevForceSlotSelection(
      animalId: DeveloperToolsPreferences.defaultAnimalId,
      mutationId: DeveloperToolsPreferences.defaultMutationId,
    ),
  );
  bool _slotsLoaded = false;

  GameService get game => widget.game;

  List<Animal> get _sortedAnimals {
    final list = List<Animal>.from(GameData.animals);
    list.sort((a, b) => GameData.compareOwnedAnimals(a.id, b.id));
    return list;
  }

  @override
  void initState() {
    super.initState();
    _coinController.text = '${game.coins}';
    _lifetimeController.text = '${game.lifetimeCoinsEarned}';
    _luckController.text = '${game.luckLevel}';
    _rebirthController.text = '${game.rebirthLevel}';
    _loadSavedSlots();
  }

  Future<void> _loadSavedSlots() async {
    final saved = await DeveloperToolsPreferences.load();
    if (!mounted) return;
    setState(() {
      _slots = saved;
      _slotsLoaded = true;
    });
  }

  Future<void> _persistSlots() async {
    await DeveloperToolsPreferences.saveSlots(_slots);
  }

  void _updateSlotAnimal(int slotIndex, String animalId) {
    setState(() {
      final current = _slots.slotAt(slotIndex);
      _slots = _slots.updateSlot(
        slotIndex,
        current.copyWith(animalId: animalId),
      );
    });
    _persistSlots();
  }

  void _updateSlotMutation(int slotIndex, String mutationId) {
    setState(() {
      final current = _slots.slotAt(slotIndex);
      _slots = _slots.updateSlot(
        slotIndex,
        current.copyWith(mutationId: mutationId),
      );
    });
    _persistSlots();
  }

  String _formatForcedName(ForcedHatchResult result) {
    final animal = GameData.animalById(result.animalId);
    final mutation = GameData.mutationById(result.mutationId);
    if (animal == null || mutation == null) return 'Unknown';
    return mutation.fullName(animal);
  }

  String _activeForceStatus() {
    if (!game.hasForcedNextHatch) return 'No forced hatch active';

    if (game.isForcedTripleHatch) {
      final names = game.forcedHatchQueue.map(_formatForcedName).join(', ');
      return 'Next triple hatch forced: $names';
    }

    final first = game.forcedHatchQueue.first;
    return 'Next single hatch forced: ${_formatForcedName(first)}';
  }

  void _forceSingleHatch() {
    final slot = _slots.slot1;
    game.setForcedNextHatch(slot.animalId, slot.mutationId);
    final animal = GameData.animalById(slot.animalId)!;
    final mutation = GameData.mutationById(slot.mutationId)!;
    _showMessage('Next single hatch forced: ${mutation.fullName(animal)}');
    setState(() {});
  }

  void _forceTripleHatch() {
    game.setForcedNextTripleHatch([
      _slots.slot1.toForcedResult(),
      _slots.slot2.toForcedResult(),
      _slots.slot3.toForcedResult(),
    ]);
    final names = game.forcedHatchQueue.map(_formatForcedName).join(', ');
    _showMessage('Next triple hatch forced: $names');
    setState(() {});
  }

  void _clearForcedHatch() {
    game.clearForcedNextHatch();
    _showMessage('Forced hatch cleared.');
    setState(() {});
  }

  @override
  void dispose() {
    _coinController.dispose();
    _lifetimeController.dispose();
    _luckController.dispose();
    _rebirthController.dispose();
    super.dispose();
  }

  void _setCoinsFromField() {
    final value = int.tryParse(_coinController.text.trim());
    if (value == null) {
      _showMessage('Enter a valid number.');
      return;
    }
    game.setCoins(value);
    _showMessage('Coins set to $value.');
  }

  void _addCoins(int amount) {
    game.addCoins(amount);
    _coinController.text = '${game.coins}';
    _showMessage('Added $amount coins.');
  }

  void _resetCoins() {
    game.resetCoins();
    _coinController.text = '${game.coins}';
    _showMessage('Coins reset to 250.');
  }

  void _showMessage(String text) {
    showGameSnackBar(
      context,
      message: text,
      backgroundColor: DevToolsTheme.primaryDim,
    );
  }

  Widget _wrapDevToolsReturn(Widget child) {
    final returnTheme = widget.returnTheme;
    if (returnTheme == null) return child;
    return ReturnToHatcheryPopScope(theme: returnTheme, child: child);
  }

  PreferredSizeWidget _devToolsAppBar() {
    final returnTheme = widget.returnTheme;
    return PhoneWidthAppBar.widget(
      titleWidget: Text(
        '> Developer Tools',
        style: DevToolsTheme.sectionTitle(size: 18),
      ),
      backgroundColor: DevToolsTheme.surface,
      foregroundColor: DevToolsTheme.text,
      automaticallyImplyLeading: returnTheme == null,
      leading: returnTheme == null
          ? null
          : ReturnToHatcheryBackButton(
              theme: returnTheme,
              color: DevToolsTheme.text,
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([game, widget.customSprites]),
      builder: (context, _) {
        if (!_slotsLoaded) {
          return _wrapDevToolsReturn(
            Scaffold(
              backgroundColor: Colors.transparent,
              appBar: _devToolsAppBar(),
              body: const Center(
                child: CircularProgressIndicator(color: DevToolsTheme.primary),
              ),
            ),
          );
        }

        return _wrapDevToolsReturn(
          Scaffold(
            backgroundColor: Colors.transparent,
            appBar: _devToolsAppBar(),
            body: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: _kDevToolsMaxContentWidth,
                  ),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    children: [
                      _SectionTitle('Coins'),
                      Text(
                        'Current: ${game.coins} coins',
                        style: DevToolsTheme.bodyText(),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _coinController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        style: DevToolsTheme.bodyText(),
                        cursorColor: DevToolsTheme.primary,
                        decoration: DevToolsTheme.inputDecoration(
                          'Coin amount',
                        ),
                      ),
                      const SizedBox(height: 12),
                      _BigButton(
                        label: 'Set Coins',
                        onPressed: _setCoinsFromField,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _QuickButton(
                            label: '+1,000',
                            onPressed: () => _addCoins(1000),
                          ),
                          _QuickButton(
                            label: '+10,000',
                            onPressed: () => _addCoins(10000),
                          ),
                          _QuickButton(
                            label: '+100,000',
                            onPressed: () => _addCoins(100000),
                          ),
                          _QuickButton(
                            label: '+1,000,000',
                            onPressed: () => _addCoins(1000000),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _BigButton(
                        label: 'Reset to 250 coins',
                        color: DevToolsTheme.warning,
                        onPressed: _resetCoins,
                      ),
                      const SizedBox(height: 32),
                      _SectionTitle('Lifetime Coins (Unlock Testing)'),
                      Text(
                        'Current: ${game.lifetimeCoinsEarned} lifetime coins',
                        style: DevToolsTheme.bodyText(),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _lifetimeController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        style: DevToolsTheme.bodyText(),
                        cursorColor: DevToolsTheme.primary,
                        decoration: DevToolsTheme.inputDecoration(
                          'Lifetime coins earned',
                        ),
                      ),
                      const SizedBox(height: 12),
                      _BigButton(
                        label: 'Set Lifetime Coins Earned',
                        onPressed: () {
                          final value = int.tryParse(
                            _lifetimeController.text.trim(),
                          );
                          if (value == null) {
                            _showMessage('Enter a valid number.');
                            return;
                          }
                          game.setLifetimeCoinsEarned(value);
                          _showMessage('Lifetime coins set to $value.');
                        },
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _QuickButton(
                            label: '+500 lifetime',
                            onPressed: () {
                              game.addLifetimeCoinsEarned(500);
                              _lifetimeController.text =
                                  '${game.lifetimeCoinsEarned}';
                              _showMessage('Added 500 lifetime coins.');
                            },
                          ),
                          _QuickButton(
                            label: '+5,000 lifetime',
                            onPressed: () {
                              game.addLifetimeCoinsEarned(5000);
                              _lifetimeController.text =
                                  '${game.lifetimeCoinsEarned}';
                              _showMessage('Added 5,000 lifetime coins.');
                            },
                          ),
                          _QuickButton(
                            label: '+50,000 lifetime',
                            onPressed: () {
                              game.addLifetimeCoinsEarned(50000);
                              _lifetimeController.text =
                                  '${game.lifetimeCoinsEarned}';
                              _showMessage('Added 50,000 lifetime coins.');
                            },
                          ),
                          _QuickButton(
                            label: '+1M lifetime',
                            onPressed: () {
                              game.addLifetimeCoinsEarned(1000000);
                              _lifetimeController.text =
                                  '${game.lifetimeCoinsEarned}';
                              _showMessage('Added 1,000,000 lifetime coins.');
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _BigButton(
                        label: 'Unlock all eggs (750K lifetime)',
                        onPressed: () {
                          game.setLifetimeCoinsEarned(750000);
                          _lifetimeController.text =
                              '${game.lifetimeCoinsEarned}';
                          _showMessage('All eggs unlocked.');
                        },
                      ),
                      const SizedBox(height: 12),
                      _BigButton(
                        label: 'Reset lifetime coins to 0',
                        color: DevToolsTheme.warning,
                        onPressed: () {
                          game.resetLifetimeCoinsEarned();
                          _lifetimeController.text = '0';
                          _showMessage('Lifetime coins reset to 0.');
                        },
                      ),
                      const SizedBox(height: 32),
                      _SectionTitle('Luck (Mutation Testing)'),
                      Text(
                        'Current: Luck Level ${game.luckLevel}',
                        style: DevToolsTheme.bodyText(),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _luckController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        style: DevToolsTheme.bodyText(),
                        cursorColor: DevToolsTheme.primary,
                        decoration: DevToolsTheme.inputDecoration(
                          'Luck Level (1–10)',
                        ),
                      ),
                      const SizedBox(height: 12),
                      _BigButton(
                        label: 'Set Luck Level',
                        onPressed: () {
                          final value = int.tryParse(
                            _luckController.text.trim(),
                          );
                          if (value == null) {
                            _showMessage('Enter a valid number.');
                            return;
                          }
                          game.setLuckLevel(value);
                          _luckController.text = '${game.luckLevel}';
                          _showMessage('Luck set to Level ${game.luckLevel}.');
                        },
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _QuickButton(
                            label: '+1 Luck',
                            onPressed: () {
                              if (game.luckLevel >= LuckLogic.maxLevel) {
                                _showMessage('Luck is already max level.');
                                return;
                              }
                              game.setLuckLevel(game.luckLevel + 1);
                              _luckController.text = '${game.luckLevel}';
                              _showMessage(
                                'Luck is now Level ${game.luckLevel}.',
                              );
                            },
                          ),
                          _QuickButton(
                            label: 'Reset Luck',
                            onPressed: () {
                              game.resetLuckLevel();
                              _luckController.text = '${game.luckLevel}';
                              _showMessage('Luck reset to Level 1.');
                            },
                          ),
                          _QuickButton(
                            label: 'Max Luck',
                            onPressed: () {
                              game.maxLuckLevel();
                              _luckController.text = '${game.luckLevel}';
                              _showMessage(
                                'Luck set to max Level ${game.luckLevel}.',
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      _SectionTitle('Rebirth Testing'),
                      Text(
                        'Current: Rebirth Level ${game.rebirthLevel} · '
                        '${RebirthLogic.formatMultiplier(game.incomeMultiplier)} income · '
                        'Next rebirth: ${formatCoins(game.rebirthRequirement)} lifetime',
                        style: DevToolsTheme.bodyText(),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _rebirthController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        style: DevToolsTheme.bodyText(),
                        cursorColor: DevToolsTheme.primary,
                        decoration: DevToolsTheme.inputDecoration(
                          'Rebirth Level',
                        ),
                      ),
                      const SizedBox(height: 12),
                      _BigButton(
                        label: 'Set Rebirth Level',
                        onPressed: () {
                          final value = int.tryParse(
                            _rebirthController.text.trim(),
                          );
                          if (value == null) {
                            _showMessage('Enter a valid number.');
                            return;
                          }
                          game.setRebirthLevel(value);
                          _rebirthController.text = '${game.rebirthLevel}';
                          _showMessage(
                            'Rebirth set to Level ${game.rebirthLevel}.',
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _QuickButton(
                            label: '+1 Rebirth',
                            onPressed: () {
                              game.devIncrementRebirthLevel();
                              _rebirthController.text = '${game.rebirthLevel}';
                              _showMessage(
                                'Rebirth is now Level ${game.rebirthLevel}.',
                              );
                            },
                          ),
                          _QuickButton(
                            label: 'Reset Rebirth',
                            onPressed: () {
                              game.resetRebirthLevel();
                              _rebirthController.text = '${game.rebirthLevel}';
                              _showMessage('Rebirth reset to Level 0.');
                            },
                          ),
                          _QuickButton(
                            label: 'Next rebirth lifetime',
                            onPressed: () {
                              final requirement = game.rebirthRequirement;
                              game.setLifetimeCoinsEarned(requirement);
                              _lifetimeController.text =
                                  '${game.lifetimeCoinsEarned}';
                              _showMessage(
                                'Lifetime coins set to ${formatCoins(requirement)}.',
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _BigButton(
                        label: 'Perform Rebirth (if eligible)',
                        onPressed: () {
                          if (!game.canRebirth) {
                            _showMessage(
                              'Need ${formatCoins(game.rebirthRequirement)} lifetime coins to rebirth.',
                            );
                            return;
                          }
                          game.performRebirth();
                          _coinController.text = '${game.coins}';
                          _lifetimeController.text =
                              '${game.lifetimeCoinsEarned}';
                          _luckController.text = '${game.luckLevel}';
                          _rebirthController.text = '${game.rebirthLevel}';
                          _showMessage('Rebirth performed.');
                        },
                      ),
                      const SizedBox(height: 32),
                      _SectionTitle('Boss Battle Testing'),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _QuickButton(
                            label: '+10 battle tokens',
                            onPressed: () {
                              game.devAddBattleTokens(10);
                              _showMessage('Added 10 battle tokens.');
                            },
                          ),
                          _QuickButton(
                            label: 'Reset tokens',
                            onPressed: () {
                              game.devResetBattleTokens();
                              _showMessage('Battle tokens reset to 0.');
                            },
                          ),
                          _QuickButton(
                            label: 'Max Battle Upgrades',
                            onPressed: () {
                              game.devMaxBattleUpgrades();
                              _showMessage('Battle upgrades maxed.');
                            },
                          ),
                          _QuickButton(
                            label: 'Reset Battle Upgrades',
                            onPressed: () {
                              game.devResetBattleUpgrades();
                              _showMessage('Battle upgrades reset.');
                            },
                          ),
                          _QuickButton(
                            label: 'Reset Daily Reward',
                            onPressed: () {
                              game.devResetDailyRewardClaim();
                              _showMessage('Daily reward claim reset.');
                            },
                          ),
                          _QuickButton(
                            label: 'Reset Daily Quests',
                            onPressed: () {
                              game.devResetDailyQuests();
                              _showMessage('Daily quests rerolled.');
                            },
                          ),
                          _QuickButton(
                            label: 'Reroll Daily Quests',
                            onPressed: () {
                              game.devRerollDailyQuests();
                              _showMessage('Daily quests rerolled.');
                            },
                          ),
                          _QuickButton(
                            label: 'Complete Daily Quests',
                            onPressed: () {
                              game.devCompleteDailyQuests();
                              _showMessage('Daily quests completed.');
                            },
                          ),
                          _QuickButton(
                            label: 'Reset boss wins',
                            onPressed: () {
                              game.devResetBossWins();
                              _showMessage('Boss win counts cleared.');
                            },
                          ),
                          _QuickButton(
                            label: 'Unlock Boss Mutation',
                            onPressed: () {
                              game.devUnlockBossMutation();
                              _showMessage('Boss Mutation unlocked.');
                            },
                          ),
                          _QuickButton(
                            label: 'Add Boss mutation animal',
                            onPressed: () {
                              game.devAddBossMutationAnimal();
                              _showMessage('Added Boss mutation chicken.');
                            },
                          ),
                          _QuickButton(
                            label: '+2 Chickens (fusion test)',
                            onPressed: () {
                              game.devAddFusionTestAnimals();
                              _showMessage(
                                'Added 2 Normal Chickens for fusion testing.',
                              );
                            },
                          ),
                          _QuickButton(
                            label: '+2 Golden Chickens (fusion test)',
                            onPressed: () {
                              game.devAddFusionTestAnimals(
                                mutationId: 'golden',
                              );
                              _showMessage(
                                'Added 2 Golden Chickens for fusion testing.',
                              );
                            },
                          ),
                          _QuickButton(
                            label: 'Reset fusion test chickens',
                            onPressed: () {
                              game.devResetFusionTestAnimals();
                              _showMessage(
                                'Removed fusion-test Normal/Golden Chickens.',
                              );
                            },
                          ),
                          _QuickButton(
                            label: 'Reset Battle quest stats',
                            onPressed: () {
                              game.devResetBattleQuestStats();
                              _showMessage('Battle quest stats reset.');
                            },
                          ),
                          _QuickButton(
                            label: '+1 Slime Boss win',
                            onPressed: () {
                              game.devAddBossWin('slime_boss');
                              _showMessage('Added Slime Boss win.');
                            },
                          ),
                          _QuickButton(
                            label: 'Unlock Hard Phases',
                            onPressed: () {
                              game.devUnlockHardPhases();
                              _showMessage(
                                'Set all boss wins to 5 for Hard Phase unlock.',
                              );
                            },
                          ),
                          _QuickButton(
                            label: 'Unlock Nightmare Modes',
                            onPressed: () {
                              game.devUnlockNightmareModes();
                              _showMessage(
                                'Set all Hard Phase wins to 7 for Nightmare unlock.',
                              );
                            },
                          ),
                          _QuickButton(
                            label: 'Start Tutorial Now',
                            onPressed: () {
                              TutorialService.instance.devStartTutorialNow();
                              _showMessage('Tutorial welcome shown.');
                            },
                          ),
                          _QuickButton(
                            label: 'Reset Tutorial',
                            onPressed: () {
                              game.devResetTutorial();
                              _showMessage('Tutorial state reset.');
                            },
                          ),
                          _QuickButton(
                            label: 'Complete Tutorial',
                            onPressed: () {
                              game.devCompleteTutorial();
                              _showMessage('Tutorial marked complete.');
                            },
                          ),
                          _QuickButton(
                            label: 'Grant Secret Reward Badge',
                            onPressed: () {
                              game.devGrantSecretRewardBadge();
                              _showMessage(
                                'Secret Reward Badge claim reset for testing.',
                              );
                            },
                          ),
                          _QuickButton(
                            label: 'Unlock Elite Bosses',
                            onPressed: () {
                              game.devUnlockEliteBosses();
                              _showMessage(
                                'Set Nightmare wins to 3 for elite boss unlock.',
                              );
                            },
                          ),
                          _QuickButton(
                            label: 'Add 10 Egg Shards',
                            onPressed: () {
                              game.devAddEggShards(10);
                              _showMessage('Added 10 Egg Shards.');
                            },
                          ),
                          _QuickButton(
                            label: 'Unlock Rotten Shell reqs',
                            onPressed: () {
                              game.devUnlockRottenShellRequirements();
                              _showMessage('Rotten Shell requirements met.');
                            },
                          ),
                          _QuickButton(
                            label: 'Preview DayGull Unlock',
                            onPressed: () async {
                              await DayGullUnlockCinematic.show(context);
                              if (!context.mounted) return;
                              await DayGullDiscoverySequence.show(
                                context,
                                game: game,
                                theme:
                                    widget.returnTheme ??
                                    BackgroundThemes.hatcheryDefault,
                              );
                            },
                          ),
                          _QuickButton(
                            label: 'Shadow Phoenix flawless',
                            onPressed: () {
                              game.devSetShadowPhoenixFlawlessWin(true);
                              _showMessage('Shadow Phoenix flawless win set.');
                            },
                          ),
                          _QuickButton(
                            label: 'Reset Egg Shard upgrades',
                            onPressed: () {
                              game.devResetEggShardUpgrades();
                              _showMessage('Egg Shard upgrades reset.');
                            },
                          ),
                          _QuickButton(
                            label: 'Mark Elite Reward Animals',
                            onPressed: () {
                              game.devMarkEliteRewardAnimals();
                              _showMessage(
                                'Marked elite boss reward animals as Elite.',
                              );
                            },
                          ),
                          _QuickButton(
                            label: 'Grant Elite Boss Animals',
                            onPressed: () {
                              game.devGrantEliteBossAnimals();
                              _showMessage(
                                'Granted elite boss animals with mutation rolls.',
                              );
                            },
                          ),
                          _QuickButton(
                            label: 'Grant Golden Slime King',
                            onPressed: () {
                              game.devGrantEliteBossAnimal(
                                'slime_king',
                                mutationId: 'golden',
                              );
                              _showMessage('Granted Golden Slime King.');
                            },
                          ),
                          _QuickButton(
                            label: 'Grant Rainbow Egg Guardian',
                            onPressed: () {
                              game.devGrantEliteBossAnimal(
                                'egg_guardian',
                                mutationId: 'rainbow',
                              );
                              _showMessage('Granted Rainbow Egg Guardian.');
                            },
                          ),
                          _QuickButton(
                            label: 'Grant Shadow Shadow Phoenix',
                            onPressed: () {
                              game.devGrantEliteBossAnimal(
                                'shadow_phoenix',
                                mutationId: 'shadow',
                              );
                              _showMessage('Granted Shadow Shadow Phoenix.');
                            },
                          ),
                          _QuickButton(
                            label: 'Advance auto battle',
                            onPressed: () {
                              game.devAdvanceActiveAutoBattleFight();
                              _showMessage(
                                'Advanced active auto battle one fight.',
                              );
                            },
                          ),
                          _QuickButton(
                            label: 'Complete auto battle',
                            onPressed: () {
                              game.devCompleteActiveAutoBattle();
                              _showMessage('Completed active auto battle.');
                            },
                          ),
                          _QuickButton(
                            label: 'Clear auto battle',
                            onPressed: () {
                              game.devClearActiveAutoBattle();
                              _showMessage('Cleared active auto battle.');
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      _SectionTitle('Egg Mastery Testing'),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _QuickButton(
                            label: '+10 hatches each egg',
                            onPressed: () {
                              game.devAddEggMasteryHatches();
                              _showMessage(
                                'Added 10 mastery hatches to each egg.',
                              );
                            },
                          ),
                          _QuickButton(
                            label: 'Max all Egg Mastery',
                            onPressed: () {
                              game.devMaxAllEggMastery();
                              _showMessage('Maxed Egg Mastery for all eggs.');
                            },
                          ),
                          _QuickButton(
                            label: 'Reset Egg Mastery',
                            onPressed: () {
                              game.devResetEggMastery();
                              _showMessage('Reset Egg Mastery progress.');
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      _SectionTitle('Quest Testing'),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _QuickButton(
                            label: '+10 eggs hatched',
                            onPressed: () {
                              game.devAddEggsHatched(10);
                              _showMessage('Added 10 to eggs hatched stat.');
                            },
                          ),
                          _QuickButton(
                            label: '+1 mutation',
                            onPressed: () {
                              game.devAddMutationHatched();
                              _showMessage('Added 1 mutation hatched stat.');
                            },
                          ),
                          _QuickButton(
                            label: '+1 animal upgrade',
                            onPressed: () {
                              game.devAddAnimalUpgrade();
                              _showMessage('Added 1 animal upgrade stat.');
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _BigButton(
                        label: 'Collect All Animals',
                        color: DevToolsTheme.primaryDim,
                        onPressed: () {
                          game.devCollectAllAnimals();
                          _showMessage('Granted every missing base animal.');
                        },
                      ),
                      const SizedBox(height: 12),
                      _BigButton(
                        label: 'Reset quest stats',
                        color: DevToolsTheme.warning,
                        onPressed: () {
                          game.devResetQuestStats();
                          _showMessage('Quest stats reset to 0.');
                        },
                      ),
                      const SizedBox(height: 12),
                      _BigButton(
                        label: 'Clear claimed quests',
                        color: DevToolsTheme.warning,
                        onPressed: () {
                          game.devClearClaimedQuests();
                          _showMessage('Claimed quests cleared.');
                        },
                      ),
                      const SizedBox(height: 32),
                      _SectionTitle('Retro Pixel Sprite Debug'),
                      Text(
                        'All built-in animals should use native64 art.',
                        style: DevToolsTheme.bodyText(muted: true),
                      ),
                      const SizedBox(height: 12),
                      for (final animal in GameData.animals) ...[
                        Builder(
                          builder: (context) {
                            final sprite = RetroPixelAnimalSprites.spriteFor(
                              animal.id,
                            )!;
                            final source = RetroPixelAnimalSprites.sourceFor(
                              animal.id,
                            );
                            final sourceLabel = switch (source) {
                              RetroPixelSpriteSource.native64 => 'native64',
                              RetroPixelSpriteSource.legacyUpscaled => 'legacy',
                              RetroPixelSpriteSource.catalogGenerated =>
                                'catalog',
                            };
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Text(
                                '${animal.id} — ${sprite.width}×${sprite.height} — $sourceLabel',
                                style: DevToolsTheme.bodyText(),
                              ),
                            );
                          },
                        ),
                      ],
                      const SizedBox(height: 32),
                      _SectionTitle('Sprite Quest Testing'),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _QuickButton(
                            label: '+1 sprite rated',
                            onPressed: () {
                              game.devAddSpriteRated();
                              _showMessage('Added 1 sprite rated stat.');
                            },
                          ),
                          _QuickButton(
                            label: '+1 reward claimed',
                            onPressed: () {
                              game.devAddSpriteRewardClaimed();
                              _showMessage(
                                'Added 1 sprite reward claimed stat.',
                              );
                            },
                          ),
                          _QuickButton(
                            label: '+1 overlay unlocked',
                            onPressed: () {
                              game.devAddOverlayUnlocked();
                              _showMessage('Added 1 overlay unlocked stat.');
                            },
                          ),
                          _QuickButton(
                            label: 'Set best score 10',
                            onPressed: () {
                              game.devSetBestSpriteRatingScore(10);
                              _showMessage('Best sprite rating set to 10.');
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _BigButton(
                        label: 'Reset sprite quest stats',
                        color: DevToolsTheme.warning,
                        onPressed: () {
                          game.devResetSpriteQuestStats();
                          _showMessage('Sprite quest stats reset to 0.');
                        },
                      ),
                      const SizedBox(height: 32),
                      _SectionTitle('Force Next Hatch'),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: DevToolsTheme.panelDecoration(
                          active: game.hasForcedNextHatch,
                        ),
                        child: Text(
                          _activeForceStatus(),
                          style: DevToolsTheme.bodyText(
                            muted: !game.hasForcedNextHatch,
                          ).copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 16),
                      for (var i = 0; i < 3; i++) ...[
                        if (i > 0) const SizedBox(height: 20),
                        _ForceSlotEditor(
                          slotNumber: i + 1,
                          selection: _slots.slotAt(i),
                          animals: _sortedAnimals,
                          customSprites: widget.customSprites,
                          onAnimalChanged: (id) => _updateSlotAnimal(i, id),
                          onMutationChanged: (id) => _updateSlotMutation(i, id),
                        ),
                      ],
                      const SizedBox(height: 16),
                      _BigButton(
                        label: 'Force Next Single Hatch',
                        onPressed: _forceSingleHatch,
                      ),
                      const SizedBox(height: 12),
                      _BigButton(
                        label: 'Force Next Triple Hatch',
                        color: DevToolsTheme.primaryDim,
                        onPressed: _forceTripleHatch,
                      ),
                      const SizedBox(height: 12),
                      _BigButton(
                        label: 'Clear Forced Hatch',
                        color: DevToolsTheme.danger,
                        onPressed: _clearForcedHatch,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ForceSlotEditor extends StatelessWidget {
  const _ForceSlotEditor({
    required this.slotNumber,
    required this.selection,
    required this.animals,
    required this.customSprites,
    required this.onAnimalChanged,
    required this.onMutationChanged,
  });

  final int slotNumber;
  final DevForceSlotSelection selection;
  final List<Animal> animals;
  final CustomSpriteService customSprites;
  final ValueChanged<String> onAnimalChanged;
  final ValueChanged<String> onMutationChanged;

  @override
  Widget build(BuildContext context) {
    final animal = GameData.animalById(selection.animalId)!;
    final mutation =
        GameData.mutationById(selection.mutationId) ?? GameData.mutations.first;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: DevToolsTheme.panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Force Slot $slotNumber',
            style: DevToolsTheme.sectionTitle(size: 16),
          ),
          const SizedBox(height: 12),
          _DevAnimalPreview(
            animal: animal,
            mutation: mutation,
            customSprites: customSprites,
          ),
          const SizedBox(height: 12),
          _LabeledDropdown<String>(
            label: 'Animal',
            value: selection.animalId,
            items: [
              for (final item in animals)
                DropdownMenuItem(
                  value: item.id,
                  child: _DevAnimalDropdownRow(
                    animal: item,
                    customSprites: customSprites,
                  ),
                ),
            ],
            onChanged: (value) {
              if (value != null) onAnimalChanged(value);
            },
          ),
          const SizedBox(height: 12),
          _LabeledDropdown<String>(
            label: 'Mutation',
            value: selection.mutationId,
            items: [
              for (final item in GameData.mutations)
                DropdownMenuItem(
                  value: item.id,
                  child: Text(
                    item.isNormal
                        ? 'Normal (none)'
                        : '${item.icon} ${item.displayName}',
                    style: DevToolsTheme.bodyText(),
                  ),
                ),
            ],
            onChanged: (value) {
              if (value != null) onMutationChanged(value);
            },
          ),
        ],
      ),
    );
  }
}

class _DevAnimalPreview extends StatelessWidget {
  const _DevAnimalPreview({
    required this.animal,
    required this.mutation,
    required this.customSprites,
  });

  final Animal animal;
  final Mutation mutation;
  final CustomSpriteService customSprites;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: DevToolsTheme.panelDecoration(),
      child: Column(
        children: [
          Text('Preview', style: DevToolsTheme.bodyText(muted: true)),
          const SizedBox(height: 12),
          GameAnimalPortrait(
            customSprite: customSprites.getDisplaySprite(animal.id),
            animalId: animal.id,
            spritePath: animal.spritePath,
            fallbackEmoji: animal.emoji,
            size: 72,
            mutation: mutation,
            semanticLabel: mutation.fullName(animal),
            emojiFontSize: 48,
          ),
          const SizedBox(height: 10),
          Text(
            mutation.fullName(animal),
            style: DevToolsTheme.bodyText().copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _DevAnimalDropdownRow extends StatelessWidget {
  const _DevAnimalDropdownRow({
    required this.animal,
    required this.customSprites,
  });

  final Animal animal;
  final CustomSpriteService customSprites;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 32,
          height: 32,
          child: GameSprite(
            customSprite: customSprites.getDisplaySprite(animal.id),
            animalId: animal.id,
            spritePath: animal.spritePath,
            fallbackEmoji: animal.emoji,
            size: 28,
            emojiFontSize: 20,
            semanticLabel: animal.name,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            '${animal.name} (${animal.coinsPerSecond}/s)',
            style: DevToolsTheme.bodyText(),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(text, style: DevToolsTheme.sectionTitle(size: 22)),
    );
  }
}

class _BigButton extends StatelessWidget {
  const _BigButton({required this.label, required this.onPressed, this.color});

  final String label;
  final VoidCallback onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: onPressed,
        style: DevToolsTheme.filledButton(color: color),
        icon: Icon(_developerActionIcon(label)),
        label: Text(label, textAlign: TextAlign.center),
      ),
    );
  }
}

class _LabeledDropdown<T> extends StatelessWidget {
  const _LabeledDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: DevToolsTheme.inputDecoration(label),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          isExpanded: true,
          value: value,
          dropdownColor: DevToolsTheme.surface,
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _QuickButton extends StatelessWidget {
  const _QuickButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      style: DevToolsTheme.compactButton(color: DevToolsTheme.primaryDim),
      icon: Icon(_developerActionIcon(label), size: 18),
      label: Text(label),
    );
  }
}

IconData _developerActionIcon(String label) {
  final normalized = label.toLowerCase();
  if (normalized.contains('delete')) return Icons.delete_outline_rounded;
  if (normalized.contains('reset') || normalized.contains('clear')) {
    return Icons.restart_alt_rounded;
  }
  if (normalized.contains('unlock')) return Icons.lock_open_rounded;
  if (normalized.contains('tutorial') || normalized.contains('start')) {
    return Icons.play_arrow_rounded;
  }
  if (normalized.contains('complete') || normalized.contains('win')) {
    return Icons.check_circle_outline_rounded;
  }
  if (normalized.contains('save')) return Icons.save_rounded;
  if (normalized.contains('load')) return Icons.folder_open_rounded;
  if (normalized.contains('remove') || normalized.contains('subtract')) {
    return Icons.remove_circle_outline_rounded;
  }
  if (normalized.contains('add') || normalized.contains('grant')) {
    return Icons.add_circle_outline_rounded;
  }
  return Icons.tune_rounded;
}
