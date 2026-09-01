import 'package:egg_hatchers/models/custom_egg.dart';
import 'package:egg_hatchers/models/custom_sprite_data.dart';
import 'package:egg_hatchers/services/account_storage.dart';
import 'package:egg_hatchers/services/custom_egg_service.dart';
import 'package:egg_hatchers/services/custom_sprite_service.dart';
import 'package:egg_hatchers/services/sprite_rating_service.dart';
import 'package:egg_hatchers/services/sprite_reference_overlay_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('player-created content and rewards stay with their account', () async {
    final eggs = CustomEggService();
    final sprites = CustomSpriteService();
    final ratings = SpriteRatingService();
    final references = SpriteReferenceOverlayService();

    await Future.wait([
      eggs.initialize(accountId: 'player_a'),
      sprites.initialize(accountId: 'player_a'),
      ratings.initialize(accountId: 'player_a'),
      references.initialize(accountId: 'player_a'),
    ]);
    await eggs.saveEgg(
      const CustomEgg(
        id: 'custom_a',
        name: 'Player A Egg',
        emoji: 'A',
        cost: 100,
        selectedAnimalIds: ['chicken'],
      ),
    );
    await sprites.saveSprite(
      'chicken',
      CustomSpriteData.empty().setPixel(0, 0, 0xFFFFFFFF),
    );
    await ratings.recordClaim(
      animalId: 'chicken',
      spriteHash: 'player-a-sprite',
      score: 10,
      rewardCoins: 100,
    );
    await references.unlock('chicken');

    await Future.wait([
      eggs.initialize(accountId: 'player_b'),
      sprites.initialize(accountId: 'player_b'),
      ratings.initialize(accountId: 'player_b'),
      references.initialize(accountId: 'player_b'),
    ]);
    expect(eggs.allEggs, isEmpty);
    expect(sprites.hasCustomSprite('chicken'), isFalse);
    expect(ratings.isClaimed('chicken', 'player-a-sprite'), isFalse);
    expect(references.isUnlocked('chicken'), isFalse);

    await Future.wait([
      eggs.initialize(accountId: 'player_a'),
      sprites.initialize(accountId: 'player_a'),
      ratings.initialize(accountId: 'player_a'),
      references.initialize(accountId: 'player_a'),
    ]);
    expect(eggs.getById('custom_a'), isNotNull);
    expect(sprites.hasCustomSprite('chicken'), isTrue);
    expect(ratings.isClaimed('chicken', 'player-a-sprite'), isTrue);
    expect(references.isUnlocked('chicken'), isTrue);
  });

  test('deleting an account removes all account-scoped content', () async {
    final eggs = CustomEggService();
    await eggs.initialize(accountId: 'delete_me');
    await eggs.saveEgg(
      const CustomEgg(
        id: 'custom_delete',
        name: 'Delete Egg',
        emoji: 'D',
        cost: 100,
        selectedAnimalIds: ['chicken'],
      ),
    );

    await AccountStorage.deleteAccountData('delete_me');
    final reloaded = CustomEggService();
    await reloaded.initialize(accountId: 'delete_me');

    expect(reloaded.allEggs, isEmpty);
  });
}
