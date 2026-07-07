import 'package:flutter/material.dart';


class RideScreen extends StatelessWidget {
  const RideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // --- Top Map Placeholder ---
            Container(
              height: 250,
              width: double.infinity,
              color: Colors.blue.shade100,
              child: Center(
                child: Text(
                  'Map Area',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            // --- Driver Info Card ---
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundImage: NetworkImage(
                            'https://images.unsplash.com/photo-1544005313-94ddf0286df2?q=80&w=200',
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text("Shubham Singh",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16)),
                                  SizedBox(width: 6),
                                  Icon(Icons.star,
                                      color: Colors.orange, size: 16),
                                  Text("4.5",
                                      style: TextStyle(fontSize: 14)),
                                ],
                              ),
                              SizedBox(height: 4),
                              Text("KA05 MN 3812 · Silver Toyota Otis",
                                  style: TextStyle(fontSize: 12)),
                              SizedBox(height: 8),
                              Container(
                                padding: EdgeInsets.symmetric(
                                    vertical: 4, horizontal: 8),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade100,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  "Your driver is arriving in 3 mins",
                                  style: TextStyle(
                                      color: Colors.green.shade800,
                                      fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                    SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _button(Icons.call, "Call", Colors.green),
                        _button(Icons.chat_bubble_outline, "Chat", Colors.blue),
                        _button(Icons.share, "Share", Colors.grey),
                      ],
                    )
                  ],
                ),
              ),
            ),

            // --- Timeline / Stops Section ---
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      )
                    ],
                  ),
                  child: ListView(
                    children: [
                      _stopRow("Pickup", "3 Min", "Chikka Banaswadi", "Metro"),
                      Divider(),
                      _stopRow("Pickup", "2 Min", "Chikka Banaswadi", ""),
                      Divider(),
                      _stopRow("Pickup", "-", "Chikka Banaswadi", ""),
                    ],
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _button(IconData icon, String label, Color color) {
    return OutlinedButton.icon(
      onPressed: () {},
      icon: Icon(icon, color: color),
      label: Text(label, style: TextStyle(color: color)),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color.withOpacity(0.5)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _stopRow(
      String title, String time, String subtitle, String extra) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(title,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            Spacer(),
            Text(time, style: TextStyle(color: Colors.grey)),
          ],
        ),
        SizedBox(height: 4),
        Text(subtitle, style: TextStyle(fontSize: 13)),
        if (extra.isNotEmpty)
          Text(extra, style: TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
