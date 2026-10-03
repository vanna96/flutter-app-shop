import 'package:grocery_app/localization/localized_material.dart';
import 'package:grocery_app/localization/app_ui_translations.dart';
import 'package:get/get.dart';
import 'package:grocery_app/controllers/network_status_controller.dart';
import 'package:grocery_app/styles/colors.dart';

class NetworkStatusBanner extends StatefulWidget {
  const NetworkStatusBanner({super.key});

  @override
  State<NetworkStatusBanner> createState() => _NetworkStatusBannerState();
}

class _NetworkStatusBannerState extends State<NetworkStatusBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<NetworkStatusController>()) {
      return const SizedBox.shrink();
    }
    final controller = Get.find<NetworkStatusController>();

    return Obx(() {
      final isOffline =
          controller.isUnavailable.value && !controller.isDismissed.value;
      final isBackOnline = controller.showBackOnline.value;

      final isVisible = isOffline || isBackOnline;
      final isKhmer = Localizations.localeOf(context).languageCode == 'km';

      return AnimatedSlide(
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOutCubic,
        offset: isVisible ? const Offset(0, 0) : const Offset(0, -1.2),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 280),
          opacity: isVisible ? 1.0 : 0.0,
          child: isVisible
              ? SafeArea(
                  minimum: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: isBackOnline
                        ? _buildBackOnlineToast(isKhmer)
                        : Material(
                            color: Colors.transparent,
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 520),
                              padding: EdgeInsets.symmetric(
                                horizontal: isKhmer ? 10 : 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isBackOnline
                                      ? const [
                                          Color(0xFF047857),
                                          Color(0xFF059669),
                                          Color(0xFF10B981),
                                        ]
                                      : const [
                                          Color(0xFF1E293B),
                                          Color(0xFF0F172A),
                                        ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isBackOnline
                                      ? const Color(
                                          0xFF34D399,
                                        ).withValues(alpha: 0.6)
                                      : const Color(
                                          0xFFEF4444,
                                        ).withValues(alpha: 0.4),
                                  width: 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: isBackOnline
                                        ? const Color(
                                            0xFF10B981,
                                          ).withValues(alpha: 0.28)
                                        : const Color(
                                            0xFF000000,
                                          ).withValues(alpha: 0.35),
                                    blurRadius: 18,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  // Animated Icon Badge
                                  ScaleTransition(
                                    scale: isBackOnline
                                        ? const AlwaysStoppedAnimation(1.0)
                                        : _pulseAnimation,
                                    child: Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: isBackOnline
                                            ? Colors.white.withValues(
                                                alpha: 0.2,
                                              )
                                            : const Color(
                                                0xFFDC2626,
                                              ).withValues(alpha: 0.25),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isBackOnline
                                              ? Colors.white.withValues(
                                                  alpha: 0.4,
                                                )
                                              : const Color(
                                                  0xFFF87171,
                                                ).withValues(alpha: 0.5),
                                        ),
                                      ),
                                      child: Icon(
                                        isBackOnline
                                            ? Icons.wifi_rounded
                                            : Icons.wifi_off_rounded,
                                        color: isBackOnline
                                            ? Colors.white
                                            : const Color(0xFFFCA5A5),
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // Texts
                                  Expanded(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                isBackOnline
                                                    ? (isKhmer
                                                          ? 'ភ្ជាប់អ៊ីនធឺណិតវិញហើយ!'
                                                          : 'Back Online!')
                                                    : (isKhmer
                                                          ? 'គ្មានការតភ្ជាប់អ៊ីនធឺណិត'
                                                          : "You're Offline"),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 13.5,
                                                  fontWeight: FontWeight.w700,
                                                  letterSpacing: 0.2,
                                                ),
                                              ),
                                            ),
                                            if (!isBackOnline && !isKhmer) ...[
                                              const SizedBox(width: 6),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 1.5,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                    0xFFEF4444,
                                                  ).withValues(alpha: 0.2),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  isKhmer
                                                      ? 'ក្រៅបណ្តាញ'
                                                      : 'Offline',
                                                  style: const TextStyle(
                                                    color: Color(0xFFFCA5A5),
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          isBackOnline
                                              ? (isKhmer
                                                    ? 'បានភ្ជាប់ទៅកាន់ប្រព័ន្ធជោគជ័យ'
                                                    : 'Connected to server')
                                              : (isKhmer
                                                    ? 'សូមពិនិត្យ Wi-Fi ឬទិន្នន័យទូរសព្ទ'
                                                    : 'Check Wi-Fi or mobile network'),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: Colors.white.withValues(
                                              alpha: 0.78,
                                            ),
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(width: 8),

                                  // Action: Retry Button (if offline)
                                  if (!isBackOnline) ...[
                                    InkWell(
                                      onTap: controller.isRetrying.value
                                          ? null
                                          : () => controller.retry(),
                                      borderRadius: BorderRadius.circular(10),
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: isKhmer ? 9 : 12,
                                          vertical: 6.5,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              AppColors.primaryColor,
                                              AppColors.primaryHover,
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppColors.primaryColor
                                                  .withValues(alpha: 0.35),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: controller.isRetrying.value
                                            ? const SizedBox(
                                                width: 14,
                                                height: 14,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: Colors.white,
                                                    ),
                                              )
                                            : Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(
                                                    Icons.refresh_rounded,
                                                    color: Colors.white,
                                                    size: 14,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    isKhmer
                                                        ? 'សាកល្បង'
                                                        : 'Retry',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                      ),
                                    ),

                                    const SizedBox(width: 4),

                                    // Dismiss 'X' button
                                    IconButton(
                                      onPressed: () => controller.dismiss(),
                                      icon: const Icon(
                                        Icons.close_rounded,
                                        color: Colors.white60,
                                        size: 18,
                                      ),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(
                                        minWidth: 28,
                                        minHeight: 28,
                                      ),
                                      visualDensity: VisualDensity.compact,
                                      splashRadius: 16,
                                      tooltip: AppUiTranslations.text(
                                        context,
                                        'Dismiss',
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      );
    });
  }

  Widget _buildBackOnlineToast(bool isKhmer) {
    return Semantics(
      liveRegion: true,
      label: isKhmer ? 'ភ្ជាប់អ៊ីនធឺណិតវិញហើយ' : 'Back online',
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: const Color(0xFF10B981).withValues(alpha: 0.32),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF065F46).withValues(alpha: 0.18),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Color(0xFFD1FAE5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Color(0xFF047857),
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                isKhmer ? 'បានភ្ជាប់អ៊ីនធឺណិតវិញ' : 'Back online',
                style: const TextStyle(
                  color: Color(0xFF065F46),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
