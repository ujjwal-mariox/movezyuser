// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:hexcolor/hexcolor.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:movezy_user_app/CommonWidgets/button_widget.dart';
// import 'package:movezy_user_app/Screens/ProfileScreen/Model/user_profile_response.dart';
// import 'package:movezy_user_app/Screens/ProfileScreen/ProfileApiService/update_profile_api_service.dart';
// import 'package:movezy_user_app/Utils/AppColors/app_colors.dart';
// import 'package:movezy_user_app/Utils/PermissionsManager/permissions_manager.dart'; // ✅ ADD THIS IMPORT

// class UpdateProfileScreen extends StatefulWidget {
//   final UserData? userData;

//   const UpdateProfileScreen({super.key, this.userData});

//   @override
//   State<UpdateProfileScreen> createState() => _UpdateProfileScreenState();
// }

// class _UpdateProfileScreenState extends State<UpdateProfileScreen> {
//   late TextEditingController fullNameController;
//   late TextEditingController emailController;
//   late TextEditingController genderController;
//   late TextEditingController dobController;
  
//   bool isLoading = false;
//   String? selectedGender;
//   File? _selectedImage;
  
//   final List<String> genderOptions = ['Male', 'Female', 'Other'];
//   final ImagePicker _imagePicker = ImagePicker();

//   @override
//   void initState() {
//     super.initState();
//     fullNameController = TextEditingController(text: widget.userData?.fullName ?? '');
//     emailController = TextEditingController(text: widget.userData?.email ?? '');
//     genderController = TextEditingController(text: widget.userData?.gender ?? '');
//     dobController = TextEditingController(text: widget.userData?.dob ?? '');
//     selectedGender = widget.userData?.gender;
//   }

//   @override
//   void dispose() {
//     fullNameController.dispose();
//     emailController.dispose();
//     genderController.dispose();
//     dobController.dispose();
//     super.dispose();
//   }

//   Future<void> _selectDate() async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: _parseDate(dobController.text) ?? DateTime(2000),
//       firstDate: DateTime(1950),
//       lastDate: DateTime.now(),
//     );
//     if (picked != null) {
//       setState(() {
//         dobController.text = "${picked.day.toString().padLeft(2, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.year}";
//       });
//     }
//   }

//   DateTime? _parseDate(String dateString) {
//     try {
//       if (dateString.isEmpty) return null;
//       final parts = dateString.split('-');
//       if (parts.length == 3) {
//         return DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
//       }
//     } catch (e) {
//       // Date parsing error
//     }
//     return null;
//   }

//   // ✅ REPLACE THIS METHOD - Updated _pickImage with camera/gallery selection
//   Future<void> _pickImage() async {
//     try {
//       // Show camera/gallery choice sheet
//       final source = await PermissionsManager.showImageSourceSheet(context);
      
//       if (source == null) return; // User cancelled

//       bool hasPermission = false;

//       // Request appropriate permission based on source
//       if (source == ImageSource.camera) {
//         hasPermission = await PermissionsManager.requestCameraPermissionWithDialog(context);
//       } else {
//         hasPermission = await PermissionsManager.requestGalleryPermissionWithDialog(context);
//       }

//       // If permission denied, show error and return
//       if (!hasPermission) {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text(
//                 source == ImageSource.camera
//                     ? 'Camera permission is required to take photos'
//                     : 'Gallery permission is required to select images',
//               ),
//               duration: const Duration(seconds: 2),
//               backgroundColor: Colors.red,
//             ),
//           );
//         }
//         return;
//       }

//       // Pick image from selected source
//       final XFile? pickedFile = await _imagePicker.pickImage(
//         source: source == ImageSource.camera ? ImageSource.camera : ImageSource.gallery,
//         imageQuality: 80,
//       );

//       // Update UI with selected image
//       if (pickedFile != null && mounted) {
//         setState(() {
//           _selectedImage = File(pickedFile.path);
//         });

//         // Show success message
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(
//               content: Text('Image selected successfully'),
//               duration: Duration(seconds: 1),
//               backgroundColor: Colors.green,
//             ),
//           );
//         }
//       }
//     } catch (e) {
//       debugPrint('Error picking image: $e');
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Error: ${e.toString()}'),
//             duration: const Duration(seconds: 2),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     }
//   }

//   Future<void> _updateProfile() async {
//     if (fullNameController.text.isEmpty) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Full name is required")),
//       );
//       return;
//     }

//     setState(() {
//       isLoading = true;
//     });

//     bool success = await UpdateProfileApiService().updateUserProfile(
//       context: context,
//       fullName: fullNameController.text,
//       email: emailController.text,
//       gender: selectedGender,
//       dob: dobController.text,
//       profileImage: _selectedImage,
//     );

//     if (!mounted) return;
    
//     setState(() {
//       isLoading = false;
//     });

//     if (success) {
//       Navigator.pop(context, true);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
//       statusBarColor: Colors.transparent,
//       statusBarIconBrightness: Brightness.dark,
//       statusBarBrightness: Brightness.dark,
//     ));

//     return Scaffold(
//       backgroundColor: const Color(0xFFFDF6EF),
//       bottomNavigationBar: Container(
//         color: Colors.white,
//         padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
//         child: ButtonWidget(
//           text: isLoading ? "Updating..." : "Save Changes",
//           onTap: isLoading ? null : _updateProfile,
//           backgroundColor: isLoading ? Colors.grey : AppColors.appColor,
//           textStyle: const TextStyle(
//             color: Colors.white,
//             fontWeight: FontWeight.w600,
//             fontSize: 16,
//           ),
//           borderRadius: BorderRadius.circular(10),
//         ),
//       ),
//       body: SingleChildScrollView(
//         child: Column(
//           children: [
//             Container(
//               width: double.infinity,
//               padding: const EdgeInsets.fromLTRB(16, 50, 16, 24),
//               decoration: const BoxDecoration(
//                 color: Color(0xFFE96D2D),
//                 borderRadius: BorderRadius.only(
//                   bottomLeft: Radius.circular(32),
//                   bottomRight: Radius.circular(32),
//                 ),
//               ),
//               child: Row(
//                 children: [
//                   InkWell(
//                     onTap: () {
//                       Navigator.pop(context);
//                     },
//                     child: Container(
//                       padding: const EdgeInsets.only(left: 16),
//                       width: 40,
//                       height: 35,
//                       alignment: Alignment.center,
//                       child: const Icon(Icons.arrow_back_ios, color: Colors.white),
//                     ),
//                   ),
//                   const Text(
//                     "Update Profile",
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 18,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                 ],
//               ),
//             ),

//             const SizedBox(height: 24),

//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16),
//               child: GestureDetector(
//                 onTap: _pickImage,
//                 child: Container(
//                   width: 120,
//                   height: 120,
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(15),
//                     border: Border.all(color: HexColor("#E0E0E0"), width: 2),
//                   ),
//                   child: Stack(
//                     alignment: Alignment.center,
//                     children: [
//                       if (_selectedImage != null)
//                         ClipRRect(
//                           borderRadius: BorderRadius.circular(13),
//                           child: Image.file(
//                             _selectedImage!,
//                             width: 120,
//                             height: 120,
//                             fit: BoxFit.cover,
//                           ),
//                         )
//                       else if (widget.userData?.profileImage != null && (widget.userData?.profileImage ?? '').isNotEmpty)
//                         ClipRRect(
//                           borderRadius: BorderRadius.circular(13),
//                           child: Image.network(
//                             widget.userData?.profileImage ?? '',
//                             width: 120,
//                             height: 120,
//                             fit: BoxFit.cover,
//                             errorBuilder: (context, error, stackTrace) {
//                               return Container(
//                                 color: HexColor("#F5F5F5"),
//                                 child: Icon(
//                                   Icons.person,
//                                   size: 48,
//                                   color: HexColor("#B8B8B8"),
//                                 ),
//                               );
//                             },
//                           ),
//                         )
//                       else
//                         Icon(
//                           Icons.person,
//                           size: 48,
//                           color: HexColor("#B8B8B8"),
//                         ),
//                       Positioned(
//                         bottom: 0,
//                         right: 0,
//                         child: Container(
//                           width: 36,
//                           height: 36,
//                           decoration: BoxDecoration(
//                             color: AppColors.appColor,
//                             shape: BoxShape.circle,
//                             border: Border.all(color: Colors.white, width: 2),
//                           ),
//                           child: const Icon(
//                             Icons.camera_alt,
//                             color: Colors.white,
//                             size: 18,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),

//             const SizedBox(height: 24),

//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   _buildLabel("Full Name"),
//                   const SizedBox(height: 8),
//                   _buildTextField(
//                     controller: fullNameController,
//                     hintText: "Enter your full name",
//                     keyboardType: TextInputType.text,
//                   ),

//                   const SizedBox(height: 20),

//                   _buildLabel("Email"),
//                   const SizedBox(height: 8),
//                   _buildTextField(
//                     controller: emailController,
//                     hintText: "Enter your email",
//                     keyboardType: TextInputType.emailAddress,
//                   ),

//                   const SizedBox(height: 20),

//                   _buildLabel("Gender"),
//                   const SizedBox(height: 8),
//                   _buildGenderDropdown(),

//                   const SizedBox(height: 20),

//                   _buildLabel("Date of Birth (DD-MM-YYYY)"),
//                   const SizedBox(height: 8),
//                   _buildDateField(),

//                   const SizedBox(height: 40),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildLabel(String text) {
//     return Text(
//       text,
//       style: const TextStyle(
//         fontSize: 14,
//         fontWeight: FontWeight.w600,
//         color: Colors.black,
//       ),
//     );
//   }

//   Widget _buildTextField({
//     required TextEditingController controller,
//     required String hintText,
//     required TextInputType keyboardType,
//     int maxLines = 1,
//   }) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 15),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(10),
//         border: Border.all(color: HexColor("#E0E0E0")),
//       ),
//       child: TextField(
//         controller: controller,
//         keyboardType: keyboardType,
//         maxLines: maxLines,
//         decoration: InputDecoration(
//           hintText: hintText,
//           hintStyle: TextStyle(
//             color: HexColor("#B8B8B8"),
//             fontSize: 13,
//             fontWeight: FontWeight.w400,
//           ),
//           border: InputBorder.none,
//           contentPadding: const EdgeInsets.symmetric(vertical: 14),
//         ),
//         style: const TextStyle(
//           color: Colors.black,
//           fontSize: 13,
//           fontWeight: FontWeight.w400,
//         ),
//       ),
//     );
//   }

//   Widget _buildGenderDropdown() {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 15),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(10),
//         border: Border.all(color: HexColor("#E0E0E0")),
//       ),
//       child: DropdownButtonHideUnderline(
//         child: SizedBox(
//           height: 48,
//           child: DropdownButton<String>(
//             value: selectedGender,
//             hint: Text(
//               "Select Gender",
//               style: TextStyle(
//                 color: HexColor("#B8B8B8"),
//                 fontSize: 13,
//                 fontWeight: FontWeight.w400,
//               ),
//             ),
//             isExpanded: true,
//             items: genderOptions.map((String value) {
//               return DropdownMenuItem<String>(
//                 value: value,
//                 child: Text(
//                   value,
//                   style: const TextStyle(
//                     color: Colors.black,
//                     fontSize: 13,
//                     fontWeight: FontWeight.w400,
//                   ),
//                 ),
//               );
//             }).toList(),
//             onChanged: (String? newValue) {
//               setState(() {
//                 selectedGender = newValue;
//                 genderController.text = newValue ?? '';
//               });
//             },
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildDateField() {
//     return GestureDetector(
//       onTap: _selectDate,
//       child: Container(
//         height: 48,
//         padding: const EdgeInsets.symmetric(horizontal: 15),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(10),
//           border: Border.all(color: HexColor("#E0E0E0")),
//         ),
//         child: Row(
//           children: [
//             Expanded(
//               child: Align(
//                 alignment: Alignment.centerLeft,
//                 child: Text(
//                   dobController.text.isEmpty ? "Select Date of Birth" : dobController.text,
//                   style: TextStyle(
//                     color: dobController.text.isEmpty ? HexColor("#B8B8B8") : Colors.black,
//                     fontSize: 13,
//                     fontWeight: FontWeight.w400,
//                   ),
//                 ),
//               ),
//             ),
//             const SizedBox(width: 8),
//             Icon(
//               Icons.calendar_today,
//               color: HexColor("#B8B8B8"),
//               size: 18,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:image_picker/image_picker.dart';
import 'package:movezy_user_app/CommonWidgets/button_widget.dart';
import 'package:movezy_user_app/Screens/ProfileScreen/Model/user_profile_response.dart';
import 'package:movezy_user_app/Screens/ProfileScreen/ProfileApiService/update_profile_api_service.dart';
import 'package:movezy_user_app/Utils/AppColors/app_colors.dart';
import 'package:movezy_user_app/Utils/PermissionsManager/permissions_manager.dart'; // ✅ ADD THIS IMPORT

class UpdateProfileScreen extends StatefulWidget {
  final UserData? userData;

  const UpdateProfileScreen({super.key, this.userData});

  @override
  State<UpdateProfileScreen> createState() => _UpdateProfileScreenState();
}

class _UpdateProfileScreenState extends State<UpdateProfileScreen> {
  late TextEditingController fullNameController;
  late TextEditingController emailController;
  late TextEditingController genderController;
  late TextEditingController dobController;
  
  bool isLoading = false;
  String? selectedGender;
  File? _selectedImage;
  
  final List<String> genderOptions = ['Male', 'Female', 'Other'];
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    fullNameController = TextEditingController(text: widget.userData?.fullName ?? '');
    emailController = TextEditingController(text: widget.userData?.email ?? '');
    genderController = TextEditingController(text: widget.userData?.gender ?? '');
    dobController = TextEditingController(text: widget.userData?.dob ?? '');
    selectedGender = widget.userData?.gender;
  }

  @override
  void dispose() {
    fullNameController.dispose();
    emailController.dispose();
    genderController.dispose();
    dobController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _parseDate(dobController.text) ?? DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        dobController.text = "${picked.day.toString().padLeft(2, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.year}";
      });
    }
  }

  DateTime? _parseDate(String dateString) {
    try {
      if (dateString.isEmpty) return null;
      final parts = dateString.split('-');
      if (parts.length == 3) {
        return DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
      }
    } catch (e) {
      // Date parsing error
    }
    return null;
  }

  // ✅ REPLACE THIS METHOD - Updated _pickImage with camera/gallery selection
  Future<void> _pickImage() async {
    if (!mounted) return;

    try {
      // Show camera/gallery choice sheet
      final source = await PermissionsManager.showImageSourceSheet(context);
      
      if (source == null || !mounted) return; // User cancelled or widget disposed

      bool hasPermission = false;

      // Request appropriate permission based on source
      if (source == 'camera') {
        hasPermission = await PermissionsManager.requestCameraPermissionWithDialog(context);
      } else {
        hasPermission = await PermissionsManager.requestGalleryPermissionWithDialog(context);
      }

      if (!mounted) return; // Check after async operation

      // If permission denied, show error and return
      if (!hasPermission) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              source == 'camera'
                  ? 'Camera permission is required to take photos'
                  : 'Gallery permission is required to select images',
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Pick image from selected source
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source == 'camera' ? ImageSource.camera : ImageSource.gallery,
        imageQuality: 80,
      );

      if (!mounted) return; // Check after async operation

      // Update UI with selected image
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image selected successfully'),
            duration: Duration(seconds: 1),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateProfile() async {
    if (fullNameController.text.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Full name is required")),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    bool success = await UpdateProfileApiService().updateUserProfile(
      context: context,
      fullName: fullNameController.text,
      email: emailController.text,
      gender: selectedGender,
      dob: dobController.text,
      profileImage: _selectedImage,
    );

    if (!mounted) return;
    
    setState(() {
      isLoading = false;
    });

    if (success) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.dark,
    ));

    return Scaffold(
      backgroundColor: const Color(0xFFFDF6EF),
      // SafeArea(top: false): the bar itself applies no inset, so "Save Changes"
      // sat partly under the gesture bar / nav buttons.
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
          child: ButtonWidget(
            text: isLoading ? "Updating..." : "Save Changes",
            onTap: isLoading ? null : _updateProfile,
            backgroundColor: isLoading ? Colors.grey : AppColors.appColor,
            textStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 50, 16, 24),
              decoration: const BoxDecoration(
                color: Color(0xFFE96D2D),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Row(
                children: [
                  InkWell(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.only(left: 16),
                      width: 40,
                      height: 35,
                      alignment: Alignment.center,
                      child: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    ),
                  ),
                  const Text(
                    "Update Profile",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: HexColor("#E0E0E0"), width: 2),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (_selectedImage != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(13),
                          child: Image.file(
                            _selectedImage!,
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                          ),
                        )
                      else if (widget.userData?.profileImage != null && (widget.userData?.profileImage ?? '').isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(13),
                          child: Image.network(
                            widget.userData?.profileImage ?? '',
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: HexColor("#F5F5F5"),
                                child: Icon(
                                  Icons.person,
                                  size: 48,
                                  color: HexColor("#B8B8B8"),
                                ),
                              );
                            },
                          ),
                        )
                      else
                        Icon(
                          Icons.person,
                          size: 48,
                          color: HexColor("#B8B8B8"),
                        ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.appColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel("Full Name"),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: fullNameController,
                    hintText: "Enter your full name",
                    keyboardType: TextInputType.text,
                  ),

                  const SizedBox(height: 20),

                  _buildLabel("Email"),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: emailController,
                    hintText: "Enter your email",
                    keyboardType: TextInputType.emailAddress,
                  ),

                  const SizedBox(height: 20),

                  _buildLabel("Gender"),
                  const SizedBox(height: 8),
                  _buildGenderDropdown(),

                  const SizedBox(height: 20),

                  _buildLabel("Date of Birth (DD-MM-YYYY)"),
                  const SizedBox(height: 8),
                  _buildDateField(),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.black,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required TextInputType keyboardType,
    int maxLines = 1,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: HexColor("#E0E0E0")),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: HexColor("#B8B8B8"),
            fontSize: 13,
            fontWeight: FontWeight.w400,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
        style: const TextStyle(
          color: Colors.black,
          fontSize: 13,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: HexColor("#E0E0E0")),
      ),
      child: DropdownButtonHideUnderline(
        child: SizedBox(
          height: 48,
          child: DropdownButton<String>(
            value: selectedGender,
            hint: Text(
              "Select Gender",
              style: TextStyle(
                color: HexColor("#B8B8B8"),
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
            ),
            isExpanded: true,
            items: genderOptions.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(
                  value,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                selectedGender = newValue;
                genderController.text = newValue ?? '';
              });
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDateField() {
    return GestureDetector(
      onTap: _selectDate,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: HexColor("#E0E0E0")),
        ),
        child: Row(
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  dobController.text.isEmpty ? "Select Date of Birth" : dobController.text,
                  style: TextStyle(
                    color: dobController.text.isEmpty ? HexColor("#B8B8B8") : Colors.black,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.calendar_today,
              color: HexColor("#B8B8B8"),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}