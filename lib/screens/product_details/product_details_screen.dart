import 'package:flutter/material.dart';
import 'package:grocery_app/common_widgets/app_button.dart';
import 'package:grocery_app/common_widgets/app_text.dart';
import 'package:grocery_app/models/grocery_item.dart';
import 'package:grocery_app/styles/colors.dart';
import 'package:grocery_app/widgets/item_counter_widget.dart';

import 'favourite_toggle_icon_widget.dart';

class ProductDetailsScreen extends StatefulWidget {
  final GroceryItem groceryItem;
  final String? heroSuffix;

  const ProductDetailsScreen(this.groceryItem, {this.heroSuffix});

  @override
  _ProductDetailsScreenState createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  int amount = 1;

  @override
  Widget build(BuildContext context) {
    double bottomNavigationBarHeight = 90.0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: GestureDetector(
          onTap: () {
            Navigator.pop(context);
          },
          child: Container(
            padding: EdgeInsets.only(left: 25),
            child: Icon(
              Icons.arrow_back_ios,
              color: Colors.black,
            ),
          ),
        ),
        title: Container(
          padding: EdgeInsets.symmetric(
            horizontal: 25,
          ),
          child: AppText(
            text: "Details",
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          Padding(
              padding: EdgeInsets.only(right: 10), child: FavoriteToggleIcon())
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height -
                      bottomNavigationBarHeight,
                ),
                child: Column(
                  children: [
                    getImageHeaderWidget(),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                widget.groceryItem.name,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: AppText(
                                text: widget.groceryItem.description,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xff7C7C7C),
                              ),
                              trailing: Text(
                                "\$${getTotalPrice().toStringAsFixed(2)}",
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              )),
                          Divider(height: 10),
                          // Row(
                          //   children: [
                          //     ItemCounterWidget(
                          //       onAmountChanged: (newAmount) {
                          //         setState(() {
                          //           amount = newAmount;
                          //         });
                          //       },
                          //     ),
                          //     Spacer(),
                          //     Text(
                          //       "\$${getTotalPrice().toStringAsFixed(2)}",
                          //       style: TextStyle(
                          //         fontSize: 24,
                          //         fontWeight: FontWeight.bold,
                          //       ),
                          //     )
                          //   ],
                          // ),
                          Divider(height: 25),
                          Text('Description',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              )),
                          Divider(height: 10),
                          Text(
                              "Introducing our irresistible organic bananas, nature's golden delight! Grown with utmost care, these beauties offer a tropical escape for your taste buds. With their vibrant yellow peel and creamy texture, each bite unveils a burst of sweetness that will transport you to sun-drenched plantations.")
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: ClipRRect(
        // borderRadius: BorderRadius.only(
        //   topLeft: Radius.circular(20.0), // Adjust the radius as needed
        //   topRight: Radius.circular(20.0), // Adjust the radius as needed
        // ),
        child: Container(
            padding: EdgeInsets.only(left: 20, right: 20, bottom: 30),
            height: bottomNavigationBarHeight,
            color: Colors.white, // Set your preferred color
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    child: Container(
                        height: 50, // Set your preferred height
                        child: SizedBox(
                          height: 50,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 500),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: AppColors
                                        .trGrey, // Set grey background color
                                    borderRadius: BorderRadius.circular(
                                        15), // Set border radius
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.remove,
                                        color: Colors.red),
                                    onPressed: () {
                                      setState(() {
                                        if (amount <= 0) return;
                                        amount--;
                                      });
                                    },
                                  ),
                                ),
                                SizedBox(width: 12),
                                SizedBox(
                                    width: 30,
                                    child: Align(
                                      alignment: Alignment.center,
                                      child: Text(
                                        amount.toString(),
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    )),
                                SizedBox(width: 12),
                                Container(
                                  decoration: BoxDecoration(
                                    color: AppColors
                                        .primaryColor, // Set red background color
                                    borderRadius: BorderRadius.circular(
                                        15), // Set border radius
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.add,
                                        color: Colors.white),
                                    onPressed: () {
                                      setState(() {
                                        if (amount >= 99) return;
                                        amount++;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )),
                  ),
                ),
                SizedBox(width: 30),
                Expanded(
                  child: Card(
                    color: AppColors.primaryColor,
                    child: Container(
                        height: 50, // Set your preferred height
                        child: TextButton(
                          child: const Text(
                            'Add To Cart',
                            style: TextStyle(color: Colors.white, fontSize: 20),
                          ),
                          onPressed: () {
                            // Handle Add Item button onPressed
                          },
                        )),
                  ),
                ),
              ],
            )),
      ),
    );

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            getImageHeaderWidget(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        widget.groceryItem.name,
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      subtitle: AppText(
                        text: widget.groceryItem.description,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xff7C7C7C),
                      ),
                      trailing: FavoriteToggleIcon(),
                    ),
                    Spacer(),
                    Row(
                      children: [
                        ItemCounterWidget(
                          onAmountChanged: (newAmount) {
                            setState(() {
                              amount = newAmount;
                            });
                          },
                        ),
                        Spacer(),
                        Text(
                          "\$${getTotalPrice().toStringAsFixed(2)}",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      ],
                    ),
                    Spacer(),
                    Divider(thickness: 1),
                    getProductDataRowWidget("Product Details"),
                    Divider(thickness: 1),
                    getProductDataRowWidget("Nutrition",
                        customWidget: nutritionWidget()),
                    Divider(thickness: 1),
                    getProductDataRowWidget(
                      "Review",
                      customWidget: ratingWidget(),
                    ),
                    Spacer(),
                    AppButton(
                      label: "Add To Basket",
                    ),
                    Spacer(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget getImageHeaderWidget() {
    return Container(
      height: 250,
      padding: EdgeInsets.symmetric(horizontal: 25, vertical: 25),
      width: double.maxFinite,
      decoration: BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(25),
          bottomRight: Radius.circular(25),
        ),
        gradient: new LinearGradient(
            colors: [
              AppColors.primaryColor.withOpacity(0.2),
              const Color(0xFF3366FF).withOpacity(0.09),
            ],
            begin: const FractionalOffset(0.0, 0.0),
            end: const FractionalOffset(0.0, 1.0),
            stops: [0.0, 1.0],
            tileMode: TileMode.clamp),
      ),
      child: Hero(
        tag: "GroceryItem:" +
            widget.groceryItem.name +
            "-" +
            (widget.heroSuffix ?? ""),
        child: Image(
          image: AssetImage(widget.groceryItem.imagePath),
        ),
      ),
    );
  }

  Widget getProductDataRowWidget(String label, {Widget? customWidget}) {
    return Container(
      margin: EdgeInsets.only(
        top: 20,
        bottom: 20,
      ),
      child: Row(
        children: [
          AppText(text: label, fontWeight: FontWeight.w600, fontSize: 16),
          Spacer(),
          if (customWidget != null) ...[
            customWidget,
            SizedBox(
              width: 20,
            )
          ],
          Icon(
            Icons.arrow_forward_ios,
            size: 20,
          )
        ],
      ),
    );
  }

  Widget nutritionWidget() {
    return Container(
      padding: EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Color(0xffEBEBEB),
        borderRadius: BorderRadius.circular(5),
      ),
      child: AppText(
        text: "100gm",
        fontWeight: FontWeight.w600,
        fontSize: 12,
        color: Color(0xff7C7C7C),
      ),
    );
  }

  Widget ratingWidget() {
    Widget starIcon() {
      return Icon(
        Icons.star,
        color: Color(0xffF3603F),
        size: 20,
      );
    }

    return Row(
      children: [
        starIcon(),
        starIcon(),
        starIcon(),
        starIcon(),
        starIcon(),
      ],
    );
  }

  double getTotalPrice() {
    return amount * widget.groceryItem.price;
  }
}
