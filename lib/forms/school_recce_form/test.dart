import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GradeEnrollmentScreen extends StatefulWidget {
  @override
  _GradeEnrollmentScreenState createState() => _GradeEnrollmentScreenState();
}

class _GradeEnrollmentScreenState extends State<GradeEnrollmentScreen> {
  var jsonData = <String, Map<String, String>>{};
  final List<TextEditingController> boysControllers = [];
  final List<TextEditingController> girlsControllers = [];
  bool validateEnrolmentRecords = false;
  final List<ValueNotifier<int>> totalNotifiers = [];
  bool isInitialized = false;

  // ValueNotifiers for the grand totals
  final ValueNotifier<int> grandTotalBoys = ValueNotifier<int>(0);
  final ValueNotifier<int> grandTotalGirls = ValueNotifier<int>(0);
  final ValueNotifier<int> grandTotal = ValueNotifier<int>(0);

  // Checkbox selection management
  final List<bool> isSelected =
      List.generate(10, (index) => false); // 10 grades
  final List<String> grades = [

  ]; // Dynamically populated selected grades

  @override
  void initState() {
    super.initState();
  }

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

    setState(() {
      isInitialized = true;
    });
  }

  @override
  void dispose() {
    super.dispose();

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
  }

  TableRow tableRowMethod(String classname, TextEditingController boyController,
      TextEditingController girlController, ValueNotifier<int> totalNotifier) {
    return TableRow(
      children: [
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.middle,
          child: Center(
            child: Text(
              classname,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.middle,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextFormField(
              controller: boyController,
              decoration: const InputDecoration(border: InputBorder.none),
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(3),
              ],
            ),
          ),
        ),
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.middle,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextFormField(
              controller: girlController,
              decoration: const InputDecoration(border: InputBorder.none),
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(3),
              ],
            ),
          ),
        ),
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.middle,
          child: ValueListenableBuilder<int>(
            valueListenable: totalNotifier,
            builder: (context, total, child) {
              return Center(
                child: Text(
                  total.toString(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Grade Enrollment'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: 10,
              itemBuilder: (context, index) {
                String gradeName = "Grade ${index + 1}";
                return CheckboxListTile(
                  title: Text(gradeName),
                  value: isSelected[index],
                  onChanged: (bool? value) {
                    setState(() {
                      isSelected[index] = value ?? false;

                      if (isSelected[index] && !grades.contains(gradeName)) {
                        grades.add(gradeName);
                      } else if (!isSelected[index] &&
                          grades.contains(gradeName)) {
                        grades.remove(gradeName);
                      }

                      initializeControllers();
                    });
                  },
                );
              },
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (grades.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Please select at least one grade.')),
                );
              } else {
                collectData();
              }
            },
            child: const Text('Save Data'),
          ),
          if (isInitialized)
            Expanded(
              child: SingleChildScrollView(
                child: Table(
                  border: TableBorder.all(),
                  children: [
                    TableRow(
                      children: [
                        const TableCell(
                          child: Center(
                              child: Text('Class Name',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                        ),
                        const TableCell(
                          child: Center(
                              child: Text('Boys',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                        ),
                        const TableCell(
                          child: Center(
                              child: Text('Girls',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                        ),
                        const TableCell(
                          child: Center(
                              child: Text('Total',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                        ),
                      ],
                    ),
                    ...grades.asMap().entries.map((entry) {
                      final index = entry.key;
                      final grade = entry.value;
                      return tableRowMethod(
                        grade,
                        boysControllers[index],
                        girlsControllers[index],
                        totalNotifiers[index],
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
