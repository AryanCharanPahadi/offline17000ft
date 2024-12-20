import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:offline17000ft/base_client/app_exception.dart';
import 'package:offline17000ft/base_client/base_client.dart';
import 'package:offline17000ft/helper/database_helper.dart';
import 'package:offline17000ft/tourDetails/tour_model.dart';

class ApiService {
  final String baseUrl = 'https://mis.17000ft.org/apis/fast_apis/';
  List<TourDetails> _tourList = <TourDetails>[]; // Explicit type annotation
  List<TourDetails> get tourList => _tourList;

  // Fetch tour ids
  Future<List<TourDetails>> fetchTourIds(String? office) async {
    if (kDebugMode) {
      print('Fetching Tour IDs for office: $office');
    }
    _tourList = [];

    var request = {'office': office ?? ''};
    if (kDebugMode) {
      print('Request payload: $request');
    }

    dynamic response; // Or use Map<String, dynamic>?
    try {
      response = await BaseClient().post(baseUrl, 'tourIds.php', request);
      if (kDebugMode) {
        print('Response received: $response');
      }
    } catch (error) {
      if (error is BadRequestException) {
        // Decode and print the API error
        var apiError = json.decode(error.message!);
        if (kDebugMode) {
          print('API Error: $apiError');
        }
      } else {
        // Print other errors
        if (kDebugMode) {
          print('An unexpected error occurred: ${error.toString()}');
        }
      }
      return []; // Return an empty list on error
    }

    if (response == null) {
      if (kDebugMode) {
        print('No response received from the API.');
      }
      return [];
    }

    try {
      _tourList = tourDetailsFromJson(response);
      if (kDebugMode) {
        print('Parsed tour details: $_tourList');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error parsing response to TourDetails: $e');
      }
      return []; // Return an empty list if parsing fails
    }

    // Check if there are any tour details to write to the local database
    if (_tourList.isNotEmpty) {
      if (kDebugMode) {
        print('Deleting existing tour details from the local database...');
      }
      try {
        await SqfliteDatabaseHelper().delete('tour_details');
        for (var tour in _tourList) {
          if (kDebugMode) {
            print('Adding tour detail to local database: $tour');
          }
          await LocalDbController().addData(tourDetails: tour);
        }
        if (kDebugMode) {
          print('All tour details saved to local database.');
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error saving tour details to local database: $e');
        }
      }
    }

    return _tourList; // Return the list, whether empty or populated
  }

  // Clear tour details upon logout
  Future<void> clearTourDetailsOnLogout() async {
    if (kDebugMode) {
      print('Clearing tour details on logout...');
    }
    try {
      await SqfliteDatabaseHelper()
          .delete('tour_details'); // Clear from local DB
      _tourList.clear(); // Clear in-memory list
      if (kDebugMode) {
        print('Tour details cleared.');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing tour details on logout: $e');
      }
    }
  }

  // Refresh tour details on login
  Future<void> refreshTourDetailsOnLogin(String? office) async {
    if (kDebugMode) {
      print('Refreshing tour details on login...');
    }
    await fetchTourIds(office); // Fetch fresh data and update local storage
  }
}
