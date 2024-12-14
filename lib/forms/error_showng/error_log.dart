import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../components/custom_appBar.dart';

class ErrorLogsScreen extends StatefulWidget {
  @override
  _ErrorLogsScreenState createState() => _ErrorLogsScreenState();
}

class _ErrorLogsScreenState extends State<ErrorLogsScreen> {
  String? _errorLogs;
  bool _isLoading = true;
  String _errorMessage = "";

  @override
  void initState() {
    super.initState();
    _fetchErrorLogs();
  }

  Future<void> _fetchErrorLogs() async {
    final url =
        Uri.parse('https://mis.17000ft.org/apis/fast_apis/errorlogs.txt');
    try {
      if (kDebugMode) {
        print("Fetching error logs from: $url");
      } // Log the URL
      final response = await http.get(url);

      if (kDebugMode) {
        print(
          "Response status code: ${response.statusCode}");
      } // Log the status code
      if (kDebugMode) {
        print("Response body: ${response.body}");
      } // Log the response body

      if (response.statusCode == 200) {
        final responseBody = response.body.trim();

        // Check if the response is likely an HTML page
        if (responseBody.startsWith('<!DOCTYPE html>') ||
            responseBody.startsWith('<html')) {
          setState(() {
            _errorLogs = null;
            _errorMessage = "";
            _isLoading = false;
          });
          if (kDebugMode) {
            print("API response contains HTML instead of logs.");
          } // Log this case
        } else if (responseBody.isEmpty) {
          setState(() {
            _errorLogs = null;
            _errorMessage = "Nothing is in API.";
            _isLoading = false;
          });
          if (kDebugMode) {
            print("API returned an empty response.");
          } // Log empty response
        } else {
          setState(() {
            _errorLogs = responseBody;
            _isLoading = false;
          });
          if (kDebugMode) {
            print("API logs fetched successfully.");
          } // Log success
        }
      } else {
        setState(() {
          _errorMessage =
              "Failed to load logs. Error code: ${response.statusCode}";
          _isLoading = false;
        });
        if (kDebugMode) {
          print(
            "Failed to fetch logs. Error code: ${response.statusCode}");
        } // Log error
      }
    } catch (e) {
      setState(() {
        _errorMessage = "An error occurred while fetching logs: $e";
        _isLoading = false;
      });
      if (kDebugMode) {
        print("Error occurred while fetching logs: $e");
      } // Log exception
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppbar(title: 'Show Error'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage))
              : _errorLogs != null
                  ? SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        _errorLogs!,
                        style: const TextStyle(fontSize: 14, fontFamily: 'monospace'),
                      ),
                    )
                  : const Center(child: Text('')),
    );
  }
}
