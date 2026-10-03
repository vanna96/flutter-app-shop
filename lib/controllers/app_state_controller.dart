import 'dart:async';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:grocery_app/controllers/login_controller.dart';
import 'package:grocery_app/controllers/notification_controller.dart';
import 'package:grocery_app/controllers/product_controller.dart';
import 'package:grocery_app/data/mock_data.dart';
import 'package:grocery_app/models/cart_pricing_model.dart';
import 'package:grocery_app/models/currency_model.dart';
import 'package:grocery_app/models/product_model.dart';
import 'package:grocery_app/services/mobile_api_repository.dart';
import 'package:intl/intl.dart';

class CartLine {
  CartLine({
    required this.product,
    required this.quantity,
    this.isReward = false,
    this.rewardPromotionName,
    this.discountAmount = 0.0,
    this.promotionalUnitPrice,
    this.finalLineTotal,
    this.selectedUomName,
    this.selectedOptionLabels = const [],
    this.selectedVariantId,
    this.selectedUomId,
    this.selectedOptionValueIds = const [],
  });

  final ProductModel product;
  final int quantity;
  final bool isReward;
  final String? rewardPromotionName;
  final double discountAmount;
  final double? promotionalUnitPrice;
  final double? finalLineTotal;
  final String? selectedUomName;
  final List<String> selectedOptionLabels;
  final int? selectedVariantId;
  final int? selectedUomId;
  final List<int> selectedOptionValueIds;

  double get unitPrice => promotionalUnitPrice ?? product.price;
  double get originalTotalPrice => product.price * quantity;
  double get totalPrice => isReward
      ? 0.0
      : (finalLineTotal ?? (unitPrice * quantity - discountAmount));
}

class OrderLine {
  OrderLine({
    required this.productId,
    required this.name,
    this.foreignName,
    required this.image,
    required this.quantity,
    required this.unitPrice,
  });

  final int productId;
  final String name;
  final String? foreignName;
  final String image;
  final int quantity;
  final double unitPrice;

  double get totalPrice => unitPrice * quantity;

  String get displayImage {
    final trimmed = image.trim();
    if (trimmed.isNotEmpty) return trimmed;
    if (productId > 0) {
      final p = MockDataRepository.getProductById(productId);
      if (p != null && p.image.trim().isNotEmpty) {
        return p.image.trim();
      }
    }
    if (name.trim().isNotEmpty) {
      final query = name.trim().toLowerCase();
      for (final p in MockDataRepository.allProducts) {
        if (p.name.trim().toLowerCase() == query && p.image.trim().isNotEmpty) {
          return p.image.trim();
        }
      }
    }
    return '';
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'name': name,
      if (foreignName != null) 'foreign_name': foreignName,
      'image': displayImage.isNotEmpty ? displayImage : image,
      'quantity': quantity,
      'unit_price': unitPrice,
    };
  }

  factory OrderLine.fromJson(Map<String, dynamic> json) {
    final productId =
        int.tryParse(
          (json['product_id'] ?? json['item_id'])?.toString() ?? '0',
        ) ??
        0;
    var rawName = (json['name'] ?? json['item_title'])?.toString() ?? '';
    var rawImage =
        (json['image_url'] ?? json['image'] ?? json['thumbnail_url'])
            ?.toString() ??
        '';

    if (rawImage.isEmpty && productId > 0) {
      final p = MockDataRepository.getProductById(productId);
      if (p != null && p.image.trim().isNotEmpty) {
        rawImage = p.image.trim();
      }
    }
    if (rawImage.isEmpty && rawName.isNotEmpty) {
      final query = rawName.trim().toLowerCase();
      for (final p in MockDataRepository.allProducts) {
        if (p.name.trim().toLowerCase() == query && p.image.trim().isNotEmpty) {
          rawImage = p.image.trim();
          break;
        }
      }
    }
    if (rawName.isEmpty && productId > 0) {
      final p = MockDataRepository.getProductById(productId);
      if (p != null && p.name.trim().isNotEmpty) {
        rawName = p.name.trim();
      }
    }

    return OrderLine(
      productId: productId,
      name: rawName.isNotEmpty ? rawName : 'Product #$productId',
      foreignName: json['foreign_name']?.toString(),
      image: rawImage,
      quantity: int.tryParse(json['quantity']?.toString() ?? '1') ?? 1,
      unitPrice:
          double.tryParse(
            (json['unit_price'] ?? json['unit_price_base'])?.toString() ?? '0',
          ) ??
          0.0,
    );
  }
}

class OrderRecord {
  OrderRecord({
    required this.id,
    required this.createdAt,
    required this.status,
    required this.totalAmount,
    required this.totalItems,
    required this.lines,
    this.paymentMethod = 'Cash',
    this.saleFrom = 'mobile',
    this.subtotal,
    this.discountTotal = 0.0,
    this.orderType = 'Delivery',
    this.currencyCode = '',
  });

  final String id;
  final DateTime createdAt;
  final String status;
  final double totalAmount;
  final int totalItems;
  final List<OrderLine> lines;
  final String paymentMethod;
  final String saleFrom;
  final double? subtotal;
  final double discountTotal;
  final String orderType;
  final String currencyCode;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'status': status,
      'total_amount': totalAmount,
      'total_items': totalItems,
      'payment_method': paymentMethod,
      'sale_from': saleFrom,
      'subtotal': subtotal,
      'discount_total': discountTotal,
      'order_type': orderType,
      'currency_code': currencyCode,
      'lines': lines.map((line) => line.toJson()).toList(growable: false),
    };
  }

  factory OrderRecord.fromJson(Map<String, dynamic> json) {
    final rawLines =
        (json['lines'] ?? json['items']) as List<dynamic>? ?? const [];
    return OrderRecord(
      id: json['order_number']?.toString() ?? json['id']?.toString() ?? '',
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.tryParse(json['placed_at']?.toString() ?? '') ??
          DateTime.now(),
      status: json['status']?.toString() ?? 'Completed',
      totalAmount:
          double.tryParse(
            (json['total_amount'] ?? json['total'])?.toString() ?? '0',
          ) ??
          0.0,
      totalItems:
          int.tryParse(
            (json['total_items'] ?? json['item_count'])?.toString() ?? '0',
          ) ??
          0,
      paymentMethod: json['payment_method']?.toString() ?? 'Cash',
      saleFrom: json['sale_from']?.toString() ?? 'mobile',
      subtotal: double.tryParse(
        (json['subtotal'] ?? json['subtotal_base'])?.toString() ?? '',
      ),
      discountTotal:
          double.tryParse(
            (json['discount_total'] ?? json['discount_base'])?.toString() ??
                '0',
          ) ??
          0.0,
      orderType:
          json['delivery_method']?.toString() ??
          json['order_type']?.toString() ??
          'Delivery',
      currencyCode:
          json['currency_code']?.toString() ??
          json['base_currency_code']?.toString() ??
          '',
      lines: rawLines
          .whereType<Map>()
          .map((line) => OrderLine.fromJson(Map<String, dynamic>.from(line)))
          .toList(growable: false),
    );
  }
}

class AppStateController extends GetxController {
  static const List<String> _obsoleteLocalCartKeys = [
    'cart_by_store_v2',
    'cart_quantities',
    'cart_selected_variants',
    'cart_selected_uoms',
    'cart_selected_options',
    'cart_selected_option_labels',
    'cart_selected_uom_names',
  ];

  AppStateController({
    GetStorage? storage,
    MobileApiRepository? mobileApiRepository,
  }) : _storage = storage ?? GetStorage(),
       _mobileApiRepository = mobileApiRepository ?? MobileApiRepository();

  final GetStorage _storage;
  final MobileApiRepository _mobileApiRepository;
  List<Map<String, dynamic>>? _pendingCartSync;
  bool _cartSyncInProgress = false;
  Future<void>? _cartSyncFuture;
  bool _isApplyingRemoteCart = false;

  final RxMap<int, int> cartQuantities = <int, int>{}.obs;
  final RxMap<int, int> cartSelectedVariants = <int, int>{}.obs;
  final RxMap<int, int> cartSelectedUoms = <int, int>{}.obs;
  final RxMap<int, List<int>> cartSelectedOptionValues = <int, List<int>>{}.obs;
  final RxMap<int, List<String>> cartSelectedOptionLabels =
      <int, List<String>>{}.obs;
  final RxMap<int, String> cartSelectedUomNames = <int, String>{}.obs;
  final RxMap<int, ProductModel> cartCachedProducts = <int, ProductModel>{}.obs;
  final RxList<int> favoriteIds = <int>[].obs;
  final RxList<OrderRecord> orderHistory = <OrderRecord>[].obs;
  final RxBool isSyncing = false.obs;

  // Promotion Pricing Reactive State (Matches Next.js PosSummaryCard & PosCartItem)
  final Rxn<AppliedPromotionModel> appliedPromotion =
      Rxn<AppliedPromotionModel>();
  final RxDouble promotionDiscountAmount = 0.0.obs;
  final RxDouble subTotalAmount = 0.0.obs;
  final RxDouble totalPayable = 0.0.obs;
  final RxBool isPromotionPricing = false.obs;
  final RxBool isPromotionChecked = false.obs;
  final RxnString promotionPricingError = RxnString();
  final RxnString cartErrorMessage = RxnString();
  final RxnString lastOrderError = RxnString();
  final RxList<CartLine> bogoRewardItems = <CartLine>[].obs;
  final RxInt stockUpdateTrigger = 0.obs;

  void notifyStockUpdated() {
    stockUpdateTrigger.value++;
  }

  static String extractErrorMessage(dynamic error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map) {
        if (data['errors'] is Map) {
          final errors = data['errors'] as Map;
          final errorMessages = <String>[];
          for (final entry in errors.entries) {
            if (entry.value is List && (entry.value as List).isNotEmpty) {
              errorMessages.add((entry.value as List).first.toString());
            } else if (entry.value != null) {
              errorMessages.add(entry.value.toString());
            }
          }
          if (errorMessages.isNotEmpty) {
            return errorMessages.join('\n');
          }
        }
        if (data['message'] != null &&
            data['message'].toString().trim().isNotEmpty) {
          return data['message'].toString().trim();
        }
        if (data['error'] != null &&
            data['error'].toString().trim().isNotEmpty) {
          return data['error'].toString().trim();
        }
      }
      if (error.response?.statusCode == 422) {
        return 'The request was unprocessable (422). Please verify your cart items.';
      }
      if (error.response?.statusCode == 401) {
        return 'Please sign in to place and save your order.';
      }
      if (error.response?.statusCode == 403) {
        return 'Access denied for the current store or tenant.';
      }
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        return 'Network connection timeout. Please check your internet connection.';
      }
    }
    return error.toString();
  }

  CartPricingResult? _cartPricingResult;
  Timer? _pricingDebounceTimer;
  int _pricingRequestSequence = 0;

  @override
  void onInit() {
    super.onInit();
    _loadStoredState();

    // Trigger initial promotion check
    calculatePromotions();

    Future<void>.microtask(() async {
      if (Get.isRegistered<LoginController>() &&
          Get.find<LoginController>().isAuthenticated.value) {
        await syncRemoteState();
      }
    });
  }

  // Dynamic Currencies & Multi-Currency System
  static double? _dynamicKhrExchangeRate;
  static bool get hasKhrExchangeRate {
    if (Get.isRegistered<AppStateController>()) {
      return Get.find<AppStateController>().hasExchangeRateFor('KHR');
    }
    return _dynamicKhrExchangeRate != null && _dynamicKhrExchangeRate! > 0;
  }

  static double get kKhrExchangeRate {
    if (Get.isRegistered<AppStateController>()) {
      return Get.find<AppStateController>().getExchangeRate('KHR') ??
          _dynamicKhrExchangeRate ??
          0.0;
    }
    return _dynamicKhrExchangeRate ?? 0.0;
  }

  static set kKhrExchangeRate(double? value) =>
      _dynamicKhrExchangeRate = (value != null && value > 0) ? value : null;

  final RxString activeCurrencyCode = ''.obs;
  final RxString activeCurrencySymbol = ''.obs;
  final Rx<double?> activeExchangeRate = Rx<double?>(null);
  final RxList<CurrencyModel> availableCurrencies = <CurrencyModel>[].obs;
  final Rx<CurrencyModel?> activeCurrency = Rx<CurrencyModel?>(null);

  CurrencyModel get baseCurrency =>
      availableCurrencies.firstWhereOrNull((c) => c.isDefault) ??
      activeCurrency.value ??
      (availableCurrencies.isNotEmpty
          ? availableCurrencies.first
          : CurrencyModel(
              code: activeCurrencyCode.value,
              symbol: activeCurrencySymbol.value,
              isDefault: true,
            ));

  String get baseCurrencyCode => baseCurrency.code;

  String get baseCurrencySymbol => baseCurrency.symbol;

  List<CurrencyModel> get foreignCurrencies => availableCurrencies
      .where(
        (c) =>
            !c.isDefault &&
            c.code.toUpperCase() != baseCurrencyCode.toUpperCase() &&
            c.status.toLowerCase() != 'inactive',
      )
      .toList();

  CurrencyModel? getCurrency(String? code) {
    if (code == null || code.trim().isEmpty) return null;
    final clean = code.trim().toUpperCase();
    return availableCurrencies.firstWhereOrNull(
      (c) => c.code.toUpperCase() == clean,
    );
  }

  double? getExchangeRate(String? currencyCode) {
    if (currencyCode == null || currencyCode.trim().isEmpty) return null;
    final clean = currencyCode.trim().toUpperCase();
    if (clean == baseCurrencyCode.toUpperCase()) return 1.0;
    final curr = getCurrency(clean);
    if (curr == null) return null;
    return curr.hasExchangeRate ? curr.exchangeRate : null;
  }

  bool hasExchangeRateFor(String? currencyCode) {
    if (currencyCode == null || currencyCode.trim().isEmpty) return false;
    final clean = currencyCode.trim().toUpperCase();
    if (clean == baseCurrencyCode.toUpperCase()) return true;
    final curr = getCurrency(clean);
    if (curr == null) return false;
    return curr.hasExchangeRate;
  }

  double convertToBase(double amount, String? fromCurrencyCode) {
    if (fromCurrencyCode == null || fromCurrencyCode.trim().isEmpty)
      return amount;
    final clean = fromCurrencyCode.trim().toUpperCase();
    if (clean == baseCurrencyCode.toUpperCase()) return amount;
    final rate = getExchangeRate(clean);
    if (rate != null && rate > 0) {
      return amount / rate;
    }
    return amount;
  }

  double convertFromBase(double baseAmount, String? targetCurrencyCode) {
    if (targetCurrencyCode == null || targetCurrencyCode.trim().isEmpty)
      return baseAmount;
    final clean = targetCurrencyCode.trim().toUpperCase();
    if (clean == baseCurrencyCode.toUpperCase()) return baseAmount;
    final rate = getExchangeRate(clean);
    if (rate != null && rate > 0) {
      return baseAmount * rate;
    }
    return baseAmount;
  }

  String formatPrice(
    double amount, {
    String? currencyCode,
    String? currencySymbol,
    int? decimalPlaces,
  }) {
    final targetCode = (currencyCode != null && currencyCode.isNotEmpty)
        ? currencyCode
        : baseCurrencyCode;
    final curr = getCurrency(targetCode);
    final sym =
        currencySymbol ??
        curr?.symbol ??
        (targetCode.toUpperCase() == baseCurrencyCode.toUpperCase()
            ? baseCurrencySymbol
            : targetCode);
    final decimals =
        decimalPlaces ??
        curr?.decimalPlaces ??
        (targetCode.toUpperCase() == baseCurrencyCode.toUpperCase()
            ? baseCurrency.decimalPlaces
            : 2);
    final formatter = decimals > 0
        ? NumberFormat('#,##0.' + '0' * decimals)
        : NumberFormat('#,##0');
    return '$sym${formatter.format(amount)}';
  }

  void updateCurrenciesFromApi(
    List<CurrencyModel> list, {
    dynamic defaultCurrencyData,
    dynamic exchangeRateData,
  }) {
    if (list.isEmpty) return;

    String? defaultCode;
    if (defaultCurrencyData is Map) {
      defaultCode =
          (defaultCurrencyData['code'] ??
                  defaultCurrencyData['currency_code'] ??
                  defaultCurrencyData['currency'])
              ?.toString()
              .trim()
              .toUpperCase();
    } else if (defaultCurrencyData is String &&
        defaultCurrencyData.trim().isNotEmpty) {
      defaultCode = defaultCurrencyData.trim().toUpperCase();
    }

    if (defaultCode == null || defaultCode.isEmpty) {
      final existingDef = list.firstWhereOrNull((c) => c.isDefault);
      if (existingDef != null) {
        defaultCode = existingDef.code.toUpperCase();
      }
    }

    final updatedList = list.map((c) {
      final isDef = defaultCode != null
          ? c.code.toUpperCase() == defaultCode
          : c.isDefault;

      double rate = c.exchangeRate;
      if (isDef) {
        rate = 1.0;
      } else if (rate <= 0 && exchangeRateData != null) {
        final r = double.tryParse(exchangeRateData.toString());
        if (r != null && r > 0) {
          rate = r;
        }
      }

      return CurrencyModel(
        id: c.id,
        code: c.code,
        name: c.name,
        symbol: c.symbol,
        decimalPlaces: c.decimalPlaces,
        sortOrder: c.sortOrder,
        status: c.status,
        exchangeRate: rate,
        isDefault: isDef,
      );
    }).toList();

    if (defaultCurrencyData is Map) {
      final defModel = CurrencyModel.fromJson(
        Map<String, dynamic>.from(defaultCurrencyData),
      );
      if (defModel.code.isNotEmpty &&
          !updatedList.any(
            (c) => c.code.toUpperCase() == defModel.code.toUpperCase(),
          )) {
        updatedList.insert(
          0,
          CurrencyModel(
            id: defModel.id,
            code: defModel.code,
            name: defModel.name,
            symbol: defModel.symbol,
            decimalPlaces: defModel.decimalPlaces,
            sortOrder: defModel.sortOrder,
            status: defModel.status,
            exchangeRate: 1.0,
            isDefault: true,
          ),
        );
      }
    }

    if (!updatedList.any((c) => c.isDefault) && updatedList.isNotEmpty) {
      final first = updatedList.first;
      updatedList[0] = CurrencyModel(
        id: first.id,
        code: first.code,
        name: first.name,
        symbol: first.symbol,
        decimalPlaces: first.decimalPlaces,
        sortOrder: first.sortOrder,
        status: first.status,
        exchangeRate: 1.0,
        isDefault: true,
      );
    }

    if (exchangeRateData != null) {
      final r = double.tryParse(exchangeRateData.toString());
      if (r != null && r > 0) {
        final unconfigured = updatedList.firstWhereOrNull(
          (c) => !c.isDefault && c.exchangeRate <= 0,
        );
        if (unconfigured != null) {
          final idx = updatedList.indexOf(unconfigured);
          updatedList[idx] = CurrencyModel(
            id: unconfigured.id,
            code: unconfigured.code,
            name: unconfigured.name,
            symbol: unconfigured.symbol,
            decimalPlaces: unconfigured.decimalPlaces,
            sortOrder: unconfigured.sortOrder,
            status: unconfigured.status,
            exchangeRate: r,
            isDefault: false,
          );
        }
      }
    }

    availableCurrencies.value = updatedList;
    final defaultCurr =
        updatedList.firstWhereOrNull((c) => c.isDefault) ?? updatedList.first;
    activeCurrency.value = defaultCurr;
    activeCurrencyCode.value = defaultCurr.code;
    activeCurrencySymbol.value = defaultCurr.symbol;

    final firstForeignWithRate = updatedList.firstWhereOrNull(
      (c) => !c.isDefault && c.hasExchangeRate,
    );
    if (firstForeignWithRate != null) {
      _dynamicKhrExchangeRate = firstForeignWithRate.exchangeRate;
      activeExchangeRate.value = firstForeignWithRate.exchangeRate;
    } else if (exchangeRateData != null) {
      final r = double.tryParse(exchangeRateData.toString());
      if (r != null && r > 0) {
        _dynamicKhrExchangeRate = r;
        activeExchangeRate.value = r;
      } else {
        _dynamicKhrExchangeRate = null;
        activeExchangeRate.value = null;
      }
    } else {
      _dynamicKhrExchangeRate = null;
      activeExchangeRate.value = null;
    }
  }

  void updateCurrencyFromApi(dynamic currencyData, {dynamic exchangeRateData}) {
    if (currencyData == null && exchangeRateData == null) return;

    double? parsedRate;
    String? code;
    String? symbol;
    int decimals = 2;
    String name = '';
    int? id;

    if (currencyData is Map) {
      code =
          (currencyData['code'] ??
                  currencyData['currency_code'] ??
                  currencyData['currency'])
              ?.toString()
              .trim()
              .toUpperCase();
      symbol =
          (currencyData['symbol'] ??
                  currencyData['currency_symbol'] ??
                  currencyData['sign'])
              ?.toString()
              .replaceAll(r'\', '')
              .trim();
      name = currencyData['name']?.toString() ?? '';
      id = int.tryParse(currencyData['id']?.toString() ?? '');
      decimals =
          int.tryParse(currencyData['decimal_places']?.toString() ?? '') ?? 2;
      parsedRate = double.tryParse(
        currencyData['exchange_rate']?.toString() ??
            currencyData['rate']?.toString() ??
            currencyData['khr_exchange_rate']?.toString() ??
            '',
      );

      if (code != null && code.trim().isNotEmpty) {
        activeCurrencyCode.value = code.trim().toUpperCase();
      }
      if (symbol != null && symbol.trim().isNotEmpty) {
        activeCurrencySymbol.value = symbol.replaceAll(r'\', '').trim();
      }
    } else if (currencyData is String && currencyData.trim().isNotEmpty) {
      final str = currencyData.replaceAll(r'\', '').trim();
      if (str.length <= 3 && RegExp(r'^[A-Za-z]{3}$').hasMatch(str)) {
        code = str.toUpperCase();
        activeCurrencyCode.value = code;
      } else {
        symbol = str;
        activeCurrencySymbol.value = symbol;
      }
    }

    if (exchangeRateData != null) {
      final r = double.tryParse(exchangeRateData.toString());
      if (r != null && r > 0) {
        parsedRate = r;
      }
    }

    if (parsedRate != null && parsedRate > 0) {
      activeExchangeRate.value = parsedRate;
      kKhrExchangeRate = parsedRate;
    }

    if (code != null && code.isNotEmpty) {
      final singleCurr = CurrencyModel(
        id: id,
        code: code,
        name: name,
        symbol: symbol?.isNotEmpty == true ? symbol! : code,
        decimalPlaces: decimals,
        exchangeRate: 1.0,
        isDefault: true,
      );
      activeCurrency.value = singleCurr;
      if (availableCurrencies.isEmpty) {
        availableCurrencies.value = [singleCurr];
      } else {
        final idx = availableCurrencies.indexWhere(
          (c) => c.code.toUpperCase() == code,
        );
        if (idx >= 0) {
          availableCurrencies[idx] = singleCurr;
        } else {
          availableCurrencies.insert(0, singleCurr);
        }
      }
    }
  }

  List<CartLine> get cartItems {
    final isSubtotalPromo =
        _cartPricingResult?.appliedPromotion?.type == 'subtotal_discount';

    final userItems = cartQuantities.entries
        .map((entry) {
          final product =
              cartCachedProducts[entry.key] ??
              MockDataRepository.getProductById(entry.key);
          if (product == null) {
            return null;
          }

          final pricingItem = _cartPricingResult?.items.firstWhereOrNull(
            (item) => item.itemId == product.id,
          );

          // Subtotal discounts (like SPEND200) apply at cart summary level,
          // matching Next.js PosCartItem behavior.
          // Item-level discounts apply directly to the line item.
          double discount = 0.0;
          double? promoUnitPrice;
          double? lineTotal;

          if (pricingItem != null &&
              !isSubtotalPromo &&
              pricingItem.discountAmount > 0) {
            final isForeign =
                product.currencyCode.isNotEmpty &&
                product.currencyCode.toUpperCase() !=
                    baseCurrencyCode.toUpperCase();
            final rateFactor = isForeign
                ? (getExchangeRate(product.currencyCode) ?? 1.0)
                : 1.0;
            discount = isForeign
                ? (pricingItem.discountAmount * rateFactor)
                : pricingItem.discountAmount;
            promoUnitPrice = isForeign
                ? (pricingItem.lineTotal / pricingItem.quantity * rateFactor)
                : (pricingItem.lineTotal / pricingItem.quantity);
            lineTotal = isForeign
                ? (pricingItem.lineTotal * rateFactor)
                : pricingItem.lineTotal;
          }

          // Resolve Variant ID
          final resolvedVariantId =
              cartSelectedVariants[product.id] ??
              (product.variants.isNotEmpty
                  ? (product.variants
                            .firstWhereOrNull((v) => v.isDefault)
                            ?.id ??
                        product.variants.first.id)
                  : null);

          // Resolve Option Value IDs
          final resolvedOptionValueIds =
              cartSelectedOptionValues[product.id] ??
              (resolvedVariantId != null
                  ? product.variants
                        .firstWhereOrNull((v) => v.id == resolvedVariantId)
                        ?.optionValueIds
                  : null) ??
              const <int>[];

          // Resolve Option Labels
          List<String> optionLabels = [];
          if (cartSelectedOptionLabels[product.id]?.isNotEmpty == true) {
            optionLabels = List<String>.from(
              cartSelectedOptionLabels[product.id]!,
            );
          } else if (pricingItem != null &&
              pricingItem.selectedOptionLabels.isNotEmpty) {
            optionLabels = List<String>.from(pricingItem.selectedOptionLabels);
          } else {
            // Attempt to derive from option groups or variant
            if (resolvedOptionValueIds.isNotEmpty &&
                product.optionGroups.isNotEmpty) {
              final valMap = <int, String>{
                for (final g in product.optionGroups)
                  for (final val in g.values) val.id: val.name,
              };
              final names = resolvedOptionValueIds
                  .map((id) => valMap[id])
                  .whereType<String>()
                  .where((n) => n.trim().isNotEmpty)
                  .toList();
              if (names.isNotEmpty) {
                optionLabels = names;
              }
            }
            if (optionLabels.isEmpty && resolvedVariantId != null) {
              final matchingVariant = product.variants.firstWhereOrNull(
                (v) => v.id == resolvedVariantId,
              );
              if (matchingVariant != null &&
                  matchingVariant.name.trim().isNotEmpty) {
                if (matchingVariant.name.contains(' / ')) {
                  optionLabels = matchingVariant.name
                      .split(' / ')
                      .map((s) => s.trim())
                      .where((s) => s.isNotEmpty)
                      .toList();
                } else if (matchingVariant.name.contains('/')) {
                  optionLabels = matchingVariant.name
                      .split('/')
                      .map((s) => s.trim())
                      .where((s) => s.isNotEmpty)
                      .toList();
                } else {
                  optionLabels = [matchingVariant.name.trim()];
                }
              }
            }
          }

          // Resolve UOM ID & Name
          final resolvedUomId =
              cartSelectedUoms[product.id] ??
              (product.uomList.isNotEmpty
                  ? (product.uomList
                            .firstWhereOrNull((u) => u.isBaseUnit)
                            ?.id ??
                        product.uomList.first.id)
                  : null);

          String? uomName = cartSelectedUomNames[product.id];
          if ((uomName == null || uomName.isEmpty) &&
              resolvedUomId != null &&
              product.uomList.isNotEmpty) {
            final match = product.uomList.firstWhereOrNull(
              (u) => u.id == resolvedUomId,
            );
            if (match != null && match.name.isNotEmpty) {
              uomName = match.name;
            }
          }
          if (uomName == null || uomName.isEmpty) {
            uomName = product.defaultUOMName;
          }

          return CartLine(
            product: product,
            quantity: entry.value,
            discountAmount: discount,
            promotionalUnitPrice: promoUnitPrice,
            finalLineTotal: lineTotal,
            selectedUomName: uomName,
            selectedOptionLabels: optionLabels,
            selectedVariantId: resolvedVariantId,
            selectedUomId: resolvedUomId,
            selectedOptionValueIds: resolvedOptionValueIds,
          );
        })
        .whereType<CartLine>()
        .toList(growable: false);

    return [...userItems, ...bogoRewardItems];
  }

  List<ProductModel> get favoriteProducts {
    return favoriteIds
        .map(MockDataRepository.getProductById)
        .whereType<ProductModel>()
        .toList(growable: false);
  }

  int get cartItemCount {
    final userCount = cartQuantities.values.fold(
      0,
      (sum, quantity) => sum + quantity,
    );
    final rewardCount = bogoRewardItems.fold(
      0,
      (sum, item) => sum + item.quantity,
    );
    return userCount + rewardCount;
  }

  double get rawSubTotal {
    return cartQuantities.entries.fold(0.0, (sum, entry) {
      final product =
          cartCachedProducts[entry.key] ??
          MockDataRepository.getProductById(entry.key);
      if (product == null) return sum;
      final unitPriceInBase = convertToBase(
        product.price,
        product.currencyCode,
      );
      return sum + (unitPriceInBase * entry.value);
    });
  }

  double get subTotal =>
      subTotalAmount.value > 0 ? subTotalAmount.value : rawSubTotal;

  double get cartTotal {
    if (totalPayable.value > 0 || appliedPromotion.value != null) {
      return totalPayable.value;
    }
    return rawSubTotal;
  }

  bool get hasForeignCurrencyItems {
    return cartQuantities.keys.any((id) {
      final p = cartCachedProducts[id] ?? MockDataRepository.getProductById(id);
      return p != null &&
          p.currencyCode.isNotEmpty &&
          p.currencyCode.toUpperCase() != baseCurrencyCode.toUpperCase();
    });
  }

  List<String> get unconfiguredCartCurrencies {
    final missing = <String>{};
    for (final id in cartQuantities.keys) {
      final p = cartCachedProducts[id] ?? MockDataRepository.getProductById(id);
      if (p != null &&
          p.currencyCode.isNotEmpty &&
          p.currencyCode.toUpperCase() != baseCurrencyCode.toUpperCase()) {
        if (!hasExchangeRateFor(p.currencyCode)) {
          missing.add(p.currencyCode);
        }
      }
    }
    return missing.toList();
  }

  bool isFavorite(int productId) => favoriteIds.contains(productId);

  int quantityFor(int productId) => cartQuantities[productId] ?? 0;

  void calculatePromotions() {
    final requestId = ++_pricingRequestSequence;
    if (cartQuantities.isEmpty) {
      _pricingDebounceTimer?.cancel();
      bogoRewardItems.clear();
      appliedPromotion.value = null;
      promotionDiscountAmount.value = 0.0;
      subTotalAmount.value = 0.0;
      totalPayable.value = 0.0;
      isPromotionChecked.value = false;
      isPromotionPricing.value = false;
      promotionPricingError.value = null;
      _cartPricingResult = null;
      return;
    }

    final rawTotal = rawSubTotal;
    subTotalAmount.value = rawTotal;
    totalPayable.value = rawTotal;
    isPromotionPricing.value = true;
    promotionPricingError.value = null;

    _pricingDebounceTimer?.cancel();
    _pricingDebounceTimer = Timer(const Duration(milliseconds: 250), () async {
      await _fetchPromotionPricing(requestId);
    });
  }

  Future<void> _fetchPromotionPricing(int requestId) async {
    if (requestId != _pricingRequestSequence) return;
    if (cartQuantities.isEmpty) {
      isPromotionPricing.value = false;
      return;
    }

    try {
      final itemsPayload = <Map<String, dynamic>>[];
      final cartSnapshot = Map<int, int>.from(cartQuantities);
      for (final entry in cartSnapshot.entries) {
        var product =
            cartCachedProducts[entry.key] ??
            MockDataRepository.getProductById(entry.key);

        if (product == null ||
            (product.hasVariants && product.variants.isEmpty)) {
          final fetched = await _mobileApiRepository.fetchProductById(
            entry.key,
          );
          if (requestId != _pricingRequestSequence) return;
          if (fetched != null) {
            product = fetched;
            cartCachedProducts[entry.key] = fetched;
            MockDataRepository.updateProduct(fetched);
          }
        }

        if (product == null) continue;

        // Resolve variant ID
        int? variantId = cartSelectedVariants[product.id];
        if (variantId == null &&
            (product.variants.isNotEmpty || product.hasVariants)) {
          final defaultVariant =
              product.variants.firstWhereOrNull((v) => v.isDefault) ??
              (product.variants.isNotEmpty ? product.variants.first : null);
          variantId = defaultVariant?.id;
          if (variantId != null) {
            cartSelectedVariants[product.id] = variantId;
          }
        }

        // Resolve UOM ID
        int? uomId = cartSelectedUoms[product.id];
        if (uomId == null && (product.uomList.isNotEmpty || product.hasUOM)) {
          final baseUom =
              product.uomList.firstWhereOrNull((u) => u.isBaseUnit) ??
              (product.uomList.isNotEmpty ? product.uomList.first : null);
          uomId = baseUom?.id;
          if (uomId != null) {
            cartSelectedUoms[product.id] = uomId;
          }
        }

        // Resolve option value IDs
        List<int>? optionValueIds = cartSelectedOptionValues[product.id];
        if ((optionValueIds == null || optionValueIds.isEmpty) &&
            variantId != null) {
          final matchingVariant = product.variants.firstWhereOrNull(
            (v) => v.id == variantId,
          );
          if (matchingVariant != null &&
              matchingVariant.optionValueIds.isNotEmpty) {
            optionValueIds = matchingVariant.optionValueIds;
            cartSelectedOptionValues[product.id] = optionValueIds;
          }
        }

        itemsPayload.add({
          'item_id': product.id,
          if (variantId != null) 'variant_id': variantId,
          if (uomId != null) 'uom_id': uomId,
          if (optionValueIds != null && optionValueIds.isNotEmpty)
            'option_value_ids': optionValueIds,
          'quantity': entry.value,
        });
      }

      // Persist any product details or default selections resolved while
      // preparing the pricing request.
      if (requestId != _pricingRequestSequence) return;
      _persistCart();

      if (itemsPayload.isEmpty) {
        isPromotionPricing.value = false;
        return;
      }

      final pricing = await _mobileApiRepository.priceCart(
        items: itemsPayload,
        currencyMode: 'base',
      );
      if (requestId != _pricingRequestSequence) return;

      _cartPricingResult = pricing;
      appliedPromotion.value = pricing.appliedPromotion;
      promotionDiscountAmount.value = pricing.discountTotal;
      subTotalAmount.value = pricing.subtotal;
      totalPayable.value = pricing.finalTotal;

      // Handle auto add items (e.g. BOGO free reward products)
      final newRewards = <CartLine>[];
      for (final autoItem in pricing.autoAddItems) {
        var rewardProduct =
            cartCachedProducts[autoItem.itemId] ??
            MockDataRepository.getProductById(autoItem.itemId);
        if (rewardProduct == null) {
          try {
            final fetched = await _mobileApiRepository.fetchProductById(
              autoItem.itemId,
            );
            if (requestId != _pricingRequestSequence) return;
            if (fetched != null) {
              rewardProduct = fetched;
              cartCachedProducts[autoItem.itemId] = fetched;
              MockDataRepository.updateProduct(fetched);
            }
          } catch (_) {}
        }
        if (rewardProduct != null) {
          newRewards.add(
            CartLine(
              product: rewardProduct,
              quantity: autoItem.quantity,
              isReward: true,
              rewardPromotionName: autoItem.promotionName,
              discountAmount: rewardProduct.price * autoItem.quantity,
              promotionalUnitPrice: 0.0,
              finalLineTotal: 0.0,
            ),
          );
        }
      }
      bogoRewardItems.assignAll(newRewards);

      isPromotionChecked.value = true;
      promotionPricingError.value = null;
      cartErrorMessage.value = null;
    } catch (e) {
      if (requestId != _pricingRequestSequence) return;
      final errorMsg = extractErrorMessage(e);
      promotionPricingError.value = errorMsg;
      cartErrorMessage.value = errorMsg;
      // Fallback local promotion calculations (offline or error resilience)
      _applyLocalPromotionFallback();
    } finally {
      if (requestId == _pricingRequestSequence) {
        isPromotionPricing.value = false;
      }
    }
  }

  void _applyLocalPromotionFallback() {
    final sub = double.parse(rawSubTotal.toStringAsFixed(2));
    subTotalAmount.value = sub;

    // Check SPEND200 rule (15% off >= $200 in base currency)
    if (sub >= 200.0) {
      final savings = double.parse((sub * 0.15).toStringAsFixed(2));
      appliedPromotion.value = AppliedPromotionModel(
        id: 3,
        code: 'SPEND200',
        name: 'Pchum Ben Spend & Save',
        type: 'subtotal_discount',
        summary: 'Spend USD 200.00, get 15% off',
        savings: savings,
      );
      promotionDiscountAmount.value = savings;
      totalPayable.value = double.parse((sub - savings).toStringAsFixed(2));
    } else {
      appliedPromotion.value = null;
      promotionDiscountAmount.value = 0.0;
      totalPayable.value = sub;
    }

    isPromotionChecked.value = true;
  }

  Future<void> syncRemoteState() async {
    if (!Get.isRegistered<LoginController>() ||
        !Get.find<LoginController>().isAuthenticated.value) {
      return;
    }

    try {
      isSyncing.value = true;
      await Future.wait([syncFavorites(), syncOrders(), syncCartFromServer()]);
    } catch (e) {
      print('Remote sync error: $e');
    } finally {
      isSyncing.value = false;
    }
  }

  Future<void> syncFavorites() async {
    final result = await _mobileApiRepository.fetchFavorites();
    final ids = (result['ids'] as List<dynamic>? ?? const [])
        .map((item) => int.tryParse(item.toString()))
        .whereType<int>()
        .toList(growable: false);
    final products = (result['products'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((item) => ProductModel.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);

    if (products.isNotEmpty) {
      MockDataRepository.updateProducts(products);
    }

    favoriteIds.assignAll(ids);
    _persistFavorites();
  }

  Future<void> syncOrders() async {
    final orders = await _mobileApiRepository.fetchOrders();
    orderHistory.assignAll(
      orders.map(OrderRecord.fromJson).toList(growable: false),
    );
    _persistOrders();
  }

  Future<void> syncCartFromServer() async {
    if (!_isAuthenticated) return;

    final localQuantities = Map<int, int>.from(cartQuantities);
    final localVariants = Map<int, int>.from(cartSelectedVariants);
    final localUoms = Map<int, int>.from(cartSelectedUoms);
    final localOptions = <int, List<int>>{
      for (final entry in cartSelectedOptionValues.entries)
        entry.key: List<int>.from(entry.value),
    };
    final localOptionLabels = <int, List<String>>{
      for (final entry in cartSelectedOptionLabels.entries)
        entry.key: List<String>.from(entry.value),
    };
    final localUomNames = Map<int, String>.from(cartSelectedUomNames);
    final localProducts = Map<int, ProductModel>.from(cartCachedProducts);

    final remoteItems = await _mobileApiRepository.fetchCart();
    _applyRemoteCart(remoteItems);

    // A cart created before login is merged into the saved account cart.
    // The device selections win when the same product exists in both carts.
    if (localQuantities.isNotEmpty) {
      cartQuantities.addAll(localQuantities);
      cartSelectedVariants.addAll(localVariants);
      cartSelectedUoms.addAll(localUoms);
      cartSelectedOptionValues.addAll(localOptions);
      cartSelectedOptionLabels.addAll(localOptionLabels);
      cartSelectedUomNames.addAll(localUomNames);
      cartCachedProducts.addAll(localProducts);
      cartQuantities.refresh();
      calculatePromotions();
      await _mobileApiRepository.syncCart(items: _cartPayload());
    }
  }

  void _applyRemoteCart(List<Map<String, dynamic>> items) {
    _isApplyingRemoteCart = true;
    try {
      _clearCartMemory();
      for (final line in items) {
        final itemId = int.tryParse(line['item_id']?.toString() ?? '');
        final quantity = int.tryParse(line['quantity']?.toString() ?? '');
        if (itemId == null ||
            itemId <= 0 ||
            quantity == null ||
            quantity <= 0) {
          continue;
        }

        cartQuantities[itemId] = quantity;

        final variantId = int.tryParse(line['variant_id']?.toString() ?? '');
        if (variantId != null && variantId > 0) {
          cartSelectedVariants[itemId] = variantId;
        }

        final uomId = int.tryParse(line['uom_id']?.toString() ?? '');
        if (uomId != null && uomId > 0) {
          cartSelectedUoms[itemId] = uomId;
        }

        final optionValueIds =
            (line['option_value_ids'] as List<dynamic>? ?? const [])
                .map((value) => int.tryParse(value.toString()))
                .whereType<int>()
                .where((value) => value > 0)
                .toList(growable: false);
        if (optionValueIds.isNotEmpty) {
          cartSelectedOptionValues[itemId] = optionValueIds;
        }

        final rawProduct = line['product'];
        if (rawProduct is Map) {
          final product = ProductModel.fromJson(
            Map<String, dynamic>.from(rawProduct),
          );
          cartCachedProducts[itemId] = product;
          MockDataRepository.updateProduct(product);
        }
      }
      cartQuantities.refresh();
    } finally {
      _isApplyingRemoteCart = false;
    }
    calculatePromotions();
  }

  Future<void> toggleFavorite(ProductModel product) async {
    final wasFavorite = isFavorite(product.id);

    if (wasFavorite) {
      favoriteIds.remove(product.id);
    } else {
      favoriteIds.add(product.id);
    }

    favoriteIds.refresh();
    _persistFavorites();

    if (!Get.isRegistered<LoginController>() ||
        !Get.find<LoginController>().isAuthenticated.value) {
      return;
    }

    try {
      await _mobileApiRepository.toggleFavorite(product.id);
    } catch (_) {
      if (wasFavorite) {
        favoriteIds.add(product.id);
      } else {
        favoriteIds.remove(product.id);
      }
      favoriteIds.refresh();
      _persistFavorites();
    }
  }

  int? getMaxStock(ProductModel product, {int? variantId, int? uomId}) {
    final currentProduct =
        MockDataRepository.getProductById(product.id) ?? product;
    if (!currentProduct.stockControl) return null;

    final resolvedVariantId =
        variantId ?? cartSelectedVariants[currentProduct.id];
    if (resolvedVariantId != null && currentProduct.variants.isNotEmpty) {
      final v = currentProduct.variants.firstWhereOrNull(
        (v) => v.id == resolvedVariantId,
      );
      if (v != null) {
        final variantStock = v.stock;
        return variantStock < currentProduct.stock
            ? variantStock
            : currentProduct.stock;
      }
    }

    final resolvedUomId = uomId ?? cartSelectedUoms[currentProduct.id];
    if (resolvedUomId != null && currentProduct.uomList.isNotEmpty) {
      final u = currentProduct.uomList.firstWhereOrNull(
        (u) => u.id == resolvedUomId,
      );
      final factor = u?.conversionFactorToBase.toInt() ?? 1;
      final safeFactor = factor > 0 ? factor : 1;
      return currentProduct.stock ~/ safeFactor;
    }

    return currentProduct.stock;
  }

  void addToCart(
    ProductModel product, {
    int quantity = 1,
    int? variantId,
    int? uomId,
    List<int>? optionValueIds,
    List<String>? optionLabels,
    String? uomName,
    bool replaceQuantity = false,
  }) {
    final currentQuantity = cartQuantities[product.id] ?? 0;
    var targetQuantity = replaceQuantity
        ? quantity
        : (currentQuantity + quantity);

    if (product.stockControl) {
      final maxStock = getMaxStock(product, variantId: variantId, uomId: uomId);
      if (maxStock != null) {
        if (maxStock <= 0) {
          Get.snackbar(
            'Out of Stock',
            '${product.name} is currently out of stock.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
            duration: const Duration(seconds: 2),
          );
          return;
        }

        if (targetQuantity > maxStock) {
          targetQuantity = maxStock;
          Get.snackbar(
            'Maximum stock reached',
            'Maximum available stock ($maxStock) reached.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.black87,
            colorText: Colors.white,
            duration: const Duration(seconds: 2),
          );
        }
      }
    }

    cartQuantities[product.id] = targetQuantity;

    cartCachedProducts[product.id] = product;
    MockDataRepository.updateProduct(product);

    final resolvedVariantId =
        variantId ??
        (product.variants.isNotEmpty
            ? (product.variants.firstWhereOrNull((v) => v.isDefault)?.id ??
                  product.variants.first.id)
            : null);
    if (resolvedVariantId != null) {
      cartSelectedVariants[product.id] = resolvedVariantId;
    }

    final resolvedUomId =
        uomId ??
        (product.uomList.isNotEmpty
            ? (product.uomList.firstWhereOrNull((u) => u.isBaseUnit)?.id ??
                  product.uomList.first.id)
            : null);
    if (resolvedUomId != null) {
      cartSelectedUoms[product.id] = resolvedUomId;
    }

    if (optionValueIds != null) {
      if (optionValueIds.isEmpty) {
        cartSelectedOptionValues.remove(product.id);
      } else {
        cartSelectedOptionValues[product.id] = optionValueIds;
      }
    } else if (resolvedVariantId != null) {
      final matchingVariant = product.variants.firstWhereOrNull(
        (v) => v.id == resolvedVariantId,
      );
      if (matchingVariant != null &&
          matchingVariant.optionValueIds.isNotEmpty) {
        cartSelectedOptionValues[product.id] = matchingVariant.optionValueIds;
      }
    }

    if (optionLabels != null) {
      if (optionLabels.isEmpty) {
        cartSelectedOptionLabels.remove(product.id);
      } else {
        cartSelectedOptionLabels[product.id] = optionLabels;
      }
    } else if (resolvedVariantId != null) {
      final matchingVariant = product.variants.firstWhereOrNull(
        (v) => v.id == resolvedVariantId,
      );
      if (matchingVariant != null && matchingVariant.name.trim().isNotEmpty) {
        if (matchingVariant.name.contains(' / ')) {
          cartSelectedOptionLabels[product.id] = matchingVariant.name
              .split(' / ')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList();
        } else if (matchingVariant.name.contains('/')) {
          cartSelectedOptionLabels[product.id] = matchingVariant.name
              .split('/')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList();
        } else {
          cartSelectedOptionLabels[product.id] = [matchingVariant.name.trim()];
        }
      }
    }

    if (uomName != null && uomName.isNotEmpty) {
      cartSelectedUomNames[product.id] = uomName;
    } else if (resolvedUomId != null && product.uomList.isNotEmpty) {
      final match = product.uomList.firstWhereOrNull(
        (u) => u.id == resolvedUomId,
      );
      if (match != null && match.name.isNotEmpty) {
        cartSelectedUomNames[product.id] = match.name;
      }
    } else if (product.defaultUOMName != null &&
        product.defaultUOMName!.isNotEmpty) {
      cartSelectedUomNames[product.id] = product.defaultUOMName!;
    }

    cartQuantities.refresh();
    _persistCart();
    calculatePromotions();
  }

  void updateCartQuantity(ProductModel product, int quantity) {
    if (quantity <= 0) {
      removeFromCart(product.id);
      return;
    }

    var targetQuantity = quantity;
    if (product.stockControl) {
      final maxStock = getMaxStock(product);
      if (maxStock != null) {
        if (maxStock <= 0) {
          removeFromCart(product.id);
          Get.snackbar(
            'Out of Stock',
            '${product.name} is currently out of stock.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
            duration: const Duration(seconds: 2),
          );
          return;
        }

        if (targetQuantity > maxStock) {
          targetQuantity = maxStock;
          Get.snackbar(
            'Maximum stock reached',
            'Maximum available stock ($maxStock) reached.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.black87,
            colorText: Colors.white,
            duration: const Duration(seconds: 2),
          );
        }
      }
    }

    cartQuantities[product.id] = targetQuantity;
    cartQuantities.refresh();
    _persistCart();
    calculatePromotions();
  }

  void removeFromCart(int productId) {
    cartQuantities.remove(productId);
    cartSelectedVariants.remove(productId);
    cartSelectedUoms.remove(productId);
    cartSelectedOptionValues.remove(productId);
    cartSelectedOptionLabels.remove(productId);
    cartSelectedUomNames.remove(productId);
    cartCachedProducts.remove(productId);
    cartQuantities.refresh();
    _persistCart();
    calculatePromotions();
  }

  void clearCart() {
    cartQuantities.clear();
    cartSelectedVariants.clear();
    cartSelectedUoms.clear();
    cartSelectedOptionValues.clear();
    cartSelectedOptionLabels.clear();
    cartSelectedUomNames.clear();
    cartCachedProducts.clear();
    cartQuantities.refresh();
    _persistCart();
    calculatePromotions();
  }

  Future<OrderRecord?> placeOrder({
    String paymentMethod = 'Cash',
    String deliveryMethod = 'Home Delivery',
    String note = '',
  }) async {
    if (cartItems.isEmpty) {
      return null;
    }

    if (!Get.isRegistered<LoginController>() ||
        !Get.find<LoginController>().isAuthenticated.value) {
      Get.snackbar(
        'Login required',
        'Please sign in to place your order and save to your account.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return null;
    }

    final loginController = Get.find<LoginController>();
    final defaultAddress = loginController.defaultAddress;
    final addressId = defaultAddress?['id']?.toString();

    try {
      final regularItems = cartItems.where((i) => !i.isReward).toList();
      final orderItems = regularItems
          .map((item) {
            final variantId =
                cartSelectedVariants[item.product.id] ??
                (item.product.variants.isNotEmpty
                    ? (item.product.variants
                              .firstWhereOrNull((v) => v.isDefault)
                              ?.id ??
                          item.product.variants.first.id)
                    : null);
            final uomId =
                cartSelectedUoms[item.product.id] ??
                (item.product.uomList.isNotEmpty
                    ? (item.product.uomList
                              .firstWhereOrNull((u) => u.isBaseUnit)
                              ?.id ??
                          item.product.uomList.first.id)
                    : null);
            final optionValueIds =
                cartSelectedOptionValues[item.product.id] ??
                (variantId != null
                    ? item.product.variants
                          .firstWhereOrNull((v) => v.id == variantId)
                          ?.optionValueIds
                    : null);

            return {
              'item_id': item.product.id,
              if (variantId != null) 'variant_id': variantId,
              if (uomId != null) 'uom_id': uomId,
              if (optionValueIds != null && optionValueIds.isNotEmpty)
                'option_value_ids': optionValueIds,
              'quantity': item.quantity,
            };
          })
          .toList(growable: false);
      final expectedSubtotal = subTotal;
      final expectedDiscountTotal = promotionDiscountAmount.value;
      final expectedTotal = cartTotal;
      final expectedPromotionId = appliedPromotion.value?.id;

      // Do not let an older asynchronous cart write finish after checkout and
      // recreate rows that the order transaction has removed.
      await _settleCartSyncBeforeCheckout();

      final orderData = await _mobileApiRepository.placeOrder(
        addressId: addressId,
        items: orderItems,
        paymentMethod: paymentMethod,
        deliveryMethod: deliveryMethod,
        note: note,
        currencyMode: 'base',
        saleFrom: 'mobile',
        expectedSubtotal: expectedSubtotal,
        expectedDiscountTotal: expectedDiscountTotal,
        expectedTotal: expectedTotal,
        expectedPromotionId: expectedPromotionId,
      );

      final order = OrderRecord.fromJson(orderData);
      final enrichedLines = order.lines
          .map((line) {
            if (line.image.isNotEmpty) return line;
            CartLine? cartMatch;
            for (final c in regularItems) {
              if (c.product.id == line.productId) {
                cartMatch = c;
                break;
              }
            }
            final img = cartMatch?.product.image ?? line.displayImage;
            return OrderLine(
              productId: line.productId,
              name: line.name,
              foreignName: line.foreignName,
              image: img,
              quantity: line.quantity,
              unitPrice: line.unitPrice,
            );
          })
          .toList(growable: false);

      final finalOrder = OrderRecord(
        id: order.id,
        createdAt: order.createdAt,
        status: order.status,
        totalAmount: order.totalAmount,
        totalItems: order.totalItems,
        lines: enrichedLines,
        paymentMethod: order.paymentMethod,
        saleFrom: order.saleFrom,
        subtotal: order.subtotal,
        discountTotal: order.discountTotal,
        orderType: order.orderType,
        currencyCode: order.currencyCode,
      );

      // Immediately deduct stock locally for all ordered items
      for (final item in regularItems) {
        final current =
            MockDataRepository.getProductById(item.product.id) ?? item.product;
        final orderedQty = item.quantity;
        final variantId =
            item.selectedVariantId ?? cartSelectedVariants[current.id];
        final uomId = item.selectedUomId ?? cartSelectedUoms[current.id];

        int newProductStock = current.stock;
        if (current.stockControl) {
          if (uomId != null && current.uomList.isNotEmpty) {
            final uom = current.uomList.firstWhereOrNull((u) => u.id == uomId);
            final factor = uom?.conversionFactorToBase.toInt() ?? 1;
            final safeFactor = factor > 0 ? factor : 1;
            newProductStock = math.max(
              0,
              current.stock - (orderedQty * safeFactor),
            );
          } else {
            newProductStock = math.max(0, current.stock - orderedQty);
          }
        }

        List<ProductVariantModel> updatedVariants = current.variants;
        if (variantId != null && current.variants.isNotEmpty) {
          updatedVariants = current.variants
              .map((v) {
                if (v.id == variantId) {
                  final newVariantStock = math.max(0, v.stock - orderedQty);
                  return v.copyWith(stock: newVariantStock);
                }
                return v;
              })
              .toList(growable: false);
        }

        final updatedProduct = current.copyWith(
          stock: newProductStock,
          variants: updatedVariants,
        );

        MockDataRepository.updateProduct(updatedProduct);
        cartCachedProducts[current.id] = updatedProduct;
      }

      notifyStockUpdated();

      orderHistory.insert(0, finalOrder);
      orderHistory.refresh();
      _persistOrders();
      discardCart();

      if (Get.isRegistered<NotificationController>()) {
        await Get.find<NotificationController>().fetchInitData();
      }

      if (Get.isRegistered<ProductController>()) {
        Get.find<ProductController>().fetchInitData().then((_) {
          notifyStockUpdated();
        });
      }

      return finalOrder;
    } catch (e) {
      final errorMsg = extractErrorMessage(e);
      cartErrorMessage.value = errorMsg;
      lastOrderError.value = errorMsg;
      Get.snackbar(
        'Order Failed',
        errorMsg,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFEF4444),
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        icon: const Icon(Icons.error_outline_rounded, color: Colors.white),
      );
      print('Place order error: $e ($errorMsg)');
      rethrow;
    }
  }

  void _loadStoredState() {
    final storedFavorites = _storage.read('favorite_ids');
    if (storedFavorites is List) {
      favoriteIds.assignAll(
        storedFavorites
            .map((item) => int.tryParse(item.toString()))
            .whereType<int>(),
      );
    }

    final storedOrders = _storage.read('order_history');
    if (storedOrders is List) {
      orderHistory.assignAll(
        storedOrders.whereType<Map>().map(
          (order) => OrderRecord.fromJson(Map<String, dynamic>.from(order)),
        ),
      );
    }

    // Cart persistence is server-side. Remove values written by older app
    // versions so they cannot restore a stale device cart.
    for (final key in _obsoleteLocalCartKeys) {
      _storage.remove(key);
    }
  }

  void _persistFavorites() {
    _storage.write('favorite_ids', favoriteIds.toList(growable: false));
  }

  void _persistCart() {
    if (_isApplyingRemoteCart || !_isAuthenticated) return;
    _pendingCartSync = _cartPayload();
    if (_cartSyncFuture == null) {
      final future = _drainCartSyncQueue();
      _cartSyncFuture = future;
      unawaited(
        future.whenComplete(() {
          if (identical(_cartSyncFuture, future)) {
            _cartSyncFuture = null;
          }
        }),
      );
    }
  }

  Future<void> _settleCartSyncBeforeCheckout() async {
    final activeSync = _cartSyncFuture;
    if (activeSync != null) {
      await activeSync;
    }
    // A failed sync is intentionally discarded here because the order uses
    // the in-memory cart and clears the database atomically on success.
    _pendingCartSync = null;
  }

  void _clearCartMemory() {
    cartQuantities.clear();
    cartSelectedVariants.clear();
    cartSelectedUoms.clear();
    cartSelectedOptionValues.clear();
    cartSelectedOptionLabels.clear();
    cartSelectedUomNames.clear();
    cartCachedProducts.clear();
  }

  bool get _isAuthenticated =>
      Get.isRegistered<LoginController>() &&
      Get.find<LoginController>().isAuthenticated.value;

  List<Map<String, dynamic>> _cartPayload() {
    return cartQuantities.entries
        .where((entry) => entry.key > 0 && entry.value > 0)
        .map((entry) {
          final itemId = entry.key;
          final variantId = cartSelectedVariants[itemId];
          final uomId = cartSelectedUoms[itemId];
          final optionValueIds =
              cartSelectedOptionValues[itemId] ?? const <int>[];
          return <String, dynamic>{
            'item_id': itemId,
            'quantity': entry.value,
            if (variantId != null) 'variant_id': variantId,
            if (uomId != null) 'uom_id': uomId,
            if (optionValueIds.isNotEmpty) 'option_value_ids': optionValueIds,
          };
        })
        .toList(growable: false);
  }

  Future<void> _drainCartSyncQueue() async {
    if (_cartSyncInProgress || !_isAuthenticated) return;
    _cartSyncInProgress = true;
    try {
      while (_pendingCartSync != null && _isAuthenticated) {
        final payload = _pendingCartSync!;
        _pendingCartSync = null;
        try {
          if (payload.isEmpty) {
            await _mobileApiRepository.clearCart();
          } else {
            await _mobileApiRepository.syncCart(items: payload);
          }
          cartErrorMessage.value = null;
        } catch (error) {
          // Keep the latest unsaved cart for a retry on the next mutation or
          // explicit remote refresh, without writing it to device storage.
          if (_isAuthenticated) {
            _pendingCartSync ??= payload;
            cartErrorMessage.value = extractErrorMessage(error);
          } else {
            _pendingCartSync = null;
          }
          break;
        }
      }
    } finally {
      _cartSyncInProgress = false;
    }
  }

  void discardCart() {
    _pendingCartSync = null;
    _clearCartMemory();
    cartQuantities.refresh();
    calculatePromotions();
  }

  void _persistOrders() {
    _storage.write(
      'order_history',
      orderHistory.map((order) => order.toJson()).toList(growable: false),
    );
  }

  @override
  void onClose() {
    _pendingCartSync = null;
    _pricingDebounceTimer?.cancel();
    super.onClose();
  }
}
