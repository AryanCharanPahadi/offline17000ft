import 'dart:convert';
import 'dart:io';
import 'package:offline17000ft/forms/school_recce_form/school_recce_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:http_parser/http_parser.dart'; // for MediaType
import 'package:offline17000ft/components/custom_appBar.dart';
import 'package:offline17000ft/components/custom_dialog.dart';
import 'package:offline17000ft/components/custom_snackbar.dart';
import 'package:offline17000ft/constants/color_const.dart';
import 'package:offline17000ft/helper/database_helper.dart';
import 'package:offline17000ft/services/network_manager.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
class SchoolRecceSync extends StatefulWidget {
  const SchoolRecceSync({super.key});

  @override
  State<SchoolRecceSync> createState() => _SchoolRecceSyncState();
}

class _SchoolRecceSyncState extends State<SchoolRecceSync> {
  final SchoolRecceController _schoolRecceController =
  Get.put(SchoolRecceController());  final NetworkManager _networkManager = Get.put(NetworkManager());
  var isLoading = false.obs;
  var syncProgress = 0.0.obs; // Progress variable for syncing
  var hasError = false.obs; // Variable to track if syncing failed

  @override
  void initState() {
    super.initState();
    _schoolRecceController.fetchData();
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
        appBar: const CustomAppbar(title: 'School Recce Sync'),
        body: GetBuilder<SchoolRecceController>(
          builder: (schoolRecceController) {
            if (schoolRecceController.schoolRecceList.isEmpty) {
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
                    itemCount: schoolRecceController.schoolRecceList.length,
                    itemBuilder: (context, index) {
                      final item = schoolRecceController.schoolRecceList[index];
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
                                      var rsp = await insertSchoolRecce(
                                        item.tourId,
                                        item.school,
                                        item.udiseValue,
                                        item.udise_correct,
                                        item.boardImg,
                                        item.buildingImg,
                                        item.gradeTaught,
                                        item.instituteHead,
                                        item.headDesignation,
                                        item.headPhone,
                                        item.headEmail,
                                        item.appointedYear,
                                        item.noTeachingStaff,
                                        item.noNonTeachingStaff,
                                        item.totalStaff,
                                        item.registerImg,
                                        item.smcHeadName,
                                        item.smcPhone,
                                        item.smcQual,
                                        item.qualOther,
                                        item.totalSmc,
                                        item.meetingDuration,
                                        item.meetingOther,
                                        item.smcDesc,
                                        item.noUsableClass,
                                        item.electricityAvailability,
                                        item.networkAvailability,
                                        item.digitalLearning,
                                        item.smartClassImg,
                                        item.projectorImg,
                                        item.computerImg,
                                        item.libraryExisting,
                                        item.libImg,
                                        item.playGroundSpace,
                                        item.spaceImg,
                                        item.enrollmentReport,
                                        item.enrollmentImg,
                                        item.academicYear,
                                        item.gradeReportYear1,
                                        item.gradeReportYear2,
                                        item.gradeReportYear3,
                                        item.DigiLabRoomImg,
                                        item.libRoomImg,
                                        item.remoteInfo,
                                        item.motorableRoad,
                                        item.languageSchool,
                                        item.languageOther,
                                        item.supportingNgo,
                                        item.otherNgo,
                                        item.observationPoint,
                                        item.submittedBy,
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
                          schoolRecceController.schoolRecceList[index].tourId;
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

var baseurl = "https://mis.17000ft.org/apis/fast_apis/insert_recce.php";
Future insertSchoolRecce(
    String? tourId,
    String? school,
    String? udiseValue,
    String? udise_correct,
    String? boardImg,
    String? buildingImg,
    String? gradeTaught,
    String? instituteHead,
    String? headDesignation,
    String? headPhone,
    String? headEmail,
    String? appointedYear,
    String? noTeachingStaff,
    String? noNonTeachingStaff,
    String? totalStaff,
    String? registerImg,
    String? smcHeadName,
    String? smcPhone,
    String? smcQual,
    String? qualOther,
    String? totalSmc,
    String? meetingDuration,
    String? meetingOther,
    String? smcDesc,
    String? noUsableClass,
    String? electricityAvailability,
    String? networkAvailability,
    String? digitalLearning,
    String? smartClassImg,
    String? projectorImg,
    String? computerImg,
    String? libraryExisting,
    String? libImg,
    String? playGroundSpace,
    String? spaceImg,
    String? enrollmentReport,
    String? enrollmentImg,
    String? academicYear,
    String? gradeReportYear1,
    String? gradeReportYear2,
    String? gradeReportYear3,
    String? DigiLabRoomImg,
    String? libRoomImg,
    String? remoteInfo,
    String? motorableRoad,
    String? languageSchool,
    String? languageOther,
    String? supportingNgo,
    String? otherNgo,
    String? observationPoint,
    String? submittedBy,
    String? createdAt,
    String? office,
    int? id,
    Function(double) updateProgress, // Progress callback
    ) async {
  if (kDebugMode) {
    print('This is School Recce Data');
    print('Tour ID: $tourId');
    print('School: $school');
    print('UDISE Value: $udiseValue');
    print('UDISE Correct: $udise_correct');
    print('Board Image: $boardImg');
    print('Building Image: $buildingImg');
    print('Grade Taught: $gradeTaught');
    print('Institute Head: $instituteHead');
    print('Head Designation: $headDesignation');
    print('Head Phone: $headPhone');
    print('Head Email: $headEmail');
    print('Appointed Year: $appointedYear');
    print('No Teaching Staff: $noTeachingStaff');
    print('No Non-Teaching Staff: $noNonTeachingStaff');
    print('Total Staff: $totalStaff');
    print('Register Image: $registerImg');
    print('SMC Head Name: $smcHeadName');
    print('SMC Phone: $smcPhone');
    print('SMC Qualification: $smcQual');
    print('Qualification Other: $qualOther');
    print('Total SMC: $totalSmc');
    print('Meeting Duration: $meetingDuration');
    print('Meeting Other: $meetingOther');
    print('SMC Description: $smcDesc');
    print('No Usable Class: $noUsableClass');
    print('Electricity Availability: $electricityAvailability');
    print('Network Availability: $networkAvailability');
    print('Digital Learning: $digitalLearning');
    print('Smart Class Image: $smartClassImg');
    print('Projector Image: $projectorImg');
    print('Computer Image: $computerImg');
    print('Library Existing: $libraryExisting');
    print('Library Image: $libImg');
    print('Playground Space: $playGroundSpace');
    print('Space Image: $spaceImg');
    print('Enrollment Report: $enrollmentReport');
    print('Enrollment Image: $enrollmentImg');
    print('Academic Year: $academicYear');
    print('Grade Report Year 1: $gradeReportYear1');
    print('Grade Report Year 2: $gradeReportYear2');
    print('Grade Report Year 3: $gradeReportYear3');
    print('Digital Lab Room Image: $DigiLabRoomImg');
    print('Library Room Image: $libRoomImg');
    print('Remote Info: $remoteInfo');
    print('Motorable Road: $motorableRoad');
    print('Language School: $languageSchool');
    print('Language Other: $languageOther');
    print('Supporting NGO: $supportingNgo');
    print('Other NGO: $otherNgo');
    print('Observation Point: $observationPoint');
    print('Submitted By: $submittedBy');
    print('Created At: $createdAt');
    print('ID: $id');
  }

  var request = http.MultipartRequest(
    'POST',
    Uri.parse(baseurl),
  );
  request.headers["Accept"] = "Application/json";

  // Ensure enrolmentData is a valid JSON string
  final String enrollmentReportJsonData = enrollmentReport ?? '';
  final String gradeReportYear1JsonData = gradeReportYear1 ?? '';
  final String gradeReportYear2JsonData = gradeReportYear2 ?? '';
  final String gradeReportYear3JsonData = gradeReportYear3 ?? '';

  // Add text fields
  request.fields.addAll({
    'tourId': tourId ?? '',
    'school': school ?? '',
    'udiseValue': udiseValue ?? '',
    'udise_correct': udise_correct ?? '',
    'gradeTaught': gradeTaught ?? '',
    'instituteHead': instituteHead ?? '',
    'headDesignation': headDesignation ?? '',
    'headPhone': headPhone ?? '',
    'headEmail': headEmail ?? '',
    'appointedYear': appointedYear ?? '',
    'noTeachingStaff': noTeachingStaff ?? '',
    'noNonTeachingStaff': noNonTeachingStaff ?? '',
    'totalStaff': totalStaff ?? '',
    'smcHeadName': smcHeadName ?? '',
    'smcPhone': smcPhone ?? '',
    'smcQual': smcQual ?? '',
    'qualOther': qualOther ?? '',
    'totalSmc': totalSmc ?? '',
    'meetingDuration': meetingDuration ?? '',
    'meetingOther': meetingOther ?? '',
    'smcDesc': smcDesc ?? '',
    'noUsableClass': noUsableClass ?? '',
    'electricityAvailability': electricityAvailability ?? '',
    'networkAvailability': networkAvailability ?? '',
    'digitalLearning': digitalLearning ?? '',
    'libraryExisting': libraryExisting ?? '',
    'playGroundSpace': playGroundSpace ?? '',
    'enrollmentReport': enrollmentReportJsonData ?? '',
    'academicYear': academicYear ?? '',
    'gradeReportYear1': gradeReportYear1JsonData ?? '',
    'gradeReportYear2': gradeReportYear2JsonData ?? '',
    'gradeReportYear3': gradeReportYear3JsonData ?? '',
    'remoteInfo': remoteInfo ?? '',
    'motorableRoad': motorableRoad ?? '',
    'languageSchool': languageSchool ?? '',
    'languageOther': languageOther ?? '',
    'supportingNgo': supportingNgo ?? '',
    'otherNgo': otherNgo ?? '',
    'observationPoint': observationPoint ?? '',
    'submittedBy': submittedBy ?? '',
    'createdAt': createdAt ?? '',
    'office': office ?? '',
  });

    if (boardImg != null && boardImg.isNotEmpty) {
      List<String> imagePaths = boardImg.split(',');

      for (String path in imagePaths) {
        File imageFile = File(path.trim());
        if (imageFile.existsSync()) {
          request.files.add(
            await http.MultipartFile.fromPath(
              'boardImg[]', // Use array-like name for multiple images
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

    if (buildingImg != null && buildingImg.isNotEmpty) {
      List<String> imagePaths = buildingImg.split(',');

      for (String path in imagePaths) {
        File imageFile = File(path.trim());
        if (imageFile.existsSync()) {
          request.files.add(
            await http.MultipartFile.fromPath(
              'buildingImg[]', // Use array-like name for multiple images
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

    if (registerImg != null && registerImg.isNotEmpty) {
      List<String> imagePaths = registerImg.split(',');

      for (String path in imagePaths) {
        File imageFile = File(path.trim());
        if (imageFile.existsSync()) {
          request.files.add(
            await http.MultipartFile.fromPath(
              'registerImg[]', // Use array-like name for multiple images
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

    if (smartClassImg != null && smartClassImg.isNotEmpty) {
      List<String> imagePaths = smartClassImg.split(',');

      for (String path in imagePaths) {
        File imageFile = File(path.trim());
        if (imageFile.existsSync()) {
          request.files.add(
            await http.MultipartFile.fromPath(
              'smartClassImg[]', // Use array-like name for multiple images
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

    if (projectorImg != null && projectorImg.isNotEmpty) {
      List<String> imagePaths = projectorImg.split(',');

      for (String path in imagePaths) {
        File imageFile = File(path.trim());
        if (imageFile.existsSync()) {
          request.files.add(
            await http.MultipartFile.fromPath(
              'projectorImg[]', // Use array-like name for multiple images
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

    if (computerImg != null && computerImg.isNotEmpty) {
      List<String> imagePaths = computerImg.split(',');

      for (String path in imagePaths) {
        File imageFile = File(path.trim());
        if (imageFile.existsSync()) {
          request.files.add(
            await http.MultipartFile.fromPath(
              'computerImg[]', // Use array-like name for multiple images
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

    if (libImg != null && libImg.isNotEmpty) {
      List<String> imagePaths = libImg.split(',');

      for (String path in imagePaths) {
        File imageFile = File(path.trim());
        if (imageFile.existsSync()) {
          request.files.add(
            await http.MultipartFile.fromPath(
              'libImg[]', // Use array-like name for multiple images
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

    if (spaceImg != null && spaceImg.isNotEmpty) {
      List<String> imagePaths = spaceImg.split(',');

      for (String path in imagePaths) {
        File imageFile = File(path.trim());
        if (imageFile.existsSync()) {
          request.files.add(
            await http.MultipartFile.fromPath(
              'spaceImg[]', // Use array-like name for multiple images
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

    if (enrollmentImg != null && enrollmentImg.isNotEmpty) {
      List<String> imagePaths = enrollmentImg.split(',');

      for (String path in imagePaths) {
        File imageFile = File(path.trim());
        if (imageFile.existsSync()) {
          request.files.add(
            await http.MultipartFile.fromPath(
              'enrollmentImg[]', // Use array-like name for multiple images
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

    if (DigiLabRoomImg != null && DigiLabRoomImg.isNotEmpty) {
      List<String> imagePaths = DigiLabRoomImg.split(',');

      for (String path in imagePaths) {
        File imageFile = File(path.trim());
        if (imageFile.existsSync()) {
          request.files.add(
            await http.MultipartFile.fromPath(
              'DigiLabRoomImg[]', // Use array-like name for multiple images
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

    if (libRoomImg != null && libRoomImg.isNotEmpty) {
      List<String> imagePaths = libRoomImg.split(',');

      for (String path in imagePaths) {
        File imageFile = File(path.trim());
        if (imageFile.existsSync()) {
          request.files.add(
            await http.MultipartFile.fromPath(
              'libRoomImg[]', // Use array-like name for multiple images
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
          table: 'schoolRecce',
          field: 'id',
        );
        if (kDebugMode) {
          print("Record with id $id deleted from local database.");
        }

        // Refresh data
        await Get.find<SchoolRecceController>().fetchData();

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