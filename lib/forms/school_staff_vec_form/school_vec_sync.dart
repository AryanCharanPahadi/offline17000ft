import 'dart:convert';
import 'package:offline17000ft/forms/school_staff_vec_form/school_vec_controller.dart';
import 'package:offline17000ft/components/custom_appBar.dart';
import 'package:offline17000ft/components/custom_dialog.dart';
import 'package:offline17000ft/components/custom_snackbar.dart';
import 'package:offline17000ft/constants/color_const.dart';
import 'package:offline17000ft/helper/database_helper.dart';
import 'package:offline17000ft/home/home_screen.dart';
import 'package:offline17000ft/services/network_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
class SchoolStaffVecSync extends StatefulWidget {
  const SchoolStaffVecSync({super.key});

  @override
  State<SchoolStaffVecSync> createState() => _SchoolStaffVecSyncState();
}

class _SchoolStaffVecSyncState extends State<SchoolStaffVecSync> {
  final _schoolStaffVecController = Get.put(SchoolStaffVecController());
  final NetworkManager _networkManager = Get.put(NetworkManager());
  var isLoading = false.obs;
  var syncProgress = 0.0.obs; // Progress variable for syncing
  var hasError = false.obs; // Variable to track if syncing failed

  @override
  void initState() {
    super.initState();
    _schoolStaffVecController.fetchData();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        showDialog(
          context: context,
          builder: (_) => Confirmation(
            iconname: Icons.check_circle,
            title: 'Exit Confirmation',
            yes: 'Yes',
            no: 'No',
            desc: 'Are you sure you want to leave?',
            onPressed: () {
              Navigator.of(context).pop(true);

            },
          ),
        );
      },
      child: Scaffold(
        appBar: const CustomAppbar(title: 'School Staff & SMC/VEC Details'),
        body: GetBuilder<SchoolStaffVecController>(
          builder: (schoolStaffVecController) {
            if (schoolStaffVecController.schoolStaffVecList.isEmpty) {
              return const Center(
                child: Text(
                  'No Records Found',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary),
                ),
              );
            }

            return Obx(() => isLoading.value
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: AppColors.primary),
                  const SizedBox(height: 20),
                  Text(
                    'Syncing: ${(syncProgress.value * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  if (hasError.value) // Show error message if syncing failed
                    const Text(
                      'Syncing failed. Please try again.',
                      style: TextStyle(color: Colors.red, fontSize: 16),
                    ),
                ],
              ),
            )
                : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    separatorBuilder: (BuildContext context, int index) => const Divider(),
                    itemCount: schoolStaffVecController.schoolStaffVecList.length,
                    itemBuilder: (context, index) {
                      final item = schoolStaffVecController.schoolStaffVecList[index];
                      return ListTile(
                        title:  Text(
                          "${index + 1}. Tour ID: ${item.tourId}\n"
                              "School.: ${item.school}\n"
                          ,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold),
                          textAlign: TextAlign
                              .left, // Adjust text alignment if needed
                          maxLines:
                          3, // Limit the lines, or remove this if you don't want a limit
                          overflow: TextOverflow
                              .ellipsis, // Handles overflow gracefully
                        ),
                        trailing: Obx(() => IconButton(
                            color: _networkManager.connectionType.value == 0
                                ? Colors.grey  // Grey out the button when offline
                                : AppColors.primary,  // Regular color when online
                            icon: const Icon(Icons.sync),
                            onPressed: _networkManager.connectionType.value == 0
                                ? null // Disable the button when offline
                                : () async {
                              // Proceed with sync logic when online
                              IconData icon = Icons.check_circle;
                              showDialog(
                                context: context,
                                builder: (_) => Confirmation(
                                  iconname: icon,
                                  title: 'Confirm',
                                  yes: 'Confirm',
                                  no: 'Cancel',
                                  desc: 'Are you sure you want to Sync?',
                                  onPressed: () async {
                                    setState(() {
                                      isLoading.value = true; // Show loading spinner
                                      syncProgress.value = 0.0; // Reset progress
                                      hasError.value = false; // Reset error state
                                    });

                                    if (_networkManager.connectionType.value == 1 ||
                                        _networkManager.connectionType.value == 2) {

                                      // Call the insert function
                                      var rsp = await insertSchoolStaffVec(
                                        item.tourId,
                                        item.school,
                                        item.udiseValue,
                                        item.correctUdise,
                                        item.headName,
                                        item.headGender,
                                        item.headMobile,
                                        item.headEmail,
                                        item.headDesignation,
                                        item.totalTeachingStaff,
                                        item.totalNonTeachingStaff,
                                        item.totalStaff,
                                        item.smcVecName,
                                        item.genderVec,
                                        item.vecMobile,
                                        item.vecEmail,
                                        item.vecQualification,
                                        item.vecTotal,
                                        item.meetingDuration,
                                        item.createdBy,
                                        item.createdAt,
                                        item.other,
                                        item.otherQual,
                                        item.office,
                                        item.id,

                                        (progress) {
                                          syncProgress.value = progress; // Update sync progress
                                        },
                                      );

                                      if (rsp['status'] == 1) {
                                        // After successful sync, stop the loading spinner and show the success message
                                        setState(() {
                                          isLoading.value = false;
                                        });
                                      } else {
                                        hasError.value = true; // Set error state if sync fails
                                        customSnackbar(
                                          "Error",
                                          "${rsp['message']}",
                                          AppColors.error,
                                          AppColors.onError,
                                          Icons.warning,
                                        );
                                        setState(() {
                                          isLoading.value = false;
                                        });
                                      }
                                    }
                                  },
                                ),
                              );
                            }

                        )),
                        onTap: () {
                          schoolStaffVecController.schoolStaffVecList[index].tourId;
                        },
                      );
                    },
                  ),
                ),
              ],
            ));
          },
        ),
      ),
    );
  }
}


var baseurl = "https://mis.17000ft.org/apis/fast_apis/insert_vec.php";
Future insertSchoolStaffVec(
    String? tourId,
    String? school,
    String? udiseValue,
    String? correctUdise,
    String? headName,
    String? headGender,
    String? headMobile,
    String? headEmail,
    String? headDesignation,
    String? totalTeachingStaff,
    String? totalNonTeachingStaff,
    String? totalStaff,
    String? smcVecName,
    String? genderVec,
    String? vecMobile,
    String? vecEmail,
    String? vecQualification,
    String? vecTotal,
    String? meetingDuration,
    String? createdBy,
    String? createdAt,
    String? other,
    String? otherQual,
    String? office,
    int? id,
    Function(double) updateProgress, // Progress callback
    ) async {
  if(kDebugMode) {
    print('This is enrolment data:');
    print('tourId: $tourId');
    print('school: $school');
    print('udiseValue: $udiseValue');
    print('correctUdise: $correctUdise');
    print('headName: $headName');
    print('headGender: $headGender');
    print('headMobile: $headMobile');
    print('headEmail: $headEmail');
    print('headDesignation: $headDesignation');
    print('totalTeachingStaff: $totalTeachingStaff');
    print('totalNonTeachingStaff: $totalNonTeachingStaff');
    print('totalStaff: $totalStaff');
    print('SmcVecName: $smcVecName');
    print('genderVec: $genderVec');
    print('vecMobile: $vecMobile');
    print('vecEmail: $vecEmail');
    print('vecQualification: $vecQualification');
    print('vecTotal: $vecTotal');
    print('meetingDuration: $meetingDuration');
    print('createdBy: $createdBy');
    print('createdAt: $createdAt');
    print('other: $other');
    print('otherQual: $otherQual');
    print('Office Sync: $office');
    print('id: $id');
  }
  var request = http.MultipartRequest(
    'POST',
    Uri.parse(baseurl),
  );

  // Set headers
  request.headers["Accept"] = "Application/json";

  // Add text fields
  request.fields.addAll({
    'tourId': tourId ?? '',
    'school': school ?? '',
    'udiseValue': udiseValue ?? '',
    'correctUdise': correctUdise ?? '',
    'headName': headName ?? '',
    'headGender': headGender ?? '',
    'headMobile': headMobile ?? '',
    'headEmail': headEmail ?? '',
    'headDesignation': headDesignation ?? '',
    'totalTeachingStaff': totalTeachingStaff?.toString() ?? '',
    'totalNonTeachingStaff': totalNonTeachingStaff?.toString() ?? '',
    'totalStaff': totalStaff?.toString() ?? '',
    'SmcVecName': smcVecName ?? '',
    'genderVec': genderVec ?? '',
    'vecMobile': vecMobile ?? '',
    'vecEmail': vecEmail ?? '',
    'vecQualification': vecQualification ?? '',
    'vecTotal': vecTotal ?? '',
    'meetingDuration': meetingDuration ?? '',
    'createdBy': createdBy ?? '',
    'createdAt': createdAt ?? '',
    'other': other ?? '',
    'otherQual': otherQual ?? '',
    'office': office ?? 'N/A',
    'id': id?.toString() ?? '', // Convert the integer ID to a string
  });


  // Send the request to the server
  var response = await request.send();
  var responseBody = await response.stream.bytesToString();

  if (kDebugMode) {
    print('Server Response Body: $responseBody');
  }

  if (response.statusCode == 200) {
    try {
      var parsedResponse = json.decode(responseBody);
      if (parsedResponse['status'] == 1) {
        // Delete local record if sync is successful
        await SqfliteDatabaseHelper().queryDelete(
          arg: id.toString(),
          table: 'schoolStaffVec',
          field: 'id',
        );
        if (kDebugMode) {
          print("Record with id $id deleted from local database.");
        }

        // Refresh data
        await Get.find<SchoolStaffVecController>().fetchData();

        // Show success message after syncing
        customSnackbar(
          'Successfully',
          "${parsedResponse['message']}",
          AppColors.secondary,
          AppColors.onSecondary,
          Icons.check,
        );

        return parsedResponse;
      } else {
        if (kDebugMode) {
          print('Error: ${parsedResponse['message']}');
        }
        customSnackbar(
          "Error",
          "${parsedResponse['message']}",
          AppColors.error,
          AppColors.onError,
          Icons.warning,
        );
        return {"status": 0, "message": parsedResponse['message'] ?? 'Failed to insert data'};
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error parsing response: $e');
      }
      return {"status": 0, "message": "Invalid response format"};
    }
  } else {
    if (kDebugMode) {
      print('Server error: ${response.statusCode}');
    }
    return {"status": 0, "message": "Server returned error $responseBody"};
  }
}



void showLoaderDialog(BuildContext context, double progress) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => AlertDialog(
      content: Row(
        children: [
          CircularProgressIndicator(value: progress),
          const SizedBox(width: 20),
          Text("Uploading... ${(progress * 100).toStringAsFixed(0)}%"),
        ],
      ),
    ),
  );
}