import 'dart:math' as math;
import 'package:grocery_app/localization/localized_material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:grocery_app/controllers/app_state_controller.dart';
import 'package:grocery_app/data/mock_data.dart';
import 'package:grocery_app/localization/catalog_localization.dart';
import 'package:grocery_app/models/product_model.dart';
import 'package:grocery_app/styles/colors.dart';
import 'package:grocery_app/widgets/app_network_image.dart';
import 'package:grocery_app/widgets/cart_toast.dart';

class OptionSelectorBottomSheet extends StatefulWidget {
  final ProductModel product;
  final String? heroSuffix;
  final List<int>? initialOptionValueIds;
  final int? initialQuantity;
  final bool isEditingCart;

  const OptionSelectorBottomSheet({
    super.key,
    required this.product,
    this.heroSuffix,
    this.initialOptionValueIds,
    this.initialQuantity,
    this.isEditingCart = false,
  });

  static Future<void> show(
    BuildContext context,
    ProductModel product, {
    String? heroSuffix,
    List<int>? initialOptionValueIds,
    int? initialQuantity,
    bool isEditingCart = false,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => OptionSelectorBottomSheet(
        product: product,
        heroSuffix: heroSuffix,
        initialOptionValueIds: initialOptionValueIds,
        initialQuantity: initialQuantity,
        isEditingCart: isEditingCart,
      ),
    );
  }

  @override
  State<OptionSelectorBottomSheet> createState() =>
      _OptionSelectorBottomSheetState();
}

class _OptionSelectorBottomSheetState extends State<OptionSelectorBottomSheet> {
  final Map<int, List<ProductOptionValue>> _selectedOptions = {};
  int _quantity = 1;
  final AppStateController _appStateController = Get.find<AppStateController>();

  @override
  void initState() {
    super.initState();
    final currentProduct = p;
    for (int i = 0; i < currentProduct.optionGroups.length; i++) {
      final group = currentProduct.optionGroups[i];
      if (group.values.isNotEmpty) {
        final initialIds = widget.initialOptionValueIds?.toSet() ?? const {};
        final initialValues = group.values
            .where((value) => initialIds.contains(value.id))
            .take(group.effectiveMaximumSelections)
            .toList(growable: false);
        final defaultValues = group.values
            .where((value) => value.isDefault)
            .take(group.effectiveMaximumSelections)
            .toList(growable: false);
        final selected = initialValues.isNotEmpty
            ? initialValues
            : defaultValues;
        if (selected.isNotEmpty) {
          _selectedOptions[group.id] = List<ProductOptionValue>.from(selected);
        }
      }
    }
    if (widget.initialQuantity != null && widget.initialQuantity! > 0) {
      _quantity = widget.initialQuantity!;
    }
    final maxQ = maxQuantity;
    if (maxQ != null && maxQ > 0 && _quantity > maxQ) {
      _quantity = maxQ;
    }
  }

  ProductModel get p {
    final _ = _appStateController.stockUpdateTrigger.value;
    final latest = MockDataRepository.getProductById(widget.product.id);
    if (latest == null) {
      return widget.product;
    }

    // Remote sync can replace the repository entry with a compact product
    // payload that omits configuration. Keep the configuration from the item
    // the user tapped while still using the latest price and stock values.
    return latest.copyWith(
      hasVariants: latest.hasVariants || widget.product.hasVariants,
      optionGroups: widget.product.optionGroups.isNotEmpty
          ? widget.product.optionGroups
          : latest.optionGroups,
      variants: widget.product.variants.isNotEmpty
          ? widget.product.variants
          : latest.variants,
    );
  }

  ProductVariantModel? get matchedVariant {
    if (p.variants.isEmpty) {
      return null;
    }
    final variantValues = p.optionGroups
        .where((group) => group.type.toLowerCase() == 'variant')
        .expand((group) => _selectedOptions[group.id] ?? const [])
        .toList(growable: false);
    if (variantValues.isEmpty) return null;
    final selectedIds = variantValues.map((value) => value.id).toSet();
    for (final variant in p.variants) {
      final varIds = variant.optionValueIds.toSet();
      if (varIds.isNotEmpty && varIds.containsAll(selectedIds)) {
        return variant;
      }
    }
    // Fallback: match by option value names or variant name
    for (final variant in p.variants) {
      final vName = variant.name.toLowerCase();
      final allNamesMatch = variantValues.every(
        (val) =>
            vName.contains(val.name.toLowerCase()) ||
            variant.sku.toLowerCase().contains(val.name.toLowerCase()),
      );
      if (allNamesMatch) {
        return variant;
      }
    }
    return null;
  }

  List<ProductOptionValue> _selectionFor(ProductOptionGroup group) =>
      _selectedOptions[group.id] ?? const [];

  List<ProductOptionValue> get _allSelectedOptions => p.optionGroups
      .expand((group) => _selectionFor(group))
      .toList(growable: false);

  bool get _hasValidOptionSelections => p.optionGroups.every(
    (group) => group.isSelectionCountValid(_selectionFor(group).length),
  );

  bool get _hasCompleteVariantSelections => p.optionGroups
      .where((group) => group.type.toLowerCase() == 'variant')
      .every(
        (group) => group.isSelectionCountValid(_selectionFor(group).length),
      );

  bool _isOptionValueDisabled(
    int groupIndex,
    ProductOptionGroup group,
    ProductOptionValue val,
  ) {
    final selected = _selectionFor(group);
    final isSelected = selected.any((value) => value.id == val.id);
    if (group.allowsMultiple &&
        !isSelected &&
        selected.length >= group.effectiveMaximumSelections) {
      return true;
    }
    if (group.type.toLowerCase() != 'variant') return false;
    if (!p.stockControl) return false;
    if (p.variants.isEmpty) return false;

    final priorGroups = p.optionGroups.sublist(0, groupIndex);
    final priorSelected = priorGroups
        .where((priorGroup) => priorGroup.type.toLowerCase() == 'variant')
        .expand((priorGroup) => _selectionFor(priorGroup))
        .toList();

    return !p.variants.any((variant) {
      if (variant.stock <= 0) return false;

      // Check if variant matches `val`
      final matchesVal =
          (variant.optionValueIds.isNotEmpty &&
              variant.optionValueIds.contains(val.id)) ||
          variant.name.toLowerCase().contains(val.name.toLowerCase()) ||
          variant.sku.toLowerCase().contains(val.name.toLowerCase());
      if (!matchesVal) return false;

      // Check prior selections
      for (final prior in priorSelected) {
        final matchesPrior =
            (variant.optionValueIds.isNotEmpty &&
                variant.optionValueIds.contains(prior.id)) ||
            variant.name.toLowerCase().contains(prior.name.toLowerCase()) ||
            variant.sku.toLowerCase().contains(prior.name.toLowerCase());
        if (!matchesPrior) return false;
      }
      return true;
    });
  }

  void _selectOption(
    ProductOptionGroup group,
    ProductOptionValue val,
    int groupIndex,
  ) {
    final current = List<ProductOptionValue>.from(_selectionFor(group));
    final selectedIndex = current.indexWhere((value) => value.id == val.id);
    if (selectedIndex < 0 && _isOptionValueDisabled(groupIndex, group, val)) {
      return;
    }

    setState(() {
      if (!group.allowsMultiple) {
        if (selectedIndex >= 0) {
          _selectedOptions.remove(group.id);
        } else {
          _selectedOptions[group.id] = [val];
        }
      } else if (selectedIndex >= 0) {
        current.removeAt(selectedIndex);
        if (current.isEmpty) {
          _selectedOptions.remove(group.id);
        } else {
          _selectedOptions[group.id] = current;
        }
      } else {
        current.add(val);
        _selectedOptions[group.id] = current;
      }

      // Ensure subsequent groups have valid (non-disabled) selections
      for (int i = groupIndex + 1; i < p.optionGroups.length; i++) {
        final nextGroup = p.optionGroups[i];
        final validSelections = _selectionFor(nextGroup)
            .where((value) => !_isOptionValueDisabled(i, nextGroup, value))
            .toList(growable: false);
        if (validSelections.isEmpty) {
          _selectedOptions.remove(nextGroup.id);
        } else {
          _selectedOptions[nextGroup.id] = validSelections;
        }
      }

      final maxQ = maxQuantity;
      if (maxQ != null && maxQ > 0 && _quantity > maxQ) {
        _quantity = maxQ;
      } else if (maxQ != null && maxQ <= 0) {
        _quantity = 1;
      }
    });
  }

  int? get maxQuantity {
    final currentProduct = p;
    if (!currentProduct.stockControl) return null;

    final baseInCart = widget.isEditingCart
        ? 0
        : (_appStateController.cartQuantities[currentProduct.id] ?? 0);
    final remainingBase = math.max(0, currentProduct.stock - baseInCart);

    if (currentProduct.variants.isNotEmpty) {
      final variant = matchedVariant;
      if (variant == null) {
        return _hasCompleteVariantSelections ? 0 : null;
      }

      final variantInCart =
          (!widget.isEditingCart &&
              _appStateController.cartSelectedVariants[currentProduct.id] ==
                  variant.id)
          ? (_appStateController.cartQuantities[currentProduct.id] ?? 0)
          : 0;

      final remainingVariant = math.max(0, variant.stock - variantInCart);
      if (currentProduct.stock > 0) {
        return math.min(remainingVariant, remainingBase);
      }
      return remainingVariant;
    }

    return remainingBase;
  }

  double get unitPrice {
    final variant = matchedVariant;
    double price = variant?.resolvedPrice ?? p.displayPrice;
    for (final group in p.optionGroups) {
      if (variant != null && group.type.toLowerCase() == 'variant') continue;
      for (final val in _selectionFor(group)) {
        price += val.priceAdjustment;
      }
    }
    return price;
  }

  double get totalPrice => unitPrice * _quantity;

  String formatCurrency(double value) {
    if (Get.isRegistered<AppStateController>()) {
      return Get.find<AppStateController>().formatPrice(
        value,
        currencyCode: p.currencyCode,
        currencySymbol: p.currencySymbol,
      );
    }
    final symbol = p.currencySymbol;
    return '$symbol${NumberFormat('#,##0.00').format(value)}';
  }

  String _optionLabel(BuildContext context, ProductOptionValue value) {
    final name = value.localizedName(context);
    if (value.priceAdjustment == 0) return name;
    final sign = value.priceAdjustment > 0 ? '+' : '-';
    return '$name ($sign${formatCurrency(value.priceAdjustment.abs())})';
  }

  String _selectionRule(ProductOptionGroup group) {
    final requiredLabel = group.isRequired ? 'Required' : 'Optional';
    if (!group.allowsMultiple) return '$requiredLabel · Choose 1';
    final min = group.effectiveMinimumSelections;
    final max = group.effectiveMaximumSelections;
    if (min == 0) return '$requiredLabel · Choose up to $max';
    if (min == max) return '$requiredLabel · Choose $min';
    return '$requiredLabel · Choose $min–$max';
  }

  Widget _badgePill({
    required String label,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: Colors.white),
          const SizedBox(width: 3.5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final currentProduct = p;
      final mediaQuery = MediaQuery.of(context);
      final maxQ = maxQuantity;
      final isStockControlled = currentProduct.stockControl;
      final isOutOfStock = isStockControlled && maxQ != null && maxQ <= 0;
      final isQuantityExceeded =
          isStockControlled && maxQ != null && _quantity > maxQ;
      final hasValidVariant =
          currentProduct.variants.isEmpty ||
          (matchedVariant != null &&
              (!isStockControlled || matchedVariant!.stock > 0));
      final isAddToCartDisabled =
          !_hasValidOptionSelections ||
          !hasValidVariant ||
          isOutOfStock ||
          isQuantityExceeded;

      return Container(
        constraints: BoxConstraints(maxHeight: mediaQuery.size.height * 0.85),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle Bar
              const SizedBox(height: 10),
              Center(
                child: Container(
                  width: 38,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Modal Header (Matching Next.js ModalConfigProduct)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.tune_rounded,
                        color: Color(0xFF4F46E5),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.localizedName(context),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (p.sku.isNotEmpty)
                            Text(
                              p.sku,
                              style: const TextStyle(
                                fontSize: 12,
                                fontFamily: 'monospace',
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Color(0xFF94A3B8)),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 12),

              // Scrollable Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Preview Card (Matching Next.js ModalConfigProduct)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: AppNetworkImage(
                                  image: p.image,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Badges
                                  if (p.isTryOnEnabled ||
                                      p.isPremium ||
                                      p.isFeatured ||
                                      p.isNewArrival)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Wrap(
                                        spacing: 4,
                                        runSpacing: 4,
                                        children: [
                                          if (p.isTryOnEnabled)
                                            _badgePill(
                                              label: 'Try-On',
                                              color: const Color(0xFF7C3AED),
                                              icon: Icons.auto_awesome,
                                            ),
                                          if (p.isPremium)
                                            _badgePill(
                                              label: 'Premium',
                                              color: const Color(0xFFD97706),
                                              icon: Icons.workspace_premium,
                                            ),
                                          if (p.isFeatured)
                                            _badgePill(
                                              label: 'Featured',
                                              color: const Color(0xFF2563EB),
                                              icon: Icons.star,
                                            ),
                                          if (p.isNewArrival)
                                            _badgePill(
                                              label: 'New',
                                              color: const Color(0xFF059669),
                                              icon: Icons.auto_awesome,
                                            ),
                                        ],
                                      ),
                                    ),
                                  Text(
                                    'Base Price: ${formatCurrency(p.price)}',
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    formatCurrency(unitPrice),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'monospace',
                                      color: AppColors.primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Virtual Try-On Supported Banner
                      if (p.isTryOnEnabled) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F3FF),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFDDD6FE)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF7C3AED),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.auto_awesome,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Virtual Try-On Supported',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF5B21B6),
                                      ),
                                    ),
                                    Text(
                                      'This item is flagged for customer garment virtual preview',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        color: Color(0xFF7C3AED),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF7C3AED),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: const Text(
                                  'Active',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 14),

                      // Option Groups
                      if (p.optionGroups.isNotEmpty)
                        ...p.optionGroups.asMap().entries.map((entry) {
                          final groupIndex = entry.key;
                          final group = entry.value;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: 4,
                                  bottom: 8,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      group.localizedName(context),
                                      style: const TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _selectionRule(group),
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        color: group.isRequired
                                            ? const Color(0xFFDC2626)
                                            : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: group.values.map((val) {
                                  final isSelected = _selectionFor(
                                    group,
                                  ).any((value) => value.id == val.id);
                                  final isDisabled = _isOptionValueDisabled(
                                    groupIndex,
                                    group,
                                    val,
                                  );

                                  return GestureDetector(
                                    onTap: isDisabled && !isSelected
                                        ? null
                                        : () => _selectOption(
                                            group,
                                            val,
                                            groupIndex,
                                          ),
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 150,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 8.5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? AppColors.primaryColor
                                            : isDisabled
                                            ? const Color(0xFFF8FAFC)
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: isSelected
                                              ? AppColors.primaryColor
                                              : const Color(0xFFE2E8F0),
                                          width: isSelected ? 1.5 : 1.0,
                                        ),
                                      ),
                                      child: Text(
                                        _optionLabel(context, val),
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.w500,
                                          color: isSelected
                                              ? Colors.white
                                              : isDisabled
                                              ? const Color(0xFF94A3B8)
                                              : const Color(0xFF0F172A),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 14),
                            ],
                          );
                        })
                      else
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: Text(
                              'No option configurations available for this item.',
                              style: TextStyle(color: Color(0xFF64748B)),
                            ),
                          ),
                        ),

                      // Quantity Stepper (Matching Next.js ModalConfigProduct)
                      const Divider(height: 24, color: Color(0xFFF1F5F9)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Quantity:',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                if (isStockControlled && maxQ != null)
                                  Text(
                                    maxQ > 0
                                        ? '$maxQ available'
                                        : 'Out of stock',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: maxQ > 0
                                          ? FontWeight.normal
                                          : FontWeight.w600,
                                      color: maxQ > 0
                                          ? const Color(0xFF64748B)
                                          : const Color(0xFFEF4444),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            height: 38,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove, size: 16),
                                  color: _quantity > 1
                                      ? const Color(0xFF475569)
                                      : const Color(0xFFCBD5E1),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minWidth: 36,
                                  ),
                                  onPressed: _quantity > 1
                                      ? () => setState(() => _quantity--)
                                      : null,
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  child: Text(
                                    '$_quantity',
                                    style: const TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add, size: 16),
                                  color: (maxQ == null || _quantity < maxQ)
                                      ? const Color(0xFF0F172A)
                                      : const Color(0xFFCBD5E1),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minWidth: 36,
                                  ),
                                  onPressed: (maxQ == null || _quantity < maxQ)
                                      ? () => setState(() => _quantity++)
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              // Bottom Action Buttons (Matching Next.js ModalConfigProduct)
              Padding(
                padding: const EdgeInsets.only(
                  left: 18,
                  right: 18,
                  top: 10,
                  bottom: 14,
                ),
                child: Row(
                  children: [
                    // Cancel Button
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF1F5F9),
                            foregroundColor: const Color(0xFF475569),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Add to Cart Button
                    Expanded(
                      flex: 3,
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            disabledBackgroundColor: const Color(0xFFCBD5E1),
                            disabledForegroundColor: Colors.white70,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: isAddToCartDisabled
                              ? null
                              : () {
                                  final variant = matchedVariant;
                                  final configuredProduct = p.copyWith(
                                    price: unitPrice,
                                  );

                                  final optionLabels = _allSelectedOptions
                                      .map(
                                        (value) => _optionLabel(context, value),
                                      )
                                      .where((s) => s.isNotEmpty)
                                      .toList();

                                  _appStateController.addToCart(
                                    configuredProduct,
                                    quantity: _quantity,
                                    variantId: variant?.id,
                                    optionValueIds: _allSelectedOptions
                                        .map((v) => v.id)
                                        .toList(growable: false),
                                    optionLabels: optionLabels,
                                    replaceQuantity: widget.isEditingCart,
                                  );

                                  final messenger = ScaffoldMessenger.of(
                                    context,
                                  );
                                  Navigator.pop(context);

                                  final optionsSummary = optionLabels.join(
                                    ', ',
                                  );

                                  showCartToast(
                                    messenger: messenger,
                                    productName: p.localizedName(context),
                                    quantity: _quantity,
                                    configuration: optionsSummary,
                                    isUpdate: widget.isEditingCart,
                                  );
                                },
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  isOutOfStock
                                      ? 'Out of Stock'
                                      : widget.isEditingCart
                                      ? 'Update Cart'
                                      : 'Add to Cart',
                                  style: const TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (!isOutOfStock) ...[
                                  const SizedBox(width: 6),
                                  const Text(
                                    '•',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    formatCurrency(totalPrice),
                                    style: const TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
