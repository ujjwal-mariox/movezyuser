# Architecture Diagram - User Profile Integration

## System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     MOVEZY USER APP                             │
└─────────────────────────────────────────────────────────────────┘

                           LOGIN FLOW
                           
┌──────────────────┐     ┌─────────────┐     ┌──────────────┐
│  Login Screen    │────▶│  OTP Screen │────▶│ Location Perm│
│                  │     │             │     │              │
│ - Phone number   │     │ - OTP input │     │ - Permission │
│ - Validation     │     │ - Verify    │     │ - Auto skip  │
└──────────────────┘     └─────────────┘     └──────────────┘
                              │
                              │ ✅ Save Token
                              ▼
                         SharedPreferences
                              │
                         ┌─────────────────┐
                         │ token: "xyz..."│
                         │ userId: "123..." │
                         │ mobile: "798..." │
                         │ check_log_in: t  │
                         └─────────────────┘


                        PROFILE FETCH FLOW
                        
                    ┌──────────────────────────┐
                    │   Profile Screen Init    │
                    │  (StatefulWidget)        │
                    └────────────┬─────────────┘
                                 │
                                 ▼
                    ┌──────────────────────────┐
                    │ _fetchUserProfile()      │
                    │ Called in initState()    │
                    └────────────┬─────────────┘
                                 │
                                 ▼
                    ┌──────────────────────────┐
                    │ ProfileApiService        │
                    │ .getUserProfile()        │
                    └────────────┬─────────────┘
                                 │
                    ┌────────────▼────────────┐
                    │ Get token from Prefs    │
                    │ token = "xyz..."        │
                    └────────────┬────────────┘
                                 │
                    ┌────────────▼────────────────┐
                    │ Build HTTP Headers         │
                    │ Authorization: Bearer xyz..│
                    │ Content-Type: application/ │
                    └────────────┬────────────────┘
                                 │
                    ┌────────────▼────────────────┐
                    │ HTTP GET Request            │
                    │ /user/profile               │
                    │ 103.194.228.68:9050/v1/api  │
                    └────────────┬────────────────┘
                                 │
                                 │ (Network)
                                 ▼
                    ┌──────────────────────────┐
                    │  Backend Server          │
                    │  Validates Token         │
                    │  Fetches User Data       │
                    │  Returns JSON            │
                    └────────────┬─────────────┘
                                 │
                    ┌────────────▼────────────┐
                    │ JSON Response            │
                    │ {                        │
                    │   code: 1,               │
                    │   message: "success",    │
                    │   data: {                │
                    │     _id: "...",          │
                    │     fullName: "...",     │
                    │     email: "...",        │
                    │     profileImage: "..."  │
                    │   }                      │
                    │ }                        │
                    └────────────┬────────────┘
                                 │
                    ┌────────────▼────────────┐
                    │ Parse JSON Response      │
                    │ Create UserData Object   │
                    └────────────┬────────────┘
                                 │
                    ┌────────────▼────────────┐
                    │ Update State:            │
                    │ userData = response.data │
                    │ isLoading = false        │
                    └────────────┬────────────┘
                                 │
                    ┌────────────▼────────────┐
                    │ Rebuild Widget Tree      │
                    └────────────┬────────────┘
                                 │
                                 ▼
                    ┌──────────────────────────┐
                    │  Profile Header          │
                    │  ┌────────────────────┐  │
                    │  │ Profile Image      │  │ ◄─── From userData.profileImage
                    │  │ [Image from S3]    │  │      or fallback asset
                    │  └────────────────────┘  │
                    │                          │
                    │  Name: [userData.full... │ ◄─── From userData.fullName
                    │  Email: test@gmail.com   │ ◄─── From userData.email
                    │  Phone: 7986341518       │ ◄─── From userData.mobileNumber
                    │                          │
                    │  + Add GST Details       │
                    └──────────────────────────┘


## Component Hierarchy

```
ProfileScreen (StatefulWidget)
    │
    ├── State Variables
    │   ├── userData: UserData?
    │   ├── isLoading: bool
    │   └── ProfileApiService instance
    │
    ├── initState()
    │   └── _fetchUserProfile()
    │       └── ProfileApiService.getUserProfile()
    │           ├── Get token from Prefs
    │           ├── Build headers
    │           ├── HTTP GET request
    │           ├── Parse response
    │           └── setState() with data
    │
    ├── build()
    │   ├── if isLoading
    │   │   └── CircularProgressIndicator
    │   └── else
    │       ├── _header(context)
    │       │   ├── Profile Image
    │       │   │   ├── If image URL exists
    │       │   │   │   └── Image.network(url, fallback: asset)
    │       │   │   └── Edit button overlay
    │       │   ├── User Info Column
    │       │   │   ├── Name (userData.fullName ?? "User Name")
    │       │   │   ├── Email (userData.email ?? "No email")
    │       │   │   ├── Phone (userData.mobileNumber ?? "No phone")
    │       │   │   └── GST button
    │       │
    │       ├── _topTwoCards(context)
    │       │   ├── Saved Addresses
    │       │   └── Help & Support
    │       │
    │       ├── _middleList(context)
    │       │   └── Menu items
    │       │
    │       ├── _enterpriseCard(context)
    │       │   └── Enterprise offer
    │       │
    │       └── logoutCard(context)
    │           └── Logout button
    │
    └── dispose()
        └── Cleanup (if needed)


## Data Models

```
UserProfileResponse
    │
    ├── code: int (1 = success)
    ├── message: String
    └── data: UserData
           │
           ├── id (_id): String
           ├── fullName: String
           ├── email: String
           ├── profileImages: String (deprecated)
           ├── gender: String
           ├── dob: String
           ├── countryCode: String
           ├── mobileNumber: String
           ├── isActive: bool
           ├── isDeleted: bool
           ├── notificationAllowed: bool
           ├── createdAt: String
           ├── updatedAt: String
           ├── v (__v): int
           └── profileImage: String (URL)


## Service Layer

```
ProfileApiService
    │
    ├── getUserProfile(BuildContext)
    │   ├── Step 1: Get token from Prefs
    │   │   └── String token = Prefs.getString('token')
    │   │
    │   ├── Step 2: Build headers
    │   │   ├── Content-Type: application/json
    │   │   └── Authorization: Bearer {token}
    │   │
    │   ├── Step 3: Make HTTP GET request
    │   │   └── http.get(url, headers: headers)
    │   │
    │   ├── Step 4: Parse response
    │   │   ├── if statusCode == 200
    │   │   │   └── return UserProfileResponse
    │   │   └── else
    │   │       ├── show toast error
    │   │       └── return null
    │   │
    │   └── Step 5: Handle exceptions
    │       ├── catch all errors
    │       ├── show toast error
    │       └── return null


## SharedPreferences Keys

```
check_log_in: boolean ────────┐
mobile_number: String ────────┼─── Set by: OtpApiService
token: String ────────────────┤    Used by: ProfileApiService
userId: String ───────────────┘
```


## API Communication Flow

```
App                          Backend
 │                              │
 ├─── GET /user/profile ───────▶│
 │    (with Bearer token)       │
 │                              │
 │                    Validate Token
 │                    Query Database
 │                    Find User by ID
 │                    Fetch Profile Data
 │                              │
 │◀─── JSON Response ───────────┤
 │    code: 1                    │
 │    message: "success"         │
 │    data: {...}                │
 │                              │
 └─ Parse & Display ────────────┘
```


## Error Handling Flow

```
getUserProfile()
    │
    ├─ Network Error
    │   └─ Show Toast: "Error fetching profile data"
    │       └─ Return null
    │
    ├─ HTTP 401 (Unauthorized)
    │   └─ Show Toast: message from response
    │       └─ Return null (may need re-login)
    │
    ├─ HTTP 404 (Not Found)
    │   └─ Show Toast: message from response
    │       └─ Return null
    │
    ├─ HTTP 500 (Server Error)
    │   └─ Show Toast: message from response
    │       └─ Return null
    │
    └─ Parse Error
        └─ Show Toast: "Error fetching profile data"
            └─ Return null


## State Management

```
Initial State
    isLoading = true
    userData = null
         │
         ▼ (initState called)
    _fetchUserProfile()
         │
         ▼ (API call)
    Loading State
    isLoading = true
    userData = null
         │
         ▼ (Response received)
    Final State
    isLoading = false
    userData = UserData {...}
         │
         ▼ (Widget rebuild)
    Display UI
```

This architecture ensures:
- ✅ Clean separation of concerns
- ✅ Easy to test
- ✅ Easy to maintain
- ✅ Easy to extend
- ✅ Proper error handling
- ✅ Loading states
- ✅ Null safety
