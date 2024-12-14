import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http_parser/http_parser.dart'; // for MediaType
import 'package:offline17000ft/components/custom_appBar.dart';
import 'package:offline17000ft/components/custom_dialog.dart';
import 'package:offline17000ft/components/custom_snackbar.dart';
import 'package:offline17000ft/constants/color_const.dart';
import 'package:offline17000ft/forms/issue_tracker/issue_tracker_controller.dart';
import 'package:offline17000ft/forms/issue_tracker/playground_issue.dart';
import 'package:offline17000ft/helper/database_helper.dart';
import 'package:offline17000ft/services/network_manager.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'alexa_issue.dart';
import 'digilab_issue.dart';
import 'furniture_issue.dart';
import 'issue_tracker_modal.dart';
import 'lib_issue_modal.dart';

class FinalIssueTrackerSync extends StatefulWidget {
  const FinalIssueTrackerSync({Key? key}) : super(key: key);

  @override
  State<FinalIssueTrackerSync> createState() => _FinalIssueTrackerSyncState();
}

class _FinalIssueTrackerSyncState extends State<FinalIssueTrackerSync> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<IssueTrackerRecords> finalList = [];
  final IssueTrackerController _issueTrackerController =
      Get.put(IssueTrackerController());
  double _percent = 0.0; // To track the sync percentage
  bool _isSubmitting = false; // To track whether syncing is in progress

  filterUnique() {
    finalList = [];
    finalList = _issueTrackerController.issueTrackerList;
    if (kDebugMode) {
      print('length of ${finalList.length}');
    }
    setState(() {});
  }

  List<IssueTrackerRecords>? filterdByUniqueId;
  List<LibIssue>? libIssueList;
  List<PlaygroundIssue>? playgroundIssueList;
  List<DigiLabIssue>? digiLabIssueList;
  List<FurnitureIssue>? furnitureIssueList;
  List<AlexaIssue>? alexaIssueList;


  @override
  void initState() {
    super.initState();
    _issueTrackerController.fetchData().then((value) {
      filterUnique();
    });
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
      child: GetBuilder<NetworkManager>(
          init: NetworkManager(),
          builder: (networkManager) {
            return Scaffold(
              key: _scaffoldKey,
              appBar: const CustomAppbar(title: 'Issue Tracker Sync'),
              body: GetBuilder<IssueTrackerController>(
                  init: IssueTrackerController(),
                  builder: (issueTrackerController) {
                    return Stack(children: [
                      // List and Sync Button
                      Column(
                        children: [
                          Expanded(
                              child: finalList.isEmpty
                                  ? const Center(
                                      child: Text(
                                      'No Records Found',
                                      style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary),
                                    ))
                                  : Stack(
                                      children: [
                                        ListView.separated(
                                          itemCount: finalList.length,
                                          separatorBuilder:
                                              (BuildContext context,
                                                      int index) =>
                                                  const Divider(),
                                          itemBuilder: (BuildContext context,
                                              int index) {
                                            return ListTile(
                                              leading: Text("(${(index + 1)})"),

                                              subtitle: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  const SizedBox(height: 10),
                                                  Text(
                                                    "TourId:${finalList[index].tourId ?? 'N/A'}",
                                                    style: const TextStyle(
                                                      color: Colors.black,
                                                      fontSize: 16,
                                                    ),
                                                  ),

                                                  const SizedBox(height: 10),
                                                  Text(
                                                    "School: ${finalList[index].school.toString()}",
                                                    style: const TextStyle(
                                                        color: Colors.black,
                                                        fontSize: 16),
                                                  ),
                                                ],
                                              ),
                                              trailing: networkManager
                                                          .connectionType !=
                                                      0
                                                  ? IconButton(
                                                      icon: const Icon(
                                                          Icons.sync,
                                                          color: AppColors
                                                              .primary),
                                                      onPressed: () async {
                                                        filterdByUniqueId = [
                                                          finalList[index]
                                                        ];
                                                        libIssueList = Get.find<
                                                                IssueTrackerController>()
                                                            .libIssueList
                                                            .toList();
                                                        playgroundIssueList = Get
                                                                .find<
                                                                    IssueTrackerController>()
                                                            .playgroundIssueList
                                                            .toList();
                                                        furnitureIssueList = Get
                                                                .find<
                                                                    IssueTrackerController>()
                                                            .furnitureIssueList
                                                            .toList();
                                                        digiLabIssueList = Get.find<
                                                                IssueTrackerController>()
                                                            .digiLabIssueList
                                                            .toList();
                                                        alexaIssueList = Get.find<
                                                                IssueTrackerController>()
                                                            .alexaIssueList
                                                            .toList();

                                                        setState(() {
                                                          _isSubmitting = true;
                                                          _percent =
                                                              0.0; // Reset percentage
                                                        });

                                                        IconData icon =
                                                            Icons.check_circle;
                                                        showDialog(
                                                            context: context,
                                                            builder: (_) =>
                                                                Confirmation(
                                                                  iconname:
                                                                      icon,
                                                                  title:
                                                                      'Confirm Submission',
                                                                  yes:
                                                                      'Confirm',
                                                                  no: 'Cancel',
                                                                  desc:
                                                                      'Are you sure you want to Sync this record?',
                                                                  onPressed:
                                                                      () async {
                                                                    for (int i =
                                                                            0;
                                                                        i < filterdByUniqueId!.length;
                                                                        i++) {
                                                                      if (kDebugMode) {
                                                                        print(
                                                                          '$i no of row inserted');
                                                                      }
                                                                      if (kDebugMode) {
                                                                        print(
                                                                          'TABLE 1 BASIC RECORDS ');
                                                                      }

                                                                      var rsp = await insertBasicRecords(
                                                                          filterdByUniqueId![i]
                                                                              .tourId!
                                                                              .toString(),
                                                                          filterdByUniqueId![i].school ??
                                                                              'NA',
                                                                          filterdByUniqueId![i].udiseCode ??
                                                                              'NA',
                                                                          filterdByUniqueId![i].correctUdise ??
                                                                              'NA',
                                                                          filterdByUniqueId![i].uniqueId ??
                                                                              'NA',
                                                                          filterdByUniqueId![i]
                                                                              .office,
                                                                          filterdByUniqueId![i]
                                                                              .createdAt!,
                                                                          filterdByUniqueId![i]
                                                                              .created_by!,
                                                                          filterdByUniqueId![i]
                                                                              .id);
                                                                      if (rsp !=
                                                                              null &&
                                                                          rsp['status'] ==
                                                                              1) {
                                                                        if (kDebugMode) {
                                                                          print(
                                                                            'TABLE of Library ${libIssueList?.length ?? 0}');
                                                                        }

                                                                        if (libIssueList !=
                                                                                null &&
                                                                            libIssueList!.isNotEmpty) {
                                                                          for (int i = 0;
                                                                              i < libIssueList!.length;
                                                                              i++) {
                                                                            if (kDebugMode) {
                                                                              print('library records of num row $i');
                                                                            }

                                                                            var rsplib =
                                                                                await insertIssueRecords(
                                                                              libIssueList![i].uniqueId,
                                                                              libIssueList![i].issueExist!,
                                                                              libIssueList![i].issueName,
                                                                              libIssueList![i].lib_issue_img,
                                                                              libIssueList![i].issueDescription!,
                                                                              libIssueList![i].issueReportOn!,
                                                                              libIssueList![i].issueReportBy!,
                                                                              libIssueList![i].issueResolvedOn!,
                                                                              libIssueList![i].issueResolvedBy!,
                                                                              libIssueList![i].issueStatus!,
                                                                              libIssueList![i].id,
                                                                            );

                                                                            // Debug print statements to track the value of rsplib
                                                                            if (kDebugMode) {
                                                                              print('rsplib response: $rsplib');
                                                                            }

                                                                            if (rsplib != null &&
                                                                                rsplib.containsKey('status') &&
                                                                                rsplib['status'] == 1) {
                                                                              customSnackbar(
                                                                                'Successfully',
                                                                                "${rsp['message']}",
                                                                                AppColors.secondary,
                                                                                AppColors.onSecondary,
                                                                                Icons.check,
                                                                              );
                                                                            } else {
                                                                              customSnackbar(
                                                                                'Error',
                                                                                rsplib != null ? rsplib['message'] ?? 'Unknown error occurred' : 'Failed to upload issue record',
                                                                                AppColors.errorContainer,
                                                                                AppColors.onBackground,
                                                                                Icons.warning,
                                                                              );
                                                                            }
                                                                          }
                                                                        }

                                                                        if (kDebugMode) {
                                                                          print(
                                                                            'TABLE of Playground ${playgroundIssueList?.length ?? 0}');
                                                                        }

                                                                        if (playgroundIssueList !=
                                                                                null &&
                                                                            playgroundIssueList!.isNotEmpty) {
                                                                          for (int i = 0;
                                                                              i < playgroundIssueList!.length;
                                                                              i++) {
                                                                            if (kDebugMode) {
                                                                              print('Playground records of num row $i');
                                                                            }

                                                                            var rspPlay =
                                                                                await insertPlayRecords(
                                                                              playgroundIssueList![i].uniqueId,
                                                                              playgroundIssueList![i].issueExist!,
                                                                              playgroundIssueList![i].issueName,
                                                                              playgroundIssueList![i].play_issue_img,
                                                                              playgroundIssueList![i].issueDescription!,
                                                                              playgroundIssueList![i].issueReportOn!,
                                                                              playgroundIssueList![i].issueReportBy!,
                                                                              playgroundIssueList![i].issueResolvedOn!,
                                                                              playgroundIssueList![i].issueResolvedBy!,
                                                                              playgroundIssueList![i].issueStatus!,
                                                                              playgroundIssueList![i].id,
                                                                            );

                                                                            // Debug print statements to track the value of rsplib
                                                                            if (kDebugMode) {
                                                                              print('rspPlay response: $rspPlay');
                                                                            }

                                                                            if (rspPlay != null &&
                                                                                rspPlay.containsKey('status') &&
                                                                                rspPlay['status'] == 1) {
                                                                              customSnackbar(
                                                                                'Successfully',
                                                                                "${rsp['message']}",
                                                                                AppColors.secondary,
                                                                                AppColors.onSecondary,
                                                                                Icons.check,
                                                                              );
                                                                            } else {
                                                                              customSnackbar(
                                                                                'Error',
                                                                                rspPlay != null ? rspPlay['message'] ?? 'Unknown error occurred' : 'Failed to upload issue record',
                                                                                AppColors.errorContainer,
                                                                                AppColors.onBackground,
                                                                                Icons.warning,
                                                                              );
                                                                            }
                                                                          }
                                                                        }

                                                                        if (kDebugMode) {
                                                                          print(
                                                                            'TABLE of Furniture ${furnitureIssueList?.length ?? 0}');
                                                                        }

                                                                        if (furnitureIssueList !=
                                                                                null &&
                                                                            furnitureIssueList!.isNotEmpty) {
                                                                          for (int i = 0;
                                                                              i < furnitureIssueList!.length;
                                                                              i++) {
                                                                            if (kDebugMode) {
                                                                              print('Furniture records of num row $i');
                                                                            }

                                                                            var rspFurn =
                                                                                await insertFurnRecords(
                                                                              furnitureIssueList![i].uniqueId,
                                                                              furnitureIssueList![i].issueExist!,
                                                                              furnitureIssueList![i].issueName,
                                                                              furnitureIssueList![i].furn_issue_img,
                                                                              furnitureIssueList![i].issueDescription!,
                                                                              furnitureIssueList![i].issueReportOn!,
                                                                              furnitureIssueList![i].issueReportBy!,
                                                                              furnitureIssueList![i].issueResolvedOn!,
                                                                              furnitureIssueList![i].issueResolvedBy!,
                                                                              furnitureIssueList![i].issueStatus!,
                                                                              furnitureIssueList![i].id,
                                                                            );

                                                                            // Debug print statements to track the value of rsplib
                                                                            if (kDebugMode) {
                                                                              print('rspFurn response: $rspFurn');
                                                                            }

                                                                            if (rspFurn != null &&
                                                                                rspFurn.containsKey('status') &&
                                                                                rspFurn['status'] == 1) {
                                                                              customSnackbar(
                                                                                'Successfully',
                                                                                "${rsp['message']}",
                                                                                AppColors.secondary,
                                                                                AppColors.onSecondary,
                                                                                Icons.check,
                                                                              );
                                                                            } else {
                                                                              customSnackbar(
                                                                                'Error',
                                                                                rspFurn != null ? rspFurn['message'] ?? 'Unknown error occurred' : 'Failed to upload issue record',
                                                                                AppColors.errorContainer,
                                                                                AppColors.onBackground,
                                                                                Icons.warning,
                                                                              );
                                                                            }
                                                                          }
                                                                        }

                                                                        if (kDebugMode) {
                                                                          print(
                                                                            'TABLE of DigiLab ${digiLabIssueList?.length ?? 0}');
                                                                        }

                                                                        if (digiLabIssueList !=
                                                                                null &&
                                                                            digiLabIssueList!.isNotEmpty) {
                                                                          for (int i = 0;
                                                                              i < digiLabIssueList!.length;
                                                                              i++) {
                                                                            if (kDebugMode) {
                                                                              print('DigiLab records of num row $i');
                                                                            }

                                                                            var rspDig =
                                                                                await insertDigRecords(
                                                                              digiLabIssueList![i].uniqueId,
                                                                              digiLabIssueList![i].issueExist!,
                                                                              digiLabIssueList![i].issueName,
                                                                              digiLabIssueList![i].dig_issue_img,
                                                                              digiLabIssueList![i].issueDescription!,
                                                                              digiLabIssueList![i].issueReportOn,
                                                                              digiLabIssueList![i].issueReportBy,
                                                                              digiLabIssueList![i].issueResolvedOn?.toString() ?? 'Not Resolved Yet',
                                                                              digiLabIssueList![i].issueResolvedBy?.toString() ?? 'Not Resolved Yet',
                                                                              digiLabIssueList![i].issueStatus!,
                                                                              digiLabIssueList![i].tabletNumber?.toString() ?? 'N/A',
                                                                              digiLabIssueList![i].id,
                                                                            );

                                                                            // Debug print statements to track the value of rsplib
                                                                            if (kDebugMode) {
                                                                              print('rspDig response: $rspDig');
                                                                            }

                                                                            if (rspDig != null &&
                                                                                rspDig.containsKey('status') &&
                                                                                rspDig['status'] == 1) {
                                                                              customSnackbar(
                                                                                'Successfully',
                                                                                "${rsp['message']}",
                                                                                AppColors.secondary,
                                                                                AppColors.onSecondary,
                                                                                Icons.check,
                                                                              );
                                                                            } else {
                                                                              customSnackbar(
                                                                                'Error',
                                                                                rspDig != null ? rspDig['message'] ?? 'Unknown error occurred' : 'Failed to upload issue record',
                                                                                AppColors.errorContainer,
                                                                                AppColors.onBackground,
                                                                                Icons.warning,
                                                                              );
                                                                            }
                                                                          }
                                                                        }

                                                                        if (kDebugMode) {
                                                                          print(
                                                                            'TABLE of Alexa ${alexaIssueList?.length ?? 0}');
                                                                        }

                                                                        if (alexaIssueList !=
                                                                                null &&
                                                                            alexaIssueList!.isNotEmpty) {
                                                                          for (int i = 0;
                                                                              i < alexaIssueList!.length;
                                                                              i++) {
                                                                            if (kDebugMode) {
                                                                              print('Alexa records of num row $i');
                                                                            }

                                                                            var rspAlexa =
                                                                                await insertAlexaRecords(
                                                                              alexaIssueList![i].uniqueId,
                                                                              alexaIssueList![i].issueExist!,
                                                                              alexaIssueList![i].issueName,
                                                                              alexaIssueList![i].alexa_issue_img,
                                                                              alexaIssueList![i].issueDescription!,
                                                                              alexaIssueList![i].issueReportOn!,
                                                                              alexaIssueList![i].issueReportBy!,
                                                                              alexaIssueList![i].issueResolvedOn!,
                                                                              alexaIssueList![i].issueResolvedBy!,
                                                                              alexaIssueList![i].issueStatus!,
                                                                              alexaIssueList![i].other?.toString() ?? 'N/A',
                                                                              alexaIssueList![i].missingDot?.toString() ?? 'N/A',
                                                                              alexaIssueList![i].notConfiguredDot?.toString() ?? 'N/A',
                                                                              alexaIssueList![i].notConnectingDot?.toString() ?? 'N/A',
                                                                              alexaIssueList![i].notChargingDot?.toString() ?? 'N/A',
                                                                              alexaIssueList![i].id,
                                                                            );

                                                                            // Debug print statements to track the value of rsplib
                                                                            if (kDebugMode) {
                                                                              print('rspAlexa response: $rspAlexa');
                                                                            }

                                                                            if (rspAlexa != null &&
                                                                                rspAlexa.containsKey('status') &&
                                                                                rspAlexa['status'] == 1) {
                                                                              customSnackbar(
                                                                                'Successfully',
                                                                                "${rsp['message']}",
                                                                                AppColors.secondary,
                                                                                AppColors.onSecondary,
                                                                                Icons.check,
                                                                              );
                                                                            } else {
                                                                              customSnackbar(
                                                                                'Error',
                                                                                rspAlexa != null ? rspAlexa['message'] ?? 'Unknown error occurred' : 'Failed to upload issue record',
                                                                                AppColors.errorContainer,
                                                                                AppColors.onBackground,
                                                                                Icons.warning,
                                                                              );
                                                                            }
                                                                          }
                                                                        }
                                                                        // Update the percentage after each sync operation
                                                                        setState(
                                                                            () {
                                                                          _percent =
                                                                              ((i + 1) / filterdByUniqueId!.length) * 100;

                                                                          // Remove the synced record from the list
                                                                          finalList
                                                                              .removeAt(index);
                                                                        });

                                                                        // Introduce a delay to simulate processing time
                                                                        await Future.delayed(const Duration(
                                                                            milliseconds:
                                                                                500));

                                                                        if (i ==
                                                                            (filterdByUniqueId!.length -
                                                                                1)) {
                                                                          customSnackbar(
                                                                              'Synced Successfully',
                                                                              "${rsp['message']}",
                                                                              AppColors.secondary,
                                                                              AppColors.onSecondary,
                                                                              Icons.check);
                                                                        } else {
                                                                          customSnackbar(
                                                                            'Error',
                                                                            rsp['message'],
                                                                            AppColors.errorContainer,
                                                                            AppColors.onBackground,
                                                                            Icons.warning,
                                                                          );
                                                                        }

                                                                        if (kDebugMode) {
                                                                          print(
                                                                            'ALL data is removed from tables');
                                                                        }

                                                                        issueTrackerController
                                                                            .libIssueList
                                                                            .clear();
                                                                        issueTrackerController
                                                                            .digiLabIssueList
                                                                            .clear();
                                                                        issueTrackerController
                                                                            .furnitureIssueList
                                                                            .clear();
                                                                        issueTrackerController
                                                                            .playgroundIssueList
                                                                            .clear();
                                                                        issueTrackerController
                                                                            .issueTrackerList
                                                                            .clear();
                                                                        issueTrackerController
                                                                            .alexaIssueList
                                                                            .clear();
                                                                      }

                                                                      // Stop the loading
                                                                      setState(
                                                                          () {
                                                                        _isSubmitting =
                                                                            false; // Stop spinner
                                                                        _percent =
                                                                            0.0; // Reset percentage
                                                                      });
                                                                    }
                                                                  },
                                                                ));
                                                      },
                                                    )
                                                  : null, // Hide sync icon when offline
                                            );
                                          },
                                        ),
                                        if (_isSubmitting)
                                          Positioned.fill(
                                            child: Center(
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  SizedBox(
                                                    width: 100,
                                                    height: 100,
                                                    child:
                                                        CircularProgressIndicator(
                                                      value: _percent / 100,
                                                      backgroundColor:
                                                          Colors.grey[300],
                                                      color: AppColors.primary,
                                                      strokeWidth: 8,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    "${_percent.toStringAsFixed(0)}%",
                                                    style: const TextStyle(
                                                        fontSize: 20),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                      ],
                                    ))
                        ],
                      )
                    ]);
                  }),
            );
          }),
    );
  }
}

var baseurl = "https://mis.17000ft.org/17000ft_apis/";
Future insertIssueRecords(
  String? uniqueId,
  String? issueExist,
  String? issueValue,
  String? lib_issue_img,
  String? issueDescription,
  String? reportedOn,
  String? reportedBy,
  String? resolvedOn,
  String? resolvedBy,
  String? issueStatus,
  int? id,
) async {
  if (uniqueId == null || issueExist == null) {
    if (kDebugMode) {
      print('Missing critical data: uniqueId or issueExist is null.');
    }
    return null;
  }

  if (kDebugMode) {
    print('Insert Library issue records called');
    print('uniqueId: $uniqueId');
    print('issueExist: $issueExist');
    print('issueValue: $issueValue');
    print('lib_issue_img: $lib_issue_img');
    print('issueDescription: $issueDescription');
    print('reportedOn: $reportedOn');
    print('reportedBy: $reportedBy');
    print('resolvedOn: $resolvedOn');
    print('resolvedBy: $resolvedBy');
    print('issueStatus: $issueStatus');
  }


  var request = http.MultipartRequest(
    'POST',
    Uri.parse('${baseurl}IssueTracker/issueTrackerSave_new.php'),
  );
  request.headers["Accept"] = "Application/json";

  request.fields.addAll({
    'unique_id': uniqueId,
    'lib_issue': issueExist.toString(),
    'lib_issue_value': issueValue.toString(),
    'lib_desc': issueDescription.toString(),
    'reported_on': reportedOn.toString(),
    'reported_by': reportedBy.toString(),
    'issue_status': issueStatus.toString(),
    'resolved_on': resolvedOn.toString(),
    'resolved_by': resolvedBy.toString(),
  });

  if (kDebugMode) {
    print('Stage 1: Text fields added to the request');
  }

  if (lib_issue_img != null && lib_issue_img.isNotEmpty) {
    List<String> imagePaths = lib_issue_img.split(',');

    for (String path in imagePaths) {
      File imageFile = File(path.trim());
      if (imageFile.existsSync()) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'lib_issue_img[]', // Use array-like name for multiple images
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

  try {
    var response = await request.send();
    var responseBody = await response.stream.bytesToString();
    var parsedResponse = json.decode(responseBody);

    if (kDebugMode) {
      print('Response status: ${response.statusCode}');
    }
    if (kDebugMode) {
      print('Response body: $responseBody');
    }

    if (response.statusCode == 200 && parsedResponse['status'] == 1) {
      await SqfliteDatabaseHelper().queryDelete(
        arg: uniqueId.toString(),
        table: 'libIssueTable',
        field: 'unique_id',
      );
      await Get.find<IssueTrackerController>().fetchData();
      if (kDebugMode) {
        print('Issue records uploaded successfully.');
      }
    } else {
      if (kDebugMode) {
        print('Failed to upload issue records. Response: $parsedResponse');
      }
    }
    return parsedResponse;
  } catch (error) {
    if (kDebugMode) {
      print('Error uploading issue records: $error');
    }
    return null;
  }
}

Future insertBasicRecords(
  String? tourId,
  String? school,
  String? udiseCode,
  String? correctUdise,
  String? uniqueId,
  String? office,
  String? createdAt,
  String? created_by,
  int? id,
) async {
  var request = http.MultipartRequest(
    'POST',
    Uri.parse('${baseurl}IssueTracker/issueTrackerSave_new.php'),
  );

  request.headers["Accept"] = "Application/json";

  // Print the data being sent for debugging purposes
  if(kDebugMode) {
    print('Syncing data:');
    print('tourId: $tourId');
    print('school: $school');
    print('udiseCode: $udiseCode');
    print('correctUdise: $correctUdise');
    print('uniqueId: $uniqueId');
    print('office: $office');
    print('createdAt: $createdAt');
    print('created_by: $created_by');
    print('id: $id');
  }
  // Add text fields safely to avoid null values
  request.fields.addAll({
    if (tourId != null) 'tourId': tourId,
    if (school != null) 'school': school,
    if (uniqueId != null) 'unique_id': uniqueId,
    if (createdAt != null) 'createdAt': createdAt,
    if (created_by != null) 'created_by': created_by,
    if (udiseCode != null) 'udisevalue': udiseCode,
    if (correctUdise != null) 'correct_udise': correctUdise,
    if (office != null) 'office': office,
  });

  if (kDebugMode) {
    print('Request: $request');
  } // Print the entire request object

  try {
    var response = await request.send();
    var responseBody = await response.stream.bytesToString();
    if (kDebugMode) {
      print('Response Body: $responseBody');
    } // Print raw response body

    var parsedResponse;

    if (response.statusCode == 200) {
      // Check if the response is JSON before parsing
      if (response.headers['content-type']?.contains('application/json') ??
          false) {
        parsedResponse = json.decode(responseBody);
        if (kDebugMode) {
          print('Parsed Response: $parsedResponse');
        } // Print parsed response

        if (parsedResponse['status'] == 1) {
          // If status is 1, delete the local record and show success snack bar
          await SqfliteDatabaseHelper().queryDelete(
            arg: uniqueId.toString(),
            table: 'issueTracker',
            field: 'uniqueId',
          );
          await Get.find<IssueTrackerController>().fetchData();
          customSnackbar(
            "${parsedResponse['message']}",
            'Data synced for ${school.toString()}',
            AppColors.primary,
            Colors.white,
            Icons.check,
          );
          if (kDebugMode) {
            print('Data synced for ${school.toString()}');
          }
        } else if (parsedResponse['status'] == 0) {
          // If status is 0, show error snackbar
          customSnackbar(
            "${parsedResponse['message']}",
            'Something went wrong with school ${school.toString()}',
            AppColors.error,
            AppColors.primary,
            Icons.warning,
          );
        }
      } else {
        // Handle non-JSON response
        if (kDebugMode) {
          print('Unexpected content type: ${response.headers['content-type']}');
        }
        if (kDebugMode) {
          print('Response body: $responseBody');
        }
      }
    } else {
      // Handle non-200 responses
      if (kDebugMode) {
        print('Request failed with status: ${response.statusCode}');
      }
      if (kDebugMode) {
        print('Response body: $responseBody');
      }
    }

    return parsedResponse;
  } catch (error) {
    // Catch and log any errors that occur
    if (kDebugMode) {
      print('Error catch');
    }
    if (kDebugMode) {
      print(error);
    }
  }
}

Future insertPlayRecords(
  String? uniqueId,
  String? issueExist,
  String? issueValue,
  String? play_issue_img,
  String? issueDescription,
  String? reportedOn,
  String? reportedBy,
  String? resolvedOn,
  String? resolvedBy,
  String? issueStatus,
  int? id,
) async {
  if (uniqueId == null || issueExist == null) {
    if (kDebugMode) {
      print('Missing critical data: uniqueId or issueExist is null.');
    }
    return null;
  }
if(kDebugMode) {
  print('Insert Playground issue records called');
  print('uniqueId: $uniqueId');
  print('issueExist: $issueExist');
  print('issueValue: $issueValue');
  print('play_issue_img: $play_issue_img');
  print('issueDescription: $issueDescription');
  print('reportedOn: $reportedOn');
  print('reportedBy: $reportedBy');
  print('resolvedOn: $resolvedOn');
  print('resolvedBy: $resolvedBy');
  print('issueStatus: $issueStatus');
}
  var request = http.MultipartRequest(
    'POST',
    Uri.parse('${baseurl}IssueTracker/issueTrackerSave_new.php'),
  );
  request.headers["Accept"] = "Application/json";

  request.fields.addAll({
    'unique_id': uniqueId,
    'play_issue': issueExist.toString(),
    'play_issue_value': issueValue.toString(),
    'play_desc': issueDescription.toString(),
    'play_reported_on': reportedOn.toString(),
    'play_reported_by': reportedBy.toString(),
    'play_issue_status': issueStatus.toString(),
    'play_resolved_on': resolvedOn.toString(),
    'play_resolved_by': resolvedBy.toString(),
  });

  if (kDebugMode) {
    print('Stage 1: Text fields added to the request');
  }

  if (play_issue_img != null && play_issue_img.isNotEmpty) {
    List<String> imagePaths = play_issue_img.split(',');

    for (String path in imagePaths) {
      File imageFile = File(path.trim());
      if (imageFile.existsSync()) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'play_issue_img[]', // Use array-like name for multiple images
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

  try {
    var response = await request.send();
    var responseBody = await response.stream.bytesToString();
    var parsedResponse = json.decode(responseBody);

    if (kDebugMode) {
      print('Response status: ${response.statusCode}');
    }
    if (kDebugMode) {
      print('Response body: $responseBody');
    }

    if (response.statusCode == 200 && parsedResponse['status'] == 1) {
      await SqfliteDatabaseHelper().queryDelete(
        arg: uniqueId.toString(),
        table: 'play_issue',
        field: 'unique_id',
      );
      await Get.find<IssueTrackerController>().fetchData();
      if (kDebugMode) {
        print('Issue records uploaded successfully.');
      }
    } else {
      if (kDebugMode) {
        print('Failed to upload issue records. Response: $parsedResponse');
      }
    }
    return parsedResponse;
  } catch (error) {
    if (kDebugMode) {
      print('Error uploading issue records: $error');
    }
    return null;
  }
}

Future insertFurnRecords(
  String? uniqueId,
  String? issueExist,
  String? issueValue,
  String? furn_issue_img,
  String? issueDescription,
  String? reportedOn,
  String? reportedBy,
  String? resolvedOn,
  String? resolvedBy,
  String? issueStatus,
  int? id,
) async {
  if (uniqueId == null || issueExist == null) {
    if (kDebugMode) {
      print('Missing critical data: uniqueId or issueExist is null.');
    }
    return null;
  }
if(kDebugMode) {
  print('Insert Furniture issue records called');
  print('uniqueId: $uniqueId');
  print('issueExist: $issueExist');
  print('issueValue: $issueValue');
  print('furn_issue_img: $furn_issue_img');
  print('issueDescription: $issueDescription');
  print('reportedOn: $reportedOn');
  print('reportedBy: $reportedBy');
  print('resolvedOn: $resolvedOn');
  print('resolvedBy: $resolvedBy');
  print('issueStatus: $issueStatus');
}
  var request = http.MultipartRequest(
    'POST',
    Uri.parse('${baseurl}IssueTracker/issueTrackerSave_new.php'),
  );
  request.headers["Accept"] = "Application/json";

  request.fields.addAll({
    'unique_id': uniqueId,

    'furn_issue': issueExist.toString(),
    'furn_issue_value': issueValue.toString(),
    'furn_desc': issueDescription.toString(),
    'furn_reported_on': reportedOn.toString(),
    'furn_reported_by': reportedBy.toString(),
    'furn_issue_status': issueStatus.toString(),
    'furn_resolved_on': resolvedOn.toString(),
    'furn_resolved_by': resolvedBy.toString(),
  });

  if (kDebugMode) {
    print('Stage 1: Text fields added to the request');
  }

  if (furn_issue_img != null && furn_issue_img.isNotEmpty) {
    List<String> imagePaths = furn_issue_img.split(',');

    for (String path in imagePaths) {
      File imageFile = File(path.trim());
      if (imageFile.existsSync()) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'furn_issue_img[]', // Use array-like name for multiple images
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

  try {
    var response = await request.send();
    var responseBody = await response.stream.bytesToString();
    var parsedResponse = json.decode(responseBody);

    if (kDebugMode) {
      print('Response status: ${response.statusCode}');
    }
    if (kDebugMode) {
      print('Response body: $responseBody');
    }

    if (response.statusCode == 200 && parsedResponse['status'] == 1) {
      await SqfliteDatabaseHelper().queryDelete(
        arg: uniqueId.toString(),
        table: 'furniture_issue',
        field: 'unique_id',
      );
      await Get.find<IssueTrackerController>().fetchData();
      if (kDebugMode) {
        print('Issue records uploaded successfully.');
      }
    } else {
      if (kDebugMode) {
        print('Failed to upload issue records. Response: $parsedResponse');
      }
    }
    return parsedResponse;
  } catch (error) {
    if (kDebugMode) {
      print('Error uploading issue records: $error');
    }
    return null;
  }
}

Future insertDigRecords(
  String? uniqueId,
  String? issueExist,
  String? issueValue,
  String? dig_issue_img,
  String? issueDescription,
  String? reportedOn,
  String? reportedBy,
  String? resolvedOn,
  String? resolvedBy,
  String? issueStatus,
  String? tabletNumber,
  int? id,
) async {
  // Validate mandatory fields
  if (uniqueId == null || issueExist == null) {
    if (kDebugMode) {
      print('Missing critical data: uniqueId or issueExist is null.');
    }
    return null;
  }
if(kDebugMode) {
  print('Insert DigiLab issue records called');
  print('uniqueId: $uniqueId');
  print('issueExist: $issueExist');
  print('issueValue: $issueValue');
  print('dig_issue_img: $dig_issue_img');
  print('issueDescription: $issueDescription');
  print('reportedOn: $reportedOn');
  print('reportedBy: $reportedBy');
  print('resolvedOn: $resolvedOn');
  print('resolvedBy: $resolvedBy');
  print('issueStatus: $issueStatus');
  print('tabletNumber: $tabletNumber');
}
  // Create the multipart request
  var request = http.MultipartRequest(
    'POST',
    Uri.parse('${baseurl}IssueTracker/issueTrackerSave_new.php'),
  );
  request.headers["Accept"] = "Application/json";

  // Add the fields to the request
  request.fields.addAll({
    'unique_id': uniqueId,
    'digi_issue': issueExist.toString(),
    'digi_issue_value': issueValue.toString(),
    'digi_desc': issueDescription.toString(),
    'digi_reported_on': reportedOn.toString(),
    'digi_reported_by': reportedBy.toString(),
    'digi_issue_status': issueStatus.toString(),
    'digi_resolved_on': resolvedOn.toString(),
    'digi_resolved_by': resolvedBy.toString(),
    'tablet_number': tabletNumber.toString(),
  });

  if (kDebugMode) {
    print('Stage 1: Text fields added to the request');
  }

  // Add image file if provided
  if (dig_issue_img != null && dig_issue_img.isNotEmpty) {
    List<String> imagePaths = dig_issue_img.split(',');

    for (String path in imagePaths) {
      File imageFile = File(path.trim());
      if (imageFile.existsSync()) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'dig_issue_img[]', // Use array-like name for multiple images
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

  try {
    // Send the request and get the response
    var response = await request.send();

    // Convert the response stream to a string
    var responseBody = await response.stream.bytesToString();

    // Log the raw response body for debugging
    if (kDebugMode) {
      print('Response status: ${response.statusCode}');
    }
    if (kDebugMode) {
      print('Response body: $responseBody');
    }

    // Try parsing the response as JSON
    try {
      var parsedResponse = json.decode(responseBody);

      // Check if the response status and the parsed response indicate success
      if (response.statusCode == 200 && parsedResponse['status'] == 1) {
        // Perform database delete operation after successful response
        await SqfliteDatabaseHelper().queryDelete(
          arg: uniqueId.toString(),
          table: 'digiLab_issue',
          field: 'unique_id',
        );

        // Fetch updated data after successful deletion
        await Get.find<IssueTrackerController>().fetchData();
        if (kDebugMode) {
          print('Issue records uploaded successfully.');
        }
      } else {
        // Log failure message with parsed response details
        if (kDebugMode) {
          print('Failed to upload issue records. Response: $parsedResponse');
        }
      }

      // Return the parsed response
      return parsedResponse;
    } catch (jsonError) {
      // If response is not valid JSON, log the error and raw response
      if (kDebugMode) {
        print('Failed to parse JSON response. Error: $jsonError');
      }
      if (kDebugMode) {
        print('Response body: $responseBody');
      }
      return null;
    }
  } catch (error) {
    // Log any other errors that occurred during the request
    if (kDebugMode) {
      print('Error uploading issue records: $error');
    }
    return null;
  }
}

//insert Alexa Issues
Future insertAlexaRecords(
  String? uniqueId,
  String? issueExist,
  String? issueValue,
  String? alexa_issue_img,
  String? issueDescription,
  String? reportedOn,
  String? reportedBy,
  String? resolvedOn,
  String? resolvedBy,
  String? issueStatus,
  String? other,
  String? missing,
  String? notConfigured,
  String? notConnecting,
  String? notCharging,
  int? id,
) async {
  if (uniqueId == null || issueExist == null) {
    if (kDebugMode) {
      print('Missing critical data: uniqueId or issueExist is null.');
    }
    return null;
  }


  if (kDebugMode) {
    print('Insert Alexa issue records called');
    print('uniqueId: $uniqueId');
    print('issueExist: $issueExist');
    print('issueValue: $issueValue');
    print('alexa_issue_img: $alexa_issue_img');
    print('issueDescription: $issueDescription');
    print('reportedOn: $reportedOn');
    print('reportedBy: $reportedBy');
    print('resolvedOn: $resolvedOn');
    print('resolvedBy: $resolvedBy');
    print('issueStatus: $issueStatus');
    print('other: $other');
    print('missing: $missing');
    print('notConfigured: $notConfigured');
    print('notConnecting: $notConnecting');
    print('notCharging: $notCharging');
  }

  var request = http.MultipartRequest(
    'POST',
    Uri.parse('${baseurl}IssueTracker/issueTrackerSave_new.php'),
  );
  request.headers["Accept"] = "Application/json";

  request.fields.addAll({
    'unique_id': uniqueId,
    'alexa_issue': issueExist.toString(),
    'alexa_issue_value': issueValue.toString(),
    'alexa_desc': issueDescription.toString(),
    'alexa_reported_on': reportedOn.toString(),
    'alexa_reported_by': reportedBy.toString(),
    'alexa_issue_status': issueStatus.toString(),
    'alexa_resolved_on': resolvedOn.toString(),
    'alexa_resolved_by': resolvedBy.toString(),
    'other': other.toString(),
    'missing': missing.toString(),
    'not_configured': notConfigured.toString(),
    'not_connecting': notConnecting.toString(),
    'not_charging': notCharging.toString(),
  });

  if (kDebugMode) {
    print('Stage 1: Text fields added to the request');
  }

  if (alexa_issue_img != null && alexa_issue_img.isNotEmpty) {
    List<String> imagePaths = alexa_issue_img.split(',');

    for (String path in imagePaths) {
      File imageFile = File(path.trim());
      if (imageFile.existsSync()) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'alexa_issue_img[]', // Use array-like name for multiple images
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

  try {
    var response = await request.send();
    var responseBody = await response.stream.bytesToString();
    var parsedResponse = json.decode(responseBody);

    if (kDebugMode) {
      print('Response status: ${response.statusCode}');
    }
    if (kDebugMode) {
      print('Response body: $responseBody');
    }

    if (response.statusCode == 200 && parsedResponse['status'] == 1) {
      await SqfliteDatabaseHelper().queryDelete(
        arg: uniqueId.toString(),
        table: 'alexa_issue',
        field: 'unique_id',
      );
      await SqfliteDatabaseHelper().queryDelete(
        arg: uniqueId.toString(),
        table: 'issueTracker',
        field: 'uniqueId',
      );

      await Get.find<IssueTrackerController>().fetchData();
      if (kDebugMode) {
        print('Issue records uploaded successfully.');
      }
    } else {
      if (kDebugMode) {
        print('Failed to upload issue records. Response: $parsedResponse');
      }
    }
    return parsedResponse;
  } catch (error) {
    if (kDebugMode) {
      print('Error uploading issue records: $error');
    }
    return null;
  }
}
