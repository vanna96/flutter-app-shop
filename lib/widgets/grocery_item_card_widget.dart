import 'package:grocery_app/localization/localized_material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:grocery_app/controllers/app_state_controller.dart';
import 'package:grocery_app/controllers/login_controller.dart';
import 'package:grocery_app/localization/catalog_localization.dart';
import 'package:grocery_app/models/product_model.dart';
import 'package:grocery_app/screens/product_details/product_details_screen.dart';
import 'package:grocery_app/styles/colors.dart';
import 'package:grocery_app/widgets/app_network_image.dart';
import 'package:grocery_app/widgets/cart_toast.dart';
import 'package:grocery_app/data/mock_data.dart';
import 'package:grocery_app/widgets/uom_selector_bottom_sheet.dart';
import 'package:grocery_app/widgets/option_selector_bottom_sheet.dart';

class GroceryItemCardWidget extends StatelessWidget {
  GroceryItemCardWidget(
      {super.key, required ProductModel item, this.heroSuffix})
      : _initialItem = item;

  final ProductModel _initialItem;
  final String? heroSuffix;

  final AppStateController appStateController = Get.find<AppStateController>();
  final LoginController loginController = Get.find<LoginController>();

  ProductModel get item {
    final _ = appStateController.stockUpdateTrigger.value;
    return MockDataRepository.getProductById(_initialItem.id) ?? _initialItem;
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final _ = item;
      return LayoutBuilder(
        builder: (context, constraints) {
          const cardPadding = 8.0;
          const imageHeight = 125.0;

          final hasBoundedHeight = constraints.hasBoundedHeight;

          return GestureDetector(
            onTap: () => _openDetails(context),
            behavior: HitTestBehavior.opaque,
            child: Container(
              height: hasBoundedHeight ? constraints.maxHeight : null,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(cardPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize:
                      hasBoundedHeight ? MainAxisSize.max : MainAxisSize.min,
                  children: [
                    // 1. Product Thumbnail with Badge Overlays
                    Container(
                      height: imageHeight,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFFE2E8F0),
                          width: 0.8,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Stack(
                          children: [
                            // Centered Product Image or SVG Placeholder
                            Positioned.fill(
                              child: Center(
                                child: Hero(
                                  tag:
                                      "GroceryItem:${item.id}-${heroSuffix ?? 'card'}",
                                  child: AppNetworkImage(
                                    image: item.image,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ),

                            // Top-Left Badges Stack (Matching Next.js POS)
                            Positioned(
                              top: 6,
                              left: 6,
                              child: _buildBadgesColumn(),
                            ),

                            // Top-Right: Favorite Button (Heart icon)
                            Positioned(
                              top: 6,
                              right: 6,
                              child: _buildFavoriteButton(),
                            ),

                            // Bottom Row: Promotions (Left) & In-Cart Rounded Number Badge (Bottom-Right Corner)
                            Positioned(
                              bottom: 6,
                              left: 6,
                              right: 6,
                              child: IgnorePointer(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Expanded(
                                      child: Align(
                                        alignment: Alignment.bottomLeft,
                                        child: _buildBottomPromotions(),
                                      ),
                                    ),
                                    _buildInCartBadge(),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),

                    // 2. SKU (Fixed Height: 16px so cards with or without SKU align identically)
                    SizedBox(
                      height: 16,
                      child: item.sku.isNotEmpty
                          ? Text(
                              item.sku,
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontFamily: 'monospace',
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            )
                          : const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 2),

                    // 3. Product Title (Fixed Height: 36px for 2 lines so 1-line & 2-line titles match perfectly)
                    SizedBox(
                      height: 36,
                      child: Text(
                        item.localizedName(context),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                          height: 1.25,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    // Push Divider & Action Row to stay at the bottom
                    if (hasBoundedHeight)
                      const Spacer()
                    else
                      const SizedBox(height: 6),

                    // 4. Subtle Horizontal Divider
                    Container(
                      margin: const EdgeInsets.only(top: 2, bottom: 6),
                      height: 1,
                      color: const Color(0xFFF1F5F9),
                    ),

                    // 5. Price and Action Button Row (Fixed Height: 34px for identical alignment)
                    SizedBox(
                      height: 34,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: _buildPriceSection(),
                          ),
                          const SizedBox(width: 4),
                          _buildActionButton(context),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    });
  }

  Widget _buildBadgesColumn() {
    final List<Widget> badges = [];

    // Out of Stock / Low Stock
    if (item.isOutOfStock) {
      badges.add(_badgePill(
        label: 'Out of Stock',
        color: const Color(0xFFEF4444),
        icon: Icons.cancel_outlined,
      ));
    } else if (item.isLowStock) {
      badges.add(_badgePill(
        label: 'Low Stock',
        color: const Color(0xFFF59E0B),
        icon: Icons.warning_amber_rounded,
        textColor: Colors.black87,
      ));
    }

    // Try-On Badge (Purple #7C3AED)
    if (item.isTryOnEnabled) {
      badges.add(_badgePill(
        label: 'Try-On',
        color: const Color(0xFF7C3AED),
        icon: Icons.auto_awesome,
      ));
    }

    // Premium Badge (Amber #D97706)
    if (item.isPremium) {
      badges.add(_badgePill(
        label: 'Premium',
        color: const Color(0xFFD97706),
        icon: Icons.workspace_premium,
      ));
    }

    // Featured Badge (Royal Blue #2563EB)
    if (item.isFeatured) {
      badges.add(_badgePill(
        label: 'Featured',
        color: const Color(0xFF2563EB),
        icon: Icons.star,
      ));
    }

    // New Arrival Badge (Emerald #059669)
    if (item.isNewArrival) {
      badges.add(_badgePill(
        label: 'New',
        color: const Color(0xFF059669),
        icon: Icons.auto_awesome,
      ));
    }

    // UOM Badge (Light blue #DBEAFE with border)
    if (item.hasUOM) {
      final uomCode = (item.defaultUOMCode ?? 'ea').toLowerCase();
      badges.add(Container(
        padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
        decoration: BoxDecoration(
          color: const Color(0xFFDBEAFE),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFBAE6FD), width: 0.8),
        ),
        child: Text(
          'UOM: $uomCode',
          style: const TextStyle(
            fontSize: 9.0,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1D4ED8),
            height: 1.1,
          ),
        ),
      ));
    } else if (item.hasVariants) {
      badges.add(Container(
        padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
        decoration: BoxDecoration(
          color: const Color(0xFFEDE9FE),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFDDD6FE), width: 0.8),
        ),
        child: const Text(
          'Options',
          style: TextStyle(
            fontSize: 9.0,
            fontWeight: FontWeight.bold,
            color: Color(0xFF6D28D9),
            height: 1.1,
          ),
        ),
      ));
    }

    if (badges.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < badges.length; i++)
          Padding(
            padding: EdgeInsets.only(
              bottom: i == badges.length - 1 ? 0 : 3.5,
            ),
            child: badges[i],
          ),
      ],
    );
  }

  Widget _badgePill({
    required String label,
    required Color color,
    IconData? icon,
    Color textColor = Colors.white,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 8.5, color: textColor),
            const SizedBox(width: 2.5),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 9.0,
              fontWeight: FontWeight.bold,
              color: textColor,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomPromotions() {
    if (item.promotions.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 3.5,
      runSpacing: 3.0,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final promo in item.promotions) _buildPromotionBadge(promo),
      ],
    );
  }

  Widget _buildPromotionBadge(ProductPromotion promo) {
    final isBogo = promo.type == 'bogo';
    final isItemPrice = promo.type == 'item_price';

    final gradient = isBogo
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
          )
        : isItemPrice
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF97316), Color(0xFFEA580C)],
              )
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF059669), Color(0xFF047857)],
              );

    final icon = isBogo ? Icons.card_giftcard : Icons.local_offer;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.5),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.18),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 9.0, color: Colors.white),
          const SizedBox(width: 3.0),
          Text(
            promo.label,
            style: const TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 0.2,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInCartBadge() {
    return Obx(() {
      final qty = appStateController.quantityFor(item.id);
      if (qty <= 0) return const SizedBox.shrink();

      return Container(
        margin: const EdgeInsets.only(left: 4),
        constraints: const BoxConstraints(
          minWidth: 22,
          minHeight: 22,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 5.5, vertical: 2.0),
        decoration: BoxDecoration(
          color: const Color(0xFF059669),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: Colors.white,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.22),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          '$qty',
          style: const TextStyle(
            fontSize: 11.0,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            height: 1.0,
            letterSpacing: -0.2,
          ),
        ),
      );
    });
  }

  Widget _buildFavoriteButton() {
    return Obx(() {
      if (!loginController.isAuthenticated.value) {
        return const SizedBox.shrink();
      }

      final isFav = appStateController.isFavorite(item.id);

      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => appStateController.toggleFavorite(item),
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.94),
            shape: BoxShape.circle,
            border: Border.all(
              color: isFav ? const Color(0xFFFECDD3) : const Color(0xFFE2E8F0),
              width: 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Center(
            child: Icon(
              isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              size: 15,
              color: isFav ? const Color(0xFFEF4444) : const Color(0xFF94A3B8),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildPriceSection() {
    final symbol = item.currencySymbol;
    final appState = Get.isRegistered<AppStateController>()
        ? Get.find<AppStateController>()
        : null;
    final decimals = appState?.getCurrency(item.currencyCode)?.decimalPlaces ??
        (appState != null &&
                item.currencyCode.isNotEmpty &&
                item.currencyCode.toUpperCase() ==
                    appState.baseCurrencyCode.toUpperCase()
            ? appState.baseCurrency.decimalPlaces
            : 2);
    final formatter = decimals > 0
        ? NumberFormat('#,##0.' + '0' * decimals)
        : NumberFormat('#,##0');

    final displayPriceText = formatter.format(item.displayPrice);
    final originalPriceText = formatter.format(item.price);
    final uomSuffix = (item.hasUOM &&
            item.defaultUOMName != null &&
            item.defaultUOMName!.isNotEmpty)
        ? "/${item.defaultUOMName}"
        : "";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (item.hasDiscount) ...[
          Text(
            "$symbol$originalPriceText",
            style: const TextStyle(
              fontSize: 9.5,
              color: Color(0xFF94A3B8),
              decoration: TextDecoration.lineThrough,
              fontWeight: FontWeight.w600,
              height: 1.0,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 1),
          Text.rich(
            TextSpan(
              text: "$symbol$displayPriceText",
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryColor,
                height: 1.1,
              ),
              children: [
                if (uomSuffix.isNotEmpty)
                  TextSpan(
                    text: uomSuffix,
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.normal,
                    ),
                  ),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ] else ...[
          Text.rich(
            TextSpan(
              text: "$symbol$displayPriceText",
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryColor,
                height: 1.1,
              ),
              children: [
                if (uomSuffix.isNotEmpty)
                  TextSpan(
                    text: uomSuffix,
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.normal,
                    ),
                  ),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  Widget _buildActionButton(BuildContext context) {
    // 1. If product has multiple UOMs -> Outline Pill "Select UOM" (Matching Next.js)
    if (item.hasUOM) {
      return GestureDetector(
        onTap: () => UomSelectorBottomSheet.show(
          context,
          item,
          heroSuffix: heroSuffix,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4.5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primaryColor, width: 1.5),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.balance, size: 12, color: AppColors.primaryColor),
              SizedBox(width: 3),
              Text(
                "UOM",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryColor,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 2. If product has Variants -> Outline Pill "Options" (Matching Next.js)
    if (item.hasVariants) {
      return GestureDetector(
        onTap: () => OptionSelectorBottomSheet.show(
          context,
          item,
          heroSuffix: heroSuffix,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4.5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primaryColor, width: 1.5),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.tune, size: 12, color: AppColors.primaryColor),
              SizedBox(width: 3),
              Text(
                "Options",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryColor,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 3. Out of stock
    if (item.isOutOfStock) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4.5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: const Color(0xFFF1F5F9),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Text(
          'Out of Stock',
          style: TextStyle(
            fontSize: 11,
            color: Color(0xFF94A3B8),
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    // 4. In Cart -> Stepper
    return Obx(() {
      final qty = appStateController.quantityFor(item.id);

      if (qty > 0) {
        final maxStock = appStateController.getMaxStock(item);
        final isMax = maxStock != null && qty >= maxStock;

        return Container(
          height: 30,
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.primaryColor.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () =>
                    appStateController.updateCartQuantity(item, qty - 1),
                child: Container(
                  width: 24,
                  height: 30,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.remove,
                    size: 14,
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Text(
                  '$qty',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
              GestureDetector(
                onTap: isMax
                    ? null
                    : () =>
                        appStateController.updateCartQuantity(item, qty + 1),
                child: Container(
                  width: 24,
                  height: 30,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.add,
                    size: 14,
                    color: isMax
                        ? const Color(0xFFCBD5E1)
                        : AppColors.primaryColor,
                  ),
                ),
              ),
            ],
          ),
        );
      }

      // 5. Default Add button
      final isOutOfStock = item.stockControl && item.stock <= 0;

      return GestureDetector(
        onTap: isOutOfStock
            ? null
            : () {
                appStateController.addToCart(item);
                showCartToast(
                  messenger: ScaffoldMessenger.of(context),
                  productName: item.localizedName(context),
                  quantity: 1,
                );
              },
        child: Container(
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color:
                isOutOfStock ? const Color(0xFFE2E8F0) : AppColors.primaryColor,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isOutOfStock) ...[
                const Icon(Icons.add, color: Colors.white, size: 15),
                const SizedBox(width: 2),
              ],
              Text(
                isOutOfStock ? "Out of Stock" : "Add",
                style: TextStyle(
                  color: isOutOfStock ? const Color(0xFF94A3B8) : Colors.white,
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  void _openDetails(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailsScreen(
          item,
          heroSuffix: heroSuffix,
        ),
      ),
    );
  }
}
