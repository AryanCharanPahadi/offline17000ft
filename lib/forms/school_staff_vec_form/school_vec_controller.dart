
import 'package:offline17000ft/forms/school_staff_vec_form/school_vec_modals.dart';
import 'package:offline17000ft/helper/database_helper.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../base_client/baseClient_controller.dart';

class SchoolStaffVecController extends GetxController with BaseController {
  var counterText = ''.obs;
  String? _tourValue;
  String? get tourValue => _tourValue;

  String? _schoolValue;
  String? get schoolValue => _schoolValue;

  bool isLoading = false;

  final TextEditingController nameOfHoiController = TextEditingController();
  final TextEditingController staffPhoneNumberController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController correctUdiseCodeController = TextEditingController();
  final TextEditingController totalTeachingStaffController = TextEditingController();
  final TextEditingController totalNonTeachingStaffController = TextEditingController();
  final TextEditingController totalStaffController = TextEditingController();
  final TextEditingController nameOfchairpersonController = TextEditingController();
  final TextEditingController chairPhoneNumberController = TextEditingController();
  final TextEditingController email2Controller = TextEditingController();
  final TextEditingController totalVecStaffController = TextEditingController();
  final TextEditingController QualSpecifyController = TextEditingController();
  final TextEditingController QualSpecify2Controller = TextEditingController();

  // Start of Showing Fields
  bool showBasicDetails = true; // For show Basic Details
  bool showStaffDetails = false; //For show and hide School Facilities
  bool showSmcVecDetails = false; //For show and hide Library
  // End of Showing Fields

  List<String> splitSchoolLists = [];
  String? selectedDesignation;
  String? selected2Designation;
  String? selected3Designation;

  // Start of selecting Field
  String? selectedValue = ''; // For the UDISE code
  String? selectedValue2 = ''; // For the Gender
  String? selectedValue3 = ''; // For the Gender2
  // End of selecting Field error

  // Start of radio Field
  bool radioFieldError = false; // For the UDISE code
  bool radioFieldError2 = false; // For the Gender
  bool radioFieldError3 = false; // For the Gender2

  // End of radio Field error


  final FocusNode _tourIdFocusNode = FocusNode();
  FocusNode get tourIdFocusNode => _tourIdFocusNode;

  final FocusNode _schoolFocusNode = FocusNode();
  FocusNode get schoolFocusNode => _schoolFocusNode;

  List<SchoolStaffVecRecords> _schoolStaffVecList = [];
  List<SchoolStaffVecRecords> get schoolStaffVecList => _schoolStaffVecList;



  void setSchool(String? value) {
    _schoolValue = value;


  }

  void setTour(String? value) {
    _tourValue = value;

  }


  void clearFields() {
    _tourValue = null;
    _schoolValue = null;
    correctUdiseCodeController.clear();
    nameOfHoiController.clear();
    staffPhoneNumberController.clear();
    emailController.clear();
    totalTeachingStaffController.clear();
    totalNonTeachingStaffController.clear();
    totalStaffController.clear();
    nameOfchairpersonController.clear();
    chairPhoneNumberController.clear();
    email2Controller.clear();
    totalVecStaffController.clear();
    QualSpecifyController.clear();
    QualSpecify2Controller.clear();

update();


  }

  Future<void> fetchData() async {
    isLoading = true;
    _schoolStaffVecList = [];
    _schoolStaffVecList = await LocalDbController().fetchLocalSchoolStaffVecRecords();
    update();
  }
}
