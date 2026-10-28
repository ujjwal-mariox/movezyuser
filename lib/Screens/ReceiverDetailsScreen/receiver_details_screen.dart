import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:movezy_user_app/AppNavigation/app_navigation.dart';
import 'package:movezy_user_app/CommonWidgets/location_icon.dart';
import 'package:movezy_user_app/Screens/HomeScreen/Model/booking_data.dart';
import 'package:movezy_user_app/Screens/ProfileScreen/ProfileApiService/profile_api_service.dart';
import 'package:movezy_user_app/Screens/ReviewBookingScreen/review_booking_screen.dart';
import 'package:movezy_user_app/Screens/SavedAddress/AddressApiService/address_api_service.dart';
import 'package:movezy_user_app/Utils/AppColors/app_colors.dart';
import 'package:movezy_user_app/Utils/CustomToast/custome_toast.dart';
import 'package:movezy_user_app/Utils/PrefsManager/prefs_manager.dart';

/// What the receiver step hands back to the screen that opened it.
class ReceiverDetailsResult {
  /// The customer tapped Change on the drop address: the opener should reopen
  /// the location editor (a new drop can change prices and vehicles).
  final bool changeDrop;
  final String name;
  final String phone;

  const ReceiverDetailsResult({
    this.changeDrop = false,
    required this.name,
    required this.phone,
  });
}

/// "Who receives the goods" — its own step after the vehicle is chosen, not
/// one field among many on checkout (client feedback). Shows the drop on the
/// map with the address, then the receiver's name and number, a shortcut to
/// use the customer's own number, and an optional "Save as" for the drop.
///
/// Both receiver fields are optional (client decision): left blank, the
/// customer is the contact at the drop. A number, when given, must be a valid
/// 10-digit mobile — the backend texts it when the parcel is picked up.
///
/// [editOnly] is the checkout's "Edit": the same screen, but Confirm returns
/// the details instead of opening checkout, and the drop can't be changed
/// from here (that would invalidate the quote the checkout is showing).
class ReceiverDetailsScreen extends StatefulWidget {
  final BookingData bookingData;
  final bool editOnly;

  const ReceiverDetailsScreen({
    super.key,
    required this.bookingData,
    this.editOnly = false,
  });

  @override
  State<ReceiverDetailsScreen> createState() => _ReceiverDetailsScreenState();
}

class _ReceiverDetailsScreenState extends State<ReceiverDetailsScreen> {
  static const _linkBlue = Color(0xFF1668E3);
  static const _saveAsOptions = [
    ['Home', Icons.home_outlined],
    ['Work', Icons.work_outline],
    ['Other', Icons.favorite_border],
  ];

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  String _ownName = '';
  String _ownPhone = '';
  bool _useMyNumber = false;
  String? _phoneError;

  /// Hidden when the drop is already one of the customer's saved addresses.
  bool _canSaveAddress = true;
  String? _saveAs;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.bookingData.receiverName ?? '';
    _phoneController.text = widget.bookingData.receiverPhone ?? '';
    _ownPhone = _tenDigits(Prefs.getString('mobile_number'));
    _useMyNumber =
        _ownPhone.isNotEmpty && _phoneController.text.trim() == _ownPhone;
    // Kept on the shared BookingData as they're typed, so backing out to the
    // vehicle list and returning (or tapping Change) never loses them.
    _nameController.addListener(() =>
        widget.bookingData.receiverName = _nameController.text.trim());
    _phoneController.addListener(() =>
        widget.bookingData.receiverPhone = _phoneController.text.trim());
    _loadProfile();
    _checkAlreadySaved();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  String _tenDigits(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    return digits.length >= 10 ? digits.substring(digits.length - 10) : '';
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await ProfileApiService().getUserProfile();
      if (!mounted) return;
      setState(() {
        _ownName = profile.data.fullName.trim();
        final phone = _tenDigits(profile.data.mobileNumber);
        if (phone.isNotEmpty) _ownPhone = phone;
      });
    } catch (_) {
      // The number from login is enough for the shortcut; the name is a nicety.
    }
  }

  /// No "Save as" for a drop that is already saved (picked from the list, or
  /// the same spot entered again) — saving it twice only clutters the list.
  Future<void> _checkAlreadySaved() async {
    final lat = widget.bookingData.dropLat;
    final lng = widget.bookingData.dropLng;
    if (lat == null || lng == null) {
      setState(() => _canSaveAddress = false);
      return;
    }
    final saved = await AddressApiService.getAllAddresses(context: context);
    if (!mounted) return;
    final match = saved.any((a) =>
        Geolocator.distanceBetween(lat, lng, a.latitude, a.longitude) < 75);
    if (match) setState(() => _canSaveAddress = false);
  }

  void _toggleUseMyNumber(bool? value) {
    final on = value ?? false;
    setState(() {
      _useMyNumber = on;
      _phoneError = null;
      if (on) {
        _phoneController.text = _ownPhone;
        if (_nameController.text.trim().isEmpty && _ownName.isNotEmpty) {
          _nameController.text = _ownName;
        }
      } else {
        if (_phoneController.text.trim() == _ownPhone) _phoneController.clear();
        if (_nameController.text.trim() == _ownName) _nameController.clear();
      }
    });
  }

  String? _validatePhone(String phone) {
    if (phone.isEmpty) return null;
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(phone)) {
      return 'Enter a valid 10-digit mobile number';
    }
    return null;
  }

  Future<void> _confirm() async {
    if (_submitting) return;
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final error = _validatePhone(phone);
    if (error != null) {
      setState(() => _phoneError = error);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _submitting = true);
    try {
      if (_saveAs != null && _canSaveAddress) {
        final saved = await _saveDropAddress(name, phone);
        if (saved && mounted) setState(() => _canSaveAddress = false);
      }
      if (!mounted) return;
      widget.bookingData.receiverName = name;
      widget.bookingData.receiverPhone = phone;
      if (widget.editOnly) {
        Navigator.pop(context, ReceiverDetailsResult(name: name, phone: phone));
      } else {
        await pushTo(
          context,
          ReviewBookingScreen(
            bookingData: widget.bookingData.copyWith(
              receiverName: name,
              receiverPhone: phone,
            ),
          ),
        );
        // Back from checkout: the drop may have been saved meanwhile (here
        // or from checkout's Edit), so offering "Save as" again would
        // create a duplicate.
        if (mounted && _canSaveAddress) {
          setState(() => _saveAs = null);
          await _checkAlreadySaved();
        }
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  /// Saves the drop to Saved Addresses under the chosen label. The address API
  /// needs city / state / PIN as separate fields, which the drop only has as
  /// text, so they come from a reverse geocode of the pin (OSM Nominatim, the
  /// same service the map search uses). If that can't produce them the booking
  /// carries on and the customer is told to add it from Saved Addresses.
  Future<bool> _saveDropAddress(String name, String phone) async {
    final lat = widget.bookingData.dropLat!;
    final lng = widget.bookingData.dropLng!;
    final text = widget.bookingData.dropAddress ?? '';
    Map<String, dynamic> a = {};
    // The public geocoder occasionally drops a request; one retry after a
    // second (its rate limit) recovers that without a visible wait.
    for (var attempt = 0; attempt < 2 && a.isEmpty; attempt++) {
      if (attempt > 0) await Future.delayed(const Duration(seconds: 1));
      try {
        final res = await http.get(
          Uri.parse('https://nominatim.openstreetmap.org/reverse'
              '?format=jsonv2&addressdetails=1&lat=$lat&lon=$lng'),
          headers: {'User-Agent': 'MovezyApp/1.0', 'Accept-Language': 'en'},
        ).timeout(const Duration(seconds: 10));
        if (res.statusCode == 200) {
          final body = json.decode(res.body);
          if (body is Map && body['address'] is Map) {
            a = Map<String, dynamic>.from(body['address'] as Map);
          }
        }
      } catch (_) {}
    }

    String pick(List<String> keys) {
      for (final k in keys) {
        final v = (a[k] ?? '').toString().trim();
        if (v.isNotEmpty) return v;
      }
      return '';
    }

    final parts = text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final postcode = pick(['postcode']).replaceAll(RegExp(r'\D'), '');
    final pin = int.tryParse(postcode.length == 6
        ? postcode
        : (RegExp(r'\b\d{6}\b').firstMatch(text)?.group(0) ?? ''));
    final state = pick(['state']);
    final city = pick(['city', 'town', 'village', 'county', 'state_district']);
    if (pin == null || state.isEmpty || city.isEmpty) {
      if (mounted) {
        showCustomToast(context,
            "Couldn't save this address automatically. Add it from Saved Addresses.");
      }
      return false;
    }
    final building = [pick(['house_number']), pick(['building', 'amenity', 'shop', 'road'])]
        .where((s) => s.isNotEmpty)
        .join(' ');
    final houseNo = building.isNotEmpty
        ? building
        : (parts.isNotEmpty ? parts.first : city);
    final areaPick = pick(['suburb', 'neighbourhood', 'quarter', 'road']);
    final area = areaPick.isNotEmpty
        ? areaPick
        : (parts.length > 1 ? parts[1] : city);
    final contactPhone = phone.isNotEmpty ? phone : _ownPhone;
    if (!mounted || contactPhone.isEmpty) return false;
    final saved = await AddressApiService.createAddress(
      fullName: name.isNotEmpty ? name : (_ownName.isNotEmpty ? _ownName : 'Me'),
      mobileNumber: contactPhone,
      houseNo: houseNo,
      area: area,
      city: city,
      state: state,
      country: 'India',
      pinCode: pin,
      addressType: _saveAs!,
      latitude: lat,
      longitude: lng,
      context: context,
    );
    return saved != null;
  }

  void _changeDrop() {
    Navigator.pop(
      context,
      ReceiverDetailsResult(
        changeDrop: true,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: keyboardOpen ? 140 : size.height * 0.36,
            child: _mapHeader(),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _addressCard(),
                  const SizedBox(height: 20),
                  Text('Receiver details',
                      style: GoogleFonts.poppins(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(
                    "Optional. We'll text them when the parcel is on its way. "
                    'Leave blank if you will receive it yourself.',
                    style: GoogleFonts.poppins(
                        fontSize: 11.5, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    style: GoogleFonts.poppins(fontSize: 14),
                    decoration: _fieldDecoration(
                      "Receiver's name",
                      icon: Icons.person_outline,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: GoogleFonts.poppins(fontSize: 14),
                    onChanged: (v) => setState(() {
                      _phoneError = null;
                      _useMyNumber = _ownPhone.isNotEmpty && v.trim() == _ownPhone;
                    }),
                    decoration: _fieldDecoration(
                      "Receiver's mobile number",
                      icon: Icons.phone_outlined,
                    ).copyWith(counterText: '', errorText: _phoneError),
                  ),
                  if (_ownPhone.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: () => _toggleUseMyNumber(!_useMyNumber),
                      child: Row(
                        children: [
                          Checkbox(
                            value: _useMyNumber,
                            onChanged: _toggleUseMyNumber,
                            activeColor: AppColors.appColor,
                            visualDensity: VisualDensity.compact,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4)),
                          ),
                          Expanded(
                            child: Text.rich(TextSpan(children: [
                              TextSpan(
                                  text: 'Use my mobile number : ',
                                  style: GoogleFonts.poppins(fontSize: 13)),
                              TextSpan(
                                  text: _ownPhone,
                                  style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600)),
                            ])),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (_canSaveAddress) ...[
                    const SizedBox(height: 14),
                    Text('Save as (optional):',
                        style: GoogleFonts.poppins(
                            fontSize: 13, color: Colors.grey.shade700)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final o in _saveAsOptions)
                          _saveAsChip(o[0] as String, o[1] as IconData),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottomInset),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.appColor,
                  disabledBackgroundColor: Colors.grey.shade400,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _submitting ? null : _confirm,
                child: _submitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white),
                      )
                    : Text(
                        widget.editOnly
                            ? 'Save receiver details'
                            : 'Confirm and proceed',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// The drop on the map, with the pin and its caption. Not interactive: the
  /// place is changed through Change, which re-prices the trip.
  Widget _mapHeader() {
    final lat = widget.bookingData.dropLat;
    final lng = widget.bookingData.dropLng;
    return Stack(
      children: [
        Positioned.fill(
          child: lat == null || lng == null
              ? Container(color: Colors.grey.shade200)
              : FlutterMap(
                  options: MapOptions(
                    initialCenter: LatLng(lat, lng),
                    initialZoom: 16,
                    interactionOptions:
                        const InteractionOptions(flags: InteractiveFlag.none),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.movezy_user_app',
                      maxZoom: 19,
                    ),
                  ],
                ),
        ),
        if (lat != null && lng != null)
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF14233B),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('Your goods will be delivered here',
                        style: GoogleFonts.poppins(
                            fontSize: 11.5,
                            color: Colors.white,
                            fontWeight: FontWeight.w500)),
                  ),
                  Icon(Icons.location_on, size: 44, color: AppColors.appColor),
                ],
              ),
            ),
          ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Material(
              color: Colors.white,
              shape: const CircleBorder(),
              elevation: 3,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => Navigator.pop(context),
                child: const Padding(
                  padding: EdgeInsets.all(9),
                  child: Icon(Icons.arrow_back, size: 22, color: Colors.black87),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _addressCard() {
    final address = (widget.bookingData.dropAddress ?? '').trim();
    final comma = address.indexOf(',');
    final title = comma > 0 ? address.substring(0, comma).trim() : address;
    final rest = comma > 0 ? address.substring(comma + 1).trim() : '';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          const LocationIcon.drop(size: AppIconSize.md),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title.isEmpty ? 'Drop location' : title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                if (rest.isNotEmpty)
                  Text(rest,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ),
          if (!widget.editOnly) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _submitting ? null : _changeDrop,
              child: Text('Change',
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _linkBlue)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _saveAsChip(String label, IconData icon) {
    final selected = _saveAs == label;
    final color = selected ? AppColors.appColor : Colors.black87;
    return GestureDetector(
      onTap: () => setState(() => _saveAs = selected ? null : label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.appColor.withValues(alpha: 0.08)
              : Colors.white,
          border: Border.all(
            color: selected ? AppColors.appColor : const Color(0xFFE1E6EF),
            width: selected ? 1.4 : 1,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 12.5, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(String hint, {required IconData icon}) {
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: c, width: w),
        );
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.grey),
      prefixIcon: Icon(icon, size: 20, color: Colors.grey.shade600),
      border: border(Colors.grey.shade300),
      enabledBorder: border(Colors.grey.shade300),
      focusedBorder: border(AppColors.appColor, 1.4),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      isDense: true,
    );
  }
}
