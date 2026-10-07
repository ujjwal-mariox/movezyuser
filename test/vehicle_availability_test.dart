import 'dart:async';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:movezy_user_app/CommonWidgets/vehicle_availability_notice.dart';
import 'package:movezy_user_app/Screens/HomeScreen/Model/booking_data.dart';
import 'package:movezy_user_app/Screens/HomeScreen/Model/home_page_model.dart';
import 'package:movezy_user_app/Screens/SearchScreen/search_screen.dart';
import 'package:movezy_user_app/Screens/VehicleSelectionScreen/vehicle_selection_screen.dart';
import 'package:movezy_user_app/Services/booking_service.dart';
import 'package:movezy_user_app/Services/vehicle_availability.dart';
import 'package:movezy_user_app/Utils/PrefsManager/prefs_manager.dart';

BookingData trip() => BookingData(
  selectedVehicle: HomeVehicleType(
    id: 'bike',
    name: 'Bike',
    categoryCode: '2W',
    maxWeightKg: 100,
    baseFare: 100,
    perKmRate: 10,
    perMinuteRate: 1,
    maxRangeKm: 100,
  ),
  serviceType: 'WITHIN_CITY',
  pickupAddress: 'Pickup',
  dropAddress: 'Drop',
  pickupLat: 12,
  pickupLng: 77,
  dropLat: 13,
  dropLng: 78,
  stops: [
    {'address': 'Stop one', 'lat': 12.5, 'lng': 77.5},
  ],
  receiverName: 'Receiver',
  receiverPhone: '1234567890',
  goodsCategory: 'Parcels',
  goodsTypeId: 'goods',
);
VehicleOption truck() => VehicleOption(
  vehicleTypeId: 'truck',
  name: 'Truck',
  categoryCode: '4W',
  maxWeightKg: 1000,
  baseFare: 100,
  estimatedFare: 300,
  distanceKm: 150,
  estimatedDuration: 360,
  maxRangeKm: 300,
);
const overLimit = VehicleAvailability(
  code: 'AVAILABLE',
  availableCount: 1,
  withinCityAvailableCount: 1,
  outstationAvailableCount: 1,
  distanceKm: 150,
  preferredCode: 'DISTANCE_LIMIT',
  preferredMessage:
      'This trip is 150.0 km including stops. Bike can cover up to 100.0 km. Change your locations or choose another vehicle.',
);
VehicleOptionsResult result(
  VehicleAvailability availability, [
  List<VehicleOption> options = const [],
]) => VehicleOptionsResult(options: options, availability: availability);

void phoneSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(360, 640);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

class LocalTiles extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      const AssetImage('assets/current_location.png');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Prefs.load();
  });

  testWidgets('location connection failure clears the spinner and a later retry preserves the trip', (tester) async {
    phoneSize(tester);
    var requests = 0;
    BookingData? proceeded;
    await tester.pumpWidget(MaterialApp(home: SearchScreen(bookingData: trip(),
      mapTileProvider: LocalTiles(), loadPreviewRoute: (points) async => points,
      checkVehicleAvailability: (_) async {
        if (++requests == 1) throw const VehicleOptionsException('CONNECTION', 'Check your connection and try again.');
        return result(const VehicleAvailability(availableCount: 1, preferredCode: 'AVAILABLE'));
      }, onTripValidated: (data) => proceeded = data)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('search vehicle')); await tester.pumpAndSettle();
    expect(find.text('Check your connection'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(proceeded, isNull);
    await tester.tap(find.text('Back to locations')); await tester.pumpAndSettle();
    await tester.tap(find.text('search vehicle')); await tester.pumpAndSettle();
    expect(requests, 2);
    expect(proceeded!.stops.single['address'], 'Stop one');
    expect(tester.takeException(), isNull);
  });

  testWidgets('an explicitly selected Outstation service survives a failed recheck and retry', (tester) async {
    phoneSize(tester);
    final checked = <BookingData>[];
    BookingData? proceeded;
    await tester.pumpWidget(MaterialApp(home: SearchScreen(bookingData: trip(),
      mapTileProvider: LocalTiles(), loadPreviewRoute: (points) async => points,
      checkVehicleAvailability: (data) async {
        checked.add(data);
        if (checked.length == 1) return result(overLimit);
        if (checked.length == 2) throw const VehicleOptionsException('SERVICE_UNAVAILABLE', 'Please try again.');
        return result(const VehicleAvailability(availableCount: 1, outstationAvailableCount: 1));
      }, onTripValidated: (data) => proceeded = data)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('search vehicle')); await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Switch to Outstation'));
    await tester.tap(find.text('Switch to Outstation')); await tester.pumpAndSettle();
    await tester.tap(find.text('Back to locations')); await tester.pumpAndSettle();
    await tester.tap(find.text('search vehicle')); await tester.pumpAndSettle();
    expect(checked.last.serviceType, 'OUTSTATION');
    expect(checked.last.selectedVehicle, isNull);
    expect(proceeded!.goodsTypeId, 'goods');
    expect(tester.takeException(), isNull);
  });

  test(
    'coordinate validation accepts zero latitude and rejects missing, invalid and placeholder pins',
    () {
      expect(validBookingCoordinates(0, 77), isTrue);
      expect(validBookingCoordinates(12, 0), isTrue);
      for (final point in [
        [null, 77],
        [12, null],
        [0, 0],
        [91, 77],
        [12, 181],
        [double.nan, 77],
        [double.infinity, 77],
      ]) {
        expect(validBookingCoordinates(point[0], point[1]), isFalse);
      }
    },
  );

  test(
    'Outstation recovery explicitly clears the incompatible vehicle and preserves route, goods and receiver',
    () {
      final before = trip();
      final after = applyTripRecovery(before, TripRecoveryAction.outstation);
      expect(after.selectedVehicle, isNull);
      expect(after.serviceType, 'OUTSTATION');
      expect(after.stops, before.stops);
      expect(after.pickupLat, before.pickupLat);
      expect(after.dropLng, before.dropLng);
      expect(after.goodsTypeId, before.goodsTypeId);
      expect(after.receiverPhone, before.receiverPhone);
      expect(before.selectedVehicle, isNotNull);
    },
  );

  test(
    'no Outstation action is offered when all larger vehicles exceed their own distance limits',
    () {
      const none = VehicleAvailability(
        code: 'DISTANCE_LIMIT',
        preferredCode: 'DISTANCE_LIMIT',
      );
      expect(tripRecoveryActions(none, 'WITHIN_CITY'), [
        TripRecoveryAction.changeLocations,
      ]);
      expect(
        tripRecoveryActions(overLimit, 'WITHIN_CITY'),
        contains(TripRecoveryAction.outstation),
      );
      expect(
        tripRecoveryActions(overLimit, 'OUTSTATION'),
        isNot(contains(TripRecoveryAction.outstation)),
      );
    },
  );

  test(
    'structured and older empty API responses do not become connection errors',
    () {
      final response = VehicleOptionsResult.fromJson({
        'success': true,
        'data': [],
        'eligibility': {
          'code': 'DISTANCE_LIMIT',
          'distanceKm': 500,
          'availableCount': 0,
          'message': 'No vehicle can cover 500 km.',
          'preferredVehicle': {
            'code': 'DISTANCE_LIMIT',
            'message': 'Bike can cover up to 100 km.',
          },
        },
      });
      expect(response.availability.code, 'DISTANCE_LIMIT');
      expect(
        response.availability.explanation,
        contains('Bike can cover up to 100 km.'),
      );
      expect(
        response.availability.explanation,
        contains('No vehicle can cover 500 km.'),
      );
      final legacy = VehicleOptionsResult.fromJson({
        'success': true,
        'data': [],
      });
      expect(legacy.availability.code, 'NO_MATCHING_VEHICLES');
      expect(legacy.availability.explanation, contains('Change locations'));
      expect(
        () => VehicleOptionsResult.fromJson({'data': {}}),
        throwsFormatException,
      );
    },
  );

  testWidgets(
    'location selection shows the two-wheeler warning before progressing and retains stops',
    (tester) async {
      phoneSize(tester);
      final checked = <BookingData>[];
      BookingData? proceeded;
      await tester.pumpWidget(
        MaterialApp(
          home: SearchScreen(
            bookingData: trip(),
            mapTileProvider: LocalTiles(),
            loadPreviewRoute: (points) async => points,
            checkVehicleAvailability: (data) async {
              checked.add(data);
              return result(overLimit);
            },
            onTripValidated: (data) => proceeded = data,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('search vehicle'));
      await tester.pumpAndSettle();
      expect(checked.single.stops.single['address'], 'Stop one');
      expect(
        find.text('Trip exceeds the vehicle distance limit'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Two-wheelers are not available'),
        findsOneWidget,
      );
      expect(proceeded, isNull);
      await tester.tap(find.text('Change locations'));
      await tester.pumpAndSettle();
      expect(find.byType(SearchScreen), findsOneWidget);
      expect(proceeded, isNull);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'explicit Outstation switch rechecks eligibility and passes the preserved trip forward',
    (tester) async {
      phoneSize(tester);
      final checked = <BookingData>[];
      BookingData? proceeded;
      await tester.pumpWidget(
        MaterialApp(
          home: SearchScreen(
            bookingData: trip(),
            mapTileProvider: LocalTiles(),
            loadPreviewRoute: (points) async => points,
            checkVehicleAvailability: (data) async {
              checked.add(data);
              return result(
                data.serviceType == 'OUTSTATION'
                    ? const VehicleAvailability(
                        availableCount: 1,
                        outstationAvailableCount: 1,
                      )
                    : overLimit,
              );
            },
            onTripValidated: (data) => proceeded = data,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('search vehicle'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Switch to Outstation'));
      await tester.tap(find.text('Switch to Outstation'));
      await tester.pumpAndSettle();
      expect(checked.length, 2);
      expect(proceeded!.serviceType, 'OUTSTATION');
      expect(proceeded!.selectedVehicle, isNull);
      expect(proceeded!.stops.single['address'], 'Stop one');
      expect(proceeded!.goodsTypeId, 'goods');
      expect(proceeded!.receiverName, 'Receiver');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'rapid repeated searches cannot start duplicate eligibility requests',
    (tester) async {
      phoneSize(tester);
      final response = Completer<VehicleOptionsResult>();
      var requests = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: SearchScreen(
            bookingData: trip(),
            mapTileProvider: LocalTiles(),
            loadPreviewRoute: (points) async => points,
            checkVehicleAvailability: (_) {
              requests++;
              return response.future;
            },
            onTripValidated: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      final button = find.text('search vehicle');
      await tester.tap(button);
      await tester.tap(button);
      await tester.pump();
      expect(requests, 1);
      expect(find.text('Checking trip…'), findsOneWidget);
      response.complete(
        result(
          const VehicleAvailability(
            availableCount: 1,
            preferredCode: 'AVAILABLE',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(requests, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'vehicle screen explains an empty distance result on a compact phone without the generic failure',
    (tester) async {
      phoneSize(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: VehicleSelectionScreen(
            bookingData: trip(),
            loadVehicleResult: (_) async => result(
              const VehicleAvailability(
                code: 'DISTANCE_LIMIT',
                message:
                    'No vehicle covers this 500 km trip. Change locations.',
                preferredCode: 'DISTANCE_LIMIT',
                preferredMessage: 'Bike can cover up to 100 km.',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Bike can cover up to 100 km.'),
        findsOneWidget,
      );
      expect(find.text('Change locations'), findsOneWidget);
      expect(find.text('Failed to load vehicles'), findsNothing);
      expect(find.text('Switch to Outstation'), findsNothing);
      expect(
        tester
            .widget<ElevatedButton>(
              find.widgetWithText(ElevatedButton, 'Select a vehicle'),
            )
            .onPressed,
        isNull,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'unavailable preferred vehicle requires choosing another card and does not silently replace it',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: VehicleSelectionScreen(
            bookingData: trip(),
            loadVehicleResult: (_) async => result(overLimit, [truck()]),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Recommended'), findsNothing);
      expect(
        find.text('Trip exceeds the vehicle distance limit'),
        findsOneWidget,
      );
      expect(
        tester
            .widget<ElevatedButton>(
              find.widgetWithText(ElevatedButton, 'Select a vehicle'),
            )
            .onPressed,
        isNull,
      );
      await tester.tap(find.text('Truck'));
      await tester.pumpAndSettle();
      expect(find.text('Recommended'), findsOneWidget);
      expect(
        find.text('Trip exceeds the vehicle distance limit'),
        findsNothing,
      );
      expect(
        tester
            .widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Next'))
            .onPressed,
        isNotNull,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'connection error has a real retry that recovers and clears the old error',
    (tester) async {
      phoneSize(tester);
      var requests = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: VehicleSelectionScreen(
            bookingData: trip().copyWith(clearSelectedVehicle: true),
            loadVehicleResult: (_) async {
              if (++requests == 1) {
                throw const VehicleOptionsException(
                  'CONNECTION',
                  'Check your internet connection and try again.',
                );
              }
              return result(const VehicleAvailability(availableCount: 1), [
                truck(),
              ]);
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Check your internet connection and try again.'),
        findsOneWidget,
      );
      expect(find.text('Failed to load vehicles'), findsNothing);
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(requests, 2);
      expect(find.text('Truck'), findsOneWidget);
      expect(
        find.text('Check your internet connection and try again.'),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
