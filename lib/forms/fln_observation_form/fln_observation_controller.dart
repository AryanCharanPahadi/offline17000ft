import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:offline17000ft/constants/color_const.dart';
import 'package:offline17000ft/forms/fln_observation_form/fln_observation_modal.dart';
import 'package:offline17000ft/helper/database_helper.dart';
import 'package:get/get.dart';
import '../../base_client/baseClient_controller.dart';

class FlnObservationController extends GetxController with BaseController{

  String? _tourValue;
  String? get tourValue => _tourValue;

  //school Value
  String? _schoolValue;
  String? get schoolValue => _schoolValue;

  bool isLoading = false;

  final TextEditingController remarksController = TextEditingController();
  final TextEditingController correctUdiseCodeController = TextEditingController();
  final TextEditingController noOfStaffTrainedController = TextEditingController();
  final TextEditingController moduleEnglishController = TextEditingController();
  final TextEditingController alfaNumercyController = TextEditingController();
  final TextEditingController noOfTeacherTrainedController = TextEditingController();


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
  FocusNode get  tourIdFocusNode => _tourIdFocusNode;
  final FocusNode _schoolFocusNode = FocusNode();
  FocusNode get  schoolFocusNode => _schoolFocusNode;

  List<FlnObservationModel> _flnObservationList =[];
  List<FlnObservationModel> get flnObservationList => _flnObservationList;

  final List<XFile> _multipleImage = [];
  List<XFile> get multipleImage => _multipleImage;
  final List<String> _imagePaths = [];
  List<String> get imagePaths => _imagePaths;

  final List<XFile> _multipleImage2 = [];
  List<XFile> get multipleImage2 => _multipleImage2;

  final List<String> _imagePaths2 = [];
  List<String> get imagePaths2 => _imagePaths2;


  final List<XFile> _multipleImage3 = [];
  List<XFile> get multipleImage3 => _multipleImage3;

  final List<String> _imagePaths3 = [];
  List<String> get imagePaths3 => _imagePaths3;

  final List<XFile> _multipleImage4 = [];
  List<XFile> get multipleImage4 => _multipleImage4;

  final List<String> _imagePaths4 = [];
  List<String> get imagePaths4 => _imagePaths4;


  final List<XFile> _multipleImage5 = [];
  List<XFile> get multipleImage5 => _multipleImage5;

  final List<String> _imagePaths5 = [];
  List<String> get imagePaths5 => _imagePaths5;


  final List<XFile> _multipleImage6 = [];
  List<XFile> get multipleImage6 => _multipleImage6;

  final List<String> _imagePaths6 = [];
  List<String> get imagePaths6 => _imagePaths6;



  final List<XFile> _multipleImage7 = [];
  List<XFile> get multipleImage7 => _multipleImage7;

  final List<String> _imagePaths7 = [];
  List<String> get imagePaths7 => _imagePaths7;


  final List<XFile> _multipleImage8 = [];
  List<XFile> get multipleImage8 => _multipleImage8;

  final List<String> _imagePaths8 = [];
  List<String> get imagePaths8 => _imagePaths8;



  final List<XFile> _multipleImage9 = [];
  List<XFile> get multipleImage9 => _multipleImage9;

  final List<String> _imagePaths9 = [];
  List<String> get imagePaths9 => _imagePaths9;



  Future<String> takePhoto(ImageSource source, int index) async {
    final ImagePicker picker = ImagePicker();
    List<XFile> selectedImages = [];
    XFile? pickedImage;

    // Determine which list to use based on the index parameter
    List<XFile> multipleImages;
    List<String> imagePaths;

    switch (index) {
      case 1:
        multipleImages = _multipleImage;
        imagePaths = _imagePaths;
        break;
      case 2:
        multipleImages = _multipleImage2;
        imagePaths = _imagePaths2;
        break;
      case 3:
        multipleImages = _multipleImage3;
        imagePaths = _imagePaths3;
        break;
      case 4:
        multipleImages = _multipleImage4;
        imagePaths = _imagePaths4;
        break;
      case 5:
        multipleImages = _multipleImage5;
        imagePaths = _imagePaths5;
        break;
      case 6:
        multipleImages = _multipleImage6;
        imagePaths = _imagePaths6;
        break;
      case 7:
        multipleImages = _multipleImage7;
        imagePaths = _imagePaths7;
        break;
      case 8:
        multipleImages = _multipleImage8;
        imagePaths = _imagePaths8;
        break;
      case 9:
        multipleImages = _multipleImage9;
        imagePaths = _imagePaths9;
        break;
      default:
        throw ArgumentError('Invalid index: $index');
    }

    if (source == ImageSource.gallery) {
      selectedImages = await picker.pickMultiImage(
        imageQuality: 50, // Set image quality (0-100, where 0 is lowest)
        maxWidth: 800,  // Set max width to resize
        maxHeight: 600, // Set max height to resize
      );
      for (var selectedImage in selectedImages) {
        // Add the selected image path directly
        multipleImages.add(selectedImage);
        imagePaths.add(selectedImage.path);
      }
      update();
    } else if (source == ImageSource.camera) {
      pickedImage = await picker.pickImage(
        source: source,
        imageQuality: 50, // Set image quality (0-100)
        maxWidth: 800,   // Set max width to resize
        maxHeight: 600,  // Set max height to resize
      );
      if (pickedImage != null) {
        // Add the picked image path directly
        multipleImages.add(pickedImage);
        imagePaths.add(pickedImage.path);
      }
      update();
    }

    return imagePaths.toString();
  }


  setSchool(value)
  {
    _schoolValue = value;
    // update();
  }

  setTour(value){
    _tourValue = value;
    // update();

  }

  Widget bottomSheet(BuildContext context, int index) {
    return Container(
      color: AppColors.primary,
      height: 100,
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        children: <Widget>[
          const Text("Select Image",
              style: TextStyle(fontSize: 20.0, color: Colors.white)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                onPressed: () async {
                  await takePhoto(ImageSource.camera, index);
                  Get.back();
                },
                child: const Text('Camera',
                    style: TextStyle(fontSize: 20.0, color: AppColors.primary)),
              ),
              const SizedBox(width: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                onPressed: () async {
                  await takePhoto(ImageSource.gallery, index);
                  Get.back();
                },
                child: const Text('Gallery',
                    style: TextStyle(fontSize: 20.0, color: AppColors.primary)),
              ),
            ],
          ),
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
              child: Image.file(File(imagePath), fit: BoxFit.contain),
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

    _flnObservationList = [];
    _flnObservationList = await LocalDbController().fetchLocalFlnObservationModel();


    update();
  }

  void removeRecordFromList(int id) {
    _flnObservationList.removeWhere((record) => record.id == id); // Remove synced record
    update();  // Refresh the UI
  }
//
}