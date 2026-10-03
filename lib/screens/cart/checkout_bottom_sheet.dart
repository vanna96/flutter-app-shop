import 'package:grocery_app/localization/localized_material.dart';
import 'package:get/get.dart';
import 'package:grocery_app/common_widgets/app_text.dart';
import 'package:grocery_app/controllers/app_state_controller.dart';
import 'package:grocery_app/controllers/login_controller.dart';
import 'package:grocery_app/controllers/navigation_controller.dart';
import 'package:grocery_app/localization/app_ui_translations.dart';
import 'package:grocery_app/screens/order_accepted_screen.dart';

class CheckoutBottomSheet extends StatefulWidget {
  const CheckoutBottomSheet({
    super.key,
    required this.totalCost,
    this.subTotal,
    this.promotionDiscount = 0.0,
    this.promotionName,
    required this.itemCount,
    this.currencySymbol = '',
    this.currencyCode = '',
  });

  final double totalCost;
  final double? subTotal;
  final double promotionDiscount;
  final String? promotionName;
  final int itemCount;
  final String currencySymbol;
  final String currencyCode;

  @override
  _CheckoutBottomSheetState createState() => _CheckoutBottomSheetState();
}

class _CheckoutBottomSheetState extends State<CheckoutBottomSheet> {
  final AppStateController appStateController = Get.find<AppStateController>();

  String _selectedMethod = 'Cash';
  bool _isPlacingOrder = false;
  String? _errorMessage;

  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'id': 'Cash',
      'label': 'Cash',
      'icon': Icons.monetization_on_rounded,
      'iconColor': const Color(0xFF22C55E),
    },
    {
      'id': 'Card',
      'label': 'Card',
      'icon': Icons.credit_card_rounded,
      'iconColor': const Color(0xFFF97316),
    },
    {
      'id': 'QR / UPI',
      'label': 'QR / UPI',
      'icon': Icons.qr_code_2_rounded,
      'iconColor': const Color(0xFF3B82F6),
    },
    {
      'id': 'Bank',
      'label': 'Bank',
      'icon': Icons.account_balance_rounded,
      'iconColor': const Color(0xFFEAB308),
    },
  ];

  String get effectiveCurrencyCode =>
      widget.currencyCode.isNotEmpty
          ? widget.currencyCode
          : appStateController.baseCurrencyCode;

  String get effectiveCurrencySymbol =>
      widget.currencySymbol.isNotEmpty
          ? widget.currencySymbol
          : appStateController.baseCurrencySymbol;

  String _formatPrice(double amount) {
    return appStateController.formatPrice(
      amount,
      currencyCode: effectiveCurrencyCode,
      currencySymbol: effectiveCurrencySymbol,
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasPromotion =
        widget.promotionDiscount > 0 ||
        (widget.promotionName != null && widget.promotionName!.isNotEmpty);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: [
                const AppText(
                  text: "Checkout",
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.close,
                    size: 22,
                    color: Color(0xFF64748B),
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 18),
            getDivider(),
            checkoutRow("Delivery", trailingText: "Home Delivery"),
            getDivider(),

            // Payment Section Title
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  const AppText(
                    text: "Payment Method",
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _selectedMethod,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4F46E5),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Next.js POS Parity Payment Quick Methods Grid (Pic 2)
            _buildPaymentGrid(),
            const SizedBox(height: 10),
            getDivider(),

            checkoutRow("Items", trailingText: '${widget.itemCount}'),
            if (widget.subTotal != null && hasPromotion) ...[
              getDivider(),
              checkoutRow(
                "Subtotal",
                trailingText: _formatPrice(widget.subTotal!),
              ),
            ],
            if (hasPromotion) ...[
              getDivider(),
              checkoutRow(
                widget.promotionName != null && widget.promotionName!.isNotEmpty
                    ? widget.promotionName!
                    : "Promotion",
                trailingText: "− ${_formatPrice(widget.promotionDiscount)}",
                trailingTextColor: const Color(0xFF2E7D32),
                leadingIcon: Icons.confirmation_number_outlined,
              ),
            ],
            getDivider(),

            // Total Cost Row with dual-currency display if applicable
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  const AppText(
                    text: "Total Cost",
                    fontSize: 17,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      AppText(
                        text: _formatPrice(widget.totalCost),
                        fontSize: 18,
                        color: const Color(0xFF0F172A),
                        fontWeight: FontWeight.w900,
                      ),
                      if (appStateController.foreignCurrencies.isNotEmpty) ...[
                        ...appStateController.foreignCurrencies
                            .where((c) => c.hasExchangeRate)
                            .map((c) => Text(
                                  '≈ ${c.format(widget.totalCost * c.exchangeRate)}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF94A3B8),
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.w500,
                                  ),
                                )),
                        ...appStateController.unconfiguredCartCurrencies.map((code) => Text(
                              AppUiTranslations.text(
                                context,
                                "Today's exchange rate is not configured for $code.",
                              ),
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFFD97706),
                                fontWeight: FontWeight.w500,
                              ),
                            )),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            getDivider(),
            const SizedBox(height: 16),
            termsAndConditionsAgreement(context),
            const SizedBox(height: 16),

            // In-Sheet Validation Error Banner
            if (_errorMessage != null && _errorMessage!.isNotEmpty) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 18,
                      color: Color(0xFFDC2626),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Unable to Place Order',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF991B1B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _errorMessage!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFFB91C1C),
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        setState(() {
                          _errorMessage = null;
                        });
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(2),
                        child: Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: Color(0xFF991B1B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Next.js btn-charge Parity Primary Button (Pay [Method] • $Total)
            InkWell(
              onTap: _isPlacingOrder ? null : onPlaceOrderClicked,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _isPlacingOrder
                        ? [const Color(0xFFFFB285), const Color(0xFFFF8E42)]
                        : [const Color(0xFFFF762D), const Color(0xFFFF8E42)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33FF762D),
                      blurRadius: 14,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_isPlacingOrder) ...[
                      const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        "Saving Order...",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ] else ...[
                      Text(
                        "Pay $_selectedMethod",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _formatPrice(widget.totalCost),
                        style: const TextStyle(
                          color: Color(0xFFFF762D),
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  // Next.js POS Parity: 3 columns grid for payment methods
  Widget _buildPaymentGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildPaymentPill(_paymentMethods[0])),
            const SizedBox(width: 8),
            Expanded(child: _buildPaymentPill(_paymentMethods[1])),
            const SizedBox(width: 8),
            Expanded(child: _buildPaymentPill(_paymentMethods[2])),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildPaymentPill(_paymentMethods[3])),
            const SizedBox(width: 8),
            const Expanded(child: SizedBox()),
            const SizedBox(width: 8),
            const Expanded(child: SizedBox()),
          ],
        ),
      ],
    );
  }

  Widget _buildPaymentPill(Map<String, dynamic> method) {
    final isSelected = _selectedMethod == method['id'];
    final iconColor = isSelected ? Colors.white : method['iconColor'] as Color;
    final textColor = isSelected ? Colors.white : const Color(0xFF1E293B);

    return InkWell(
      onTap: () {
        setState(() {
          _selectedMethod = method['id'] as String;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4F46E5) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF4F46E5)
                : const Color(0xFFE2E8F0),
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  const BoxShadow(
                    color: Color(0x4D4F46E5),
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                ]
              : [
                  const BoxShadow(
                    color: Color(0x08000000),
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(method['icon'] as IconData, size: 16, color: iconColor),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                method['label'] as String,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget getDivider() {
    return const Divider(thickness: 1, color: Color(0xFFF1F5F9), height: 16);
  }

  Widget termsAndConditionsAgreement(BuildContext context) {
    return Text(
      'By placing an order you agree to our Terms And Conditions',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: const Color(0xFF94A3B8),
        fontSize: 12,
        fontFamily: Theme.of(context).textTheme.bodyLarge?.fontFamily,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget checkoutRow(
    String label, {
    String? trailingText,
    Widget? trailingWidget,
    Color? trailingTextColor,
    IconData? leadingIcon,
    bool isBold = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          if (leadingIcon != null) ...[
            Icon(leadingIcon, size: 16, color: const Color(0xFF2E7D32)),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: AppText(
              text: label,
              fontSize: isBold ? 16 : 14,
              color: isBold ? Colors.black : const Color(0xFF64748B),
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              maxLines: 1,
            ),
          ),
          if (trailingText != null)
            AppText(
              text: trailingText,
              fontSize: isBold ? 16 : 14,
              color:
                  trailingTextColor ??
                  (isBold ? Colors.black : const Color(0xFF1E293B)),
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            ),
          if (trailingWidget != null) trailingWidget,
          const SizedBox(width: 8),
          const Icon(
            Icons.arrow_forward_ios,
            size: 13,
            color: Color(0xFF94A3B8),
          ),
        ],
      ),
    );
  }

  void onPlaceOrderClicked() async {
    if (_isPlacingOrder) return;

    if (Get.isRegistered<LoginController>() &&
        !Get.find<LoginController>().isAuthenticated.value) {
      Navigator.pop(context);
      if (Get.isRegistered<NavigationController>()) {
        Get.find<NavigationController>().currentIndex.value = 4;
      }
      Get.snackbar(
        'Login Required',
        'Please sign in to place and save your order to the database.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (appStateController.unconfiguredCartCurrencies.isNotEmpty) {
      final unconfiguredCodes =
          appStateController.unconfiguredCartCurrencies.join(', ');
      setState(() {
        _errorMessage = AppUiTranslations.text(
          context,
          "Today's exchange rate is not configured for $unconfiguredCodes.",
        );
      });
      return;
    }

    setState(() {
      _isPlacingOrder = true;
      _errorMessage = null;
    });

    try {
      final order = await appStateController.placeOrder(
        paymentMethod: _selectedMethod,
      );
      if (mounted) {
        setState(() {
          _isPlacingOrder = false;
        });
      }
      if (order != null) {
        if (mounted) {
          Navigator.pop(context);
        }
        Get.to(() => const OrderAcceptedScreen());
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isPlacingOrder = false;
          _errorMessage = AppStateController.extractErrorMessage(e);
        });
      }
    }
  }
}
