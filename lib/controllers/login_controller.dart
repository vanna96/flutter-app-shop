import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Response;
import 'package:get_storage/get_storage.dart';
import 'package:grocery_app/controllers/notification_controller.dart';
import '../services/api_service.dart';

class LoginController extends GetxController {
  var isLoading = false.obs;
  var email = "".obs;
  var password = "".obs;
  var isAuthenticated = false.obs;

  final box = GetStorage();
  Rxn<Map<String, dynamic>> userData = Rxn<Map<String, dynamic>>();

  final NotificationController notificationController =
  Get.put(NotificationController());

  @override
  void onInit() {
    super.onInit();
    _checkStoredToken();
  }

  void _checkStoredToken() async {
    final storedData = box.read("user");

    if (storedData != null && storedData["token"] != null) {
      try {
        isLoading.value = true;

        Response res = await ApiService().dio.get(
              "/api/notifications",
              options: Options(
                headers: {"Authorization": "Bearer ${storedData['token']}"},
                validateStatus: (status) => status! < 500,
              ),
            );

        if (res.statusCode == 200) {
          isAuthenticated.value = true;
          userData.value = storedData;
        } else {
          isAuthenticated.value = false;
          box.remove("user"); // token invalid, remove
        }
      } catch (e) {
        isAuthenticated.value = false;
        box.remove("user");
      } finally {
        isLoading.value = false;
      }
    } else {
      isAuthenticated.value = false;
    }
  }

  Future<bool> login() async {
    if (email.value.isEmpty || password.value.isEmpty) {
      Get.snackbar(
        "",
        "",
        snackPosition: SnackPosition.BOTTOM, // show at bottom
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
        messageText: Container(
          height: 20, // set your custom height here
          alignment: Alignment.centerLeft,
          child: Text(
            "Email and password are required",
            style: TextStyle(color: Colors.white),
          ),
        ),
        titleText: Container(
          height: 20,
          child: Text(
            "Error",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
      return false;
    }

    try {
      isLoading.value = true;

      Response res = await ApiService().dio.post(
            "/api/auth/login",
            data: {
              "login_type": "phone",
              "username": email.value,
              "password": password.value,
            },
            // Prevent Dio from throwing on non-200 status codes
            options: Options(validateStatus: (status) => status! < 500),
          );

      if (res.statusCode == 200
          // && res.data["success"] == true
          ) {
        // Save token
        box.write("user", res.data['data']);
        userData.value = res.data['data'];
        await notificationController.fetchInitData();
        return true;
      } else {
        // Handle client errors (like 422) here
        Get.snackbar(
          "Login Failed",
          res.data["message"] ?? "Unknown error",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: Duration(seconds: 3),
        );
        return false;
      }
    } on DioError catch (e) {
      // Network error or server error >= 500
      Get.snackbar(
        "Error",
        e.response?.data["message"] ?? e.message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: Duration(seconds: 3),
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
