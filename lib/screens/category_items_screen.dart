import 'package:demo_app/controllers/product_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:demo_app/common_widgets/app_text.dart';
import 'package:demo_app/models/product_model.dart';
import 'package:demo_app/screens/product_details/product_details_screen.dart';
import 'package:demo_app/widgets/grocery_item_card_widget.dart';
import 'package:get/get.dart';

import 'filter_screen.dart';

class CategoryItemsScreen extends StatefulWidget {
  final String title;
  final int id;

  CategoryItemsScreen({required this.title, required this.id});

  @override
  _CategoryItemsScreenState createState() => _CategoryItemsScreenState();
}

class _CategoryItemsScreenState extends State<CategoryItemsScreen> {
  final ProductController productController = Get.find<ProductController>();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    productController.getProductByCategory(widget.id, reset: true);

    // Listen to scroll to load more
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 100 &&
          !productController.isLoading.value &&
          productController.hasMore.value) {
        productController.getProductByCategory(widget.id);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: EdgeInsets.only(left: 25),
            child: Icon(Icons.arrow_back_ios, color: Colors.black),
          ),
        ),
        actions: [
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => FilterScreen()),
            ),
            child: Container(
              padding: EdgeInsets.only(right: 25),
              child: Icon(Icons.sort, color: Colors.black),
            ),
          ),
        ],
        title: AppText(
          text: widget.title,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      body: Obx(() {
        if (productController.isLoading.value && productController.page.value == 1) {
          return Center(child: CircularProgressIndicator());
        }

        if (productController.productByCategory.isEmpty) {
          return Center(child: Text("No products found"));
        }

        return SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            children: [
              StaggeredGrid.count(
                crossAxisCount: 2,
                mainAxisSpacing: 3,
                crossAxisSpacing: 0,
                children: productController.productByCategory.map((item) {
                  return GestureDetector(
                    onTap: () => onItemClicked(context, item),
                    child: Container(
                      padding: EdgeInsets.all(10),
                      child: GroceryItemCardWidget(
                        item: item,
                        heroSuffix:
                        "product_by_category_${item.id}_${item.categoryEn}",
                      ),
                    ),
                  );
                }).toList(),
              ),
              if (productController.isLoading.value)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: CircularProgressIndicator(),
                ),
            ],
          ),
        );
      }),
    );
  }

  void onItemClicked(BuildContext context, ProductModel groceryItem) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailsScreen(
          groceryItem,
          heroSuffix: "product_detail_screen_${groceryItem.id}",
        ),
      ),
    );
  }
}
