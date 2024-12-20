import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'version_controller.dart'; // Import your controller



//  No use in the project


class VersionCheckPage extends StatelessWidget {
  final VersionController versionController = Get.put(VersionController());

   VersionCheckPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Version Check'),
      ),
      body: Obx(() {
        if (versionController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        } else {
          return Center(
            child: Text(
              'Current Version: ${versionController.version.value}',
              style: const TextStyle(fontSize: 20),
            ),
          );
        }
      }),
    );
  }
}
