# Address Management - Quick Testing Guide

## 🚀 Quick Start

### 1. Run the App
```bash
cd /Users/arvindkumar/Desktop/movezy_user_app-main
flutter run
```

### 2. Navigate to Saved Addresses
- Profile Screen → Click "Saved Addresses" card
- Or Search Screen → Click "Saved Addresses" option

---

## 📋 Test Scenarios

### Test 1: Load Addresses
**Expected:** See list of addresses loaded from API with pagination support
```
✓ Addresses load on screen open
✓ Loading indicator shows while fetching
✓ Addresses display correctly
✓ Empty state shows if no addresses exist
```

### Test 2: Create New Address
**Expected:** Add a new address and see it in the list
```
1. Click FAB (+) button
2. Fill in address details:
   - Full Name: "John Doe"
   - Mobile: "9876543210"
   - House No: "Flat 302, A-Block"
   - Area: "Raj Nagar Extension"
   - City: "Ghaziabad"
   - State: "Uttar Pradesh"
   - Country: "India"
   - Pincode: "201309"
   - Address Type: "Home"
3. Click "Save Address"
✓ Toast shows "Address added successfully"
✓ Screen closes and list refreshes
✓ New address appears at top of list
```

### Test 3: Edit Address
**Expected:** Modify address details and save changes
```
1. Click menu (⋮) on any address card
2. Select "Edit"
3. Modify fields (e.g., house number, area)
4. Click "Update Address"
✓ Toast shows "Address updated successfully"
✓ Changes reflect in the list immediately
```

### Test 4: Delete Address
**Expected:** Remove address after confirmation
```
1. Click menu (⋮) on any address card
2. Select "Delete"
3. Confirm deletion in dialog
✓ Toast shows "Address deleted successfully"
✓ Address removed from list
```

### Test 5: Pagination
**Expected:** Load more addresses when scrolling
```
1. Have 10+ addresses
2. Scroll to bottom (80% scroll position)
✓ Loading indicator appears
✓ Next page loads automatically
✓ New addresses appended to list
```

### Test 6: Empty State
**Expected:** Show helpful message when no addresses
```
1. Delete all addresses
✓ Icon, title, and description show
✓ "Add Address" button is clickable
✓ Button opens add address screen
```

---

## 🔍 Debugging Tips

### Check API Response
Add a breakpoint in `address_api_service.dart` and inspect:
```dart
print('📍 DEBUG: Response Body: ${response.body}');
```

### Check Token
Ensure user is logged in and token is saved:
```dart
final token = Prefs.getString('token');
print('📍 Token: $token');
```

### View Logs
```bash
flutter run -v 2>&1 | grep "📍"
```

---

## 🐛 Common Issues & Solutions

### Issue 1: "Please login to continue" message
**Solution:** 
- Ensure you're logged in
- Token should be saved in preferences after login
- Check Prefs.getString('token') is not empty

### Issue 2: "Failed to load addresses"
**Solution:**
- Check internet connection
- Verify API is running on http://103.194.228.68:9050
- Check response status code in logs
- Ensure token is valid (not expired)

### Issue 3: Addresses not showing
**Solution:**
- Check API response format
- Verify backend returns data correctly
- Check AddressListResponse.fromJson() parsing

### Issue 4: Pagination not working
**Solution:**
- Ensure you have 10+ addresses
- Scroll to bottom (80% of list)
- Check totalPages in response

---

## ✅ API Verification Checklist

- [ ] Can create address
- [ ] Can read addresses (paginated)
- [ ] Can update address
- [ ] Can delete address
- [ ] Pagination loads more items
- [ ] Errors handled gracefully
- [ ] Toast messages display correctly
- [ ] Empty state shows when needed

---

## 📊 API Response Examples

### Successful GET Response
```json
{
  "data": [
    {
      "_id": "695081df3a2a1ccc40459c12",
      "fullName": "Rahul Sharma",
      "mobileNumber": "9876543210",
      "houseNo": "Flat 302",
      "area": "Raj Nagar Extension",
      "city": "Ghaziabad",
      "state": "Uttar Pradesh",
      "country": "India",
      "pinCode": 201309,
      "addressType": "Home",
      "latitude": 28.6692,
      "longitude": 77.4538
    }
  ],
  "totalCount": 1,
  "page": 1,
  "limit": 10,
  "totalPages": 1
}
```

### Successful POST Response
```json
{
  "success": true,
  "message": "Address created successfully",
  "data": {
    "_id": "695081df3a2a1ccc40459c13",
    "fullName": "John Doe",
    ...
  }
}
```

### Error Response (401)
```json
{
  "success": false,
  "message": "Unauthorized - Session expired"
}
```

---

## 🎯 Expected Behavior

| Action | Expected Result |
|--------|-----------------|
| Open Saved Addresses | List loads, spinner shows during loading |
| Click Add Button | AddAddressScreen opens |
| Fill form & save | Address created, list refreshes, toast shows |
| Click Edit | Form pre-populates, can modify fields |
| Click Delete | Confirmation dialog, then removes address |
| Scroll to bottom | Auto-loads next page of addresses |
| No addresses | Empty state displays with helpful message |
| Session expired | Redirects to login screen |

---

## 📞 Support

For detailed API documentation, see: `ADDRESS_API_IMPLEMENTATION.md`

For code changes/debugging:
1. Check logs with `flutter run -v`
2. Inspect API responses
3. Verify token and authentication
4. Check internet connection
