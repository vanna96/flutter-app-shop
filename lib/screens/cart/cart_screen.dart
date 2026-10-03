import 'package:grocery_app/localization/localized_material.dart';
import 'package:get/get.dart';
import 'package:grocery_app/common_widgets/app_button.dart';
import 'package:grocery_app/common_widgets/app_text.dart';
import 'package:grocery_app/controllers/app_state_controller.dart';
import 'package:grocery_app/controllers/login_controller.dart';
import 'package:grocery_app/controllers/navigation_controller.dart';
import 'package:grocery_app/helpers/responsive_layout.dart';
import 'package:grocery_app/localization/app_ui_translations.dart';
import 'package:grocery_app/localization/catalog_localization.dart';
import 'package:grocery_app/widgets/app_network_image.dart';
import 'package:grocery_app/widgets/option_selector_bottom_sheet.dart';
import 'package:grocery_app/widgets/uom_selector_bottom_sheet.dart';

import 'checkout_bottom_sheet.dart';

class CartScreen extends StatelessWidget {
  CartScreen({super.key});

  final AppStateController appStateController = Get.find<AppStateController>();
  final NavigationController navigationController =
      Get.find<NavigationController>();

  String _formatBasePrice(double amount) {
    return appStateController.baseCurrency.format(amount);
  }

  void _confirmClearCart(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Clear Cart',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Are you sure you want to remove all items from your cart?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              appStateController.clearCart();
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  Widget _buildCurvedHeader(
      BuildContext context, double horizontalPadding, int itemCount) {
    return Container(
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
          padding:
              EdgeInsets.fromLTRB(horizontalPadding, 12, horizontalPadding, 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.shopping_bag_outlined,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'My Cart',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              if (itemCount > 0) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    '$itemCount ${itemCount == 1 ? "item" : "items"}',
                    style: const TextStyle(
                      color: Color(0xFFFF762D),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => _confirmClearCart(context),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.delete_outline,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCartErrorBanner(
      BuildContext context, double horizontalPadding, String message) {
    return Container(
      margin: EdgeInsets.fromLTRB(horizontalPadding, 10, horizontalPadding, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECACA)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEF4444).withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: const BoxDecoration(
              color: Color(0xFFFEE2E2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: Color(0xFFDC2626),
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cart Notice',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF991B1B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFFB91C1C),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () {
              appStateController.cartErrorMessage.value = null;
              appStateController.promotionPricingError.value = null;
            },
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(
                Icons.close_rounded,
                size: 16,
                color: Color(0xFF991B1B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = ResponsiveLayout.horizontalPadding(context);
    final contentMaxWidth = ResponsiveLayout.maxContentWidth(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Obx(() {
        final cartItems = appStateController.cartItems;
        final totalCount = appStateController.cartItemCount;

        if (cartItems.isEmpty) {
          if (appStateController.cartQuantities.isNotEmpty) {
            return Column(
              children: [
                _buildCurvedHeader(context, horizontalPadding, totalCount),
                const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFFFF762D)),
                    ),
                  ),
                ),
              ],
            );
          }
          return Column(
            children: [
              _buildCurvedHeader(context, horizontalPadding, 0),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: contentMaxWidth),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF2EB),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFF762D)
                                      .withValues(alpha: 0.15),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.shopping_bag_outlined,
                              size: 50,
                              color: Color(0xFFFF762D),
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Your Cart is Empty',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Discover fresh groceries, exclusive discounts, and promotional items from our shop.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF64748B),
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 28),
                          SizedBox(
                            width: 220,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF762D),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              icon: const Icon(Icons.storefront_outlined,
                                  size: 20),
                              label: const Text(
                                'Start Shopping',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onPressed: () {
                                navigationController.currentIndex.value =
                                    2; // Shop
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        }

        final appliedPromo = appStateController.appliedPromotion.value;
        final promoDiscount = appStateController.promotionDiscountAmount.value;
        final isPricing = appStateController.isPromotionPricing.value;
        final isChecked = appStateController.isPromotionChecked.value;
        final pricingError = appStateController.promotionPricingError.value;
        final cartError = appStateController.cartErrorMessage.value;

        return Column(
          children: [
            _buildCurvedHeader(context, horizontalPadding, totalCount),
            if (cartError != null && cartError.isNotEmpty)
              _buildCartErrorBanner(context, horizontalPadding, cartError),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: contentMaxWidth),
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          padding: EdgeInsets.fromLTRB(
                            horizontalPadding,
                            14,
                            horizontalPadding,
                            8,
                          ),
                          itemCount: cartItems.length,
                          itemBuilder: (context, index) {
                            return _CartTile(line: cartItems[index]);
                          },
                        ),
                      ),

                      // Next.js PosSummaryCard Parity Container
                      Container(
                        margin: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                          vertical: 6,
                        ),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Subtotal Row
                            Row(
                              children: [
                                const Text(
                                  'Subtotal',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                                const Spacer(),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      _formatBasePrice(
                                          appStateController.subTotal),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'monospace',
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                    if (appStateController
                                        .foreignCurrencies.isNotEmpty)
                                      ...appStateController.foreignCurrencies
                                          .where((c) => c.hasExchangeRate)
                                          .map(
                                            (c) => Text(
                                              '≈ ${c.format(appStateController.subTotal * c.exchangeRate)}',
                                              style: const TextStyle(
                                                fontSize: 10,
                                                color: Color(0xFF94A3B8),
                                                fontFamily: 'monospace',
                                              ),
                                            ),
                                          ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Promotion Status / Alert Banner
                            if (isPricing)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: Row(
                                  children: const [
                                    SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          Color(0xFF64748B),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Checking promotions…',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF64748B),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else if (pricingError != null &&
                                pricingError.isNotEmpty)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF2F2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0xFFFECACA),
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.error_outline_rounded,
                                      size: 16,
                                      color: Color(0xFFDC2626),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        pricingError,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF991B1B),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else if (appliedPromo != null)
                              // Next.js Alert Success Box: Green bg, border, coupon icon, name, summary, - $savings
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F5E9),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0xFFA5D6A7),
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.confirmation_number_outlined,
                                      size: 16,
                                      color: Color(0xFF2E7D32),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            appliedPromo.name,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF1B5E20),
                                            ),
                                          ),
                                          if (appliedPromo.summary.isNotEmpty)
                                            Padding(
                                              padding:
                                                  const EdgeInsets.only(top: 2),
                                              child: Text(
                                                appliedPromo.summary,
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: Color(0xFF2E7D32),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '− ${_formatBasePrice(promoDiscount)}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'monospace',
                                        color: Color(0xFF2E7D32),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else if (isChecked)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.check_circle_outline,
                                      size: 13,
                                      color: Color(0xFF94A3B8),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        appStateController.subTotal < 200
                                            ? 'Add ${_formatBasePrice(200 - appStateController.subTotal)} more to get 15% OFF (SPEND200)'
                                            : 'No automatic promotion applies to this cart.',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF64748B),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            // Promotion discount row
                            if (promoDiscount > 0) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Text(
                                    'Promotion Discount',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF2E7D32),
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '− ${_formatBasePrice(promoDiscount)}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'monospace',
                                      color: Color(0xFF2E7D32),
                                    ),
                                  ),
                                ],
                              ),
                            ],

                            const Divider(height: 18, color: Color(0xFFE2E8F0)),

                            // Grand Total Row
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Grand Total',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                    Text(
                                      '${appStateController.cartItemCount} Items included',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF94A3B8),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      _formatBasePrice(
                                          appStateController.cartTotal),
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w900,
                                        fontFamily: 'monospace',
                                        color: Color(0xFFFF7A00),
                                      ),
                                    ),
                                    ...appStateController.foreignCurrencies.map((foreignCurr) {
                                      if (foreignCurr.hasExchangeRate) {
                                        final converted = appStateController.cartTotal * foreignCurr.exchangeRate;
                                        return Text(
                                          '≈ ${foreignCurr.format(converted)} (1 ${appStateController.baseCurrencyCode} = ${foreignCurr.format(foreignCurr.exchangeRate).replaceFirst(foreignCurr.symbol, '')} ${foreignCurr.code})',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: Color(0xFF94A3B8),
                                            fontFamily: 'monospace',
                                            fontWeight: FontWeight.w500,
                                          ),
                                        );
                                      }
                                      return const SizedBox.shrink();
                                    }),
                                    if (appStateController.unconfiguredCartCurrencies.isNotEmpty)
                                      Text(
                                        AppUiTranslations.text(
                                          context,
                                          "Today's exchange rate is not configured for ${appStateController.unconfiguredCartCurrencies.join(', ')}.",
                                        ),
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Color(0xFFD97706),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      getCheckoutButton(context),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget getCheckoutButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: AppButton(
          label: "Proceed to Checkout",
          fontWeight: FontWeight.bold,
          height: 56,
          onPressed: () {
            if (Get.isRegistered<LoginController>() &&
                !Get.find<LoginController>().isAuthenticated.value) {
              navigationController.currentIndex.value = 4;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please sign in to continue to checkout.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
              return;
            }
            if (appStateController.unconfiguredCartCurrencies.isNotEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    AppUiTranslations.text(
                      context,
                      "Today's exchange rate is not configured for ${appStateController.unconfiguredCartCurrencies.join(', ')}.",
                    ),
                  ),
                  backgroundColor: const Color(0xFFD97706),
                  behavior: SnackBarBehavior.floating,
                ),
              );
              return;
            }
            showBottomSheet(context);
          },
        ),
      ),
    );
  }

  void showBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext bc) {
        return CheckoutBottomSheet(
          totalCost: appStateController.cartTotal,
          subTotal: appStateController.subTotal,
          promotionDiscount: appStateController.promotionDiscountAmount.value,
          promotionName: appStateController.appliedPromotion.value?.name,
          itemCount: appStateController.cartItemCount,
          currencySymbol: appStateController.baseCurrencySymbol,
          currencyCode: appStateController.baseCurrencyCode,
        );
      },
    );
  }
}

class _CartTile extends StatelessWidget {
  _CartTile({required this.line});

  final CartLine line;
  final AppStateController appStateController = Get.find<AppStateController>();

  String _formatPrice(double amount) {
    return appStateController.formatPrice(
      amount,
      currencyCode: line.product.currencyCode,
      currencySymbol: line.product.currencySymbol,
    );
  }

  bool _canConfigure(CartLine line) {
    return line.product.hasVariants ||
        line.product.optionGroups.isNotEmpty ||
        line.product.variants.isNotEmpty ||
        line.product.hasUOM ||
        line.product.uomList.isNotEmpty;
  }

  bool _shouldShowUomBadge(CartLine line) {
    if (line.selectedUomName == null || line.selectedUomName!.trim().isEmpty) {
      return false;
    }
    final lower = line.selectedUomName!.trim().toLowerCase();
    if (lower == 'unit' || lower == 'each' || lower == 'ea') {
      return false;
    }
    return true;
  }

  bool _shouldShowBadgesRow(CartLine line, bool hasDiscount) {
    return _shouldShowUomBadge(line) ||
        line.isReward ||
        hasDiscount ||
        line.selectedOptionLabels.isNotEmpty;
  }

  String _unitSuffix(CartLine line) {
    if (line.selectedUomName != null &&
        line.selectedUomName!.trim().isNotEmpty) {
      return line.selectedUomName!.trim();
    }
    return 'unit';
  }

  void _openItemConfig(BuildContext context, CartLine line) {
    if (line.product.hasVariants ||
        line.product.optionGroups.isNotEmpty ||
        line.product.variants.isNotEmpty) {
      OptionSelectorBottomSheet.show(
        context,
        line.product,
        initialOptionValueIds: line.selectedOptionValueIds,
        initialQuantity: line.quantity,
        isEditingCart: true,
      );
    } else if (line.product.hasUOM || line.product.uomList.isNotEmpty) {
      UomSelectorBottomSheet.show(
        context,
        line.product,
        initialUomId: line.selectedUomId,
        initialQuantity: line.quantity,
        isEditingCart: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final heroSuffix =
        'cart-${line.product.id}-${line.isReward ? "reward" : "item"}';
    final hasDiscount = line.discountAmount > 0;
    final maxStock = appStateController.getMaxStock(
      line.product,
      variantId: line.selectedVariantId,
      uomId: line.selectedUomId,
    );
    final isAtMaxStock = maxStock != null && line.quantity >= maxStock;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 76,
            height: 76,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Hero(
              tag: 'GroceryItem:${line.product.name}-$heroSuffix',
              child: AppNetworkImage(
                image: line.product.image,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (line.product.sku.isNotEmpty)
                  Text(
                    line.product.sku,
                    style: const TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                AppText(
                  text: line.product.localizedName(context),
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  maxLines: 2,
                ),

                // Badges Row (Next.js Parity: UOM + Free reward + Promo price + Options/Variants)
                if (_shouldShowBadgesRow(line, hasDiscount))
                  Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 4),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        // UOM Badge (Next.js info-subtle: light blue background & border)
                        if (_shouldShowUomBadge(line))
                          InkWell(
                            onTap: !line.isReward && _canConfigure(line)
                                ? () => _openItemConfig(context, line)
                                : null,
                            borderRadius: BorderRadius.circular(4),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0F9FF),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: const Color(0xFFBAE6FD),
                                ),
                              ),
                              child: Text(
                                line.selectedUomName!,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0284C7),
                                ),
                              ),
                            ),
                          ),

                        // Free Reward Badge
                        if (line.isReward)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: const Color(0xFFA5D6A7),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(
                                  Icons.card_giftcard,
                                  size: 11,
                                  color: Color(0xFF2E7D32),
                                ),
                                SizedBox(width: 3),
                                Text(
                                  'Free reward',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2E7D32),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else if (hasDiscount)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF3E0),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: const Color(0xFFFFB74D),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(
                                  Icons.local_offer,
                                  size: 10,
                                  color: Color(0xFFE65100),
                                ),
                                SizedBox(width: 3),
                                Text(
                                  'Promo price',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFE65100),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Selected Option / Variant Pills (Matches Next.js Pic 2)
                        for (final label in line.selectedOptionLabels)
                          InkWell(
                            onTap: !line.isReward && _canConfigure(line)
                                ? () => _openItemConfig(context, line)
                                : null,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFCBD5E1),
                                ),
                              ),
                              child: Text(
                                label,
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                // Price display (with unit suffix and edit pencil icon)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      if (line.isReward) ...[
                        Text(
                          '${_formatPrice(line.product.price)}/${_unitSuffix(line)}',
                          style: const TextStyle(
                            fontSize: 11,
                            decoration: TextDecoration.lineThrough,
                            color: Colors.red,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'FREE',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                      ] else if (hasDiscount) ...[
                        Text(
                          _formatPrice(line.product.price),
                          style: const TextStyle(
                            fontSize: 11,
                            decoration: TextDecoration.lineThrough,
                            color: Color(0xFF94A3B8),
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${_formatPrice(line.unitPrice)}/${_unitSuffix(line)}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFE65100),
                            fontFamily: 'monospace',
                          ),
                        ),
                      ] else ...[
                        Text(
                          '${_formatPrice(line.product.price)}/${_unitSuffix(line)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      if (!line.isReward && _canConfigure(line)) ...[
                        const SizedBox(width: 4),
                        InkWell(
                          onTap: () => _openItemConfig(context, line),
                          borderRadius: BorderRadius.circular(4),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 2.0,
                              vertical: 1.0,
                            ),
                            child: Icon(
                              Icons.edit_outlined,
                              size: 13,
                              color: Color(0xFF7C3AED),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Stepper
                Row(
                  children: [
                    _QuantityButton(
                      icon: Icons.remove,
                      disabled: line.isReward,
                      onTap: line.isReward
                          ? () {}
                          : () => appStateController.updateCartQuantity(
                                line.product,
                                line.quantity - 1,
                              ),
                    ),
                    const SizedBox(width: 12),
                    AppText(
                      text: '${line.quantity}',
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                    const SizedBox(width: 12),
                    _QuantityButton(
                      icon: Icons.add,
                      disabled: line.isReward || isAtMaxStock,
                      onTap: (line.isReward || isAtMaxStock)
                          ? () {}
                          : () => appStateController.updateCartQuantity(
                                line.product,
                                line.quantity + 1,
                              ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Right Column: Remove action and Line total
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (line.isReward)
                const SizedBox(height: 38)
              else
                InkWell(
                  onTap: () =>
                      appStateController.removeFromCart(line.product.id),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Color(0xFF64748B),
                      size: 14,
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              if (line.isReward)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatPrice(line.product.price * line.quantity),
                      style: const TextStyle(
                        fontSize: 11,
                        decoration: TextDecoration.lineThrough,
                        color: Colors.red,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Text(
                      r'$0.00',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  ],
                )
              else if (hasDiscount)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatPrice(line.originalTotalPrice),
                      style: const TextStyle(
                        fontSize: 11,
                        decoration: TextDecoration.lineThrough,
                        color: Color(0xFF94A3B8),
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      _formatPrice(line.totalPrice),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    if (line.product.currencyCode.isNotEmpty &&
                        line.product.currencyCode.toUpperCase() !=
                            appStateController.baseCurrencyCode.toUpperCase()) ...[
                      if (appStateController.hasExchangeRateFor(line.product.currencyCode))
                        Text(
                          '≈ ${appStateController.baseCurrency.format(appStateController.convertToBase(line.totalPrice, line.product.currencyCode))}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF94A3B8),
                            fontFamily: 'monospace',
                          ),
                        )
                      else
                        Text(
                          AppUiTranslations.text(
                            context,
                            "Rate for ${line.product.currencyCode} not set",
                          ),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFFD97706),
                            fontFamily: 'monospace',
                          ),
                        ),
                    ] else ...[
                      ...appStateController.foreignCurrencies
                          .where((c) => c.hasExchangeRate)
                          .map((foreignCurr) => Text(
                                '≈ ${foreignCurr.format(line.totalPrice * foreignCurr.exchangeRate)}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF94A3B8),
                                  fontFamily: 'monospace',
                                ),
                              )),
                    ],
                  ],
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatPrice(line.totalPrice),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    if (line.product.currencyCode.isNotEmpty &&
                        line.product.currencyCode.toUpperCase() !=
                            appStateController.baseCurrencyCode.toUpperCase()) ...[
                      if (appStateController.hasExchangeRateFor(line.product.currencyCode))
                        Text(
                          '≈ ${appStateController.baseCurrency.format(appStateController.convertToBase(line.totalPrice, line.product.currencyCode))}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF94A3B8),
                            fontFamily: 'monospace',
                          ),
                        )
                      else
                        Text(
                          AppUiTranslations.text(
                            context,
                            "Rate for ${line.product.currencyCode} not set",
                          ),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFFD97706),
                            fontFamily: 'monospace',
                          ),
                        ),
                    ] else ...[
                      ...appStateController.foreignCurrencies
                          .where((c) => c.hasExchangeRate)
                          .map((foreignCurr) => Text(
                                '≈ ${foreignCurr.format(line.totalPrice * foreignCurr.exchangeRate)}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF94A3B8),
                                  fontFamily: 'monospace',
                                ),
                              )),
                    ],
                  ],
                ),
            ],
          )
        ],
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  const _QuantityButton({
    required this.icon,
    required this.onTap,
    this.disabled = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: disabled ? null : onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: disabled ? const Color(0xFFE2E8F0) : const Color(0xFFCBD5E1),
          ),
          color: disabled ? const Color(0xFFF1F5F9) : Colors.white,
        ),
        child: Icon(
          icon,
          size: 16,
          color: disabled ? const Color(0xFF94A3B8) : const Color(0xFF334155),
        ),
      ),
    );
  }
}
