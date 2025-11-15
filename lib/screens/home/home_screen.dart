import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:grocery_app/controllers/home_controller.dart';
import 'package:grocery_app/generated/l10n.dart';
import 'package:grocery_app/models/category_model.dart';
import 'package:grocery_app/models/grocery_item.dart';
import 'package:grocery_app/screens/product_details/product_details_screen.dart';
import 'package:grocery_app/styles/colors.dart';
import 'package:grocery_app/widgets/grocery_item_card_widget.dart';
import 'category_cart.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'notification_list_screen.dart';

class HomeScreen extends StatefulWidget {
  HomeScreen({super.key});
  final HomeController homeController = Get.put(HomeController());

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedLocationId = 1;

  List<Color> gridColors = [
    Color(0xff53B175),
    Color(0xffF8A44C),
    Color(0xffF7A593),
    Color(0xffD3B0E0),
    Color(0xffFDE598),
    Color(0xffB7DFF5),
    Color(0xff836AF6),
    Color(0xffD73B77),
  ];

  final Random random = Random();

  final List<Map<String, dynamic>> locations = [
    {
      'id': 1,
      'name': 'ចែច្រិប',
      'description': 'ភូមិកំពង់ទួល ឃុំអន្លង់រមៀត ស្រុកកណ្តាលស្ទឹង ខេត្តកណ្តាល',
      'image': 'assets/images/shop.png',
    },
    {
      'id': 2,
      'name': 'ចែអូនលក់សំបកធុងសាំងនឹងស៊ីទែនគ្រប់ប្រភេទ',
      'description': 'ភូមិព្រែកតាទែន, NR5, ខេត្កណ្តាល',
      'image': 'assets/images/shop.png',
    }
  ];

  State<HomeScreen> createState() => _HomeScreenState();

  @override
  Widget build(BuildContext context) {
    String _shortenText(String text, int maxLength) {
      if (text.length <= maxLength) return text;
      return '${text.substring(0, maxLength)}…';
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        titleSpacing: 0,
        title: GestureDetector(
          onTap: () => _showLocationSelector(context),
          child: Padding(
            padding: const EdgeInsets.only(left: 5.0),
            child: Row(
              children: [
                Text(
                  _shortenText(
                    locations.firstWhere(
                        (loc) => loc['id'] == selectedLocationId)['name'],
                    20, // max characters to show
                  ),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.arrow_drop_down, color: Colors.black),
              ],
            ),
          ),
        ),
        actions: [
          _buildNotification(context),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 25),
              Obx(() {
                if (widget.homeController.isLoading.value) {
                  return Center(child: CircularProgressIndicator());
                }

                if (widget.homeController.banners.isEmpty) {
                  return SizedBox.shrink();
                }

                return CarouselSlider(
                  options: CarouselOptions(
                    height: 180.0,
                    autoPlay: true,
                    enlargeCenterPage: true,
                    viewportFraction: 0.9,
                    aspectRatio: 16 / 9,
                    autoPlayCurve: Curves.fastOutSlowIn,
                    enableInfiniteScroll: true,
                    autoPlayAnimationDuration: const Duration(seconds: 1),
                  ),
                  items: widget.homeController.banners.map((banner) {
                    return Builder(
                      builder: (BuildContext context) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Image.network(
                            banner.image, // use network image from API
                            fit: BoxFit.fitWidth,
                            width: MediaQuery.of(context).size.width,
                          ),
                        );
                      },
                    );
                  }).toList(),
                );
              }),
              SizedBox(height: 25),
              _buildSubTitle(S.of(context).category, context),
              SizedBox(height: 15),
              Obx(() {
                if (widget.homeController.isLoading.value) {
                  return Center(child: CircularProgressIndicator());
                }

                if (widget.homeController.categories.isEmpty) {
                  return Center(child: Text("No categories found"));
                }
                return _buildFeaturedCategories(
                    widget.homeController.categories);
              }),
              SizedBox(height: 25),
              _buildSubTitle(S.of(context).new_arrival, context),
              _buildHorizontalItemSlider(exclusiveOffers),
              SizedBox(height: 15),
              _buildSubTitle(S.of(context).best_sell, context),
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

  Widget _buildNotification(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => const NotificationListScreen()),
        );
      },
      borderRadius: BorderRadius.circular(size.width * 0.1),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(
            Icons.notifications_none,
            size: size.width * 0.1,
            color: Colors.black,
          ),
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red,
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
              ),
              constraints: const BoxConstraints(
                minWidth: 20,
                minHeight: 20,
              ),
              child: const Center(
                child: Text(
                  '10+',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubTitle(String text, context) {
    return Row(
      children: [
        Text(
          text,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Spacer(),
        Text(
          S.of(context).see_all,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue, // Example color change
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedCategories(List<CategoryModel> categories) {
    return Container(
      height: 105,
      child: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          return CategoryCard(
            categories[index],
            color: AppColors.primaryColor, // you can vary colors if you want
          );
        },
        separatorBuilder: (context, index) => SizedBox(width: 20),
      ),
    );
  }

  Widget _buildHorizontalItemSlider(List<GroceryItem> items) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10),
      height: 250,
      child: ListView.separated(
        // padding: EdgeInsets.zero,
        padding: EdgeInsets.symmetric(horizontal: 10),
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              _onItemClicked(context, items[index]);
            },
            child: GroceryItemCardWidget(
              item: items[index],
              heroSuffix:
                  "item_grocery--${DateTime.now().microsecondsSinceEpoch}",
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
          heroSuffix: "item_detail-${DateTime.now().microsecondsSinceEpoch}",
        ),
      ),
    );
  }

  void _showLocationSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true, // important for dynamic height
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        // Calculate max height (e.g., 60% of screen)
        final maxHeight = MediaQuery.of(context).size.height * 0.6;

        return LayoutBuilder(
          builder: (context, constraints) {
            // Calculate total list height
            final itemHeight = 100.0; // approx height of each location box
            final totalHeight =
                16 + 40 + 16 + 18 + 16 + locations.length * (itemHeight + 16);
            // 16 = padding/margin, 40 = drag handle, 18 = title, 16 = spacing

            return Container(
              constraints: BoxConstraints(
                maxHeight: maxHeight,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  Text(
                    S.of(context).select_location,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  // Wrap list in Flexible + SingleChildScrollView for dynamic scrolling
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: locations.length,
                      itemBuilder: (context, index) {
                        final color = gridColors[index];
                        final offsetX =
                            (random.nextDouble() * 6) - 3; // -3 to 3
                        final offsetY = (random.nextDouble() * 6) - 3;
                        final blur = random.nextDouble() * 10 + 4; // 4 to 14
                        final opacity =
                            0.3 + random.nextDouble() * 0.3; // 0.3 to 0.6
                        final loc = locations[index];
                        return GestureDetector(
                          onTap: () => _showLocationDetails(loc),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            height: 80,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.grey[100],
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                              border: Border.all(
                                color: color.withOpacity(0.1), // subtle border
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(left: 10),
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(12),
                                      bottomLeft: Radius.circular(12),
                                    ),
                                    child: Image.asset(
                                      loc['image'],
                                      width: 40,
                                      height: 40,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment
                                        .center, // <-- center vertically
                                    children: [
                                      Text(
                                        loc['name'],
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(Icons.location_on,
                                              size: 14, color: Colors.grey),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              loc['description'],
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showLocationDetails(Map<String, dynamic> loc) {
    Navigator.pop(context); // Close the selector first

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                loc['name'],
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_on, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      loc['description'],
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel',
                          style: TextStyle(color: AppColors.primaryColor)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          selectedLocationId = loc['id'];
                        });
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor),
                      child: const Text(
                        'Change',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
