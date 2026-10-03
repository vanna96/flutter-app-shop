import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:grocery_app/controllers/app_state_controller.dart';
import 'package:grocery_app/localization/app_ui_translations.dart';
import 'package:grocery_app/models/currency_model.dart';

import 'package:flutter/services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    const MethodChannel channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      return '.';
    });
  });

  setUp(() async {
    Get.testMode = true;
    Get.reset();
  });

  test('AppStateController has no default fallback exchange rate', () {
    AppStateController.kKhrExchangeRate = 0.0;
    expect(AppStateController.hasKhrExchangeRate, false);
    expect(AppStateController.kKhrExchangeRate, 0.0);
  });

  test('updateCurrenciesFromApi sets KHR rate only when explicitly provided', () {
    final controller = AppStateController();

    // 1. Currencies list without explicit rate (USD only)
    controller.updateCurrenciesFromApi([
      CurrencyModel(code: 'USD', symbol: r'$', isDefault: true, exchangeRate: 1.0),
    ]);
    expect(AppStateController.hasKhrExchangeRate, false);

    // 2. Currencies list with explicit exchange rate in KHR currency
    controller.updateCurrenciesFromApi([
      CurrencyModel(code: 'USD', symbol: r'$', isDefault: true, exchangeRate: 1.0),
      CurrencyModel(code: 'KHR', symbol: '៛', isDefault: false, exchangeRate: 4150.0),
    ]);
    expect(AppStateController.hasKhrExchangeRate, true);
    expect(AppStateController.kKhrExchangeRate, 4150.0);

    // 3. Currencies list with explicit rate passed via exchangeRateData
    controller.updateCurrenciesFromApi(
      [
        CurrencyModel(code: 'USD', symbol: r'$', isDefault: true, exchangeRate: 1.0),
      ],
      exchangeRateData: '4200.0',
    );
    expect(AppStateController.hasKhrExchangeRate, true);
    expect(AppStateController.kKhrExchangeRate, 4200.0);
  });

  test('Supports dynamic default currency (e.g. KHR as default base)', () {
    final controller = AppStateController();

    // Setup where KHR is the default currency from the API
    controller.updateCurrenciesFromApi(
      [
        CurrencyModel(code: 'KHR', symbol: '៛', isDefault: true, decimalPlaces: 0, exchangeRate: 1.0),
        CurrencyModel(code: 'USD', symbol: r'$', isDefault: false, decimalPlaces: 2, exchangeRate: 0.00024),
        CurrencyModel(code: 'THB', symbol: '฿', isDefault: false, decimalPlaces: 2, exchangeRate: 0.0085),
      ],
      defaultCurrencyData: {'code': 'KHR'},
    );

    expect(controller.baseCurrencyCode, 'KHR');
    expect(controller.baseCurrencySymbol, '៛');
    expect(controller.foreignCurrencies.length, 2);
    expect(controller.foreignCurrencies.map((c) => c.code).toList(), ['USD', 'THB']);

    // Formatting in base currency (KHR) uses 0 decimals
    expect(controller.formatPrice(50000), '៛50,000');

    // Formatting foreign currency (USD) uses 2 decimals
    expect(controller.formatPrice(12.5, currencyCode: 'USD'), r'$12.50');
  });

  test('Supports multi-currency configuration (USD, CNY, KHR)', () {
    final controller = AppStateController();

    // Match exact live API payload: USD is default, CNY rate 6.75, KHR rate 4200
    controller.updateCurrenciesFromApi([
      CurrencyModel(code: 'CNY', symbol: '¥', decimalPlaces: 2, exchangeRate: 6.75, isDefault: false),
      CurrencyModel(code: 'USD', symbol: r'$', decimalPlaces: 2, exchangeRate: 1.0, isDefault: true),
      CurrencyModel(code: 'KHR', symbol: '៛', decimalPlaces: 0, exchangeRate: 4200.0, isDefault: false),
    ]);

    expect(controller.baseCurrencyCode, 'USD');
    expect(controller.baseCurrencySymbol, r'$');
    expect(controller.foreignCurrencies.length, 2);
    expect(controller.foreignCurrencies.map((c) => c.code).toSet(), {'CNY', 'KHR'});

    // Foreign currency conversions
    expect(controller.convertFromBase(10.0, 'CNY'), 67.5);
    expect(controller.convertFromBase(10.0, 'KHR'), 42000.0);

    // Has exchange rate check
    expect(controller.hasExchangeRateFor('CNY'), true);
    expect(controller.hasExchangeRateFor('KHR'), true);
    expect(controller.hasExchangeRateFor('EUR'), false);
  });

  test('Flags unconfigured foreign currencies with null/0 rate', () {
    final controller = AppStateController();

    controller.updateCurrenciesFromApi([
      CurrencyModel(code: 'USD', symbol: r'$', isDefault: true, exchangeRate: 1.0),
      CurrencyModel(code: 'KHR', symbol: '៛', isDefault: false, exchangeRate: 0.0), // Unconfigured!
    ]);

    expect(controller.hasExchangeRateFor('KHR'), false);
    expect(controller.getExchangeRate('KHR'), null);
  });

  testWidgets('Dynamic regex translations for arbitrary currency codes in Khmer', (tester) async {
    await tester.pumpWidget(
      Localizations(
        locale: const Locale('km'),
        delegates: const [DefaultWidgetsLocalizations.delegate],
        child: Builder(
          builder: (kmContext) {
            expect(
              AppUiTranslations.text(kmContext, "Today's exchange rate is not configured for THB."),
              'អត្រាប្តូរប្រាក់ថ្ងៃនេះមិនទាន់បានកំណត់សម្រាប់ THB ទេ។',
            );
            expect(
              AppUiTranslations.text(kmContext, "Today's exchange rate is not configured for CNY."),
              'អត្រាប្តូរប្រាក់ថ្ងៃនេះមិនទាន់បានកំណត់សម្រាប់ CNY ទេ។',
            );
            expect(
              AppUiTranslations.text(kmContext, "Today's exchange rate is not configured for KHR."),
              'អត្រាប្តូរប្រាក់ថ្ងៃនេះមិនទាន់បានកំណត់សម្រាប់ KHR ទេ។',
            );
            expect(
              AppUiTranslations.text(kmContext, "Rate for USD not set"),
              'មិនទាន់កំណត់អត្រាសម្រាប់ USD',
            );
            return const SizedBox();
          },
        ),
      ),
    );
  });
}
