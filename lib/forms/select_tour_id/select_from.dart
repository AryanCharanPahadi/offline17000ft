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
import '../../components/custom_sizedBox.dart';


import '../../components/custom_button.dart';
import '../../components/custom_labeltext.dart';
import '../../helper/database_helper.dart';
import '../../home/home_screen.dart';
import '../cab_meter_tracking_form/cab_meter_tracing_controller.dart';
import '../inPerson_qualitative_form/inPerson_qualitative_controller.dart';
import '../school_recce_form/school_recce_controller.dart';

class SelectForm extends StatefulWidget {
  const SelectForm({super.key});

  @override
  _SelectFormState createState() => _SelectFormState();
}

class _SelectFormState extends State<SelectForm> {
  bool isConnected = true; // To track network connection status
  final schoolEnrolmentController =
  Get.put(SchoolEnrolmentController());
  final cabMeterTracingController =
  Get.put(CabMeterTracingController());
  final inPersonQuantitativeController =
  Get.put(InPersonQuantitativeController());
  final inpersonQualitativeController =
  Get.put(InpersonQualitativeController());
  final issueTrackerController =
  Get.put(IssueTrackerController());
  final flnObservationController =
  Get.put(FlnObservationController());
  final schoolStaffVecController =
  Get.put(SchoolStaffVecController());
  final schoolFacilitiesController =
  Get.put(SchoolFacilitiesController());
  final schoolRecceController =
  Get.put(SchoolRecceController());
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
                                  if (selectController.selectedRadioTourId !=
                                      null) {
                                    // If no specific school is selected, lock all schools
                                    List<String> schoolsToLock =
                                    selectController.schoolValue != null
                                        ? [selectController.schoolValue!]
                                        : selectController.splitSchoolLists;

                                    // Lock the selected tour ID and schools
                                    selectController.lockTourAndSchools(
                                      selectController.selectedRadioTourId!,
                                      schoolsToLock,
                                    );

                                    // Fetch and save data in the background without navigating
                                    await fetchData(
                                        selectController.selectedRadioTourId!,
                                        schoolsToLock,
                                        context);

                                    // Navigate to the HomeScreen after data is fetched and saved
                                    Navigator.of(context).pushReplacement(
                                      MaterialPageRoute(
                                          builder: (context) => const HomeScreen()),
                                    );
                                  } else {
                                    // Handle the case where no tour ID is selected
                                    // Get.snackbar(
                                    //   'Error',
                                    //   'Please select a tour ID',
                                    //   snackPosition: SnackPosition.BOTTOM,
                                    // );
                                  }
                                },
                              ),

                              // Unlock button
                              CustomButton(
                                title: 'Unselect',
                                onPressedButton: () async {
                               await   selectController.unlockTourAndSchools();
                               schoolEnrolmentController.setTour(null);
                               schoolEnrolmentController.setSchool(null);
                               cabMeterTracingController.setTour(null);
                               cabMeterTracingController.setSchool(null);
                               inpersonQualitativeController.setTour(null);
                               inpersonQualitativeController.setSchool(null);
                               inPersonQuantitativeController.setTour(null);
                               inPersonQuantitativeController.setSchool(null);
                               issueTrackerController.setTour(null);
                               issueTrackerController.setSchool(null);
                               flnObservationController.setTour(null);
                               flnObservationController.setSchool(null);
                               schoolStaffVecController.setTour(null);
                               schoolStaffVecController.setSchool(null);
                               schoolFacilitiesController.setTour(null);
                               schoolFacilitiesController.setSchool(null);
                               schoolRecceController.setTour(null);
                               schoolRecceController.setSchool(null);
                                  //   'Unlocked',
                                  //   'All tour IDs and schools have been unlocked.',
                                  //   snackPosition: SnackPosition.BOTTOM,
                                  // );
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
