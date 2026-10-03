import 'package:grocery_app/localization/localized_material.dart';
import 'package:grocery_app/helpers/category_visuals.dart';
import 'package:grocery_app/localization/catalog_localization.dart';
import 'package:grocery_app/models/category_model.dart';
import 'package:grocery_app/widgets/app_network_image.dart';

class CategoryCard extends StatelessWidget {
  const CategoryCard(
    this.category, {
    required this.color,
    this.width = 76,
    this.height = 105,
    this.onTap,
    super.key,
  });

  final CategoryModel category;
  final Color color;
  final double width;
  final double height;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final effectiveImage =
        CategoryVisuals.getEffectiveImage(category.image, category.name);
    final fallbackIcon = CategoryVisuals.getIcon(category.name);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: width,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: color.withValues(alpha: 0.22),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: effectiveImage.isNotEmpty
                        ? AppNetworkImage(
                            key: ValueKey(category.id),
                            image: effectiveImage,
                            width: 38,
                            height: 38,
                            fit: BoxFit.cover,
                            fallbackIcon: fallbackIcon,
                            borderRadius: BorderRadius.circular(12),
                          )
                        : Icon(
                            fallbackIcon,
                            color: color,
                            size: 26,
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                category.localizedName(context),
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
