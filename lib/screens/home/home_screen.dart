import 'package:flutter/material.dart';
import 'package:grocery_app/models/grocery_item.dart';
import 'package:grocery_app/screens/product_details/product_details_screen.dart';
import 'package:grocery_app/styles/colors.dart';
import 'package:grocery_app/widgets/grocery_item_card_widget.dart';
import 'grocery_featured_Item_widget.dart';

class HomeScreen extends StatelessWidget {
  final String selectedLocation = "ចែច្រិបកំពង់ទួល"; // Default selected location

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Shop Now',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: Colors.grey[400],
                  size: 16,
                ),
                SizedBox(width: 8),
                Text(
                  selectedLocation,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          _buildProfileAvatar(context),
          SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 25),
              _buildSubTitle("ប្រភេទ"),
              SizedBox(height: 15),
              _buildFeaturedItems(),
              SizedBox(height: 25),
              _buildSubTitle("ផលិតផលមកដល់ថ្មី"),
              _buildHorizontalItemSlider(exclusiveOffers),
              SizedBox(height: 15),
              _buildSubTitle("ចំណាត់ថ្នាក់កំពូល"),
              _buildHorizontalItemSlider(bestSelling),
              SizedBox(height: 15),
              _buildHorizontalItemSlider(groceries),
              SizedBox(height: 15),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileAvatar(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return Stack(
      children: [
        CircleAvatar(
          radius: size.width * 0.070,
          foregroundImage: AssetImage("assets/images/account_image.jpg"),
        ),
        Positioned(
          right: 0,
          top: 0,
          child: Container(
            padding: EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.red,
              border: Border.all(
                color: Colors.white,
                width: 2,
              ),
            ),
            constraints: BoxConstraints(
              minWidth: 20,
              minHeight: 20,
            ),
            child: Center(
              child: Text(
                '10+',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubTitle(String text) {
    return Row(
      children: [
        Text(
          text,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Spacer(),
        Text(
          "See All",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue, // Example color change
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedItems() {
    return Container(
      height: 105,
      child: ListView(
        padding: EdgeInsets.zero,
        scrollDirection: Axis.horizontal,
        children: [
          SizedBox(width: 20),
          GroceryFeaturedCard(
            groceryFeaturedItems[0],
            color: Color(0xffF8A44C),
          ),
          SizedBox(width: 20),
          GroceryFeaturedCard(
            groceryFeaturedItems[1],
            color: AppColors.primaryColor,
          ),
          SizedBox(width: 20),
        ],
      ),
    );
  }

  Widget _buildHorizontalItemSlider(List<GroceryItem> items) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10),
      height: 250,
      child: ListView.separated(
        padding: EdgeInsets.zero,
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              _onItemClicked(context, items[index]);
            },
            child: GroceryItemCardWidget(
              item: items[index],
              heroSuffix: "home_screen",
            ),
          );
        },
        separatorBuilder: (context, index) => SizedBox(width: 20),
      ),
    );
  }

  void _onItemClicked(BuildContext context, GroceryItem groceryItem) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailsScreen(
          groceryItem,
          heroSuffix: "home_screen",
        ),
      ),
    );
  }
}
