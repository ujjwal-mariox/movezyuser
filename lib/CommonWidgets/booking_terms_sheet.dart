import 'package:flutter/material.dart';

/// Porter-style Terms & Conditions bottom sheet for bookings.
///
/// Usage:
/// ```dart
/// showBookingTermsSheet(context);
/// ```
void showBookingTermsSheet(BuildContext context, {String? vehicleName}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _BookingTermsSheet(vehicleName: vehicleName),
  );
}

class _BookingTermsSheet extends StatelessWidget {
  final String? vehicleName;
  const _BookingTermsSheet({this.vehicleName});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      vehicleName != null
                          ? "$vehicleName: Terms & conditions"
                          : "Terms & conditions",
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close, size: 24),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Scrollable content
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                children: [
                  _sectionHeader("I. Booking Details"),
                  const SizedBox(height: 10),
                  _numberedItem(1, null, [
                    _boldInline("Cancellation:", " Free cancellation is allowed up to 1 hour before pickup time, after which Booking amount (if any) will not be refunded. If there is any cancellation, liquidated damages or penalty may be levied to the Customer."),
                  ]),
                  const SizedBox(height: 20),

                  _sectionHeader("II. Payment Guidelines"),
                  const SizedBox(height: 10),
                  _numberedItem(1, null, [
                    _boldInline("Total Payment:", " Excluding Booking amount (if any), remaining amount should be paid to Partner at drop location once order is completed."),
                  ]),
                  const SizedBox(height: 8),
                  _numberedItem(2, null, [
                    // Don't restate the waiting terms here. This said "Rs. 3 /
                    // min beyond 60 minutes" — a THIRD set of numbers, and
                    // wrong: the fare summary on the booking screen shows the
                    // real free minutes and per-minute rate straight from the
                    // server. One source of truth beats three guesses.
                    _boldInline("Price Revision:", " Price may change due to modification of goods, quantity, service type or changes in pickup/drop location, date & time that was mentioned by the customer while booking an order, or any extra waiting charges that may be leviable if the vehicle waits beyond the free loading/unloading time shown in your fare summary."),
                  ]),
                  const SizedBox(height: 20),

                  _sectionHeader("III. Goods"),
                  const SizedBox(height: 10),
                  _numberedItem(1, null, [
                    _boldInline("Packaging, Assembly-Disassembly, Dismantling & Rope Pulling", " of goods are NOT included."),
                  ]),
                  const SizedBox(height: 8),
                  _numberedItem(2, null, [
                    _boldInline("Technical Assistance NOT", " included: If any machine, appliance, or electronic gadgets require technical assistance of the manufacturer for locking/unlocking, it is the customer's responsibility to arrange for it as Movezy DOES NOT offer these services."),
                  ]),
                  const SizedBox(height: 8),
                  _numberedItem(3, "Prohibited goods:", []),
                  Padding(
                    padding: const EdgeInsets.only(left: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _bulletPoint("Goods heavier than 25 kg or that which CANNOT BE LIFTED by 1 PERSON, CANNOT be moved using this service. Eg: Cots, wardrobe/Almirahs, sofa, other such goods bigger than 5.5 feet, etc."),
                        const SizedBox(height: 4),
                        _bulletPoint("Goods prohibited by Movezy for transportation will not be allowed."),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  _sectionHeader("IV. Delay"),
                  const SizedBox(height: 10),
                  _numberedItem(1, null, [
                    const TextSpan(
                      text: "Due to No Entry Hours in specific cities, restricted movement, festival days, peak days or owing to traffic or other reasons beyond Movezy's control, the service might be delayed & Movezy is not liable for it.",
                      style: TextStyle(fontSize: 13, color: Colors.black87, height: 1.5),
                    ),
                  ]),
                  const SizedBox(height: 20),

                  _sectionHeader("V. Dispute Settlement"),
                  const SizedBox(height: 10),
                  _numberedItem(1, null, [
                    const TextSpan(
                      text: "You may reach out to the customer care in order to register any complaint within 24 hours of the completion of the order. Movezy will not entertain any disputes if it is raised beyond 24 hours and if there were any variation in the order details which were not duly communicated to Movezy customer care.",
                      style: TextStyle(fontSize: 13, color: Colors.black87, height: 1.5),
                    ),
                  ]),
                  const SizedBox(height: 24),

                  // Footer
                  Text(
                    "You will be governed by our Terms of Service.",
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "For assistance, contact customer care or email at support@movezy.in",
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _numberedItem(int number, String? boldPrefix, List<InlineSpan> spans) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("$number. ",
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        Expanded(
          child: boldPrefix != null && spans.isEmpty
              ? Text(
                  boldPrefix,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    height: 1.5,
                  ),
                )
              : RichText(text: TextSpan(children: spans)),
        ),
      ],
    );
  }

  InlineSpan _boldInline(String boldPart, String normalPart) {
    return TextSpan(
      children: [
        TextSpan(
          text: boldPart,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            height: 1.5,
          ),
        ),
        TextSpan(
          text: normalPart,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.black87,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _bulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("• ", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
