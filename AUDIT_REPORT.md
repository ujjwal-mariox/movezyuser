# Movezy User App — End-to-End Audit Report

**Date:** 2025  
**Scope:** `lib/` directory — 87 Dart files across Services, Screens, CommonWidgets, Utils, Routes  
**Backend API Base:** `https://movize-backend.maidkart.in/v1/api`

---

## Executive Summary

| Metric | Count |
|--------|-------|
| Total Dart files | 87 |
| Screens with **real API** integration | ~22 |
| Screens that are **hardcoded mockups** | ~12 |
| TODO/FIXME comments | 2 |
| Socket.io integration | ❌ None |
| Firebase / FCM push notifications | ❌ None |
| Google Maps SDK | ❌ None (uses OpenStreetMap via `flutter_map`) |
| Razorpay integration | ✅ Active (test key) |
| SavedAddressScreen (old) | ❌ Entirely commented out |
| Unused API endpoints | ~3 |

**Overall Readiness:** The core delivery booking flow (Home → Search → Category → Vehicle → Review → Payment → Tracking → Completion) is **fully functional with real APIs**. However, roughly a dozen screens remain as **hardcoded UI prototypes** from an earlier multimodal/ride-hailing concept. Real-time tracking uses HTTP polling (no WebSocket), and push notifications are absent.

---

## 1. Authentication & Onboarding ✅

| File | Lines | Status |
|------|-------|--------|
| `SplashScreen/splash_screen.dart` | ~100 | ✅ Real |
| `SplashScreen/Controller.dart` | — | GetX controller for splash |
| `SplashScreen/SplashBinding.dart` | — | GetX binding |
| `LoginScreen/login_screen.dart` | ~300 | ✅ Real |
| `LoginScreen/LoginApiService/login_api_service.dart` | — | ✅ API service |
| `LoginScreen/Model/login_response.dart` | — | Model |
| `OtpScreen/otp_screen.dart` | ~250 | ✅ Real |
| `OtpScreen/OtpApiService/otp_api_service.dart` | — | ✅ API service |
| `OtpScreen/Model/otp_response.dart` | — | Model |
| `LocationPermissionScreen/location_permission_screen.dart` | — | ✅ Real |

**Details:**
- Phone-based OTP login via real backend APIs (`/auth/login`, `/auth/verify-otp`)
- Token stored in `SharedPreferences` via `PrefsManager`
- Splash checks `check_log_in` pref → routes to `DashboardScreen` or `LoginScreen`
- Location permission request handled before first use
- **No biometric, social login, or email/password auth**

**Issues:** None critical.

---

## 2. Home & Navigation ✅

| File | Lines | Status |
|------|-------|--------|
| `DashboardScreen/dashboard_screen.dart` | ~120 | ✅ Real |
| `HomeScreen/home_screen.dart` | 1298 | ✅ Real |
| `HomeScreen/Service/home_api_service.dart` | — | ✅ API |
| `HomeScreen/Model/home_page_model.dart` | — | Model |
| `HomeScreen/Model/booking_data.dart` | — | Model |
| `HomeScreen/Widgets/morning_dialogs.dart` | — | Widget |

**Details:**
- `DashboardScreen` = bottom nav with 5 tabs: Home, History, Coins, Wallet, Profile (via `IndexedStack`)
- `HomeScreen` fetches vehicle types + promo banners from `HomeApiService`, wallet balance from `WalletService`, GST status
- Map uses `FlutterMap` with OpenStreetMap tiles + dummy nearby vehicle markers (hardcoded positions near user)
- Dynamic vehicle grid from backend with fallback to static assets
- PromoCode carousel from API data
- Service type selection sheet (Within City / Outstation)
- `WidgetsBindingObserver` refreshes data on app resume

**Issues:**
- ⚠️ Nearby vehicle markers are randomly generated around user location (not real driver positions)
- ⚠️ "Outstation" service type navigates to same SearchScreen — no differentiated flow

---

## 3. Address / Location Selection ✅

| File | Lines | Status |
|------|-------|--------|
| `SearchScreen/search_screen.dart` | 696 | ✅ Real |
| `MapPickerScreen/map_picker_screen.dart` | 515 | ✅ Real |

**Details:**
- `SearchScreen` = pickup/drop entry with map picker integration, GPS current location, recent deliveries (real API), reorder from past booking, popular places (static), saved addresses link
- `MapPickerScreen` = full-screen OpenStreetMap with center-pin selection, search via **Nominatim** (OSM geocoding, free, no key), reverse geocoding on map drag, GPS location button
- Geocoding fallback: if coordinates not obtained via map, forward geocodes the text address

**Issues:**
- ⚠️ "Add Stop" button visible but non-functional (no multi-stop support)
- ⚠️ Popular places list is static (hardcoded Railway Station, Airport, etc.)
- ⚠️ Nominatim has strict usage policy (1 req/sec) — no debounce rate limiting beyond 500ms

---

## 4. Saved Addresses ⚠️

| File | Lines | Status |
|------|-------|--------|
| `SavedAddress/saved_address_screen.dart` | 735 | ❌ **Entirely commented out** |
| `SavedAddress/saved_address.dart` | 758 | ✅ Real (new version at line 436+) |
| `SavedAddress/add_address_screen.dart` | — | ✅ Real |
| `SavedAddress/Models/address_model.dart` | — | Model |
| `SavedAddress/AddressApiService/address_api_service.dart` | — | ✅ API service |

**Details:**
- The file `saved_address_screen.dart` is **100% commented out** — an older version
- The file `saved_address.dart` contains the working replacement (class `SavedAddressScreen` starts at line 436)
- Uses `AddressApiService` with real backend API (`/user/address`)
- CRUD: list (paginated), add, edit, delete
- Models: `AddressModel` with label, full address, lat/lng, type (Home/Work/Other)

**Issues:**
- ⚠️ Two files with overlapping purpose — `saved_address_screen.dart` should be deleted
- ⚠️ First ~430 lines of `saved_address.dart` are also commented-out old code

---

## 5. Booking Flow ✅

| File | Lines | Status |
|------|-------|--------|
| `DeliveryCategoryScreen/delivery_category_screen.dart` | ~250 | ✅ Real API |
| `VehicleSelectionScreen/vehicle_selection_screen.dart` | ~500 | ✅ Real API |
| `LoadAssistScreen/load_assist_screen.dart` | ~290 | ✅ Static (pass-through) |
| `ReviewBookingScreen/review_booking_screen.dart` | 1966 | ✅ Real API |
| `Services/booking_service.dart` | 630 | ✅ Full API service |

**Flow:** Home → Search → DeliveryCategory → VehicleSelection → LoadAssist → ReviewBooking

**Details:**
- `DeliveryCategoryScreen` fetches goods types from `BookingService.getGoodsTypes()`, filters vehicles by allowed types
- `VehicleSelectionScreen` fetches vehicle options with fares from `BookingService.getVehicleOptions()`, auto-selects recommended option
- `LoadAssistScreen` collects goods type (Business/Personal) and weight range — UI only, no API call
- `ReviewBookingScreen` is the most complex screen (1966 lines):
  - Parallel API calls: fare estimate, addons, promos, wallet balance
  - Payment methods: CASH, WALLET, ONLINE (Razorpay)
  - Promo code apply/remove with validation
  - GST input for invoicing
  - Prohibited items sheet, booking terms sheet
  - Creates booking via `BookingService.createBooking()`
  - Razorpay for online payment + wallet recharge if insufficient
  - Navigates to `RideFindingScreen` on success

**Issues:**
- ⚠️ `LoadAssistScreen` weight logic shows same "1 Partner" regardless of weight selection
- ⚠️ Razorpay key is **test key** (`rzp_test_SEYGtmd4CbElON`) — needs production key before launch

---

## 6. Live Tracking & Trip Details ⚠️

| File | Lines | Status |
|------|-------|--------|
| `RideFindingScreen/ride_finding_screen.dart` | ~300 | ✅ Real API |
| `TripDetailsScreen/trip_details_screen.dart` | 1187 | ✅ Real API |
| `CancelRideScreen/cancel_ride_screen.dart` | ~280 | ✅ Real API |
| `RideCanceledSuccessScreen/ride_canceled_success_screen.dart` | ~120 | ✅ Static success |
| `CommonWidgets/order_status_timeline.dart` | 208 | ✅ Real widget |

**Details:**
- `RideFindingScreen` polls `BookingService.trackBooking()` every **5 seconds**. On ASSIGNED/DRIVER_ARRIVED/PICKED/IN_PROGRESS → navigates to `TripDetailsScreen`. On CANCELLED → DashboardScreen.
- `TripDetailsScreen` (1187 lines) polls every **10 seconds**:
  - Real driver name, vehicle info, OTP, ETA from API
  - Order status timeline (5 steps: Confirmed → Assigned → On the way → In-transit → Delivered)
  - **Delay detection** banner (compares current time vs expected arrival)
  - Payment section with fare, coins earned
  - Cancel booking button (only for SEARCHING/ASSIGNED/DRIVER_ARRIVED)
  - Share trip, contact support, consignment note download
  - Auto-navigates to `DeliveryCompleteScreen` on COMPLETED, `RideCanceledSuccessScreen` on CANCELLED
- `CancelRideScreen` fetches cancellation reasons from API with fallback hardcoded list

**Issues:**
- ❌ **No real-time tracking** — uses HTTP polling only, no Socket.io/WebSocket
- ❌ **No driver location on map** — TripDetailsScreen shows status text only, no live map
- ⚠️ TODO at line 601: "Add stop" not implemented
- ⚠️ TODO at line 654: "View details" not implemented
- ⚠️ "Contact Support" shows snackbar only — no actual call/chat integration

---

## 7. Post-Delivery ✅

| File | Lines | Status |
|------|-------|--------|
| `DeliveryCompleteScreen/delivery_complete_screen.dart` | ~400 | ✅ Real API |

**Details:**
- Rating (1-5 stars) with `BookingService.rateBooking()` 
- Feedback tags (On time, Good packaging, Polite driver, Neat vehicle, etc.)
- Optional comment field
- Coins earned display
- Navigates to DashboardScreen

**Issues:** None.

---

## 8. Payment ✅ (core) / ❌ (standalone screens)

| File | Lines | Status |
|------|-------|--------|
| `Services/wallet_service.dart` | ~200 | ✅ Real API + Razorpay |
| `RechangeWalletApp/recharge_wallet_screen.dart` | 425 | ✅ Real API + Razorpay |
| `ReviewBookingScreen` (payment section) | — | ✅ Real Razorpay |
| `PaymentScreen/payment_screen.dart` | ~250 | ❌ **Hardcoded mockup** |
| `UpiCheckoutScreen/payment_checkout_screen.dart` | 269 | ❌ **Hardcoded mockup** |
| `PaymentSuccessScreen/payment_success_screen.dart` | 375 | ❌ **Hardcoded mockup** |
| `add_payment_card_screen.dart` | 400 | ❌ **Hardcoded mockup** |

**Details:**
- **Real payment** happens inside `ReviewBookingScreen` via Razorpay (ONLINE) or wallet deduction
- `WalletRechargeScreen` has full Razorpay integration: create order → open Razorpay → verify
- `PaymentScreen`, `UpiCheckoutScreen`, `PaymentSuccessScreen`, `AddPaymentCardScreen` are all **static UI mockups** with hardcoded amounts (₹145), no API calls
- `AddPaymentCardScreen` title says "Notification Management" — **copy-paste bug**

**Issues:**
- ⚠️ Razorpay key is test key — needs production key
- ❌ Standalone payment screens are dead code / prototypes — not reachable in main flow
- ❌ `AddPaymentCardScreen` has wrong title

---

## 9. Profile & Settings ✅

| File | Lines | Status |
|------|-------|--------|
| `ProfileScreen/profile_screen.dart` | 1115 | ✅ Real API |
| `ProfileScreen/ProfileApiService/profile_api_service.dart` | — | ✅ API |
| `ProfileScreen/ProfileApiService/update_profile_api_service.dart` | — | ✅ API |
| `ProfileScreen/Model/user_profile_response.dart` | — | Model |
| `ProfileScreen/update_profile_screen.dart` | — | ✅ Real API |
| `ProfileEditScreen/profile_edit_screen.dart` | — | ✅ Real |
| `EditProfile/edit_profile_screen.dart` | — | ✅ Real |
| `NotificationSettingsScreen/notification_settings_screen.dart` | — | ⚠️ Local only |

**Details:**
- Profile fetches user data from `ProfileApiService`, displays name/email/phone/image/GST
- Image upload via `UpdateProfileApiService`
- GST submit via dedicated API endpoint
- Menu: Saved Addresses, Help & Support, Movezy Rewards, Refer & Earn, Language, Terms, Privacy, Enterprise, Logout
- Language selection: English, Hindi, Tamil, Telugu, Kannada, Bengali, Marathi — **local only, no backend i18n**
- Terms & Privacy content hardcoded inline
- Logout clears SharedPreferences and navigates to LoginScreen

**Issues:**
- ⚠️ `NotificationSettingsScreen` toggles are **local state only** — no API to persist preferences
- ⚠️ Language selection is **cosmetic only** — doesn't actually change app locale
- ⚠️ Two profile edit screens exist: `EditProfile/edit_profile_screen.dart` and `ProfileEditScreen/profile_edit_screen.dart`

---

## 10. Booking History ✅

| File | Lines | Status |
|------|-------|--------|
| `BookingHistory/booking_history.dart` | 966 | ✅ Real API |
| `BookingDetailsScreen/booking_details_screen.dart` | 529 | ✅ Real API |

**Details:**
- Fetches bookings from `/user/bookings` with pagination
- Groups into Active, Completed, Cancelled sections
- Each card: vehicle icon, booking #, driver, status badge, addresses, fare, distance, date
- Actions: Track (→ TripDetailsScreen), Cancel (→ CancelRideScreen), Download Invoice, Rate, Rebook
- `BookingDetailsScreen` fetches full booking from `BookingService.getBookingById()`
- In-app rating dialog with star + comment

**Issues:**
- ⚠️ "Report Issue" button shows "coming soon" snackbar — not implemented
- ⚠️ "Rebook" just navigates to DashboardScreen — doesn't pre-fill addresses

---

## 11. Wallet & Coins ✅ (Wallet) / ❌ (Coins)

| File | Lines | Status |
|------|-------|--------|
| `Services/wallet_service.dart` | ~200 | ✅ Real API |
| `RechangeWalletApp/recharge_wallet_screen.dart` | 425 | ✅ Real |
| `CoinsScreen/coins_screen.dart` | 252 | ❌ **Hardcoded mockup** |
| `CoinsScreen/BottomSheets/coins_bottom_screen.dart` | — | ❌ Mockup |

**Details:**
- **Wallet** is fully functional: balance display, Razorpay recharge (₹100-₹5000), transaction history
- **Coins** screen shows hardcoded "00" available coins, static UI, "Porter coins" label (branding mistake), no API
- "Transfer into Movezy Credits" / "Transfer into Bank Account" are non-functional UI

**Issues:**
- ❌ CoinsScreen is entirely static — no backend integration
- ❌ "Porter coins" reference should be "Movezy coins"
- ⚠️ Coins are mentioned in TripDetailsScreen/DeliveryCompleteScreen but never shown with real data in CoinsScreen

---

## 12. Refer & Earn ✅

| File | Lines | Status |
|------|-------|--------|
| `Services/referral_service.dart` | ~120 | ✅ Real API |
| `ReferAndEarn/refer_and_earn_Screen.dart` | 435 | ✅ Real API |

**Details:**
- Fetches referral code + stats from `ReferralService.getReferralStats()`
- Shows referral code, count, earnings
- Copy to clipboard + Share functionality
- "How it works" steps section

**Issues:** None.

---

## 13. Help & Support ⚠️

| File | Lines | Status |
|------|-------|--------|
| `HelpSupportScreen/help_support_screen.dart` | 481 | ⚠️ Partial |
| `FaqScreen/faq_screen.dart` | — | — |
| `TicketScreen/ticket_screen.dart` | — | — |

**Details:**
- Fetches recent orders from real API
- FAQ data is **local/hardcoded** per category (driver late, payment, account, cancellation, damaged, other)
- Issue resolution via tap feedback (was this helpful?) — local only
- No ticket submission API

**Issues:**
- ⚠️ No real ticket/complaint submission system
- ⚠️ FAQ content is hardcoded, not fetched from backend
- ⚠️ "Contact Support" doesn't make a real call or open chat

---

## 14. Enterprise ✅

| File | Lines | Status |
|------|-------|--------|
| `PorterEnterpriseScreen/porter_enterprise_screen.dart` | 611 | ✅ Real API |

**Details:**
- Fetches enterprise page content (hero, features, FAQs, clients) from `/enterprise/content`
- Submits inquiry via `/enterprise/inquiry`
- Fallback to hardcoded content if API fails
- Auto-scrolling client logos, expandable FAQs
- Acknowledgment popup on successful inquiry

**Issues:**
- ⚠️ File/class still named "PorterEnterprise" (old branding)

---

## 15. Multimodal / Prototype Screens ❌ (Not Production-Ready)

These screens form an **alternative multimodal journey concept** (Cab + Metro + Bike) that is **NOT connected to the main delivery flow**:

| File | Lines | Status | Notes |
|------|-------|--------|-------|
| `RideScreen/ride_screen.dart` | ~350 | ❌ Mock | Hardcoded driver "Shubham Singh", static map |
| `JourneyScreen/journey_screen.dart` | 415 | ❌ Mock | Static ₹565, 52 mins, auto-nav after 4s |
| `RideDetailsScreen/ride_details_screen.dart` | 374 | ❌ Mock | Static data, auto-nav after 5s |
| `DestinationSummeryScreen/destination_summery_screen.dart` | 312 | ❌ Mock | Static ₹145, "MetroPoints", typo "Summery" |
| `BookingConfirmedScreen` (booking_confirmed_screen.dart) | 373 | ❌ Mock | Hardcoded driver, auto-nav after 4s |
| `BookingConfirmation/booking_confirmation_screen.dart` | 464 | ❌ Mock | Static cab/metro/bike journey, ₹145 |
| `TipScreen/tip_screen.dart` | 288 | ❌ Mock | Tips in $ not ₹, no API |
| `FeedbackThanksScreen/feed_back_thanks_screen.dart` | ~120 | ❌ Mock | Static thank you |
| `SelectServiceScreen/select_service_screen.dart` | 651 | ❌ Mock | Hardcoded pickup times, ₹603 fare |
| `RideHistoryScreen/ride_history_screen.dart` | 390 | ❌ Mock | Static 3 rides, no API |
| `ChatScreen/chat_screen.dart` | ~200 | ❌ Mock | Static chat bubbles, no messaging |
| `BookACab/book_a_cab.dart` | ~400 | ❌ Mock | Older booking screen, not used |

**Recommendation:** These 12 screens should be **removed or clearly marked** as prototypes to avoid confusion. They are not reachable through the production booking flow.

---

## Routing & Navigation

| Area | Status |
|------|--------|
| `Routes/app_routes.dart` | Only defines 1 GetX route (SplashScreen) |
| All other navigation | Imperative via `pushTo()` / `replaceRoute()` helpers |
| `AppNavigation/app_navigation.dart` | Simple `Navigator.push` / `pushReplacement` wrappers |

**Issues:**
- ⚠️ Only 1 of ~30+ screens uses GetX routing — inconsistent pattern
- ⚠️ No deep linking support
- ⚠️ No named routes for most screens

---

## API Endpoints Audit

### Defined in `api_urls.dart` (67 lines):

| Endpoint | Used By | Status |
|----------|---------|--------|
| `/auth/login` | LoginScreen | ✅ Used |
| `/auth/verify-otp` | OtpScreen | ✅ Used |
| `/user/profile` | ProfileScreen | ✅ Used |
| `/user/address` | SavedAddress | ✅ Used |
| `/home` | HomeScreen | ✅ Used |
| `/user/gst` | ProfileScreen, HomeScreen | ✅ Used |
| `/wallet/balance` | WalletService | ✅ Used |
| `/wallet/transactions` | WalletRechargeScreen | ✅ Used |
| `/wallet/recharge` | WalletService | ✅ Used |
| `/wallet/verify-recharge` | WalletService | ✅ Used |
| `/booking/goods-types` | DeliveryCategoryScreen | ✅ Used |
| `/booking/addons` | ReviewBookingScreen | ✅ Used |
| `/booking/vehicle-options` | VehicleSelectionScreen | ✅ Used |
| `/booking/fare-estimate` | ReviewBookingScreen | ✅ Used |
| `/booking/create` | ReviewBookingScreen | ✅ Used |
| `/user/bookings` | BookingHistory, SearchScreen | ✅ Used |
| `/user/bookings/:id` | BookingDetailsScreen | ✅ Used |
| `/user/bookings/:id/track` | RideFindingScreen, TripDetails | ✅ Used |
| `/user/bookings/:id/cancel` | CancelRideScreen | ✅ Used |
| `/user/bookings/:id/invoice` | BookingHistory | ✅ Used |
| `/user/bookings/:id/rate` | DeliveryCompleteScreen, BookingHistory | ✅ Used |
| `/booking/cancellation-reasons` | CancelRideScreen | ✅ Used |
| `/booking/prohibited-items` | ProhibitedItemsSheet | ✅ Used |
| `/booking/time-slots` | — | ⚠️ **Defined but unused** |
| `/promo/available` | ReviewBookingScreen | ✅ Used |
| `/promo/validate` | ReviewBookingScreen | ✅ Used |
| `/enterprise/content` | PorterEnterpriseScreen | ✅ Used |
| `/enterprise/inquiry` | PorterEnterpriseScreen | ✅ Used |
| `/referral/code` | ReferralService | ✅ Used |
| `/referral/apply` | ReferralService | ✅ Used |
| `/referral/stats` | ReferAndEarnScreen | ✅ Used |

**Unused endpoints:** `/booking/time-slots` (defined but never called)

---

## TODO/FIXME Comments

Only **2** found in production code:

| Location | Content |
|----------|---------|
| `TripDetailsScreen` line 601 | `/* TODO: Add stop */` |
| `TripDetailsScreen` line 654 | `/* TODO: View details */` |

---

## Integration Assessment

### Socket.io / WebSocket
❌ **Not integrated.** Searched entire codebase — zero imports of `socket_io_client`, `web_socket_channel`, or any WebSocket package. Tracking uses HTTP polling at 5-10 second intervals.

### Firebase / FCM Push Notifications
❌ **Not integrated.** No Firebase imports, no `google-services.json`, no `firebase_messaging` or `firebase_core` package. Users have no way to receive push notifications for booking updates.

### Google Maps SDK
❌ **Not used.** The app uses `flutter_map` with OpenStreetMap tiles (free, no API key). Search uses Nominatim geocoding API. Location uses `geolocator` + `geocoding` packages.

### Razorpay
✅ **Integrated** via `razorpay_flutter` package. Used in `ReviewBookingScreen` (online payment) and `WalletRechargeScreen` (wallet recharge). Key is **test mode** (`rzp_test_...`) — needs production key before launch.

---

## Critical Issues Summary

### 🔴 Must Fix Before Launch

1. **No push notifications (FCM)** — Users won't know when driver is assigned, arrived, or delivery is complete
2. **No real-time tracking (Socket.io/WebSocket)** — HTTP polling at 5-10s intervals is inefficient and has latency
3. **No driver location on map** — TripDetailsScreen shows text status only, no live map tracking
4. **Razorpay test key** — Must switch to production key
5. **ChatScreen is fake** — A non-functional static chat UI with no messaging backend

### 🟡 Should Fix

6. **12 hardcoded mockup screens** — Dead code creating confusion; should be removed or isolated
7. **SavedAddressScreen old file** — `saved_address_screen.dart` (735 lines) is entirely commented out; delete it
8. **CoinsScreen** has no API — Shows hardcoded "00" coins, references "Porter coins"
9. **NotificationSettings** doesn't persist — Toggle states lost on app restart
10. **Language selector** is cosmetic — No actual i18n/locale support
11. **"Add Stop"** not implemented — Button visible in Search and TripDetails
12. **AddPaymentCardScreen** title says "Notification Management"
13. **Help & Support** has no ticket submission — FAQ only, hardcoded
14. **"Report Issue"** in BookingHistory shows "coming soon"

### 🟢 Nice to Have

15. Add deep linking / named routes for all screens
16. Replace imperative navigation with GetX routing (or remove GetX dependency)
17. Add offline support / caching for booking history
18. Replace Nominatim with a commercial geocoding API for production reliability
19. Add retry/offline handling for API calls

---

## File-by-File Status Matrix

| # | File | Lines | API | Status |
|---|------|-------|-----|--------|
| 1 | `main.dart` | 47 | — | ✅ Entry point |
| 2 | `Routes/app_routes.dart` | 22 | — | ⚠️ Only 1 route |
| 3 | `AppNavigation/app_navigation.dart` | ~30 | — | ✅ Nav helpers |
| 4 | `ApiUrls/api_urls.dart` | 67 | — | ✅ All endpoints |
| 5 | `Services/booking_service.dart` | 630 | ✅ | ✅ Full service |
| 6 | `Services/wallet_service.dart` | ~200 | ✅ | ✅ Full service |
| 7 | `Services/referral_service.dart` | ~120 | ✅ | ✅ Full service |
| 8 | `SplashScreen/splash_screen.dart` | ~100 | ✅ | ✅ Real |
| 9 | `LoginScreen/login_screen.dart` | ~300 | ✅ | ✅ Real |
| 10 | `OtpScreen/otp_screen.dart` | ~250 | ✅ | ✅ Real |
| 11 | `DashboardScreen/dashboard_screen.dart` | ~120 | — | ✅ Real |
| 12 | `HomeScreen/home_screen.dart` | 1298 | ✅ | ✅ Real |
| 13 | `SearchScreen/search_screen.dart` | 696 | ✅ | ✅ Real |
| 14 | `MapPickerScreen/map_picker_screen.dart` | 515 | ✅ | ✅ Real |
| 15 | `DeliveryCategoryScreen/delivery_category_screen.dart` | ~250 | ✅ | ✅ Real |
| 16 | `VehicleSelectionScreen/vehicle_selection_screen.dart` | ~500 | ✅ | ✅ Real |
| 17 | `LoadAssistScreen/load_assist_screen.dart` | ~290 | — | ✅ UI pass-through |
| 18 | `ReviewBookingScreen/review_booking_screen.dart` | 1966 | ✅ | ✅ Real |
| 19 | `RideFindingScreen/ride_finding_screen.dart` | ~300 | ✅ | ✅ Real |
| 20 | `TripDetailsScreen/trip_details_screen.dart` | 1187 | ✅ | ✅ Real |
| 21 | `CancelRideScreen/cancel_ride_screen.dart` | ~280 | ✅ | ✅ Real |
| 22 | `RideCanceledSuccessScreen/...` | ~120 | — | ✅ Static success |
| 23 | `DeliveryCompleteScreen/...` | ~400 | ✅ | ✅ Real |
| 24 | `BookingHistory/booking_history.dart` | 966 | ✅ | ✅ Real |
| 25 | `BookingDetailsScreen/...` | 529 | ✅ | ✅ Real |
| 26 | `ProfileScreen/profile_screen.dart` | 1115 | ✅ | ✅ Real |
| 27 | `ProfileScreen/update_profile_screen.dart` | — | ✅ | ✅ Real |
| 28 | `ProfileEditScreen/profile_edit_screen.dart` | — | ✅ | ✅ Real |
| 29 | `EditProfile/edit_profile_screen.dart` | — | ✅ | ✅ Real |
| 30 | `RechangeWalletApp/recharge_wallet_screen.dart` | 425 | ✅ | ✅ Real |
| 31 | `ReferAndEarn/refer_and_earn_Screen.dart` | 435 | ✅ | ✅ Real |
| 32 | `HelpSupportScreen/help_support_screen.dart` | 481 | ⚠️ | ⚠️ Partial |
| 33 | `PorterEnterpriseScreen/...` | 611 | ✅ | ✅ Real |
| 34 | `SavedAddress/saved_address.dart` | 758 | ✅ | ✅ Real (line 436+) |
| 35 | `SavedAddress/add_address_screen.dart` | — | ✅ | ✅ Real |
| 36 | `NotificationSettingsScreen/...` | — | — | ⚠️ Local only |
| 37 | `LocationPermissionScreen/...` | — | ✅ | ✅ Real |
| 38 | `CoinsScreen/coins_screen.dart` | 252 | ❌ | ❌ Hardcoded |
| 39 | `PaymentScreen/payment_screen.dart` | ~250 | ❌ | ❌ Mockup |
| 40 | `ChatScreen/chat_screen.dart` | ~200 | ❌ | ❌ Mockup |
| 41 | `RideScreen/ride_screen.dart` | ~350 | ❌ | ❌ Mockup |
| 42 | `JourneyScreen/journey_screen.dart` | 415 | ❌ | ❌ Mockup |
| 43 | `RideDetailsScreen/ride_details_screen.dart` | 374 | ❌ | ❌ Mockup |
| 44 | `DestinationSummeryScreen/...` | 312 | ❌ | ❌ Mockup |
| 45 | `BookingConfirmation/...` | 464 | ❌ | ❌ Mockup |
| 46 | `BookingConfimed/...` | 373 | ❌ | ❌ Mockup |
| 47 | `TipScreen/tip_screen.dart` | 288 | ❌ | ❌ Mockup |
| 48 | `FeedbackThanksScreen/...` | ~120 | ❌ | ❌ Mockup |
| 49 | `SelectServiceScreen/...` | 651 | ❌ | ❌ Mockup |
| 50 | `RideHistoryScreen/...` | 390 | ❌ | ❌ Mockup |
| 51 | `UpiCheckoutScreen/...` | 269 | ❌ | ❌ Mockup |
| 52 | `PaymentSuccessScreen/...` | 375 | ❌ | ❌ Mockup |
| 53 | `add_payment_card_screen.dart` | 400 | ❌ | ❌ Mockup |
| 54 | `CommonWidgets/order_status_timeline.dart` | 208 | — | ✅ Widget |
| 55 | `CommonWidgets/prohibited_items_sheet.dart` | — | ✅ | ✅ API fetch |
| 56 | `CommonWidgets/booking_terms_sheet.dart` | — | — | ✅ Widget |
| 57 | `CommonWidgets/wallet_widget.dart` | — | — | ✅ Widget |
| 58 | `CommonWidgets/button_widget.dart` | — | — | ✅ Widget |
| 59 | `CommonWidgets/app_bar.dart` | — | — | ✅ Widget |

---

## Conclusion

The **core delivery booking flow is production-ready** with real backend integration across ~22 screens. The app successfully handles: authentication, vehicle/goods selection, fare estimation, Razorpay payment, booking creation, status polling, cancellation, rating, wallet management, referrals, and profile management.

**Critical gaps** are: no push notifications (FCM), no WebSocket real-time tracking, no in-app chat, and ~12 leftover mockup screens that should be cleaned up. The Razorpay key must be switched from test to production before launch.
