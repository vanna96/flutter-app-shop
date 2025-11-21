import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:grocery_app/controllers/navigation_controller.dart';
import 'package:grocery_app/styles/colors.dart';
import 'navigator_item.dart';

class DashboardScreen extends StatelessWidget {
  final NavigationController navController = Get.put(NavigationController());

  @override
  Widget build(BuildContext context) {
    final items = getNavigatorItems(context);

    return Obx(() => Scaffold(
      backgroundColor: Colors.white,
      body: items[navController.currentIndex.value].screen,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(15),
            topLeft: Radius.circular(15),
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black38.withOpacity(0.1),
                spreadRadius: 0,
                blurRadius: 37,
                offset: Offset(0, -12)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(15),
            topRight: Radius.circular(15),
          ),
          child: BottomNavigationBar(
            backgroundColor: Colors.white,
            currentIndex: navController.currentIndex.value,
            onTap: (index) {
              navController.currentIndex.value = index; // update reactive state
            },
            type: BottomNavigationBarType.fixed,
            selectedItemColor: AppColors.primaryColor,
            selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600),
            unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w600),
            unselectedItemColor: Colors.black,
            items: items.map((e) {
              return BottomNavigationBarItem(
                label: e.label,
                icon: SvgPicture.asset(
                  e.iconPath,
                  color: e.index == navController.currentIndex.value
                      ? AppColors.primaryColor
                      : Colors.black,
                ),
              );
            }).toList(),
          ),
        ),
      ),
    ));
  }
}
