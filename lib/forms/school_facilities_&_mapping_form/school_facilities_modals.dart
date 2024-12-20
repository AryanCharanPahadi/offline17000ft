import 'dart:convert';

List<SchoolFacilitiesRecords?>? schoolFacilitiesRecordsFromJson(String str) =>
    str.isEmpty ? [] : List<SchoolFacilitiesRecords?>.from(json.decode(str).map((x) => SchoolFacilitiesRecords.fromJson(x)));
String schoolFacilitiesRecordsToJson(List<SchoolFacilitiesRecords?>? data) =>
    json.encode(data == null ? [] : List<dynamic>.from(data.map((x) => x!.toJson())));
class SchoolFacilitiesRecords {
  SchoolFacilitiesRecords({

    this.id,
    this.school,
    this.udiseCode,
    this.correctUdise,
    this.tourId,
    this.residentialValue,
    this.electricityValue,
    this.internetValue,
    this.projectorValue,
    this.smartClassValue,
    this.numFunctionalClass,
    this.playgroundValue,
    this.playImg,
    this.libValue,
    this.libLocation,
    this.librarianName,
    this.librarianTraining,
    this.libRegisterValue,
    this.imgRegister,
    this.createdBy,
    this.createdAt,
    this.office,


  });

  int? id;
  String? tourId;
  String? school;
  String? udiseCode;
  String? correctUdise;
  String? residentialValue;
  String? electricityValue;
  String? internetValue;
  String? projectorValue;
  String? smartClassValue;
  String? numFunctionalClass;
  String? playgroundValue;
  String? playImg;
  String? libValue;
  String? libLocation;
  String? librarianName;
  String? librarianTraining;
  String? libRegisterValue;
  String? imgRegister;
  String? createdBy;
  String? createdAt;
  String? office;



  factory SchoolFacilitiesRecords.fromJson(Map<String, dynamic> json) => SchoolFacilitiesRecords(
    id: json["id"],
    tourId: json["tourId"],
    school: json["school"],
    udiseCode: json["udiseCode"],
    correctUdise: json["correctUdise"],

    residentialValue: json["residentialValue"],
    electricityValue: json["electricityValue"],
    internetValue: json["internetValue"],
    projectorValue: json["projectorValue"],
    smartClassValue: json["smartClassValue"],
    numFunctionalClass: json["numFunctionalClass"],
    playgroundValue: json["playgroundValue"],
    playImg: json["playImg"],
    libValue: json["libValue"],
    libLocation: json["libLocation"],
    librarianName: json["librarianName"],
    librarianTraining: json["librarianTraining"],
    libRegisterValue: json["libRegisterValue"],
    imgRegister: json["imgRegister"],
    createdBy: json["created_by"],
    createdAt: json["created_at"],
    office: json["office"],


  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "tourId": tourId,
    "school": school,
    "udiseCode": udiseCode,
    "correctUdise": correctUdise,
    "residentialValue": residentialValue,
    "electricityValue": electricityValue,
    "internetValue": internetValue,
    "projectorValue": projectorValue,
    "smartClassValue": smartClassValue,
    "numFunctionalClass": numFunctionalClass,
    "playgroundValue": playgroundValue,
    "playImg": playImg,
    "libValue": libValue,
    "libLocation": libLocation,
    "librarianName": librarianName,
    "librarianTraining": librarianTraining,
    "libRegisterValue": libRegisterValue,
    "imgRegister": imgRegister,
    "created_by": createdBy,
    "created_at": createdAt,
    "office": office,


  };
}
