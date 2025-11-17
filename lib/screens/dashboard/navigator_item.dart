import 'package:flutter/material.dart';
import 'package:grocery_app/screens/account/account_screen.dart';
import 'package:grocery_app/screens/cart/cart_screen.dart';
import 'package:grocery_app/screens/explore_screen.dart';
import 'package:grocery_app/screens/home/home_screen.dart';
// import 'package:grocery_app/screens/shop/shop_screen.dart';
import 'package:grocery_app/generated/l10n.dart';
// import '../favourite_screen.dart';

class NavigatorItem {
  final String label;
  final String iconPath;
  final int index;
  final Widget screen;

  NavigatorItem(this.label, this.iconPath, this.index, this.screen);
}

List<NavigatorItem> getNavigatorItems(BuildContext context) {
  return [
    NavigatorItem(S.of(context).home, "assets/icons/home.svg", 0, HomeScreen()),
    NavigatorItem(S.of(context).explore, "assets/icons/explore_icon.svg", 1,
        ExploreScreen()),
    // NavigatorItem(
    //     S.of(context).shop, "assets/icons/shop_icon.svg", 2, ShopScreen()),
    NavigatorItem(
        S.of(context).cart, "assets/icons/cart_icon.svg", 2, CartScreen()),
    NavigatorItem(S.of(context).account, "assets/icons/account_icon.svg", 3,
        AccountScreen()),
  ];
}
