import 'package:grocery_app/controllers/app_state_controller.dart';
import 'package:get/get.dart';
import 'package:grocery_app/controllers/store_controller.dart';
import 'package:grocery_app/controllers/category_controller.dart';
import 'package:grocery_app/data/mock_data.dart';
import 'package:grocery_app/models/category_model.dart';
import 'package:grocery_app/models/currency_model.dart';
import 'package:grocery_app/models/product_model.dart';
import 'package:grocery_app/models/store_model.dart';
import 'package:grocery_app/services/mobile_api_repository.dart';
import 'package:grocery_app/services/version_control_service.dart';

class ProductController extends GetxController {
  var isLoading = true.obs;
  final MobileApiRepository _mobileApiRepository = MobileApiRepository();

  final StoreController storeController = Get.find<StoreController>();

  RxList<ProductModel> newP = <ProductModel>[].obs;
  RxList<ProductModel> bestSell = <ProductModel>[].obs;
  RxList<ProductModel> bestSell2 = <ProductModel>[].obs;
  RxList<ProductModel> shopProducts = <ProductModel>[].obs;

  @override
  void onInit() {
    super.onInit();

    fetchInitData();

    ever(storeController.selectedLocationId, (_) {
      fetchInitData();
    });
  }

  Future<void> fetchInitData() async {
    final selectedId = storeController.selectedLocationId.value;
    final int? branchIdParam = selectedId == 0 ? null : selectedId;

    try {
      isLoading.value = true;
      final bootstrap =
          await _mobileApiRepository.fetchBootstrap(branchId: branchIdParam);

      // Check Force / Optional Version Updates
      if (bootstrap['mobile_version'] != null) {
        final versionInfo = bootstrap['mobile_version'];
        final minVersion = versionInfo['minimum_version']?.toString() ?? '';
        final latestVersion = versionInfo['latest_version']?.toString() ?? '';
        final iosUrl = versionInfo['store_url_ios']?.toString() ?? '';
        final androidUrl = versionInfo['store_url_android']?.toString() ?? '';

        bool requiresForceUpdate =
            await VersionControlService.isForceUpdateRequired(minVersion);
        if (requiresForceUpdate) {
          VersionControlService.showForceUpdateDialog(
            iosUrl,
            androidUrl,
            minVersion: minVersion,
            latestVersion: latestVersion,
          );
          return; // Stop further initialization since the app is locked
        } else if (await VersionControlService.isOptionalUpdateAvailable(
            latestVersion)) {
          VersionControlService.showOptionalUpdateDialog(
            iosUrl,
            androidUrl,
            latestVersion: latestVersion,
          );
        }
      }

      // Fetch / extract currency configuration from backend micro-service
      if (Get.isRegistered<AppStateController>()) {
        final appState = Get.find<AppStateController>();

        final dynamic explicitExchangeRate = bootstrap['khr_exchange_rate'] ??
            bootstrap['exchange_rate'] ??
            bootstrap['rate'] ??
            (bootstrap['settings'] is Map
                ? (bootstrap['settings']['exchange_rate'] ??
                    bootstrap['settings']['khr_exchange_rate'] ??
                    bootstrap['settings']['rate'])
                : null);

        final dynamic defaultCurrencyData = bootstrap['currency'] ??
            (bootstrap['settings'] is Map
                ? bootstrap['settings']['currency']
                : null);

        if (bootstrap['currencies'] is List &&
            (bootstrap['currencies'] as List).isNotEmpty) {
          final currenciesList = (bootstrap['currencies'] as List)
              .whereType<Map>()
              .map((c) =>
                  CurrencyModel.fromJson(Map<String, dynamic>.from(c)))
              .toList(growable: false);
          appState.updateCurrenciesFromApi(
            currenciesList,
            defaultCurrencyData: defaultCurrencyData,
            exchangeRateData: explicitExchangeRate,
          );
        } else if (bootstrap['currency'] != null) {
          appState.updateCurrencyFromApi(
            bootstrap['currency'],
            exchangeRateData: explicitExchangeRate,
          );
        } else if (bootstrap['settings'] != null &&
            bootstrap['settings'] is Map) {
          final settings = bootstrap['settings'] as Map;
          appState.updateCurrencyFromApi(
            settings['currency'] ?? settings,
            exchangeRateData: explicitExchangeRate,
          );
        } else if (explicitExchangeRate != null) {
          appState.updateCurrencyFromApi(
            null,
            exchangeRateData: explicitExchangeRate,
          );
        } else {
          try {
            final remoteCurrencies =
                await _mobileApiRepository.fetchCurrencies();
            if (remoteCurrencies.isNotEmpty) {
              appState.updateCurrenciesFromApi(
                remoteCurrencies,
                defaultCurrencyData: defaultCurrencyData,
                exchangeRateData: explicitExchangeRate,
              );
            }
          } catch (_) {}
        }
      }

      final featuredProducts = _parseProducts(bootstrap['featured_products']);
      final newArrivals = _parseProducts(bootstrap['new_arrivals']);
      final bestSellers = _parseProducts(bootstrap['best_sellers']);
      final recommended = _parseProducts(bootstrap['recommended_products']);

      MockDataRepository.updateHomeSections(
        featuredProducts: featuredProducts,
        newArrivals: newArrivals,
        bestSellers: bestSellers,
        recommendedProducts: recommended,
        replaceProducts: true,
      );
      MockDataRepository.updateStores(_parseStores(bootstrap['branches']));

      final parsedCategories = _parseCategories(bootstrap['categories']);
      MockDataRepository.updateCategories(parsedCategories);
      if (Get.isRegistered<CategoryController>()) {
        Get.find<CategoryController>().categories.value =
            List<CategoryModel>.from(parsedCategories);
      }

      final remoteProducts =
          await _mobileApiRepository.fetchProducts(branchId: branchIdParam);
      if (remoteProducts.isNotEmpty) {
        final branchProducts = selectedId > 0
            ? remoteProducts
                .where((p) => p.branchId == selectedId)
                .toList(growable: false)
            : remoteProducts;
        MockDataRepository.updateProducts(branchProducts);
      } else {
        // Use all available products from bootstrap sections
        final bootstrapProducts = <ProductModel>[
          ...featuredProducts,
          ...newArrivals,
          ...bestSellers,
          ...recommended,
        ];
        final branchProducts = selectedId > 0
            ? bootstrapProducts
                .where((p) => p.branchId == selectedId)
                .toList(growable: false)
            : bootstrapProducts;
        MockDataRepository.updateProducts(branchProducts);
      }

      if (Get.isRegistered<AppStateController>()) {
        Get.find<AppStateController>().calculatePromotions();
      }

      newP.value = List<ProductModel>.from(
          MockDataRepository.getNewArrivals(selectedId));
      bestSell.value = List<ProductModel>.from(
          MockDataRepository.getBestSellers(selectedId));
      bestSell2.value = List<ProductModel>.from(
          MockDataRepository.getRecommended(selectedId));
      shopProducts.value = List<ProductModel>.from(
          MockDataRepository.getShopProducts(selectedId));
    } catch (e) {
      newP.value = List<ProductModel>.from(
          MockDataRepository.getNewArrivals(selectedId));
      bestSell.value = List<ProductModel>.from(
          MockDataRepository.getBestSellers(selectedId));
      bestSell2.value = List<ProductModel>.from(
          MockDataRepository.getRecommended(selectedId));
      shopProducts.value = List<ProductModel>.from(
          MockDataRepository.getShopProducts(selectedId));
      print('ERROR: $e');
    } finally {
      isLoading.value = false;
    }
  }

  List<ProductModel> _parseProducts(dynamic raw) {
    if (raw is! List) {
      return const <ProductModel>[];
    }

    return raw
        .whereType<Map>()
        .map((item) => ProductModel.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);
  }

  List<dynamic> _asList(dynamic raw) => raw is List ? raw : const [];

  List<StoreModel> _parseStores(dynamic raw) {
    return _asList(raw)
        .whereType<Map>()
        .map((item) => StoreModel.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);
  }

  List<CategoryModel> _parseCategories(dynamic raw) {
    return _asList(raw)
        .whereType<Map>()
        .map((item) => CategoryModel.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);
  }
}
