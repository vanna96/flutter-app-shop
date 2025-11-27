import 'package:cached_network_image/cached_network_image.dart';
import 'package:demo_app/models/category_model.dart';
import 'package:demo_app/styles/colors.dart';
import 'package:flutter/material.dart';
import 'package:demo_app/common_widgets/app_text.dart';

class CategoryItemCardWidget extends StatelessWidget {
  CategoryItemCardWidget(
      {Key? key, required this.item, this.color = Colors.blue})
      : super(key: key);
  final CategoryModel item;

  final height = 200.0;

  final width = 175.0;

  final Color borderColor = Color(0xffE2E2E2);
  final double borderRadius = 18;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: 5, bottom: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: color.withOpacity(0.7),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            height: 120,
            width: 120,
            child: imageWidget(context),
          ),
          SizedBox(
            height: 60,
            child: Center(
              child: AppText(
                text: item.name,
                textAlign: TextAlign.center,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget imageWidget(context) {
    return Container(
      child: CachedNetworkImage(
        imageUrl: item.image,
        fit: BoxFit.cover,
        width: MediaQuery.of(context).size.width,
        placeholder: (context, url) => Container(
          width: double.infinity,
          height: 180,
          color: Colors.grey[300],
          child: const Center(
            child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primaryColor),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          width: double.infinity,
          height: 180,
          color: Colors.grey[300],
          child: const Icon(Icons.error, color: Colors.red),
        ),
      ),
    );
  }
}
