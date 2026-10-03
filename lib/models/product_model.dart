import 'package:get/get.dart';
import 'package:grocery_app/controllers/app_state_controller.dart';

class ProductPromotion {
  final int id;
  final String code;
  final String name;
  final String type; // 'item_price', 'subtotal_discount', 'bogo', etc.
  final String label; // e.g. '15% OFF +', 'PROMO PRICE', 'BUY 2 GET 1'
  final String summary;
  final double? promotionalPrice;
  final double? discountPercent;

  const ProductPromotion({
    required this.id,
    required this.code,
    required this.name,
    required this.type,
    required this.label,
    required this.summary,
    this.promotionalPrice,
    this.discountPercent,
  });

  factory ProductPromotion.fromJson(Map<String, dynamic> json) {
    return ProductPromotion(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      summary: json['summary']?.toString() ?? '',
      promotionalPrice: double.tryParse(
        json['promotional_price']?.toString() ?? '',
      ),
      discountPercent: double.tryParse(
        json['discount_percent']?.toString() ?? '',
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'name': name,
    'type': type,
    'label': label,
    'summary': summary,
    if (promotionalPrice != null) 'promotional_price': promotionalPrice,
    if (discountPercent != null) 'discount_percent': discountPercent,
  };
}

class ProductOptionValue {
  final int id;
  final String name;
  final String foreignName;
  final String? colorHex;
  final double priceAdjustment;
  final bool isDefault;

  const ProductOptionValue({
    required this.id,
    required this.name,
    this.foreignName = '',
    this.colorHex,
    this.priceAdjustment = 0.0,
    this.isDefault = false,
  });

  factory ProductOptionValue.fromJson(Map<String, dynamic> json) {
    return ProductOptionValue(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name']?.toString() ?? '',
      foreignName: json['foreign_name']?.toString() ?? '',
      colorHex: json['color_hex']?.toString(),
      priceAdjustment:
          double.tryParse(json['price_adjustment']?.toString() ?? '') ?? 0.0,
      isDefault:
          json['is_default'] == true ||
          json['is_default'] == 1 ||
          json['is_default'] == '1',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'foreign_name': foreignName,
    if (colorHex != null) 'color_hex': colorHex,
    'price_adjustment': priceAdjustment,
    'is_default': isDefault,
  };
}

class ProductOptionGroup {
  final int id;
  final String name;
  final String foreignName;
  final String type; // 'variant', 'modifier', etc.
  final String selectionType; // 'single', 'multiple'
  final bool isRequired;
  final int minSelections;
  final int? maxSelections;
  final List<ProductOptionValue> values;

  const ProductOptionGroup({
    required this.id,
    required this.name,
    this.foreignName = '',
    this.type = 'variant',
    this.selectionType = 'single',
    this.isRequired = true,
    this.minSelections = 1,
    this.maxSelections,
    this.values = const [],
  });

  bool get allowsMultiple => selectionType.toLowerCase() == 'multiple';

  int get effectiveMinimumSelections {
    if (!isRequired) return 0;
    return minSelections > 0 ? minSelections : 1;
  }

  int get effectiveMaximumSelections {
    if (!allowsMultiple) return 1;
    final configuredMaximum = maxSelections;
    if (configuredMaximum == null || configuredMaximum <= 0) {
      return values.length;
    }
    return configuredMaximum;
  }

  bool isSelectionCountValid(int count) {
    return count >= effectiveMinimumSelections &&
        count <= effectiveMaximumSelections;
  }

  factory ProductOptionGroup.fromJson(Map<String, dynamic> json) {
    final rawValues = json['values'] is List
        ? json['values'] as List
        : const [];
    final parsedValues = rawValues
        .whereType<Map>()
        .map((v) => ProductOptionValue.fromJson(Map<String, dynamic>.from(v)))
        .toList(growable: false);

    return ProductOptionGroup(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name']?.toString() ?? '',
      foreignName: json['foreign_name']?.toString() ?? '',
      type: json['type']?.toString() ?? 'variant',
      selectionType: json['selection_type']?.toString() ?? 'single',
      isRequired:
          json['is_required'] != false &&
          json['is_required'] != 0 &&
          json['is_required'] != '0' &&
          json['is_required']?.toString().toLowerCase() != 'false',
      minSelections:
          int.tryParse(json['min_selections']?.toString() ?? '') ?? 1,
      maxSelections: int.tryParse(json['max_selections']?.toString() ?? ''),
      values: parsedValues,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'foreign_name': foreignName,
    'type': type,
    'selection_type': selectionType,
    'is_required': isRequired,
    'min_selections': minSelections,
    if (maxSelections != null) 'max_selections': maxSelections,
    'values': values.map((value) => value.toJson()).toList(growable: false),
  };
}

class ProductVariantModel {
  final int id;
  final String sku;
  final String? barcode;
  final String name;
  final double? price;
  final double resolvedPrice;
  final int stock;
  final bool isDefault;
  final List<int> optionValueIds;

  const ProductVariantModel({
    required this.id,
    required this.sku,
    this.barcode,
    this.name = '',
    this.price,
    required this.resolvedPrice,
    this.stock = 0,
    this.isDefault = false,
    this.optionValueIds = const [],
  });

  factory ProductVariantModel.fromJson(Map<String, dynamic> json) {
    final rawIds = json['option_value_ids'] is List
        ? json['option_value_ids'] as List
        : const [];
    return ProductVariantModel(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      sku: json['sku']?.toString() ?? '',
      barcode: json['barcode']?.toString(),
      name: json['name']?.toString() ?? '',
      price: double.tryParse(json['price']?.toString() ?? ''),
      resolvedPrice:
          double.tryParse(
            json['resolved_price']?.toString() ??
                json['price']?.toString() ??
                '',
          ) ??
          0.0,
      stock: int.tryParse(json['stock']?.toString() ?? '') ?? 0,
      isDefault:
          json['is_default'] == true ||
          json['is_default'] == 1 ||
          json['is_default'] == '1',
      optionValueIds: rawIds
          .map((id) => int.tryParse(id.toString()))
          .whereType<int>()
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'sku': sku,
    if (barcode != null) 'barcode': barcode,
    'name': name,
    if (price != null) 'price': price,
    'resolved_price': resolvedPrice,
    'stock': stock,
    'is_default': isDefault,
    'option_value_ids': optionValueIds,
  };

  ProductVariantModel copyWith({
    int? id,
    String? sku,
    String? barcode,
    String? name,
    double? price,
    double? resolvedPrice,
    int? stock,
    bool? isDefault,
    List<int>? optionValueIds,
  }) {
    return ProductVariantModel(
      id: id ?? this.id,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      name: name ?? this.name,
      price: price ?? this.price,
      resolvedPrice: resolvedPrice ?? this.resolvedPrice,
      stock: stock ?? this.stock,
      isDefault: isDefault ?? this.isDefault,
      optionValueIds: optionValueIds ?? this.optionValueIds,
    );
  }
}

class ProductUomModel {
  final int id;
  final String name;
  final String foreignName;
  final String code;
  final String symbol;
  final double conversionFactorToBase;
  final bool isBaseUnit;
  final double basePrice;
  final double price;
  final double reduceByPercent;
  final bool isAuto;
  final bool isActive;

  const ProductUomModel({
    required this.id,
    required this.name,
    this.foreignName = '',
    required this.code,
    required this.symbol,
    required this.conversionFactorToBase,
    required this.isBaseUnit,
    required this.basePrice,
    required this.price,
    this.reduceByPercent = 0.0,
    this.isAuto = true,
    this.isActive = true,
  });

  factory ProductUomModel.fromJson(Map<String, dynamic> json) {
    return ProductUomModel(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name']?.toString() ?? '',
      foreignName: json['foreign_name']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      symbol: json['symbol']?.toString() ?? json['code']?.toString() ?? '',
      conversionFactorToBase:
          double.tryParse(
            json['conversion_factor_to_base']?.toString() ?? '',
          ) ??
          1.0,
      isBaseUnit: json['is_base_unit'] == true,
      basePrice: double.tryParse(json['base_price']?.toString() ?? '') ?? 0.0,
      price: double.tryParse(json['price']?.toString() ?? '') ?? 0.0,
      reduceByPercent:
          double.tryParse(json['reduce_by_percent']?.toString() ?? '') ?? 0.0,
      isAuto: json['is_auto'] != false,
      isActive: json['is_active'] != false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'foreign_name': foreignName,
    'code': code,
    'symbol': symbol,
    'conversion_factor_to_base': conversionFactorToBase,
    'is_base_unit': isBaseUnit,
    'base_price': basePrice,
    'price': price,
    'reduce_by_percent': reduceByPercent,
    'is_auto': isAuto,
    'is_active': isActive,
  };
}

class ProductModel {
  final int id;
  final String sku;
  final String name;
  final String? khName;
  final String image;
  final double price;
  final double? promotionalPrice;
  final String categoryEn;
  final String categoryKh;
  final String description;
  final bool isNewArrival;
  final bool isFeatured;
  final bool isPremium;
  final bool isTryOnEnabled;
  final bool stockControl;
  final int stock;
  final String currencySymbol;
  final String currencyCode;
  final bool hasUOM;
  final String? uomGroupName;
  final String? uomGroupForeignName;
  final String? defaultUOMName;
  final String? defaultUOMForeignName;
  final String? defaultUOMCode;
  final bool hasVariants;
  final List<ProductPromotion> promotions;
  final int? branchId;
  final List<ProductUomModel> uomList;
  final List<ProductOptionGroup> optionGroups;
  final List<ProductVariantModel> variants;

  ProductModel({
    required this.id,
    this.sku = '',
    required this.name,
    this.khName,
    required this.image,
    required this.price,
    this.promotionalPrice,
    required this.categoryEn,
    required this.categoryKh,
    required this.description,
    this.isNewArrival = false,
    this.isFeatured = false,
    this.isPremium = false,
    this.isTryOnEnabled = false,
    this.stockControl = true,
    this.stock = 0,
    this.currencySymbol = '',
    this.currencyCode = '',
    this.hasUOM = false,
    this.uomGroupName,
    this.uomGroupForeignName,
    this.defaultUOMName,
    this.defaultUOMForeignName,
    this.defaultUOMCode,
    this.hasVariants = false,
    this.promotions = const [],
    this.branchId,
    this.uomList = const [],
    this.optionGroups = const [],
    this.variants = const [],
  });

  bool get hasDiscount =>
      promotionalPrice != null &&
      promotionalPrice! > 0 &&
      promotionalPrice! < price;

  double get displayPrice => hasDiscount ? promotionalPrice! : price;

  bool get isOutOfStock => stockControl && stock <= 0;

  bool get isLowStock => stockControl && stock > 0 && stock <= 5;

  ProductModel copyWith({
    int? id,
    String? sku,
    String? name,
    String? khName,
    String? image,
    double? price,
    double? promotionalPrice,
    String? categoryEn,
    String? categoryKh,
    String? description,
    bool? isNewArrival,
    bool? isFeatured,
    bool? isPremium,
    bool? isTryOnEnabled,
    bool? stockControl,
    int? stock,
    String? currencySymbol,
    String? currencyCode,
    bool? hasUOM,
    String? uomGroupName,
    String? uomGroupForeignName,
    String? defaultUOMName,
    String? defaultUOMForeignName,
    String? defaultUOMCode,
    bool? hasVariants,
    List<ProductPromotion>? promotions,
    int? branchId,
    List<ProductUomModel>? uomList,
    List<ProductOptionGroup>? optionGroups,
    List<ProductVariantModel>? variants,
  }) {
    return ProductModel(
      id: id ?? this.id,
      sku: sku ?? this.sku,
      name: name ?? this.name,
      khName: khName ?? this.khName,
      image: image ?? this.image,
      price: price ?? this.price,
      promotionalPrice: promotionalPrice ?? this.promotionalPrice,
      categoryEn: categoryEn ?? this.categoryEn,
      categoryKh: categoryKh ?? this.categoryKh,
      description: description ?? this.description,
      isNewArrival: isNewArrival ?? this.isNewArrival,
      isFeatured: isFeatured ?? this.isFeatured,
      isPremium: isPremium ?? this.isPremium,
      isTryOnEnabled: isTryOnEnabled ?? this.isTryOnEnabled,
      stockControl: stockControl ?? this.stockControl,
      stock: stock ?? this.stock,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      currencyCode: currencyCode ?? this.currencyCode,
      hasUOM: hasUOM ?? this.hasUOM,
      uomGroupName: uomGroupName ?? this.uomGroupName,
      uomGroupForeignName: uomGroupForeignName ?? this.uomGroupForeignName,
      defaultUOMName: defaultUOMName ?? this.defaultUOMName,
      defaultUOMForeignName:
          defaultUOMForeignName ?? this.defaultUOMForeignName,
      defaultUOMCode: defaultUOMCode ?? this.defaultUOMCode,
      hasVariants: hasVariants ?? this.hasVariants,
      promotions: promotions ?? this.promotions,
      branchId: branchId ?? this.branchId,
      uomList: uomList ?? this.uomList,
      optionGroups: optionGroups ?? this.optionGroups,
      variants: variants ?? this.variants,
    );
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final category = json['category'] is Map<String, dynamic>
        ? json['category'] as Map<String, dynamic>
        : json['category'] is Map
        ? Map<String, dynamic>.from(json['category'] as Map)
        : const <String, dynamic>{};

    final promotionsList = (json['promotions'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((p) => ProductPromotion.fromJson(Map<String, dynamic>.from(p)))
        .toList(growable: false);

    ProductPromotion? itemPricePromo;
    for (final promo in promotionsList) {
      if (promo.type == 'item_price' &&
          promo.promotionalPrice != null &&
          promo.promotionalPrice! > 0) {
        itemPricePromo = promo;
        break;
      }
    }

    final regularPrice =
        double.tryParse(
          (json['price'] ?? json['final_price'] ?? 0).toString(),
        ) ??
        0;

    double? promoPrice = itemPricePromo?.promotionalPrice;
    if (promoPrice == null && json['promotional_price'] != null) {
      promoPrice = double.tryParse(json['promotional_price'].toString());
    }

    bool hasUOM = false;
    String? uomGroupName;
    String? uomGroupForeignName;
    String? defaultUOMName;
    String? defaultUOMForeignName;
    String? defaultUOMCode;
    List<ProductUomModel> uomList = const [];

    if (json['uom_group'] is Map && json['uom_group']['units'] is List) {
      uomGroupName = json['uom_group']['name']?.toString();
      uomGroupForeignName = json['uom_group']['foreign_name']?.toString();
      final rawUnits = json['uom_group']['units'] as List;
      final parsedUnits = rawUnits
          .whereType<Map>()
          .map((u) => ProductUomModel.fromJson(Map<String, dynamic>.from(u)))
          .where((u) => u.isActive)
          .toList(growable: false);

      uomList = parsedUnits;
      hasUOM =
          (json['item_type'] == 'uom' || json['item_type'] == null) &&
          parsedUnits.length > 1;

      final defaultUnit = parsedUnits.firstWhere(
        (u) => u.isBaseUnit,
        orElse: () => parsedUnits.isNotEmpty
            ? parsedUnits.first
            : const ProductUomModel(
                id: 0,
                name: 'Each',
                code: 'ea',
                symbol: 'ea',
                conversionFactorToBase: 1.0,
                isBaseUnit: true,
                basePrice: 0.0,
                price: 0.0,
              ),
      );
      if (parsedUnits.isNotEmpty) {
        defaultUOMName = defaultUnit.name;
        defaultUOMForeignName = defaultUnit.foreignName;
        defaultUOMCode = defaultUnit.symbol.isNotEmpty
            ? defaultUnit.symbol
            : defaultUnit.code;
      }
    }

    final rawOptionGroups =
        (json['option_groups'] as List<dynamic>? ?? const []);
    final parsedOptionGroups = rawOptionGroups
        .whereType<Map>()
        .map((g) => ProductOptionGroup.fromJson(Map<String, dynamic>.from(g)))
        .toList(growable: false);

    final rawVariants = (json['variants'] as List<dynamic>? ?? const []);
    final parsedVariants = rawVariants
        .whereType<Map>()
        .map((v) => ProductVariantModel.fromJson(Map<String, dynamic>.from(v)))
        .toList(growable: false);

    // 1. Fetch currency directly from API product payload or active backend currency
    String? apiCurrencySymbol;
    String? apiCurrencyCode;

    if (json['currency'] is Map) {
      final cMap = Map<String, dynamic>.from(json['currency'] as Map);
      apiCurrencySymbol = cMap['symbol']?.toString();
      apiCurrencyCode =
          cMap['code']?.toString() ?? cMap['currency_code']?.toString();
    } else if (json['currency'] is String &&
        json['currency'].toString().trim().isNotEmpty) {
      final cStr = json['currency'].toString().trim();
      if (cStr.length == 3 && RegExp(r'^[A-Za-z]{3}$').hasMatch(cStr)) {
        apiCurrencyCode = cStr.toUpperCase();
      } else {
        apiCurrencySymbol = cStr;
      }
    }

    // Direct product fields from API
    apiCurrencySymbol ??=
        json['currency_symbol']?.toString() ??
        json['currencySymbol']?.toString() ??
        json['symbol']?.toString();

    apiCurrencyCode ??=
        json['currency_code']?.toString() ?? json['currencyCode']?.toString();

    // If product payload does not provide currency, read from active currency fetched from backend
    if (apiCurrencySymbol == null || apiCurrencySymbol.trim().isEmpty) {
      if (Get.isRegistered<AppStateController>()) {
        final appState = Get.find<AppStateController>();
        if (appState.activeCurrencySymbol.value.isNotEmpty) {
          apiCurrencySymbol = appState.activeCurrencySymbol.value;
        }
        if ((apiCurrencyCode == null || apiCurrencyCode.isEmpty) &&
            appState.activeCurrencyCode.value.isNotEmpty) {
          apiCurrencyCode = appState.activeCurrencyCode.value;
        }
      }
    }

    final currencyCode = apiCurrencyCode?.trim() ?? '';
    final currencySymbol = apiCurrencySymbol?.replaceAll(r'\', '').trim() ?? '';

    final bool hasVariants =
        parsedOptionGroups.isNotEmpty ||
        parsedVariants.isNotEmpty ||
        json['has_variations'] == true ||
        (json['variants'] is List && (json['variants'] as List).isNotEmpty);

    return ProductModel(
      id: int.tryParse(json['id'].toString()) ?? 0,
      sku: json['sku']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      khName: json['foreign_name']?.toString() ?? json['kh_name']?.toString(),
      image:
          json['thumbnail_url']?.toString() ??
          json['image_url']?.toString() ??
          json['thumbnail']?.toString() ??
          '',
      price: regularPrice,
      promotionalPrice: promoPrice,
      categoryEn:
          category['name']?.toString() ?? json['cat_en']?.toString() ?? '',
      categoryKh:
          category['foreign_name']?.toString() ??
          json['cat_kh']?.toString() ??
          '',
      description: json['description']?.toString() ?? '',
      isNewArrival:
          json['is_new_arrival'] == true ||
          json['is_new_arrival'] == 1 ||
          json['is_new_arrival'] == '1',
      isFeatured:
          json['is_featured'] == true ||
          json['is_featured'] == 1 ||
          json['is_featured'] == '1',
      isPremium:
          json['is_premium'] == true ||
          json['is_premium'] == 1 ||
          json['is_premium'] == '1',
      isTryOnEnabled:
          json['is_try_on_enabled'] == true ||
          json['is_try_on_enabled'] == 1 ||
          json['is_try_on_enabled'] == '1',
      stockControl:
          json['stock_control'] != false &&
          json['stock_control'] != 0 &&
          json['stock_control'] != '0',
      stock: int.tryParse(json['stock']?.toString() ?? '0') ?? 0,
      currencySymbol: currencySymbol,
      currencyCode: currencyCode,
      hasUOM: hasUOM,
      uomGroupName: uomGroupName,
      uomGroupForeignName: uomGroupForeignName,
      defaultUOMName: defaultUOMName,
      defaultUOMForeignName: defaultUOMForeignName,
      defaultUOMCode: defaultUOMCode,
      hasVariants: hasVariants,
      promotions: promotionsList,
      branchId: int.tryParse(
        json['branch_id']?.toString() ??
            json['branch']?['id']?.toString() ??
            '',
      ),
      uomList: uomList,
      optionGroups: parsedOptionGroups,
      variants: parsedVariants,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'sku': sku,
    'name': name,
    if (khName != null) 'foreign_name': khName,
    'image_url': image,
    'price': price,
    if (promotionalPrice != null) 'promotional_price': promotionalPrice,
    'category': {'name': categoryEn, 'foreign_name': categoryKh},
    'description': description,
    'is_new_arrival': isNewArrival,
    'is_featured': isFeatured,
    'is_premium': isPremium,
    'is_try_on_enabled': isTryOnEnabled,
    'stock_control': stockControl,
    'stock': stock,
    'currency': {'symbol': currencySymbol, 'code': currencyCode},
    'item_type': hasUOM ? 'uom' : 'standard',
    'uom_group': {
      'name': uomGroupName,
      'foreign_name': uomGroupForeignName,
      'units': uomList.map((uom) => uom.toJson()).toList(growable: false),
    },
    'has_variations': hasVariants,
    'option_groups': optionGroups
        .map((group) => group.toJson())
        .toList(growable: false),
    'variants': variants
        .map((variant) => variant.toJson())
        .toList(growable: false),
    'promotions': promotions
        .map((promotion) => promotion.toJson())
        .toList(growable: false),
    if (branchId != null) 'branch_id': branchId,
  };
}
