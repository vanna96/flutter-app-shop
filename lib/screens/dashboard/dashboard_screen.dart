import 'dart:async';

import 'package:grocery_app/localization/localized_material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:grocery_app/controllers/app_state_controller.dart';
import 'package:grocery_app/controllers/navigation_controller.dart';
import 'package:grocery_app/screens/account/developer_settings_screen.dart';

import 'navigator_item.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final NavigationController navController = Get.put(NavigationController());

  @override
  void initState() {
    super.initState();
  }

  Timer? _homePressTimer;
  bool _developerSettingsOpenedFromHold = false;
  @override
  Widget build(BuildContext context) {
    final items = getNavigatorItems(context);

    return Obx(
      () => Scaffold(
        backgroundColor: Colors.white,
        body: items[navController.currentIndex.value].screen,
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(20),
              topLeft: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 20,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            child: SafeArea(
              top: false,
              bottom: false,
              child: Container(
                color: Colors.white,
                // Keep the navigation compact. A fixed 24px bottom inset left
                // a visibly empty footer below the labels on iPhone.
                padding: const EdgeInsets.only(top: 10, bottom: 8),
                child: Row(
                  children: items
                      .map((item) {
                        final isSelected =
                            item.index == navController.currentIndex.value;
                        return Expanded(
                          child: _DashboardNavItem(
                            index: item.index,
                            label: item.label,
                            iconPath: item.iconPath,
                            isSelected: isSelected,
                            selectedColor: const Color(0xFFFF762D),
                            unselectedColor: const Color(0xFF64748B),
                            onTap: () => _handleItemTap(item.index),
                            onTapDown: item.index == 0
                                ? (_) => _startHomePressTimer()
                                : null,
                            onTapUp: item.index == 0
                                ? (_) => _cancelHomePressTimer()
                                : null,
                            onTapCancel: item.index == 0
                                ? _cancelHomePressTimer
                                : null,
                          ),
                        );
                      })
                      .toList(growable: false),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleItemTap(int index) {
    if (index == 0 && _developerSettingsOpenedFromHold) {
      _developerSettingsOpenedFromHold = false;
      return;
    }

    navController.currentIndex.value = index;
  }

  void _startHomePressTimer() {
    _cancelHomePressTimer();
    _developerSettingsOpenedFromHold = false;

    _homePressTimer = Timer(const Duration(seconds: 2), () async {
      if (!mounted) {
        return;
      }

      _developerSettingsOpenedFromHold = true;
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const DeveloperSettingsScreen()),
      );
    });
  }

  void _cancelHomePressTimer() {
    _homePressTimer?.cancel();
    _homePressTimer = null;
  }

  @override
  void dispose() {
    _cancelHomePressTimer();
    super.dispose();
  }
}

class _DashboardNavItem extends StatelessWidget {
  const _DashboardNavItem({
    required this.index,
    required this.label,
    required this.iconPath,
    required this.isSelected,
    required this.selectedColor,
    required this.unselectedColor,
    required this.onTap,
    this.onTapDown,
    this.onTapUp,
    this.onTapCancel,
  });

  final int index;
  final String label;
  final String iconPath;
  final bool isSelected;
  final Color selectedColor;
  final Color unselectedColor;
  final VoidCallback onTap;
  final GestureTapDownCallback? onTapDown;
  final GestureTapUpCallback? onTapUp;
  final VoidCallback? onTapCancel;

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? selectedColor : unselectedColor;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      onTapDown: onTapDown,
      onTapUp: onTapUp,
      onTapCancel: onTapCancel,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                SvgPicture.asset(iconPath, color: color),
                if (index == 3)
                  Obx(() {
                    try {
                      final appStateController = Get.find<AppStateController>();
                      final count = appStateController.cartItemCount;
                      if (count <= 0) return const SizedBox.shrink();
                      return Positioned(
                        top: -5,
                        right: -10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF762D),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          child: Text(
                            '$count',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    } catch (_) {
                      return const SizedBox.shrink();
                    }
                  }),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 11.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
