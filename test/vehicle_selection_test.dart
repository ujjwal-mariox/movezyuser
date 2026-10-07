import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movezy_user_app/Screens/HomeScreen/Model/booking_data.dart';
import 'package:movezy_user_app/Screens/HomeScreen/Model/home_page_model.dart';
import 'package:movezy_user_app/Screens/VehicleSelectionScreen/vehicle_selection_screen.dart';
import 'package:movezy_user_app/Services/booking_service.dart';

VehicleOption option(String id, String name, {bool recommended = false}) =>
    VehicleOption(
      vehicleTypeId: id,
      name: name,
      maxWeightKg: 100,
      baseFare: 100,
      estimatedFare: 120,
      distanceKm: 5,
      estimatedDuration: 15,
      isRecommended: recommended,
    );

void main() {
  testWidgets(
    'only the selected vehicle is Recommended and selection moves it to the top',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final booking = BookingData(
        pickupLat: 12,
        pickupLng: 77,
        dropLat: 13,
        dropLng: 78,
        pickupAddress: 'Pickup',
        dropAddress: 'Drop',
        selectedVehicle: HomeVehicleType(
          id: 'bike',
          name: 'Bike',
          maxWeightKg: 100,
          baseFare: 100,
          perKmRate: 10,
          perMinuteRate: 1,
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: VehicleSelectionScreen(
            bookingData: booking,
            loadVehicleOptions: (_) async => [
              option('truck', 'Truck', recommended: true),
              option('bike', 'Bike', recommended: true),
              option('van', 'Van'),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      void expectGrouping(String selected, List<String> others) {
        final recommendedY = tester.getTopLeft(find.text('Recommended')).dy;
        final othersY = tester.getTopLeft(find.text('Others')).dy;
        final selectedY = tester.getTopLeft(find.text(selected).first).dy;
        expect(selectedY, greaterThan(recommendedY));
        expect(selectedY, lessThan(othersY));
        for (final name in others) {
          expect(find.text(name), findsOneWidget);
          expect(tester.getTopLeft(find.text(name)).dy, greaterThan(othersY));
        }
      }

      expectGrouping('Bike', ['Truck', 'Van']);
      await tester.tap(find.text('Van'));
      await tester.pumpAndSettle();
      expectGrouping('Van', ['Truck', 'Bike']);
      expect(tester.takeException(), isNull);
    },
  );
}
