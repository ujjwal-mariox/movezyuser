import 'dart:convert';

UserProfileResponse userProfileResponseFromJson(String str) => UserProfileResponse.fromJson(json.decode(str));

String userProfileResponseToJson(UserProfileResponse data) => json.encode(data.toJson());

class UserProfileResponse {
  int code;
  String message;
  UserData data;

  UserProfileResponse({
    required this.code,
    required this.message,
    required this.data,
  });

  factory UserProfileResponse.fromJson(Map<String, dynamic> json) => UserProfileResponse(
    code: json["code"],
    message: json["message"],
    data: UserData.fromJson(json["data"]),
  );

  Map<String, dynamic> toJson() => {
    "code": code,
    "message": message,
    "data": data.toJson(),
  };
}

class UserData {
  String id;
  String fullName;
  String email;
  String profileImages;
  String gender;
  String dob;
  String countryCode;
  String mobileNumber;
  bool isActive;
  bool isDeleted;
  bool notificationAllowed;
  String createdAt;
  String updatedAt;
  int v;
  String profileImage;

  UserData({
    required this.id,
    required this.fullName,
    required this.email,
    required this.profileImages,
    required this.gender,
    required this.dob,
    required this.countryCode,
    required this.mobileNumber,
    required this.isActive,
    required this.isDeleted,
    required this.notificationAllowed,
    required this.createdAt,
    required this.updatedAt,
    required this.v,
    required this.profileImage,
  });

  factory UserData.fromJson(Map<String, dynamic> json) => UserData(
    id: json["_id"] ?? "",
    fullName: json["fullName"] ?? "",
    email: json["email"] ?? "",
    profileImages: json["profileImages"] ?? "",
    gender: json["gender"] ?? "",
    dob: json["dob"] ?? "",
    countryCode: json["countryCode"] ?? "+91",
    mobileNumber: json["mobileNumber"] ?? "",
    isActive: json["isActive"] ?? false,
    isDeleted: json["isDeleted"] ?? false,
    notificationAllowed: json["notificationAllowed"] ?? false,
    createdAt: json["createdAt"] ?? "",
    updatedAt: json["updatedAt"] ?? "",
    v: json["__v"] ?? 0,
    profileImage: json["profileImage"] ?? "",
  );

  Map<String, dynamic> toJson() => {
    "_id": id,
    "fullName": fullName,
    "email": email,
    "profileImages": profileImages,
    "gender": gender,
    "dob": dob,
    "countryCode": countryCode,
    "mobileNumber": mobileNumber,
    "isActive": isActive,
    "isDeleted": isDeleted,
    "notificationAllowed": notificationAllowed,
    "createdAt": createdAt,
    "updatedAt": updatedAt,
    "__v": v,
    "profileImage": profileImage,
  };
}
