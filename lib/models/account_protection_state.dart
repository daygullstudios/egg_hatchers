enum AccountProtectionStatus {
  starting,
  localOnly,
  guest,
  syncing,
  protected,
  error,
}

class AccountProtectionState {
  const AccountProtectionState({
    required this.status,
    this.protectedPlayerId,
    this.providerIds = const <String>{},
    this.message,
  });

  const AccountProtectionState.localOnly()
    : this(
        status: AccountProtectionStatus.localOnly,
        message: 'Progress is saved only on this device.',
      );

  final AccountProtectionStatus status;
  final String? protectedPlayerId;
  final Set<String> providerIds;
  final String? message;

  bool get isProtected => status == AccountProtectionStatus.protected;

  bool get canProtect =>
      status == AccountProtectionStatus.guest ||
      status == AccountProtectionStatus.error;

  String get label => switch (status) {
    AccountProtectionStatus.starting => 'Checking protection',
    AccountProtectionStatus.localOnly => 'Device only',
    AccountProtectionStatus.guest => 'Not protected',
    AccountProtectionStatus.syncing => 'Syncing',
    AccountProtectionStatus.protected => 'Protected',
    AccountProtectionStatus.error => 'Sync issue',
  };
}
