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
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:movezy_user_app/Screens/MapPickerScreen/map_picker_screen.dart';
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

  // List-based fields. State/country were free text, so the backend holds
  // whatever was typed ("up", "U.P.", "utter pradesh") and no two addresses
  // agree; a dropdown makes the values canonical.
  String? _selectedState;
  // The design has no country field; records save with India, and a legacy
  // non-India value on an edited address is preserved untouched.
  String _selectedCountry = 'India';
  static const List<String> _indianStates = [
    'Andhra Pradesh', 'Arunachal Pradesh', 'Assam', 'Bihar', 'Chhattisgarh',
    'Goa', 'Gujarat', 'Haryana', 'Himachal Pradesh', 'Jharkhand', 'Karnataka',
    'Kerala', 'Madhya Pradesh', 'Maharashtra', 'Manipur', 'Meghalaya',
    'Mizoram', 'Nagaland', 'Odisha', 'Punjab', 'Rajasthan', 'Sikkim',
    'Tamil Nadu', 'Telangana', 'Tripura', 'Uttar Pradesh', 'Uttarakhand',
    'West Bengal',
    // Union territories
    'Andaman & Nicobar Islands', 'Chandigarh',
    'Dadra & Nagar Haveli and Daman & Diu', 'Delhi', 'Jammu & Kashmir',
    'Ladakh', 'Lakshadweep', 'Puducherry',
  ];

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
      // Match the stored free-text state against the canonical list; an old
      // value that doesn't match cleanly just starts unselected so the user
      // re-picks it once and the record becomes canonical.
      final stored = widget.addressToEdit!.state.trim().toLowerCase();
      for (final s in _indianStates) {
        if (s.toLowerCase() == stored) {
          _selectedState = s;
          break;
        }
      }
      final storedCountry = widget.addressToEdit!.country.trim().toLowerCase();
      if (storedCountry.isNotEmpty && storedCountry != 'india') {
        // Non-India legacy value: keep it selectable rather than crash the
        // dropdown, but the list stays canonical for new entries.
        _selectedCountry = widget.addressToEdit!.country.trim();
      }
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
          fullName: _fullNameController.text.trim(),
          mobileNumber: _mobileController.text.trim(),
          houseNo: _houseNoController.text.trim(),
          area: _areaController.text.trim(),
          city: _cityController.text.trim(),
          state: _selectedState ?? '',
          country: _selectedCountry,
          pinCode: int.parse(_pinCodeController.text),
          addressType: _selectedAddressType,
          // The corrected pin — previously dropped on every edit.
          latitude: _latitude,
          longitude: _longitude,
          context: context,
        );
      } else {
        await AddressApiService.createAddress(
          fullName: _fullNameController.text.trim(),
          mobileNumber: _mobileController.text.trim(),
          houseNo: _houseNoController.text.trim(),
          area: _areaController.text.trim(),
          city: _cityController.text.trim(),
          state: _selectedState ?? '',
          country: _selectedCountry,
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
          _addressMap(size.height * 0.42),

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

  /// Real map preview for the address being saved. Tap to pick the exact spot.
  ///
  /// This was a static `assets/map_iii.png` whose pin only re-read the DEVICE's
  /// GPS, so the saved address's coordinates were wherever the user happened to
  /// be standing — add "Office" from home and every booking to it routed the
  /// driver to your home. The design shows a real map here.
  Widget _addressMap(double height) {
    final hasPoint = _latitude != 0 || _longitude != 0;
    final point = LatLng(
      hasPoint ? _latitude : 28.6139,
      hasPoint ? _longitude : 77.2090,
    );

    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        children: [
          // Preview only — tapping opens the full picker.
          AbsorbPointer(
            child: FlutterMap(
              key: ValueKey('$_latitude,$_longitude'),
              options: MapOptions(
                initialCenter: point,
                initialZoom: hasPoint ? 16 : 11,
                interactionOptions:
                    const InteractionOptions(flags: InteractiveFlag.none),
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.movezy_user_app',
                ),
                if (hasPoint)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: point,
                        width: 44,
                        height: 44,
                        child: const Icon(Icons.location_pin,
                            size: 40, color: Colors.red),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // Tap target over the whole map.
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(onTap: _pickOnMap),
            ),
          ),

          if (_isLoadingLocation)
            const Center(child: CircularProgressIndicator()),

          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: GestureDetector(
              onTap: _pickOnMap,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.edit_location_alt, size: 16),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        hasPoint
                            ? 'Tap to adjust this location on the map'
                            : 'Tap to set this address on the map',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Open the real map picker and store the point the user actually chose.
  Future<void> _pickOnMap() async {
    final result = await Navigator.push<MapPickerResult>(
      context,
      MaterialPageRoute(
        builder: (_) => MapPickerScreen(
          title: 'Set address location',
          initialLocation: (_latitude != 0 || _longitude != 0)
              ? LatLng(_latitude, _longitude)
              : null,
          initialAddress: _areaController.text.isNotEmpty
              ? _areaController.text
              : null,
        ),
      ),
    );
    if (result == null || !mounted) return;

    setState(() {
      _latitude = result.lat;
      _longitude = result.lng;
      // Seed the area field from the picked place if the user hasn't typed one.
      if (_areaController.text.trim().isEmpty) {
        _areaController.text = result.address;
      }
    });
  }

  Widget _buildForm(ScrollController controller) {
    return Form(
      key: _formKey,
      child: ListView(
        controller: controller,
        // With padding:null a ListView silently ADOPTS the ambient MediaQuery
        // vertical padding — which put a status-bar-sized phantom gap at the
        // top of this sheet and left the bottom inset applied only by accident.
        // State it once, explicitly: the real bottom inset, so "Save &
        // Continue" clears the gesture bar / nav buttons at the end of the
        // scroll. (The sheet's own 16px bottom padding is the design's gap and
        // stays.)
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
        children: [
          // ── Field order and grouping per the design: name, house no,
          // apartment/area, mobile, pincode, then City + State side by side.
          _labeled('Full Name', false,
            _buildField(
              controller: _fullNameController,
              hint: 'Your name',
              inputFormatters: [
                // Letters, spaces, dots only — "123" is not a recipient.
                FilteringTextInputFormatter.allow(RegExp(r"[a-zA-Z .'\-]")),
                LengthLimitingTextInputFormatter(50),
              ],
              validator: (v) {
                final s = (v ?? '').trim();
                if (s.length < 3) return 'Enter the full name (min 3 letters)';
                return null;
              },
            ),
          ),

          _labeled('House No', true,
            _buildField(
              controller: _houseNoController,
              hint: 'Your house no',
              inputFormatters: [LengthLimitingTextInputFormatter(40)],
              validator: (v) => (v ?? '').trim().isNotEmpty
                  ? null
                  : 'House / flat no is required',
            ),
          ),

          _labeled('Apartment', false,
            _buildField(
              controller: _areaController,
              hint: 'Apartment, Area, sector, village',
              inputFormatters: [LengthLimitingTextInputFormatter(120)],
              validator: (v) => (v ?? '').trim().length >= 3
                  ? null
                  : 'Enter the apartment / area',
            ),
          ),

          _labeled('Mobile number', false,
            _buildField(
              controller: _mobileController,
              hint: '10-digit mobile number',
              inputType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              validator: (v) {
                final s = v ?? '';
                if (s.length != 10) return 'Mobile number must be 10 digits';
                // Indian mobiles start 6-9; catches typed landlines/junk.
                if (!RegExp(r'^[6-9][0-9]{9}$').hasMatch(s)) {
                  return 'Enter a valid Indian mobile number';
                }
                return null;
              },
            ),
          ),

          _labeled('Pincode', true,
            _buildField(
              controller: _pinCodeController,
              hint: 'e.g. 201306',
              inputType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              validator: (v) {
                final s = v ?? '';
                if (s.length != 6) return 'Pincode must be 6 digits';
                // Indian pincodes never start with 0.
                if (!RegExp(r'^[1-9][0-9]{5}$').hasMatch(s)) {
                  return 'Enter a valid pincode';
                }
                return null;
              },
            ),
          ),

          // City + State share a row, as in the design.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _labeled('City', true,
                  _buildField(
                    controller: _cityController,
                    hint: 'City',
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r"[a-zA-Z .'\-]")),
                      LengthLimitingTextInputFormatter(40),
                    ],
                    validator: (v) => (v ?? '').trim().length >= 2
                        ? null
                        : 'Enter the city',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _labeled('State', true,
                  _buildDropdown<String>(
                    value: _selectedState,
                    hint: 'State',
                    items: _indianStates,
                    onChanged: (v) => setState(() => _selectedState = v),
                    validator: (v) => v == null ? 'Select the state' : null,
                  ),
                ),
              ),
            ],
          ),
          // Country is intentionally not asked (the design has no field for
          // it) — the record still saves with _selectedCountry = 'India'.

          Padding(
            padding: const EdgeInsets.only(top: 2, bottom: 14),
            child: Row(
              children: [
                Icon(Icons.info_outline,
                    size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Please enter the complete address for smooth Pickup',
                    style: TextStyle(
                        fontSize: 11.5, color: Colors.grey.shade600),
                  ),
                ),
              ],
            ),
          ),

          // ── "Save Address As" radio pills (design) ──
          // The state existed but no control ever rendered it, so every saved
          // address silently became "Home". Editing keeps it read-only because
          // the update API doesn't carry addressType.
          const Text('Save Address As',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Row(
            children: _addressTypes.map((t) {
              final active = _selectedAddressType == t;
              final disabled = widget.addressToEdit != null;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                      right: t == _addressTypes.last ? 0 : 10),
                  child: InkWell(
                    onTap: disabled
                        ? null
                        : () => setState(() => _selectedAddressType = t),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: active
                              ? const Color(0xFFFF6200)
                              : const Color(0xFFE0E0E0),
                          width: active ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: active
                                    ? const Color(0xFFFF6200)
                                    : Colors.black45,
                                width: 1.6,
                              ),
                            ),
                            child: active
                                ? Center(
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Color(0xFFFF6200),
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 7),
                          Flexible(
                            child: Text(
                              t,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: active
                                    ? const Color(0xFFFF6200)
                                    : Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          ButtonWidget(
            text: _isSaving ? 'Saving...' : 'Save & Continue',
            onTap: _isSaving ? null : _saveAddress,
            height: 50,
            borderRadius: BorderRadius.circular(12),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  /// Small grey label above a field, with an optional required asterisk —
  /// the design labels every input this way instead of relying on hints.
  Widget _labeled(String label, bool required, Widget child) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              text: label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade700),
              children: [
                if (required)
                  const TextSpan(
                      text: ' *',
                      style: TextStyle(color: Color(0xFFFF6200))),
              ],
            ),
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    IconData? icon,
    TextInputType inputType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: inputType,
      inputFormatters: inputFormatters,
      validator: validator,
      // Errors show as the user leaves a field, not only on Continue.
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 14, color: Colors.grey.shade400),
        prefixIcon: icon != null ? Icon(icon) : null,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T? value,
    required String hint,
    IconData? icon,
    required List<T> items,
    required ValueChanged<T?> onChanged,
    String? Function(T?)? validator,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      hint: Text(hint,
          style: TextStyle(fontSize: 15, color: Colors.grey.shade600)),
      items: items
          .map((e) => DropdownMenuItem<T>(
                value: e,
                child: Text('$e', overflow: TextOverflow.ellipsis),
              ))
          .toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        prefixIcon: icon != null ? Icon(icon) : null,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
