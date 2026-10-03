import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:grocery_app/controllers/app_state_controller.dart';
import 'package:grocery_app/controllers/notification_controller.dart';
import 'package:grocery_app/services/api_service.dart';
import 'package:grocery_app/services/mobile_api_repository.dart';

class LoginController extends GetxController {
  static const String _rememberedCredentialsKey =
      'remembered_login_credentials';

  var isLoading = false.obs;
  var email = "".obs;
  var password = "".obs;
  var isAuthenticated = false.obs;
  var errorMessage = "".obs;
  var isPasswordVisible = false.obs;
  var rememberMe = false.obs;

  final TextEditingController emailTextController = TextEditingController();
  final TextEditingController passwordTextController = TextEditingController();

  final box = GetStorage();
  final MobileApiRepository _mobileApiRepository = MobileApiRepository();
  Rxn<Map<String, dynamic>> userData = Rxn<Map<String, dynamic>>();

  final NotificationController notificationController = Get.put(
    NotificationController(),
  );

  @override
  void onClose() {
    emailTextController.dispose();
    passwordTextController.dispose();
    super.onClose();
  }

  @override
  void onInit() {
    super.onInit();
    _restoreRememberedCredentials();
    _checkStoredToken();
  }

  void setRememberMe(bool value) {
    rememberMe.value = value;
    if (!value) {
      box.remove(_rememberedCredentialsKey);
    }
  }

  void _restoreRememberedCredentials() {
    final stored = box.read(_rememberedCredentialsKey);
    if (stored is! Map) {
      rememberMe.value = false;
      return;
    }

    final username = stored['username']?.toString() ?? '';
    final savedPassword = stored['password']?.toString() ?? '';
    if (username.isEmpty || savedPassword.isEmpty) {
      rememberMe.value = false;
      box.remove(_rememberedCredentialsKey);
      return;
    }

    rememberMe.value = true;
    email.value = username;
    password.value = savedPassword;
    emailTextController.text = username;
    passwordTextController.text = savedPassword;
  }

  Future<void> _checkStoredToken() async {
    final storedData = box.read("user");

    if (storedData != null && storedData["token"] != null) {
      isAuthenticated.value = true;
      final normalizedUser = _normalizeUser(
        Map<String, dynamic>.from(storedData),
      );
      userData.value = normalizedUser;
      await box.write("user", normalizedUser);
      ApiService().refreshConfig();
      await _loadRemoteUserData(showError: false);
      await notificationController.fetchInitData();
    } else {
      isAuthenticated.value = false;
    }
  }

  Future<bool> login() async {
    errorMessage.value = "";

    final username = emailTextController.text.trim().isNotEmpty
        ? emailTextController.text.trim()
        : email.value.trim();
    final pwd = passwordTextController.text.isNotEmpty
        ? passwordTextController.text
        : password.value;

    email.value = username;
    password.value = pwd;

    if (username.isEmpty || pwd.isEmpty) {
      errorMessage.value = "Email / Username and password are required.";
      return false;
    }

    try {
      isLoading.value = true;

      final loginData = await _mobileApiRepository.login(
        username: username,
        password: pwd,
      );
      final user = {
        ..._normalizeUser(
          Map<String, dynamic>.from(
            loginData['user'] as Map? ?? <String, dynamic>{},
          ),
        ),
        'token': loginData['token']?.toString() ?? '',
      };

      await box.write("user", user);
      if (rememberMe.value) {
        await box.write(_rememberedCredentialsKey, {
          'username': username,
          'password': pwd,
        });
      } else {
        await box.remove(_rememberedCredentialsKey);
      }
      userData.value = user;
      isAuthenticated.value = true;
      errorMessage.value = "";
      emailTextController.clear();
      passwordTextController.clear();
      email.value = "";
      password.value = "";
      ApiService().refreshConfig();
      await _loadRemoteUserData(showError: false);

      if (Get.isRegistered<AppStateController>()) {
        await Get.find<AppStateController>().syncRemoteState();
      }

      await notificationController.fetchInitData();
      return true;
    } on DioException catch (e) {
      errorMessage.value = _extractErrorMessage(e);
      return false;
    } catch (e) {
      errorMessage.value = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Map<String, dynamic> get currentUser =>
      Map<String, dynamic>.from(userData.value ?? <String, dynamic>{});

  String get displayName {
    final user = currentUser;
    final fullName = user['full_name']?.toString().trim() ?? '';
    if (fullName.isNotEmpty) {
      return fullName;
    }

    final name = user['name']?.toString().trim() ?? '';
    if (name.isNotEmpty) {
      return name;
    }

    final customer = user['customer'] as Map<String, dynamic>?;
    final firstName = customer?['first_name']?.toString() ?? '';
    final lastName = customer?['last_name']?.toString() ?? '';
    final customerName = '$firstName $lastName'.trim();
    if (customerName.isNotEmpty) {
      return customerName;
    }

    final username = user['username']?.toString().trim() ?? '';
    return username.isNotEmpty ? username : 'User';
  }

  List<Map<String, dynamic>> get addresses {
    final rawAddresses = currentUser['addresses'];
    if (rawAddresses is! List) {
      return <Map<String, dynamic>>[];
    }

    return rawAddresses
        .whereType<Map>()
        .map((address) => Map<String, dynamic>.from(address))
        .toList(growable: false);
  }

  Map<String, dynamic>? get defaultAddress {
    for (final address in addresses) {
      if (address['is_default'] == true) {
        return address;
      }
    }

    return addresses.isEmpty ? null : addresses.first;
  }

  Future<void> updateProfile({
    required String name,
    required String firstName,
    required String lastName,
    required String username,
    required String email,
    required String gender,
    required String countryCode,
    required String phone,
    String? password,
    String? profileBase64,
    required String dob,
  }) async {
    final cleanFirst = firstName.trim();
    final cleanLast = lastName.trim();
    final cleanName = name.trim();
    final cleanEmail = email.trim();
    final cleanPhone = phone.trim();
    final cleanDob = dob.trim();
    final cleanCountryCode = countryCode.trim();

    final resolvedName = cleanName.isNotEmpty
        ? cleanName
        : '$cleanFirst $cleanLast'.trim();

    final payload = <String, dynamic>{
      'name': resolvedName.isNotEmpty ? resolvedName : username.trim(),
      'first_name': cleanFirst.isNotEmpty ? cleanFirst : null,
      'last_name': cleanLast.isNotEmpty ? cleanLast : null,
      'username': username.trim(),
      'email': cleanEmail.isNotEmpty ? cleanEmail : null,
      'gender': gender == 'Other' ? 'Female' : gender,
      'country_code': cleanCountryCode.isNotEmpty ? cleanCountryCode : null,
      'phone': cleanPhone.isNotEmpty ? cleanPhone : null,
      if (password?.trim().isNotEmpty == true) 'password': password!.trim(),
      if (profileBase64?.trim().isNotEmpty == true) 'profile': profileBase64,
      'dob': cleanDob.isNotEmpty ? cleanDob : null,
    };

    final updatedProfile = await _mobileApiRepository.updateProfile(payload);

    final updatedUser = {
      ...currentUser,
      ...updatedProfile,
      'name': resolvedName.isNotEmpty
          ? resolvedName
          : (updatedProfile['name'] ?? currentUser['name']),
      'full_name': resolvedName.isNotEmpty
          ? resolvedName
          : (updatedProfile['name'] ?? currentUser['name']),
      'first_name': cleanFirst.isNotEmpty
          ? cleanFirst
          : (updatedProfile['first_name'] ?? currentUser['first_name'] ?? ''),
      'last_name': cleanLast.isNotEmpty
          ? cleanLast
          : (updatedProfile['last_name'] ?? currentUser['last_name'] ?? ''),
      'username': username.trim(),
      'email': cleanEmail,
      'gender': gender,
      'country_code': cleanCountryCode,
      'phone': cleanPhone,
      'dob': cleanDob,
      if (password?.trim().isNotEmpty == true) 'password': password!.trim(),
    };

    await _saveUser(updatedUser);
  }

  Future<void> addAddress({
    required String label,
    required String recipientName,
    required String countryCode,
    required String phone,
    required String line1,
    required String city,
    required String note,
    required bool isDefault,
  }) async {
    await _mobileApiRepository.createAddress({
      'label': label.trim(),
      'recipient_name': recipientName.trim(),
      'country_code': countryCode.trim(),
      'phone': phone.trim(),
      'address_line': line1.trim(),
      'city': city.trim(),
      'note': note.trim(),
      'is_default': isDefault || addresses.isEmpty,
    });
    await _refreshAddresses();
  }

  Future<void> updateAddress({
    required String id,
    required String label,
    required String recipientName,
    required String countryCode,
    required String phone,
    required String line1,
    required String city,
    required String note,
    required bool isDefault,
  }) async {
    await _mobileApiRepository.updateAddress(
      id: id,
      payload: {
        'label': label.trim(),
        'recipient_name': recipientName.trim(),
        'country_code': countryCode.trim(),
        'phone': phone.trim(),
        'address_line': line1.trim(),
        'city': city.trim(),
        'note': note.trim(),
        'is_default': isDefault || addresses.length == 1,
      },
    );
    await _refreshAddresses();
  }

  Future<void> deleteAddress(String id) async {
    await _mobileApiRepository.deleteAddress(id);
    await _refreshAddresses();
  }

  Future<void> setDefaultAddress(String id) async {
    await _mobileApiRepository.setDefaultAddress(id);
    await _refreshAddresses();
  }

  Future<void> logout() async {
    try {
      await _mobileApiRepository.logout();
    } catch (_) {}

    await box.remove("user");
    await box.remove("favorite_ids");
    await box.remove("order_history");
    userData.value = null;
    isAuthenticated.value = false;
    email.value = "";
    password.value = "";
    errorMessage.value = "";
    emailTextController.clear();
    passwordTextController.clear();
    _restoreRememberedCredentials();
    notificationController.notifications.clear();
    if (Get.isRegistered<AppStateController>()) {
      final appStateController = Get.find<AppStateController>();
      appStateController.favoriteIds.clear();
      appStateController.orderHistory.clear();
      appStateController.discardCart();
    }
    ApiService().refreshConfig();
  }

  Future<void> _refreshAddresses() async {
    final remoteAddresses = await _mobileApiRepository.fetchAddresses();
    await _saveAddresses(remoteAddresses);
  }

  Future<void> _saveAddresses(List<Map<String, dynamic>> nextAddresses) async {
    final updatedUser = {
      ...currentUser,
      'addresses': _normalizeAddresses(
        nextAddresses,
        fallbackName: displayName.ifEmpty('Demo Shopper'),
        fallbackCountryCode: currentUser['country_code']?.toString() ?? '+855',
        fallbackPhone: currentUser['phone']?.toString() ?? '',
      ),
    };

    await _saveUser(updatedUser);
  }

  Future<void> _saveUser(Map<String, dynamic> nextUser) async {
    final normalizedUser = _normalizeUser(nextUser);
    userData.value = normalizedUser;
    userData.refresh();
    await box.write("user", normalizedUser);
  }

  Map<String, dynamic> _normalizeUser(Map<String, dynamic> source) {
    final normalizedUser = Map<String, dynamic>.from(source);
    final firstName = source['first_name']?.toString().trim() ?? '';
    final lastName = source['last_name']?.toString().trim() ?? '';
    final customer = source['customer'] is Map
        ? Map<String, dynamic>.from(source['customer'] as Map)
        : <String, dynamic>{};

    if (firstName.isNotEmpty) {
      customer['first_name'] = firstName;
    }
    if (lastName.isNotEmpty) {
      customer['last_name'] = lastName;
    }
    normalizedUser['customer'] = customer;

    final derivedFirst = firstName.isNotEmpty
        ? firstName
        : (customer['first_name']?.toString().trim() ?? '');
    final derivedLast = lastName.isNotEmpty
        ? lastName
        : (customer['last_name']?.toString().trim() ?? '');

    final sourceName = source['name']?.toString().trim() ?? '';
    final sourceFullName = source['full_name']?.toString().trim() ?? '';

    final resolvedName = sourceName.isNotEmpty
        ? sourceName
        : (sourceFullName.isNotEmpty
              ? sourceFullName
              : ('$derivedFirst $derivedLast'.trim().ifEmpty('User')));

    normalizedUser['name'] = resolvedName;
    normalizedUser['full_name'] = resolvedName;
    normalizedUser['first_name'] = derivedFirst;
    normalizedUser['last_name'] = derivedLast;
    normalizedUser['country_code'] =
        normalizedUser['country_code']?.toString() ?? '+855';
    normalizedUser['phone'] = normalizedUser['phone']?.toString() ?? '';
    normalizedUser['addresses'] = _normalizeAddresses(
      normalizedUser['addresses'],
      fallbackName: resolvedName,
      fallbackCountryCode: normalizedUser['country_code']!.toString(),
      fallbackPhone: normalizedUser['phone']!.toString(),
    );

    return normalizedUser;
  }

  List<Map<String, dynamic>> _normalizeAddresses(
    dynamic rawAddresses, {
    required String fallbackName,
    required String fallbackCountryCode,
    required String fallbackPhone,
  }) {
    if (rawAddresses == null || rawAddresses is! List) {
      return const <Map<String, dynamic>>[];
    }

    if (rawAddresses.isEmpty) {
      return <Map<String, dynamic>>[];
    }

    final normalizedAddresses = <Map<String, dynamic>>[];
    var hasDefault = false;

    for (var index = 0; index < rawAddresses.length; index++) {
      final rawAddress = rawAddresses[index];
      if (rawAddress is! Map) {
        continue;
      }

      final address = Map<String, dynamic>.from(rawAddress);
      final isDefault = address['is_default'] == true;
      hasDefault = hasDefault || isDefault;

      normalizedAddresses.add({
        'id': address['id']?.toString() ?? 'addr_${index + 1}',
        'label':
            address['label']?.toString().trim().ifEmpty(
              'Address ${index + 1}',
            ) ??
            'Address ${index + 1}',
        'recipient_name':
            address['recipient_name']?.toString().trim().ifEmpty(
              fallbackName,
            ) ??
            fallbackName,
        'country_code':
            address['country_code']?.toString().trim().ifEmpty(
              address['code']?.toString().trim().ifEmpty(fallbackCountryCode) ??
                  fallbackCountryCode,
            ) ??
            fallbackCountryCode,
        'phone':
            address['phone']?.toString().trim().ifEmpty(fallbackPhone) ??
            fallbackPhone,
        'line_1':
            address['line_1']?.toString().trim().ifEmpty(
              address['address_line']?.toString().trim().ifEmpty(
                    'Address line',
                  ) ??
                  'Address line',
            ) ??
            'Address line',
        'city':
            address['city']?.toString().trim().ifEmpty('Phnom Penh') ??
            'Phnom Penh',
        'note': address['note']?.toString().trim() ?? '',
        'is_default': isDefault,
      });
    }

    if (normalizedAddresses.isNotEmpty && !hasDefault) {
      normalizedAddresses.first['is_default'] = true;
    }

    return normalizedAddresses;
  }

  Future<void> _loadRemoteUserData({required bool showError}) async {
    try {
      final profile = await _mobileApiRepository.fetchProfile();
      final remoteAddresses = await _mobileApiRepository.fetchAddresses();
      await _saveUser({
        ...currentUser,
        ...profile,
        'addresses': remoteAddresses,
      });
    } on DioException catch (e) {
      if (!showError) {
        return;
      }

      Get.snackbar(
        "Error",
        _extractErrorMessage(e),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }

  String extractErrorMessage(dynamic exception) {
    if (exception is! DioException) {
      return exception.toString().replaceFirst('Exception: ', '');
    }
    return _extractErrorMessage(exception);
  }

  String _extractErrorMessage(DioException exception) {
    dynamic data = exception.response?.data;
    if (data is String) {
      try {
        data = jsonDecode(data);
      } catch (_) {}
    }

    if (data is Map) {
      if (data['message'] != null &&
          data['message'].toString().trim().isNotEmpty) {
        return data['message'].toString();
      }

      if (data['errors'] is Map && (data['errors'] as Map).isNotEmpty) {
        final firstError = (data['errors'] as Map).values.first;
        if (firstError is List && firstError.isNotEmpty) {
          return firstError.first.toString();
        } else if (firstError != null) {
          return firstError.toString();
        }
      }
      if (data['error'] != null) {
        return data['error'].toString();
      }
    }

    final statusCode = exception.response?.statusCode;
    if (statusCode == 401) {
      return 'Invalid username or password.';
    } else if (statusCode == 403) {
      return 'Access denied. Account may be inactive or unauthorized.';
    } else if (statusCode == 404) {
      return 'Authentication endpoint not found. Please check server settings.';
    } else if (statusCode == 422) {
      return 'Invalid credentials provided.';
    } else if (statusCode != null && statusCode >= 500) {
      return 'Server error ($statusCode). Please try again later.';
    }

    if (exception.type == DioExceptionType.connectionTimeout ||
        exception.type == DioExceptionType.receiveTimeout ||
        exception.type == DioExceptionType.sendTimeout) {
      return 'Connection timed out. Please check your internet or server.';
    } else if (exception.type == DioExceptionType.connectionError) {
      return 'Could not connect to server. Please check your network and settings.';
    }

    return exception.message ?? 'Login failed. Please try again.';
  }
}

extension on String {
  String ifEmpty(String fallback) => trim().isEmpty ? fallback : this;
}
