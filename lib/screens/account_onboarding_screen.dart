import 'package:flutter/material.dart';

import '../models/player_account.dart';
import '../services/account_service.dart';
import '../services/game_service.dart';
import '../widgets/local_player_removal_dialog.dart';

class AccountOnboardingScreen extends StatefulWidget {
  const AccountOnboardingScreen({
    super.key,
    required this.accounts,
    required this.game,
  });

  final AccountService accounts;
  final GameService game;

  @override
  State<AccountOnboardingScreen> createState() =>
      _AccountOnboardingScreenState();
}

class _AccountOnboardingScreenState extends State<AccountOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _usernameController = TextEditingController();
  var _avatarColor = AccountService.avatarColors.first;
  var _submitting = false;
  String? _error;
  late bool _showCreateForm;

  @override
  void initState() {
    super.initState();
    _showCreateForm = widget.accounts.accounts.isEmpty;
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _createAccount() async {
    if (_submitting || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await widget.accounts.createAccount(
        displayName: _displayNameController.text,
        username: _usernameController.text,
        avatarColor: _avatarColor,
      );
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Could not create this local player. Try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _removeLocalPlayer(PlayerAccount account) async {
    if (_submitting) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) =>
            LocalPlayerRemovalDialog(account: account, fromPlayerPicker: true),
      );
      if (confirmed != true || !mounted) return;
      await widget.game.deleteAccountSave(account.id);
      await widget.accounts.deleteAccount(account.id);
      if (mounted) {
        setState(() => _showCreateForm = widget.accounts.accounts.isEmpty);
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Could not finish removing this local player. Try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Image.asset(
                      'assets/images/ui/app_logo.png',
                      height: 112,
                      fit: BoxFit.contain,
                      semanticLabel: 'Nestarium',
                    ),
                    const SizedBox(height: 14),
                    Text(
                      _showCreateForm
                          ? 'Create local player'
                          : 'Choose local player',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _showCreateForm
                          ? 'Start separate progress on this device. Existing players keep their saves.'
                          : 'Open a player saved here. This is not a sign-in or recovery screen.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_error != null) ...[
                      Semantics(liveRegion: true, child: Text(_error!)),
                      const SizedBox(height: 12),
                    ],
                    if (!_showCreateForm) ...[
                      for (final account in widget.accounts.accounts)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _AccountChoice(
                            account: account,
                            onPressed: _submitting
                                ? null
                                : () =>
                                      widget.accounts.selectAccount(account.id),
                            onDelete: _submitting
                                ? null
                                : () => _removeLocalPlayer(account),
                          ),
                        ),
                      const SizedBox(height: 6),
                      OutlinedButton.icon(
                        key: const ValueKey('create-another-account-button'),
                        onPressed: _submitting
                            ? null
                            : () => setState(() {
                                _showCreateForm = true;
                                _error = null;
                              }),
                        icon: const Icon(Icons.person_add_alt_1),
                        label: const Text('Create another player'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(48, 48),
                        ),
                      ),
                    ] else ...[
                      const Text(
                        'Use a nickname, not your real name. These details do not create a sign-in account or recover progress from another device.',
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        key: const ValueKey('account-display-name'),
                        enabled: !_submitting,
                        controller: _displayNameController,
                        textInputAction: TextInputAction.next,
                        maxLength: 20,
                        autofillHints: const [AutofillHints.nickname],
                        decoration: const InputDecoration(
                          labelText: 'Player name',
                          errorMaxLines: 3,
                          prefixIcon: Icon(Icons.badge_outlined),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            AccountService.isDisplayNameValid(value ?? '')
                            ? null
                            : 'Use 2-20 characters.',
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        key: const ValueKey('account-username'),
                        enabled: !_submitting,
                        controller: _usernameController,
                        textInputAction: TextInputAction.done,
                        maxLength: 16,
                        autocorrect: false,
                        enableSuggestions: false,
                        decoration: const InputDecoration(
                          labelText: 'Username',
                          errorMaxLines: 3,
                          helperMaxLines: 3,
                          prefixText: '@',
                          prefixIcon: Icon(Icons.alternate_email),
                          helperText: '3-16 letters, numbers, or underscores',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          final username = AccountService.normalizeUsername(
                            value ?? '',
                          );
                          if (!AccountService.isUsernameValid(username)) {
                            return 'Enter a valid username.';
                          }
                          if (!widget.accounts.isUsernameAvailable(username)) {
                            return 'That username is already used on this device.';
                          }
                          return null;
                        },
                        onFieldSubmitted: (_) => _createAccount(),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Avatar color',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final (index, color)
                              in AccountService.avatarColors.indexed)
                            _ColorChoice(
                              color: color,
                              name: const [
                                'Blue',
                                'Purple',
                                'Teal',
                                'Pink',
                                'Orange',
                                'Green',
                              ][index],
                              selected: color == _avatarColor,
                              onPressed: _submitting
                                  ? null
                                  : () => setState(() => _avatarColor = color),
                            ),
                        ],
                      ),
                      const SizedBox(height: 26),
                      FilledButton.icon(
                        key: const ValueKey('create-account-button'),
                        onPressed: _submitting ? null : _createAccount,
                        icon: _submitting
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.arrow_forward),
                        label: const Text('Create player'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(48, 48),
                        ),
                      ),
                      if (widget.accounts.accounts.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: _submitting
                              ? null
                              : () => setState(() {
                                  _showCreateForm = false;
                                  _error = null;
                                }),
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Back to players'),
                          style: TextButton.styleFrom(
                            minimumSize: const Size(48, 48),
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AccountChoice extends StatelessWidget {
  const _AccountChoice({
    required this.account,
    required this.onPressed,
    required this.onDelete,
  });

  final PlayerAccount account;
  final VoidCallback? onPressed;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: account.avatarColor,
                child: Text(
                  account.displayName.characters.first.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.displayName,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    Text(account.localProfileLabel),
                  ],
                ),
              ),
              IconButton(
                key: ValueKey('delete-account-${account.id}'),
                onPressed: onDelete,
                tooltip: 'Remove local player ${account.displayName}',
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                icon: const Icon(Icons.person_remove_outlined),
              ),
              const Icon(Icons.login),
            ],
          ),
        ),
      ),
    );
  }
}

class _ColorChoice extends StatelessWidget {
  const _ColorChoice({
    required this.color,
    required this.name,
    required this.selected,
    required this.onPressed,
  });

  final Color color;
  final String name;
  final bool selected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '$name avatar',
      child: Semantics(
        button: true,
        selected: selected,
        label: '$name avatar',
        child: InkResponse(
          key: ValueKey('avatar-color-$name'),
          onTap: onPressed,
          radius: 26,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? Colors.white : Colors.transparent,
                width: 3,
              ),
              boxShadow: selected
                  ? [BoxShadow(color: color.withAlpha(130), blurRadius: 10)]
                  : null,
            ),
            child: selected
                ? const Icon(Icons.check, color: Colors.white, size: 22)
                : null,
          ),
        ),
      ),
    );
  }
}
