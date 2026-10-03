import 'package:grocery_app/models/banner_model.dart';
import 'package:grocery_app/models/category_model.dart';
import 'package:grocery_app/models/notification_model.dart';
import 'package:grocery_app/models/product_model.dart';
import 'package:grocery_app/models/store_model.dart';

class MockDataRepository {
  static final List<BannerModel> _defaultBanners = <BannerModel>[];

  static List<StoreModel> _stores = <StoreModel>[];
  static List<BannerModel> _banners = <BannerModel>[];
  static List<CategoryModel> _categories = <CategoryModel>[];
  static List<ProductModel> _products = <ProductModel>[];
  static List<ProductModel> _featuredProducts = <ProductModel>[];
  static List<ProductModel> _newArrivals = <ProductModel>[];
  static List<ProductModel> _bestSellers = <ProductModel>[];
  static List<ProductModel> _recommendedProducts = <ProductModel>[];
  static List<NotificationModel> _notifications = <NotificationModel>[];

  static bool _hasRemoteBanners = false;
  static bool get hasRemoteBanners => _hasRemoteBanners;

  static List<StoreModel> get stores => List<StoreModel>.unmodifiable(_stores);

  static List<BannerModel> get defaultBanners =>
      List<BannerModel>.unmodifiable(_defaultBanners);

  static List<BannerModel> get banners =>
      List<BannerModel>.unmodifiable(_banners);

  static List<CategoryModel> get categories =>
      List<CategoryModel>.unmodifiable(_categories);

  static List<NotificationModel> get notifications =>
      List<NotificationModel>.unmodifiable(_notifications);

  static List<ProductModel> get allProducts =>
      List<ProductModel>.unmodifiable(_products);

  static List<ProductModel> getShopProducts([int? storeId]) {
    if (storeId != null && storeId > 0) {
      final filtered = _products
          .where((p) => p.branchId == storeId)
          .toList(growable: false);
      return filtered;
    }
    return List<ProductModel>.from(_products, growable: false);
  }

  static void updateStores(List<StoreModel> stores) {
    _stores = List<StoreModel>.from(stores, growable: false);
  }

  static void updateBanners(List<BannerModel> banners) {
    if (banners.isNotEmpty) {
      _banners = List<BannerModel>.from(banners, growable: false);
      _hasRemoteBanners = true;
    } else {
      _banners = List<BannerModel>.from(_defaultBanners, growable: false);
      _hasRemoteBanners = false;
    }
  }

  static void updateCategories(List<CategoryModel> categories) {
    _categories = List<CategoryModel>.from(categories, growable: false);
  }

  static void updateProducts(List<ProductModel> products) {
    final byId = <int, ProductModel>{
      for (final p in _products) p.id: p,
      for (final p in products) p.id: p,
    };
    _products = byId.values.toList(growable: false);
    final flaggedNewArrivals =
        _products.where((product) => product.isNewArrival).toList(growable: false);
    if (flaggedNewArrivals.isNotEmpty) {
      _newArrivals = flaggedNewArrivals;
    }
  }

  static void updateProduct(ProductModel product) {
    final byId = <int, ProductModel>{
      for (final p in _products) p.id: p,
      product.id: product,
    };
    _products = byId.values.toList(growable: false);
    _featuredProducts = _featuredProducts
        .map((p) => p.id == product.id ? product : p)
        .toList(growable: false);
    _newArrivals = _newArrivals
        .map((p) => p.id == product.id ? product : p)
        .toList(growable: false);
    _bestSellers = _bestSellers
        .map((p) => p.id == product.id ? product : p)
        .toList(growable: false);
    _recommendedProducts = _recommendedProducts
        .map((p) => p.id == product.id ? product : p)
        .toList(growable: false);
  }

  static void updateNotifications(List<NotificationModel> notifications) {
    _notifications = List<NotificationModel>.from(
      notifications,
      growable: false,
    );
  }

  static void updateHomeSections({
    List<ProductModel>? featuredProducts,
    List<ProductModel>? newArrivals,
    List<ProductModel>? bestSellers,
    List<ProductModel>? recommendedProducts,
    bool replaceProducts = false,
  }) {
    if (featuredProducts != null) {
      _featuredProducts = List<ProductModel>.from(
        featuredProducts,
        growable: false,
      );
    }

    if (newArrivals != null) {
      _newArrivals = List<ProductModel>.from(newArrivals, growable: false);
    }

    if (bestSellers != null) {
      _bestSellers = List<ProductModel>.from(bestSellers, growable: false);
    }

    if (recommendedProducts != null) {
      _recommendedProducts = List<ProductModel>.from(
        recommendedProducts,
        growable: false,
      );
    }

    final byId = <int, ProductModel>{
      if (!replaceProducts)
        for (final product in _products) product.id: product,
      for (final product in _featuredProducts) product.id: product,
      for (final product in _newArrivals) product.id: product,
      for (final product in _bestSellers) product.id: product,
      for (final product in _recommendedProducts) product.id: product,
    };

    _products = byId.values.toList(growable: false);
  }

  static ProductModel? getProductById(int id) {
    for (final product in _products) {
      if (product.id == id) {
        return product;
      }
    }

    return null;
  }

  static List<ProductModel> getBeverageProducts() {
    return _products
        .where((product) => product.categoryEn == 'Beverages')
        .toList(growable: false);
  }

  static List<ProductModel> getNewArrivals(int storeId) {
    final items = _newArrivals.isNotEmpty
        ? _newArrivals
        : _products.where((product) => product.isNewArrival).toList(growable: false);

    if (storeId > 0) {
      return items
          .where((product) => product.branchId == storeId)
          .toList(growable: false);
    }

    return List<ProductModel>.unmodifiable(items);
  }

  static List<ProductModel> getBestSellers(int storeId) {
    if (storeId > 0) {
      return _bestSellers
          .where((product) => product.branchId == storeId)
          .toList(growable: false);
    }
    return List<ProductModel>.unmodifiable(_bestSellers);
  }

  static List<ProductModel> getRecommended(int storeId) {
    if (storeId > 0) {
      return _recommendedProducts
          .where((product) => product.branchId == storeId)
          .toList(growable: false);
    }
    return List<ProductModel>.unmodifiable(_recommendedProducts);
  }

  static List<ProductModel> getFeaturedProducts([int? storeId]) {
    if (storeId != null && storeId > 0) {
      return _featuredProducts
          .where((product) => product.branchId == storeId)
          .toList(growable: false);
    }
    return List<ProductModel>.unmodifiable(_featuredProducts);
  }
}
