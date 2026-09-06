import 'package:flutter_test/flutter_test.dart';
import 'package:vrm_polygon_checker/localization.dart';

void main() {
  // load() reads the language files through rootBundle, which needs a binding.
  TestWidgetsFlutterBinding.ensureInitialized();

  // The hook is static, so it outlives each test unless it is cleared.
  tearDown(() => Localization.onLanguageChanged = null);

  group('Localization.onLanguageChanged', () {
    test('fires on every load, including repeats of the same language',
        () async {
      final seen = <AppLanguage>[];
      Localization.onLanguageChanged = seen.add;

      await Localization.load(AppLanguage.ja);
      await Localization.load(AppLanguage.en);
      // The second ja load is served from the cache; the hook still has to run,
      // or the document would keep the previous language.
      await Localization.load(AppLanguage.ja);

      expect(seen, [AppLanguage.ja, AppLanguage.en, AppLanguage.ja]);
    });

    test('reports the language that was actually loaded', () async {
      AppLanguage? seen;
      Localization.onLanguageChanged = (language) => seen = language;

      await Localization.load(AppLanguage.en);

      expect(seen, AppLanguage.en);
      expect(Localization.currentLanguage, AppLanguage.en);
    });

    test('loading works with no hook registered', () async {
      Localization.onLanguageChanged = null;

      await Localization.load(AppLanguage.ja);

      expect(Localization.currentLanguage, AppLanguage.ja);
    });
  });

  group('Localization.get', () {
    test('returns the key itself for an unknown one', () async {
      await Localization.load(AppLanguage.ja);

      expect(Localization.get('definitely-not-a-key'), 'definitely-not-a-key');
    });
  });
}
