import 'package:grocery_app/localization/localized_material.dart';
import 'package:grocery_app/helpers/category_visuals.dart';
import 'package:grocery_app/models/category_item.dart';
import 'package:grocery_app/styles/colors.dart';
import 'package:grocery_app/widgets/app_network_image.dart';

class CategoryItemCardWidget extends StatelessWidget {
  const CategoryItemCardWidget({
    super.key,
    required this.item,
    this.color = AppColors.primaryColor,
  });

  final CategoryItem item;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final effectiveImage =
        CategoryVisuals.getEffectiveImage(item.imagePath, item.name);
    final fallbackIcon = CategoryVisuals.getIcon(item.name);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              item.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
                height: 1.25,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: effectiveImage.isNotEmpty
                  ? AppNetworkImage(
                      image: effectiveImage,
                      fit: BoxFit.cover,
                      width: 48,
                      height: 48,
                      fallbackIcon: fallbackIcon,
                    )
                  : Center(
                      child: Icon(
                        fallbackIcon,
                        color: color,
                        size: 24,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
