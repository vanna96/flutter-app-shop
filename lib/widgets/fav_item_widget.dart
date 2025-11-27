import 'package:flutter/material.dart';
import 'package:demo_app/common_widgets/app_text.dart';
import 'package:demo_app/models/grocery_item.dart';
import 'package:demo_app/styles/colors.dart';

class FavItemWidget extends StatefulWidget {
  FavItemWidget({Key? key, required this.item}) : super(key: key);
  final GroceryItem item;

  @override
  _ChartItemWidgetState createState() => _ChartItemWidgetState();
}

class _ChartItemWidgetState extends State<FavItemWidget> {
  final double height = 110;

  final Color borderColor = Color(0xffE2E2E2);

  final double borderRadius = 18;

  int amount = 1;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      margin: EdgeInsets.symmetric(
        vertical: 30,
      ),
      child: IntrinsicHeight(
          child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Image
          imageWidget(),
          const SizedBox(width: 30),
          // Middle Column (title, description, price stacked)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppText(
                text: widget.item.name,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              const SizedBox(height: 5),
              AppText(
                text: widget.item.description,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.darkGrey,
              ),
              const SizedBox(height: 12),
              AppText(
                text: "\$${getPrice().toStringAsFixed(2)}",
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ],
          ),
          const Spacer(),
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(height: 15), // top spacing
              Icon(
                Icons.bookmark,
                color: AppColors.primaryColor,
                size: 25,
              ),
            ],
          ),

        ],
      )),
    );
  }

  Widget imageWidget() {
    return Container(
      width: 100,
      child: Image.asset(widget.item.imagePath),
    );
  }

  double getPrice() {
    return widget.item.price * amount;
  }
}
