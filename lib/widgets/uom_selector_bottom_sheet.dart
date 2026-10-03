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

class UomSelectorBottomSheet extends StatefulWidget {
  final ProductModel product;
  final String? heroSuffix;
  final int? initialUomId;
  final int? initialQuantity;
  final bool isEditingCart;

  const UomSelectorBottomSheet({
    super.key,
    required this.product,
    this.heroSuffix,
    this.initialUomId,
    this.initialQuantity,
    this.isEditingCart = false,
  });

  static Future<void> show(
    BuildContext context,
    ProductModel product, {
    String? heroSuffix,
    int? initialUomId,
    int? initialQuantity,
    bool isEditingCart = false,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => UomSelectorBottomSheet(
        product: product,
        heroSuffix: heroSuffix,
        initialUomId: initialUomId,
        initialQuantity: initialQuantity,
        isEditingCart: isEditingCart,
      ),
    );
  }

  @override
  State<UomSelectorBottomSheet> createState() => _UomSelectorBottomSheetState();
}

class _UomSelectorBottomSheetState extends State<UomSelectorBottomSheet> {
  ProductUomModel? _selectedUom;
  int _quantity = 1;
  final AppStateController _appStateController = Get.find<AppStateController>();

  @override
  void initState() {
    super.initState();
    final currentProduct = p;
    if (currentProduct.uomList.isNotEmpty) {
      if (widget.initialUomId != null) {
        _selectedUom = currentProduct.uomList.firstWhereOrNull(
          (u) => u.id == widget.initialUomId,
        );
      }
      if (_selectedUom == null) {
        // Prefer base unit if available, or first in-stock unit
        final base = currentProduct.uomList.firstWhereOrNull(
          (u) => u.isBaseUnit,
        );
        if (base != null && !_isUomOutOfStock(base)) {
          _selectedUom = base;
        } else {
          _selectedUom =
              currentProduct.uomList.firstWhereOrNull(
                (u) => !_isUomOutOfStock(u),
              ) ??
              base ??
              currentProduct.uomList.first;
        }
      }
    } else {
      _selectedUom = null;
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

    // Preserve the selectable units from the tapped item when an auth sync
    // has cached a compact product payload without its UOM details.
    return latest.copyWith(
      hasUOM: latest.hasUOM || widget.product.hasUOM,
      defaultUOMName: widget.product.defaultUOMName ?? latest.defaultUOMName,
      defaultUOMCode: widget.product.defaultUOMCode ?? latest.defaultUOMCode,
      uomList: widget.product.uomList.isNotEmpty
          ? widget.product.uomList
          : latest.uomList,
    );
  }

  int? _getUomStock(ProductUomModel uom) {
    final currentProduct = p;
    if (!currentProduct.stockControl) return null;
    final factor = uom.conversionFactorToBase.toInt();
    final safeFactor = factor > 0 ? factor : 1;
    final baseInCart = widget.isEditingCart
        ? 0
        : (_appStateController.cartQuantities[currentProduct.id] ?? 0);
    final remainingBase = math.max(0, currentProduct.stock - baseInCart);
    return remainingBase ~/ safeFactor;
  }

  bool _isUomOutOfStock(ProductUomModel uom) {
    if (!p.stockControl) return false;
    final stock = _getUomStock(uom);
    return stock != null && stock <= 0;
  }

  int? get maxQuantity {
    if (_selectedUom == null) return null;
    return _getUomStock(_selectedUom!);
  }

  double get _currentUnitPrice {
    if (_selectedUom != null) {
      return _selectedUom!.price;
    }
    return p.displayPrice;
  }

  double get _totalPrice => _currentUnitPrice * _quantity;

  String _formatPrice(double amount) {
    if (Get.isRegistered<AppStateController>()) {
      return Get.find<AppStateController>().formatPrice(
        amount,
        currencyCode: p.currencyCode,
        currencySymbol: p.currencySymbol,
      );
    }
    final symbol = p.currencySymbol;
    return '$symbol${NumberFormat('#,##0.00').format(amount)}';
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
            const SizedBox(width: 3.5),
          ],
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.white,
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
      final maxQ = maxQuantity;
      final isStockControlled = currentProduct.stockControl;
      final isOutOfStock = isStockControlled && maxQ != null && maxQ <= 0;
      final isQuantityExceeded =
          isStockControlled && maxQ != null && _quantity > maxQ;
      final isAddToCartDisabled = isOutOfStock || isQuantityExceeded;

      return Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
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
              // Top Drag Handle
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

              // Header: Icon + Title + SKU + Close Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEEF2FF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.balance,
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
                    mainAxisSize: MainAxisSize.min,
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
                                  // Badges Row
                                  if (p.isTryOnEnabled ||
                                      p.isPremium ||
                                      p.isFeatured ||
                                      p.isNewArrival ||
                                      p.promotions.isNotEmpty)
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
                                          for (final promo in p.promotions)
                                            _badgePill(
                                              label: promo.label,
                                              color: promo.type == 'bogo'
                                                  ? const Color(0xFF7C3AED)
                                                  : const Color(0xFF059669),
                                              icon: promo.type == 'bogo'
                                                  ? Icons.card_giftcard
                                                  : Icons.local_offer,
                                            ),
                                        ],
                                      ),
                                    ),
                                  Text(
                                    _selectedUom != null
                                        ? 'Unit: ${_selectedUom!.name}'
                                        : 'Base Price: ${_formatPrice(p.price)}',
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _formatPrice(_currentUnitPrice),
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

                      // Virtual Try-On Banner
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

                      // UOM Selector Section (Matching Next.js ModalConfigProduct)
                      if (p.uomList.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.only(top: 4, bottom: 8),
                          child: Text(
                            'Select Unit of Measure (UOM):',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        Column(
                          children: p.uomList.map((uom) {
                            final isSelected = _selectedUom?.id == uom.id;
                            final uomStock = _getUomStock(uom);
                            final isUomOutOfStock = _isUomOutOfStock(uom);

                            return GestureDetector(
                              onTap: isUomOutOfStock
                                  ? null
                                  : () {
                                      setState(() {
                                        _selectedUom = uom;
                                        final maxQ = maxQuantity;
                                        if (maxQ != null &&
                                            maxQ > 0 &&
                                            _quantity > maxQ) {
                                          _quantity = maxQ;
                                        } else if (maxQ != null && maxQ <= 0) {
                                          _quantity = 1;
                                        }
                                      });
                                    },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primaryColor
                                      : isUomOutOfStock
                                      ? const Color(0xFFF8FAFC)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.primaryColor
                                        : const Color(0xFFE2E8F0),
                                    width: isSelected ? 1.5 : 1.0,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    // Short Code Badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? Colors.white
                                            : const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        (uom.symbol.isNotEmpty
                                                ? uom.symbol
                                                : uom.code)
                                            .toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: isSelected
                                              ? AppColors.primaryColor
                                              : const Color(0xFF475569),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),

                                    // Name and Stock Badge
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Text(
                                            uom.localizedName(context),
                                            style: TextStyle(
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w600,
                                              color: isSelected
                                                  ? Colors.white
                                                  : isUomOutOfStock
                                                  ? const Color(0xFF94A3B8)
                                                  : const Color(0xFF0F172A),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          if (isStockControlled &&
                                              uomStock != null)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: isUomOutOfStock
                                                    ? const Color(0xFFFEE2E2)
                                                    : isSelected
                                                    ? Colors.white.withValues(
                                                        alpha: 0.25,
                                                      )
                                                    : const Color(0xFFF1F5F9),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                isUomOutOfStock
                                                    ? 'Out of stock'
                                                    : '$uomStock available',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600,
                                                  color: isUomOutOfStock
                                                      ? const Color(0xFFDC2626)
                                                      : isSelected
                                                      ? Colors.white
                                                      : const Color(0xFF64748B),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),

                                    // Price
                                    Text(
                                      _formatPrice(uom.price),
                                      style: TextStyle(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'monospace',
                                        color: isSelected
                                            ? Colors.white
                                            : AppColors.primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],

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
                                  final targetProduct = _selectedUom != null
                                      ? p.copyWith(
                                          price: _selectedUom!.price,
                                          defaultUOMName: _selectedUom!.name,
                                          defaultUOMCode:
                                              _selectedUom!.symbol.isNotEmpty
                                              ? _selectedUom!.symbol
                                              : _selectedUom!.code,
                                        )
                                      : p;

                                  _appStateController.addToCart(
                                    targetProduct,
                                    quantity: _quantity,
                                    uomId: _selectedUom?.id,
                                    uomName: _selectedUom?.name,
                                    replaceQuantity: widget.isEditingCart,
                                  );

                                  final messenger = ScaffoldMessenger.of(
                                    context,
                                  );
                                  Navigator.pop(context);

                                  showCartToast(
                                    messenger: messenger,
                                    productName: p.localizedName(context),
                                    quantity: _quantity,
                                    configuration:
                                        _selectedUom?.localizedName(context) ??
                                        '',
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
                                    _formatPrice(_totalPrice),
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
