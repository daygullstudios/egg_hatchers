import 'package:flutter/material.dart';

import '../models/player_account.dart';
import '../services/account_service.dart';

class AccountOnboardingScreen extends StatefulWidget {
  const AccountOnboardingScreen({super.key, required this.accounts});

  final AccountService accounts;

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
    setState(() => _submitting = true);
    try {
      await widget.accounts.createAccount(
        displayName: _displayNameController.text,
        username: _usernameController.text,
        avatarColor: _avatarColor,
      );
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
                      semanticLabel: 'Egg Hatchers',
                    ),
                    const SizedBox(height: 14),
                    Text(
                      _showCreateForm
                          ? 'Create your account'
                          : 'Choose account',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _showCreateForm
                          ? 'Choose the identity other players will see.'
                          : 'Each tab can use a different player.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (!_showCreateForm) ...[
                      for (final account in widget.accounts.accounts)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _AccountChoice(
                            account: account,
                            onPressed: () =>
                                widget.accounts.selectAccount(account.id),
                          ),
                        ),
                      const SizedBox(height: 6),
                      OutlinedButton.icon(
                        key: const ValueKey('create-another-account-button'),
                        onPressed: () => setState(() => _showCreateForm = true),
                        icon: const Icon(Icons.person_add_alt_1),
                        label: const Text('Create another account'),
                      ),
                    ] else ...[
                      TextFormField(
                        key: const ValueKey('account-display-name'),
                        controller: _displayNameController,
                        textInputAction: TextInputAction.next,
                        maxLength: 20,
                        autofillHints: const [AutofillHints.nickname],
                        decoration: const InputDecoration(
                          labelText: 'Player name',
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
                        controller: _usernameController,
                        textInputAction: TextInputAction.done,
                        maxLength: 16,
                        autocorrect: false,
                        enableSuggestions: false,
                        decoration: const InputDecoration(
                          labelText: 'Username',
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
                            return 'That username already exists.';
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          for (final color in AccountService.avatarColors)
                            _ColorChoice(
                              color: color,
                              selected: color == _avatarColor,
                              onPressed: () =>
                                  setState(() => _avatarColor = color),
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
                        label: const Text('Enter Egg Hatchers'),
                      ),
                      if (widget.accounts.accounts.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () =>
                              setState(() => _showCreateForm = false),
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Back to accounts'),
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
  const _AccountChoice({required this.account, required this.onPressed});

  final PlayerAccount account;
  final VoidCallback onPressed;

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
                    Text('@${account.username}'),
                  ],
                ),
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
    required this.selected,
    required this.onPressed,
  });

  final Color color;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Choose avatar color',
      child: Semantics(
        button: true,
        selected: selected,
        label: 'Avatar color',
        child: InkResponse(
          onTap: onPressed,
          radius: 26,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 42,
            height: 42,
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
