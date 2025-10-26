import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:word_game_app/services/settings_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('defaults are applied on load', () async {
    final settings = SettingsService();
    await settings.load();

    expect(settings.hintEffect, 'ring');
    expect(settings.animatedBackgroundEnabled, isTrue);
    expect(settings.idleShimmerEnabled, isTrue);
  });
}
