import 'package:flutter/material.dart';
import 'package:demo_app/common_widgets/app_text.dart';
import 'package:demo_app/models/grocery_item.dart';
import 'package:demo_app/models/product_model.dart';
import 'package:demo_app/widgets/grocery_item_card_widget.dart';
import 'package:demo_app/screens/product_details/product_details_screen.dart';

class ShopScreen extends StatefulWidget {
  @override
  _ShopScreenState createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  bool isGridView = false; // false = list, true = grid
  String? selectedSort; // Tracks selected sorting option

  List<ProductModel> sortedGroceries = List.from([]); // Copy of groceries

  @override
  Widget build(BuildContext context) {
    // Sort the list dynamically whenever selectedSort changes
    sortGroceries();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            getHeader(),
            getViewToggleAndSortToolbar(),
            Expanded(
              child: isGridView
                  ? _buildGridItemList(sortedGroceries)
                  : _buildVerticalItemList(sortedGroceries),
            ),
          ],
        ),
      ),
    );
  }

  Widget getHeader() {
    return Column(
      children: [
        SizedBox(height: 20),
        Center(
          child: AppText(
            text: "Shop Now",
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 10),
      ],
    );
  }

  Widget getViewToggleAndSortToolbar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10),
      child: Row(
        children: [
          // Sort dropdown
          DropdownButton<String>(
            hint: Text("Sort by"),
            value: selectedSort,
            items: [
              "Price: Low to High",
              "Price: High to Low",
              "Name: A-Z",
              "Name: Z-A",
            ].map((sortOption) {
              return DropdownMenuItem(
                value: sortOption,
                child: Text(sortOption),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedSort = value;
              });
            },
          ),
          Spacer(),
          // List/Grid toggle
          IconButton(
            icon: Icon(Icons.list_alt),
            color: isGridView ? Colors.grey : Colors.black,
            onPressed: () {
              setState(() {
                isGridView = false;
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.grid_view),
            color: isGridView ? Colors.black : Colors.grey,
            onPressed: () {
              setState(() {
                isGridView = true;
              });
            },
          ),
        ],
      ),
    );
  }

  void sortGroceries() {
    if (selectedSort == null) return;

    sortedGroceries = List.from(groceries); // Reset to original

    switch (selectedSort) {
      case "Price: Low to High":
        sortedGroceries.sort((a, b) => a.price.compareTo(b.price));
        break;
      case "Price: High to Low":
        sortedGroceries.sort((a, b) => b.price.compareTo(a.price));
        break;
      case "Name: A-Z":
        sortedGroceries.sort((a, b) => a.name.compareTo(b.name));
        break;
      case "Name: Z-A":
        sortedGroceries.sort((a, b) => b.name.compareTo(a.name));
        break;
    }
  }

  Widget _buildVerticalItemList(List<ProductModel> items) {
    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () => _onItemClicked(context, items[index]),
          child: GroceryItemCardWidget(
            item: items[index],
            heroSuffix: "item_grocery-${index}",
          ),
        );
      },
      separatorBuilder: (context, index) => SizedBox(height: 20),
    );
  }

  Widget _buildGridItemList(List<ProductModel> items) {
    return GridView.builder(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.7,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () => _onItemClicked(context, items[index]),
          child: GroceryItemCardWidget(
            item: items[index],
            heroSuffix: "item_grocery-${index}",
          ),
        );
      },
    );
  }

  void _onItemClicked(BuildContext context, ProductModel groceryItem) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailsScreen(
          groceryItem,
          heroSuffix: "item_detail",
        ),
      ),
    );
  }
}
