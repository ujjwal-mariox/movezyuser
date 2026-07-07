// import 'package:flutter/material.dart';
// import 'package:movezy_user_app/Screens/SavedAddress/Models/address_model.dart';
// import 'package:movezy_user_app/Screens/SavedAddress/AddressApiService/address_api_service.dart';
// import 'package:movezy_user_app/Screens/SavedAddress/add_address_screen.dart';
// import 'package:movezy_user_app/CommonWidgets/button_widget.dart';

// class SavedAddressScreen extends StatefulWidget {
//   const SavedAddressScreen({super.key});

//   @override
//   State<SavedAddressScreen> createState() => _SavedAddressScreenState();
// }

// class _SavedAddressScreenState extends State<SavedAddressScreen> {
//   final ScrollController _scrollController = ScrollController();
//   final List<AddressModel> _addresses = [];
//   int _currentPage = 1;
//   final int _pageSize = 10;
//   int _totalPages = 1;
//   bool _isLoading = false;
//   bool _hasMoreData = true;

//   @override
//   void initState() {
//     super.initState();
//     _scrollController.addListener(_onScroll);
//     // Delay loading to ensure proper context initialization
//     Future.delayed(const Duration(milliseconds: 100), () {
//       if (mounted) {
//         _loadAddresses();
//       }
//     });
//   }

//   @override
//   void dispose() {
//     _scrollController.dispose();
//     super.dispose();
//   }

//   void _onScroll() {
//     // Check if we're near the bottom (80% of the scroll)
//     if (_scrollController.position.pixels >=
//         _scrollController.position.maxScrollExtent * 0.8) {
//       if (_hasMoreData && !_isLoading && _currentPage < _totalPages) {
//         _loadMoreAddresses();
//       }
//     }
//   }

//   Future<void> _loadAddresses() async {
//     if (_isLoading) return;

//     setState(() => _isLoading = true);
//     print('📍 SavedAddress: Loading page $_currentPage...');

//     final response = await AddressApiService.getAddresses(
//       page: _currentPage,
//       limit: _pageSize,
//       context: context,
//     );

//     if (!mounted) return;

//     print('📍 SavedAddress: Response = $response');
    
//     if (response != null) {
//       print('📍 SavedAddress: Got ${response.addresses.length} addresses');
//       setState(() {
//         _addresses.clear();
//         _addresses.addAll(response.addresses);
//         _totalPages = response.totalPages;
//         _hasMoreData = _currentPage < _totalPages;
//       });
//     } else {
//       print('📍 SavedAddress: Response is null');
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Failed to load addresses')),
//       );
//     }

//     if (mounted) {
//       setState(() => _isLoading = false);
//     }
//   }

//   Future<void> _loadMoreAddresses() async {
//     if (_isLoading || !_hasMoreData) return;

//     setState(() => _isLoading = true);
//     _currentPage++;

//     final response = await AddressApiService.getAddresses(
//       page: _currentPage,
//       limit: _pageSize,
//       context: context,
//     );

//     if (response != null) {
//       setState(() {
//         _addresses.addAll(response.addresses);
//         _totalPages = response.totalPages;
//         _hasMoreData = _currentPage < _totalPages;
//       });
//     } else {
//       // Revert page number if request fails
//       _currentPage--;
//     }

//     setState(() => _isLoading = false);
//   }

//   Future<void> _deleteAddress(String addressId, int index) async {
//     // Show confirmation dialog
//     final confirm = await showDialog<bool>(
//       context: context,
//       builder: (dialogContext) => AlertDialog(
//         title: const Text('Delete Address'),
//         content: const Text('Are you sure you want to delete this address?'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(dialogContext, false),
//             child: const Text('Cancel'),
//           ),
//           TextButton(
//             onPressed: () => Navigator.pop(dialogContext, true),
//             child: const Text('Delete', style: TextStyle(color: Colors.red)),
//           ),
//         ],
//       ),
//     );

//     if (confirm == true && mounted) {
//       final success = await AddressApiService.deleteAddress(
//         addressId: addressId,
//         context: context,
//       );

//       if (success && mounted) {
//         setState(() {
//           _addresses.removeAt(index);
//         });
//       }
//     }
//   }

//   Future<void> _editAddress(AddressModel address) async {
//     final result = await Navigator.push<bool>(
//       context,
//       MaterialPageRoute(
//         builder: (context) => AddAddressScreen(addressToEdit: address),
//       ),
//     );

//     if (result == true) {
//       _currentPage = 1;
//       _loadAddresses();
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Saved Addresses'),
//         centerTitle: true,
//         elevation: 0,
//       ),
//       body: _addresses.isEmpty && !_isLoading
//           ? _buildEmptyState()
//           : ListView.builder(
//               controller: _scrollController,
//               padding: const EdgeInsets.all(16),
//               itemCount: _addresses.length + (_isLoading && _addresses.isNotEmpty ? 1 : 0),
//               itemBuilder: (context, index) {
//                 // Show loading indicator at the bottom when paginating
//                 if (index == _addresses.length) {
//                   return Center(
//                     child: Padding(
//                       padding: const EdgeInsets.symmetric(vertical: 16),
//                       child: SizedBox(
//                         height: 40,
//                         width: 40,
//                         child: CircularProgressIndicator(
//                           strokeWidth: 2,
//                           valueColor: AlwaysStoppedAnimation<Color>(
//                             Theme.of(context).primaryColor,
//                           ),
//                         ),
//                       ),
//                     ),
//                   );
//                 }

//                 final address = _addresses[index];
//                 return _buildAddressCard(address, index);
//               },
//             ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () async {
//           final result = await Navigator.push<bool>(
//             context,
//             MaterialPageRoute(builder: (context) => const AddAddressScreen()),
//           );

//           if (result == true) {
//             _currentPage = 1;
//             _loadAddresses();
//           }
//         },
//         child: const Icon(Icons.add),
//       ),
//     );
//   }

//   Widget _buildEmptyState() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(
//             Icons.location_off,
//             size: 64,
//             color: Colors.grey[400],
//           ),
//           const SizedBox(height: 16),
//           Text(
//             'No Addresses Found',
//             style: TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.w600,
//               color: Colors.grey[700],
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             'Add your first address to get started',
//             style: TextStyle(
//               fontSize: 14,
//               color: Colors.grey[600],
//             ),
//           ),
//           const SizedBox(height: 24),
//           ButtonWidget(
//             text: 'Add Address',
//             height: 50,
//             borderRadius: BorderRadius.circular(8),
//             onTap: () async {
//               final result = await Navigator.push<bool>(
//                 context,
//                 MaterialPageRoute(builder: (context) => const AddAddressScreen()),
//               );

//               if (result == true) {
//                 _currentPage = 1;
//                 _loadAddresses();
//               }
//             },
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildAddressCard(AddressModel address, int index) {
//     return Card(
//       margin: const EdgeInsets.only(bottom: 12),
//       elevation: 1,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Header with address type badge
//             Row(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         address.fullName,
//                         style: const TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.bold,
//                         ),
//                         maxLines: 1,
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                       const SizedBox(height: 4),
//                       Container(
//                         padding: const EdgeInsets.symmetric(
//                           horizontal: 8,
//                           vertical: 4,
//                         ),
//                         decoration: BoxDecoration(
//                           color: _getAddressTypeColor(address.addressType),
//                           borderRadius: BorderRadius.circular(4),
//                         ),
//                         child: Text(
//                           address.addressType,
//                           style: const TextStyle(
//                             fontSize: 12,
//                             color: Colors.white,
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 // Action buttons
//                 PopupMenuButton<String>(
//                   onSelected: (value) {
//                     if (value == 'edit') {
//                       _editAddress(address);
//                     } else if (value == 'delete') {
//                       _deleteAddress(address.id ?? '', index);
//                     }
//                   },
//                   itemBuilder: (BuildContext context) => [
//                     const PopupMenuItem(
//                       value: 'edit',
//                       child: Row(
//                         children: [
//                           Icon(Icons.edit, size: 18),
//                           SizedBox(width: 8),
//                           Text('Edit'),
//                         ],
//                       ),
//                     ),
//                     const PopupMenuItem(
//                       value: 'delete',
//                       child: Row(
//                         children: [
//                           Icon(Icons.delete, size: 18, color: Colors.red),
//                           SizedBox(width: 8),
//                           Text('Delete', style: TextStyle(color: Colors.red)),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//             const SizedBox(height: 12),
//             // Address details
//             _buildAddressDetail('Name', address.fullName),
//             _buildAddressDetail('Phone', address.mobileNumber),
//             _buildAddressDetail('Address', _formatAddress(address)),
//             _buildAddressDetail('City', address.city),
//             _buildAddressDetail('Pincode', address.pinCode.toString()),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildAddressDetail(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 8),
//       child: Row(
//         children: [
//           SizedBox(
//             width: 80,
//             child: Text(
//               label,
//               style: const TextStyle(
//                 fontSize: 13,
//                 color: Colors.grey,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//           ),
//           Expanded(
//             child: Text(
//               value,
//               style: const TextStyle(
//                 fontSize: 13,
//                 fontWeight: FontWeight.w500,
//               ),
//               maxLines: 2,
//               overflow: TextOverflow.ellipsis,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   String _formatAddress(AddressModel address) {
//     final parts = [
//       address.houseNo.isNotEmpty ? address.houseNo : null,
//       address.area.isNotEmpty ? address.area : null,
//       address.state.isNotEmpty ? address.state : null,
//       address.country.isNotEmpty ? address.country : null,
//     ].whereType<String>().toList();
//     return parts.join(', ');
//   }

//   Color _getAddressTypeColor(String type) {
//     switch (type.toLowerCase()) {
//       case 'home':
//         return Colors.blue;
//       case 'work':
//         return Colors.orange;
//       case 'other':
//         return Colors.grey;
//       default:
//         return Colors.blueGrey;
//     }
//   }
// }


import 'package:flutter/material.dart';
import 'package:movezy_user_app/Screens/SavedAddress/Models/address_model.dart';
import 'package:movezy_user_app/Screens/SavedAddress/AddressApiService/address_api_service.dart';
import 'package:movezy_user_app/Screens/SavedAddress/add_address_screen.dart';
import 'package:movezy_user_app/CommonWidgets/button_widget.dart';

class SavedAddressScreen extends StatefulWidget {
  const SavedAddressScreen({super.key});

  @override
  State<SavedAddressScreen> createState() => _SavedAddressScreenState();
}

class _SavedAddressScreenState extends State<SavedAddressScreen> {
  final ScrollController _scrollController = ScrollController();
  final List<AddressModel> _addresses = [];

  int _currentPage = 1;
  final int _pageSize = 10;
  int _totalPages = 1;
  bool _isLoading = false;
  bool _hasMoreData = true;

  String? _selectedAddressId;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadAddresses();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      if (_hasMoreData && !_isLoading && _currentPage < _totalPages) {
        _loadMoreAddresses();
      }
    }
  }

  Future<void> _loadAddresses() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    final response = await AddressApiService.getAddresses(
      page: _currentPage,
      limit: _pageSize,
      context: context,
    );

    if (!mounted) return;

    if (response != null) {
      setState(() {
        _addresses.clear();
        _addresses.addAll(response.addresses);
        _totalPages = response.totalPages;
        _hasMoreData = _currentPage < _totalPages;

        if (_addresses.isNotEmpty) {
          _selectedAddressId ??= _addresses.first.id;
        }
      });
    }

    setState(() => _isLoading = false);
  }

  Future<void> _loadMoreAddresses() async {
    if (_isLoading || !_hasMoreData) return;

    setState(() => _isLoading = true);
    _currentPage++;

    final response = await AddressApiService.getAddresses(
      page: _currentPage,
      limit: _pageSize,
      context: context,
    );

    if (response != null) {
      setState(() {
        _addresses.addAll(response.addresses);
        _totalPages = response.totalPages;
        _hasMoreData = _currentPage < _totalPages;
      });
    } else {
      _currentPage--;
    }

    setState(() => _isLoading = false);
  }

  Future<void> _deleteAddress(String addressId, int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Address'),
        content: const Text('Are you sure you want to delete this address?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final success = await AddressApiService.deleteAddress(
        addressId: addressId,
        context: context,
      );

      if (success) {
        setState(() {
          _addresses.removeAt(index);
        });
      }
    }
  }

  Future<void> _editAddress(AddressModel address) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddAddressScreen(addressToEdit: address),
      ),
    );

    if (result == true) {
      _currentPage = 1;
      _loadAddresses();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.orange,
        title: const Text('Saved Addresses'),
        centerTitle: true,
        leading: const BackButton(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: _addresses.isEmpty && !_isLoading
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _addresses.length +
                        (_isLoading && _addresses.isNotEmpty ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _addresses.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      return _buildAddressCard(_addresses[index], index);
                    },
                  ),
          ),

          /// BOTTOM BUTTON (FIGMA STYLE)
          Padding(
            padding: const EdgeInsets.all(16),
            child: ButtonWidget(
              text: 'Add New Address',
              height: 50,
              borderRadius: BorderRadius.circular(12),
              onTap: () async {
                final result = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AddAddressScreen(),
                  ),
                );

                if (result == true) {
                  _currentPage = 1;
                  _loadAddresses();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard(AddressModel address, int index) {
    final isSelected = _selectedAddressId == address.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? Colors.orange : Colors.grey.shade300,
        ),
        color: Colors.white,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// RADIO BUTTON
          GestureDetector(
            onTap: () {
              setState(() => _selectedAddressId = address.id);
            },
            child: Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
              color: isSelected ? Colors.orange : Colors.grey,
            ),
          ),
          const SizedBox(width: 12),

          /// ADDRESS CONTENT
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${address.fullName} (${address.addressType})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _formatAddress(address),
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 6),
                Text(
                  address.mobileNumber,
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),

          /// ACTION ICONS
          Column(
            children: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                onPressed: () => _editAddress(address),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () =>
                    _deleteAddress(address.id ?? '', index),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.location_off, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No Addresses Found',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 8),
          Text(
            'Add your first address to get started',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  String _formatAddress(AddressModel address) {
    final parts = [
      address.houseNo,
      address.area,
      address.city,
      address.state,
      address.country,
      address.pinCode.toString(),
    ].where((e) => e.isNotEmpty).toList();

    return parts.join(', ');
  }
}
