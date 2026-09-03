import 'package:egg_hatchers/utils/rebirth_logic.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('rebirthRequirementForLevel', () {
    test('level 0 requirement is 1,000,000', () {
      expect(RebirthLogic.rebirthRequirementForLevel(0), 1000000);
    });

    test('level 1 requirement is 4,000,000', () {
      expect(RebirthLogic.rebirthRequirementForLevel(1), 4000000);
    });

    test('level 2 requirement is 9,000,000', () {
      expect(RebirthLogic.rebirthRequirementForLevel(2), 9000000);
    });

    test('level 3 requirement is 16,000,000', () {
      expect(RebirthLogic.rebirthRequirementForLevel(3), 16000000);
    });

    test('level 4 requirement is 25,000,000', () {
      expect(RebirthLogic.rebirthRequirementForLevel(4), 25000000);
    });

    test('level 5 requirement is 36,000,000', () {
      expect(RebirthLogic.rebirthRequirementForLevel(5), 36000000);
    });
  });

  group('canRebirth', () {
    test('false below requirement at level 0', () {
      expect(
        RebirthLogic.canRebirth(lifetimeCoinsEarned: 999999, rebirthLevel: 0),
        isFalse,
      );
    });

    test('true at requirement at level 0', () {
      expect(
        RebirthLogic.canRebirth(lifetimeCoinsEarned: 1000000, rebirthLevel: 0),
        isTrue,
      );
    });

    test('false below requirement at level 1', () {
      expect(
        RebirthLogic.canRebirth(lifetimeCoinsEarned: 3999999, rebirthLevel: 1),
        isFalse,
      );
    });

    test('true at requirement at level 1', () {
      expect(
        RebirthLogic.canRebirth(lifetimeCoinsEarned: 4000000, rebirthLevel: 1),
        isTrue,
      );
    });
  });

  test('nextRebirthRequirement matches rebirthRequirementForLevel', () {
    expect(RebirthLogic.nextRebirthRequirement(2), 9000000);
  });

  test('income multiplier doubles with every rebirth', () {
    expect(RebirthLogic.incomeMultiplier(0), 1);
    expect(RebirthLogic.incomeMultiplier(1), 2);
    expect(RebirthLogic.incomeMultiplier(2), 4);
    expect(RebirthLogic.incomeMultiplier(3), 8);
    expect(RebirthLogic.incomeMultiplier(10), 1024);
    expect(RebirthLogic.nextIncomeMultiplier(3), 16);
  });

  test('negative rebirth levels safely use the base multiplier', () {
    expect(RebirthLogic.incomeMultiplier(-3), 1);
  });
}
