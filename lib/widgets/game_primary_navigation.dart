import 'package:flutter/material.dart';

import '../models/background_theme.dart';
import '../services/game_service.dart';
import '../theme/game_theme.dart';
import '../utils/quest_logic.dart';
import 'tutorial_targets.dart';

enum MainGameDestination {
  hatchery,
  shop,
  battles,
  collection,
  quests,
  customAnimals,
}

class MainGameShellScope extends InheritedWidget {
  const MainGameShellScope({
    super.key,
    required this.current,
    required this.game,
    required this.onSelect,
    required this.onOpenSettings,
    required super.child,
  });

  final MainGameDestination current;
  final GameService game;
  final ValueChanged<MainGameDestination> onSelect;
  final VoidCallback onOpenSettings;

  static MainGameShellScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<MainGameShellScope>();
  }

  @override
  bool updateShouldNotify(MainGameShellScope oldWidget) {
    return current != oldWidget.current || game != oldWidget.game;
  }
}

class GamePrimaryNavigation extends StatelessWidget
    implements PreferredSizeWidget {
  const GamePrimaryNavigation({
    super.key,
    required this.theme,
    required this.hostDestination,
  });

  final BackgroundTheme theme;
  final MainGameDestination hostDestination;

  @override
  Size get preferredSize => const Size.fromHeight(58);

  @override
  Widget build(BuildContext context) {
    final shell = MainGameShellScope.maybeOf(context);
    if (shell == null) return const SizedBox.shrink();

    return Material(
      color: theme.appBarColor,
      child: SafeArea(
        top: false,
        bottom: false,
        child: SizedBox(
          height: preferredSize.height,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return ListenableBuilder(
                listenable: shell.game,
                builder: (context, _) {
                  final readyCount =
                      QuestLogic.readyToClaimCount(shell.game.state) +
                      shell.game.dailyQuests
                          .where((quest) => quest.isComplete && !quest.claimed)
                          .length;
                  if (constraints.maxWidth >= 720) {
                    return _DesktopNavigation(
                      shell: shell,
                      theme: theme,
                      hostDestination: hostDestination,
                      readyCount: readyCount,
                    );
                  }
                  return _MobileNavigation(
                    shell: shell,
                    theme: theme,
                    hostDestination: hostDestination,
                    readyCount: readyCount,
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _MobileNavigation extends StatelessWidget {
  const _MobileNavigation({
    required this.shell,
    required this.theme,
    required this.hostDestination,
    required this.readyCount,
  });

  final MainGameShellScope shell;
  final BackgroundTheme theme;
  final MainGameDestination hostDestination;
  final int readyCount;

  @override
  Widget build(BuildContext context) {
    final moreSelected =
        shell.current == MainGameDestination.quests ||
        shell.current == MainGameDestination.customAnimals;
    return Row(
      children: [
        _NavItem(
          icon: Icons.home_rounded,
          label: 'Hatchery',
          selected: shell.current == MainGameDestination.hatchery,
          theme: theme,
          tutorialKey: _tutorialKey(MainGameDestination.hatchery),
          onTap: () => shell.onSelect(MainGameDestination.hatchery),
        ),
        _NavItem(
          icon: Icons.shopping_cart_rounded,
          label: 'Shop',
          selected: shell.current == MainGameDestination.shop,
          theme: theme,
          tutorialKey: _tutorialKey(MainGameDestination.shop),
          onTap: () => shell.onSelect(MainGameDestination.shop),
        ),
        _NavItem(
          icon: Icons.sports_martial_arts_rounded,
          label: 'Battles',
          selected: shell.current == MainGameDestination.battles,
          theme: theme,
          tutorialKey: _tutorialKey(MainGameDestination.battles),
          onTap: () => shell.onSelect(MainGameDestination.battles),
        ),
        _NavItem(
          icon: Icons.collections_bookmark_rounded,
          label: 'Collection',
          selected: shell.current == MainGameDestination.collection,
          theme: theme,
          tutorialKey: _tutorialKey(MainGameDestination.collection),
          onTap: () => shell.onSelect(MainGameDestination.collection),
        ),
        _NavItem(
          icon: Icons.more_horiz_rounded,
          label: 'More',
          selected: moreSelected,
          badgeCount: readyCount,
          theme: theme,
          onTap: () => _showMore(context),
        ),
      ],
    );
  }

  Key? _tutorialKey(MainGameDestination destination) {
    // Keep the tutorial's GlobalKeys on the original Hatchery navigation.
    // Moving the same GlobalKey between IndexedStack children during a tab
    // switch can briefly mount it twice.
    if (hostDestination != MainGameDestination.hatchery) return null;
    return switch (destination) {
      MainGameDestination.shop => TutorialTargets.shopButton,
      MainGameDestination.battles => TutorialTargets.battlesButton,
      MainGameDestination.collection => TutorialTargets.collectionButton,
      _ => null,
    };
  }

  Future<void> _showMore(BuildContext context) async {
    final selection = await showModalBottomSheet<_MoreDestination>(
      context: context,
      backgroundColor: theme.cardColor,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('More', style: GameTheme.sectionTitle(theme, size: 18)),
              const SizedBox(height: 10),
              _MoreTile(
                icon: Icons.flag_rounded,
                label: 'Quests',
                badgeCount: readyCount,
                theme: theme,
                onTap: () =>
                    Navigator.pop(sheetContext, _MoreDestination.quests),
              ),
              _MoreTile(
                icon: Icons.auto_fix_high_rounded,
                label: 'Custom Animals',
                theme: theme,
                onTap: () =>
                    Navigator.pop(sheetContext, _MoreDestination.customAnimals),
              ),
              _MoreTile(
                icon: Icons.settings_rounded,
                label: 'Settings',
                theme: theme,
                onTap: () =>
                    Navigator.pop(sheetContext, _MoreDestination.settings),
              ),
            ],
          ),
        ),
      ),
    );
    if (!context.mounted || selection == null) return;
    switch (selection) {
      case _MoreDestination.quests:
        shell.onSelect(MainGameDestination.quests);
      case _MoreDestination.customAnimals:
        shell.onSelect(MainGameDestination.customAnimals);
      case _MoreDestination.settings:
        shell.onOpenSettings();
    }
  }
}

class _DesktopNavigation extends StatelessWidget {
  const _DesktopNavigation({
    required this.shell,
    required this.theme,
    required this.hostDestination,
    required this.readyCount,
  });

  final MainGameShellScope shell;
  final BackgroundTheme theme;
  final MainGameDestination hostDestination;
  final int readyCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _destination(
          Icons.home_rounded,
          'Hatchery',
          MainGameDestination.hatchery,
        ),
        _destination(
          Icons.shopping_cart_rounded,
          'Shop',
          MainGameDestination.shop,
        ),
        _destination(
          Icons.sports_martial_arts_rounded,
          'Battles',
          MainGameDestination.battles,
        ),
        _destination(
          Icons.collections_bookmark_rounded,
          'Collection',
          MainGameDestination.collection,
        ),
        _destination(
          Icons.flag_rounded,
          'Quests',
          MainGameDestination.quests,
          badgeCount: readyCount,
        ),
        _destination(
          Icons.auto_fix_high_rounded,
          'Custom',
          MainGameDestination.customAnimals,
        ),
        _NavItem(
          icon: Icons.settings_rounded,
          label: 'Settings',
          selected: false,
          theme: theme,
          onTap: shell.onOpenSettings,
        ),
      ],
    );
  }

  Widget _destination(
    IconData icon,
    String label,
    MainGameDestination destination, {
    int badgeCount = 0,
  }) {
    final tutorialKey = hostDestination != MainGameDestination.hatchery
        ? null
        : switch (destination) {
            MainGameDestination.shop => TutorialTargets.shopButton,
            MainGameDestination.battles => TutorialTargets.battlesButton,
            MainGameDestination.collection => TutorialTargets.collectionButton,
            MainGameDestination.quests => TutorialTargets.questsButton,
            _ => null,
          };
    return _NavItem(
      icon: icon,
      label: label,
      selected: shell.current == destination,
      badgeCount: badgeCount,
      theme: theme,
      tutorialKey: tutorialKey,
      onTap: () => shell.onSelect(destination),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.theme,
    required this.onTap,
    this.badgeCount = 0,
    this.tutorialKey,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final BackgroundTheme theme;
  final VoidCallback onTap;
  final int badgeCount;
  final Key? tutorialKey;

  @override
  Widget build(BuildContext context) {
    final foreground = selected
        ? Colors.white
        : Colors.white.withValues(alpha: 0.72);
    return Expanded(
      child: Semantics(
        selected: selected,
        button: true,
        label: label,
        child: InkWell(
          key: tutorialKey,
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              color: selected
                  ? theme.secondaryColor.withValues(alpha: 0.9)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Badge(
                  isLabelVisible: badgeCount > 0,
                  label: Text(badgeCount > 99 ? '99+' : '$badgeCount'),
                  child: Icon(icon, size: 20, color: foreground),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: TextStyle(
                      color: foreground,
                      fontSize: 10,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _MoreDestination { quests, customAnimals, settings }

class _MoreTile extends StatelessWidget {
  const _MoreTile({
    required this.icon,
    required this.label,
    required this.theme,
    required this.onTap,
    this.badgeCount = 0,
  });

  final IconData icon;
  final String label;
  final BackgroundTheme theme;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: theme.primaryColor),
      title: Text(
        label,
        style: TextStyle(
          color: theme.cardTextPrimaryColor,
          fontWeight: FontWeight.w700,
        ),
      ),
      trailing: badgeCount > 0
          ? Badge(label: Text('$badgeCount'))
          : const Icon(Icons.chevron_right_rounded),
    );
  }
}
