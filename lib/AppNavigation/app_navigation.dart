import 'package:flutter/cupertino.dart';
import 'package:movezy_user_app/Screens/DashboardScreen/dashboard_screen.dart';

/// Go back safely from a screen that may be the only route on the stack.
///
/// `replaceRoute` clears the whole stack, so screens reached that way (ride
/// finding, trip details, cancel-success) had nothing to pop to — the back
/// arrow dead-ended on a black screen while the booking carried on. Falls back
/// to the dashboard, which is where "back" means from those screens anyway.
void safeBack(BuildContext context) {
  if (Navigator.of(context).canPop()) {
    Navigator.pop(context);
  } else {
    replaceRoute(context, const DashboardScreen());
  }
}

Future<dynamic> pushTo(BuildContext context, Widget name) async {
  return await Navigator.push(
    context,
    CupertinoPageRoute(builder: (context) => name),
  );
}

void replaceRoute(BuildContext context, Widget name){
  Navigator.pushAndRemoveUntil(
    context,
    CupertinoPageRoute(builder: (context) => name),
        (Route<dynamic> route) => false,
  );
}