import 'dart:math' as math;
import 'package:grocery_app/localization/localized_material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:grocery_app/controllers/app_state_controller.dart';
import 'package:grocery_app/controllers/login_controller.dart';
import 'package:grocery_app/data/mock_data.dart';
import 'package:grocery_app/helpers/responsive_layout.dart';
import 'package:grocery_app/localization/app_ui_translations.dart';
import 'package:grocery_app/localization/catalog_localization.dart';
import 'package:grocery_app/models/product_model.dart';
import 'package:grocery_app/widgets/app_network_image.dart';
import 'package:grocery_app/widgets/cart_toast.dart';

import 'favourite_toggle_icon_widget.dart';

class ProductDetailsScreen extends StatefulWidget {
  final ProductModel groceryItem;
  final String? heroSuffix;

  const ProductDetailsScreen(this.groceryItem, {super.key, this.heroSuffix});

  @override
  _ProductDetailsScreenState createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  int amount = 1;
  late ProductUomModel? _selectedUom;
  final Map<int, List<ProductOptionValue>> _selectedOptions = {};
  final AppStateController appStateController = Get.find<AppStateController>();
  final LoginController loginController = Get.find<LoginController>();

  @override
  void initState() {
    super.initState();
    if (widget.groceryItem.uomList.isNotEmpty) {
      _selectedUom = widget.groceryItem.uomList.firstWhere(
        (u) => u.isBaseUnit,
        orElse: () => widget.groceryItem.uomList.first,
      );
    } else {
      _selectedUom = null;
    }

    for (int i = 0; i < widget.groceryItem.optionGroups.length; i++) {
      final group = widget.groceryItem.optionGroups[i];
      if (group.values.isNotEmpty) {
        final defaults = group.values
            .where((value) => value.isDefault)
            .take(group.effectiveMaximumSelections)
            .toList(growable: false);
        if (defaults.isNotEmpty) {
          _selectedOptions[group.id] = defaults;
        }
      }
    }

    final maxQ = maxQuantity;
    if (maxQ != null && maxQ > 0 && amount > maxQ) {
      amount = maxQ;
    }
  }

  ProductModel get p {
    final _ = appStateController.stockUpdateTrigger.value;
    return MockDataRepository.getProductById(widget.groceryItem.id) ??
        widget.groceryItem;
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

      final matchesVal =
          (variant.optionValueIds.isNotEmpty &&
              variant.optionValueIds.contains(val.id)) ||
          variant.name.toLowerCase().contains(val.name.toLowerCase()) ||
          variant.sku.toLowerCase().contains(val.name.toLowerCase());
      if (!matchesVal) return false;

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
      if (maxQ != null && maxQ > 0 && amount > maxQ) {
        amount = maxQ;
      } else if (maxQ != null && maxQ <= 0) {
        amount = 1;
      }
    });
  }

  int? get maxQuantity {
    final current = p;
    if (!current.stockControl) return null;

    final baseInCart = appStateController.cartQuantities[current.id] ?? 0;
    final remainingBase = math.max(0, current.stock - baseInCart);

    if (current.variants.isNotEmpty) {
      final variant = matchedVariant;
      if (variant == null) {
        return _hasCompleteVariantSelections ? 0 : null;
      }

      final variantInCart =
          appStateController.cartSelectedVariants[current.id] == variant.id
          ? (appStateController.cartQuantities[current.id] ?? 0)
          : 0;

      final remainingVariant = math.max(0, variant.stock - variantInCart);
      if (current.stock > 0) {
        return math.min(remainingVariant, remainingBase);
      }
      return remainingVariant;
    }

    if (_selectedUom != null) {
      final factor = _selectedUom!.conversionFactorToBase.toInt();
      final safeFactor = factor > 0 ? factor : 1;
      return remainingBase ~/ safeFactor;
    }

    return remainingBase;
  }

  double get unitPrice {
    final variant = matchedVariant;
    double price =
        _selectedUom?.price ?? variant?.resolvedPrice ?? p.displayPrice;
    for (final group in p.optionGroups) {
      if (variant != null && group.type.toLowerCase() == 'variant') continue;
      for (final val in _selectionFor(group)) {
        price += val.priceAdjustment;
      }
    }
    return price;
  }

  double getTotalPrice() {
    return amount * unitPrice;
  }

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

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final currentProduct = p;
      final productDescription = currentProduct.description.isEmpty
          ? 'Freshly prepared and ready to add to your basket.'
          : currentProduct.description;
      final horizontalPadding = ResponsiveLayout.horizontalPadding(context);
      final contentMaxWidth = ResponsiveLayout.maxContentWidth(context);

      final uomSuffix = _selectedUom != null
          ? '/${_selectedUom!.name}'
          : (currentProduct.defaultUOMName != null &&
                    currentProduct.defaultUOMName!.isNotEmpty
                ? '/${currentProduct.defaultUOMName}'
                : '');

      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Column(
          children: [
            // 1. Curved Warm Gradient Top Header
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFF762D), Color(0xFFFF8E42)],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x28FF762D),
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    10,
                    horizontalPadding,
                    16,
                  ),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.22),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.categoryEn.isNotEmpty
                                  ? p.localizedCategoryName(context)
                                  : 'Product Details',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              p.localizedName(context),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Obx(() {
                        if (!loginController.isAuthenticated.value) {
                          return const SizedBox.shrink();
                        }

                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.22),
                                shape: BoxShape.circle,
                              ),
                              child: FavoriteToggleIcon(
                                product: widget.groceryItem,
                                size: 22,
                              ),
                            ),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),

            // 2. Scrollable Body Content
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: contentMaxWidth),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      14,
                      horizontalPadding,
                      30,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image Presentation Stage
                        _buildImageStage(context, p),

                        const SizedBox(height: 14),

                        // Product Title & Pricing Card
                        _buildProductInfoCard(p, uomSuffix),

                        const SizedBox(height: 14),

                        // Virtual Try-On Banner (if active)
                        if (p.isTryOnEnabled) ...[
                          _buildTryOnBanner(),
                          const SizedBox(height: 14),
                        ],

                        // Unit of Measure (UOM) Selector Card
                        if (p.uomList.isNotEmpty) ...[
                          _buildUomSelectorCard(p),
                          const SizedBox(height: 14),
                        ],

                        // Variant Options Selector Card (Size, Color, etc.)
                        if (p.optionGroups.isNotEmpty) ...[
                          _buildOptionsSelectorCard(p),
                          const SizedBox(height: 14),
                        ],

                        // Description Card
                        _buildDescriptionCard(productDescription),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: _buildBottomActionBar(context, contentMaxWidth),
      );
    });
  }

  // ==========================================
  // IMAGE PRESENTATION STAGE
  // ==========================================
  Widget _buildImageStage(BuildContext context, ProductModel p) {
    final isTablet = ResponsiveLayout.isTablet(context);

    return Container(
      width: double.infinity,
      height: isTablet ? 300 : 250,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Hero(
                tag:
                    "GroceryItem:${widget.groceryItem.id}-${widget.heroSuffix ?? 'card'}",
                child: AppNetworkImage(
                  image: widget.groceryItem.image,
                  width: double.infinity,
                  height: isTablet ? 250 : 210,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          if (p.isTryOnEnabled)
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome, size: 12, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      'Try-On Ready',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (p.hasDiscount)
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF762D),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.local_offer, size: 12, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      'Special Offer',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ==========================================
  // PRODUCT INFO CARD
  // ==========================================
  Widget _buildProductInfoCard(ProductModel p, String uomSuffix) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badges Row
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (p.sku.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    matchedVariant?.sku.isNotEmpty == true
                        ? matchedVariant!.sku
                        : p.sku,
                    style: const TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF475569),
                    ),
                  ),
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
              for (final promo in p.promotions)
                _badgePill(
                  label: promo.label,
                  color: const Color(0xFFFF762D),
                  icon: Icons.local_offer,
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Title
          Text(
            p.localizedName(context),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
              letterSpacing: -0.3,
            ),
          ),

          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 10),

          // Price & Currency Section
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                formatCurrency(unitPrice),
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFFF762D),
                  letterSpacing: -0.5,
                ),
              ),
              if (uomSuffix.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    uomSuffix,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
              if (p.hasDiscount &&
                  _selectedUom == null &&
                  matchedVariant == null) ...[
                const SizedBox(width: 10),
                Text(
                  formatCurrency(p.price),
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF94A3B8),
                    decoration: TextDecoration.lineThrough,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
          // Dynamic Secondary Currency Conversions (Works for any number of currencies: 1, 2, 3, 4+)
          ...appStateController.foreignCurrencies.map((foreignCurr) {
            final isProductInBase =
                p.currencyCode.isEmpty ||
                p.currencyCode.toUpperCase() ==
                    appStateController.baseCurrencyCode.toUpperCase();

            if (isProductInBase) {
              if (foreignCurr.hasExchangeRate) {
                final converted = unitPrice * foreignCurr.exchangeRate;
                return Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    '≈ ${foreignCurr.format(converted)} (1 ${appStateController.baseCurrencyCode} = ${foreignCurr.format(foreignCurr.exchangeRate).replaceFirst(foreignCurr.symbol, '')} ${foreignCurr.code})',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF94A3B8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              } else {
                return Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 12,
                        color: Color(0xFFD97706),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          AppUiTranslations.text(
                            context,
                            "Today's exchange rate is not configured for ${foreignCurr.code}.",
                          ),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFFD97706),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
            }
            return const SizedBox.shrink();
          }),

          // If product is in a foreign currency, show equivalent in base currency
          if (p.currencyCode.isNotEmpty &&
              p.currencyCode.toUpperCase() !=
                  appStateController.baseCurrencyCode.toUpperCase())
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: appStateController.hasExchangeRateFor(p.currencyCode)
                  ? Text(
                      '≈ ${appStateController.baseCurrency.format(appStateController.convertToBase(unitPrice, p.currencyCode))}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF94A3B8),
                        fontWeight: FontWeight.w500,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.info_outline,
                          size: 12,
                          color: Color(0xFFD97706),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            AppUiTranslations.text(
                              context,
                              "Today's exchange rate is not configured for ${p.currencyCode}.",
                            ),
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFFD97706),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          if (p.stockControl) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: (maxQuantity != null && maxQuantity! > 0)
                    ? const Color(0xFFF0FDF4)
                    : const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: (maxQuantity != null && maxQuantity! > 0)
                      ? const Color(0xFFBBF7D0)
                      : const Color(0xFFFECACA),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    (maxQuantity != null && maxQuantity! > 0)
                        ? Icons.check_circle_outline
                        : Icons.error_outline,
                    size: 14,
                    color: (maxQuantity != null && maxQuantity! > 0)
                        ? const Color(0xFF16A34A)
                        : const Color(0xFFDC2626),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    (maxQuantity != null && maxQuantity! > 0)
                        ? '$maxQuantity available in stock'
                        : 'Out of stock',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: (maxQuantity != null && maxQuantity! > 0)
                          ? const Color(0xFF15803D)
                          : const Color(0xFFB91C1C),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ==========================================
  // VIRTUAL TRY-ON BANNER
  // ==========================================
  Widget _buildTryOnBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDD6FE)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: Color(0xFF7C3AED),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Virtual Try-On Supported',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5B21B6),
                  ),
                ),
                Text(
                  'This item is flagged for customer garment virtual preview',
                  style: TextStyle(fontSize: 11, color: Color(0xFF7C3AED)),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'Active',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // UOM SELECTOR CARD
  // ==========================================
  Widget _buildUomSelectorCard(ProductModel p) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.balance_rounded, size: 18, color: Color(0xFFFF762D)),
              SizedBox(width: 8),
              Text(
                'Select Unit of Measure (UOM)',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...p.uomList.map((uom) {
            final isSelected = _selectedUom?.id == uom.id;
            final factor = uom.conversionFactorToBase.toInt();
            final safeFactor = factor > 0 ? factor : 1;
            final baseInCart = appStateController.cartQuantities[p.id] ?? 0;
            final remainingBase = math.max(0, p.stock - baseInCart);
            final uomStock = remainingBase ~/ safeFactor;
            final isUomOutOfStock = p.stockControl && uomStock <= 0;
            final factorText = factor > 1 ? '$factor units' : 'Base unit';
            final stockText = p.stockControl
                ? ' • ${uomStock > 0 ? "$uomStock available" : "Out of stock"}'
                : '';

            return GestureDetector(
              onTap: isUomOutOfStock
                  ? null
                  : () {
                      setState(() {
                        _selectedUom = uom;
                        final maxQ = maxQuantity;
                        if (maxQ != null && maxQ > 0 && amount > maxQ) {
                          amount = maxQ;
                        } else if (maxQ != null && maxQ <= 0) {
                          amount = 1;
                        }
                      });
                    },
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isUomOutOfStock
                      ? const Color(0xFFF8FAFC)
                      : isSelected
                      ? const Color(0xFFFFF7ED)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isUomOutOfStock
                        ? const Color(0xFFE2E8F0)
                        : isSelected
                        ? const Color(0xFFFF762D)
                        : const Color(0xFFE2E8F0),
                    width: isSelected ? 1.8 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isUomOutOfStock
                            ? const Color(0xFFE2E8F0)
                            : isSelected
                            ? const Color(0xFFFF762D)
                            : const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        (uom.symbol.isNotEmpty ? uom.symbol : uom.code)
                            .toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isUomOutOfStock
                              ? const Color(0xFF94A3B8)
                              : isSelected
                              ? Colors.white
                              : const Color(0xFF475569),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            uom.localizedName(context),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isUomOutOfStock
                                  ? const Color(0xFF94A3B8)
                                  : isSelected
                                  ? const Color(0xFFEA580C)
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            '$factorText$stockText',
                            style: TextStyle(
                              fontSize: 11,
                              color: isUomOutOfStock
                                  ? const Color(0xFFEF4444)
                                  : const Color(0xFF94A3B8),
                              fontWeight: isUomOutOfStock
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      formatCurrency(uom.price),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? const Color(0xFFFF762D)
                            : const Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      isSelected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      color: isSelected
                          ? const Color(0xFFFF762D)
                          : const Color(0xFFCBD5E1),
                      size: 20,
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ==========================================
  // OPTIONS SELECTOR CARD
  // ==========================================
  Widget _buildOptionsSelectorCard(ProductModel p) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...p.optionGroups.asMap().entries.map((entry) {
            final groupIndex = entry.key;
            final group = entry.value;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group.localizedName(context),
                  style: const TextStyle(
                    fontSize: 14,
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
                const SizedBox(height: 8),
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
                          : () => _selectOption(group, val, groupIndex),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFFFF7ED)
                              : isDisabled
                              ? const Color(0xFFF8FAFC)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFFFF762D)
                                : const Color(0xFFE2E8F0),
                            width: isSelected ? 1.8 : 1,
                          ),
                        ),
                        child: Text(
                          _optionLabel(context, val),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: isSelected
                                ? const Color(0xFFEA580C)
                                : isDisabled
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
              ],
            );
          }),
        ],
      ),
    );
  }

  // ==========================================
  // DESCRIPTION CARD
  // ==========================================
  Widget _buildDescriptionCard(String productDescription) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Product Description',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            productDescription,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // FLOATING BOTTOM ACTION BAR
  // ==========================================
  Widget _buildBottomActionBar(BuildContext context, double contentMaxWidth) {
    final maxQ = maxQuantity;
    final isStockControlled = p.stockControl;
    final isOutOfStock = isStockControlled && maxQ != null && maxQ <= 0;
    final isQuantityExceeded =
        isStockControlled && maxQ != null && amount > maxQ;
    final hasValidVariant =
        p.variants.isEmpty ||
        (matchedVariant != null &&
            (!isStockControlled || matchedVariant!.stock > 0));
    final isAddToCartDisabled =
        !_hasValidOptionSelections ||
        !hasValidVariant ||
        isOutOfStock ||
        isQuantityExceeded;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.topCenter,
          heightFactor: 1.0,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: contentMaxWidth),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Amount Stepper with live stock indicator
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isStockControlled && maxQ != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4, left: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: maxQ > 0
                                    ? const Color(0xFF16A34A)
                                    : const Color(0xFFDC2626),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              maxQ > 0 ? '$maxQ available' : 'Out of stock',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: maxQ > 0
                                    ? const Color(0xFF64748B)
                                    : const Color(0xFFEF4444),
                              ),
                            ),
                          ],
                        ),
                      ),
                    Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove, size: 18),
                            color: amount > 1
                                ? const Color(0xFF475569)
                                : const Color(0xFFCBD5E1),
                            onPressed: amount > 1
                                ? () {
                                    setState(() => amount--);
                                  }
                                : null,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              '$amount',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add, size: 18),
                            color: (maxQ == null || amount < maxQ)
                                ? const Color(0xFFFF762D)
                                : const Color(0xFFCBD5E1),
                            onPressed: (maxQ == null || amount < maxQ)
                                ? () {
                                    setState(() => amount++);
                                  }
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),

                // Add To Basket Button
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF762D),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        disabledBackgroundColor: const Color(0xFFCBD5E1),
                        disabledForegroundColor: Colors.white70,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: isAddToCartDisabled
                          ? null
                          : () {
                              final variant = matchedVariant;
                              final configuredProduct = p.copyWith(
                                price: unitPrice,
                                defaultUOMName:
                                    _selectedUom?.name ?? p.defaultUOMName,
                                defaultUOMCode:
                                    _selectedUom?.symbol.isNotEmpty == true
                                    ? _selectedUom!.symbol
                                    : _selectedUom?.code ?? p.defaultUOMCode,
                              );

                              final optionLabels = _allSelectedOptions
                                  .map((value) => _optionLabel(context, value))
                                  .where((s) => s.isNotEmpty)
                                  .toList();

                              appStateController.addToCart(
                                configuredProduct,
                                quantity: amount,
                                variantId: variant?.id,
                                uomId: _selectedUom?.id,
                                uomName: _selectedUom?.name,
                                optionValueIds: _allSelectedOptions
                                    .map((v) => v.id)
                                    .toList(growable: false),
                                optionLabels: optionLabels,
                              );

                              final configuration = [
                                ...optionLabels,
                                if (_selectedUom != null)
                                  _selectedUom!.localizedName(context),
                              ].join(', ');

                              showCartToast(
                                messenger: ScaffoldMessenger.of(context),
                                productName: p.localizedName(context),
                                quantity: amount,
                                configuration: configuration,
                              );
                            },
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!isOutOfStock) ...[
                              const Icon(
                                Icons.shopping_bag_outlined,
                                size: 18,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 8),
                            ],
                            Text(
                              isOutOfStock ? 'Out of Stock' : 'Add',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (!isOutOfStock) ...[
                              const Text(
                                '  •  ',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                formatCurrency(getTotalPrice()),
                                style: const TextStyle(
                                  fontSize: 15,
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
        ),
      ),
    );
  }

  Widget _badgePill({
    required String label,
    required Color color,
    IconData? icon,
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
          if (icon != null) ...[
            Icon(icon, size: 10, color: Colors.white),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
