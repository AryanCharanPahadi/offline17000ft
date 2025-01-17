import 'dart:convert';
import 'dart:io';
import 'package:offline17000ft/forms/fln_observation_form/fln_observation_controller.dart';
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
class FlnObservationSync extends StatefulWidget {
  const FlnObservationSync({super.key});

  @override
  State<FlnObservationSync> createState() => _FlnObservationSyncState();
}

class _FlnObservationSyncState extends State<FlnObservationSync> {
  final FlnObservationController _flnObservationController =
  Get.put(FlnObservationController());  final NetworkManager _networkManager = Get.put(NetworkManager());
  var isLoading = false.obs;
  var syncProgress = 0.0.obs; // Progress variable for syncing
  var hasError = false.obs; // Variable to track if syncing failed

  @override
  void initState() {
    super.initState();
    _flnObservationController.fetchData();
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
        appBar: const CustomAppbar(title: 'FLN Observation Sync'),
        body: GetBuilder<FlnObservationController>(
          builder: (flnObservationController) {
            if (flnObservationController.flnObservationList.isEmpty) {
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
                    itemCount: flnObservationController.flnObservationList.length,
                    itemBuilder: (context, index) {
                      final item = flnObservationController.flnObservationList[index];
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
                                      var rsp = await  insertFlnObservation(
                                        item.tourId,
                                        item.school,
                                        item.udiseValue,
                                        item.correctUdise,
                                        item.noStaffTrained,
                                        item.imgNurTimeTable,
                                        item.imgLKGTimeTable,
                                        item.imgUKGTimeTable,
                                        item.lessonPlanValue,
                                        item.activityValue,
                                        item.imgActivity,
                                        item.imgTLM,
                                        item.baselineValue,
                                        item.baselineGradeReport,
                                        item.flnConductValue,
                                        item.flnGradeReport,
                                        item.imgFLN,
                                        item.refresherValue,
                                        item.numTrainedTeacher,
                                        item.imgTraining,
                                        item.readingValue,
                                        item.libGradeReport,
                                        item.imgLib,
                                        item.methodologyValue,
                                        item.imgClass,
                                        item.observation,
                                        item.created_by,
                                        item.createdAt,
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
                          flnObservationController.flnObservationList[index].tourId;
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
var baseurl = "https://mis.17000ft.org/apis/fast_apis/insert_fln.php";

Future<Map<String, dynamic>> insertFlnObservation(
    String? tourId,
    String? school,
    String? udiseValue,
    String? correctUdise,
    String? noStaffTrained,
    String? imgNurTimeTable,
    String? imgLKGTimeTable,
    String? imgUKGTimeTable,
    String? lessonPlanValue,
    String? activityValue,
    String? imgActivity,
    String? imgTLM,
    String? baselineValue,
    String? baselineGradeReport,
    String? flnConductValue,
    String? flnGradeReport,
    String? imgFLN,
    String? refresherValue,
    String? numTrainedTeacher,
    String? imgTraining,
    String? readingValue,
    String? libGradeReport,
    String? imgLib,
    String? methodologyValue,
    String? imgClass,
    String? observation,
    String? created_by,
    String? createdAt,
    String? office,
    int? id,
    Function(double) updateProgress,
    ) async {
  if (kDebugMode) {
    print('Inserting FLN Observation Data');
  }
  if (kDebugMode) {
    print('tourId: $tourId');
  }
  if (kDebugMode) {
    print('school: $school');
  }
  if (kDebugMode) {
    print('No. of Staff Trained: $noStaffTrained');
  }

  var request = http.MultipartRequest('POST', Uri.parse(baseurl));
  request.headers["Accept"] = "application/json";

  // Add fields
  request.fields.addAll({
    'tourId': tourId ?? '',
    'school': school ?? '',
    'udiseValue': udiseValue ?? '',
    'correctUdise': correctUdise ?? '',
    'noStaffTrained': noStaffTrained ?? '',
    'lessonPlanValue': lessonPlanValue ?? '',
    'activityValue': activityValue ?? '',
    'baselineValue': baselineValue ?? '',
    'baselineGradeReport': baselineGradeReport ?? '',
    'flnConductValue': flnConductValue ?? '',
    'flnGradeReport': flnGradeReport ?? '',
    'refresherValue': refresherValue ?? '',
    'numTrainedTeacher': numTrainedTeacher ?? '',
    'readingValue': readingValue ?? '',
    'libGradeReport': libGradeReport ?? '',
    'methodologyValue': methodologyValue ?? '',
    'observation': observation ?? '',
    'created_by': created_by ?? '',
    'createdAt': createdAt ?? '',
    'office': office ?? '',
  });

// Function to handle image uploads
  Future<void> attachImages(String? imagePaths, String fieldName) async {
    if (imagePaths != null && imagePaths.isNotEmpty) {
      List<String> images = imagePaths.split(',');
      for (String path in images) {
        if (kDebugMode) {
          print('Processing image for field $fieldName: $path');
        } // Debug log

        File imageFile = File(path.trim());
        if (imageFile.existsSync()) {
          request.files.add(
            await http.MultipartFile.fromPath(
              '$fieldName[]', // Use array-like name for multiple images
              imageFile.path,
              contentType: MediaType('image', 'jpeg'),
            ),
          );
          if (kDebugMode) {
            print("Image file $path attached successfully for $fieldName.");
          }
        } else {
          if (kDebugMode) {
            print('Image file does not exist at the path: $path for $fieldName');
          }
          throw Exception("Image file not found at $path for $fieldName.");
        }
      }
    } else {
      if (kDebugMode) {
        print('No image file path provided for $fieldName');
      }
    }
  }

// Attach all image files and handle missing ones
  try {
    await attachImages(imgNurTimeTable, 'imgNurTimeTable');
    await attachImages(imgLKGTimeTable, 'imgLKGTimeTable');
    await attachImages(imgUKGTimeTable, 'imgUKGTimeTable');
    await attachImages(imgActivity, 'imgActivity');
    await attachImages(imgTLM, 'imgTLM');
    await attachImages(imgFLN, 'imgFLN');
    await attachImages(imgTraining, 'imgTraining');
    await attachImages(imgLib, 'imgLib');
    await attachImages(imgClass, 'imgClass');
  } catch (e) {
    if (kDebugMode) {
      print('Error attaching images: $e');
    }
    return {"status": 0, "message": e.toString()};
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
          table: 'flnObservation',
          field: 'id',
        );
        if (kDebugMode) {
          print("Record with id $id deleted from local database.");
        }

        // Refresh data
        await Get.find<FlnObservationController>().fetchData();

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



