import 'package:offline17000ft/forms/issue_tracker/issue_tracker_controller.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import '../constants/color_const.dart';
import '../forms/cab_meter_tracking_form/cab_meter_tracing_sync.dart';
import '../forms/edit_form/edit_form_page.dart';
import '../forms/error_showng/error_log.dart';
import '../forms/fln_observation_form/fln_observation_sync.dart';
import '../forms/inPerson_qualitative_form/inPerson_qualitative_sync.dart';
import '../forms/in_person_quantitative/in_person_quantitative_sync.dart';
import '../forms/issue_tracker/issue_tracker_sync.dart';
import '../forms/school_enrolment/school_enrolment_sync.dart';
import '../forms/school_facilities_&_mapping_form/school_facilities_sync.dart';
import '../forms/school_recce_form/school_recce_sync.dart';
import '../forms/school_staff_vec_form/school_vec_sync.dart';
import '../forms/select_tour_id/select_from.dart';
import '../forms/user_controller/user_controller.dart';
import '../helper/api_services.dart';
import '../helper/responsive_helper.dart';
import '../helper/shared_prefernce.dart';
import '../change_password/change_pasword.dart';
import '../home/home_controller.dart';
import '../home/home_screen.dart';
import '../login/login_screen.dart';
import 'custom_snackbar.dart';

class CustomDrawer extends StatefulWidget {
  const CustomDrawer({super.key});

  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  final UserController _userController = Get.put(UserController());
  final HomeController _homeController = Get.put(HomeController());
  final IssueTrackerController _issueController = Get.put(IssueTrackerController());


  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);

    return Drawer(
      backgroundColor: AppColors.background,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildUserHeader(responsive),
          _buildDrawerMenuItems(),
        ],
      ),
    );
  }

  // Build the user header with user information
  Widget _buildUserHeader(Responsive responsive) {
    return GestureDetector(
      onTap: _userController.loadUserData, // Refresh user data on tap
      child: Container(
        color: AppColors.primary,
        height: responsive.responsiveValue(small: 250.0, medium: 260.0, large: 280.0),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.white,
              child: Icon(
                Icons.person,
                size: 60,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 15),
            Obx(() => Text(
              _userController.username.value.toUpperCase(),
              style: TextStyle(
                color: Colors.white,
                fontSize: responsive.responsiveValue(small: 18, medium: 20, large: 22),
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            )),
            const SizedBox(height: 8),
            Obx(() => Text(
              _userController.officeName.value.toUpperCase(),
              style: TextStyle(
                color: Colors.white,
                fontSize: responsive.responsiveValue(small: 16, medium: 18, large: 20),
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            )),
            const SizedBox(height: 8),
            Text(
              '4.0.0',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: responsive.responsiveValue(small: 14, medium: 16, large: 18),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Build the list of drawer menu items
  Widget _buildDrawerMenuItems() {
    return Column(
      children: [
        _buildDrawerMenu('Home', FontAwesomeIcons.house, () => _navigateTo(const HomeScreen())),
        _buildDrawerMenu('Change Password', FontAwesomeIcons.key, _navigateToChangePassword),
        _buildDrawerMenu('Edit Form', FontAwesomeIcons.penToSquare, () => _navigateTo(EditFormPage())),
        _buildDrawerMenu('Select Tour Id', FontAwesomeIcons.penToSquare, () => _navigateTo(SelectForm())),
        // _buildDrawerMenu('Alfa Observation Sync', FontAwesomeIcons.database, () => _syncNavigation(const AlfaObservationSync())),
        _buildDrawerMenu('Cab Meter Tracing Sync', FontAwesomeIcons.database, () => _syncNavigation(const CabTracingSync())),
        _buildDrawerMenu('Enrollment Sync', FontAwesomeIcons.database, () => _syncNavigation(const EnrolmentSync())),
        _buildDrawerMenu('FLN Observation Sync', FontAwesomeIcons.database, () => _syncNavigation(const FlnObservationSync())),
        _buildDrawerMenu('In Person Quantitative Sync', FontAwesomeIcons.database, () => _syncNavigation(const InPersonQuantitativeSync())),
        _buildDrawerMenu('IN-Person Qualitative Sync', FontAwesomeIcons.database, () => _syncNavigation(const InpersonQualitativeSync())),
        _buildDrawerMenu('Issue Tracker Sync', FontAwesomeIcons.database, () => _syncNavigation(const FinalIssueTrackerSync())),
        _buildDrawerMenu('School Facilities Mapping Form Sync', FontAwesomeIcons.database, () => _syncNavigation(const SchoolFacilitiesSync())),
        _buildDrawerMenu('School Staff & SMC/VEC Details Sync', FontAwesomeIcons.database, () => _syncNavigation(const SchoolStaffVecSync())),
        _buildDrawerMenu('School Recce Sync', FontAwesomeIcons.database, () => _syncNavigation(const SchoolRecceSync())),
        _buildDrawerMenu('Show Error', FontAwesomeIcons.triangleExclamation, () => _syncNavigation( ErrorLogsScreen())),
        _buildDrawerMenu('Logout', FontAwesomeIcons.arrowRightFromBracket, _handleLogout),
      ],
    );
  }

  // Drawer menu builder
  DrawerMenu _buildDrawerMenu(String title, IconData icon, VoidCallback onPressed) {
    return DrawerMenu(
      title: title,
      icon: FaIcon(icon),
      onPressed: onPressed,
    );
  }

  // Navigate to a specific screen
  void _navigateTo(Widget screen) {
    Navigator.pop(context);
    Get.to(() => screen);
  }

  // Navigate to the Change Password screen if empId is available
  void _navigateToChangePassword() {
    if (_homeController.empId?.isNotEmpty == true) {
      _navigateTo(ChangePassword(userid: _homeController.empId!));
    } else {
      print("empId is null or empty, cannot navigate to ChangePassword.");
    }
  }

  // Handle navigation to sync screens and logout user if required
  Future<void> _syncNavigation(Widget syncScreen) async {
    try {
      await SharedPreferencesHelper.logout();
      _navigateTo(syncScreen);
    } catch (e) {
      print("Error during sync navigation: $e");
      customSnackbar(
        'Error',
        'Failed to navigate to sync screen.',
        AppColors.error,
        AppColors.onError,
        Icons.error,
      );
    }
  }

  // Handle user logout and clear data
  Future<void> _handleLogout() async {
    await ApiService().clearTourDetailsOnLogout(); // Clear tour details before logout
    _issueController.clearStaffNameOnLogout();
    _userController.clearUserData();
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
}

// Drawer Menu item widget
class DrawerMenu extends StatelessWidget {
  final String title;
  final FaIcon icon;
  final VoidCallback onPressed;

  const DrawerMenu({
    super.key,
    required this.title,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: icon,
      title: Text(
        title,
        style: TextStyle(
          color: AppColors.onBackground,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      onTap: onPressed,
    );
  }
}
