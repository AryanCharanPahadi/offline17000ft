import 'package:offline17000ft/components/circular_indicator.dart';
import 'package:offline17000ft/components/custom_drawer.dart';
import 'package:offline17000ft/constants/color_const.dart';
import 'package:offline17000ft/forms/fln_observation_form/fln_observation_form.dart';
import 'package:offline17000ft/forms/inPerson_qualitative_form/inPerson_qualitative_form.dart';
import 'package:offline17000ft/forms/in_person_quantitative/in_person_quantitative.dart';
import 'package:offline17000ft/forms/school_enrolment/school_enrolment.dart';
import 'package:offline17000ft/forms/school_recce_form/school_recce_form.dart';
import 'package:offline17000ft/helper/api_services.dart';
import 'package:offline17000ft/helper/responsive_helper.dart';
import 'package:offline17000ft/home/home_controller.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../components/custom_confirmation.dart';
import '../components/custom_snackbar.dart';
import '../forms/alfa_observation_form/alfa_observation_form.dart';
import '../forms/cab_meter_tracking_form/cab_meter.dart';
import '../forms/issue_tracker/issue_tracker_form.dart';
import '../forms/school_facilities_&_mapping_form/SchoolFacilitiesForm.dart';
import '../forms/school_staff_vec_form/school_vec_from.dart';
import '../forms/user_controller/user_controller.dart';
import '../helper/shared_prefernce.dart';
import '../login/login_screen.dart';

import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

import '../version_file/version_controller.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final VersionController versionController = Get.put(VersionController());

  bool _isOnline = false;
  bool _isPermissionGranted = false;
  @override
  void initState() {
    super.initState();
    _initializeConnectivity();
    _checkPermissionStatus(); // Check permission on app startup
    versionController.fetchVersion(); // Fetch version when HomeScreen is loaded
  }

  Future<void> _checkPermissionStatus() async {
    if (await requestPermission()) {
      setState(() {
        _isPermissionGranted = true;
      });
    }
  }

  Future<bool> requestPermission() async {
    if (Platform.isAndroid) {
      var androidInfo = await DeviceInfoPlugin().androidInfo;

      if (androidInfo.version.sdkInt >= 30) {
        var manageStoragePermission =
            await Permission.manageExternalStorage.status;
        if (manageStoragePermission.isDenied) {
          manageStoragePermission =
              await Permission.manageExternalStorage.request();
          return manageStoragePermission.isGranted;
        }
        return true;
      }

      if (await Permission.storage.isDenied) {
        var permissionStatus = await Permission.storage.request();
        return permissionStatus.isGranted;
      }
    } else if (Platform.isIOS) {
      // For iOS, assuming permission is granted as it's not usually needed
      return true;
    }
    return true;
  }

  Future<void> _initializeConnectivity() async {
    // Check initial connectivity status and update the state
    _isOnline = await _checkConnectivity();
    setState(() {});

    // Listen for connectivity changes
    Connectivity().onConnectivityChanged.listen((result) {
      setState(() {
        _isOnline = result != ConnectivityResult.none;
      });
    });
  }

  Future<void> _refreshStatus() async {
    _isOnline = await _checkConnectivity();
    setState(() {});
  }

  Future<bool> _checkConnectivity() async {
    ConnectivityResult result = await Connectivity().checkConnectivity();
    bool isConnected = result != ConnectivityResult.none;

    // Optional: log the result for debugging
    if (kDebugMode) {
      print('Connectivity check result: $result, is connected: $isConnected');
    }

    return isConnected;
  }

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);

    return WillPopScope(
      onWillPop: () async {
        return await showDialog(
          context: context,
          builder: (_) => Confirmation(
            iconname: Icons.check_circle,
            title: 'Exit Confirmation',
            yes: 'Ok',
            desc: 'To leave this screen you have to close the app',
            onPressed: () {},
          ),
        );
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Home',
            style: AppStyles.appBarTitle(context, AppColors.onPrimary),
          ),
          backgroundColor: AppColors.primary,
          iconTheme: IconThemeData(
              color: Colors.white), // Set drawer icon color to white
          actions: [
            Row(
              children: [
                // Grant Permission Button (Visible only if permission is not granted)
                if (!_isPermissionGranted)
                  IconButton(
                    icon: Icon(Icons.lock_open, color: Colors.white),
                    onPressed: () async {
                      if (await requestPermission()) {
                        setState(() {
                          _isPermissionGranted = true;
                        });
                      }
                    },
                  ),
                const SizedBox(width: 20),

                Icon(
                  _isOnline ? Icons.wifi : Icons.wifi_off,
                  color: _isOnline ? Colors.white : Colors.red,
                ),
                const SizedBox(width: 5),
                Text(
                  _isOnline ? 'Online' : 'Offline',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(width: 20),
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.white),
                  onPressed: () async {
                    await _handleLogout();
                  },
                ),
              ],
            ),
          ],
        ),
        drawer: const CustomDrawer(),
        body: RefreshIndicator(
          onRefresh: _refreshStatus,
          child: GetBuilder<HomeController>(
            init: HomeController(),
            builder: (homeController) {
              if (homeController.isLoading) {
                return const Center(
                  child: TextWithCircularProgress(
                    text: 'Loading...',
                    indicatorColor: AppColors.primary,
                    fontsize: 14,
                    strokeSize: 2,
                  ),
                );
              }
              return homeController.offlineTaskList.isNotEmpty
                  ? _buildOfflineTaskGrid(homeController, responsive)
                  : _buildNoDataMessage();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildOfflineTaskGrid(
      HomeController homeController, Responsive responsive) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [AppColors.inverseOnSurface, AppColors.outlineVariant],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(
            responsive.responsiveValue(small: 10.0, medium: 15.0, large: 20.0)),
        child: SingleChildScrollView(
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            padding: EdgeInsets.all(responsive.responsiveValue(
                small: 8.0, medium: 10.0, large: 12.0)),
            itemCount: homeController.offlineTaskList.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount:
                  responsive.responsiveValue(small: 2, medium: 3, large: 4),
              crossAxisSpacing: responsive.responsiveValue(
                  small: 10.0, medium: 20.0, large: 30.0),
              mainAxisSpacing: responsive.responsiveValue(
                  small: 10.0, medium: 20.0, large: 30.0),
              childAspectRatio: 1.3,
            ),
            itemBuilder: (context, index) {
              return _buildTaskCard(homeController.offlineTaskList[index],
                  homeController, responsive);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTaskCard(
      String task, HomeController homeController, Responsive responsive) {
    return InkWell(
      onTap: () => _navigateToForm(task, homeController),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: AppColors.background,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 5,
              blurRadius: 4,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(responsive.responsiveValue(
                small: 8.0, medium: 10.0, large: 12.0)),
            child: Text(
              task,
              textAlign: TextAlign.center,
              style: AppStyles.captionText(
                context,
                AppColors.onBackground,
                responsive.responsiveValue(small: 12, medium: 14, large: 16),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoDataMessage() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.onSurface, AppColors.tertiaryFixedDim],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
      ),
      child: const Center(child: Text('No Data Found')),
    );
  }

  Future<void> _handleLogout() async {
    final UserController userController = Get.put(UserController());

    // Clear user data and tour details
    await ApiService()
        .clearTourDetailsOnLogout(); // Clear tour details before logout

    userController.clearUserData();
    await SharedPreferencesHelper.logout();

    Get.offAll(() => const LoginScreen());

    customSnackbar(
      'Success',
      'You have been logged out successfully.',
      AppColors.secondary,
      AppColors.onSecondary,
      Icons.verified,
    );
  }

  void _navigateToForm(String task, HomeController homeController) {
    final navigationMap = {
      'ALfA Observation Form': () => AlfaObservationForm(
          userid: homeController.empId, office: homeController.office),
      'Cab Meter Tracing Form': () => CabMeterTracingForm(
          userid: homeController.empId,
          office: homeController.office,
          version: homeController.version),
      'FLN Observation Form': () => FlnObservationForm(
          userid: homeController.empId, office: homeController.office),
      'In Person Monitoring Quantitative': () => InPersonQuantitative(
          userid: homeController.empId, office: homeController.office),
      'In Person Monitoring Qualitative': () => InPersonQualitativeForm(
          userid: homeController.empId, office: homeController.office),
      'Issue Tracker (New)': () => IssueTrackerForm(
          userid: homeController.empId, office: homeController.office),
      'School Enrollment Form': () => SchoolEnrollmentForm(
          userid: homeController.empId, office: homeController.office),
      'School Facilities Mapping Form': () => SchoolFacilitiesForm(
          userid: homeController.empId, office: homeController.office),
      'School Staff & SMC/VEC Details': () => SchoolStaffVecForm(
          userid: homeController.empId, office: homeController.office),
      'School Recce Form': () => SchoolRecceForm(
          userid: homeController.empId, office: homeController.office),
    };

    if (navigationMap.containsKey(task)) {
      Get.to(() => navigationMap[task]!());
    }
  }
}
