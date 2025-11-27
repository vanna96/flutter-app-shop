import 'package:demo_app/controllers/category_controller.dart';
import 'package:demo_app/models/category_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:demo_app/common_widgets/app_text.dart';
import 'package:demo_app/widgets/category_item_card_widget.dart';
import 'package:demo_app/widgets/search_bar_widget.dart';
import 'package:get/get.dart';
import 'category_items_screen.dart';

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

class ExploreScreen extends StatefulWidget {
  @override
  _ExploreScreenState createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final CategoryController categoryController = Get.find<CategoryController>();

  late List<CategoryModel> categoryList;
  CategoryModel? currentParent; // 👈 track parent category
  List<List<CategoryModel>> history = []; // 👈 store navigation stack

  @override
  void initState() {
    super.initState();
    categoryList = categoryController.categories;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0x379E9E97),
      body: SafeArea(
        child: Column(
          children: [
            buildHeader(),
            Expanded(child: getStaggeredGridView(context)),
          ],
        ),
      ),
    );
  }

  // ---------------- HEADER -------------------

  Widget buildHeader() {
    if (currentParent == null) {
      // ROOT CATEGORY HEADER
      return Column(
        children: [
          SizedBox(height: 20),
          Center(
            child: AppText(
              text: "Find Products",
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 20),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: SearchBarWidget(), // 👈 only show in root
          ),
          SizedBox(height: 10),
        ],
      );
    }

    // CHILD CATEGORY HEADER
    return Column(
      children: [
        SizedBox(height: 10),
        Row(
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back_ios),
              onPressed: onBackPressed, // 👈 go back
            ),
            Expanded(
              child: AppText(
                text: currentParent!.name,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(width: 48), // balance the back icon width
          ],
        ),
        SizedBox(height: 10),
      ],
    );
  }

  // ---------------- GRID VIEW -------------------

  Widget getStaggeredGridView(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: StaggeredGrid.count(
        crossAxisCount: 2,
        children: categoryList.asMap().entries.map((e) {
          int index = e.key;
          CategoryModel category = e.value;

          return GestureDetector(
            onTap: () => onCategoryItemClicked(category),
            child: Container(
              padding: EdgeInsets.all(10),
              child: CategoryItemCardWidget(
                item: category,
                color: gridColors[index % gridColors.length],
              ),
            ),
          );
        }).toList(),
        mainAxisSpacing: 3.0,
        crossAxisSpacing: 4.0,
      ),
    );
  }

  // ---------------- NAVIGATION -------------------

  void onCategoryItemClicked(CategoryModel category) {
    if (category.children.isNotEmpty) {
      // Save current list in navigation history
      history.add(categoryList);

      setState(() {
        currentParent = category;
        categoryList = category.children; // 👈 go deeper
      });
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => CategoryItemsScreen(title:category.name, id: category.id)),
      );
    }
  }

  void onBackPressed() {
    if (history.isNotEmpty) {
      setState(() {
        categoryList = history.removeLast(); // 👈 go back to previous list
        currentParent = history.isEmpty ? null : null;
      });
    } else {
      setState(() {
        currentParent = null;
      });
    }
  }
}
