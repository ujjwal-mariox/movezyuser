# 📊 Address Management - API Flow Diagrams

## 1. Overall Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        MOVEZY USER APP                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │              SavedAddressScreen (UI)                     │  │
│  │  ├─ Load addresses on init                              │  │
│  │  ├─ Pagination on scroll                                │  │
│  │  ├─ Add/Edit/Delete actions                             │  │
│  │  └─ Show loading & error states                         │  │
│  └──────────────────────────────────────────────────────────┘  │
│                          ↓↑                                     │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │         AddressApiService (Business Logic)               │  │
│  │  ├─ getAddresses() - Fetch with pagination              │  │
│  │  ├─ createAddress() - Create new                        │  │
│  │  ├─ updateAddress() - Update existing                   │  │
│  │  ├─ deleteAddress() - Remove                            │  │
│  │  └─ getAllAddresses() - Fetch all                       │  │
│  └──────────────────────────────────────────────────────────┘  │
│                          ↓↑                                     │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │          Models (Data Serialization)                     │  │
│  │  ├─ AddressModel                                         │  │
│  │  ├─ AddressListResponse                                 │  │
│  │  └─ AddressResponse                                     │  │
│  └──────────────────────────────────────────────────────────┘  │
│                          ↓↑                                     │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │         HTTP Client (http package)                       │  │
│  │  ├─ GET requests                                         │  │
│  │  ├─ POST requests                                        │  │
│  │  ├─ PUT requests                                         │  │
│  │  └─ DELETE requests                                      │  │
│  └──────────────────────────────────────────────────────────┘  │
│                          ↓↑                                     │
└─────────────────────────────────────────────────────────────────┘
                          ↓↑
┌─────────────────────────────────────────────────────────────────┐
│                    BACKEND API                                  │
│    http://103.194.228.68:9050/v1/api                            │
├─────────────────────────────────────────────────────────────────┤
│  ├─ GET /user/address?page={p}&limit={l}                       │
│  ├─ POST /user/address                                          │
│  ├─ PUT /user/address/{id}                                      │
│  └─ DELETE /user/address/{id}                                   │
└─────────────────────────────────────────────────────────────────┘
                          ↓↑
┌─────────────────────────────────────────────────────────────────┐
│                    DATABASE                                     │
│    Addresses Collection / Table                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 2. GET - Fetch Addresses Flow

```
┌──────────────────┐
│  User opens app  │
└────────┬─────────┘
         │
         ↓
┌──────────────────────────────┐
│ SavedAddressScreen.initState  │
│ Calls _loadAddresses()        │
└────────┬─────────────────────┘
         │
         ↓
┌──────────────────────────────────────────────┐
│ AddressApiService.getAddresses()             │
│  • Get token from preferences                 │
│  • Build URL: /user/address?page=1&limit=10 │
│  • Add Authorization header                   │
│  • Send GET request                           │
└────────┬─────────────────────────────────────┘
         │
         ↓
┌──────────────────────────────────────────────┐
│ Backend API (http.get)                       │
│  Query database for addresses               │
│  Apply pagination                            │
│  Return 200 response                         │
└────────┬─────────────────────────────────────┘
         │
         ↓
┌──────────────────────────────────────────────┐
│ AddressListResponse.fromJson()               │
│  Parse response JSON                         │
│  Extract addresses array                     │
│  Extract pagination metadata                 │
│  Create AddressListResponse object           │
└────────┬─────────────────────────────────────┘
         │
         ↓
┌──────────────────────────────────────────────┐
│ SavedAddressScreen.setState()                │
│  Update _addresses list                      │
│  Update pagination vars                      │
│  Rebuild ListView                            │
└────────┬─────────────────────────────────────┘
         │
         ↓
┌──────────────────────────────────┐
│ Display addresses in list         │
│ Show loading indicator (if more)  │
└──────────────────────────────────┘
```

**Pagination Load More:**
```
User scrolls 80% ↓
    ↓
Check _hasMoreData && !_isLoading
    ↓
_currentPage++ (2, 3, 4...)
    ↓
Call getAddresses(page=2, limit=10)
    ↓
Append new addresses to list
    ↓
Continue scrolling...
```

---

## 3. POST - Create Address Flow

```
┌──────────────────────┐
│ User clicks FAB (+)  │
│ Opens AddressScreen  │
└────────┬─────────────┘
         │
         ↓
┌──────────────────────────────────┐
│ User fills form fields:          │
│  • fullName                       │
│  • mobileNumber                   │
│  • houseNo, area, city, etc       │
│  • addressType (Home/Work/Other)  │
│  • latitude, longitude            │
└────────┬─────────────────────────┘
         │
         ↓
┌──────────────────────┐
│ User clicks "Save"   │
│ Validate all fields  │
└────────┬─────────────┘
         │
         ↓
┌────────────────────────────────────────────────┐
│ AddressApiService.createAddress()              │
│  • Sanitize all string inputs                   │
│  • Get token from preferences                   │
│  • Build request body with all fields           │
│  • Send POST to /user/address                   │
└────────┬───────────────────────────────────────┘
         │
         ↓
┌────────────────────────────────────────────────┐
│ Backend API (http.post)                        │
│  • Validate required fields                     │
│  • Check authentication                         │
│  • Create address in database                   │
│  • Return 201 with created address              │
└────────┬───────────────────────────────────────┘
         │
         ↓
┌────────────────────────────────────────────────┐
│ AddressResponse.fromJson()                     │
│  • Parse response                               │
│  • Extract created address data                 │
│  • Extract success message                      │
└────────┬───────────────────────────────────────┘
         │
         ↓
┌────────────────────────────────────────────────┐
│ Show Toast: "Address added successfully"       │
│ Close AddressScreen                            │
│ Return to SavedAddressScreen                   │
└────────┬───────────────────────────────────────┘
         │
         ↓
┌────────────────────────────────────────────────┐
│ Reload addresses list                          │
│ _currentPage = 1                               │
│ Call _loadAddresses() again                    │
└────────┬───────────────────────────────────────┘
         │
         ↓
┌──────────────────────┐
│ New address visible  │
│ in the list          │
└──────────────────────┘
```

---

## 4. PUT - Update Address Flow

```
┌──────────────────────────────────┐
│ User clicks Edit on address card │
└────────┬─────────────────────────┘
         │
         ↓
┌──────────────────────────────────────┐
│ AddAddressScreen opens in Edit mode   │
│ Fields pre-populated with data        │
│ • houseNo, area, city, state, pinCode│
└────────┬──────────────────────────────┘
         │
         ↓
┌──────────────────────┐
│ User modifies fields │
└────────┬─────────────┘
         │
         ↓
┌──────────────────────┐
│ User clicks "Update" │
│ Validate fields      │
└────────┬─────────────┘
         │
         ↓
┌────────────────────────────────────────────────┐
│ AddressApiService.updateAddress()              │
│  • Get addressId                                │
│  • Sanitize inputs (only updatable fields)     │
│  • Get token                                    │
│  • Send PUT to /user/address/{id}              │
│  • Body: { houseNo, area, city, state, pinCode}│
└────────┬───────────────────────────────────────┘
         │
         ↓
┌────────────────────────────────────────────────┐
│ Backend API (http.put)                         │
│  • Find address by ID                           │
│  • Update only allowed fields                   │
│  • Save to database                             │
│  • Return 200 with updated address              │
└────────┬───────────────────────────────────────┘
         │
         ↓
┌────────────────────────────────────────────────┐
│ AddressResponse.fromJson()                     │
│  • Parse updated address                        │
└────────┬───────────────────────────────────────┘
         │
         ↓
┌────────────────────────────────────────────────┐
│ Show Toast: "Address updated successfully"     │
│ Close AddAddressScreen                         │
│ Reload addresses in SavedAddressScreen         │
└────────┬───────────────────────────────────────┘
         │
         ↓
┌──────────────────────────┐
│ Updated address visible  │
│ with new details         │
└──────────────────────────┘
```

---

## 5. DELETE - Remove Address Flow

```
┌────────────────────────────────────┐
│ User clicks Delete button on card   │
│ (Menu ⋮ → Delete)                   │
└────────┬─────────────────────────────┘
         │
         ↓
┌────────────────────────────────────┐
│ Show Confirmation Dialog            │
│ "Are you sure?"                     │
│ [Cancel]  [Delete]                  │
└────────┬─────────────────────────────┘
         │
         ↓
    User confirms
         │
         ↓
┌────────────────────────────────────┐
│ AddressApiService.deleteAddress()   │
│  • Get addressId                     │
│  • Get token                         │
│  • Send DELETE to /user/address/{id} │
└────────┬─────────────────────────────┘
         │
         ↓
┌────────────────────────────────────┐
│ Backend API (http.delete)           │
│  • Find address by ID                │
│  • Remove from database              │
│  • Return 200 success                │
└────────┬─────────────────────────────┘
         │
         ↓
┌────────────────────────────────────┐
│ Check response status               │
│ Return bool success                 │
└────────┬─────────────────────────────┘
         │
         ↓
┌────────────────────────────────────┐
│ If success:                         │
│  • Show Toast: "Address deleted"    │
│  • Remove from _addresses list      │
│  • Update UI immediately            │
└────────┬─────────────────────────────┘
         │
         ↓
┌──────────────────────┐
│ Address disappears   │
│ from list            │
└──────────────────────┘
```

---

## 6. Error Handling Flow

```
Any API Call
    ↓
    ├─→ Network Error
    │   ↓
    │   Show: "Error: [exception message]"
    │   Return: null / false
    │
    ├─→ Status 401 (Unauthorized)
    │   ↓
    │   Show: "Session expired. Please login again"
    │   Return: null / false
    │   (User can navigate to login)
    │
    ├─→ Status 4xx/5xx
    │   ↓
    │   Parse error message from response
    │   Show: error['message']
    │   Return: null / false
    │
    ├─→ JSON Parse Error
    │   ↓
    │   Show: "Error: Failed to parse response"
    │   Return: null / false
    │
    └─→ Status 200/201 ✓
        ↓
        Parse response JSON
        Create model objects
        Return success
```

---

## 7. Data Flow Summary

```
┌─────────────────────────────────────────────────────────────────────┐
│                         DATA TRANSFORMATION                         │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  Dart Objects          ↔        JSON String        ↔      API     │
│  ─────────────────     ↔     ────────────────      ↔     ─────    │
│                        ↔                            ↔             │
│  AddressModel          ↔  {fullName, ...}          ↔  Database   │
│  AddressListResponse   ↔  {data: [...], ...}       ↔             │
│  AddressResponse       ↔  {success, data, ...}     ↔             │
│                        ↔                            ↔             │
│        Dart            ↔      HTTP Body             ↔   Backend   │
│      (Type-safe)       ↔   (Text Payload)          ↔             │
│                        ↔                            ↔             │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 8. Pagination Detail Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                      PAGINATION SYSTEM                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Request Parameters:                                            │
│  ├─ page: Current page (1, 2, 3, ...)                          │
│  └─ limit: Items per page (default: 10)                        │
│                                                                 │
│  URL: /user/address?page=1&limit=10                            │
│                                                                 │
│  Response Metadata:                                             │
│  ├─ totalCount: Total addresses in system                      │
│  ├─ page: Current page returned                                │
│  ├─ limit: Items per page                                      │
│  ├─ totalPages: Total pages (totalCount / limit)               │
│  └─ data: Array of addresses                                   │
│                                                                 │
│  Example:                                                       │
│  ├─ totalCount: 25 addresses                                   │
│  ├─ page: 1                                                     │
│  ├─ limit: 10                                                   │
│  ├─ totalPages: 3                                               │
│  └─ data: [10 items]                                            │
│                                                                 │
│  Second Request (Scroll to 80%):                               │
│  ├─ URL: /user/address?page=2&limit=10                        │
│  └─ data: [10 more items]                                      │
│                                                                 │
│  Third Request (Scroll more):                                  │
│  ├─ URL: /user/address?page=3&limit=10                        │
│  └─ data: [5 remaining items]                                  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 9. Authentication Flow

```
┌─────────────────────────────────────┐
│   User Logs In                      │
│   (LoginScreen → Backend)           │
└────────┬────────────────────────────┘
         │
         ↓
┌─────────────────────────────────────┐
│   Backend returns:                  │
│   {                                 │
│     "token": "jwt_token_string",   │
│     "user": {...}                   │
│   }                                 │
└────────┬────────────────────────────┘
         │
         ↓
┌─────────────────────────────────────┐
│   Preferences Manager               │
│   Prefs.setString('token', token)   │
└────────┬────────────────────────────┘
         │
         ↓
┌─────────────────────────────────────┐
│   Any API Call                      │
│   Get token: Prefs.getString('token')│
│   Check if empty                    │
└────────┬────────────────────────────┘
         │
    ┌────┴─────┐
    ↓          ↓
Empty?        Has Token?
  │               │
  ↓               ↓
 "Login"    Add to Header:
 Toast     "Authorization: Bearer {token}"
           │
           ↓
        Send Request
```

---

## 10. State Management Flow

```
SavedAddressScreen State Variables
│
├─ _addresses: List<AddressModel>
│  └─ Updates: load/add/edit/delete operations
│
├─ _currentPage: int = 1
│  └─ Updates: pagination (increment on scroll)
│
├─ _totalPages: int = 1
│  └─ Updates: from API response metadata
│
├─ _isLoading: bool = false
│  └─ Updates: during API calls
│
└─ _hasMoreData: bool = true
   └─ Updates: when _currentPage >= _totalPages

Trigger Updates:
├─ initState() → _loadAddresses()
├─ FAB Click → Navigator → Return result → _loadAddresses()
├─ Edit → Navigator → Return result → _loadAddresses()
├─ Delete → Confirm → API → setState() remove
└─ Scroll → _onScroll() → _loadMoreAddresses()
```

---

These diagrams show the complete flow of address management operations from user interaction through API calls to database operations and back to the UI.

For detailed code implementation, see: **ADDRESS_API_IMPLEMENTATION.md**
