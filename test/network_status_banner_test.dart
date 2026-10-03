import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:grocery_app/controllers/network_status_controller.dart';
import 'package:grocery_app/widgets/network_status_banner.dart';

void main() {
  setUp(() {
    Get.testMode = true;
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets('Khmer offline banner fits a phone-width viewport', (
    tester,
  ) async {
    final controller = Get.put(NetworkStatusController());
    controller.markUnavailable();

    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('km'),
        supportedLocales: [Locale('en'), Locale('km')],
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: MediaQuery(
          data: MediaQueryData(size: Size(390, 844)),
          child: Scaffold(body: Stack(children: [NetworkStatusBanner()])),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('គ្មានការតភ្ជាប់អ៊ីនធឺណិត'), findsOneWidget);
    expect(find.text('ក្រៅបណ្តាញ'), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
