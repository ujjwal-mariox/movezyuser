class AddressModel {
  final String? id;
  final String fullName;
  final String mobileNumber;
  final String houseNo;
  final String area;
  final String city;
  final String state;
  final String country;
  final int pinCode;
  final String addressType; // Home, Work, Other
  final double latitude;
  final double longitude;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  AddressModel({
    this.id,
    required this.fullName,
    required this.mobileNumber,
    required this.houseNo,
    required this.area,
    required this.city,
    required this.state,
    required this.country,
    required this.pinCode,
    required this.addressType,
    required this.latitude,
    required this.longitude,
    this.createdAt,
    this.updatedAt,
  });

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'mobileNumber': mobileNumber,
      'houseNo': houseNo,
      'area': area,
      'city': city,
      'state': state,
      'country': country,
      'pinCode': pinCode,
      'addressType': addressType,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  // Convert to JSON for update (partial)
  Map<String, dynamic> toJsonForUpdate() {
    return {
      'houseNo': houseNo,
      'area': area,
      'city': city,
      'state': state,
      'pinCode': pinCode,
    };
  }

  // Create from JSON — tolerant of string/num variations from the backend.
  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: (json['_id'] ?? json['id'])?.toString(),
      fullName: _sanitizeString(json['fullName'] ?? ''),
      mobileNumber: _sanitizeString(json['mobileNumber'] ?? ''),
      houseNo: _sanitizeString(json['houseNo'] ?? ''),
      area: _sanitizeString(json['area'] ?? ''),
      city: _sanitizeString(json['city'] ?? ''),
      state: _sanitizeString(json['state'] ?? ''),
      country: _sanitizeString(json['country'] ?? ''),
      pinCode: _toInt(json['pinCode']),
      addressType: _sanitizeString(json['addressType'] ?? 'Home'),
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
      createdAt: _tryDate(json['createdAt']),
      updatedAt: _tryDate(json['updatedAt']),
    );
  }

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  static DateTime? _tryDate(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }

  // Sanitize string: trim, remove extra spaces, capitalize properly
  static String _sanitizeString(dynamic value) {
    if (value == null) return '';
    String str = value.toString().trim();
    // Remove multiple consecutive spaces
    str = str.replaceAll(RegExp(r'\s+'), ' ');
    return str;
  }

  // Copy with method
  AddressModel copyWith({
    String? id,
    String? fullName,
    String? mobileNumber,
    String? houseNo,
    String? area,
    String? city,
    String? state,
    String? country,
    int? pinCode,
    String? addressType,
    double? latitude,
    double? longitude,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AddressModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      houseNo: houseNo ?? this.houseNo,
      area: area ?? this.area,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      pinCode: pinCode ?? this.pinCode,
      addressType: addressType ?? this.addressType,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'AddressModel(id: $id, fullName: $fullName, city: $city, addressType: $addressType)';
  }
}

class AddressListResponse {
  final List<AddressModel> addresses;
  final int totalCount;
  final int page;
  final int limit;
  final int totalPages;

  AddressListResponse({
    required this.addresses,
    required this.totalCount,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  factory AddressListResponse.fromJson(Map<String, dynamic> json) {
    // Find the list of address maps no matter how the backend nests it.
    // The user API uses a {code, message, data:{...}} envelope, and list
    // endpoints put the array under an entity key (e.g. data.addresses).
    final List<AddressModel> addresses = _extractAddressList(json);

    // Pagination may live at the top level or under `data`.
    final Map paginationSource =
        (json['data'] is Map) ? json['data'] as Map : json;

    final int total = (paginationSource['total'] ??
            paginationSource['totalCount'] ??
            json['totalCount'] ??
            addresses.length) as int;
    final int limit =
        (paginationSource['limit'] ?? json['limit'] ?? 10) as int;

    return AddressListResponse(
      addresses: addresses,
      totalCount: total,
      page: (paginationSource['page'] ?? json['page'] ?? 1) as int,
      limit: limit,
      totalPages: (paginationSource['totalPages'] ??
          (limit > 0 ? (total / limit).ceil() : 1)) as int,
    );
  }

  /// Recursively locate the first list of address-shaped maps in the payload,
  /// tolerating {data:{addresses:[...]}}, {data:[...]}, {addresses:[...]},
  /// {data:{data:[...]}}, {data:{items/results/list:[...]}}, or a bare list.
  static List<AddressModel> _extractAddressList(dynamic node, {int depth = 0}) {
    if (depth > 4 || node == null) return [];

    // A list of maps → parse each as an address.
    if (node is List) {
      return node
          .whereType<Map>()
          .map((e) => AddressModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    if (node is Map) {
      // Prefer well-known keys that hold the array.
      for (final key in ['addresses', 'data', 'items', 'results', 'list', 'docs']) {
        final v = node[key];
        if (v is List) {
          return _extractAddressList(v, depth: depth + 1);
        }
      }
      // Otherwise descend into any nested map/list once.
      for (final v in node.values) {
        if (v is Map || v is List) {
          final found = _extractAddressList(v, depth: depth + 1);
          if (found.isNotEmpty) return found;
        }
      }
    }
    return [];
  }
}

class AddressResponse {
  final bool success;
  final String message;
  final AddressModel? data;

  AddressResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory AddressResponse.fromJson(Map<String, dynamic> json) {
    return AddressResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? AddressModel.fromJson(json['data']) : null,
    );
  }
}
