import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../components/custom_confirmation.dart';
import 'package:connectivity_plus/connectivity_plus.dart'; // For checking network status

class VersionController extends GetxController {
  var version = ''.obs;
  var isLoading = false.obs;
  final double currentVersion = 4.0;

  @override
  void onInit() {
    super.onInit();
    fetchVersion();
  }

  // Fetch version from API or local storage
  Future<void> fetchVersion() async {
    isLoading(true);
    try {
      // Step 1: Check for network connectivity
      if (!await _isConnected()) {
        if (kDebugMode) {
          print('DEBUG: No internet connection, loading version from local storage.');
        }
        await _loadVersion();
        _checkForUpdate();
        return;
      }

      // Step 2: Fetch version from API
      final response = await http.get(Uri.parse('https://mis.17000ft.org/apis/fast_apis/version.php'));
      if (kDebugMode) {
        print('DEBUG: Status Code: ${response.statusCode}');
      }
      if (kDebugMode) {
        print('DEBUG: Response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        if (data.containsKey('version')) {
          version.value = data['version'] ?? '';
          if (kDebugMode) {
            print('DEBUG: Version from API: ${version.value}');
          }

          // Store the version locally
          await _storeVersion(version.value);

          // Compare versions
          _checkForUpdate();
        } else {
          if (kDebugMode) {
            print('ERROR: "version" field not found in API response.');
          }
        }
      } else {
        if (kDebugMode) {
          print('ERROR: Error fetching version from API: ${response.statusCode}, ${response.body}');
        }
        await _loadVersion();
        _checkForUpdate();
      }
    } catch (e) {
      if (kDebugMode) {
        print('EXCEPTION: Exception during version fetch: $e');
      }
      await _loadVersion();
      _checkForUpdate();
    } finally {
      isLoading(false);
    }
  }

  // Check network connectivity
  Future<bool> _isConnected() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  // Store version in SharedPreferences
  Future<void> _storeVersion(String version) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_version', version);
      if (kDebugMode) {
        print('DEBUG: Version stored locally: $version');
      }
    } catch (e) {
      if (kDebugMode) {
        print('ERROR: Error storing version locally: $e');
      }
    }
  }

  // Load version from SharedPreferences
  Future<void> _loadVersion() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? savedVersion = prefs.getString('app_version');
      if (savedVersion != null) {
        version.value = savedVersion;
        if (kDebugMode) {
          print('DEBUG: Loaded version from local storage: $savedVersion');
        }
      } else {
        if (kDebugMode) {
          print('DEBUG: No version found in local storage.');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('ERROR: Error loading version from local storage: $e');
      }
    }
  }

  // Compare API version with the current version
  void _checkForUpdate() {
    double? apiVersion = double.tryParse(version.value);

    if (apiVersion == null) {
      if (kDebugMode) {
        print('ERROR: Failed to parse API version as a double.');
      }
      return;
    }

    if (kDebugMode) {
      print('DEBUG: Parsed API version as double: $apiVersion');
    }
    if (kDebugMode) {
      print('DEBUG: Current version: $currentVersion');
    }

    if (apiVersion != currentVersion) {
      if (kDebugMode) {
        print('DEBUG: API version is newer than the current version, showing upgrade prompt.');
      }
      showUpgradePrompt();
    } else {
      if (kDebugMode) {
        print('DEBUG: Current version is up-to-date.');
      }
    }
  }

  // Show an upgrade prompt dialog
  void showUpgradePrompt() {
    if (Get.isDialogOpen != true) {
      Get.dialog(
        Confirmation(
          title: "Update Available",
          desc: "A new version of the app is available. Please update to the latest version.",
          onPressed: () {
            if (kDebugMode) {
              print("DEBUG: Navigating to update...");
            } // Handle update action
            // TODO: Add actual navigation or logic for updating the app
          },
          yes: "OK",
          iconname: Icons.update,
        ),
      );
    }
  }
}
