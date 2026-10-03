class AppliedPromotionModel {
  const AppliedPromotionModel({
    required this.id,
    required this.code,
    required this.name,
    required this.type,
    required this.summary,
    required this.savings,
  });

  final int id;
  final String code;
  final String name;
  final String type;
  final String summary;
  final double savings;

  factory AppliedPromotionModel.fromJson(Map<String, dynamic> json) {
    return AppliedPromotionModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      summary: json['summary']?.toString() ?? '',
      savings: double.tryParse(json['savings']?.toString() ?? '0') ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'type': type,
      'summary': summary,
      'savings': savings,
    };
  }
}

class AutoAddItemModel {
  const AutoAddItemModel({
    required this.promotionId,
    required this.promotionName,
    required this.itemId,
    this.uomId,
    required this.quantity,
  });

  final int promotionId;
  final String promotionName;
  final int itemId;
  final int? uomId;
  final int quantity;

  factory AutoAddItemModel.fromJson(Map<String, dynamic> json) {
    return AutoAddItemModel(
      promotionId:
          int.tryParse(json['promotion_id']?.toString() ?? '0') ?? 0,
      promotionName: json['promotion_name']?.toString() ?? '',
      itemId: int.tryParse(json['item_id']?.toString() ?? '0') ?? 0,
      uomId: int.tryParse(json['uom_id']?.toString() ?? ''),
      quantity: int.tryParse(json['quantity']?.toString() ?? '1') ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'promotion_id': promotionId,
      'promotion_name': promotionName,
      'item_id': itemId,
      'uom_id': uomId,
      'quantity': quantity,
    };
  }
}

class CartPricingItemModel {
  const CartPricingItemModel({
    required this.itemId,
    this.itemVariantId,
    this.uomId,
    required this.sku,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.lineSubtotal,
    required this.discountAmount,
    required this.lineTotal,
    this.selectedOptionLabels = const [],
  });

  final int itemId;
  final int? itemVariantId;
  final int? uomId;
  final String sku;
  final String name;
  final int quantity;
  final double unitPrice;
  final double lineSubtotal;
  final double discountAmount;
  final double lineTotal;
  final List<String> selectedOptionLabels;

  factory CartPricingItemModel.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['selected_options'] as List<dynamic>? ?? const [];
    final labels = <String>[];
    for (final opt in rawOptions) {
      if (opt is Map) {
        final values = opt['values'] as List<dynamic>? ?? const [];
        for (final val in values) {
          if (val is Map && val['name'] != null) {
            final name = val['name'].toString().trim();
            if (name.isNotEmpty) {
              labels.add(name);
            }
          }
        }
      }
    }

    return CartPricingItemModel(
      itemId: int.tryParse(json['item_id']?.toString() ?? '0') ?? 0,
      itemVariantId:
          int.tryParse(json['item_variant_id']?.toString() ?? ''),
      uomId: int.tryParse(json['uom_id']?.toString() ?? ''),
      sku: json['sku']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      quantity: int.tryParse(json['quantity']?.toString() ?? '1') ?? 1,
      unitPrice:
          double.tryParse(json['unit_price']?.toString() ?? '0') ?? 0.0,
      lineSubtotal:
          double.tryParse(json['line_subtotal']?.toString() ?? '0') ?? 0.0,
      discountAmount:
          double.tryParse(json['discount_amount']?.toString() ?? '0') ?? 0.0,
      lineTotal:
          double.tryParse(json['line_total']?.toString() ?? '0') ?? 0.0,
      selectedOptionLabels: labels,
    );
  }
}

class CartPricingResult {
  const CartPricingResult({
    required this.currencyMode,
    required this.subtotal,
    required this.discountTotal,
    required this.finalTotal,
    this.appliedPromotion,
    required this.items,
    required this.autoAddItems,
  });

  final String currencyMode;
  final double subtotal;
  final double discountTotal;
  final double finalTotal;
  final AppliedPromotionModel? appliedPromotion;
  final List<CartPricingItemModel> items;
  final List<AutoAddItemModel> autoAddItems;

  factory CartPricingResult.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? const [];
    final rawAutoAdds = json['auto_add_items'] as List<dynamic>? ?? const [];
    final rawPromo = json['applied_promotion'];

    return CartPricingResult(
      currencyMode: json['currency_mode']?.toString() ?? 'native',
      subtotal: double.tryParse(json['subtotal']?.toString() ?? '0') ?? 0.0,
      discountTotal:
          double.tryParse(json['discount_total']?.toString() ?? '0') ?? 0.0,
      finalTotal:
          double.tryParse(json['final_total']?.toString() ?? '0') ?? 0.0,
      appliedPromotion: rawPromo is Map
          ? AppliedPromotionModel.fromJson(Map<String, dynamic>.from(rawPromo))
          : null,
      items: rawItems
          .whereType<Map>()
          .map((e) => CartPricingItemModel.fromJson(
              Map<String, dynamic>.from(e)))
          .toList(growable: false),
      autoAddItems: rawAutoAdds
          .whereType<Map>()
          .map((e) =>
              AutoAddItemModel.fromJson(Map<String, dynamic>.from(e)))
          .toList(growable: false),
    );
  }
}
