import 'package:flutter/widgets.dart';
import 'package:grocery_app/models/category_model.dart';
import 'package:grocery_app/models/product_model.dart';
import 'package:grocery_app/models/store_model.dart';

bool _usesKhmer(BuildContext context) =>
    Localizations.localeOf(context).languageCode == 'km';

String localizedCatalogName(
  BuildContext context,
  String name,
  String? foreignName,
) {
  final translated = foreignName?.trim() ?? '';
  return _usesKhmer(context) && translated.isNotEmpty ? translated : name;
}

extension LocalizedProductModel on ProductModel {
  String localizedName(BuildContext context) =>
      localizedCatalogName(context, name, khName);

  String localizedCategoryName(BuildContext context) =>
      localizedCatalogName(context, categoryEn, categoryKh);
}

extension LocalizedProductUomModel on ProductUomModel {
  String localizedName(BuildContext context) =>
      localizedCatalogName(context, name, foreignName);
}

extension LocalizedProductOptionGroup on ProductOptionGroup {
  String localizedName(BuildContext context) =>
      localizedCatalogName(context, name, foreignName);
}

extension LocalizedProductOptionValue on ProductOptionValue {
  String localizedName(BuildContext context) =>
      localizedCatalogName(context, name, foreignName);
}

extension LocalizedCategoryModel on CategoryModel {
  String localizedName(BuildContext context) =>
      localizedCatalogName(context, name, khName);
}

extension LocalizedStoreModel on StoreModel {
  String localizedName(BuildContext context) =>
      localizedCatalogName(context, name, khName);
}
