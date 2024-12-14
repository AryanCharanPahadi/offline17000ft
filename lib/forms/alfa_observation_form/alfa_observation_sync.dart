import 'dart:convert';
import 'dart:io';
import 'package:http_parser/http_parser.dart'; // for MediaType
import 'package:offline17000ft/components/custom_appBar.dart';
import 'package:offline17000ft/components/custom_dialog.dart';
import 'package:offline17000ft/components/custom_snackbar.dart';
import 'package:offline17000ft/constants/color_const.dart';
import 'package:offline17000ft/helper/database_helper.dart';
import 'package:offline17000ft/services/network_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'alfa_observation_controller.dart';

class AlfaObservationSync extends StatefulWidget {
  const AlfaObservationSync({super.key});

  @override
  State<AlfaObservationSync> createState() => _AlfaObservationSync();
}

class _AlfaObservationSync extends State<AlfaObservationSync> {
  final AlfaObservationController _alfaObservationController =
      Get.put(AlfaObservationController());
  final NetworkManager _networkManager = Get.put(NetworkManager());
  var isLoading = false.obs;
  var syncProgress = 0.0.obs; // Progress variable for syncing
  var hasError = false.obs; // Variable to track if syncing failed

  @override
  void initState() {
    super.initState();
    _alfaObservationController.fetchData();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        IconData icon = Icons.check_circle;
        bool? shouldExit = await showDialog<bool>(
          context: context,
          builder: (_) => Confirmation(
            iconname: icon,
            title: 'Exit Confirmation',
            yes: 'Yes',
            no: 'No',
            desc: 'Are you sure you want to leave?',
            onPressed: () {
              Navigator.of(context).pop(true); // User confirms exit
            },
          ),
        );

        return shouldExit ?? false; // Default to false if shouldExit is null
      },
      child: Scaffold(
        appBar: const CustomAppbar(title: 'Alfa Observation Sync'),
        body: GetBuilder<AlfaObservationController>(
          builder: (alfaObservationController) {
            if (alfaObservationController.alfaObservationList.isEmpty) {
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
                      ],
                    ),
                  )
                : Column(
                    children: [
                      Expanded(
                        child: ListView.separated(
                          separatorBuilder: (BuildContext context, int index) =>
                              const Divider(),
                          itemCount: alfaObservationController
                              .alfaObservationList.length,
                          itemBuilder: (context, index) {
                            final item = alfaObservationController
                                .alfaObservationList[index];
                            return ListTile(
                              title: Text(
                                "${index + 1}. Tour ID: ${item.tourId ?? 'N/A'}\n"
                                "School: ${item.school ?? 'N/A'}\n",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                                textAlign: TextAlign.left,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Obx(() => IconButton(
                                        color: _networkManager
                                                    .connectionType.value ==
                                                0
                                            ? Colors.grey
                                            : AppColors.primary,
                                        icon: const Icon(Icons.sync),
                                        onPressed: _networkManager
                                                    .connectionType.value ==
                                                0
                                            ? null
                                            : () async {
                                                IconData icon =
                                                    Icons.check_circle;
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
                                                      isLoading.value = true;
                                                      syncProgress.value = 0.0;
                                                      hasError.value = false;

                                                      if (_networkManager
                                                                  .connectionType
                                                                  .value ==
                                                              1 ||
                                                          _networkManager
                                                                  .connectionType
                                                                  .value ==
                                                              2) {
                                                        for (int i = 0;
                                                            i <= 100;
                                                            i++) {
                                                          await Future.delayed(
                                                              const Duration(
                                                                  milliseconds:
                                                                      50));
                                                          syncProgress.value =
                                                              i / 100;
                                                        }

                                                        var rsp =
                                                            await insertAlfaObservation(
                                                          item.tourId,
                                                          item.school,
                                                          item.udiseValue,
                                                          item.correctUdise,
                                                          item.noStaffTrained,
                                                          item.imgNurTimeTable,
                                                          item.imgLKGTimeTable,
                                                          item.imgUKGTimeTable,
                                                          item.bookletValue,
                                                          item.moduleValue,
                                                          item.numeracyBooklet,
                                                          item.numeracyValue,
                                                          item.pairValue,
                                                          item.alfaActivityValue,
                                                          item.alfaGradeReport,
                                                          item.imgAlfa,
                                                          item.refresherTrainingValue,
                                                          item.noTrainedTeacher,
                                                          item.imgTraining,
                                                          item.readingValue,
                                                          item.libGradeReport,
                                                          item.imgLibrary,
                                                          item.tlmKitValue,
                                                          item.imgTlm,
                                                          item.classObservation,
                                                          item.createdAt,
                                                          item.createdBy,
                                                          item.office,
                                                          item.id,
                                                          (progress) {
                                                            syncProgress.value =
                                                                progress;
                                                          },
                                                        );

                                                        if (rsp['status'] ==
                                                            1) {
                                                          _alfaObservationController
                                                              .removeRecordFromList(
                                                                  item.id ?? 0);

                                                          customSnackbar(
                                                            'Success',
                                                            rsp['message'] ??
                                                                'Synced successfully',
                                                            AppColors.secondary,
                                                            AppColors
                                                                .onSecondary,
                                                            Icons.check,
                                                          );
                                                        } else {
                                                          hasError.value = true;
                                                          customSnackbar(
                                                            'Error',
                                                            rsp['message'] ??
                                                                'Sync failed',
                                                            AppColors.error,
                                                            AppColors.onError,
                                                            Icons.warning,
                                                          );
                                                        }
                                                        isLoading.value = false;
                                                      }
                                                    },
                                                  ),
                                                );
                                              },
                                      )),
                                ],
                              ),
                              onTap: () {
                                alfaObservationController
                                    .alfaObservationList[index].tourId;
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

var baseurl =
    "https://mis.17000ft.org/17000ft_apis/alfaObservation/insert_alfa.php";

Future<Map<String, dynamic>> insertAlfaObservation(
  String? tourId,
  String? school,
  String? udiseValue,
  String? correctUdise,
  String? noStaffTrained,
  String? imgNurTimeTable,
  String? imgLKGTimeTable,
  String? imgUKGTimeTable,
  String? bookletValue,
  String? moduleValue,
  String? numeracyBooklet,
  String? numeracyValue,
  String? pairValue,
  String? alfaActivityValue,
  String? alfaGradeReport,
  String? imgAlfa,
  String? refresherTrainingValue,
  String? noTrainedTeacher,
  String? imgTraining,
  String? readingValue,
  String? libGradeReport,
  String? imgLibrary,
  String? tlmKitValue,
  String? imgTLM,
  String? classObservation,
  String? createdAt,
  String? createdBy,
  String? office,
  int? id,
  Function(double) updateProgress, // Progress callback
) async {
  if (kDebugMode) {
    print('Inserting Alfa Observation Data');
    print('tourId: $tourId');
    print('school: $school');
    print('id: $id');
    print('udiseValue: $udiseValue');
    print('correctUdise: $correctUdise');
    print('noStaffTrained: $noStaffTrained');
    print('imgNurTimeTable: $imgNurTimeTable');
    print('imgLKGTimeTable: $imgLKGTimeTable');
    print('imgUKGTimeTable: $imgUKGTimeTable');
    print('bookletValue: $bookletValue');
    print('moduleValue: $moduleValue');
    print('numeracyBooklet: $numeracyBooklet');
    print('numeracyValue: $numeracyValue');
    print('pairValue: $pairValue');
    print('alfaActivityValue: $alfaActivityValue');
    print('alfaGradeReport: $alfaGradeReport');
    print('imgAlfa: $imgAlfa');
    print('refresherTrainingValue: $refresherTrainingValue');
    print('noTrainedTeacher: $noTrainedTeacher');
    print('imgTraining: $imgTraining');
    print('readingValue: $readingValue');
    print('libGradeReport: $libGradeReport');
    print('imgLibrary: $imgLibrary');
    print('tlmKitValue: $tlmKitValue');
    print('imgTLM: $imgTLM');
    print('classObservation: $classObservation');
    print('createdAt: $createdAt');
    print('createdBy: $createdBy');
    print('office: $office');
  }

  var request = http.MultipartRequest(
    'POST',
    Uri.parse(baseurl),
  );
  request.headers["Accept"] = "Application/json";

  // Ensure enrolmentData is a valid JSON string
  final String alfaGradeReportJsonData = alfaGradeReport ?? '';
  final String libGradeReportJsonData = libGradeReport ?? '';

  // Add text fields
  request.fields.addAll({
    'tourId': tourId ?? '',
    'school': school ?? '',
    'udiseValue': udiseValue ?? '',
    'correctUdise': correctUdise ?? '',
    'noStaffTrained': noStaffTrained ?? '',
    'bookletValue': bookletValue ?? '',
    'moduleValue': moduleValue ?? '',
    'numeracyBooklet': numeracyBooklet ?? '',
    'numeracyValue': numeracyValue ?? '',
    'pairValue': pairValue ?? '',
    'alfaActivityValue': alfaActivityValue ?? '',
    'alfaGradeReport': alfaGradeReportJsonData.isEmpty ? 'N/A' : alfaGradeReportJsonData,
    'refresherTrainingValue': refresherTrainingValue ?? '',
    'noTrainedTeacher': noTrainedTeacher ?? '',
    'readingValue': readingValue ?? '',
    'libGradeReport': libGradeReportJsonData.isEmpty ? 'N/A' : libGradeReportJsonData,
    'tlmKitValue': tlmKitValue ?? '',
    'classObservation': classObservation ?? '',
    'createdAt': createdAt ?? '',
    'createdBy': createdBy ?? '',
    'office': office ?? 'N/A',
    'id': id?.toString() ?? '',
  });

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
    await attachImages(imgAlfa, 'imgAlfa');
    await attachImages(
        imgTraining, 'imgTraining'); // Ensure this is attached properly
    await attachImages(imgLibrary, 'imgLibrary');
    await attachImages(imgTLM, 'imgTLM');
  } catch (e) {
    return {"status": 0, "message": e.toString()};
  }

  // Sending the request
  try {
    var response = await request.send();
    var responseBody = await response.stream.bytesToString();
    if (kDebugMode) {
      print('Raw response body: $responseBody');
    }

    // Try parsing the response as JSON
    var parsedResponse = json.decode(responseBody);

    if (parsedResponse['status'] == 1) {
      // If successfully inserted, delete from local database
      await SqfliteDatabaseHelper().queryDelete(
        arg: id.toString(),
        table: 'alfaObservation',
        field: 'id',
      );
      if (kDebugMode) {
        print("Record with id $id deleted from local database.");
      }
      await Get.put(AlfaObservationController()).fetchData();
    }

    return parsedResponse;
  } catch (responseBody) {
    if (kDebugMode) {
      print("Error: $responseBody");
    }
    return {
      "status": 0,
      "message": "Something went wrong, Please contact Admin $responseBody"
    };
  }
}
