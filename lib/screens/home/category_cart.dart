import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:demo_app/models/category_model.dart';
import 'package:demo_app/controllers/language_controller.dart';
import 'package:demo_app/styles/colors.dart';

class CategoryCard extends StatelessWidget {
  const CategoryCard(this.category,
      {this.color = AppColors.primaryColor, super.key});

  final CategoryModel category;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final languageController = Get.find<LanguageController>();

    return Container(
      width: 250,
      height: 105,
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 17),
      decoration: BoxDecoration(
          color: color.withOpacity(0.25),
          borderRadius: BorderRadius.circular(18)),
      child: Row(
        children: [
          CachedNetworkImage(
            key: ValueKey(category.id),
            imageUrl: category.image,
            width: 70,
            height: 70,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              width: 70,
              height: 70,
              color: Colors.grey[300],
              child: const Center(
                  child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primaryColor,
              )),
            ),
            errorWidget: (context, url, error) => Container(
              width: 70,
              height: 70,
              color: Colors.grey[300],
              child: const Icon(Icons.error, color: Colors.red),
            ),
          ),
          SizedBox(width: 15),
          Expanded(
            child: Obx(() {
              final displayName =
                  languageController.currentLanguageCode.value == 'km'
                      ? (category.khName ?? category.name)
                      : category.name;

              return Text(
                displayName,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              );
            }),
          ),
        ],
      ),
    );
  }
}
