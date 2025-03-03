import 'dart:io';
import 'package:offline17000ft/constants/color_const.dart';
import 'package:offline17000ft/forms/school_enrolment/school_enrolment_model.dart';
import 'package:offline17000ft/helper/database_helper.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../base_client/baseClient_controller.dart';

class SchoolEnrolmentController extends GetxController with BaseController {
  String? _tourValue;
  String? get tourValue => _tourValue;

  //school Value
  String? _schoolValue;
  String? get schoolValue => _schoolValue;

  bool isLoading = false;

  final TextEditingController remarksController = TextEditingController();

  //Focus nodes
  final FocusNode _tourIdFocusNode = FocusNode();
  FocusNode get tourIdFocusNode => _tourIdFocusNode;
  final FocusNode _schoolFocusNode = FocusNode();
  FocusNode get schoolFocusNode => _schoolFocusNode;

  List<EnrolmentCollectionModel> _enrolmentList = [];
  List<EnrolmentCollectionModel> get enrolmentList => _enrolmentList;

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
    update();
  }

  setTour(value) {
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
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                onPressed: () async {
                  await takePhoto(ImageSource.gallery);
                  Get.back();
                },
                child: const Text(
                  'Gallery',
                  style: TextStyle(fontSize: 20.0, color: AppColors.primary),
                ),
              ),
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
              child: Image.file(File(imagePath), fit: BoxFit.contain),
            ),
          ),
        );
      },
    );
  }

  //Clear fields
  void clearFields() {
    _tourValue = null;
    _schoolValue = null;
    remarksController.clear();
    _multipleImage.clear();
    _imagePaths.clear();
    update();
  }

  fetchData() async {
    isLoading = true;

    _enrolmentList = [];
    _enrolmentList = await LocalDbController().fetchLocalEnrolmentRecord();

    update();
  }

//

//Update the UI
}
