import 'package:offline17000ft/forms/fln_observation_form/fln_observation_controller.dart';
import 'package:offline17000ft/forms/in_person_quantitative/in_person_quantitative_controller.dart';
import 'package:offline17000ft/forms/issue_tracker/issue_tracker_controller.dart';
import 'package:offline17000ft/forms/school_enrolment/school_enrolment_controller.dart';
import 'package:offline17000ft/forms/school_facilities_&_mapping_form/school_facilities_controller.dart';
import 'package:offline17000ft/forms/school_staff_vec_form/school_vec_controller.dart';
import 'package:offline17000ft/forms/select_tour_id/select_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:connectivity_plus/connectivity_plus.dart'; // For checking network status
import 'dart:convert'; // For jsonDecode
import 'package:http/http.dart' as http; // For HTTP requests
import '../../components/custom_appBar.dart';
import '../../components/custom_confirmation.dart';
import '../../components/custom_sizedBox.dart';
import '../../components/custom_button.dart';
import '../../components/custom_labeltext.dart';
import '../../helper/database_helper.dart';
import '../../home/home_screen.dart';
import '../cab_meter_tracking_form/cab_meter_tracing_controller.dart';
import '../inPerson_qualitative_form/in_person_qualitative_controller.dart';
import '../school_recce_form/school_recce_controller.dart';

class SelectForm extends StatefulWidget {
  const SelectForm({super.key});

  @override
  SelectFormState createState() => SelectFormState();
}

class SelectFormState extends State<SelectForm> {
  bool isConnected = true; // To track network connection status
  final schoolEnrolmentController = Get.put(SchoolEnrolmentController());
  final cabMeterTracingController = Get.put(CabMeterTracingController());
  final inPersonQuantitativeController =
      Get.put(InPersonQuantitativeController());
  final inpersonQualitativeController =
      Get.put(InpersonQualitativeController());
  final issueTrackerController = Get.put(IssueTrackerController());
  final flnObservationController = Get.put(FlnObservationController());
  final schoolStaffVecController = Get.put(SchoolStaffVecController());
  final schoolFacilitiesController = Get.put(SchoolFacilitiesController());
  final schoolRecceController = Get.put(SchoolRecceController());

  @override
  void initState() {
    super.initState();
    _checkConnectivity(); // Initial connectivity check
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      // Listen for connectivity changes and update UI
      setState(() {
        isConnected = (result != ConnectivityResult.none);
      });
    });
  }

  Future<bool> checkDataInTable(String tableName) async {
    final conn = SqfliteDatabaseHelper.instance;
    final dbClient = await conn.db;

    try {
      List<Map<String, dynamic>> maps = await dbClient.rawQuery(
        'SELECT COUNT(*) AS count FROM $tableName',
      );

      if (maps.isNotEmpty && maps[0]['count'] > 0) {
        return true; // Data exists
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error checking data in table $tableName: $e");
      }
    }
    return false; // No data found
  }

  Future<void> _checkConnectivity() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    setState(() {
      isConnected = (connectivityResult != ConnectivityResult.none);
    });
  }

  Future<void> fetchData(
      String tourId, List<String> schools, BuildContext context) async {
    if (isConnected) {
      // Fetch data from the API when online
      final url =
          'https://mis.17000ft.org/apis/fast_apis/pre-fill-data.php?id=$tourId';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data != null && data.isNotEmpty) {
          List<String> allSchools = [];

          // Loop through each school in the response
          for (var schoolName in data.keys) {
            allSchools.add(schoolName);
            var schoolData = data[schoolName];

            if (schoolData != null) {
              // Save each school's form data to the local DB
              await saveFormDataToLocalDB(tourId, schoolName, schoolData);
            }
          }
        }
      }
    }
  }

  Future<void> saveFormDataToLocalDB(
      String tourId, String school, Map<String, dynamic> formData) async {
    try {
      final dbHelper = SqfliteDatabaseHelper();
      await dbHelper.insertFormData(tourId, school, formData);
    } catch (e) {
      if (kDebugMode) {
        print("Error saving data to SQLite: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppbar(
        title: 'Select Tour Id',
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          controller: Get.put(SelectController()).scrollController,
          child: Column(
            children: [
              GetBuilder<SelectController>(
                init: SelectController(),
                builder: (selectController) {
                  selectController.tourController.fetchTourDetails();

                  // Get the list of tour IDs
                  List<String?> tourIds = selectController
                      .tourController.getLocalTourList
                      .map((e) => e.tourId)
                      .toList();

                  return Form(
                    key: selectController.formKey,
                    child: Column(
                      children: [
                        CustomSizedBox(value: 20, side: 'height'),

                        // Display "You are offline" message when offline
                        if (!isConnected)
                          const Center(
                            child: Text(
                              'You are offline',
                              style: TextStyle(
                                fontSize: 20,
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),

                        // Show radio buttons and submit button when online
                        if (isConnected) ...[
                          LabelText(label: 'Select Tour Id', astrick: false),
                          CustomSizedBox(value: 20, side: 'height'),
                          // Radio buttons for selecting a tour ID
                          Column(
                            children: tourIds.map((tourId) {
                              return RadioListTile<String?>(
                                title: Text(tourId ?? ''),
                                value: tourId,
                                groupValue:
                                    selectController.selectedRadioTourId,
                                onChanged: (value) {
                                  selectController.selectedRadioTourId = value;
                                  selectController.setTour(value);
                                  selectController.updateSchoolList(value);
                                },
                              );
                            }).toList(),
                          ),
                          CustomSizedBox(value: 20, side: 'height'),

                          // Submit button
                          Row(
                            children: [
                              CustomButton(
                                title: 'Select',
                                onPressedButton: () async {
                                  print(
                                      'Select button pressed'); // Debug: Button pressed

                                  // List to track tables with data
                                  List<String> tablesWithData = [];

                                  // Check if there is data in the `schoolEnrolment` table
                                  bool hasDataInEnrolmentTable =
                                      await checkDataInTable(
                                          SqfliteDatabaseHelper
                                              .schoolEnrolment);
                                  if (hasDataInEnrolmentTable) {
                                    tablesWithData.add('schoolEnrolment');
                                  }
                                  print(
                                      'Has data in schoolEnrolment table: $hasDataInEnrolmentTable');

                                  // Check if there is data in the `schoolStaffVec` table
                                  bool hasDataInStaffVecTable =
                                      await checkDataInTable(
                                          SqfliteDatabaseHelper.schoolStaffVec);
                                  if (hasDataInStaffVecTable) {
                                    tablesWithData.add('schoolStaffVec');
                                  }
                                  print(
                                      'Has data in schoolStaffVec table: $hasDataInStaffVecTable');

                                  // Check if there is data in the `schoolFacilities` table
                                  bool hasDataInFacilitiesTable =
                                      await checkDataInTable(
                                          SqfliteDatabaseHelper
                                              .schoolFacilities);
                                  if (hasDataInFacilitiesTable) {
                                    tablesWithData.add('schoolFacilities');
                                  }
                                  print(
                                      'Has data in schoolFacilities table: $hasDataInFacilitiesTable');

                                  // Show a popup if data exists in any of the tables
                                  if (tablesWithData.isNotEmpty) {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        List<String> tablesWithData = [];

                                        // Check if there is data in the tables
                                        if (hasDataInEnrolmentTable) {
                                          tablesWithData
                                              .add('School Enrollment Form');
                                        }
                                        if (hasDataInStaffVecTable) {
                                          tablesWithData.add('School Vec Form');
                                        }
                                        if (hasDataInFacilitiesTable) {
                                          tablesWithData
                                              .add('School Facilities Form');
                                        }

                                        return Confirmation(
                                          desc:
                                              'Please sync all data from the following forms before proceeding:\n\n${tablesWithData.join(', ')}',
                                          title: 'Data Exists',
                                          yes: 'OK',
                                          no: null, // No "Cancel" button needed
                                          iconname: Icons
                                              .warning, // Use an appropriate icon
                                          onPressed: () {
                                            print(
                                                'OK button pressed in Confirmation dialog');
                                            Navigator.of(context)
                                                .pop(); // Close the dialog
                                          },
                                        );
                                      },
                                    );

                                    return; // Stop further execution
                                  }

                                  print(
                                      'Clearing the schoolEnrolment, schoolStaffVec, and schoolFacilities tables'); // Debug: Clearing tables
                                  // Clear the local database tables
                                  final dbHelper = SqfliteDatabaseHelper();
                                  await dbHelper.delete(
                                      SqfliteDatabaseHelper.schoolEnrolment);
                                  print(
                                      'schoolEnrolment table cleared'); // Debug: Table cleared
                                  await dbHelper.delete(
                                      SqfliteDatabaseHelper.schoolStaffVec);
                                  print(
                                      'schoolStaffVec table cleared'); // Debug: Table cleared
                                  await dbHelper.delete(
                                      SqfliteDatabaseHelper.schoolFacilities);
                                  print(
                                      'schoolFacilities table cleared'); // Debug: Table cleared
                                  await dbHelper.delete(
                                      SqfliteDatabaseHelper.formDataTable);
                                  print(
                                      'formDataTable table cleared'); // Debug: Table cleared

                                  // Continue with existing logic...
                                  if (selectController.selectedRadioTourId !=
                                      null) {
                                    print(
                                        'Selected tour ID: ${selectController.selectedRadioTourId}'); // Debug: Selected tour ID

                                    List<String> schoolsToLock =
                                        selectController.schoolValue != null
                                            ? [selectController.schoolValue!]
                                            : selectController.splitSchoolLists;
                                    print(
                                        'Schools to lock: $schoolsToLock'); // Debug: Schools to lock

                                    selectController.lockTourAndSchools(
                                      selectController.selectedRadioTourId!,
                                      schoolsToLock,
                                    );
                                    print(
                                        'Tour and schools locked'); // Debug: Lock successful

                                    // Fetch new data and save it to the local database
                                    print(
                                        'Fetching data for tour ID: ${selectController.selectedRadioTourId}');
                                    await fetchData(
                                      selectController.selectedRadioTourId!,
                                      schoolsToLock,
                                      context,
                                    );
                                    print(
                                        'Data fetched and saved to local DB'); // Debug: Data fetch successful

                                    WidgetsBinding.instance
                                        .addPostFrameCallback((_) {
                                      print(
                                          'Navigating to HomeScreen'); // Debug: Navigation
                                      Navigator.of(context).pushReplacement(
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const HomeScreen(),
                                        ),
                                      );
                                    });
                                  } else {
                                    print(
                                        'No tour ID selected'); // Debug: No selection
                                  }
                                },
                              ),

                              // Unlock button
                              CustomButton(
                                title: 'Unselect',
                                onPressedButton: () async {
                                  selectController.unlockTourAndSchools();
                                  selectController.unlockTourId();
                                },
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
