import 'dart:io';
import 'package:offline17000ft/constants/color_const.dart';
import 'package:offline17000ft/forms/inPerson_qualitative_form/inPerson_qualitative_modal.dart';
import 'package:offline17000ft/helper/database_helper.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../base_client/baseClient_controller.dart';

class InpersonQualitativeController extends GetxController with BaseController {
  String? _tourValue;
  String? get tourValue => _tourValue;

  //school Value
  String? _schoolValue;
  String? get schoolValue => _schoolValue;

  bool isLoading = false;

  final TextEditingController remarksController = TextEditingController();
  final TextEditingController correctUdiseCodeController =
      TextEditingController();
  final TextEditingController schoolRoutineController = TextEditingController();
  final TextEditingController componentsController = TextEditingController();
  final TextEditingController programInitiatedController =
      TextEditingController();
  final TextEditingController digiLabSessionController =
      TextEditingController();
  final TextEditingController alexaEchoController = TextEditingController();
  final TextEditingController servicesController = TextEditingController();
  final TextEditingController suggestionsController = TextEditingController();
  final TextEditingController allowingTabletsController =
      TextEditingController();
  final TextEditingController alexaSessionsController = TextEditingController();
  final TextEditingController smcQues7 = TextEditingController();
  final TextEditingController improveProgramController =
      TextEditingController();
  final TextEditingController notAbleController = TextEditingController();
  final TextEditingController operatingDigiLabController =
      TextEditingController();
  final TextEditingController difficultiesController = TextEditingController();
  final TextEditingController improvementController = TextEditingController();
  final TextEditingController studentLearningController =
      TextEditingController();
  final TextEditingController negativeImpactController =
      TextEditingController();
  final TextEditingController teacherFeelsLessController =
      TextEditingController();
  final TextEditingController factorsPreventingController =
      TextEditingController();
  final TextEditingController additionalSubjectsController =
      TextEditingController();
  final TextEditingController feedbackController = TextEditingController();
  final TextEditingController notAbleTeacherInterviewController =
      TextEditingController();
  final TextEditingController navigatingDigiLabController =
      TextEditingController();
  final TextEditingController componentsDigiLabController =
      TextEditingController();
  final TextEditingController timeDigiLabController = TextEditingController();
  final TextEditingController booksReadingController = TextEditingController();
  final TextEditingController libraryController = TextEditingController();
  final TextEditingController playingplaygroundController =
      TextEditingController();
  final TextEditingController questionsAlexaController =
      TextEditingController();
  final TextEditingController questionsAlexaNotAbleController =
      TextEditingController();
  final TextEditingController additionalTypeController =
      TextEditingController();
  final TextEditingController interviewStudentsNotController =
      TextEditingController();
  final TextEditingController administrationSchoolController =
      TextEditingController();
  final TextEditingController issuesResolveController = TextEditingController();
  final TextEditingController fearsController = TextEditingController();
  final TextEditingController easeController = TextEditingController();
  final TextEditingController guidanceController = TextEditingController();
  final TextEditingController feedbackDigiLabController =
      TextEditingController();
  final TextEditingController effectiveDigiLabController =
      TextEditingController();
  final TextEditingController suggestionsProgramController =
      TextEditingController();
  final TextEditingController playgroundAllowedController =
      TextEditingController();

  // Start of Showing
  bool showBasicDetails = true; // For show Basic Details
  bool showInputs = false; // For show Inputs Details
  bool showSchoolTeacher = false; // For show showSchoolTeacher
  bool showInputStudents = false; // For show showInputStudents
  bool showSmcMember = false; // For show showSmcMember
  // End of Showing
  bool isImageUploadedSchoolBoard = false;
  bool validateSchoolBoard = false;

  // Map to store selected values for radio buttons
  final Map<String, String?> _selectedValues = {};
  String? getSelectedValue(String key) => _selectedValues[key];

  // Map to store error states for radio buttons
  final Map<String, bool> _radioFieldErrors = {};
  bool getRadioFieldError(String key) => _radioFieldErrors[key] ?? false;

  // Method to set the selected value and clear any previous error
  void setRadioValue(String key, String? value) {
    _selectedValues[key] = value;
    _radioFieldErrors[key] = false; // Clear error when a value is selected
    update(); // Update the UI
  }

  // Method to validate radio button selection
  bool validateRadioSelection(String key) {
    if (_selectedValues[key] == null) {
      _radioFieldErrors[key] = true;
      update(); // Update the UI
      return false;
    }
    _radioFieldErrors[key] = false;
    update(); // Update the UI
    return true;
  }

  // Method to clear the selected value for a given key
  void clearRadioValue(String key) {
    _selectedValues[key] = null; // Clear the value
    update(); // Update the UI
  }

  //Focus nodes
  final FocusNode _tourIdFocusNode = FocusNode();
  FocusNode get tourIdFocusNode => _tourIdFocusNode;
  final FocusNode _schoolFocusNode = FocusNode();
  FocusNode get schoolFocusNode => _schoolFocusNode;

  List<InPersonQualitativeRecords> _inPersonQualitativeList = [];
  List<InPersonQualitativeRecords> get inPersonQualitativeList =>
      _inPersonQualitativeList;

  final List<XFile> _multipleImage = [];
  List<XFile> get multipleImage => _multipleImage;
  final List<String> _imagePaths = [];
  List<String> get imagePaths => _imagePaths;

  Future<String> takePhoto(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    List<XFile> selectedImages = [];
    XFile? pickedImage;


    if (source == ImageSource.gallery) {
      selectedImages = await picker.pickMultiImage(
        imageQuality: 50, // Set the image quality (0-100)
        maxWidth: 800, // Set the max width
        maxHeight: 600, // Set the max height
      );
      for (var selectedImage in selectedImages) {
        // Add the selected image path directly without compression
        _multipleImage.add(selectedImage);
        _imagePaths.add(selectedImage.path);
      }
      update();
    } else if (source == ImageSource.camera) {
      pickedImage = await picker.pickImage(
        source: source,
        imageQuality: 50, // Set the image quality (0-100)
        maxWidth: 800, // Set the max width
        maxHeight: 600, // Set the max height
      );
      if (pickedImage != null) {
        // Add the picked image path directly without compression
        _multipleImage.add(pickedImage);
        _imagePaths.add(pickedImage.path);
      }
      update();
    }

    return _imagePaths.toString();
  }

  setSchool(value) {
    _schoolValue = value;
    // update();
  }

  setTour(value) {
    _tourValue = value;
    // update();
  }

  Widget bottomSheet(BuildContext context) {
    return Container(
      color: AppColors.primary,
      height: 100,
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        children: <Widget>[
          const Text(
            "Select Image",
            style: TextStyle(fontSize: 20.0, color: Colors.white),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                onPressed: () async {
                  await takePhoto(ImageSource.camera);
                  Get.back();
                },
                child: const Text(
                  'Camera',
                  style: TextStyle(fontSize: 20.0, color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 30),
            ],
          )
        ],
      ),
    );
  }


  void showImagePreview(String imagePath, BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(10),
            ),
            child: GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              child: Image.file(
                File(imagePath),
                fit: BoxFit.contain,
              ),
            ),
          ),
        );
      },
    );
  }

  //Clear fields
  void clearFields() {
    update();
  }

  fetchData() async {
    isLoading = true;

    _inPersonQualitativeList = [];
    _inPersonQualitativeList =
        await LocalDbController().fetchLocalInPersonQualitativeRecords();

    update();
  }

  void removeRecordFromList(int id) {
    _inPersonQualitativeList
        .removeWhere((record) => record.id == id); // Remove synced record
    update(); // Refresh the UI
  }
//

//Update the UI
}
