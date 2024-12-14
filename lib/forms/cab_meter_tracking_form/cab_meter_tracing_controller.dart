import 'dart:io';
import 'package:offline17000ft/constants/color_const.dart';
import 'package:offline17000ft/helper/database_helper.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../base_client/baseClient_controller.dart';
import 'cab_meter_tracing_modal.dart';

class CabMeterTracingController extends GetxController with BaseController {
  String? _tourValue;
  String? get tourValue => _tourValue;

  String? _schoolValue;
  String? get schoolValue => _schoolValue;

  bool isLoading = false;

  final TextEditingController remarksController = TextEditingController();
  final TextEditingController driverNameController = TextEditingController();
  final TextEditingController meterReadingController = TextEditingController();
  final TextEditingController placeVisitedController = TextEditingController();
  final TextEditingController statusController = TextEditingController();
  final TextEditingController vehicleNumberController = TextEditingController();

  final Map<String, String?> _selectedValues = {};
  String? getSelectedValue(String key) => _selectedValues[key];

  final Map<String, bool> _radioFieldErrors = {};
  bool getRadioFieldError(String key) => _radioFieldErrors[key] ?? false;

  void setRadioValue(String key, String? value) {
    _selectedValues[key] = value;
    _radioFieldErrors[key] = false;
    update();
  }

  bool validateRadioSelection(String key) {
    if (_selectedValues[key] == null) {
      _radioFieldErrors[key] = true;
      update();
      return false;
    }
    _radioFieldErrors[key] = false;
    return true;
  }

  // Focus nodes
  final FocusNode _tourIdFocusNode = FocusNode();
  FocusNode get tourIdFocusNode => _tourIdFocusNode;

  final FocusNode _schoolFocusNode = FocusNode();
  FocusNode get schoolFocusNode => _schoolFocusNode;

  List<CabMeterTracingRecords> _cabMeterTracingList = [];
  List<CabMeterTracingRecords> get cabMeterTracingList => _cabMeterTracingList;

  final List<XFile> _multipleImage = [];
  List<XFile> get multipleImage => _multipleImage;

  final List<String> _imagePaths = [];
  List<String> get imagePaths => _imagePaths;

  Future<String> takePhoto(ImageSource source) async {
    final ImagePicker picker = ImagePicker();

    // Use the imageQuality parameter to reduce the quality
    XFile? pickedImage = await picker.pickImage(
      source: source,
      maxWidth: 800, // Set maximum width for the image
      maxHeight: 600, // Set maximum height for the image
      imageQuality:
          50, // Set the image quality (0-100, where 100 is the highest)
    );

    if (pickedImage != null) {
      // Clear previous selections
      _multipleImage.clear();
      _imagePaths.clear();

      // Add the picked image path to the lists
      _multipleImage.add(pickedImage);
      _imagePaths.add(pickedImage.path);
    }

    update();
    return _imagePaths.toString();
  }

  void setSchool(String? value) {
    _schoolValue = value;
    update();
  }

  void setTour(String? value) {
    _tourValue = value;
    update();
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

  void clearFields() {
    placeVisitedController.clear();
    vehicleNumberController.clear();
    driverNameController.clear();
    meterReadingController.clear();
    remarksController.clear();
    _tourValue = null;
    _multipleImage.clear();
    _imagePaths.clear();
    update();
  }

  Future<void> fetchData() async {
    isLoading = true;
    _cabMeterTracingList =
        await LocalDbController().fetchLocalCabMeterTracingRecord();
    isLoading = false;
    update(); // Refresh the UI
  }

  void removeRecordFromList(int id) {
    _cabMeterTracingList.removeWhere((record) => record.id == id);
    update(); // Refresh the UI
  }

  @override
  void onClose() {
    remarksController.dispose();
    driverNameController.dispose();
    meterReadingController.dispose();
    placeVisitedController.dispose();
    statusController.dispose();
    vehicleNumberController.dispose();
    _tourIdFocusNode.dispose();
    _schoolFocusNode.dispose();
    super.onClose();
  }
}
