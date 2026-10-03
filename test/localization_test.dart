import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grocery_app/controllers/app_state_controller.dart';
import 'package:grocery_app/localization/catalog_localization.dart';
import 'package:grocery_app/localization/localized_material.dart';
import 'package:grocery_app/styles/theme.dart';

void main() {
  Widget localizedApp({required Locale locale, required Widget child}) {
    return MaterialApp(
      locale: locale,
      supportedLocales: const [Locale('en'), Locale('km')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(body: child),
    );
  }

  testWidgets('shared text translates known app copy in Khmer', (tester) async {
    await tester.pumpWidget(
      localizedApp(locale: const Locale('km'), child: const Text('My Cart')),
    );

    expect(find.text('រទេះទំនិញរបស់ខ្ញុំ'), findsOneWidget);
    expect(find.text('My Cart'), findsNothing);
  });

  testWidgets('product action translates Add in Khmer', (tester) async {
    await tester.pumpWidget(
      localizedApp(locale: const Locale('km'), child: const Text('Add')),
    );

    expect(find.text('បន្ថែម'), findsOneWidget);
    expect(find.text('Add'), findsNothing);
  });

  testWidgets('unknown user content is left unchanged', (tester) async {
    await tester.pumpWidget(
      localizedApp(
        locale: const Locale('km'),
        child: const Text('Vanna Poung'),
      ),
    );

    expect(find.text('Vanna Poung'), findsOneWidget);
  });

  testWidgets('catalog names prefer foreign name only in Khmer', (
    tester,
  ) async {
    late String khmerName;
    late String englishName;

    await tester.pumpWidget(
      localizedApp(
        locale: const Locale('km'),
        child: Builder(
          builder: (context) {
            khmerName = localizedCatalogName(
              context,
              'Organic Banana',
              'ចេកសរីរាង្គ',
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    await tester.pumpWidget(
      localizedApp(
        locale: const Locale('en'),
        child: Builder(
          builder: (context) {
            englishName = localizedCatalogName(
              context,
              'Organic Banana',
              'ចេកសរីរាង្គ',
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(khmerName, 'ចេកសរីរាង្គ');
    expect(englishName, 'Organic Banana');
  });

  test('order lines retain backend foreign names', () {
    final line = OrderLine.fromJson({
      'item_id': 7,
      'name': 'Butter Bread',
      'foreign_name': 'នំបុំប៊ឺមៀ៚',
      'quantity': 2,
      'unit_price': 3.5,
    });

    expect(line.foreignName, 'នំបុំប៊ឺមៀ៚');
    expect(line.toJson()['foreign_name'], 'នំបុំប៊ឺមៀ៚');
  });

  test('language themes use their bundled font families', () {
    expect(
      buildThemeData('km').textTheme.bodyMedium?.fontFamily,
      khmerFontFamily,
    );
    expect(
      buildThemeData('en').textTheme.bodyMedium?.fontFamily,
      gilroyFontFamily,
    );
  });
}
