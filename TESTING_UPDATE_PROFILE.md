# 🧪 Update Profile Feature - Testing Guide

## Quick Start Testing

### Prerequisites
- App built and running on Android emulator
- Logged in with valid phone number (e.g., 7986341518)
- OTP verified (123456)
- Location permission granted
- Profile data loaded

## Test Scenario 1: Basic Update

### Steps
1. **Open app** → Navigate to **Profile** tab
2. **Tap Edit Profile** button (pencil icon in top-right)
3. **You should see:**
   - Screen title: "Update Profile"
   - Back button: `<`
   - Form fields pre-filled with current data:
     - Full Name: [existing name]
     - Email: [existing email]
     - Gender: [selected or empty]
     - DOB: [existing or empty]

### Update the Data
4. **Clear Full Name field**
5. **Type new name:** `John Doe`
6. **Clear Email field**
7. **Type new email:** `john.doe@example.com`
8. **Select Gender:** Tap dropdown → Select "Male"
9. **Select DOB:**
   - Tap DOB field
   - Calendar opens
   - Scroll to May 1990
   - Tap day 15
   - Should show: `15-05-1990`

### Save Changes
10. **Tap "Save Changes" button**
11. **Expected:**
    - Button shows "Updating..." text
    - Button is disabled (greyed out)
    - Loading indicator spins
    - After 2-3 seconds: Success toast appears
    - Screen returns to Profile
    - Profile header shows: "John Doe"

### Verify Update
12. **On Profile Screen:**
    - Name changed to: `John Doe`
    - Email changed to: `john.doe@example.com`
    - Data persisted correctly

**Status:** ✅ PASS if all steps work

---

## Test Scenario 2: Partial Update

### Steps
1. **Edit Profile again**
2. **Change only the Full Name:**
   - Clear field
   - Type: `Jane Smith`
3. **Leave Email as is** (don't change)
4. **Leave Gender as is** (don't change)
5. **Leave DOB as is** (don't change)
6. **Tap Save Changes**
7. **Verify:**
   - Only Full Name updated on server
   - Email/Gender/DOB remain unchanged

**Status:** ✅ PASS if name updated, others unchanged

---

## Test Scenario 3: Validation Check

### Steps
1. **Edit Profile**
2. **Clear Full Name field** (make it empty)
3. **Type in Email field** (to ensure something is entered)
4. **Tap Save Changes**
5. **Expected:**
   - Form validation error appears
   - Toast or SnackBar: "Full Name is required"
   - Form does NOT submit
   - User stays on Update Profile screen

**Status:** ✅ PASS if validation error shown

---

## Test Scenario 4: Gender Selection

### Steps
1. **Edit Profile**
2. **Tap Gender dropdown**
3. **Should see 3 options:**
   - Male
   - Female
   - Other
4. **Select different gender** (e.g., "Female")
5. **Selected value shows in field**
6. **Save changes**
7. **Verify:** Gender updated on Profile screen

**Status:** ✅ PASS if all options visible and selection works

---

## Test Scenario 5: Date Picker

### Steps
1. **Edit Profile**
2. **Tap DOB field**
3. **Calendar picker opens**
4. **Should show:**
   - Current month/year
   - All dates 1-31
   - Navigation arrows for month/year
5. **Select a date:**
   - Tap day 25
   - Calendar closes
   - Field shows: `25-MM-YYYY` (with actual month/year)
6. **Save changes**
7. **Verify:** DOB shows on Profile screen

**Status:** ✅ PASS if calendar works and date formats correctly

---

## Test Scenario 6: Back Button

### Steps
1. **Edit Profile**
2. **Change Full Name** (e.g., to "Test User")
3. **Tap back button `<`** (without saving)
4. **Expected:**
   - Returns to Profile screen
   - Name is still the PREVIOUS value
   - Changes NOT saved

**Status:** ✅ PASS if back button discards changes

---

## Test Scenario 7: Network Error

### Steps
1. **Turn off WiFi/data on emulator**
2. **Edit Profile**
3. **Make changes**
4. **Tap Save Changes**
5. **Expected:**
   - Wait 3-5 seconds
   - Error toast: "Error updating profile"
   - Form remains on screen
   - User can tap back or try again

**Status:** ✅ PASS if error handled gracefully

---

## Test Scenario 8: Empty Optional Fields

### Steps
1. **Edit Profile**
2. **Clear Email field** (make empty)
3. **Clear Gender dropdown** (make empty)
4. **Keep Full Name filled**
5. **Tap Save Changes**
6. **Expected:**
   - Saves successfully
   - Toast shows success
   - Returns to Profile
   - Email shows default (not available) or blank
   - Gender not displayed

**Status:** ✅ PASS if empty optional fields saved

---

## Test Scenario 9: Special Characters

### Steps
1. **Edit Profile**
2. **Full Name:** `José García-López`
3. **Email:** `jose.garcia+test@example.co.uk`
4. **Tap Save Changes**
5. **Expected:**
   - Saves successfully
   - Special characters preserved
   - Accents work correctly

**Status:** ✅ PASS if special characters handled

---

## Test Scenario 10: Multiple Updates

### Steps
1. **Edit Profile → Change Name to "User1" → Save**
2. **Wait 2 seconds → Profile refreshes**
3. **Edit Profile → Change Email to "user1@test.com" → Save**
4. **Wait 2 seconds → Profile refreshes**
5. **Edit Profile → Change Gender to "Other" → Save**
6. **Expected:**
   - All three updates applied
   - No conflicts
   - Latest data displayed

**Status:** ✅ PASS if sequential updates work

---

## UI Element Checklist

### Update Profile Screen Elements

- [ ] **Header**
  - Back button `<`
  - Title "Update Profile"
  - Orange background (#E96D2D)

- [ ] **Full Name Field**
  - Labeled "Full Name"
  - Text input
  - Pre-filled with current name
  - Keyboard: Default

- [ ] **Email Field**
  - Labeled "Email"
  - Text input
  - Pre-filled with current email
  - Keyboard: Email

- [ ] **Gender Dropdown**
  - Labeled "Gender"
  - Dropdown button
  - Shows: Male, Female, Other
  - Pre-selected if set

- [ ] **DOB Field**
  - Labeled "Date of Birth"
  - Read-only (opens date picker)
  - Format: DD-MM-YYYY
  - Pre-filled if set

- [ ] **Save Button**
  - Text: "Save Changes"
  - Orange background
  - Full width
  - At bottom

- [ ] **Loading State**
  - Button text: "Updating..."
  - Button disabled
  - Loading spinner visible

---

## Response Monitoring

### Check API Calls in Logcat

```bash
adb logcat | grep "UpdateProfile"
```

### Expected Log Messages

```
[UpdateProfileApiService] Starting profile update...
[UpdateProfileApiService] Token retrieved: eyJ...
[UpdateProfileApiService] API Response: 200 - success
[ProfileScreen] Profile refreshed after update
```

### Error Logs

```
[UpdateProfileApiService] API Error: 401 Unauthorized
[UpdateProfileApiService] Network Error: SocketException
[UpdateProfileApiService] No token found in SharedPreferences
```

---

## Browser DevTools (if using web)

### Network Tab
- Watch the PUT request to `/user/profile`
- Check request headers: `Authorization: Bearer {token}`
- Check request body: JSON with updated fields
- Check response status: 200
- Check response body: `{"code": 1, "message": "success"}`

### Console Tab
- Watch for any JavaScript errors
- Check for API error messages
- Verify no network warnings

---

## Common Issues & Troubleshooting

| Issue | Cause | Solution |
|-------|-------|----------|
| Form fields empty | userData not passed | Check UpdateProfileScreen constructor |
| Save button doesn't work | No token in SharedPreferences | Re-login and verify token saved |
| API error 401 | Expired token | Re-login with new OTP |
| Date picker doesn't open | Dependency missing | Ensure intl package in pubspec.yaml |
| Gender dropdown empty | Hard-coded values missing | Check _buildGenderDropdown() method |
| Changes not persisted | API returned error | Check logcat for error message |
| Loading state stuck | API call hanging | Check network connection |

---

## Success Criteria

✅ **All tests PASS** if:
1. Form pre-fills with current data
2. All fields can be edited
3. Save works and returns success
4. Profile screen refreshes with new data
5. Validation prevents empty name
6. Back button discards changes
7. Gender dropdown shows 3 options
8. Date picker formats correctly
9. Optional fields can be empty
10. Error messages shown on failure

---

## Notes

- Token must be valid (obtained from OTP verification)
- API endpoint: `http://103.194.228.68:9050/v1/api/user/profile`
- HTTP Method: PUT
- Content-Type: application/json
- Each update overwrites previous values
- Server-side validation on email format
- DOB format must be DD-MM-YYYY

---

## Reporting Bugs

If a test fails:
1. **Screenshot** the error
2. **Check logcat** for error messages
3. **Note the steps** to reproduce
4. **Record expected vs actual** behavior
5. **Report with:** Device, Android version, exact error message
