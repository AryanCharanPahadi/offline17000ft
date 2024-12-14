import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http_parser/http_parser.dart'; // for MediaType
import 'package:offline17000ft/components/custom_appBar.dart';
import 'package:offline17000ft/components/custom_dialog.dart';
import 'package:offline17000ft/components/custom_snackbar.dart';
import 'package:offline17000ft/constants/color_const.dart';
import 'package:offline17000ft/helper/database_helper.dart';
import 'package:offline17000ft/services/network_manager.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import 'in_person_quantitative_controller.dart';

class InPersonQuantitativeSync extends StatefulWidget {
  const InPersonQuantitativeSync({super.key});

  @override
  State<InPersonQuantitativeSync> createState() =>
      _InPersonQuantitativeSyncState();
}

class _InPersonQuantitativeSyncState extends State<InPersonQuantitativeSync> {
  final InPersonQuantitativeController _inPersonQuantitativeController =
      Get.put(InPersonQuantitativeController());
  final NetworkManager _networkManager = Get.put(NetworkManager());
  var isLoading = false.obs;
  var syncProgress = 0.0.obs; // Progress variable for syncing
  var hasError = false.obs; // Variable to track if syncing failed

  @override
  void initState() {
    super.initState();
    _inPersonQuantitativeController.fetchData();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        IconData icon = Icons.check_circle;
        bool shouldExit = await showDialog(
            context: context,
            builder: (_) => Confirmation(
                iconname: icon,
                title: 'Confirm Exit',
                yes: 'Exit',
                no: 'Cancel',
                desc: 'Are you sure you want to Exit?',
                onPressed: () async {
                  Navigator.of(context).pop(true);
                }));
        return shouldExit;
      },
      child: Scaffold(
        appBar: const CustomAppbar(title: 'In Person Quantitative Sync'),
        body: GetBuilder<InPersonQuantitativeController>(
          builder: (inPersonQuantitativeController) {
            if (inPersonQuantitativeController.inPersonQuantitative.isEmpty) {
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
                        const CircularProgressIndicator(
                            color: AppColors.primary),
                        const SizedBox(height: 20),
                        Text(
                          'Syncing: ${(syncProgress.value * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        if (hasError
                            .value) // Show error message if syncing failed
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
                          separatorBuilder: (BuildContext context, int index) =>
                              const Divider(),
                          itemCount: inPersonQuantitativeController
                              .inPersonQuantitative.length,
                          itemBuilder: (context, index) {
                            final item = inPersonQuantitativeController
                                .inPersonQuantitative[index];
                            return ListTile(
                              title: Text(
                                "${index + 1}. Tour ID: ${item.tourId}\n"
                                "School.: ${item.school}\n",
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
                                  color: _networkManager.connectionType.value ==
                                          0
                                      ? Colors
                                          .grey // Grey out the button when offline
                                      : AppColors
                                          .primary, // Regular color when online
                                  icon: const Icon(Icons.sync),
                                  onPressed: _networkManager
                                              .connectionType.value ==
                                          0
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
                                              desc:
                                                  'Are you sure you want to Sync?',
                                              onPressed: () async {
                                                setState(() {
                                                  isLoading.value =
                                                      true; // Show loading spinner
                                                  syncProgress.value =
                                                      0.0; // Reset progress
                                                  hasError.value =
                                                      false; // Reset error state
                                                });

                                                if (_networkManager
                                                            .connectionType
                                                            .value ==
                                                        1 ||
                                                    _networkManager
                                                            .connectionType
                                                            .value ==
                                                        2) {
                                                  // Call the insert function
                                                  var rsp =
                                                      await insertInPersonQuantitativeRecords(
                                                    item.tourId,
                                                    item.school,
                                                    item.udicevalue,
                                                    item.correct_udice,
                                                    item.no_enrolled,
                                                    item.imgpath,
                                                    item.timetable_available,
                                                    item.class_scheduled,
                                                    item.remarks_scheduling,
                                                    item.admin_appointed,
                                                    item.admin_trained,
                                                    item.admin_name,
                                                    item.admin_phone,
                                                    item.sub_teacher_trained,
                                                    item.teacher_ids,
                                                    item.no_staff,
                                                    item.training_pic,
                                                    item.specifyOtherTopics,
                                                    item.practical_demo,
                                                    item.reason_demo,
                                                    item.comments_capacity,
                                                    item.children_comfortable,
                                                    item.children_understand,
                                                    item.post_test,
                                                    item.resolved_doubts,
                                                    item.logs_filled,
                                                    item.filled_correctly,
                                                    item.send_report,
                                                    item.app_installed,
                                                    item.data_synced,
                                                    item.last_syncedDate,
                                                    item.lib_timetable,
                                                    item.timetable_followed,
                                                    item.registered_updated,
                                                    item.observation_comment,
                                                    item.topicsCoveredInTraining,
                                                    item.is_refresher_conduct,
                                                    item.participant_name,
                                                    item.major_issue,
                                                    item.created_at,
                                                    item.submitted_by,
                                                    item.unique_id,
                                                    item.office,
                                                    item.id,
                                                    (progress) {
                                                      syncProgress.value =
                                                          progress; // Update sync progress
                                                    },
                                                  );

                                                  if (rsp['status'] == 1) {
                                                    // After successful sync, stop the loading spinner and show the success message
                                                    setState(() {
                                                      isLoading.value = false;
                                                    });
                                                  } else {
                                                    hasError.value =
                                                        true; // Set error state if sync fails
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
                                        })),
                              onTap: () {
                                inPersonQuantitativeController
                                    .inPersonQuantitative[index].tourId;
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

// Insert Enrollment with multiple image paths handling
var baseurl = "https://mis.17000ft.org/apis/fast_apis/insert_quantitative.php";
Future insertInPersonQuantitativeRecords(
  String? tourId,
  String? school,
  String? udicevalue,
  String? correct_udice,
  String? no_enrolled,
  String? imgpath,
  String? timetable_available,
  String? class_scheduled,
  String? remarks_scheduling,
  String? admin_appointed,
  String? admin_trained,
  String? admin_name,
  String? admin_phone,
  String? sub_teacher_trained,
  String? teacher_ids,
  String? no_staff,
  String? training_pic,
  String? specifyOtherTopics,
  String? practical_demo,
  String? reason_demo,
  String? comments_capacity,
  String? children_comfortable,
  String? children_understand,
  String? post_test,
  String? resolved_doubts,
  String? logs_filled,
  String? filled_correctly,
  String? send_report,
  String? app_installed,
  String? data_synced,
  String? last_syncedDate,
  String? lib_timetable,
  String? timetable_followed,
  String? registered_updated,
  String? observation_comment,
  String? topicsCoveredInTraining,
  String? is_refresher_conduct,
  String? participant_name,
  String? major_issue,
  String? created_at,
  String? submitted_by,
  String? unique_id,
  String? office,
  int? id,
  Function(double) updateProgress, // Progress callback
) async {
  if (kDebugMode) {
    print('This is In person quantitative Data');
  }
  // print('Tour ID: $tourId');
  // print('School: $school');
  // print('UDICE Value: $udicevalue');
  // print('Correct UDICE: $correct_udice');
  // print('No Enrolled: $no_enrolled');
  // print('Image Path: $imgpath');
  // print('Timetable Available: $timetable_available');
  // print('Class Scheduled: $class_scheduled');
  // print('Remarks Scheduling: $remarks_scheduling');
  // print('Admin Appointed: $admin_appointed');
  // print('Admin Trained: $admin_trained');
  // print('Admin Name: $admin_name');
  // print('Admin Phone: $admin_phone');
  // print('Sub Teacher Trained: $sub_teacher_trained');
  // print('Teacher IDs: $teacher_ids');
  // print('No Staff: $no_staff');
  // print('Training Pic: $training_pic');
  // print('Specify Other Topics: $specifyOtherTopics');
  // print('Practical Demo: $practical_demo');
  // print('Reason for Demo: $reason_demo');
  // print('Comments on Capacity: $comments_capacity');
  // print('Children Comfortable: $children_comfortable');
  // print('Children Understand: $children_understand');
  // print('Post Test: $post_test');
  // print('Resolved Doubts: $resolved_doubts');
  // print('Logs Filled: $logs_filled');
  // print('Filled Correctly: $filled_correctly');
  // print('Send Report: $send_report');
  // print('App Installed: $app_installed');
  // print('Data Synced: $data_synced');
  // print('Last Synced Date: $last_syncedDate');
  // print('Library Timetable: $lib_timetable');
  // print('Timetable Followed: $timetable_followed');
  // print('Registered Updated: $registered_updated');
  // print('Observation Comment: $observation_comment');
  // print('Topics Covered in Training: $topicsCoveredInTraining');
  // print('is_refresher_conduct: $is_refresher_conduct');
  // print('Participant Name: $participant_name');
  // print('Major Issue: $major_issue');
  // print('Created At: $created_at');
  // print('Submitted By: $submitted_by');
  // print('Unique ID: $unique_id');
  // print('office Sync: $office');

  var request = http.MultipartRequest(
    'POST',
    Uri.parse(baseurl),
  );
  request.headers["Accept"] = "Application/json";
  // Add form fields with null checks
  request.fields.addAll({
    "tourId": tourId ?? '',
    "school": school ?? '',
    "udicevalue": udicevalue ?? '',
    "correct_udice": correct_udice ?? '',
    "no_enrolled": no_enrolled ?? '',
    "timetable_available": timetable_available ?? '',
    "class_scheduled": class_scheduled ?? '',
    "remarks_scheduling": remarks_scheduling ?? '',
    "admin_appointed": admin_appointed ?? '',
    "admin_trained": admin_trained ?? '',
    "admin_name": admin_name ?? '',
    "admin_phone": admin_phone ?? '',
    "sub_teacher_trained": sub_teacher_trained ?? '',
    "teacher_ids": teacher_ids ?? '',
    "no_staff": no_staff ?? '',
    "specifyOtherTopics": specifyOtherTopics ?? '',
    "practical_demo": practical_demo ?? '',
    "reason_demo": reason_demo ?? '',
    "comments_capacity": comments_capacity ?? '',
    "children_comfortable": children_comfortable ?? '',
    "children_understand": children_understand ?? '',
    "post_test": post_test ?? '',
    "resolved_doubts": resolved_doubts ?? '',
    "logs_filled": logs_filled ?? '',
    "filled_correctly": filled_correctly ?? '',
    "send_report": send_report ?? '',
    "app_installed": app_installed ?? '',
    "data_synced": data_synced ?? '',
    "last_syncedDate": last_syncedDate ?? '',
    "lib_timetable": lib_timetable ?? '',
    "timetable_followed": timetable_followed ?? '',
    "registered_updated": registered_updated ?? '',
    "observation_comment": observation_comment ?? '',
    "topicsCoveredInTraining": topicsCoveredInTraining ?? '',
    "is_refresher_conduct": is_refresher_conduct ?? '',
    "participant_name": participant_name ?? '',
    "major_issue": major_issue ?? '',
    "created_at": created_at ?? '',
    "submitted_by": submitted_by ?? '',
    "unique_id": unique_id ?? '',
    "office": office ?? 'N/A'
  });

  // Convert Base64 back to file and add it to the request for imgpath
  if (imgpath != null && imgpath.isNotEmpty) {
    List<String> imagePaths = imgpath.split(',');

    for (String path in imagePaths) {
      File imageFile = File(path.trim());
      if (imageFile.existsSync()) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'imgpath[]', // Use array-like name for multiple images
            imageFile.path,
            contentType: MediaType('image', 'jpeg'),
          ),
        );
        if (kDebugMode) {
          print("Image file $path attached successfully.");
        }
      } else {
        if (kDebugMode) {
          print('Image file does not exist at the path: $path');
        }
        return {"status": 0, "message": "Image file not found at $path."};
      }
    }
  } else {
    if (kDebugMode) {
      print('No image file path provided.');
    }
  }

// Convert Base64 back to file and add it to the request for training_pic
  // Convert Base64 back to file and add it to the request for imgpath
  if (training_pic != null && training_pic.isNotEmpty) {
    List<String> imagePaths = training_pic.split(',');

    for (String path in imagePaths) {
      File imageFile = File(path.trim());
      if (imageFile.existsSync()) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'training_pic[]', // Use array-like name for multiple images
            imageFile.path,
            contentType: MediaType('image', 'jpeg'),
          ),
        );
        if (kDebugMode) {
          print("Image file $path attached successfully.");
        }
      } else {
        if (kDebugMode) {
          print('Image file does not exist at the path: $path');
        }
        return {"status": 0, "message": "Image file not found at $path."};
      }
    }
  } else {
    if (kDebugMode) {
      print('No image file path provided.');
    }
  }

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
          table: 'inPerson_quantitative',
          field: 'id',
        );
        if (kDebugMode) {
          print("Record with id $id deleted from local database.");
        }

        // Refresh data
        await Get.find<InPersonQuantitativeController>().fetchData();

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
        return {
          "status": 0,
          "message": parsedResponse['message'] ?? 'Failed to insert data'
        };
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
