import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../helper/shared_prefernce.dart';

class UserController extends GetxController {
  var username = ''.obs;
  var officeName = ''.obs;
  var offlineVersion = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadUserData(); // Load user data when the controller is initialized
  }

  // Load user data from shared preferences
  Future<void> loadUserData() async {
    if (kDebugMode) {
      print("Loading user data...");
    }
    try {
      var userData = await SharedPreferencesHelper.getUserData();
      if (userData != null && userData['user'] != null) {
        username.value = userData['user']['username']?.toUpperCase() ?? '';
        officeName.value = userData['user']['office_name'] ?? '';
        offlineVersion.value = userData['user']['offline_version'] ?? '';

        if (kDebugMode) {
          print("Username: ${username.value}");
        }
        if (kDebugMode) {
          print("Office Name: ${officeName.value}");
        }
        if (kDebugMode) {
          print("Offline Version: ${offlineVersion.value}");
        }
      } else {
        if (kDebugMode) {
          print("No user data found.");
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error loading user data: $e");
      }
    }
  }

  // Clear user data on logout
  void clearUserData() {
    if (kDebugMode) {
      print("Clearing user data...");
    }
    username.value = '';
    officeName.value = '';
    offlineVersion.value = '';
    if (kDebugMode) {
      print("User data cleared.");
    }
  }
}
