import 'package:grocery_app/localization/localized_material.dart';
import 'package:get/get.dart';
import 'package:grocery_app/controllers/app_state_controller.dart';
import 'package:grocery_app/controllers/login_controller.dart';
import 'package:grocery_app/models/product_model.dart';

class FavoriteToggleIcon extends StatelessWidget {
  FavoriteToggleIcon({
    super.key,
    required this.product,
    this.size = 30,
    this.unselectedColor = Colors.white,
  });

  final ProductModel product;
  final double size;
  final Color unselectedColor;
  final AppStateController appStateController = Get.find<AppStateController>();
  final LoginController loginController = Get.find<LoginController>();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!loginController.isAuthenticated.value) {
        return const SizedBox.shrink();
      }

      final isFav = appStateController.isFavorite(product.id);
      return InkWell(
        onTap: () {
          appStateController.toggleFavorite(product);
        },
        child: Icon(
          isFav ? Icons.favorite : Icons.favorite_border,
          color: isFav ? Colors.red : unselectedColor,
          size: size,
        ),
      );
    });
  }
}
