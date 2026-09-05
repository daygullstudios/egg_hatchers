import 'package:flutter/material.dart';

import '../models/background_theme.dart';
import '../services/game_service.dart';
import '../utils/quest_logic.dart';
import 'phone_width_layout.dart';
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
  static const contentKey = ValueKey<String>('game-primary-navigation-content');

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
        child: Center(
          child: ConstrainedBox(
            key: contentKey,
            constraints: const BoxConstraints(maxWidth: kPhoneMaxContentWidth),
            child: SizedBox(
              width: double.infinity,
              height: preferredSize.height,
              child: ListenableBuilder(
                listenable: shell.game,
                builder: (context, _) {
                  final readyCount =
                      QuestLogic.readyToClaimCount(shell.game.state) +
                      shell.game.dailyQuests
                          .where((quest) => quest.isComplete && !quest.claimed)
                          .length;
                  return _MobileNavigation(
                    shell: shell,
                    theme: theme,
                    hostDestination: hostDestination,
                    readyCount: readyCount,
                  );
                },
              ),
            ),
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
        _MoreNavItem(
          selected: moreSelected,
          readyCount: readyCount,
          shell: shell,
          theme: theme,
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
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.theme,
    required this.onTap,
    this.tutorialKey,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final BackgroundTheme theme;
  final VoidCallback onTap;
  final Key? tutorialKey;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: _NavButton(
        icon: icon,
        label: label,
        selected: selected,
        theme: theme,
        onTap: onTap,
        badgeCount: 0,
        tutorialKey: tutorialKey,
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
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
    return SizedBox(
      height: 58,
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

class _MoreNavItem extends StatelessWidget {
  const _MoreNavItem({
    required this.selected,
    required this.readyCount,
    required this.shell,
    required this.theme,
  });

  static const menuKey = ValueKey<String>('more-navigation-menu');

  final bool selected;
  final int readyCount;
  final MainGameShellScope shell;
  final BackgroundTheme theme;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: MenuAnchor(
        key: menuKey,
        consumeOutsideTap: true,
        reservedPadding: const EdgeInsets.all(8),
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(
            Color.lerp(theme.appBarColor, Colors.white, 0.12),
          ),
          elevation: const WidgetStatePropertyAll(10),
          padding: const WidgetStatePropertyAll(EdgeInsets.all(6)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: Colors.white.withValues(alpha: 0.24)),
            ),
          ),
        ),
        menuChildren: [
          _MoreMenuItem(
            icon: Icons.flag_rounded,
            label: 'Quests',
            selected: shell.current == MainGameDestination.quests,
            badgeCount: readyCount,
            theme: theme,
            onPressed: () => shell.onSelect(MainGameDestination.quests),
          ),
          _MoreMenuItem(
            icon: Icons.auto_fix_high_rounded,
            label: 'Custom Animals',
            selected: shell.current == MainGameDestination.customAnimals,
            theme: theme,
            onPressed: () => shell.onSelect(MainGameDestination.customAnimals),
          ),
          _MoreMenuItem(
            icon: Icons.settings_rounded,
            label: 'Settings',
            selected: false,
            theme: theme,
            onPressed: shell.onOpenSettings,
          ),
        ],
        builder: (context, controller, child) => _NavButton(
          icon: controller.isOpen
              ? Icons.keyboard_arrow_up_rounded
              : Icons.more_horiz_rounded,
          label: 'More',
          selected: selected || controller.isOpen,
          badgeCount: readyCount,
          theme: theme,
          onTap: () =>
              controller.isOpen ? controller.close() : controller.open(),
        ),
      ),
    );
  }
}

class _MoreMenuItem extends StatelessWidget {
  const _MoreMenuItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.theme,
    required this.onPressed,
    this.badgeCount = 0,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final BackgroundTheme theme;
  final VoidCallback onPressed;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    final foreground = Colors.white.withValues(alpha: selected ? 1 : 0.88);
    return MenuItemButton(
      onPressed: onPressed,
      leadingIcon: Badge(
        isLabelVisible: badgeCount > 0,
        label: Text(badgeCount > 99 ? '99+' : '$badgeCount'),
        child: Icon(icon, size: 20, color: foreground),
      ),
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(190, 48)),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        ),
        foregroundColor: WidgetStatePropertyAll(foreground),
        backgroundColor: WidgetStatePropertyAll(
          selected
              ? theme.secondaryColor.withValues(alpha: 0.9)
              : Colors.transparent,
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
        ),
      ),
    );
  }
}
