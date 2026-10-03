import 'package:grocery_app/models/cart_pricing_model.dart';
import 'package:dio/dio.dart';
import 'package:grocery_app/models/banner_model.dart';
import 'package:grocery_app/models/category_model.dart';
import 'package:grocery_app/models/currency_model.dart';
import 'package:grocery_app/models/notification_model.dart';
import 'package:grocery_app/models/product_model.dart';
import 'package:grocery_app/models/store_model.dart';
import 'package:grocery_app/services/api_service.dart';

class PaginatedProductsResponse {
  final List<ProductModel> items;
  final int currentPage;
  final int lastPage;
  final int total;
  final int perPage;

  const PaginatedProductsResponse({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.total,
    required this.perPage,
  });

  bool get hasMore => currentPage < lastPage;
}

class MobileApiRepository {
  MobileApiRepository({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    final response = await _apiService.post(
      '/mobile/auth/login',
      data: {'username': username, 'password': password},
    );

    return _asMap(_extractData(response.data));
  }

  Future<void> logout() async {
    await _apiService.post('/mobile/auth/logout');
  }

  Future<Map<String, dynamic>> fetchProfile() async {
    final response = await _apiService.get('/mobile/profile');
    return _asMap(_extractData(response.data));
  }

  Future<Map<String, dynamic>> updateProfile(
    Map<String, dynamic> payload,
  ) async {
    final response = await _apiService.patch('/mobile/profile', data: payload);
    return _asMap(_extractData(response.data));
  }

  Future<List<Map<String, dynamic>>> fetchAddresses() async {
    final response = await _apiService.get('/mobile/addresses');
    return _asMapList(_extractData(response.data));
  }

  Future<Map<String, dynamic>> createAddress(
    Map<String, dynamic> payload,
  ) async {
    final response = await _apiService.post('/mobile/addresses', data: payload);
    return _asMap(_extractData(response.data));
  }

  Future<Map<String, dynamic>> updateAddress({
    required String id,
    required Map<String, dynamic> payload,
  }) async {
    final response = await _apiService.patch(
      '/mobile/addresses/$id',
      data: payload,
    );
    return _asMap(_extractData(response.data));
  }

  Future<void> deleteAddress(String id) async {
    await _apiService.delete('/mobile/addresses/$id');
  }

  Future<Map<String, dynamic>> setDefaultAddress(String id) async {
    final response = await _apiService.post('/mobile/addresses/$id/default');
    return _asMap(_extractData(response.data));
  }

  Future<Map<String, dynamic>> fetchBootstrap({int? branchId}) async {
    final response = await _apiService.get(
      '/mobile/bootstrap',
      queryParameters: branchId == null ? null : {'branch_id': branchId},
    );
    return _asMap(_extractData(response.data));
  }

  /// Fetches currency definitions from the backend / micro-service.
  Future<List<CurrencyModel>> fetchCurrencies() async {
    try {
      final response = await _apiService.get('/mobile/currencies');
      final list = _asMapList(_extractData(response.data));
      if (list.isNotEmpty) {
        return list.map(CurrencyModel.fromJson).toList(growable: false);
      }
    } catch (_) {
      try {
        final response = await _apiService.get('/mobile/currency');
        final data = _extractData(response.data);
        if (data is List) {
          return _asMapList(data)
              .map(CurrencyModel.fromJson)
              .toList(growable: false);
        } else if (data is Map) {
          return [CurrencyModel.fromJson(_asMap(data))];
        }
      } catch (_) {}
    }
    return const [];
  }

  /// Fetches the active system/store currency from the backend / micro-service.
  Future<CurrencyModel?> fetchActiveCurrency() async {
    try {
      final response = await _apiService.get('/mobile/currency');
      final data = _extractData(response.data);
      if (data is Map) {
        return CurrencyModel.fromJson(_asMap(data));
      } else if (data is List && data.isNotEmpty) {
        return CurrencyModel.fromJson(_asMap(data.first));
      }
    } catch (_) {}
    return null;
  }

  Future<List<StoreModel>> fetchBranches() async {
    final response = await _apiService.get('/mobile/branches');
    return _asMapList(
      _extractData(response.data),
    ).map(StoreModel.fromJson).toList(growable: false);
  }

  Future<List<BannerModel>> fetchBanners({int? branchId}) async {
    final response = await _apiService.get(
      '/mobile/banners',
      queryParameters: branchId == null ? null : {'branch_id': branchId},
    );
    return _asMapList(
      _extractData(response.data),
    ).map(BannerModel.fromJson).toList(growable: false);
  }

  Future<List<CategoryModel>> fetchCategories({
    int? branchId,
    String search = '',
    int perPage = 50,
  }) async {
    final response = await _apiService.get(
      '/mobile/categories',
      queryParameters: {
        'per_page': perPage,
        if (branchId != null) 'branch_id': branchId,
        if (search.trim().isNotEmpty) 'search': search.trim(),
      },
    );
    return _asMapList(
      _extractData(response.data),
    ).map(CategoryModel.fromJson).toList(growable: false);
  }

  Future<List<ProductModel>> fetchProducts({
    int? categoryId,
    int? branchId,
    String search = '',
    String sort = 'latest',
    bool featured = false,
    bool newArrival = false,
    bool premium = false,
    int perPage = 100,
  }) async {
    final response = await _apiService.get(
      '/mobile/products',
      queryParameters: {
        'per_page': perPage,
        'sort': sort,
        if (categoryId != null) 'category_id': categoryId,
        if (branchId != null) 'branch_id': branchId,
        if (search.trim().isNotEmpty) 'search': search.trim(),
        if (featured) 'featured': true,
        if (newArrival) 'new_arrival': true,
        if (premium) 'premium': true,
      },
    );

    return _asMapList(
      _extractData(response.data),
    ).map(ProductModel.fromJson).toList(growable: false);
  }

  Future<PaginatedProductsResponse> fetchProductsPaginated({
    int page = 1,
    int perPage = 20,
    int? categoryId,
    int? branchId,
    String search = '',
    String sort = 'latest',
    bool featured = false,
    bool newArrival = false,
    bool premium = false,
  }) async {
    final response = await _apiService.get(
      '/mobile/products',
      queryParameters: {
        'page': page,
        'per_page': perPage,
        'sort': sort,
        if (categoryId != null) 'category_id': categoryId,
        if (branchId != null) 'branch_id': branchId,
        if (search.trim().isNotEmpty) 'search': search.trim(),
        if (featured) 'featured': true,
        if (newArrival) 'new_arrival': true,
        if (premium) 'premium': true,
      },
    );

    final payload = _asMap(response.data);
    if (payload['success'] == false) {
      throw DioException(
        requestOptions: RequestOptions(path: '/mobile/products'),
        response: response,
        message: payload['message']?.toString() ?? 'Failed to load products.',
      );
    }

    final dataList = _asMapList(payload['data']);
    final items = dataList.map(ProductModel.fromJson).toList(growable: false);

    final meta = _asMap(payload['meta']);
    final currentPage = (meta['current_page'] as num?)?.toInt() ?? page;
    final lastPage = (meta['last_page'] as num?)?.toInt() ?? 1;
    final total = (meta['total'] as num?)?.toInt() ?? items.length;
    final perPageResolved = (meta['per_page'] as num?)?.toInt() ?? perPage;

    return PaginatedProductsResponse(
      items: items,
      currentPage: currentPage,
      lastPage: lastPage,
      total: total,
      perPage: perPageResolved,
    );
  }

  Future<ProductModel?> fetchProductById(int id) async {
    try {
      final response = await _apiService.get('/mobile/products/$id');
      final data = _asMap(_extractData(response.data));
      if (data.isNotEmpty) {
        return ProductModel.fromJson(data);
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>> fetchFavorites() async {
    final response = await _apiService.get('/mobile/favorites');
    return _asMap(_extractData(response.data));
  }

  Future<Map<String, dynamic>> toggleFavorite(int itemId) async {
    final response = await _apiService.post(
      '/mobile/favorites/toggle',
      data: {'item_id': itemId},
    );
    return _asMap(_extractData(response.data));
  }

  Future<List<Map<String, dynamic>>> fetchCart() async {
    final response = await _apiService.get('/mobile/cart');
    return _asMapList(_extractData(response.data));
  }

  Future<void> syncCart({required List<Map<String, dynamic>> items}) async {
    await _apiService.post('/mobile/cart/sync', data: {'items': items});
  }

  Future<void> clearCart() async {
    await _apiService.delete('/mobile/cart');
  }

  Future<List<Map<String, dynamic>>> fetchOrders({String search = ''}) async {
    final response = await _apiService.get(
      '/mobile/orders',
      queryParameters: {
        'per_page': 50,
        if (search.trim().isNotEmpty) 'search': search.trim(),
      },
    );
    return _asMapList(_extractData(response.data));
  }

  Future<CartPricingResult> priceCart({
    required List<Map<String, dynamic>> items,
    String currencyMode = 'base',
  }) async {
    final response = await _apiService.post(
      '/mobile/cart/price',
      data: {'currency_mode': currencyMode, 'items': items},
    );
    final data = _asMap(_extractData(response.data));
    return CartPricingResult.fromJson(data);
  }

  Future<Map<String, dynamic>> placeOrder({
    String? addressId,
    required List<Map<String, dynamic>> items,
    String note = '',
    String paymentMethod = 'Cash',
    String deliveryMethod = 'Home Delivery',
    String currencyMode = 'base',
    String saleFrom = 'mobile',
    required double expectedSubtotal,
    required double expectedDiscountTotal,
    required double expectedTotal,
    int? expectedPromotionId,
  }) async {
    final parsedAddressId = (addressId != null && addressId.isNotEmpty)
        ? int.tryParse(addressId)
        : null;

    final response = await _apiService.post(
      '/mobile/orders',
      data: {
        if (parsedAddressId != null && parsedAddressId > 0)
          'address_id': parsedAddressId,
        'items': items,
        if (note.trim().isNotEmpty) 'note': note.trim(),
        'payment_method': paymentMethod,
        'delivery_method': deliveryMethod,
        'currency_mode': currencyMode,
        'sale_from': saleFrom,
        'expected_subtotal': expectedSubtotal,
        'expected_discount_total': expectedDiscountTotal,
        'expected_total': expectedTotal,
        'expected_promotion_id': expectedPromotionId,
      },
    );
    return _asMap(_extractData(response.data));
  }

  Future<List<NotificationModel>> fetchNotifications() async {
    final response = await _apiService.get(
      '/mobile/notifications',
      queryParameters: {'per_page': 50},
    );
    return _asMapList(
      _extractData(response.data),
    ).map(NotificationModel.fromJson).toList(growable: false);
  }

  Future<void> markNotificationRead(int id) async {
    await _apiService.post('/mobile/notifications/$id/read');
  }

  Future<void> markAllNotificationsRead() async {
    await _apiService.post('/mobile/notifications/read-all');
  }

  Future<String?> fetchDefaultAddressId() async {
    final addresses = await fetchAddresses();
    for (final address in addresses) {
      if (address['is_default'] == true) {
        return address['id']?.toString();
      }
    }

    return addresses.isEmpty ? null : addresses.first['id']?.toString();
  }

  Future<Map<String, String>> fetchLegalDocuments() async {
    final response = await _apiService.get('/mobile/legal');
    final data = _asMap(_extractData(response.data));
    return {
      'terms_conditions': data['terms_conditions']?.toString() ?? '',
      'privacy_policy': data['privacy_policy']?.toString() ?? '',
    };
  }

  List<Map<String, dynamic>> _asMapList(dynamic value) {
    if (value is! List) {
      return const <Map<String, dynamic>>[];
    }

    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return <String, dynamic>{};
  }

  dynamic _extractData(dynamic body) {
    final payload = _asMap(body);
    if (payload['success'] == false) {
      throw DioException(
        requestOptions: RequestOptions(path: ''),
        response: Response(
          requestOptions: RequestOptions(path: ''),
          data: body,
          statusCode: 422,
        ),
        message: payload['message']?.toString() ?? 'Request failed.',
      );
    }

    return payload.containsKey('data') ? payload['data'] : payload;
  }
}
