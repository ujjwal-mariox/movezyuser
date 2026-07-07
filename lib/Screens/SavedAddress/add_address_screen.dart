// // import 'package:flutter/material.dart';
// // import 'package:flutter/services.dart';
// // import 'package:geolocator/geolocator.dart';
// // import 'package:movezy_user_app/Screens/SavedAddress/Models/address_model.dart';
// // import 'package:movezy_user_app/Screens/SavedAddress/AddressApiService/address_api_service.dart';
// // import 'package:movezy_user_app/Utils/PermissionsManager/permissions_manager.dart';
// // import 'package:movezy_user_app/CommonWidgets/button_widget.dart';
// // import 'package:movezy_user_app/Utils/CustomToast/custome_toast.dart';


// //                   }
// //                   return null;
// //                 },
// //               ),
// //               const SizedBox(height: 16),

// //               // Country
// //               _buildTextField(
// //                 controller: _countryController,
// //                 label: 'Country',
// //                 hint: 'e.g., India',
// //                 icon: Icons.public,
// //                 enabled: widget.addressToEdit == null,
// //                 validator: (value) {
// //                   if (value == null || value.isEmpty) {
// //                     return 'Country is required';
// //                   }
// //                   return null;
// //                 },
// //               ),
// //               const SizedBox(height: 16),

// //               // Pin Code
// //               _buildTextField(
// //                 controller: _pinCodeController,
// //                 label: 'Pin Code',
// //                 hint: 'e.g., 560001',
// //                 icon: Icons.local_post_office,
// //                 inputType: TextInputType.number,
// //                 validator: (value) {
// //                   if (value == null || value.isEmpty) {
// //                     return 'Pin code is required';
// //                   }
// //                   if (!RegExp(r'^[0-9]{6}$').hasMatch(value)) {
// //                     return 'Pin code must be 6 digits';
// //                   }
// //                   return null;
// //                 },
// //               ),
// //               const SizedBox(height: 24),

// //               // Location Button
// //               Padding(
// //                 padding: const EdgeInsets.symmetric(horizontal: 0),
// //                 child: OutlinedButton.icon(
// //                   onPressed: _isLoadingLocation ? null : _getLocation,
// //                   icon: _isLoadingLocation
// //                       ? const SizedBox(
// //                           height: 18,
// //                           width: 18,
// //                           child: CircularProgressIndicator(strokeWidth: 2),
// //                         )
// //                       : const Icon(Icons.location_searching),
// //                   label: Text(
// //                     _isLoadingLocation
// //                         ? 'Getting Location...'
// //                         : _latitude != 0
// //                             ? 'Location Set (${_latitude.toStringAsFixed(4)}, ${_longitude.toStringAsFixed(4)})'
// //                             : 'Get Location',
// //                   ),
// //                   style: OutlinedButton.styleFrom(
// //                     padding: const EdgeInsets.symmetric(
// //                       horizontal: 16,
// //                       vertical: 12,
// //                     ),
// //                     side: BorderSide(
// //                       color: _latitude != 0 ? Colors.green : Colors.grey,
// //                     ),
// //                   ),
// //                 ),
// //               ),
// //               const SizedBox(height: 32),

// //               // Save Button
// //               SizedBox(
// //                 width: double.infinity,
// //                 child: ButtonWidget(
// //                   text: _isSaving
// //                       ? 'Saving...'
// //                       : (widget.addressToEdit != null ? 'Update Address' : 'Save Address'),
// //                   onTap: _isSaving ? null : _saveAddress,
// //                   height: 50,
// //                   borderRadius: BorderRadius.circular(8),
// //                 ),
// //               ),
// //             ],
// //           ),
// //         ),
// //       ),
// //     );
// //   }

// //   Widget _buildTextField({
// //     required TextEditingController controller,
// //     required String label,
// //     required String hint,
// //     required IconData icon,
// //     TextInputType inputType = TextInputType.text,
// //     bool enabled = true,
// //     FocusNode? focusNode,
// //     FocusNode? nextFocus,
// //     List<TextInputFormatter>? inputFormatters,
// //     String? Function(String?)? validator,
// //   }) {
// //     return Column(
// //       crossAxisAlignment: CrossAxisAlignment.start,
// //       children: [
// //         Text(
// //           label,
// //           style: const TextStyle(
// //             fontSize: 14,
// //             fontWeight: FontWeight.w600,
// //           ),
// //         ),
// //         const SizedBox(height: 8),
// //         TextFormField(
// //           controller: controller,
// //           enabled: enabled,
// //           keyboardType: inputType,
// //           focusNode: focusNode,
// //           inputFormatters: inputFormatters,
// //           validator: validator,
// //           onFieldSubmitted: (value) {
// //             // Move to next field when user presses done/next
// //             if (nextFocus != null) {
// //               FocusScope.of(context).requestFocus(nextFocus);
// //             }
// //           },
// //           decoration: InputDecoration(
// //             hintText: hint,
// //             prefixIcon: Icon(icon),
// //             border: OutlineInputBorder(
// //               borderRadius: BorderRadius.circular(8),
// //             ),
// //             contentPadding: const EdgeInsets.symmetric(
// //               horizontal: 12,
// //               vertical: 12,
// //             ),
// //           ),
// //         ),
// //       ],
// //     );
// //   }

// //   Widget _buildDropdown() {
// //     return Column(
// //       crossAxisAlignment: CrossAxisAlignment.start,
// //       children: [
// //         const Text(
// //           'Address Type',
// //           style: TextStyle(
// //             fontSize: 14,
// //             fontWeight: FontWeight.w600,
// //           ),
// //         ),
// //         const SizedBox(height: 8),
// //         DropdownButtonFormField<String>(
// //           initialValue: _selectedAddressType,
// //           onChanged: widget.addressToEdit != null
// //               ? null
// //               : (value) {
// //                   setState(() => _selectedAddressType = value ?? 'Home');
// //                 },
// //           items: _addressTypes
// //               .map(
// //                 (type) => DropdownMenuItem<String>(
// //                   value: type,
// //                   child: Text(type),
// //                 ),
// //               )
// //               .toList(),
// //           decoration: InputDecoration(
// //             prefixIcon: const Icon(Icons.label),
// //             border: OutlineInputBorder(
// //               borderRadius: BorderRadius.circular(8),
// //             ),
// //             contentPadding: const EdgeInsets.symmetric(
// //               horizontal: 12,
// //               vertical: 12,
// //             ),
// //           ),
// //         ),
// //       ],
// //     );
// //   }
// // }

// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:movezy_user_app/Screens/SavedAddress/Models/address_model.dart';
// import 'package:movezy_user_app/Screens/SavedAddress/AddressApiService/address_api_service.dart';
// import 'package:movezy_user_app/Utils/PermissionsManager/permissions_manager.dart';
// import 'package:movezy_user_app/CommonWidgets/button_widget.dart';
// import 'package:movezy_user_app/Utils/CustomToast/custome_toast.dart';

// class AddAddressScreen extends StatefulWidget {
//   final AddressModel? addressToEdit;

//   const AddAddressScreen({super.key, this.addressToEdit});

//   @override
//   State<AddAddressScreen> createState() => _AddAddressScreenState();
// }

// class _AddAddressScreenState extends State<AddAddressScreen> {
//   final _formKey = GlobalKey<FormState>();

//   late TextEditingController _fullNameController;
//   late TextEditingController _mobileController;
//   late TextEditingController _houseNoController;
//   late TextEditingController _areaController;
//   late TextEditingController _cityController;
//   late TextEditingController _stateController;
//   late TextEditingController _countryController;
//   late TextEditingController _pinCodeController;

//   String _selectedAddressType = 'Home';
//   bool _isSaving = false;
//   bool _isLoadingLocation = false;

//   double _latitude = 0;
//   double _longitude = 0;

//   final List<String> _addressTypes = ['Home', 'Work', 'Other'];

//   @override
//   void initState() {
//     super.initState();

//     _fullNameController = TextEditingController(
//       text: widget.addressToEdit?.fullName ?? '',
//     );
//     _mobileController = TextEditingController(
//       text: widget.addressToEdit?.mobileNumber ?? '',
//     );
//     _houseNoController = TextEditingController(
//       text: widget.addressToEdit?.houseNo ?? '',
//     );
//     _areaController = TextEditingController(
//       text: widget.addressToEdit?.area ?? '',
//     );
//     _cityController = TextEditingController(
//       text: widget.addressToEdit?.city ?? '',
//     );
//     _stateController = TextEditingController(
//       text: widget.addressToEdit?.state ?? '',
//     );
//     _countryController = TextEditingController(
//       text: widget.addressToEdit?.country ?? '',
//     );
//     _pinCodeController = TextEditingController(
//       text: widget.addressToEdit?.pinCode?.toString() ?? '',
//     );

//     if (widget.addressToEdit != null) {
//       _selectedAddressType = widget.addressToEdit!.addressType;
//       _latitude = widget.addressToEdit!.latitude;
//       _longitude = widget.addressToEdit!.longitude;
//     } else {
//       /// 🔥 AUTO FETCH LOCATION (OLD LOGIC)
//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         _getLocation();
//       });
//     }
//   }

//   @override
//   void dispose() {
//     _fullNameController.dispose();
//     _mobileController.dispose();
//     _houseNoController.dispose();
//     _areaController.dispose();
//     _cityController.dispose();
//     _stateController.dispose();
//     _countryController.dispose();
//     _pinCodeController.dispose();
//     super.dispose();
//   }

//   /// SAME LOCATION LOGIC AS OLD CODE
//   Future<void> _getLocation() async {
//     final hasPermission = await PermissionsManager.requestLocationPermission();

//     if (!hasPermission) {
//       showCustomToast(context, 'Location permission is required');
//       return;
//     }

//     setState(() => _isLoadingLocation = true);

//     try {
//       final position = await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.high,
//       );

//       setState(() {
//         _latitude = position.latitude;
//         _longitude = position.longitude;
//         _isLoadingLocation = false;
//       });

//       showCustomToast(
//         context,
//         'Location set (${_latitude.toStringAsFixed(4)}, ${_longitude.toStringAsFixed(4)})',
//       );
//     } catch (e) {
//       setState(() => _isLoadingLocation = false);
//       showCustomToast(context, 'Failed to get location');
//     }
//   }

//   Future<void> _saveAddress() async {
//     if (!_formKey.currentState!.validate()) return;

//     if (_latitude == 0 && _longitude == 0) {
//       showCustomToast(context, 'Location not set');
//       return;
//     }

//     setState(() => _isSaving = true);

//     try {
//       if (widget.addressToEdit != null) {
//         await AddressApiService.updateAddress(
//           addressId: widget.addressToEdit!.id ?? '',
//           houseNo: _houseNoController.text.trim(),
//           area: _areaController.text.trim(),
//           city: _cityController.text.trim(),
//           state: _stateController.text.trim(),
//           pinCode: int.parse(_pinCodeController.text),
//           context: context,
//         );
//       } else {
//         await AddressApiService.createAddress(
//           fullName: _fullNameController.text.trim(),
//           mobileNumber: _mobileController.text.trim(),
//           houseNo: _houseNoController.text.trim(),
//           area: _areaController.text.trim(),
//           city: _cityController.text.trim(),
//           state: _stateController.text.trim(),
//           country: _countryController.text.trim(),
//           pinCode: int.parse(_pinCodeController.text),
//           addressType: _selectedAddressType,
//           latitude: _latitude,
//           longitude: _longitude,
//           context: context,
//         );
//       }

//       if (mounted) Navigator.pop(context, true);
//     } catch (e) {
//       showCustomToast(context, 'Failed to save address');
//     }

//     setState(() => _isSaving = false);
//   }

//   @override
//   Widget build(BuildContext context) {
//     final size = MediaQuery.of(context).size;

//     return Scaffold(
//       body: Stack(
//         children: [
//           /// MAP PLACEHOLDER + LOADER
//           SizedBox(
//             height: size.height * 0.42,
//             width: size.width,
//             child: Container(
//               color: const Color(0xFFF2F2F2),
//               child: Center(
//                 child: _isLoadingLocation
//                     ? const CircularProgressIndicator()
//                     : const Icon(
//                         Icons.location_on,
//                         size: 64,
//                         color: Colors.orange,
//                       ),
//               ),
//             ),
//           ),

//           /// BACK BUTTON
//           SafeArea(
//             child: IconButton(
//               icon: const Icon(Icons.arrow_back),
//               onPressed: () => Navigator.pop(context),
//             ),
//           ),

//           /// BOTTOM SHEET
//           DraggableScrollableSheet(
//             initialChildSize: 0.6,
//             minChildSize: 0.55,
//             maxChildSize: 0.9,
//             builder: (context, scrollController) {
//               return Container(
//                 padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
//                 decoration: const BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
//                 ),
//                 child: _buildForm(scrollController),
//               );
//             },
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildForm(ScrollController scrollController) {
//     return Form(
//       key: _formKey,
//       child: ListView(
//         controller: scrollController,
//         children: [
//           _buildField(
//             controller: _fullNameController,
//             hint: 'Full Name',
//             icon: Icons.person,
//             validator: (v) => v!.length >= 3 ? null : 'Min 3 characters',
//           ),
//           const SizedBox(height: 12),

//           _buildField(
//             controller: _mobileController,
//             hint: 'Mobile Number',
//             icon: Icons.phone,
//             inputType: TextInputType.phone,
//             inputFormatters: [
//               FilteringTextInputFormatter.digitsOnly,
//               LengthLimitingTextInputFormatter(10),
//             ],
//             validator: (v) => RegExp(r'^[0-9]{10}$').hasMatch(v ?? '')
//                 ? null
//                 : 'Invalid number',
//           ),
//           const SizedBox(height: 12),

//           _buildField(
//             controller: _houseNoController,
//             hint: 'House No / Flat No',
//             icon: Icons.home,
//             validator: (v) => v!.isNotEmpty ? null : 'Required',
//           ),
//           const SizedBox(height: 12),

//           _buildField(
//             controller: _areaController,
//             hint: 'Area / Road Name',
//             icon: Icons.location_on,
//             validator: (v) => v!.isNotEmpty ? null : 'Required',
//           ),
//           const SizedBox(height: 12),

//           _buildField(
//             controller: _cityController,
//             hint: 'City',
//             icon: Icons.location_city,
//             validator: (v) => v!.isNotEmpty ? null : 'Required',
//           ),
//           const SizedBox(height: 12),

//           _buildField(
//             controller: _stateController,
//             hint: 'State',
//             icon: Icons.map,
//             validator: (v) => v!.isNotEmpty ? null : 'Required',
//           ),
//           const SizedBox(height: 12),

//           _buildField(
//             controller: _countryController,
//             hint: 'Country',
//             icon: Icons.public,
//             validator: (v) => v!.isNotEmpty ? null : 'Required',
//           ),
//           const SizedBox(height: 12),

//           _buildField(
//             controller: _pinCodeController,
//             hint: 'Pincode',
//             icon: Icons.local_post_office,
//             inputType: TextInputType.number,
//             inputFormatters: [
//               FilteringTextInputFormatter.digitsOnly,
//               LengthLimitingTextInputFormatter(6),
//             ],
//             validator: (v) => RegExp(r'^[0-9]{6}$').hasMatch(v ?? '')
//                 ? null
//                 : 'Invalid pincode',
//           ),
//           const SizedBox(height: 24),

//           ButtonWidget(
//             text: _isSaving ? 'Saving...' : 'Continue',
//             onTap: _isSaving ? null : _saveAddress,
//             height: 50,
//             borderRadius: BorderRadius.circular(12),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildField({
//     required TextEditingController controller,
//     required String hint,
//     required IconData icon,
//     TextInputType inputType = TextInputType.text,
//     List<TextInputFormatter>? inputFormatters,
//     String? Function(String?)? validator,
//   }) {
//     return TextFormField(
//       controller: controller,
//       keyboardType: inputType,
//       inputFormatters: inputFormatters,
//       validator: validator,
//       decoration: InputDecoration(
//         hintText: hint,
//         prefixIcon: Icon(icon),
//         filled: true,
//         fillColor: Colors.white,
//         border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:movezy_user_app/Screens/SavedAddress/Models/address_model.dart';
import 'package:movezy_user_app/Screens/SavedAddress/AddressApiService/address_api_service.dart';
import 'package:movezy_user_app/Utils/PermissionsManager/permissions_manager.dart';
import 'package:movezy_user_app/CommonWidgets/button_widget.dart';
import 'package:movezy_user_app/Utils/CustomToast/custome_toast.dart';

class AddAddressScreen extends StatefulWidget {
  final AddressModel? addressToEdit;

  const AddAddressScreen({super.key, this.addressToEdit});

  @override
  State<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _fullNameController;
  late TextEditingController _mobileController;
  late TextEditingController _houseNoController;
  late TextEditingController _areaController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _countryController;
  late TextEditingController _pinCodeController;

  bool _isSaving = false;
  bool _isLoadingLocation = false;

  double _latitude = 0;
  double _longitude = 0;

  String _selectedAddressType = 'Home';
  final List<String> _addressTypes = ['Home', 'Work', 'Other'];

  @override
  void initState() {
    super.initState();

    _fullNameController =
        TextEditingController(text: widget.addressToEdit?.fullName ?? '');
    _mobileController =
        TextEditingController(text: widget.addressToEdit?.mobileNumber ?? '');
    _houseNoController =
        TextEditingController(text: widget.addressToEdit?.houseNo ?? '');
    _areaController =
        TextEditingController(text: widget.addressToEdit?.area ?? '');
    _cityController =
        TextEditingController(text: widget.addressToEdit?.city ?? '');
    _stateController =
        TextEditingController(text: widget.addressToEdit?.state ?? '');
    _countryController =
        TextEditingController(text: widget.addressToEdit?.country ?? '');
  final String initialPin = (widget.addressToEdit != null)
    ? widget.addressToEdit!.pinCode.toString()
    : '';
  _pinCodeController = TextEditingController(text: initialPin);

    if (widget.addressToEdit != null) {
      _selectedAddressType = widget.addressToEdit!.addressType;
      _latitude = widget.addressToEdit!.latitude;
      _longitude = widget.addressToEdit!.longitude;
    } else {
      /// AUTO FETCH LOCATION (OLD LOGIC)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _getLocation();
      });
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _mobileController.dispose();
    _houseNoController.dispose();
    _areaController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _countryController.dispose();
    _pinCodeController.dispose();
    super.dispose();
  }

  /// LOCATION LOGIC (UNCHANGED)
  Future<void> _getLocation() async {
    final hasPermission =
        await PermissionsManager.requestLocationPermission();

    if (!hasPermission) {
      showCustomToast(context, 'Location permission is required');
      return;
    }

    setState(() => _isLoadingLocation = true);

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _isLoadingLocation = false;
      });

      showCustomToast(
        context,
        'Location set (${_latitude.toStringAsFixed(4)}, ${_longitude.toStringAsFixed(4)})',
      );
    } catch (e) {
      setState(() => _isLoadingLocation = false);
      showCustomToast(context, 'Failed to get location');
    }
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) return;

    if (_latitude == 0 && _longitude == 0) {
      showCustomToast(context, 'Location not set');
      return;
    }

    setState(() => _isSaving = true);

    try {
      if (widget.addressToEdit != null) {
        await AddressApiService.updateAddress(
          addressId: widget.addressToEdit!.id ?? '',
          houseNo: _houseNoController.text.trim(),
          area: _areaController.text.trim(),
          city: _cityController.text.trim(),
          state: _stateController.text.trim(),
          pinCode: int.parse(_pinCodeController.text),
          context: context,
        );
      } else {
        await AddressApiService.createAddress(
          fullName: _fullNameController.text.trim(),
          mobileNumber: _mobileController.text.trim(),
          houseNo: _houseNoController.text.trim(),
          area: _areaController.text.trim(),
          city: _cityController.text.trim(),
          state: _stateController.text.trim(),
          country: _countryController.text.trim(),
          pinCode: int.parse(_pinCodeController.text),
          addressType: _selectedAddressType,
          latitude: _latitude,
          longitude: _longitude,
          context: context,
        );
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      showCustomToast(context, 'Failed to save address');
    }

    setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          /// DUMMY MAP
          _dummyMap(size.height * 0.42),

          /// BACK BUTTON
          SafeArea(
            child: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          /// FORM SHEET
          DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.55,
            maxChildSize: 0.9,
            builder: (context, scrollController) {
              return Container(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: _buildForm(scrollController),
              );
            },
          ),
        ],
      ),
    );
  }

  /// DUMMY MAP USING ASSET
  Widget _dummyMap(double height) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/map_iii.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          GestureDetector(
            onTap: _getLocation,
            child: const Icon(
              Icons.location_pin,
              size: 60,
              color: Colors.red,
            ),
          ),
          if (_isLoadingLocation)
            const CircularProgressIndicator(color: Colors.white),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _latitude != 0
                    ? 'Lat: ${_latitude.toStringAsFixed(5)}, '
                        'Lng: ${_longitude.toStringAsFixed(5)}'
                    : 'Fetching current location...',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(ScrollController controller) {
    return Form(
      key: _formKey,
      child: ListView(
        controller: controller,
        children: [
          _buildField(
            controller: _fullNameController,
            hint: 'Full Name',
            icon: Icons.person,
            validator: (v) => v!.length >= 3 ? null : 'Min 3 characters',
          ),
          const SizedBox(height: 12),

          _buildField(
            controller: _mobileController,
            hint: 'Mobile Number',
            icon: Icons.phone,
            inputType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            validator: (v) =>
                RegExp(r'^[0-9]{10}$').hasMatch(v ?? '')
                    ? null
                    : 'Invalid number',
          ),
          const SizedBox(height: 12),

          _buildField(
            controller: _houseNoController,
            hint: 'House No / Flat No',
            icon: Icons.home,
            validator: (v) => v!.isNotEmpty ? null : 'Required',
          ),
          const SizedBox(height: 12),

          _buildField(
            controller: _areaController,
            hint: 'Area / Road Name',
            icon: Icons.location_on,
            validator: (v) => v!.isNotEmpty ? null : 'Required',
          ),
          const SizedBox(height: 12),

          _buildField(
            controller: _cityController,
            hint: 'City',
            icon: Icons.location_city,
            validator: (v) => v!.isNotEmpty ? null : 'Required',
          ),
          const SizedBox(height: 12),

          _buildField(
            controller: _stateController,
            hint: 'State',
            icon: Icons.map,
            validator: (v) => v!.isNotEmpty ? null : 'Required',
          ),
          const SizedBox(height: 12),

          _buildField(
            controller: _countryController,
            hint: 'Country',
            icon: Icons.public,
            validator: (v) => v!.isNotEmpty ? null : 'Required',
          ),
          const SizedBox(height: 12),

          _buildField(
            controller: _pinCodeController,
            hint: 'Pincode',
            icon: Icons.local_post_office,
            inputType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            validator: (v) =>
                RegExp(r'^[0-9]{6}$').hasMatch(v ?? '')
                    ? null
                    : 'Invalid pincode',
          ),
          const SizedBox(height: 24),

          ButtonWidget(
            text: _isSaving ? 'Saving...' : 'Continue',
            onTap: _isSaving ? null : _saveAddress,
            height: 50,
            borderRadius: BorderRadius.circular(12),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType inputType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: inputType,
      inputFormatters: inputFormatters,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
