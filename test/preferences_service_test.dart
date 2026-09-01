import 'package:egg_hatchers/services/preferences_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('reduced battle effects default off and persist', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = PreferencesService();
    await preferences.initialize();

    expect(preferences.reducedBattleEffects, isFalse);
    await preferences.setReducedBattleEffects(true);

    final reloaded = PreferencesService();
    await reloaded.initialize();
    expect(reloaded.reducedBattleEffects, isTrue);
  });
}
