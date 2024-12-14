import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:offline17000ft/components/custom_appBar.dart';
import 'package:offline17000ft/components/custom_button.dart';
import 'package:offline17000ft/components/custom_imagepreview.dart';
import 'package:offline17000ft/components/custom_snackbar.dart';
import 'package:offline17000ft/components/custom_textField.dart';
import 'package:offline17000ft/components/error_text.dart';
import 'package:offline17000ft/constants/color_const.dart';
import 'package:offline17000ft/forms/school_recce_form/school_recce_controller.dart';
import 'package:offline17000ft/forms/school_recce_form/school_recce_modal.dart';
import 'package:offline17000ft/helper/responsive_helper.dart';
import 'package:offline17000ft/tourDetails/tour_controller.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:offline17000ft/components/custom_dropdown.dart';
import 'package:offline17000ft/components/custom_labeltext.dart';
import 'package:offline17000ft/components/custom_sizedBox.dart';
import '../../components/custom_confirmation.dart';
import '../../helper/database_helper.dart';
import '../../home/home_screen.dart';
import '../select_tour_id/select_controller.dart';

class SchoolRecceForm extends StatefulWidget {
  String? userid;
  String? office;
  SchoolRecceForm({
    super.key,
    this.userid,
    this.office,
  });

  @override
  State<SchoolRecceForm> createState() => _SchoolRecceFormState();
}

class _SchoolRecceFormState extends State<SchoolRecceForm> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _previousAcademicYear = false;
  bool _twoYearsPreviously = false;
  bool _threeYearsPreviously = false;

  // Track submitted data for academic years
  Map<String, Map<String, int>> submittedData =
      {}; // key: year, value: totals map

  // Function to calculate total students
  int get totalStudents =>
      submittedData.values.fold(0, (sum, data) => sum + data['total']!);

  int get totalBoys =>
      submittedData.values.fold(0, (sum, data) => sum + data['boys']!);
  int get totalGirls =>
      submittedData.values.fold(0, (sum, data) => sum + data['girls']!);

  // Helper to delete an academic year's data
  void _deleteAcademicYear(String year) {
    setState(() {
      submittedData.remove(year);
      if (year == 'Previous academic year') {
        _previousAcademicYear = false;
      } else if (year == 'Two years previously') {
        _twoYearsPreviously = false;
      } else if (year == 'Three years previously') {
        _threeYearsPreviously = false;
      }
    });
  }

  // Function to show bottom sheet with checkboxes
  void _showBottomSheet() {
    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (BuildContext context) {
        return FractionallySizedBox(
          heightFactor: 0.8, // Adjust height to make it more adaptive
          child: Padding(
            padding: EdgeInsets.only(
              left: 16.0,
              right: 16.0,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      if (!submittedData
                          .containsKey('Previous academic year')) ...[
                        CheckboxListTile(
                          title: const Text('Previous academic Year'),
                          activeColor: Colors.green,
                          value: _previousAcademicYear,
                          onChanged: (bool? value) {
                            setState(() {
                              _previousAcademicYear = value ?? false;
                            });
                          },
                        ),
                        if (_previousAcademicYear)
                          if (isInitialized) ...[
                            Column(
                              children: [
                                Table(
                                  border: TableBorder.all(),
                                  children: [
                                    // Header Row
                                    const TableRow(
                                      children: [
                                        TableCell(
                                          verticalAlignment:
                                              TableCellVerticalAlignment.middle,
                                          child: Center(
                                            child: Text(
                                              'Grade',
                                              style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ),
                                        TableCell(
                                          verticalAlignment:
                                              TableCellVerticalAlignment.middle,
                                          child: Center(
                                            child: Text(
                                              'Boys',
                                              style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ),
                                        TableCell(
                                          verticalAlignment:
                                              TableCellVerticalAlignment.middle,
                                          child: Center(
                                            child: Text(
                                              'Girls',
                                              style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ),
                                        TableCell(
                                          verticalAlignment:
                                              TableCellVerticalAlignment.middle,
                                          child: Center(
                                            child: Text(
                                              'Total',
                                              style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                    // Grade Rows
                                    ...staffRoles.asMap().entries.map((entry) {
                                      final index = entry.key;
                                      final grade = entry.value;
                                      return tableRowMethod(
                                        grade,
                                        teachingStaffControllers[index],
                                        nonTeachingStaffControllers[index],
                                        staffTotalNotifiers[index],
                                      );
                                    }),

                                    // Grand Total Row
                                    TableRow(
                                      children: [
                                        const TableCell(
                                          verticalAlignment:
                                              TableCellVerticalAlignment.middle,
                                          child: Center(
                                            child: Text(
                                              'Grand Total',
                                              style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ),
                                        TableCell(
                                          verticalAlignment:
                                              TableCellVerticalAlignment.middle,
                                          child: ValueListenableBuilder<int>(
                                            valueListenable:
                                                grandTotalTeachingStaff,
                                            builder: (context, total, child) {
                                              return Center(
                                                child: Text(
                                                  total.toString(),
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                        TableCell(
                                          verticalAlignment:
                                              TableCellVerticalAlignment.middle,
                                          child: ValueListenableBuilder<int>(
                                            valueListenable:
                                                grandTotalNonTeachingStaff,
                                            builder: (context, total, child) {
                                              return Center(
                                                child: Text(
                                                  total.toString(),
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                        TableCell(
                                          verticalAlignment:
                                              TableCellVerticalAlignment.middle,
                                          child: ValueListenableBuilder<int>(
                                            valueListenable: grandTotalStaff,
                                            builder: (context, total, child) {
                                              return Center(
                                                child: Text(
                                                  total.toString(),
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            )
                          ],
                      ],
                      if (!submittedData
                          .containsKey('Two years previously')) ...[
                        CheckboxListTile(
                          title: const Text('Two years previously'),
                          activeColor: Colors.green,
                          value: _twoYearsPreviously,
                          onChanged: (bool? value) {
                            setState(() {
                              _twoYearsPreviously = value ?? false;
                            });
                          },
                        ),
                        if (_twoYearsPreviously)
                          if (isInitialized) ...[
                            Column(
                              children: [
                                Table(
                                  border: TableBorder.all(),
                                  children: [
                                    // Header Row
                                    const TableRow(
                                      children: [
                                        TableCell(
                                          verticalAlignment:
                                              TableCellVerticalAlignment.middle,
                                          child: Center(
                                            child: Text(
                                              'Grade',
                                              style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ),
                                        TableCell(
                                          verticalAlignment:
                                              TableCellVerticalAlignment.middle,
                                          child: Center(
                                            child: Text(
                                              'Boys',
                                              style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ),
                                        TableCell(
                                          verticalAlignment:
                                              TableCellVerticalAlignment.middle,
                                          child: Center(
                                            child: Text(
                                              'Girls',
                                              style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ),
                                        TableCell(
                                          verticalAlignment:
                                              TableCellVerticalAlignment.middle,
                                          child: Center(
                                            child: Text(
                                              'Total',
                                              style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                    // Grade Rows
                                    ...grades2.asMap().entries.map((entry) {
                                      final index = entry.key;
                                      final grade = entry.value;
                                      return tableRowMethod(
                                        grade,
                                        boysControllers2[index],
                                        girlsControllers2[index],
                                        totalNotifiers2[index],
                                      );
                                    }),

                                    // Grand Total Row
                                    TableRow(
                                      children: [
                                        const TableCell(
                                          verticalAlignment:
                                              TableCellVerticalAlignment.middle,
                                          child: Center(
                                            child: Text(
                                              'Grand Total',
                                              style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ),
                                        TableCell(
                                          verticalAlignment:
                                              TableCellVerticalAlignment.middle,
                                          child: ValueListenableBuilder<int>(
                                            valueListenable: grandTotalBoys2,
                                            builder: (context, total, child) {
                                              return Center(
                                                child: Text(
                                                  total.toString(),
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                        TableCell(
                                          verticalAlignment:
                                              TableCellVerticalAlignment.middle,
                                          child: ValueListenableBuilder<int>(
                                            valueListenable: grandTotalGirls2,
                                            builder: (context, total, child) {
                                              return Center(
                                                child: Text(
                                                  total.toString(),
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                        TableCell(
                                          verticalAlignment:
                                              TableCellVerticalAlignment.middle,
                                          child: ValueListenableBuilder<int>(
                                            valueListenable: grandTotal2,
                                            builder: (context, total, child) {
                                              return Center(
                                                child: Text(
                                                  total.toString(),
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            )
                          ],
                      ],
                      if (!submittedData
                          .containsKey('Three years previously')) ...[
                        CheckboxListTile(
                          title: const Text('Three years previously'),
                          activeColor: Colors.green,
                          value: _threeYearsPreviously,
                          onChanged: (bool? value) {
                            setState(() {
                              _threeYearsPreviously = value ?? false;
                            });
                          },
                        ),
                        if (_threeYearsPreviously)
                          if (isInitialized) ...[
                            Column(
                              children: [
                                Table(
                                  border: TableBorder.all(),
                                  children: [
                                    // Header Row
                                    const TableRow(
                                      children: [
                                        TableCell(
                                          verticalAlignment:
                                              TableCellVerticalAlignment.middle,
                                          child: Center(
                                            child: Text(
                                              'Grade',
                                              style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ),
                                        TableCell(
                                          verticalAlignment:
                                              TableCellVerticalAlignment.middle,
                                          child: Center(
                                            child: Text(
                                              'Boys',
                                              style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ),
                                        TableCell(
                                          verticalAlignment:
                                              TableCellVerticalAlignment.middle,
                                          child: Center(
                                            child: Text(
                                              'Girls',
                                              style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ),
                                        TableCell(
                                          verticalAlignment:
                                              TableCellVerticalAlignment.middle,
                                          child: Center(
                                            child: Text(
                                              'Total',
                                              style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                    // Grade Rows
                                    ...grades3.asMap().entries.map((entry) {
                                      final index = entry.key;
                                      final grade = entry.value;
                                      return tableRowMethod(
                                        grade,
                                        boysControllers3[index],
                                        girlsControllers3[index],
                                        totalNotifiers3[index],
                                      );
                                    }),

                                    // Grand Total Row
                                    TableRow(
                                      children: [
                                        const TableCell(
                                          verticalAlignment:
                                              TableCellVerticalAlignment.middle,
                                          child: Center(
                                            child: Text(
                                              'Grand Total',
                                              style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ),
                                        TableCell(
                                          verticalAlignment:
                                              TableCellVerticalAlignment.middle,
                                          child: ValueListenableBuilder<int>(
                                            valueListenable: grandTotalBoys3,
                                            builder: (context, total, child) {
                                              return Center(
                                                child: Text(
                                                  total.toString(),
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                        TableCell(
                                          verticalAlignment:
                                              TableCellVerticalAlignment.middle,
                                          child: ValueListenableBuilder<int>(
                                            valueListenable: grandTotalGirls3,
                                            builder: (context, total, child) {
                                              return Center(
                                                child: Text(
                                                  total.toString(),
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                        TableCell(
                                          verticalAlignment:
                                              TableCellVerticalAlignment.middle,
                                          child: ValueListenableBuilder<int>(
                                            valueListenable: grandTotal3,
                                            builder: (context, total, child) {
                                              return Center(
                                                child: Text(
                                                  total.toString(),
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            )
                          ],
                      ],
                      CustomButton(
                        title: 'Add',
                        onPressedButton: () {
                          _saveData();
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _saveData() {
    setState(() {
      if (_previousAcademicYear) {
        submittedData['Previous academic year'] = {
          'boys': grandTotalTeachingStaff.value,
          'girls': grandTotalNonTeachingStaff.value,
          'total': grandTotalStaff.value,
        };
        _previousAcademicYear = false;
      }
      if (_twoYearsPreviously) {
        submittedData['Two years previously'] = {
          'boys': grandTotalBoys2.value,
          'girls': grandTotalGirls2.value,
          'total': grandTotal2.value,
        };
        _twoYearsPreviously = false;
      }
      if (_threeYearsPreviously) {
        submittedData['Three years previously'] = {
          'boys': grandTotalBoys3.value,
          'girls': grandTotalGirls3.value,
          'total': grandTotal3.value,
        };
        _threeYearsPreviously = false;
      }
    });
  }

  var jsonData = <String, Map<String, String>>{};
  final List<TextEditingController> boysControllers = [];
  final List<TextEditingController> girlsControllers = [];
  bool validateEnrolmentRecords = false;
  final List<ValueNotifier<int>> totalNotifiers = [];
  bool isInitialized = false;

  bool validateEnrolmentData() {
    for (int i = 0; i < grades.length; i++) {
      if (boysControllers[i].text.isNotEmpty ||
          girlsControllers[i].text.isNotEmpty) {
        return true; // At least one record is present
      }
    }
    return false; // No records present
  }

  final List<String> gradeLabels = [
    'Nursery',
    'LKG',
    'UKG',
    ...List.generate(12, (index) => "Grade ${index + 1}")
  ];
  late final List<bool> isSelected;

  final List<String> grades = []; // Dynamically populated selected grades

  // ValueNotifiers for the grand totals
  final ValueNotifier<int> grandTotalBoys = ValueNotifier<int>(0);
  final ValueNotifier<int> grandTotalGirls = ValueNotifier<int>(0);
  final ValueNotifier<int> grandTotal = ValueNotifier<int>(0);

  // Function to collect data and convert to JSON
  void collectData() {
    final data = <String, Map<String, String>>{};
    for (int i = 0; i < grades.length; i++) {
      data[grades[i]] = {
        'boys': boysControllers[i].text,
        'girls': girlsControllers[i].text,
      };
    }
    jsonData = data;
  }

  @override
  void initState() {
    super.initState();
    isSelected = List.generate(gradeLabels.length, (index) => false);
  }

  void updateTotal(int index) {
    final boysCount = int.tryParse(boysControllers[index].text) ?? 0;
    final girlsCount = int.tryParse(girlsControllers[index].text) ?? 0;
    totalNotifiers[index].value = boysCount + girlsCount;

    updateGrandTotal();
  }

  void updateGrandTotal() {
    int boysSum = 0;
    int girlsSum = 0;

    for (int i = 0; i < grades.length; i++) {
      boysSum += int.tryParse(boysControllers[i].text) ?? 0;
      girlsSum += int.tryParse(girlsControllers[i].text) ?? 0;
    }

    grandTotalBoys.value = boysSum;
    grandTotalGirls.value = girlsSum;
    grandTotal.value = boysSum + girlsSum;
  }

  void initializeControllers() {
    boysControllers.clear();
    girlsControllers.clear();
    totalNotifiers.clear();

    for (int i = 0; i < grades.length; i++) {
      final boysController = TextEditingController(text: '0');
      final girlsController = TextEditingController(text: '0');
      final totalNotifier = ValueNotifier<int>(0);

      boysController.addListener(() {
        updateTotal(i);
        collectData();
      });
      girlsController.addListener(() {
        updateTotal(i);
        collectData();
      });

      boysControllers.add(boysController);
      girlsControllers.add(girlsController);
      totalNotifiers.add(totalNotifier);
    }

    // Initialize controllers and notifiers for Staff Details
    for (int i = 0; i < staffRoles.length; i++) {
      final teachingStaffController = TextEditingController(text: '0');
      final nonTeachingStaffController = TextEditingController(text: '0');
      final totalNotifier = ValueNotifier<int>(0);

      teachingStaffController.addListener(() {
        updateStaffTotal(i);
        collectStaffData();
      });
      nonTeachingStaffController.addListener(() {
        updateStaffTotal(i);
        collectStaffData();
      });

      teachingStaffControllers.add(teachingStaffController);
      nonTeachingStaffControllers.add(nonTeachingStaffController);
      staffTotalNotifiers.add(totalNotifier);
    }

    for (int i = 0; i < grades2.length; i++) {
      final boysController2 = TextEditingController(text: '0');
      final girlsController2 = TextEditingController(text: '0');
      final totalNotifier2 = ValueNotifier<int>(0);

      boysController2.addListener(() {
        updateTotal2(i);
        collectData2();
      });
      girlsController2.addListener(() {
        updateTotal2(i);
        collectData2();
      });

      boysControllers2.add(boysController2);
      girlsControllers2.add(girlsController2);
      totalNotifiers2.add(totalNotifier2);
    }

    for (int i = 0; i < grades3.length; i++) {
      final boysController3 = TextEditingController(text: '0');
      final girlsController3 = TextEditingController(text: '0');
      final totalNotifier3 = ValueNotifier<int>(0);

      boysController3.addListener(() {
        updateTotal3(i);
        collectData3();
      });
      girlsController3.addListener(() {
        updateTotal3(i);
        collectData3();
      });

      boysControllers3.add(boysController3);
      girlsControllers3.add(girlsController3);
      totalNotifiers3.add(totalNotifier3);
    }

    setState(() {
      isInitialized = true;
    });
  }

  @override
  void dispose() {
    super.dispose();
    _scrollController.dispose();

    // Dispose controllers and notifiers
    for (var controller in boysControllers) {
      controller.dispose();
    }
    for (var controller in girlsControllers) {
      controller.dispose();
    }
    for (var notifier in totalNotifiers) {
      notifier.dispose();
    }
    grandTotalBoys.dispose();
    grandTotalGirls.dispose();
    grandTotal.dispose();

    // Dispose controllers and notifiers
    for (var controller in boysControllers2) {
      controller.dispose();
    }
    for (var controller in girlsControllers2) {
      controller.dispose();
    }
    for (var notifier in totalNotifiers2) {
      notifier.dispose();
    }
    grandTotalBoys2.dispose();
    grandTotalGirls2.dispose();
    grandTotal2.dispose();

    for (var controller in teachingStaffControllers) {
      controller.dispose();
    }
    for (var controller in nonTeachingStaffControllers) {
      controller.dispose();
    }
    for (var notifier in staffTotalNotifiers) {
      notifier.dispose();
    }
    grandTotalTeachingStaff.dispose();
    grandTotalNonTeachingStaff.dispose();
    grandTotalStaff.dispose();

    for (var controller in boysControllers3) {
      controller.dispose();
    }
    for (var controller in girlsControllers3) {
      controller.dispose();
    }
    for (var notifier in totalNotifiers3) {
      notifier.dispose();
    }
    grandTotalBoys3.dispose();
    grandTotalGirls3.dispose();
    grandTotal3.dispose();
  }

  TableRow tableRowMethod(String classname, TextEditingController boyController,
      TextEditingController girlController, ValueNotifier<int> totalNotifier) {
    return TableRow(
      children: [
        // Classname
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.middle,
          child: LayoutBuilder(
            builder: (context, constraints) {
              double fontSize = constraints.maxWidth < 600 ? 14 : 18;
              return Center(
                child: Text(
                  classname,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),
        ),

        // Boy Count Input
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.middle,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: StatefulBuilder(
              builder: (context, setState) {
                return TextFormField(
                  controller: boyController,
                  decoration: const InputDecoration(border: InputBorder.none),
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly, // Allow only digits
                    LengthLimitingTextInputFormatter(3), // Limit to 3 digits
                  ],
                  onChanged: (value) {
                    // Update total and notify listeners
                    setState(() {
                      int boysCount = int.tryParse(boyController.text) ?? 0;
                      int girlsCount = int.tryParse(girlController.text) ?? 0;
                      totalNotifier.value = boysCount + girlsCount;
                    });
                  },
                );
              },
            ),
          ),
        ),

        // Girl Count Input
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.middle,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: StatefulBuilder(
              builder: (context, setState) {
                return TextFormField(
                  controller: girlController,
                  decoration: const InputDecoration(border: InputBorder.none),
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly, // Allow only digits
                    LengthLimitingTextInputFormatter(3), // Limit to 3 digits
                  ],
                  onChanged: (value) {
                    // Update total and notify listeners
                    setState(() {
                      int boysCount = int.tryParse(boyController.text) ?? 0;
                      int girlsCount = int.tryParse(girlController.text) ?? 0;
                      totalNotifier.value = boysCount + girlsCount;
                    });
                  },
                );
              },
            ),
          ),
        ),

        // Total
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.middle,
          child: ValueListenableBuilder<int>(
            valueListenable: totalNotifier,
            builder: (context, total, child) {
              double fontSize =
                  MediaQuery.of(context).size.width < 600 ? 14 : 18;
              return Center(
                child: Text(
                  total.toString(),
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Map<String, Map<String, int>> staffData = {};
  var staffJsonData = <String, Map<String, String>>{};
  final List<TextEditingController> teachingStaffControllers = [];
  final List<TextEditingController> nonTeachingStaffControllers = [];
  bool validateStaffData = false;

  final List<ValueNotifier<int>> staffTotalNotifiers = [];

  final ValueNotifier<int> grandTotalTeachingStaff = ValueNotifier<int>(0);
  final ValueNotifier<int> grandTotalNonTeachingStaff = ValueNotifier<int>(0);
  final ValueNotifier<int> grandTotalStaff = ValueNotifier<int>(0);

  final List<String> staffRoles = [];

  // Collecting Staff Data
  void collectStaffData() {
    final data = <String, Map<String, String>>{};
    for (int i = 0; i < staffRoles.length; i++) {
      data[staffRoles[i]] = {
        'boys': teachingStaffControllers[i].text,
        'girls': nonTeachingStaffControllers[i].text,
      };
    }
    staffJsonData = data;
  }

  void updateStaffTotal(int index) {
    final teachingCount =
        int.tryParse(teachingStaffControllers[index].text) ?? 0;
    final nonTeachingCount =
        int.tryParse(nonTeachingStaffControllers[index].text) ?? 0;
    staffTotalNotifiers[index].value = teachingCount + nonTeachingCount;

    updateGrandStaffTotal();
  }

  void updateGrandStaffTotal() {
    int teachingSum = 0;
    int nonTeachingSum = 0;

    for (int i = 0; i < staffRoles.length; i++) {
      teachingSum += int.tryParse(teachingStaffControllers[i].text) ?? 0;
      nonTeachingSum += int.tryParse(nonTeachingStaffControllers[i].text) ?? 0;
    }

    grandTotalTeachingStaff.value = teachingSum;
    grandTotalNonTeachingStaff.value = nonTeachingSum;
    grandTotalStaff.value = teachingSum + nonTeachingSum;
  }

  Map<String, Map<String, int>> classData2 = {};
  var readingJson2 = <String, Map<String, String>>{};
  final List<TextEditingController> boysControllers2 = [];
  final List<TextEditingController> girlsControllers2 = [];
  bool validateReading = false;
  final List<ValueNotifier<int>> totalNotifiers2 = [];

  bool validateReadingData() {
    for (int i = 0; i < grades2.length; i++) {
      if (boysControllers2[i].text.isNotEmpty ||
          girlsControllers2[i].text.isNotEmpty) {
        return true; // At least one record is present
      }
    }
    return false; // No records present
  }

  final List<String> grades2 = [];

  // ValueNotifiers for the grand totals
  final ValueNotifier<int> grandTotalBoys2 = ValueNotifier<int>(0);
  final ValueNotifier<int> grandTotalGirls2 = ValueNotifier<int>(0);
  final ValueNotifier<int> grandTotal2 = ValueNotifier<int>(0);

  // Function to collect data and convert to JSON
  void collectData2() {
    final data2 = <String, Map<String, String>>{};
    for (int i = 0; i < grades2.length; i++) {
      data2[grades2[i]] = {
        'boys': boysControllers2[i].text,
        'girls': girlsControllers2[i].text,
      };
    }
    readingJson2 = data2;
  }

  void updateTotal2(int index) {
    final boysCount2 = int.tryParse(boysControllers2[index].text) ?? 0;
    final girlsCount2 = int.tryParse(girlsControllers2[index].text) ?? 0;
    totalNotifiers2[index].value = boysCount2 + girlsCount2;

    updateGrandTotal2();
  }

  void updateGrandTotal2() {
    int boysSum2 = 0;
    int girlsSum2 = 0;

    for (int i = 0; i < grades2.length; i++) {
      boysSum2 += int.tryParse(boysControllers2[i].text) ?? 0;
      girlsSum2 += int.tryParse(girlsControllers2[i].text) ?? 0;
    }

    grandTotalBoys2.value = boysSum2;
    grandTotalGirls2.value = girlsSum2;
    grandTotal2.value = boysSum2 + girlsSum2;
  }

  Map<String, Map<String, int>> classData3 = {};
  var readingJson3 = <String, Map<String, String>>{};

  final List<TextEditingController> boysControllers3 = [];
  final List<TextEditingController> girlsControllers3 = [];
  bool validateReading3 = false;
  final List<ValueNotifier<int>> totalNotifiers3 = [];

  bool validateReadingData3() {
    for (int i = 0; i < grades3.length; i++) {
      if (boysControllers3[i].text.isNotEmpty ||
          girlsControllers3[i].text.isNotEmpty) {
        return true; // At least one record is present
      }
    }
    return false; // No records present
  }

  final List<String> grades3 = [];

  // ValueNotifiers for the grand totals
  final ValueNotifier<int> grandTotalBoys3 = ValueNotifier<int>(0);
  final ValueNotifier<int> grandTotalGirls3 = ValueNotifier<int>(0);
  final ValueNotifier<int> grandTotal3 = ValueNotifier<int>(0);

  // Function to collect data and convert to JSON
  void collectData3() {
    final data3 = <String, Map<String, String>>{};
    for (int i = 0; i < grades3.length; i++) {
      data3[grades3[i]] = {
        'boys': boysControllers3[i].text,
        'girls': girlsControllers3[i].text,
      };
    }
    readingJson3 = data3;
  }

  void updateTotal3(int index) {
    final boysCount3 = int.tryParse(boysControllers3[index].text) ?? 0;
    final girlsCount3 = int.tryParse(girlsControllers3[index].text) ?? 0;
    totalNotifiers3[index].value = boysCount3 + girlsCount3;

    updateGrandTotal3();
  }

  void updateGrandTotal3() {
    int boysSum3 = 0;
    int girlsSum3 = 0;

    for (int i = 0; i < grades3.length; i++) {
      boysSum3 += int.tryParse(boysControllers3[i].text) ?? 0;
      girlsSum3 += int.tryParse(girlsControllers3[i].text) ?? 0;
    }

    grandTotalBoys3.value = boysSum3;
    grandTotalGirls3.value = girlsSum3;
    grandTotal3.value = boysSum3 + girlsSum3;
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    final responsive = Responsive(context);
    return WillPopScope(
        onWillPop: () async {
          IconData icon = Icons.check_circle;
          bool? shouldExit = await showDialog<bool>(
            context: context,
            builder: (_) => Confirmation(
              iconname: icon,
              title: 'Exit Confirmation',
              yes: 'Yes',
              no: 'No',
              desc: 'Are you sure you want to leave?',
              onPressed: () {
                Navigator.of(context).pop(true); // User confirms exit
              },
            ),
          );

          // If shouldExit is null, default to false
          return shouldExit ?? false;
        },
        child: Scaffold(
            appBar: const CustomAppbar(
              title: 'School Recce Form',
            ),
            body: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                    controller: _scrollController,
                    child: Column(children: [
                      GetBuilder<SchoolRecceController>(
                          init: SchoolRecceController(),
                          builder: (schoolRecceController) {
                            return Form(
                                key: _formKey,
                                child: GetBuilder<TourController>(
                                    init: TourController(),
                                    builder: (tourController) {
                                      // Fetch tour details
                                      tourController.fetchTourDetails();

                                      // Get locked tour ID from SelectController
                                      final selectController =
                                          Get.put(SelectController());
                                      String? lockedTourId =
                                          selectController.lockedTourId;

                                      // Consider the lockedTourId as the selected tour ID if it's not null
                                      String? selectedTourId = lockedTourId ??
                                          schoolRecceController.tourValue;

                                      // Fetch the corresponding schools if lockedTourId or selectedTourId is present
                                      if (selectedTourId != null) {
                                        schoolRecceController.splitSchoolLists =
                                            tourController.getLocalTourList
                                                .where((e) =>
                                                    e.tourId == selectedTourId)
                                                .map((e) => e.allSchool!
                                                    .split(',')
                                                    .map((s) => s.trim())
                                                    .toList())
                                                .expand((x) => x)
                                                .toList();
                                      }

                                      return Column(children: [
                                        if (schoolRecceController
                                            .showBasicDetails) ...[
                                          LabelText(
                                            label: 'Basic Details',
                                          ),
                                          CustomSizedBox(
                                            value: 20,
                                            side: 'height',
                                          ),
                                          LabelText(
                                            label: 'Tour ID',
                                            astrick: true,
                                          ),
                                          CustomSizedBox(
                                            value: 20,
                                            side: 'height',
                                          ),
                                          CustomDropdownFormField(
                                            focusNode: schoolRecceController
                                                .tourIdFocusNode,
                                            // Show the locked tour ID directly, and disable dropdown interaction if locked
                                            options: lockedTourId != null
                                                ? [
                                                    lockedTourId
                                                  ] // Show only the locked tour ID
                                                : tourController
                                                    .getLocalTourList
                                                    .map((e) => e
                                                        .tourId!) // Ensure tourId is non-nullable
                                                    .toList(),
                                            selectedOption: selectedTourId,
                                            onChanged: lockedTourId ==
                                                    null // Disable changing when tour ID is locked
                                                ? (value) {
                                                    // Fetch and set the schools for the selected tour
                                                    schoolRecceController
                                                            .splitSchoolLists =
                                                        tourController
                                                            .getLocalTourList
                                                            .where((e) =>
                                                                e.tourId ==
                                                                value)
                                                            .map((e) => e
                                                                .allSchool!
                                                                .split(',')
                                                                .map((s) =>
                                                                    s.trim())
                                                                .toList())
                                                            .expand((x) => x)
                                                            .toList();

                                                    // Single setState call for efficiency
                                                    setState(() {
                                                      schoolRecceController
                                                          .setSchool(null);
                                                      schoolRecceController
                                                          .setTour(value);
                                                    });
                                                  }
                                                : null, // Disable dropdown if lockedTourId is present
                                            labelText: "Select Tour ID",
                                          ),
                                          CustomSizedBox(
                                            value: 20,
                                            side: 'height',
                                          ),
                                          LabelText(
                                            label: 'School',
                                            astrick: true,
                                          ),
                                          CustomSizedBox(
                                            value: 20,
                                            side: 'height',
                                          ),
                                          DropdownSearch<String>(
                                            validator: (value) {
                                              if (value == null ||
                                                  value.isEmpty) {
                                                return "Please Select School";
                                              }
                                              return null;
                                            },
                                            popupProps: PopupProps.menu(
                                              showSelectedItems: true,
                                              showSearchBox: true,
                                              disabledItemFn: (String s) =>
                                                  s.startsWith(
                                                      'I'), // Disable based on condition
                                            ),
                                            items: schoolRecceController
                                                .splitSchoolLists, // Show schools based on selected or locked tour ID
                                            dropdownDecoratorProps:
                                                const DropDownDecoratorProps(
                                              dropdownSearchDecoration:
                                                  InputDecoration(
                                                labelText: "Select School",
                                                hintText: "Select School",
                                              ),
                                            ),
                                            onChanged: (value) {
                                              // Set the selected school
                                              setState(() {
                                                schoolRecceController
                                                    .setSchool(value);
                                              });
                                            },
                                            selectedItem: schoolRecceController
                                                .schoolValue,
                                          ),
                                          CustomSizedBox(
                                            value: 20,
                                            side: 'height',
                                          ),
                                          LabelText(
                                            label:
                                                'Is this UDISE code is correct?',
                                            astrick: true,
                                          ),
                                          Padding(
                                            padding: EdgeInsets.only(
                                                right: screenWidth * 0.1),
                                            child: Row(
                                              children: [
                                                Radio(
                                                  value: 'Yes',
                                                  groupValue:
                                                      schoolRecceController
                                                          .getSelectedValue(
                                                              'udiCode'),
                                                  onChanged: (value) {
                                                    schoolRecceController
                                                        .setRadioValue(
                                                            'udiCode', value);
                                                    if (value == 'Yes') {
                                                      schoolRecceController
                                                          .correctUdiseCodeController
                                                          .clear();
                                                    }
                                                  },
                                                ),
                                                const Text('Yes'),
                                              ],
                                            ),
                                          ),
                                          CustomSizedBox(
                                            value: 150,
                                            side: 'width',
                                          ),
                                          // make it that user can also edit the tourId and school
                                          Padding(
                                            padding: EdgeInsets.only(
                                                right: screenWidth * 0.1),
                                            child: Row(
                                              children: [
                                                Radio(
                                                  value: 'No',
                                                  groupValue:
                                                      schoolRecceController
                                                          .getSelectedValue(
                                                              'udiCode'),
                                                  onChanged: (value) {
                                                    schoolRecceController
                                                        .setRadioValue(
                                                            'udiCode', value);
                                                  },
                                                ),
                                                const Text('No'),
                                              ],
                                            ),
                                          ),
                                          if (schoolRecceController
                                              .getRadioFieldError('udiCode'))
                                            const Padding(
                                              padding:
                                                  EdgeInsets.only(left: 16.0),
                                              child: Align(
                                                alignment: Alignment.centerLeft,
                                                child: Text(
                                                  'Please select an option',
                                                  style: TextStyle(
                                                      color: Colors.red),
                                                ),
                                              ),
                                            ),
                                          CustomSizedBox(
                                            value: 20,
                                            side: 'height',
                                          ),
                                          if (schoolRecceController
                                                  .getSelectedValue(
                                                      'udiCode') ==
                                              'No') ...[
                                            LabelText(
                                              label:
                                                  'Write Correct UDISE school code',
                                              astrick: true,
                                            ),
                                            CustomSizedBox(
                                              value: 20,
                                              side: 'height',
                                            ),
                                            CustomTextFormField(
                                              textController:
                                                  schoolRecceController
                                                      .correctUdiseCodeController,
                                              textInputType:
                                                  TextInputType.number,
                                              inputFormatters: [
                                                LengthLimitingTextInputFormatter(
                                                    11),
                                                FilteringTextInputFormatter
                                                    .digitsOnly,
                                              ],
                                              labelText:
                                                  'Enter correct UDISE code',
                                              validator: (value) {
                                                if (value == null ||
                                                    value.isEmpty) {
                                                  return 'Please fill this field';
                                                }
                                                if (!RegExp(r'^[0-9]+$')
                                                    .hasMatch(value)) {
                                                  return 'Please enter a valid number';
                                                }
                                                return null;
                                              },
                                              showCharacterCount: true,
                                            ),
                                            CustomSizedBox(
                                              value: 20,
                                              side: 'height',
                                            ),
                                          ],
                                          LabelText(
                                            label: 'Photo of School Board',
                                            astrick: true,
                                          ),
                                          CustomSizedBox(
                                            value: 20,
                                            side: 'height',
                                          ),

                                          Container(
                                            height: 60,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(10.0),
                                              border: Border.all(
                                                  width: 2,
                                                  color: schoolRecceController
                                                              .isImageUploadedSchoolBoard ==
                                                          false
                                                      ? AppColors.primary
                                                      : AppColors.error),
                                            ),
                                            child: ListTile(
                                                title: schoolRecceController
                                                            .isImageUploadedSchoolBoard ==
                                                        false
                                                    ? const Text(
                                                        'Click or Upload Image',
                                                      )
                                                    : const Text(
                                                        'Click or Upload Image',
                                                        style: TextStyle(
                                                            color: AppColors
                                                                .error),
                                                      ),
                                                trailing: const Icon(Icons.camera_alt,
                                                    color:
                                                        AppColors.onBackground),
                                                onTap: () {
                                                  showModalBottomSheet(
                                                      backgroundColor:
                                                          AppColors.primary,
                                                      context: context,
                                                      builder: ((builder) =>
                                                          schoolRecceController
                                                              .bottomSheet2(
                                                                  context, 1)));
                                                }),
                                          ),
                                          ErrorText(
                                            isVisible: schoolRecceController
                                                .validateSchoolBoard,
                                            message: 'Board Image Required',
                                          ),
                                          CustomSizedBox(
                                            value: 20,
                                            side: 'height',
                                          ),

                                          schoolRecceController
                                                  .multipleImage.isNotEmpty
                                              ? Container(
                                                  width: responsive
                                                      .responsiveValue(
                                                          small: 600.0,
                                                          medium: 900.0,
                                                          large: 1400.0),
                                                  height: responsive
                                                      .responsiveValue(
                                                          small: 170.0,
                                                          medium: 170.0,
                                                          large: 170.0),
                                                  decoration: BoxDecoration(
                                                    border: Border.all(
                                                        color: Colors.grey),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                  ),
                                                  child:
                                                      schoolRecceController
                                                              .multipleImage
                                                              .isEmpty
                                                          ? const Center(
                                                              child: Text(
                                                                  'No images selected.'),
                                                            )
                                                          : ListView.builder(
                                                              scrollDirection:
                                                                  Axis.horizontal,
                                                              itemCount:
                                                                  schoolRecceController
                                                                      .multipleImage
                                                                      .length,
                                                              itemBuilder:
                                                                  (context,
                                                                      index) {
                                                                return SizedBox(
                                                                  height: 200,
                                                                  width: 200,
                                                                  child: Column(
                                                                    children: [
                                                                      Padding(
                                                                        padding:
                                                                            const EdgeInsets.all(8.0),
                                                                        child:
                                                                            GestureDetector(
                                                                          onTap:
                                                                              () {
                                                                            CustomImagePreview.showImagePreview(schoolRecceController.multipleImage[index].path,
                                                                                context);
                                                                          },
                                                                          child:
                                                                              Image.file(
                                                                            File(schoolRecceController.multipleImage[index].path),
                                                                            width:
                                                                                190,
                                                                            height:
                                                                                120,
                                                                            fit:
                                                                                BoxFit.fill,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                      GestureDetector(
                                                                        onTap:
                                                                            () {
                                                                          setState(
                                                                              () {
                                                                            schoolRecceController.multipleImage.removeAt(index);
                                                                          });
                                                                        },
                                                                        child:
                                                                            const Icon(
                                                                          Icons
                                                                              .delete,
                                                                          color:
                                                                              Colors.red,
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                );
                                                              },
                                                            ),
                                                )
                                              : const SizedBox(),
                                          CustomSizedBox(
                                            value: 20,
                                            side: 'height',
                                          ),
                                          LabelText(
                                            label:
                                                'Photo of School Building (Wide Angle)',
                                            astrick: true,
                                          ),
                                          CustomSizedBox(
                                            value: 20,
                                            side: 'height',
                                          ),
                                          Container(
                                            height: 60,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(10.0),
                                              border: Border.all(
                                                width: 2,
                                                color: schoolRecceController
                                                            .isImageUploadedSchoolBuilding ==
                                                        false
                                                    ? AppColors.primary
                                                    : AppColors.error,
                                              ),
                                            ),
                                            child: ListTile(
                                              title: Text(
                                                'Click or Upload Image',
                                                style: TextStyle(
                                                  color: schoolRecceController
                                                              .isImageUploadedSchoolBuilding ==
                                                          false
                                                      ? Colors.black
                                                      : AppColors.error,
                                                ),
                                              ),
                                              trailing: const Icon(Icons.camera_alt,
                                                  color:
                                                      AppColors.onBackground),
                                              onTap: () {
                                                showModalBottomSheet(
                                                  backgroundColor:
                                                      AppColors.primary,
                                                  context: context,
                                                  builder: (builder) =>
                                                      schoolRecceController
                                                          .bottomSheet(
                                                              context, 2),
                                                );
                                              },
                                            ),
                                          ),
                                          ErrorText(
                                            isVisible: schoolRecceController
                                                .validateSchoolBuilding,
                                            message: 'Image Required',
                                          ),
                                          CustomSizedBox(
                                            value: 20,
                                            side: 'height',
                                          ),
                                          schoolRecceController
                                                  .multipleImage2.isNotEmpty
                                              ? Container(
                                                  width: responsive
                                                      .responsiveValue(
                                                    small: 600.0,
                                                    medium: 900.0,
                                                    large: 1400.0,
                                                  ),
                                                  height: responsive
                                                      .responsiveValue(
                                                    small: 170.0,
                                                    medium: 170.0,
                                                    large: 170.0,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    border: Border.all(
                                                        color: Colors.grey),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                  ),
                                                  child: ListView.builder(
                                                    scrollDirection:
                                                        Axis.horizontal,
                                                    itemCount:
                                                        schoolRecceController
                                                            .multipleImage2
                                                            .length,
                                                    itemBuilder:
                                                        (context, index) {
                                                      return SizedBox(
                                                        height: 200,
                                                        width: 200,
                                                        child: Column(
                                                          children: [
                                                            Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .all(8.0),
                                                              child:
                                                                  GestureDetector(
                                                                onTap: () {
                                                                  CustomImagePreview
                                                                      .showImagePreview(
                                                                    schoolRecceController
                                                                        .multipleImage2[
                                                                            index]
                                                                        .path,
                                                                    context,
                                                                  );
                                                                },
                                                                child:
                                                                    Image.file(
                                                                  File(schoolRecceController
                                                                      .multipleImage2[
                                                                          index]
                                                                      .path),
                                                                  width: 190,
                                                                  height: 120,
                                                                  fit: BoxFit
                                                                      .fill,
                                                                ),
                                                              ),
                                                            ),
                                                            GestureDetector(
                                                              onTap: () {
                                                                setState(() {
                                                                  schoolRecceController
                                                                      .multipleImage2
                                                                      .removeAt(
                                                                          index);
                                                                });
                                                              },
                                                              child: const Icon(
                                                                Icons.delete,
                                                                color:
                                                                    Colors.red,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                )
                                              : const SizedBox(),
                                          CustomSizedBox(
                                            value: 20,
                                            side: 'height',
                                          ),
                                          LabelText(
                                            label:
                                                'Select Grades being taught in School',
                                            astrick: true,
                                          ),
                                          CustomSizedBox(
                                            value: 20,
                                            side: 'height',
                                          ),
                                          Column(
                                            children: List.generate(
                                                gradeLabels.length, (index) {
                                              String gradeName =
                                                  gradeLabels[index];
                                              return CheckboxListTile(
                                                title: Text(gradeName),
                                                value: isSelected[index],
                                                onChanged: (bool? value) {
                                                  setState(() {
                                                    isSelected[index] =
                                                        value ?? false;

                                                    // Handle the 'grades' list
                                                    if (isSelected[index] &&
                                                        !grades.contains(
                                                            gradeName)) {
                                                      grades.add(gradeName);
                                                    } else if (!isSelected[
                                                            index] &&
                                                        grades.contains(
                                                            gradeName)) {
                                                      grades.remove(gradeName);
                                                    }

                                                    // Handle the 'grades2' list
                                                    if (isSelected[index] &&
                                                        !grades2.contains(
                                                            gradeName)) {
                                                      grades2.add(gradeName);
                                                    } else if (!isSelected[
                                                            index] &&
                                                        grades2.contains(
                                                            gradeName)) {
                                                      grades2.remove(gradeName);
                                                    }

                                                    // Handle the 'grades2' list
                                                    if (isSelected[index] &&
                                                        !grades3.contains(
                                                            gradeName)) {
                                                      grades3.add(gradeName);
                                                    } else if (!isSelected[
                                                            index] &&
                                                        grades3.contains(
                                                            gradeName)) {
                                                      grades3.remove(gradeName);
                                                    }

                                                    // Handle the 'grades2' list
                                                    if (isSelected[index] &&
                                                        !staffRoles.contains(
                                                            gradeName)) {
                                                      staffRoles.add(gradeName);
                                                    } else if (!isSelected[
                                                            index] &&
                                                        staffRoles.contains(
                                                            gradeName)) {
                                                      staffRoles
                                                          .remove(gradeName);
                                                    }

                                                    // Initialize controllers (if needed)
                                                    initializeControllers();
                                                  });
                                                },
                                                activeColor: Colors.green,
                                              );
                                            }),
                                          ),

                                          CustomSizedBox(
                                            value: 20,
                                            side: 'height',
                                          ),
                                          CustomButton(
                                            title: 'Next',
                                            onPressedButton: () {
                                              // Perform radio button validations
                                              final isRadioValid1 =
                                                  schoolRecceController
                                                      .validateRadioSelection(
                                                          'udiCode');

                                              // Check if grades are selected
                                              if (grades.isEmpty) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                        customSnackbar(
                                                  'Error',
                                                  'Please select at least one grade.',
                                                  AppColors.error,
                                                  Colors.white,
                                                  Icons.error,
                                                ));
                                                return; // Stop further execution if grades are empty
                                              }

                                              // Check if at least one checkbox is selected
                                              setState(() {
                                                schoolRecceController
                                                        .validateSchoolBoard =
                                                    schoolRecceController
                                                        .multipleImage.isEmpty;
                                                schoolRecceController
                                                        .validateSchoolBuilding =
                                                    schoolRecceController
                                                        .multipleImage2.isEmpty;
                                              });

                                              // If form validation and other conditions pass
                                              if (_formKey.currentState!
                                                      .validate() &&
                                                  isRadioValid1 &&
                                                  !schoolRecceController
                                                      .validateSchoolBoard &&
                                                  !schoolRecceController
                                                      .validateSchoolBuilding) {
                                                setState(() {
                                                  schoolRecceController
                                                      .showBasicDetails = false;
                                                  schoolRecceController
                                                      .showStaffDetails = true;
                                                  WidgetsBinding.instance
                                                      .addPostFrameCallback(
                                                          (_) {
                                                    _scrollController.animateTo(
                                                      0.0, // Scroll to the top
                                                      duration: const Duration(
                                                          milliseconds: 300),
                                                      curve: Curves.easeInOut,
                                                    );
                                                  });
                                                });
                                              }
                                            },
                                          ),

                                          CustomSizedBox(
                                            value: 20,
                                            side: 'height',
                                          ),
                                        ], // End of basic Details
                                        // Start of showStaffDetails

                                        if (schoolRecceController
                                            .showStaffDetails) ...[
                                          LabelText(
                                            label: 'Staff Details',
                                          ),
                                          CustomSizedBox(
                                            value: 20,
                                            side: 'height',
                                          ),
                                          LabelText(
                                            label: 'Name of Head of Institute',
                                            astrick: true,
                                          ),
                                          CustomSizedBox(
                                            value: 20,
                                            side: 'height',
                                          ),
                                          CustomTextFormField(
                                            textController:
                                                schoolRecceController
                                                    .nameOfHoiController,
                                            labelText: 'Enter Name',
                                            validator: (value) {
                                              if (value!.isEmpty) {
                                                return 'Please fill this field';
                                              }
                                              return null;
                                            },
                                            showCharacterCount: true,
                                          ),
                                          CustomSizedBox(
                                            value: 20,
                                            side: 'height',
                                          ),
                                          LabelText(
                                            label: 'Designation',
                                            astrick: true,
                                          ),
                                          CustomSizedBox(
                                            value: 20,
                                            side: 'height',
                                          ),
                                          DropdownButtonFormField<String>(
                                            decoration: const InputDecoration(
                                              labelText: 'Select an option',
                                              border: OutlineInputBorder(),
                                            ),
                                            value: schoolRecceController
                                                .selectedDesignation,
                                            items: const [
                                              DropdownMenuItem(
                                                  value:
                                                      'HeadMaster/HeadMistress',
                                                  child: Text(
                                                      'HeadMaster/HeadMistress')),
                                              DropdownMenuItem(
                                                  value: 'Principal',
                                                  child: Text('Principal')),
                                              DropdownMenuItem(
                                                  value: 'InCharge',
                                                  child: Text('InCharge')),
                                            ],
                                            onChanged: (value) {
                                              setState(() {
                                                schoolRecceController
                                                        .selectedDesignation =
                                                    value;
                                              });
                                            },
                                            validator: (value) {
                                              if (value == null) {
                                                return 'Please select a designation';
                                              }
                                              return null;
                                            },
                                          ),
                                          CustomSizedBox(
                                              value: 20, side: 'height'),
                                          LabelText(
                                            label: 'Mobile Number',
                                            astrick: true,
                                          ),
                                          CustomSizedBox(
                                            value: 20,
                                            side: 'height',
                                          ),
                                          CustomTextFormField(
                                            textController:
                                                schoolRecceController
                                                    .hoiPhoneNumberController,
                                            labelText: 'Mobile number',
                                            textInputType: TextInputType.number,
                                            validator: (value) {
                                              if (value!.isEmpty) {
                                                return 'Write Admin Name';
                                              }

                                              // Regex for validating Indian phone number
                                              String pattern = r'^[6-9]\d{9}$';
                                              RegExp regex = RegExp(pattern);

                                              if (!regex.hasMatch(value)) {
                                                return 'Enter a valid phone number';
                                              }

                                              return null;
                                            },
                                            showCharacterCount: true,
                                          ),
                                          CustomSizedBox(
                                            value: 20,
                                            side: 'height',
                                          ),
                                          LabelText(
                                            label: 'Email Id',
                                            astrick: true,
                                          ),
                                          CustomSizedBox(
                                            value: 20,
                                            side: 'height',
                                          ),
                                          CustomTextFormField(
                                            textController:
                                                schoolRecceController
                                                    .hoiEmailController,
                                            labelText: 'Enter Email',
                                            textInputType:
                                                TextInputType.emailAddress,
                                            validator: (value) {
                                              if (value == null ||
                                                  value.isEmpty) {
                                                return 'Please Enter Email';
                                              }

                                              // Regular expression for validating email
                                              final emailRegex = RegExp(
                                                r'^[^@]+@[^@]+\.[^@]+$',
                                                caseSensitive: false,
                                              );

                                              if (!emailRegex.hasMatch(value)) {
                                                return 'Please Enter a Valid Email Address';
                                              }
                                              return null;
                                            },
                                            showCharacterCount: true,
                                          ),
                                          CustomSizedBox(
                                            value: 20,
                                            side: 'height',
                                          ),
                                          LabelText(
                                            label:
                                                'Year appointed as Head of the Institution',
                                            astrick: true,
                                          ),
                                          CustomSizedBox(
                                            value: 20,
                                            side: 'height',
                                          ),
                                          DropdownButtonFormField<String>(
                                            value: schoolRecceController
                                                .selectedYear,
                                            decoration: const InputDecoration(
                                              labelText: 'Select an option',
                                              border: OutlineInputBorder(),
                                            ),
                                            items: List.generate(
                                              DateTime.now().year -
                                                  1990 +
                                                  1, // Dynamically calculate the range
                                              (index) {
                                                int year = 1990 + index;
                                                return DropdownMenuItem(
                                                  value: year.toString(),
                                                  child: Text(year.toString()),
                                                );
                                              },
                                            ).toList(),
                                            onChanged: (newValue) {
                                              setState(() {
                                                schoolRecceController
                                                    .selectedYear = newValue;
                                              });
                                            },
                                            isExpanded: true,
                                            validator: (value) {
                                              if (value == null ||
                                                  value.isEmpty) {
                                                return 'Please select a year';
                                              }
                                              return null;
                                            },
                                          ),
                                          CustomSizedBox(
                                            value: 20,
                                            side: 'height',
                                          ),
                                          LabelText(
                                            label:
                                                'No of Teaching Staff (including Head of Institution)',
                                            astrick: true,
                                          ),
                                          CustomSizedBox(
                                            value: 20,
                                            side: 'height',
                                          ),
                                          CustomTextFormField(
                                            textController: schoolRecceController
                                                .totalTeachingStaffController,
                                            labelText: 'Enter Teaching Staff',
                                            textInputType: TextInputType.number,

                                            validator: (value) {
                                              if (value!.isEmpty) {
                                                return 'Please Enter Number';
                                              }
                                              return null;
                                            },
                                            showCharacterCount: true,
                                            onChanged: (value) =>
                                                schoolRecceController
                                                    .updateTotalStaff(), // Update total staff when this field changes
                                          ),
                                          CustomSizedBox(
                                              value: 20, side: 'height'),
                                          LabelText(
                                            label: 'Total Non Teaching Staff',
                                            astrick: true,
                                          ),
                                          CustomSizedBox(
                                              value: 20, side: 'height'),
                                          CustomTextFormField(
                                            textController: schoolRecceController
                                                .totalNonTeachingStaffController,
                                            labelText: 'Enter Teaching Staff',
                                            textInputType: TextInputType.number,

                                            validator: (value) {
                                              if (value!.isEmpty) {
                                                return 'Please Enter Number';
                                              }
                                              return null;
                                            },
                                            showCharacterCount: true,
                                            onChanged: (value) =>
                                                schoolRecceController
                                                    .updateTotalStaff(), // Update total staff when this field changes
                                          ),
                                          CustomSizedBox(
                                              value: 20, side: 'height'),
                                          LabelText(
                                            label: 'Total Staff',
                                            astrick: true,
                                          ),
                                          CustomSizedBox(
                                              value: 20, side: 'height'),
                                          CustomTextFormField(
                                            textController:
                                                schoolRecceController
                                                    .totalStaffController,
                                            labelText: 'Enter Teaching Staff',

                                            showCharacterCount: true,
                                            readOnly:
                                                true, // Make this field read-only
                                          ),
                                          CustomSizedBox(
                                              value: 20, side: 'height'),
                                          LabelText(
                                            label:
                                                'Upload photo of Teacher Register',
                                            astrick: true,
                                          ),
                                          CustomSizedBox(
                                              value: 20, side: 'height'),
                                          Container(
                                            height: 60,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(10.0),
                                              border: Border.all(
                                                width: 2,
                                                color: schoolRecceController
                                                            .isImageUploadedTeacherRegister ==
                                                        false
                                                    ? AppColors.primary
                                                    : AppColors.error,
                                              ),
                                            ),
                                            child: ListTile(
                                              title: Text(
                                                'Click or Upload Image',
                                                style: TextStyle(
                                                  color: schoolRecceController
                                                              .isImageUploadedTeacherRegister ==
                                                          false
                                                      ? Colors.black
                                                      : AppColors.error,
                                                ),
                                              ),
                                              trailing: const Icon(Icons.camera_alt,
                                                  color:
                                                      AppColors.onBackground),
                                              onTap: () {
                                                showModalBottomSheet(
                                                  backgroundColor:
                                                      AppColors.primary,
                                                  context: context,
                                                  builder: (builder) =>
                                                      schoolRecceController
                                                          .bottomSheet(
                                                              context, 3),
                                                );
                                              },
                                            ),
                                          ),
                                          ErrorText(
                                            isVisible: schoolRecceController
                                                .validateTeacherRegister,
                                            message: 'Image Required',
                                          ),
                                          CustomSizedBox(
                                            value: 20,
                                            side: 'height',
                                          ),
                                          schoolRecceController
                                                  .multipleImage3.isNotEmpty
                                              ? Container(
                                                  width: responsive
                                                      .responsiveValue(
                                                    small: 600.0,
                                                    medium: 900.0,
                                                    large: 1400.0,
                                                  ),
                                                  height: responsive
                                                      .responsiveValue(
                                                    small: 170.0,
                                                    medium: 170.0,
                                                    large: 170.0,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    border: Border.all(
                                                        color: Colors.grey),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                  ),
                                                  child: ListView.builder(
                                                    scrollDirection:
                                                        Axis.horizontal,
                                                    itemCount:
                                                        schoolRecceController
                                                            .multipleImage3
                                                            .length,
                                                    itemBuilder:
                                                        (context, index) {
                                                      return SizedBox(
                                                        height: 200,
                                                        width: 200,
                                                        child: Column(
                                                          children: [
                                                            Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .all(8.0),
                                                              child:
                                                                  GestureDetector(
                                                                onTap: () {
                                                                  CustomImagePreview
                                                                      .showImagePreview(
                                                                    schoolRecceController
                                                                        .multipleImage3[
                                                                            index]
                                                                        .path,
                                                                    context,
                                                                  );
                                                                },
                                                                child:
                                                                    Image.file(
                                                                  File(schoolRecceController
                                                                      .multipleImage3[
                                                                          index]
                                                                      .path),
                                                                  width: 190,
                                                                  height: 120,
                                                                  fit: BoxFit
                                                                      .fill,
                                                                ),
                                                              ),
                                                            ),
                                                            GestureDetector(
                                                              onTap: () {
                                                                setState(() {
                                                                  schoolRecceController
                                                                      .multipleImage3
                                                                      .removeAt(
                                                                          index);
                                                                });
                                                              },
                                                              child: const Icon(
                                                                Icons.delete,
                                                                color:
                                                                    Colors.red,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                )
                                              : const SizedBox(),
                                          CustomSizedBox(
                                            value: 20,
                                            side: 'height',
                                          ),
                                          Row(
                                            children: [
                                              CustomButton(
                                                  title: 'Back',
                                                  onPressedButton: () {
                                                    setState(() {
                                                      schoolRecceController
                                                              .showBasicDetails =
                                                          true;
                                                      schoolRecceController
                                                              .showStaffDetails =
                                                          false;
                                                    });
                                                  }),
                                              const Spacer(),
                                              CustomButton(
                                                title: 'Next',
                                                onPressedButton: () {
                                                  schoolRecceController
                                                          .validateTeacherRegister =
                                                      schoolRecceController
                                                          .multipleImage3
                                                          .isEmpty;

                                                  if (_formKey.currentState!
                                                          .validate() &&
                                                      !schoolRecceController
                                                          .validateTeacherRegister) {
                                                    setState(() {
                                                      schoolRecceController
                                                              .showStaffDetails =
                                                          false;
                                                      schoolRecceController
                                                              .showSmcVecDetails =
                                                          true;
                                                      WidgetsBinding.instance
                                                          .addPostFrameCallback(
                                                              (_) {
                                                        _scrollController
                                                            .animateTo(
                                                          0.0, // Scroll to the top
                                                          duration: const Duration(
                                                              milliseconds:
                                                                  300),
                                                          curve:
                                                              Curves.easeInOut,
                                                        );
                                                      });
                                                    });
                                                  }
                                                },
                                              ),
                                            ],
                                          ),
                                          CustomSizedBox(
                                            value: 20,
                                            side: 'height',
                                          ),
                                        ], // End of showStaffDetails

                                        // Start showSmcVecDetails

                                        if (schoolRecceController
                                            .showSmcVecDetails) ...[
                                          LabelText(
                                            label: 'SMC VEC Details',
                                          ),
                                          CustomSizedBox(
                                            value: 20,
                                            side: 'height',
                                          ),
                                          LabelText(
                                            label: 'Name of the SMC President',
                                            astrick: true,
                                          ),
                                          CustomSizedBox(
                                            value: 20,
                                            side: 'height',
                                          ),
                                          CustomTextFormField(
                                            textController:
                                                schoolRecceController
                                                    .nameOfSmcController,
                                            labelText: 'Enter Name',
                                            validator: (value) {
                                              if (value!.isEmpty) {
                                                return 'Please fill this field';
                                              }
                                              return null;
                                            },
                                            showCharacterCount: true,
                                          ),
                                          CustomSizedBox(
                                            value: 20,
                                            side: 'height',
                                          ),
                                          LabelText(
                                            label:
                                                'Phone no of the SMC President',
                                            astrick: true,
                                          ),
                                          CustomSizedBox(
                                            value: 20,
                                            side: 'height',
                                          ),
                                          CustomTextFormField(
                                            textController:
                                                schoolRecceController
                                                    .smcPhoneNumberController,
                                            labelText: 'Phone number of admin',
                                            textInputType: TextInputType.number,
                                            validator: (value) {
                                              if (value!.isEmpty) {
                                                return 'Write Admin Name';
                                              }

                                              // Regex for validating Indian phone number
                                              String pattern = r'^[6-9]\d{9}$';
                                              RegExp regex = RegExp(pattern);

                                              if (!regex.hasMatch(value)) {
                                                return 'Enter a valid phone number';
                                              }

                                              return null;
                                            },
                                            showCharacterCount: true,
                                          ),
                                          CustomSizedBox(
                                            value: 20,
                                            side: 'height',
                                          ),
                                          LabelText(
                                            label:
                                                'Educational Qualification of SMC President',
                                            astrick: true,
                                          ),
                                          CustomSizedBox(
                                            value: 20,
                                            side: 'height',
                                          ),
                                          DropdownButtonFormField<String>(
                                            decoration: const InputDecoration(
                                              labelText: 'Select an option',
                                              border: OutlineInputBorder(),
                                            ),
                                            value: schoolRecceController
                                                .selectedQualification,
                                            items: const [
                                              DropdownMenuItem(
                                                value: 'Non Graduate',
                                                child: Text('Non Graduate'),
                                              ),
                                              DropdownMenuItem(
                                                value: 'Graduate',
                                                child: Text('Graduate'),
                                              ),
                                              DropdownMenuItem(
                                                value: 'Post Graduate',
                                                child: Text('Post Graduate'),
                                              ),
                                              DropdownMenuItem(
                                                value: 'Other',
                                                child: Text('Other'),
                                              ),
                                            ],
                                            onChanged: (value) {
                                              // Ensure that the selected value is set properly
                                              setState(() {
                                                schoolRecceController
                                                        .selectedQualification =
                                                    value;
                                              });
                                            },
                                            validator: (value) {
                                              // Ensure that a selection is made
                                              if (value == null) {
                                                return 'Please select a Qualification';
                                              }
                                              return null;
                                            },
                                          ),
                                          CustomSizedBox(
                                              value: 20, side: 'height'),
                                          if (schoolRecceController
                                                  .selectedQualification ==
                                              'Other') ...[
                                            LabelText(
                                              label: 'Please Specify Other',
                                              astrick: true,
                                            ),
                                            CustomSizedBox(
                                                value: 20, side: 'height'),
                                            CustomTextFormField(
                                              textController:
                                                  schoolRecceController
                                                      .QualSpecifyController,
                                              labelText: 'Write here...',
                                              maxlines: 3,
                                              validator: (value) {
                                                if (value!.isEmpty) {
                                                  return 'Please fill this field';
                                                }

                                                if (value.length < 25) {
                                                  return 'Must be at least 25 characters long';
                                                }
                                                return null;
                                              },
                                              showCharacterCount: true,
                                            ),
                                          ],
                                          LabelText(
                                            label: 'Total no of SMC members',
                                            astrick: true,
                                          ),
                                          CustomSizedBox(
                                            value: 20,
                                            side: 'height',
                                          ),
                                          CustomTextFormField(
                                            textController:
                                                schoolRecceController
                                                    .totalnoOfSmcMemController,
                                            labelText: 'Enter Teaching Staff',
                                            textInputType: TextInputType.number,
                                            validator: (value) {
                                              if (value!.isEmpty) {
                                                return 'Please Enter Number';
                                              }
                                              return null;
                                            },
                                            showCharacterCount: true,
                                          ),
                                          CustomSizedBox(
                                              value: 20, side: 'height'),
                                          LabelText(
                                            label: 'Frequency of SMC meetings',
                                            astrick: true,
                                          ),
                                          CustomSizedBox(
                                            value: 20,
                                            side: 'height',
                                          ),
                                          DropdownButtonFormField<String>(
                                            decoration: const InputDecoration(
                                              labelText: 'Select an option',
                                              border: OutlineInputBorder(),
                                            ),
                                            value: schoolRecceController
                                                .selectedMeetings,
                                            items: const [
                                              DropdownMenuItem(
                                                  value: 'Once a month',
                                                  child: Text('Once a month')),
                                              DropdownMenuItem(
                                                  value: 'Once a quarter',
                                                  child:
                                                      Text('Once a quarter')),
                                              DropdownMenuItem(
                                                  value: 'Once in 6 months',
                                                  child:
                                                      Text('Once in 6 months')),
                                              DropdownMenuItem(
                                                  value: 'once_a_year',
                                                  child: Text('Once a year')),
                                              DropdownMenuItem(
                                                  value: 'Others',
                                                  child: Text('Others')),
                                            ],
                                            onChanged: (value) {
                                              setState(() {
                                                schoolRecceController
                                                    .selectedMeetings = value;
                                              });
                                            },
                                            validator: (value) {
                                              if (value == null) {
                                                return 'Please select a Option';
                                              }
                                              return null;
                                            },
                                          ),
                                          CustomSizedBox(
                                              value: 20, side: 'height'),
                                          if (schoolRecceController
                                                  .selectedMeetings ==
                                              'Others') ...[
                                            LabelText(
                                              label: 'Please Specify Other',
                                              astrick: true,
                                            ),
                                            CustomSizedBox(
                                                value: 20, side: 'height'),
                                            CustomTextFormField(
                                              textController:
                                                  schoolRecceController
                                                      .freSpecifyController,
                                              labelText: 'Write here...',
                                              maxlines: 3,
                                              validator: (value) {
                                                if (value!.isEmpty) {
                                                  return 'Please fill this field';
                                                }

                                                if (value.length < 25) {
                                                  return 'Must be at least 25 characters long';
                                                }
                                                return null;
                                              },
                                              showCharacterCount: true,
                                            ),
                                          ],
                                          LabelText(
                                            label:
                                                'How supportive are the SMC Members',
                                            astrick: true,
                                          ),
                                          CustomSizedBox(
                                            value: 20,
                                            side: 'height',
                                          ),
                                          CustomTextFormField(
                                            textController:
                                                schoolRecceController
                                                    .descriptionController,
                                            maxlines: 2,
                                            labelText: 'Write Description',
                                            validator: (value) {
                                              if (value!.isEmpty) {
                                                return 'Please fill this field';
                                              }

                                              if (value.length < 50) {
                                                return 'Please enter at least 50 characters';
                                              }
                                              return null;
                                            },
                                            showCharacterCount: true,
                                          ),
                                          CustomSizedBox(
                                            value: 20,
                                            side: 'height',
                                          ),
                                          Row(
                                            children: [
                                              CustomButton(
                                                  title: 'Back',
                                                  onPressedButton: () {
                                                    setState(() {
                                                      schoolRecceController
                                                              .showStaffDetails =
                                                          true;
                                                      schoolRecceController
                                                              .showSmcVecDetails =
                                                          false;
                                                    });
                                                  }),
                                              const Spacer(),
                                              CustomButton(
                                                title: 'Next',
                                                onPressedButton: () {
                                                  if (_formKey.currentState!
                                                      .validate()) {
                                                    setState(() {
                                                      schoolRecceController
                                                              .showSmcVecDetails =
                                                          false;
                                                      schoolRecceController
                                                              .showSchoolInfra =
                                                          true;
                                                      WidgetsBinding.instance
                                                          .addPostFrameCallback(
                                                              (_) {
                                                        _scrollController
                                                            .animateTo(
                                                          0.0, // Scroll to the top
                                                          duration: const Duration(
                                                              milliseconds:
                                                                  300),
                                                          curve:
                                                              Curves.easeInOut,
                                                        );
                                                      });
                                                    });
                                                  }
                                                },
                                              ),
                                            ],
                                          ),
                                          CustomSizedBox(
                                            value: 20,
                                            side: 'height',
                                          ),
                                        ], // End showSmcVecDetails

                                        // Start of showSchoolInfra

                                        if (schoolRecceController
                                            .showSchoolInfra) ...[
                                          LabelText(
                                            label: 'School Infrastructure',
                                          ),
                                          CustomSizedBox(
                                            value: 20,
                                            side: 'height',
                                          ),
                                          LabelText(
                                            label:
                                                'No of usable classrooms in schools',
                                            astrick: true,
                                          ),
                                          CustomSizedBox(
                                            value: 20,
                                            side: 'height',
                                          ),
                                          CustomTextFormField(
                                            textController:
                                                schoolRecceController
                                                    .noClassroomsController,
                                            textInputType: TextInputType.number,
                                            labelText: 'Enter number',
                                            validator: (value) {
                                              if (value == null ||
                                                  value.isEmpty) {
                                                return 'Please fill this field';
                                              }
                                              if (!RegExp(r'^[0-9]+$')
                                                  .hasMatch(value)) {
                                                return 'Please enter a valid number';
                                              }
                                              return null;
                                            },
                                            showCharacterCount: true,
                                          ),
                                          CustomSizedBox(
                                            value: 20,
                                            side: 'height',
                                          ),
                                          LabelText(
                                            label:
                                                'Availability of Electricity in Schools',
                                            astrick: true,
                                          ),
                                          CustomSizedBox(
                                            value: 20,
                                            side: 'height',
                                          ),

                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Radio<String>(
                                                    value: 'Continuous',
                                                    groupValue:
                                                        schoolRecceController
                                                            .getSelectedValue(
                                                                'electricity'),
                                                    onChanged: (value) {
                                                      schoolRecceController
                                                          .setRadioValue(
                                                              'electricity',
                                                              value);
                                                    },
                                                  ),
                                                  const Text('Continuous'),
                                                ],
                                              ),
                                              Row(
                                                children: [
                                                  Radio<String>(
                                                    value: 'Intermittent',
                                                    groupValue:
                                                        schoolRecceController
                                                            .getSelectedValue(
                                                                'electricity'),
                                                    onChanged: (value) {
                                                      schoolRecceController
                                                          .setRadioValue(
                                                              'electricity',
                                                              value);
                                                    },
                                                  ),
                                                  const Text('Intermittent'),
                                                ],
                                              ),
                                              const SizedBox(
                                                  width:
                                                      16), // Adjust spacing between rows
                                              Row(
                                                children: [
                                                  Radio<String>(
                                                    value: 'No',
                                                    groupValue:
                                                        schoolRecceController
                                                            .getSelectedValue(
                                                                'electricity'),
                                                    onChanged: (value) {
                                                      schoolRecceController
                                                          .setRadioValue(
                                                              'electricity',
                                                              value);
                                                    },
                                                  ),
                                                  const Text('No'),
                                                ],
                                              ),
                                              if (schoolRecceController
                                                  .getRadioFieldError(
                                                      'electricity'))
                                                const Padding(
                                                  padding: EdgeInsets.only(
                                                      left: 16.0),
                                                  child: Align(
                                                    alignment:
                                                        Alignment.centerLeft,
                                                    child: Text(
                                                      'Please select an option',
                                                      style: TextStyle(
                                                          color: Colors.red),
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),

                                          CustomSizedBox(
                                            value: 20,
                                            side: 'height',
                                          ),
                                          LabelText(
                                            label:
                                                'Availability of Network connectivity in school?',
                                            astrick: true,
                                          ),

                                          Padding(
                                            padding: EdgeInsets.only(
                                                right: screenWidth * 0.1),
                                            child: Row(
                                              children: [
                                                Radio(
                                                  value: 'Yes',
                                                  groupValue: schoolRecceController
                                                      .getSelectedValue(
                                                          'networkConnectivity'),
                                                  onChanged: (value) {
                                                    schoolRecceController
                                                        .setRadioValue(
                                                            'networkConnectivity',
                                                            value);
                                                  },
                                                ),
                                                const Text('Yes'),
                                              ],
                                            ),
                                          ),
                                          CustomSizedBox(
                                            value: 150,
                                            side: 'width',
                                          ),
                                          // make it that user can also edit the tourId and school
                                          Padding(
                                            padding: EdgeInsets.only(
                                                right: screenWidth * 0.1),
                                            child: Row(
                                              children: [
                                                Radio(
                                                  value: 'No',
                                                  groupValue: schoolRecceController
                                                      .getSelectedValue(
                                                          'networkConnectivity'),
                                                  onChanged: (value) {
                                                    schoolRecceController
                                                        .setRadioValue(
                                                            'networkConnectivity',
                                                            value);
                                                    if (value == 'No') {
                                                      schoolRecceController
                                                              .checkboxValue16 =
                                                          false;
                                                      schoolRecceController
                                                              .checkboxValue17 =
                                                          false;
                                                      schoolRecceController
                                                              .checkboxValue18 =
                                                          false;
                                                      schoolRecceController
                                                              .checkboxValue19 =
                                                          false;
                                                    }
                                                  },
                                                ),
                                                const Text('No'),
                                              ],
                                            ),
                                          ),
                                          if (schoolRecceController
                                              .getRadioFieldError(
                                                  'networkConnectivity'))
                                            const Padding(
                                              padding:
                                                  EdgeInsets.only(left: 16.0),
                                              child: Align(
                                                alignment: Alignment.centerLeft,
                                                child: Text(
                                                  'Please select an option',
                                                  style: TextStyle(
                                                      color: Colors.red),
                                                ),
                                              ),
                                            ),
                                          CustomSizedBox(
                                            value: 20,
                                            side: 'height',
                                          ),
                                          if (schoolRecceController
                                                  .getSelectedValue(
                                                      'networkConnectivity') ==
                                              'Yes') ...[
                                            LabelText(
                                              label: 'Select Option',
                                              astrick: true,
                                            ),
                                            CustomSizedBox(
                                              value: 20,
                                              side: 'height',
                                            ),
                                            CheckboxListTile(
                                              value: schoolRecceController
                                                  .checkboxValue16,
                                              onChanged: (bool? value) {
                                                setState(() {
                                                  schoolRecceController
                                                      .checkboxValue16 = value!;
                                                });
                                              },
                                              title: const Text('2G'),
                                              activeColor: Colors.green,
                                            ),
                                            CheckboxListTile(
                                              value: schoolRecceController
                                                  .checkboxValue17,
                                              onChanged: (bool? value) {
                                                setState(() {
                                                  schoolRecceController
                                                      .checkboxValue17 = value!;
                                                });
                                              },
                                              title: const Text('3G'),
                                              activeColor: Colors.green,
                                            ),
                                            CheckboxListTile(
                                              value: schoolRecceController
                                                  .checkboxValue18,
                                              onChanged: (bool? value) {
                                                setState(() {
                                                  schoolRecceController
                                                      .checkboxValue18 = value!;
                                                });
                                              },
                                              title: const Text('4G'),
                                              activeColor: Colors.green,
                                            ),
                                            CheckboxListTile(
                                              value: schoolRecceController
                                                  .checkboxValue19,
                                              onChanged: (bool? value) {
                                                setState(() {
                                                  schoolRecceController
                                                      .checkboxValue19 = value!;
                                                });
                                              },
                                              title: const Text('5G'),
                                              activeColor: Colors.green,
                                            ),
                                            if (schoolRecceController
                                                .checkBoxError2)
                                              const Padding(
                                                padding:
                                                    EdgeInsets.only(left: 16.0),
                                                child: Align(
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  child: Text(
                                                    'Please select at least one topic',
                                                    style: TextStyle(
                                                        color: Colors.red),
                                                  ),
                                                ),
                                              ),
                                            CustomSizedBox(
                                              value: 20,
                                              side: 'height',
                                            ),
                                          ],
                                          LabelText(
                                            label:
                                                'Availability of Digital Learning Facilities in school?',
                                            astrick: true,
                                          ),
                                          CustomSizedBox(
                                            value: 20,
                                            side: 'height',
                                          ),
                                          Padding(
                                            padding: EdgeInsets.only(
                                                right: screenWidth * 0.1),
                                            child: Row(
                                              children: [
                                                Radio(
                                                  value: 'Yes',
                                                  groupValue:
                                                      schoolRecceController
                                                          .getSelectedValue(
                                                              'learningFacility'),
                                                  onChanged: (value) {
                                                    schoolRecceController
                                                        .setRadioValue(
                                                            'learningFacility',
                                                            value);
                                                  },
                                                ),
                                                const Text('Yes'),
                                              ],
                                            ),
                                          ),
                                          CustomSizedBox(
                                            value: 150,
                                            side: 'width',
                                          ),
                                          // make it that user can also edit the tourId and school
                                          Padding(
                                            padding: EdgeInsets.only(
                                                right: screenWidth * 0.1),
                                            child: Row(
                                              children: [
                                                Radio(
                                                  value: 'No',
                                                  groupValue:
                                                      schoolRecceController
                                                          .getSelectedValue(
                                                              'learningFacility'),
                                                  onChanged: (value) {
                                                    schoolRecceController
                                                        .setRadioValue(
                                                            'learningFacility',
                                                            value);
                                                    if (value == 'No') {
                                                      schoolRecceController
                                                              .checkboxValue20 =
                                                          false;
                                                      schoolRecceController
                                                              .checkboxValue21 =
                                                          false;
                                                      schoolRecceController
                                                              .checkboxValue22 =
                                                          false;
                                                      schoolRecceController
                                                          .multipleImage4
                                                          .clear();
                                                      schoolRecceController
                                                          .multipleImage5
                                                          .clear();
                                                      schoolRecceController
                                                          .multipleImage6
                                                          .clear();
                                                    }
                                                  },
                                                ),
                                                const Text('No'),
                                              ],
                                            ),
                                          ),
                                          if (schoolRecceController
                                              .getRadioFieldError(
                                                  'learningFacility'))
                                            const Padding(
                                              padding:
                                                  EdgeInsets.only(left: 16.0),
                                              child: Align(
                                                alignment: Alignment.centerLeft,
                                                child: Text(
                                                  'Please select an option',
                                                  style: TextStyle(
                                                      color: Colors.red),
                                                ),
                                              ),
                                            ),
                                          CustomSizedBox(
                                            value: 20,
                                            side: 'height',
                                          ),

                                          if (schoolRecceController
                                                  .getSelectedValue(
                                                      'learningFacility') ==
                                              'Yes') ...[
                                            LabelText(
                                              label: 'Select Option',
                                              astrick: true,
                                            ),
                                            CustomSizedBox(
                                              value: 20,
                                              side: 'height',
                                            ),
                                            CheckboxListTile(
                                              value: schoolRecceController
                                                  .checkboxValue20,
                                              onChanged: (bool? value) {
                                                setState(() {
                                                  schoolRecceController
                                                      .checkboxValue20 = value!;

                                                  // Clear multiImage4 when checkbox16 is unchecked
                                                  if (!schoolRecceController
                                                      .checkboxValue16) {
                                                    schoolRecceController
                                                        .multipleImage4
                                                        .clear();
                                                  }
                                                });
                                              },
                                              title: const Text('Smart Class'),
                                              activeColor: Colors.green,
                                            ),
                                            CheckboxListTile(
                                              value: schoolRecceController
                                                  .checkboxValue21,
                                              onChanged: (bool? value) {
                                                setState(() {
                                                  schoolRecceController
                                                      .checkboxValue21 = value!;

                                                  // Clear multiImage4 when checkbox16 is unchecked
                                                  if (!schoolRecceController
                                                      .checkboxValue16) {
                                                    schoolRecceController
                                                        .multipleImage5
                                                        .clear();
                                                  }
                                                });
                                              },
                                              title: const Text('Projector'),
                                              activeColor: Colors.green,
                                            ),
                                            CheckboxListTile(
                                              value: schoolRecceController
                                                  .checkboxValue22,
                                              onChanged: (bool? value) {
                                                setState(() {
                                                  schoolRecceController
                                                      .checkboxValue22 = value!;
                                                  if (!schoolRecceController
                                                      .checkboxValue16) {
                                                    schoolRecceController
                                                        .multipleImage6
                                                        .clear();
                                                  }
                                                });
                                              },
                                              title: const Text('Computer'),
                                              activeColor: Colors.green,
                                            ),
                                            if (schoolRecceController
                                                .checkBoxError3)
                                              const Padding(
                                                padding:
                                                    EdgeInsets.only(left: 16.0),
                                                child: Align(
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  child: Text(
                                                    'Please select at least one topic',
                                                    style: TextStyle(
                                                        color: Colors.red),
                                                  ),
                                                ),
                                              ),
                                            CustomSizedBox(
                                              value: 20,
                                              side: 'height',
                                            ),
                                          ],
                                          if (schoolRecceController
                                              .checkboxValue20) ...[
                                            LabelText(
                                              label:
                                                  'Upload photo of Smart Class',
                                              astrick: true,
                                            ),
                                            CustomSizedBox(
                                              value: 20,
                                              side: 'height',
                                            ),
                                            Container(
                                              height: 60,
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(10.0),
                                                border: Border.all(
                                                  width: 2,
                                                  color: schoolRecceController
                                                              .isImageUploadedSmartClass ==
                                                          false
                                                      ? AppColors.primary
                                                      : AppColors.error,
                                                ),
                                              ),
                                              child: ListTile(
                                                title: Text(
                                                  'Click or Upload Image',
                                                  style: TextStyle(
                                                    color: schoolRecceController
                                                                .isImageUploadedSmartClass ==
                                                            false
                                                        ? Colors.black
                                                        : AppColors.error,
                                                  ),
                                                ),
                                                trailing: const Icon(Icons.camera_alt,
                                                    color:
                                                        AppColors.onBackground),
                                                onTap: () {
                                                  showModalBottomSheet(
                                                    backgroundColor:
                                                        AppColors.primary,
                                                    context: context,
                                                    builder: (builder) =>
                                                        schoolRecceController
                                                            .bottomSheet(
                                                                context, 4),
                                                  );
                                                },
                                              ),
                                            ),
                                            ErrorText(
                                              isVisible: schoolRecceController
                                                  .validateSmartClass,
                                              message: 'Image Required',
                                            ),
                                            CustomSizedBox(
                                              value: 20,
                                              side: 'height',
                                            ),
                                            schoolRecceController
                                                    .multipleImage4.isNotEmpty
                                                ? Container(
                                                    width: responsive
                                                        .responsiveValue(
                                                      small: 600.0,
                                                      medium: 900.0,
                                                      large: 1400.0,
                                                    ),
                                                    height: responsive
                                                        .responsiveValue(
                                                      small: 170.0,
                                                      medium: 170.0,
                                                      large: 170.0,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      border: Border.all(
                                                          color: Colors.grey),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10),
                                                    ),
                                                    child: ListView.builder(
                                                      scrollDirection:
                                                          Axis.horizontal,
                                                      itemCount:
                                                          schoolRecceController
                                                              .multipleImage4
                                                              .length,
                                                      itemBuilder:
                                                          (context, index) {
                                                        return SizedBox(
                                                          height: 200,
                                                          width: 200,
                                                          child: Column(
                                                            children: [
                                                              Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                        .all(
                                                                            8.0),
                                                                child:
                                                                    GestureDetector(
                                                                  onTap: () {
                                                                    CustomImagePreview
                                                                        .showImagePreview(
                                                                      schoolRecceController
                                                                          .multipleImage4[
                                                                              index]
                                                                          .path,
                                                                      context,
                                                                    );
                                                                  },
                                                                  child: Image
                                                                      .file(
                                                                    File(schoolRecceController
                                                                        .multipleImage4[
                                                                            index]
                                                                        .path),
                                                                    width: 190,
                                                                    height: 120,
                                                                    fit: BoxFit
                                                                        .fill,
                                                                  ),
                                                                ),
                                                              ),
                                                              GestureDetector(
                                                                onTap: () {
                                                                  setState(() {
                                                                    schoolRecceController
                                                                        .multipleImage4
                                                                        .removeAt(
                                                                            index);
                                                                  });
                                                                },
                                                                child: const Icon(
                                                                  Icons.delete,
                                                                  color: Colors
                                                                      .red,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                  )
                                                : const SizedBox(),
                                            CustomSizedBox(
                                              value: 20,
                                              side: 'height',
                                            ),
                                          ],
                                          if (schoolRecceController
                                              .checkboxValue21) ...[
                                            LabelText(
                                              label:
                                                  'Upload photo of Projector',
                                              astrick: true,
                                            ),
                                            CustomSizedBox(
                                              value: 20,
                                              side: 'height',
                                            ),
                                            Container(
                                              height: 60,
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(10.0),
                                                border: Border.all(
                                                  width: 2,
                                                  color: schoolRecceController
                                                              .isImageUploadedSmartClass ==
                                                          false
                                                      ? AppColors.primary
                                                      : AppColors.error,
                                                ),
                                              ),
                                              child: ListTile(
                                                title: Text(
                                                  'Click or Upload Image',
                                                  style: TextStyle(
                                                    color: schoolRecceController
                                                                .isImageUploadedSmartClass ==
                                                            false
                                                        ? Colors.black
                                                        : AppColors.error,
                                                  ),
                                                ),
                                                trailing: const Icon(Icons.camera_alt,
                                                    color:
                                                        AppColors.onBackground),
                                                onTap: () {
                                                  showModalBottomSheet(
                                                    backgroundColor:
                                                        AppColors.primary,
                                                    context: context,
                                                    builder: (builder) =>
                                                        schoolRecceController
                                                            .bottomSheet(
                                                                context, 5),
                                                  );
                                                },
                                              ),
                                            ),
                                            ErrorText(
                                              isVisible: schoolRecceController
                                                  .validateSmartClass,
                                              message: 'Image Required',
                                            ),
                                            CustomSizedBox(
                                              value: 20,
                                              side: 'height',
                                            ),
                                            schoolRecceController
                                                    .multipleImage5.isNotEmpty
                                                ? Container(
                                                    width: responsive
                                                        .responsiveValue(
                                                      small: 600.0,
                                                      medium: 900.0,
                                                      large: 1400.0,
                                                    ),
                                                    height: responsive
                                                        .responsiveValue(
                                                      small: 170.0,
                                                      medium: 170.0,
                                                      large: 170.0,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      border: Border.all(
                                                          color: Colors.grey),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10),
                                                    ),
                                                    child: ListView.builder(
                                                      scrollDirection:
                                                          Axis.horizontal,
                                                      itemCount:
                                                          schoolRecceController
                                                              .multipleImage5
                                                              .length,
                                                      itemBuilder:
                                                          (context, index) {
                                                        return SizedBox(
                                                          height: 200,
                                                          width: 200,
                                                          child: Column(
                                                            children: [
                                                              Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                        .all(
                                                                            8.0),
                                                                child:
                                                                    GestureDetector(
                                                                  onTap: () {
                                                                    CustomImagePreview
                                                                        .showImagePreview(
                                                                      schoolRecceController
                                                                          .multipleImage5[
                                                                              index]
                                                                          .path,
                                                                      context,
                                                                    );
                                                                  },
                                                                  child: Image
                                                                      .file(
                                                                    File(schoolRecceController
                                                                        .multipleImage5[
                                                                            index]
                                                                        .path),
                                                                    width: 190,
                                                                    height: 120,
                                                                    fit: BoxFit
                                                                        .fill,
                                                                  ),
                                                                ),
                                                              ),
                                                              GestureDetector(
                                                                onTap: () {
                                                                  setState(() {
                                                                    schoolRecceController
                                                                        .multipleImage5
                                                                        .removeAt(
                                                                            index);
                                                                  });
                                                                },
                                                                child: const Icon(
                                                                  Icons.delete,
                                                                  color: Colors
                                                                      .red,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                  )
                                                : const SizedBox(),
                                            CustomSizedBox(
                                              value: 20,
                                              side: 'height',
                                            ),
                                          ],
                                          if (schoolRecceController
                                              .checkboxValue22) ...[
                                            LabelText(
                                              label: 'Upload photo of Computer',
                                              astrick: true,
                                            ),
                                            CustomSizedBox(
                                              value: 20,
                                              side: 'height',
                                            ),
                                            Container(
                                              height: 60,
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(10.0),
                                                border: Border.all(
                                                  width: 2,
                                                  color: schoolRecceController
                                                              .isImageUploadedComputer ==
                                                          false
                                                      ? AppColors.primary
                                                      : AppColors.error,
                                                ),
                                              ),
                                              child: ListTile(
                                                title: Text(
                                                  'Click or Upload Image',
                                                  style: TextStyle(
                                                    color: schoolRecceController
                                                                .isImageUploadedComputer ==
                                                            false
                                                        ? Colors.black
                                                        : AppColors.error,
                                                  ),
                                                ),
                                                trailing: const Icon(Icons.camera_alt,
                                                    color:
                                                        AppColors.onBackground),
                                                onTap: () {
                                                  showModalBottomSheet(
                                                    backgroundColor:
                                                        AppColors.primary,
                                                    context: context,
                                                    builder: (builder) =>
                                                        schoolRecceController
                                                            .bottomSheet(
                                                                context, 6),
                                                  );
                                                },
                                              ),
                                            ),
                                            ErrorText(
                                              isVisible: schoolRecceController
                                                  .validateComputer,
                                              message: 'Image Required',
                                            ),
                                            CustomSizedBox(
                                              value: 20,
                                              side: 'height',
                                            ),
                                            schoolRecceController
                                                    .multipleImage6.isNotEmpty
                                                ? Container(
                                                    width: responsive
                                                        .responsiveValue(
                                                      small: 600.0,
                                                      medium: 900.0,
                                                      large: 1400.0,
                                                    ),
                                                    height: responsive
                                                        .responsiveValue(
                                                      small: 170.0,
                                                      medium: 170.0,
                                                      large: 170.0,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      border: Border.all(
                                                          color: Colors.grey),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10),
                                                    ),
                                                    child: ListView.builder(
                                                      scrollDirection:
                                                          Axis.horizontal,
                                                      itemCount:
                                                          schoolRecceController
                                                              .multipleImage6
                                                              .length,
                                                      itemBuilder:
                                                          (context, index) {
                                                        return SizedBox(
                                                          height: 200,
                                                          width: 200,
                                                          child: Column(
                                                            children: [
                                                              Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                        .all(
                                                                            8.0),
                                                                child:
                                                                    GestureDetector(
                                                                  onTap: () {
                                                                    CustomImagePreview
                                                                        .showImagePreview(
                                                                      schoolRecceController
                                                                          .multipleImage6[
                                                                              index]
                                                                          .path,
                                                                      context,
                                                                    );
                                                                  },
                                                                  child: Image
                                                                      .file(
                                                                    File(schoolRecceController
                                                                        .multipleImage6[
                                                                            index]
                                                                        .path),
                                                                    width: 190,
                                                                    height: 120,
                                                                    fit: BoxFit
                                                                        .fill,
                                                                  ),
                                                                ),
                                                              ),
                                                              GestureDetector(
                                                                onTap: () {
                                                                  setState(() {
                                                                    schoolRecceController
                                                                        .multipleImage6
                                                                        .removeAt(
                                                                            index);
                                                                  });
                                                                },
                                                                child: const Icon(
                                                                  Icons.delete,
                                                                  color: Colors
                                                                      .red,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                  )
                                                : const SizedBox(),
                                            CustomSizedBox(
                                              value: 20,
                                              side: 'height',
                                            ),
                                          ],
                                          LabelText(
                                            label: 'Existing Library in School',
                                            astrick: true,
                                          ),
                                          CustomSizedBox(
                                            value: 20,
                                            side: 'height',
                                          ),
                                          Padding(
                                            padding: EdgeInsets.only(
                                                right: screenWidth * 0.1),
                                            child: Row(
                                              children: [
                                                Radio(
                                                  value: 'Yes',
                                                  groupValue:
                                                      schoolRecceController
                                                          .getSelectedValue(
                                                              'existingLibrary'),
                                                  onChanged: (value) {
                                                    schoolRecceController
                                                        .setRadioValue(
                                                            'existingLibrary',
                                                            value);
                                                  },
                                                ),
                                                const Text('Yes'),
                                              ],
                                            ),
                                          ),
                                          CustomSizedBox(
                                            value: 150,
                                            side: 'width',
                                          ),
                                          // make it that user can also edit the tourId and school
                                          Padding(
                                            padding: EdgeInsets.only(
                                                right: screenWidth * 0.1),
                                            child: Row(
                                              children: [
                                                Radio(
                                                  value: 'No',
                                                  groupValue:
                                                      schoolRecceController
                                                          .getSelectedValue(
                                                              'existingLibrary'),
                                                  onChanged: (value) {
                                                    schoolRecceController
                                                        .setRadioValue(
                                                            'existingLibrary',
                                                            value);
                                                    if (value == 'No') {
                                                      schoolRecceController
                                                          .multipleImage7
                                                          .clear();
                                                    }
                                                  },
                                                ),
                                                const Text('No'),
                                              ],
                                            ),
                                          ),
                                          if (schoolRecceController
                                              .getRadioFieldError(
                                                  'existingLibrary'))
                                            const Padding(
                                              padding:
                                                  EdgeInsets.only(left: 16.0),
                                              child: Align(
                                                alignment: Alignment.centerLeft,
                                                child: Text(
                                                  'Please select an option',
                                                  style: TextStyle(
                                                      color: Colors.red),
                                                ),
                                              ),
                                            ),
                                          CustomSizedBox(
                                            value: 20,
                                            side: 'height',
                                          ),
                                          if (schoolRecceController
                                                  .getSelectedValue(
                                                      'existingLibrary') ==
                                              'Yes') ...[
                                            LabelText(
                                              label: 'Upload photo of Library',
                                              astrick: true,
                                            ),
                                            CustomSizedBox(
                                              value: 20,
                                              side: 'height',
                                            ),
                                            Container(
                                              height: 60,
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(10.0),
                                                border: Border.all(
                                                  width: 2,
                                                  color: schoolRecceController
                                                              .isImageUploadedExisitingLibrary ==
                                                          false
                                                      ? AppColors.primary
                                                      : AppColors.error,
                                                ),
                                              ),
                                              child: ListTile(
                                                title: Text(
                                                  'Click or Upload Image',
                                                  style: TextStyle(
                                                    color: schoolRecceController
                                                                .isImageUploadedExisitingLibrary ==
                                                            false
                                                        ? Colors.black
                                                        : AppColors.error,
                                                  ),
                                                ),
                                                trailing: const Icon(Icons.camera_alt,
                                                    color:
                                                        AppColors.onBackground),
                                                onTap: () {
                                                  showModalBottomSheet(
                                                    backgroundColor:
                                                        AppColors.primary,
                                                    context: context,
                                                    builder: (builder) =>
                                                        schoolRecceController
                                                            .bottomSheet(
                                                                context, 7),
                                                  );
                                                },
                                              ),
                                            ),
                                            ErrorText(
                                              isVisible: schoolRecceController
                                                  .validateExisitingLibrary,
                                              message: 'Image Required',
                                            ),
                                            CustomSizedBox(
                                              value: 20,
                                              side: 'height',
                                            ),
                                            schoolRecceController
                                                    .multipleImage7.isNotEmpty
                                                ? Container(
                                                    width: responsive
                                                        .responsiveValue(
                                                      small: 600.0,
                                                      medium: 900.0,
                                                      large: 1400.0,
                                                    ),
                                                    height: responsive
                                                        .responsiveValue(
                                                      small: 170.0,
                                                      medium: 170.0,
                                                      large: 170.0,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      border: Border.all(
                                                          color: Colors.grey),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10),
                                                    ),
                                                    child: ListView.builder(
                                                      scrollDirection:
                                                          Axis.horizontal,
                                                      itemCount:
                                                          schoolRecceController
                                                              .multipleImage7
                                                              .length,
                                                      itemBuilder:
                                                          (context, index) {
                                                        return SizedBox(
                                                          height: 200,
                                                          width: 200,
                                                          child: Column(
                                                            children: [
                                                              Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                        .all(
                                                                            8.0),
                                                                child:
                                                                    GestureDetector(
                                                                  onTap: () {
                                                                    CustomImagePreview
                                                                        .showImagePreview(
                                                                      schoolRecceController
                                                                          .multipleImage7[
                                                                              index]
                                                                          .path,
                                                                      context,
                                                                    );
                                                                  },
                                                                  child: Image
                                                                      .file(
                                                                    File(schoolRecceController
                                                                        .multipleImage7[
                                                                            index]
                                                                        .path),
                                                                    width: 190,
                                                                    height: 120,
                                                                    fit: BoxFit
                                                                        .fill,
                                                                  ),
                                                                ),
                                                              ),
                                                              GestureDetector(
                                                                onTap: () {
                                                                  setState(() {
                                                                    schoolRecceController
                                                                        .multipleImage7
                                                                        .removeAt(
                                                                            index);
                                                                  });
                                                                },
                                                                child: const Icon(
                                                                  Icons.delete,
                                                                  color: Colors
                                                                      .red,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                  )
                                                : const SizedBox(),
                                            CustomSizedBox(
                                              value: 20,
                                              side: 'height',
                                            ),
                                          ],

                                          LabelText(
                                            label:
                                                'Approx. measurement of space for playground',
                                            astrick: true,
                                          ),
                                          CustomSizedBox(
                                            value: 20,
                                            side: 'height',
                                          ),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: CustomTextFormField(
                                                  textController:
                                                      schoolRecceController
                                                          .measurnment1Controller,
                                                  textInputType:
                                                      TextInputType.number,
                                                  validator: (value) {
                                                    if (value == null ||
                                                        value.isEmpty) {
                                                      return 'Please fill this field';
                                                    }
                                                    if (!RegExp(r'^[0-9]+$')
                                                        .hasMatch(value)) {
                                                      return 'Please enter the width';
                                                    }
                                                    return null;
                                                  },
                                                  showCharacterCount: true,
                                                ),
                                              ),
                                              CustomSizedBox(
                                                value: 8,
                                                side: 'width',
                                              ),
                                              const Text(
                                                'X',
                                                style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: CustomTextFormField(
                                                  textController:
                                                      schoolRecceController
                                                          .measurnment2Controller,
                                                  textInputType:
                                                      TextInputType.number,
                                                  validator: (value) {
                                                    if (value == null ||
                                                        value.isEmpty) {
                                                      return 'Please fill this field';
                                                    }
                                                    if (!RegExp(r'^[0-9]+$')
                                                        .hasMatch(value)) {
                                                      return 'Please enter the width';
                                                    }
                                                    return null;
                                                  },
                                                  showCharacterCount: true,
                                                ),
                                              ),
                                              CustomSizedBox(
                                                value: 8,
                                                side: 'width',
                                              ),
                                              const Text(
                                                'feet',
                                                style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                          CustomSizedBox(
                                            value: 20,
                                            side: 'height',
                                          ),
                                          LabelText(
                                            label:
                                                'Upload photo of Available Space',
                                            astrick: true,
                                          ),
                                          CustomSizedBox(
                                            value: 20,
                                            side: 'height',
                                          ),
                                          Container(
                                            height: 60,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(10.0),
                                              border: Border.all(
                                                width: 2,
                                                color: schoolRecceController
                                                            .isImageUploadedAvailabaleSpace ==
                                                        false
                                                    ? AppColors.primary
                                                    : AppColors.error,
                                              ),
                                            ),
                                            child: ListTile(
                                              title: Text(
                                                'Click or Upload Image',
                                                style: TextStyle(
                                                  color: schoolRecceController
                                                              .isImageUploadedAvailabaleSpace ==
                                                          false
                                                      ? Colors.black
                                                      : AppColors.error,
                                                ),
                                              ),
                                              trailing: const Icon(Icons.camera_alt,
                                                  color:
                                                      AppColors.onBackground),
                                              onTap: () {
                                                showModalBottomSheet(
                                                  backgroundColor:
                                                      AppColors.primary,
                                                  context: context,
                                                  builder: (builder) =>
                                                      schoolRecceController
                                                          .bottomSheet(
                                                              context, 8),
                                                );
                                              },
                                            ),
                                          ),
                                          ErrorText(
                                            isVisible: schoolRecceController
                                                .validateAvailabaleSpace,
                                            message: 'Image Required',
                                          ),
                                          CustomSizedBox(
                                            value: 20,
                                            side: 'height',
                                          ),
                                          schoolRecceController
                                                  .multipleImage8.isNotEmpty
                                              ? Container(
                                                  width: responsive
                                                      .responsiveValue(
                                                    small: 600.0,
                                                    medium: 900.0,
                                                    large: 1400.0,
                                                  ),
                                                  height: responsive
                                                      .responsiveValue(
                                                    small: 170.0,
                                                    medium: 170.0,
                                                    large: 170.0,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    border: Border.all(
                                                        color: Colors.grey),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                  ),
                                                  child: ListView.builder(
                                                    scrollDirection:
                                                        Axis.horizontal,
                                                    itemCount:
                                                        schoolRecceController
                                                            .multipleImage8
                                                            .length,
                                                    itemBuilder:
                                                        (context, index) {
                                                      return SizedBox(
                                                        height: 200,
                                                        width: 200,
                                                        child: Column(
                                                          children: [
                                                            Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .all(8.0),
                                                              child:
                                                                  GestureDetector(
                                                                onTap: () {
                                                                  CustomImagePreview
                                                                      .showImagePreview(
                                                                    schoolRecceController
                                                                        .multipleImage8[
                                                                            index]
                                                                        .path,
                                                                    context,
                                                                  );
                                                                },
                                                                child:
                                                                    Image.file(
                                                                  File(schoolRecceController
                                                                      .multipleImage8[
                                                                          index]
                                                                      .path),
                                                                  width: 190,
                                                                  height: 120,
                                                                  fit: BoxFit
                                                                      .fill,
                                                                ),
                                                              ),
                                                            ),
                                                            GestureDetector(
                                                              onTap: () {
                                                                setState(() {
                                                                  schoolRecceController
                                                                      .multipleImage8
                                                                      .removeAt(
                                                                          index);
                                                                });
                                                              },
                                                              child: const Icon(
                                                                Icons.delete,
                                                                color:
                                                                    Colors.red,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                )
                                              : const SizedBox(),
                                          CustomSizedBox(
                                            value: 20,
                                            side: 'height',
                                          ),
                                          Row(
                                            children: [
                                              CustomButton(
                                                  title: 'Back',
                                                  onPressedButton: () {
                                                    setState(() {
                                                      schoolRecceController
                                                              .showSmcVecDetails =
                                                          true;
                                                      schoolRecceController
                                                              .showSchoolInfra =
                                                          false;
                                                    });
                                                  }),
                                              const Spacer(),
                                              CustomButton(
                                                title: 'Next',
                                                onPressedButton: () {
                                                  // Perform radio button validation
                                                  final isRadioValid1 =
                                                      schoolRecceController
                                                          .validateRadioSelection(
                                                              'electricity');
                                                  final isRadioValid2 =
                                                      schoolRecceController
                                                          .validateRadioSelection(
                                                              'networkConnectivity');
                                                  final isRadioValid3 =
                                                      schoolRecceController
                                                          .validateRadioSelection(
                                                              'learningFacility');
                                                  final isRadioValid4 =
                                                      schoolRecceController
                                                          .validateRadioSelection(
                                                              'existingLibrary');

                                                  // Validate checkboxes if 'networkConnectivity' is 'Yes'
                                                  if (schoolRecceController
                                                          .getSelectedValue(
                                                              'networkConnectivity') ==
                                                      'Yes') {
                                                    bool isCheckboxSelected =
                                                        schoolRecceController
                                                                .checkboxValue16 ||
                                                            schoolRecceController
                                                                .checkboxValue17 ||
                                                            schoolRecceController
                                                                .checkboxValue18 ||
                                                            schoolRecceController
                                                                .checkboxValue19;

                                                    setState(() {
                                                      schoolRecceController
                                                              .checkBoxError2 =
                                                          !isCheckboxSelected;
                                                    });

                                                    if (!isCheckboxSelected) {
                                                      return; // Exit early if validation fails
                                                    }
                                                  }

                                                  // Validate checkboxes if 'learningFacility' is 'Yes'
                                                  if (schoolRecceController
                                                          .getSelectedValue(
                                                              'learningFacility') ==
                                                      'Yes') {
                                                    bool isCheckboxSelected2 =
                                                        schoolRecceController
                                                                .checkboxValue20 ||
                                                            schoolRecceController
                                                                .checkboxValue21 ||
                                                            schoolRecceController
                                                                .checkboxValue22;

                                                    setState(() {
                                                      schoolRecceController
                                                              .checkBoxError3 =
                                                          !isCheckboxSelected2;
                                                    });

                                                    if (!isCheckboxSelected2) {
                                                      return; // Exit early if validation fails
                                                    }
                                                  }

                                                  setState(() {
                                                    if (schoolRecceController
                                                            .getSelectedValue(
                                                                'existingLibrary') ==
                                                        'Yes') {
                                                      schoolRecceController
                                                              .validateExisitingLibrary =
                                                          schoolRecceController
                                                              .multipleImage7
                                                              .isEmpty;
                                                    } else {
                                                      schoolRecceController
                                                              .validateExisitingLibrary =
                                                          false; // Skip validation
                                                    }

                                                    if (schoolRecceController
                                                        .checkboxValue20) {
                                                      schoolRecceController
                                                              .validateSmartClass =
                                                          schoolRecceController
                                                              .multipleImage4
                                                              .isEmpty;
                                                    } else {
                                                      schoolRecceController
                                                              .validateSmartClass =
                                                          false; // Skip validation
                                                    }

                                                    if (schoolRecceController
                                                        .checkboxValue21) {
                                                      schoolRecceController
                                                              .validateProjector =
                                                          schoolRecceController
                                                              .multipleImage5
                                                              .isEmpty;
                                                    } else {
                                                      schoolRecceController
                                                              .validateProjector =
                                                          false; // Skip validation
                                                    }

                                                    if (schoolRecceController
                                                        .checkboxValue22) {
                                                      schoolRecceController
                                                              .validateComputer =
                                                          schoolRecceController
                                                              .multipleImage6
                                                              .isEmpty;
                                                    } else {
                                                      schoolRecceController
                                                              .validateComputer =
                                                          false; // Skip validation
                                                    }
                                                    schoolRecceController
                                                            .validateAvailabaleSpace =
                                                        schoolRecceController
                                                            .multipleImage8
                                                            .isEmpty;
                                                  });

                                                  // Proceed with form validation
                                                  if (_formKey.currentState!
                                                          .validate() &&
                                                      isRadioValid1 &&
                                                      isRadioValid2 &&
                                                      isRadioValid3 &&
                                                      isRadioValid4 &&
                                                      !schoolRecceController
                                                          .validateExisitingLibrary &&
                                                      !schoolRecceController
                                                          .validateSmartClass &&
                                                      !schoolRecceController
                                                          .validateProjector &&
                                                      !schoolRecceController
                                                          .validateComputer &&
                                                      !schoolRecceController
                                                          .validateAvailabaleSpace) {
                                                    setState(() {
                                                      // Transition to the next view or state
                                                      schoolRecceController
                                                              .showSchoolInfra =
                                                          false;
                                                      schoolRecceController
                                                              .showSchoolStrngth =
                                                          true;
                                                      WidgetsBinding.instance
                                                          .addPostFrameCallback(
                                                              (_) {
                                                        _scrollController
                                                            .animateTo(
                                                          0.0, // Scroll to the top
                                                          duration: const Duration(
                                                              milliseconds:
                                                                  300),
                                                          curve:
                                                              Curves.easeInOut,
                                                        );
                                                      });
                                                    });
                                                  }
                                                },
                                              ),
                                            ],
                                          ),
                                          CustomSizedBox(
                                            value: 20,
                                            side: 'height',
                                          ),
                                        ], // End of showSchoolInfra

                                        // Start of showSchoolStrngth

                                        if (schoolRecceController
                                            .showSchoolStrngth) ...[
                                          LabelText(
                                            label: 'School Strength',
                                          ),
                                          CustomSizedBox(
                                            value: 20,
                                            side: 'height',
                                          ),
                                          LabelText(
                                            label:
                                                'Class wise enrolment for the current year',
                                            astrick: true,
                                          ),
                                          CustomSizedBox(
                                            value: 20,
                                            side: 'height',
                                          ),
                                          if (isInitialized)
                                            Column(
                                              children: [
                                                Table(
                                                  border: TableBorder.all(),
                                                  children: [
                                                    // Header Row
                                                    const TableRow(
                                                      children: [
                                                        TableCell(
                                                          verticalAlignment:
                                                              TableCellVerticalAlignment
                                                                  .middle,
                                                          child: Center(
                                                            child: Text(
                                                              'Grade',
                                                              style: TextStyle(
                                                                  fontSize: 18,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold),
                                                            ),
                                                          ),
                                                        ),
                                                        TableCell(
                                                          verticalAlignment:
                                                              TableCellVerticalAlignment
                                                                  .middle,
                                                          child: Center(
                                                            child: Text(
                                                              'Boys',
                                                              style: TextStyle(
                                                                  fontSize: 18,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold),
                                                            ),
                                                          ),
                                                        ),
                                                        TableCell(
                                                          verticalAlignment:
                                                              TableCellVerticalAlignment
                                                                  .middle,
                                                          child: Center(
                                                            child: Text(
                                                              'Girls',
                                                              style: TextStyle(
                                                                  fontSize: 18,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold),
                                                            ),
                                                          ),
                                                        ),
                                                        TableCell(
                                                          verticalAlignment:
                                                              TableCellVerticalAlignment
                                                                  .middle,
                                                          child: Center(
                                                            child: Text(
                                                              'Total',
                                                              style: TextStyle(
                                                                  fontSize: 18,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),

                                                    // Grade Rows
                                                    ...grades
                                                        .asMap()
                                                        .entries
                                                        .map((entry) {
                                                      final index = entry.key;
                                                      final grade = entry.value;
                                                      return tableRowMethod(
                                                        grade,
                                                        boysControllers[index],
                                                        girlsControllers[index],
                                                        totalNotifiers[index],
                                                      );
                                                    }),

                                                    // Grand Total Row
                                                    TableRow(
                                                      children: [
                                                        const TableCell(
                                                          verticalAlignment:
                                                              TableCellVerticalAlignment
                                                                  .middle,
                                                          child: Center(
                                                            child: Text(
                                                              'Grand Total',
                                                              style: TextStyle(
                                                                  fontSize: 18,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold),
                                                            ),
                                                          ),
                                                        ),
                                                        TableCell(
                                                          verticalAlignment:
                                                              TableCellVerticalAlignment
                                                                  .middle,
                                                          child:
                                                              ValueListenableBuilder<
                                                                  int>(
                                                            valueListenable:
                                                                grandTotalBoys,
                                                            builder: (context,
                                                                total, child) {
                                                              return Center(
                                                                child: Text(
                                                                  total
                                                                      .toString(),
                                                                  style:
                                                                      const TextStyle(
                                                                    fontSize:
                                                                        18,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                  ),
                                                                ),
                                                              );
                                                            },
                                                          ),
                                                        ),
                                                        TableCell(
                                                          verticalAlignment:
                                                              TableCellVerticalAlignment
                                                                  .middle,
                                                          child:
                                                              ValueListenableBuilder<
                                                                  int>(
                                                            valueListenable:
                                                                grandTotalGirls,
                                                            builder: (context,
                                                                total, child) {
                                                              return Center(
                                                                child: Text(
                                                                  total
                                                                      .toString(),
                                                                  style:
                                                                      const TextStyle(
                                                                    fontSize:
                                                                        18,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                  ),
                                                                ),
                                                              );
                                                            },
                                                          ),
                                                        ),
                                                        TableCell(
                                                          verticalAlignment:
                                                              TableCellVerticalAlignment
                                                                  .middle,
                                                          child:
                                                              ValueListenableBuilder<
                                                                  int>(
                                                            valueListenable:
                                                                grandTotal,
                                                            builder: (context,
                                                                total, child) {
                                                              return Center(
                                                                child: Text(
                                                                  total
                                                                      .toString(),
                                                                  style:
                                                                      const TextStyle(
                                                                    fontSize:
                                                                        18,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                  ),
                                                                ),
                                                              );
                                                            },
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),

                                                // Error Text
                                                if (validateEnrolmentRecords)
                                                  Padding(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        vertical: 8.0),
                                                    child: ErrorText(
                                                      isVisible:
                                                          validateEnrolmentRecords,
                                                      message:
                                                          'At least one enrolment record is required',
                                                    ),
                                                  ),

                                                // Custom Sized Box
                                                CustomSizedBox(
                                                  value: 40,
                                                  side: 'height',
                                                ),

                                                // Divider
                                                const Divider(),
                                              ],
                                            ),
                                          CustomSizedBox(
                                              side: 'height', value: 10),
                                          LabelText(
                                            label:
                                                'Upload photo of Enrolment Register',
                                            astrick: true,
                                          ),
                                          CustomSizedBox(
                                            value: 20,
                                            side: 'height',
                                          ),
                                          Container(
                                            height: 60,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(10.0),
                                              border: Border.all(
                                                width: 2,
                                                color: schoolRecceController
                                                            .isImageUploadedEnrollement ==
                                                        false
                                                    ? AppColors.primary
                                                    : AppColors.error,
                                              ),
                                            ),
                                            child: ListTile(
                                              title: Text(
                                                'Click or Upload Image',
                                                style: TextStyle(
                                                  color: schoolRecceController
                                                              .isImageUploadedEnrollement ==
                                                          false
                                                      ? Colors.black
                                                      : AppColors.error,
                                                ),
                                              ),
                                              trailing: const Icon(Icons.camera_alt,
                                                  color:
                                                      AppColors.onBackground),
                                              onTap: () {
                                                showModalBottomSheet(
                                                  backgroundColor:
                                                      AppColors.primary,
                                                  context: context,
                                                  builder: (builder) =>
                                                      schoolRecceController
                                                          .bottomSheet(
                                                              context, 9),
                                                );
                                              },
                                            ),
                                          ),
                                          ErrorText(
                                            isVisible: schoolRecceController
                                                .validateEnrollement,
                                            message: 'Image Required',
                                          ),
                                          CustomSizedBox(
                                            value: 20,
                                            side: 'height',
                                          ),
                                          schoolRecceController
                                                  .multipleImage9.isNotEmpty
                                              ? Container(
                                                  width: responsive
                                                      .responsiveValue(
                                                    small: 600.0,
                                                    medium: 900.0,
                                                    large: 1400.0,
                                                  ),
                                                  height: responsive
                                                      .responsiveValue(
                                                    small: 170.0,
                                                    medium: 170.0,
                                                    large: 170.0,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    border: Border.all(
                                                        color: Colors.grey),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                  ),
                                                  child: ListView.builder(
                                                    scrollDirection:
                                                        Axis.horizontal,
                                                    itemCount:
                                                        schoolRecceController
                                                            .multipleImage9
                                                            .length,
                                                    itemBuilder:
                                                        (context, index) {
                                                      return SizedBox(
                                                        height: 200,
                                                        width: 200,
                                                        child: Column(
                                                          children: [
                                                            Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .all(8.0),
                                                              child:
                                                                  GestureDetector(
                                                                onTap: () {
                                                                  CustomImagePreview
                                                                      .showImagePreview(
                                                                    schoolRecceController
                                                                        .multipleImage9[
                                                                            index]
                                                                        .path,
                                                                    context,
                                                                  );
                                                                },
                                                                child:
                                                                    Image.file(
                                                                  File(schoolRecceController
                                                                      .multipleImage9[
                                                                          index]
                                                                      .path),
                                                                  width: 190,
                                                                  height: 120,
                                                                  fit: BoxFit
                                                                      .fill,
                                                                ),
                                                              ),
                                                            ),
                                                            GestureDetector(
                                                              onTap: () {
                                                                setState(() {
                                                                  schoolRecceController
                                                                      .multipleImage9
                                                                      .removeAt(
                                                                          index);
                                                                });
                                                              },
                                                              child: const Icon(
                                                                Icons.delete,
                                                                color:
                                                                    Colors.red,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                )
                                              : const SizedBox(),
                                          CustomSizedBox(
                                            value: 20,
                                            side: 'height',
                                          ),
                                          Row(
                                            children: [
                                              LabelText(
                                                label: 'Add Enrollment',
                                                astrick: true,
                                              ),
                                              CustomSizedBox(
                                                  value: 10, side: 'width'),
                                              IconButton(
                                                icon: const Icon(Icons.add),
                                                onPressed: () {
                                                  _showBottomSheet();
                                                },
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 16),
                                          // Container to show the totals

                                          const SizedBox(height: 16),
                                          // ListTile to show filled academic years
                                          Column(
                                            children: submittedData.isNotEmpty
                                                ? submittedData.keys
                                                    .map((year) {
                                                    return Padding(
                                                      padding: const EdgeInsets.only(
                                                          bottom: 12.0),
                                                      child: ListTile(
                                                        shape:
                                                            RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      8.0),
                                                        ),
                                                        tileColor: Colors.white,
                                                        contentPadding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                    horizontal:
                                                                        16.0),
                                                        leading: const Icon(
                                                          Icons.school,
                                                          color: Colors.green,
                                                        ),
                                                        title: Text(
                                                          '$year: Boys: ${submittedData[year]!['boys']}, Girls: ${submittedData[year]!['girls']}, Total: ${submittedData[year]!['total']}',
                                                          style: const TextStyle(
                                                            fontSize:
                                                                20.0, // Default font size (no MediaQuery)
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                        trailing: IconButton(
                                                          icon: const Icon(
                                                              Icons.delete,
                                                              color:
                                                                  Colors.red),
                                                          onPressed: () {
                                                            _deleteAcademicYear(
                                                                year);
                                                          },
                                                        ),
                                                      ),
                                                    );
                                                  }).toList()
                                                : [
                                                    const Padding(
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                              vertical: 16.0),
                                                      child: Text(
                                                        'No enrollment data available.',
                                                        style: TextStyle(
                                                          color: Colors.red,
                                                          fontSize:
                                                              16.0, // Default font size for the "No data" message
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                          ),

                                          CustomSizedBox(
                                            value: 40,
                                            side: 'height',
                                          ),
                                          LabelText(
                                            label:
                                                'Photo of the room shortlisted for DL installation',
                                            astrick: true,
                                          ),
                                          CustomSizedBox(
                                            value: 20,
                                            side: 'height',
                                          ),
                                          Container(
                                            height: 60,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(10.0),
                                              border: Border.all(
                                                width: 2,
                                                color: schoolRecceController
                                                            .isImageUploadedDlInstallation ==
                                                        false
                                                    ? AppColors.primary
                                                    : AppColors.error,
                                              ),
                                            ),
                                            child: ListTile(
                                              title: Text(
                                                'Click or Upload Image',
                                                style: TextStyle(
                                                  color: schoolRecceController
                                                              .isImageUploadedDlInstallation ==
                                                          false
                                                      ? Colors.black
                                                      : AppColors.error,
                                                ),
                                              ),
                                              trailing: const Icon(Icons.camera_alt,
                                                  color:
                                                      AppColors.onBackground),
                                              onTap: () {
                                                showModalBottomSheet(
                                                  backgroundColor:
                                                      AppColors.primary,
                                                  context: context,
                                                  builder: (builder) =>
                                                      schoolRecceController
                                                          .bottomSheet(
                                                              context, 10),
                                                );
                                              },
                                            ),
                                          ),
                                          ErrorText(
                                            isVisible: schoolRecceController
                                                .validateDlInstallation,
                                            message: 'Image Required',
                                          ),
                                          CustomSizedBox(
                                            value: 20,
                                            side: 'height',
                                          ),
                                          schoolRecceController
                                                  .multipleImage10.isNotEmpty
                                              ? Container(
                                                  width: responsive
                                                      .responsiveValue(
                                                    small: 600.0,
                                                    medium: 900.0,
                                                    large: 1400.0,
                                                  ),
                                                  height: responsive
                                                      .responsiveValue(
                                                    small: 170.0,
                                                    medium: 170.0,
                                                    large: 170.0,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    border: Border.all(
                                                        color: Colors.grey),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                  ),
                                                  child: ListView.builder(
                                                    scrollDirection:
                                                        Axis.horizontal,
                                                    itemCount:
                                                        schoolRecceController
                                                            .multipleImage10
                                                            .length,
                                                    itemBuilder:
                                                        (context, index) {
                                                      return SizedBox(
                                                        height: 200,
                                                        width: 200,
                                                        child: Column(
                                                          children: [
                                                            Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .all(8.0),
                                                              child:
                                                                  GestureDetector(
                                                                onTap: () {
                                                                  CustomImagePreview
                                                                      .showImagePreview(
                                                                    schoolRecceController
                                                                        .multipleImage10[
                                                                            index]
                                                                        .path,
                                                                    context,
                                                                  );
                                                                },
                                                                child:
                                                                    Image.file(
                                                                  File(schoolRecceController
                                                                      .multipleImage10[
                                                                          index]
                                                                      .path),
                                                                  width: 190,
                                                                  height: 120,
                                                                  fit: BoxFit
                                                                      .fill,
                                                                ),
                                                              ),
                                                            ),
                                                            GestureDetector(
                                                              onTap: () {
                                                                setState(() {
                                                                  schoolRecceController
                                                                      .multipleImage10
                                                                      .removeAt(
                                                                          index);
                                                                });
                                                              },
                                                              child: const Icon(
                                                                Icons.delete,
                                                                color:
                                                                    Colors.red,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                )
                                              : const SizedBox(),
                                          CustomSizedBox(
                                            value: 20,
                                            side: 'height',
                                          ),
                                          LabelText(
                                            label:
                                                'Photo of the room shortlisted for Library setup',
                                            astrick: true,
                                          ),
                                          CustomSizedBox(
                                            value: 20,
                                            side: 'height',
                                          ),
                                          Container(
                                            height: 60,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(10.0),
                                              border: Border.all(
                                                width: 2,
                                                color: schoolRecceController
                                                            .isImageUploadedLibrarySetup ==
                                                        false
                                                    ? AppColors.primary
                                                    : AppColors.error,
                                              ),
                                            ),
                                            child: ListTile(
                                              title: Text(
                                                'Click or Upload Image',
                                                style: TextStyle(
                                                  color: schoolRecceController
                                                              .isImageUploadedLibrarySetup ==
                                                          false
                                                      ? Colors.black
                                                      : AppColors.error,
                                                ),
                                              ),
                                              trailing: const Icon(Icons.camera_alt,
                                                  color:
                                                      AppColors.onBackground),
                                              onTap: () {
                                                showModalBottomSheet(
                                                  backgroundColor:
                                                      AppColors.primary,
                                                  context: context,
                                                  builder: (builder) =>
                                                      schoolRecceController
                                                          .bottomSheet(
                                                              context, 11),
                                                );
                                              },
                                            ),
                                          ),
                                          ErrorText(
                                            isVisible: schoolRecceController
                                                .validateLibrarySetup,
                                            message: 'Image Required',
                                          ),
                                          CustomSizedBox(
                                            value: 20,
                                            side: 'height',
                                          ),
                                          schoolRecceController
                                                  .multipleImage11.isNotEmpty
                                              ? Container(
                                                  width: responsive
                                                      .responsiveValue(
                                                    small: 600.0,
                                                    medium: 900.0,
                                                    large: 1400.0,
                                                  ),
                                                  height: responsive
                                                      .responsiveValue(
                                                    small: 170.0,
                                                    medium: 170.0,
                                                    large: 170.0,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    border: Border.all(
                                                        color: Colors.grey),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                  ),
                                                  child: ListView.builder(
                                                    scrollDirection:
                                                        Axis.horizontal,
                                                    itemCount:
                                                        schoolRecceController
                                                            .multipleImage11
                                                            .length,
                                                    itemBuilder:
                                                        (context, index) {
                                                      return SizedBox(
                                                        height: 200,
                                                        width: 200,
                                                        child: Column(
                                                          children: [
                                                            Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .all(8.0),
                                                              child:
                                                                  GestureDetector(
                                                                onTap: () {
                                                                  CustomImagePreview
                                                                      .showImagePreview(
                                                                    schoolRecceController
                                                                        .multipleImage11[
                                                                            index]
                                                                        .path,
                                                                    context,
                                                                  );
                                                                },
                                                                child:
                                                                    Image.file(
                                                                  File(schoolRecceController
                                                                      .multipleImage11[
                                                                          index]
                                                                      .path),
                                                                  width: 190,
                                                                  height: 120,
                                                                  fit: BoxFit
                                                                      .fill,
                                                                ),
                                                              ),
                                                            ),
                                                            GestureDetector(
                                                              onTap: () {
                                                                setState(() {
                                                                  schoolRecceController
                                                                      .multipleImage11
                                                                      .removeAt(
                                                                          index);
                                                                });
                                                              },
                                                              child: const Icon(
                                                                Icons.delete,
                                                                color:
                                                                    Colors.red,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                )
                                              : const SizedBox(),
                                          CustomSizedBox(
                                            value: 20,
                                            side: 'height',
                                          ),
                                          Row(
                                            children: [
                                              CustomButton(
                                                  title: 'Back',
                                                  onPressedButton: () {
                                                    setState(() {
                                                      schoolRecceController
                                                              .showSchoolInfra =
                                                          true;
                                                      schoolRecceController
                                                              .showSchoolStrngth =
                                                          false;
                                                    });
                                                  }),
                                              const Spacer(),
                                              CustomButton(
                                                title: 'Next',
                                                onPressedButton: () {
                                                  // Check if submittedData is empty
                                                  if (submittedData.isEmpty) {
                                                    // Show snackbar error if there is no enrollment data
                                                    customSnackbar(
                                                      'Error',
                                                      'No enrollment data available.',
                                                      AppColors.error,
                                                      Colors.white,
                                                      Icons.error,
                                                    );
                                                    return; // Exit the function early
                                                  }

                                                  validateEnrolmentRecords =
                                                      jsonData.isEmpty;

                                                  schoolRecceController
                                                          .validateEnrollement =
                                                      schoolRecceController
                                                          .multipleImage9
                                                          .isEmpty;
                                                  schoolRecceController
                                                          .validateDlInstallation =
                                                      schoolRecceController
                                                          .multipleImage10
                                                          .isEmpty;
                                                  schoolRecceController
                                                          .validateLibrarySetup =
                                                      schoolRecceController
                                                          .multipleImage11
                                                          .isEmpty;

                                                  if (_formKey.currentState!
                                                          .validate() &&
                                                      !schoolRecceController
                                                          .validateDlInstallation &&
                                                      !schoolRecceController
                                                          .validateLibrarySetup &&
                                                      !schoolRecceController
                                                          .validateEnrollement &&
                                                      !validateEnrolmentRecords) {
                                                    // Check if staff data is empty
                                                    if (validateStaffData) {
                                                      // Show snackbar error for empty staff data
                                                      customSnackbar(
                                                        'Error',
                                                        'Enrollment data cannot be empty.',
                                                        AppColors.error,
                                                        Colors.white,
                                                        Icons.error,
                                                      );
                                                    } else {
                                                      // If all validations are passed, update the state
                                                      setState(() {
                                                        schoolRecceController
                                                                .showSchoolStrngth =
                                                            false;
                                                        schoolRecceController
                                                                .showOtherInfo =
                                                            true;
                                                        WidgetsBinding.instance
                                                            .addPostFrameCallback(
                                                                (_) {
                                                          _scrollController
                                                              .animateTo(
                                                            0.0, // Scroll to the top
                                                            duration: const Duration(
                                                                milliseconds:
                                                                    300),
                                                            curve: Curves
                                                                .easeInOut,
                                                          );
                                                        });
                                                      });
                                                    }
                                                  }
                                                },
                                              ),
                                            ],
                                          ),
                                          CustomSizedBox(
                                            value: 20,
                                            side: 'height',
                                          ),
                                        ], // End of showSchoolStrngth

                                        //Start of other Info
                                        if (schoolRecceController
                                            .showOtherInfo) ...[
                                          LabelText(
                                            label: 'Other Information',
                                          ),
                                          CustomSizedBox(
                                            value: 20,
                                            side: 'height',
                                          ),
                                          LabelText(
                                            label: 'How remote in the school?',
                                            astrick: true,
                                          ),

                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Radio<String>(
                                                    value: 'Not Remote',
                                                    groupValue:
                                                        schoolRecceController
                                                            .getSelectedValue(
                                                                'remote'),
                                                    onChanged: (value) {
                                                      schoolRecceController
                                                          .setRadioValue(
                                                              'remote', value);
                                                    },
                                                  ),
                                                  const Text('Not Remote'),
                                                ],
                                              ),
                                              Row(
                                                children: [
                                                  Radio<String>(
                                                    value: 'Somewhat Remote',
                                                    groupValue:
                                                        schoolRecceController
                                                            .getSelectedValue(
                                                                'remote'),
                                                    onChanged: (value) {
                                                      schoolRecceController
                                                          .setRadioValue(
                                                              'remote', value);
                                                    },
                                                  ),
                                                  const Text('Somewhat Remote'),
                                                ],
                                              ),
                                              Row(
                                                children: [
                                                  Radio<String>(
                                                    value: 'Remote',
                                                    groupValue:
                                                        schoolRecceController
                                                            .getSelectedValue(
                                                                'remote'),
                                                    onChanged: (value) {
                                                      schoolRecceController
                                                          .setRadioValue(
                                                              'remote', value);
                                                    },
                                                  ),
                                                  const Text('Remote'),
                                                ],
                                              ),
                                              Row(
                                                children: [
                                                  Radio<String>(
                                                    value: 'Very Remote',
                                                    groupValue:
                                                        schoolRecceController
                                                            .getSelectedValue(
                                                                'remote'),
                                                    onChanged: (value) {
                                                      schoolRecceController
                                                          .setRadioValue(
                                                              'remote', value);
                                                    },
                                                  ),
                                                  const Text('Very Remote'),
                                                ],
                                              ),
                                              const SizedBox(
                                                  width:
                                                      16), // Adjust spacing between rows
                                              Row(
                                                children: [
                                                  Radio<String>(
                                                    value: 'Extremely Remote',
                                                    groupValue:
                                                        schoolRecceController
                                                            .getSelectedValue(
                                                                'remote'),
                                                    onChanged: (value) {
                                                      schoolRecceController
                                                          .setRadioValue(
                                                              'remote', value);
                                                    },
                                                  ),
                                                  const Text('Extremely Remote'),
                                                ],
                                              ),
                                              if (schoolRecceController
                                                  .getRadioFieldError('remote'))
                                                const Padding(
                                                  padding: EdgeInsets.only(
                                                      left: 16.0),
                                                  child: Align(
                                                    alignment:
                                                        Alignment.centerLeft,
                                                    child: Text(
                                                      'Please select an option',
                                                      style: TextStyle(
                                                          color: Colors.red),
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),

                                          CustomSizedBox(
                                            value: 20,
                                            side: 'height',
                                          ),
                                          LabelText(
                                            label:
                                                'Is School on/next to a motorable road?',
                                            astrick: true,
                                          ),

                                          Padding(
                                            padding: EdgeInsets.only(
                                                right: screenWidth * 0.1),
                                            child: Row(
                                              children: [
                                                Radio(
                                                  value: 'Yes',
                                                  groupValue:
                                                      schoolRecceController
                                                          .getSelectedValue(
                                                              'motorable'),
                                                  onChanged: (value) {
                                                    schoolRecceController
                                                        .setRadioValue(
                                                            'motorable', value);
                                                  },
                                                ),
                                                const Text('Yes'),
                                              ],
                                            ),
                                          ),
                                          CustomSizedBox(
                                            value: 150,
                                            side: 'width',
                                          ),
                                          // make it that user can also edit the tourId and school
                                          Padding(
                                            padding: EdgeInsets.only(
                                                right: screenWidth * 0.1),
                                            child: Row(
                                              children: [
                                                Radio(
                                                  value: 'No',
                                                  groupValue:
                                                      schoolRecceController
                                                          .getSelectedValue(
                                                              'motorable'),
                                                  onChanged: (value) {
                                                    schoolRecceController
                                                        .setRadioValue(
                                                            'motorable', value);
                                                  },
                                                ),
                                                const Text('No'),
                                              ],
                                            ),
                                          ),
                                          if (schoolRecceController
                                              .getRadioFieldError('motorable'))
                                            const Padding(
                                              padding:
                                                  EdgeInsets.only(left: 16.0),
                                              child: Align(
                                                alignment: Alignment.centerLeft,
                                                child: Text(
                                                  'Please select an option',
                                                  style: TextStyle(
                                                      color: Colors.red),
                                                ),
                                              ),
                                            ),
                                          CustomSizedBox(
                                            value: 20,
                                            side: 'height',
                                          ),
                                          LabelText(
                                            label: 'Language taught in School',
                                            astrick: true,
                                          ),
                                          CustomSizedBox(
                                            value: 20,
                                            side: 'height',
                                          ),

                                          CheckboxListTile(
                                            value: schoolRecceController
                                                .checkboxValue23,
                                            onChanged: (bool? value) {
                                              setState(() {
                                                schoolRecceController
                                                    .checkboxValue23 = value!;
                                              });
                                            },
                                            title: const Text('Hindi'),
                                            activeColor: Colors.green,
                                          ),
                                          CheckboxListTile(
                                            value: schoolRecceController
                                                .checkboxValue24,
                                            onChanged: (bool? value) {
                                              setState(() {
                                                schoolRecceController
                                                    .checkboxValue24 = value!;
                                              });
                                            },
                                            title: const Text('English'),
                                            activeColor: Colors.green,
                                          ),
                                          CheckboxListTile(
                                            value: schoolRecceController
                                                .checkboxValue25,
                                            onChanged: (bool? value) {
                                              setState(() {
                                                schoolRecceController
                                                    .checkboxValue25 = value!;
                                                if (!schoolRecceController
                                                    .checkboxValue25) {
                                                  schoolRecceController
                                                      .specifyOtherController
                                                      .clear();
                                                }
                                              });
                                            },
                                            title: const Text('Other'),
                                            activeColor: Colors.green,
                                          ),

                                          if (schoolRecceController
                                              .checkBoxError4)
                                            const Padding(
                                              padding:
                                                  EdgeInsets.only(left: 16.0),
                                              child: Align(
                                                alignment: Alignment.centerLeft,
                                                child: Text(
                                                  'Please select at least one topic',
                                                  style: TextStyle(
                                                      color: Colors.red),
                                                ),
                                              ),
                                            ),
                                          CustomSizedBox(
                                            value: 20,
                                            side: 'height',
                                          ),
                                          if (schoolRecceController
                                              .checkboxValue25) ...[
                                            LabelText(
                                              label: 'Please Specify Other',
                                              astrick: true,
                                            ),
                                            CustomSizedBox(
                                              value: 20,
                                              side: 'height',
                                            ),
                                            CustomTextFormField(
                                              textController:
                                                  schoolRecceController
                                                      .specifyOtherController,
                                              labelText: 'Please Specify',
                                              maxlines: 3,
                                              validator: (value) {
                                                if (value!.isEmpty) {
                                                  return 'Please fill this field';
                                                }

                                                if (value.length < 25) {
                                                  return 'Must be at least 25 characters long';
                                                }
                                                return null;
                                              },
                                              showCharacterCount: true,
                                            ),
                                            CustomSizedBox(
                                              value: 20,
                                              side: 'height',
                                            ),
                                          ],
                                          LabelText(
                                            label:
                                                'Are there any other NGO currently supporting the school?',
                                            astrick: true,
                                          ),
                                          Padding(
                                            padding: EdgeInsets.only(
                                                right: screenWidth * 0.1),
                                            child: Row(
                                              children: [
                                                Radio(
                                                  value: 'Yes',
                                                  groupValue:
                                                      schoolRecceController
                                                          .getSelectedValue(
                                                              'supportingNgo'),
                                                  onChanged: (value) {
                                                    schoolRecceController
                                                        .setRadioValue(
                                                            'supportingNgo',
                                                            value);
                                                  },
                                                ),
                                                const Text('Yes'),
                                              ],
                                            ),
                                          ),
                                          CustomSizedBox(
                                            value: 150,
                                            side: 'width',
                                          ),
                                          // make it that user can also edit the tourId and school
                                          Padding(
                                            padding: EdgeInsets.only(
                                                right: screenWidth * 0.1),
                                            child: Row(
                                              children: [
                                                Radio(
                                                  value: 'No',
                                                  groupValue:
                                                      schoolRecceController
                                                          .getSelectedValue(
                                                              'supportingNgo'),
                                                  onChanged: (value) {
                                                    schoolRecceController
                                                        .setRadioValue(
                                                            'supportingNgo',
                                                            value);
                                                    if (value == 'No') {
                                                      schoolRecceController
                                                          .supportingNgoController
                                                          .clear();
                                                    }
                                                  },
                                                ),
                                                const Text('No'),
                                              ],
                                            ),
                                          ),
                                          if (schoolRecceController
                                              .getRadioFieldError(
                                                  'supportingNgo'))
                                            const Padding(
                                              padding:
                                                  EdgeInsets.only(left: 16.0),
                                              child: Align(
                                                alignment: Alignment.centerLeft,
                                                child: Text(
                                                  'Please select an option',
                                                  style: TextStyle(
                                                      color: Colors.red),
                                                ),
                                              ),
                                            ),
                                          CustomSizedBox(
                                            value: 20,
                                            side: 'height',
                                          ),

                                          if (schoolRecceController
                                                  .getSelectedValue(
                                                      'supportingNgo') ==
                                              'Yes') ...[
                                            LabelText(
                                              label: 'How are they Supporting?',
                                              astrick: true,
                                            ),
                                            CustomSizedBox(
                                              value: 20,
                                              side: 'height',
                                            ),
                                            CustomTextFormField(
                                              textController:
                                                  schoolRecceController
                                                      .supportingNgoController,
                                              labelText: 'Write here...',
                                              maxlines: 3,
                                              validator: (value) {
                                                if (value!.isEmpty) {
                                                  return 'Please fill this field';
                                                }

                                                if (value.length < 25) {
                                                  return 'Must be at least 25 characters long';
                                                }
                                                return null;
                                              },
                                              showCharacterCount: true,
                                            ),
                                            CustomSizedBox(
                                              value: 20,
                                              side: 'height',
                                            ),
                                          ],

                                          LabelText(
                                            label:
                                                'Any key points/interesting observation that you would like to highlight',
                                          ),
                                          CustomSizedBox(
                                            value: 20,
                                            side: 'height',
                                          ),

                                          CustomTextFormField(
                                            textController:
                                                schoolRecceController
                                                    .keyPointsController,
                                            labelText: 'Write here...',
                                            maxlines: 3,
                                            showCharacterCount: true,
                                          ),
                                          CustomSizedBox(
                                            value: 20,
                                            side: 'height',
                                          ),
                                          Row(
                                            children: [
                                              CustomButton(
                                                  title: 'Back',
                                                  onPressedButton: () {
                                                    setState(() {
                                                      schoolRecceController
                                                              .showSchoolStrngth =
                                                          true;
                                                      schoolRecceController
                                                              .showOtherInfo =
                                                          false;
                                                    });
                                                  }),
                                              const Spacer(),
                                              CustomButton(
                                                title: 'Submit',
                                                onPressedButton: () async {
                                                  bool isCheckboxSelected =
                                                      schoolRecceController
                                                              .checkboxValue23 ||
                                                          schoolRecceController
                                                              .checkboxValue24 ||
                                                          schoolRecceController
                                                              .checkboxValue25;

                                                  if (!isCheckboxSelected) {
                                                    setState(() {
                                                      schoolRecceController
                                                              .checkBoxError4 =
                                                          true;
                                                    });
                                                  } else {
                                                    setState(() {
                                                      schoolRecceController
                                                              .checkBoxError4 =
                                                          false;
                                                    });
                                                  }

                                                  final isRadioValid50 =
                                                      schoolRecceController
                                                          .validateRadioSelection(
                                                              'remote');

                                                  final isRadioValid51 =
                                                      schoolRecceController
                                                          .validateRadioSelection(
                                                              'motorable');

                                                  final isRadioValid52 =
                                                      schoolRecceController
                                                          .validateRadioSelection(
                                                              'supportingNgo');

                                                  String getSelectedLanguage() {
                                                    List<String>
                                                        selectedLanguage = [];

                                                    if (schoolRecceController
                                                        .checkboxValue23) {
                                                      selectedLanguage
                                                          .add('Hindi');
                                                    }
                                                    if (schoolRecceController
                                                        .checkboxValue24) {
                                                      selectedLanguage
                                                          .add('English');
                                                    }
                                                    if (schoolRecceController
                                                        .checkboxValue25) {
                                                      selectedLanguage
                                                          .add('Other');
                                                    }

                                                    return selectedLanguage.join(
                                                        ','); // Return a comma-separated string
                                                  }

                                                  String playGroundSpace =
                                                      '${schoolRecceController.measurnment1Controller.text} X ${schoolRecceController.measurnment2Controller.text} feet';
                                                  if (_formKey.currentState!
                                                          .validate() &&
                                                      !schoolRecceController
                                                          .checkBoxError4 &&
                                                      isRadioValid50 &&
                                                      isRadioValid51 &&
                                                      isRadioValid52) {
                                                    DateTime now =
                                                        DateTime.now();
                                                    String formattedDate =
                                                        DateFormat('yyyy-MM-dd')
                                                            .format(now);

                                                    String networkConnectivity =
                                                        [
                                                      schoolRecceController
                                                              .checkboxValue16
                                                          ? '2G'
                                                          : null,
                                                      schoolRecceController
                                                              .checkboxValue17
                                                          ? '3G'
                                                          : null,
                                                      schoolRecceController
                                                              .checkboxValue18
                                                          ? '4G'
                                                          : null,
                                                      schoolRecceController
                                                              .checkboxValue19
                                                          ? '5G'
                                                          : null,
                                                    ]
                                                            .where((value) =>
                                                                value != null)
                                                            .join(', ');

                                                    List<String>
                                                        selectedAcademicYears =
                                                        [];

                                                    if (submittedData.containsKey(
                                                        'Previous academic year')) {
                                                      selectedAcademicYears.add(
                                                          'Previous academic year');
                                                    }
                                                    if (submittedData.containsKey(
                                                        'Two years previously')) {
                                                      selectedAcademicYears.add(
                                                          'Two years previously');
                                                    }
                                                    if (submittedData.containsKey(
                                                        'Three years previously')) {
                                                      selectedAcademicYears.add(
                                                          'Three years previously');
                                                    }

                                                    // Join the selected academic years into a single string separated by commas
                                                    String academicYearsString =
                                                        '[${selectedAcademicYears.join(',')}]';

                                                    List<File> boardImgFiles =
                                                        [];
                                                    for (var imagePath
                                                        in schoolRecceController
                                                            .imagePaths) {
                                                      boardImgFiles.add(File(
                                                          imagePath)); // Convert image path to File
                                                    }

                                                    List<File>
                                                        buildingImgFiles = [];
                                                    for (var imagePath2
                                                        in schoolRecceController
                                                            .imagePaths2) {
                                                      buildingImgFiles.add(File(
                                                          imagePath2)); // Convert image path to File
                                                    }

                                                    List<File>
                                                        registerImgFiles = [];
                                                    for (var imagePath3
                                                        in schoolRecceController
                                                            .imagePaths3) {
                                                      registerImgFiles.add(File(
                                                          imagePath3)); // Convert image path to File
                                                    }

                                                    List<File> smrtImgFiles =
                                                        [];
                                                    for (var imagePath4
                                                        in schoolRecceController
                                                            .imagePaths4) {
                                                      smrtImgFiles.add(File(
                                                          imagePath4)); // Convert image path to File
                                                    }

                                                    List<File>
                                                        projectorImgFiles = [];
                                                    for (var imagePath5
                                                        in schoolRecceController
                                                            .imagePaths5) {
                                                      projectorImgFiles.add(File(
                                                          imagePath5)); // Convert image path to File
                                                    }

                                                    List<File>
                                                        computerImgFiles = [];
                                                    for (var imagePath6
                                                        in schoolRecceController
                                                            .imagePaths6) {
                                                      computerImgFiles.add(File(
                                                          imagePath6)); // Convert image path to File
                                                    }

                                                    List<File> libImgFiles = [];
                                                    for (var imagePath7
                                                        in schoolRecceController
                                                            .imagePaths7) {
                                                      libImgFiles.add(File(
                                                          imagePath7)); // Convert image path to File
                                                    }

                                                    List<File> spaceImgFiles =
                                                        [];
                                                    for (var imagePath8
                                                        in schoolRecceController
                                                            .imagePaths8) {
                                                      spaceImgFiles.add(File(
                                                          imagePath8)); // Convert image path to File
                                                    }

                                                    List<File>
                                                        enrollmentImgFiles = [];
                                                    for (var imagePath9
                                                        in schoolRecceController
                                                            .imagePaths9) {
                                                      enrollmentImgFiles.add(File(
                                                          imagePath9)); // Convert image path to File
                                                    }

                                                    List<File> digiLabImgFiles =
                                                        [];
                                                    for (var imagePath10
                                                        in schoolRecceController
                                                            .imagePaths10) {
                                                      digiLabImgFiles.add(File(
                                                          imagePath10)); // Convert image path to File
                                                    }

                                                    List<File> libRoomImgFiles =
                                                        [];
                                                    for (var imagePath11
                                                        in schoolRecceController
                                                            .imagePaths11) {
                                                      libRoomImgFiles.add(File(
                                                          imagePath11)); // Convert image path to File
                                                    }

                                                    String
                                                        enrollmentReportJson =
                                                        jsonEncode(
                                                            jsonData); // Ensure the JSON data is properly encoded
                                                    String
                                                        gradeReportYear1Json =
                                                        jsonEncode(
                                                            staffJsonData);
                                                    String
                                                        gradeReportYear2Json =
                                                        jsonEncode(
                                                            readingJson2);
                                                    String
                                                        gradeReportYear3Json =
                                                        jsonEncode(
                                                            readingJson3);

                                                    // Concatenate reports based on submission
                                                    if (submittedData.containsKey(
                                                        'Previous academic year')) {
                                                      // Assuming submittedData['Previous academic year'] contains the report data
                                                      gradeReportYear1Json =
                                                          jsonEncode({
                                                        'previous': jsonDecode(
                                                            gradeReportYear1Json),
                                                      });
                                                    }

                                                    if (submittedData.containsKey(
                                                        'Two years previously')) {
                                                      // Assuming submittedData['Two years previously'] contains the report data
                                                      gradeReportYear2Json =
                                                          jsonEncode({
                                                        'twoYearsPrevious':
                                                            jsonDecode(
                                                                gradeReportYear2Json),
                                                      });
                                                    }

                                                    if (submittedData.containsKey(
                                                        'Three years previously')) {
                                                      // Assuming submittedData['Three years previously'] contains the report data
                                                      gradeReportYear3Json =
                                                          jsonEncode({
                                                        'threeYearsPrevious':
                                                            jsonDecode(
                                                                gradeReportYear3Json),
                                                      });
                                                    }

                                                    String boardImgFilesPaths =
                                                        boardImgFiles
                                                            .map((file) =>
                                                                file.path)
                                                            .join(',');
                                                    String
                                                        buildingImgFilesPaths =
                                                        buildingImgFiles
                                                            .map((file) =>
                                                                file.path)
                                                            .join(',');
                                                    String
                                                        registerImgFilesPaths =
                                                        registerImgFiles
                                                            .map((file) =>
                                                                file.path)
                                                            .join(',');
                                                    String smrtImgFilesPaths =
                                                        smrtImgFiles
                                                            .map((file) =>
                                                                file.path)
                                                            .join(',');
                                                    String
                                                        projectorImgFilesPaths =
                                                        projectorImgFiles
                                                            .map((file) =>
                                                                file.path)
                                                            .join(',');
                                                    String
                                                        computerImgFilesPaths =
                                                        computerImgFiles
                                                            .map((file) =>
                                                                file.path)
                                                            .join(',');
                                                    String libImgFilesPaths =
                                                        libImgFiles
                                                            .map((file) =>
                                                                file.path)
                                                            .join(',');
                                                    String spaceImgFilesPaths =
                                                        spaceImgFiles
                                                            .map((file) =>
                                                                file.path)
                                                            .join(',');
                                                    String
                                                        enrollmentImgFilesPaths =
                                                        enrollmentImgFiles
                                                            .map((file) =>
                                                                file.path)
                                                            .join(',');
                                                    String
                                                        digiLabImgFilesPaths =
                                                        digiLabImgFiles
                                                            .map((file) =>
                                                                file.path)
                                                            .join(',');
                                                    String
                                                        libRoomImgFilesPaths =
                                                        libRoomImgFiles
                                                            .map((file) =>
                                                                file.path)
                                                            .join(',');
                                                    String generateUniqueId(
                                                        int length) {
                                                      const chars =
                                                          'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
                                                      Random rnd = Random();
                                                      return String.fromCharCodes(
                                                          Iterable.generate(
                                                              length,
                                                              (_) => chars
                                                                  .codeUnitAt(rnd
                                                                      .nextInt(
                                                                          chars
                                                                              .length))));
                                                    }

                                                    String selectedGrades =
                                                        '[${grades.join(',')}]'; // Adds square brackets around the list

                                                    final selectController =
                                                        Get.put(
                                                            SelectController());
                                                    String? lockedTourId =
                                                        selectController
                                                            .lockedTourId;

                                                    // Use lockedTourId if it is available, otherwise use the selected tour ID from schoolEnrolmentController
                                                    String tourIdToInsert =
                                                        lockedTourId ??
                                                            schoolRecceController
                                                                .tourValue ??
                                                            '';
                                                    String uniqueId =
                                                        generateUniqueId(6);
                                                    // Capture selected grades as a comma-separated string

                                                    String selectedLanguage =
                                                        getSelectedLanguage();
                                                    // Create the enrolment collection object
                                                    SchoolRecceModal
                                                        schoolRecceModal =
                                                        SchoolRecceModal(
                                                      tourId: tourIdToInsert,
                                                      school:
                                                          schoolRecceController
                                                                  .schoolValue ??
                                                              '',
                                                      udiseValue: schoolRecceController
                                                              .getSelectedValue(
                                                                  'udiCode') ??
                                                          '',
                                                      udise_correct:
                                                          schoolRecceController
                                                              .correctUdiseCodeController
                                                              .text,
                                                      boardImg:
                                                          boardImgFilesPaths,
                                                      buildingImg:
                                                          buildingImgFilesPaths,
                                                      gradeTaught:
                                                          selectedGrades,
                                                      instituteHead:
                                                          schoolRecceController
                                                              .nameOfHoiController
                                                              .text,
                                                      headDesignation:
                                                          schoolRecceController
                                                              .selectedDesignation,
                                                      headPhone:
                                                          schoolRecceController
                                                              .hoiPhoneNumberController
                                                              .text,
                                                      headEmail:
                                                          schoolRecceController
                                                              .hoiEmailController
                                                              .text,
                                                      appointedYear:
                                                          schoolRecceController
                                                              .selectedYear,
                                                      noTeachingStaff:
                                                          schoolRecceController
                                                              .totalTeachingStaffController
                                                              .text,
                                                      noNonTeachingStaff:
                                                          schoolRecceController
                                                              .totalNonTeachingStaffController
                                                              .text,
                                                      totalStaff:
                                                          schoolRecceController
                                                              .totalStaffController
                                                              .text,
                                                      registerImg:
                                                          registerImgFilesPaths,
                                                      smcHeadName:
                                                          schoolRecceController
                                                              .nameOfSmcController
                                                              .text,
                                                      smcPhone:
                                                          schoolRecceController
                                                              .smcPhoneNumberController
                                                              .text,
                                                      smcQual: schoolRecceController
                                                          .selectedQualification,
                                                      qualOther:
                                                          schoolRecceController
                                                              .QualSpecifyController
                                                              .text,
                                                      totalSmc:
                                                          schoolRecceController
                                                              .totalnoOfSmcMemController
                                                              .text,
                                                      meetingDuration:
                                                          schoolRecceController
                                                              .selectedMeetings,
                                                      meetingOther:
                                                          schoolRecceController
                                                              .freSpecifyController
                                                              .text,
                                                      smcDesc: schoolRecceController
                                                          .descriptionController
                                                          .text,
                                                      noUsableClass:
                                                          schoolRecceController
                                                              .noClassroomsController
                                                              .text,
                                                      electricityAvailability:
                                                          schoolRecceController
                                                                  .getSelectedValue(
                                                                      'electricity') ??
                                                              '',
                                                      networkAvailability:
                                                          networkConnectivity,
                                                      digitalLearning:
                                                          schoolRecceController
                                                                  .getSelectedValue(
                                                                      'learningFacility') ??
                                                              '',
                                                      smartClassImg:
                                                          smrtImgFilesPaths,
                                                      projectorImg:
                                                          projectorImgFilesPaths,
                                                      computerImg:
                                                          computerImgFilesPaths,
                                                      libraryExisting:
                                                          schoolRecceController
                                                                  .getSelectedValue(
                                                                      'existingLibrary') ??
                                                              '',
                                                      libImg: libImgFilesPaths,
                                                      playGroundSpace:
                                                          playGroundSpace,
                                                      spaceImg:
                                                          spaceImgFilesPaths,
                                                      enrollmentReport:
                                                          enrollmentReportJson,
                                                      enrollmentImg:
                                                          enrollmentImgFilesPaths,
                                                      academicYear:
                                                          academicYearsString,
                                                      gradeReportYear1:
                                                          gradeReportYear1Json,
                                                      gradeReportYear2:
                                                          gradeReportYear2Json,
                                                      gradeReportYear3:
                                                          gradeReportYear3Json,
                                                      DigiLabRoomImg:
                                                          digiLabImgFilesPaths,
                                                      libRoomImg:
                                                          libRoomImgFilesPaths,
                                                      remoteInfo:
                                                          schoolRecceController
                                                                  .getSelectedValue(
                                                                      'remote') ??
                                                              '',
                                                      motorableRoad:
                                                          schoolRecceController
                                                                  .getSelectedValue(
                                                                      'motorable') ??
                                                              '',
                                                      languageSchool:
                                                          selectedLanguage,
                                                      languageOther:
                                                          schoolRecceController
                                                              .specifyOtherController
                                                              .text,
                                                      supportingNgo:
                                                          schoolRecceController
                                                                  .getSelectedValue(
                                                                      'supportingNgo') ??
                                                              '',
                                                      otherNgo:
                                                          schoolRecceController
                                                              .supportingNgoController
                                                              .text,
                                                      observationPoint:
                                                          schoolRecceController
                                                              .keyPointsController
                                                              .text,
                                                      submittedBy: widget.userid
                                                          .toString(),
                                                      createdAt: formattedDate
                                                          .toString(),
                                                      office:
                                                          widget.office ?? '',
                                                    );

                                                    int result =
                                                        await LocalDbController()
                                                            .addData(
                                                                schoolRecceModal:
                                                                    schoolRecceModal);
                                                    if (result > 0) {
                                                      schoolRecceController
                                                          .clearFields();
                                                      setState(() {
                                                        jsonData = {};
                                                        staffJsonData = {};
                                                        readingJson2 = {};

                                                        schoolRecceController
                                                            .checkboxValue16;
                                                        schoolRecceController
                                                            .checkboxValue17;
                                                        schoolRecceController
                                                            .checkboxValue18;
                                                        schoolRecceController
                                                            .checkboxValue19;
                                                        schoolRecceController
                                                            .checkboxValue20;
                                                      });

                                                      String jsonData1 =
                                                          jsonEncode(
                                                              schoolRecceModal
                                                                  .toJson());

                                                      try {
                                                        JsonFileDownloader
                                                            downloader =
                                                            JsonFileDownloader();
                                                        String? filePath =
                                                            await downloader
                                                                .downloadJsonFile(
                                                          jsonData1,
                                                          uniqueId,
                                                          boardImgFiles,
                                                          buildingImgFiles,
                                                          registerImgFiles,
                                                          smrtImgFiles,
                                                          projectorImgFiles,
                                                          computerImgFiles,
                                                          libImgFiles,
                                                          spaceImgFiles,
                                                          enrollmentImgFiles,
                                                          digiLabImgFiles,
                                                          libRoomImgFiles,
                                                        );
                                                        // Notify user of success
                                                        customSnackbar(
                                                          'File Downloaded Successfully',
                                                          'File saved at $filePath',
                                                          AppColors.primary,
                                                          AppColors.onPrimary,
                                                          Icons.download_done,
                                                        );
                                                      } catch (e) {
                                                        customSnackbar(
                                                          'Error',
                                                          e.toString(),
                                                          AppColors.primary,
                                                          AppColors.onPrimary,
                                                          Icons.error,
                                                        );
                                                      }

                                                      customSnackbar(
                                                          'Submitted Successfully',
                                                          'Submitted',
                                                          AppColors.primary,
                                                          AppColors.onPrimary,
                                                          Icons.verified);

                                                      // Navigate to HomeScreen
                                                      Navigator.pushReplacement(
                                                        context,
                                                        MaterialPageRoute(
                                                            builder: (context) =>
                                                                 const HomeScreen()),
                                                      );
                                                    } else {
                                                      customSnackbar(
                                                          'Error',
                                                          'Something went wrong',
                                                          AppColors.error,
                                                          Colors.white,
                                                          Icons.error);
                                                    }
                                                  } else {
                                                    FocusScope.of(context)
                                                        .requestFocus(
                                                            FocusNode());
                                                  }
                                                },
                                              ),
                                            ],
                                          ),
                                        ], //End of other Info
                                      ]);
                                    }));
                          })
                    ])))));
  }
}

class JsonFileDownloader {
  // Method to download JSON data to the Downloads directory
  Future<String?> downloadJsonFile(
    String jsonData,
    String uniqueId,
    List<File> boardImgFiles,
    List<File> buildingImgFiles,
    List<File> registerImgFiles,
    List<File> smrtImgFiles,
    List<File> projectorImgFiles,
    List<File> computerImgFiles,
    List<File> libImgFiles,
    List<File> spaceImgFiles,
    List<File> enrollmentImgFiles,
    List<File> digiLabImgFiles,
    List<File> libRoomImgFiles,
  ) async {
    // Request storage permission

    Directory? downloadsDirectory;

    if (Platform.isAndroid) {
      downloadsDirectory = await _getAndroidDirectory();
    } else if (Platform.isIOS) {
      downloadsDirectory = await getApplicationDocumentsDirectory();
    } else {
      downloadsDirectory = await getDownloadsDirectory();
    }

    if (downloadsDirectory != null) {
      // Prepare file path to save the JSON
      String filePath =
          '${downloadsDirectory.path}/school_recce_form_$uniqueId.txt';
      File file = File(filePath);

      // Convert images to Base64 for each image list
      Map<String, dynamic> jsonObject = jsonDecode(jsonData);

      jsonObject['base64_boardImages'] =
          await _convertImagesToBase64(boardImgFiles);
      jsonObject['base64_buildingImages'] =
          await _convertImagesToBase64(buildingImgFiles);
      jsonObject['base64_registerImages'] =
          await _convertImagesToBase64(registerImgFiles);
      jsonObject['base64_smrtImages'] =
          await _convertImagesToBase64(smrtImgFiles);
      jsonObject['base64_projectorImages'] =
          await _convertImagesToBase64(projectorImgFiles);
      jsonObject['base64_computerImages'] =
          await _convertImagesToBase64(computerImgFiles);
      jsonObject['base64_libImages'] =
          await _convertImagesToBase64(libImgFiles);
      jsonObject['base64_spaceImages'] =
          await _convertImagesToBase64(spaceImgFiles);
      jsonObject['base64_enrollmentImages'] =
          await _convertImagesToBase64(enrollmentImgFiles);
      jsonObject['base64_digiLabImages'] =
          await _convertImagesToBase64(digiLabImgFiles);
      jsonObject['base64_libRoomImages'] =
          await _convertImagesToBase64(libRoomImgFiles);

      // Write the updated JSON data to the file
      await file.writeAsString(jsonEncode(jsonObject));

      // Return the file path for further use if needed
      return filePath;
    } else {
      throw Exception('Could not find the download directory');
    }
  }

  Future<String> _convertImagesToBase64(List<File> imageFiles) async {
    List<String> base64Images = [];

    for (File image in imageFiles) {
      if (await image.exists()) {
        List<int> imageBytes = await image.readAsBytes();
        String base64Image = base64Encode(imageBytes);
        base64Images.add(base64Image);
      }
    }

    // Return Base64-encoded images as a comma-separated string
    return base64Images.join(',');
  }

  // Method to get the correct directory for Android based on version
  Future<Directory?> _getAndroidDirectory() async {
    if (Platform.isAndroid) {
      var androidInfo = await DeviceInfoPlugin().androidInfo;

      // Android 11+ (API level 30 and above) - Use manage external storage
      if (androidInfo.version.sdkInt >= 30 &&
          await Permission.manageExternalStorage.isGranted) {
        return Directory('/storage/emulated/0/Download');
      }
      // Android 10 and below - Use external storage directory
      else if (await Permission.storage.isGranted) {
        return await getExternalStorageDirectory();
      }
    }
    return null;
  }
}

class NumericRangeTextInputFormatter extends TextInputFormatter {
  final int min;
  final int max;

  NumericRangeTextInputFormatter({required this.min, required this.max});

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue; // Allow empty input
    }

    final int? newValueInt = int.tryParse(newValue.text);
    if (newValueInt != null && (newValueInt < min || newValueInt > max)) {
      return oldValue; // Prevent entering numbers outside the range
    }

    return newValue; // Allow valid input
  }
}
