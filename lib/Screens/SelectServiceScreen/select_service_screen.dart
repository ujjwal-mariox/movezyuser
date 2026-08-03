import 'package:flutter/material.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:movezy_user_app/CommonWidgets/app_bar.dart';
import 'package:movezy_user_app/Utils/AppColors/app_colors.dart';


class PickUPTimeModel {
  String time;
  String day;
  bool isSelected;

  PickUPTimeModel({required this.time,required this.day, required this.isSelected});
}


class SelectServiceScreen extends StatefulWidget {
  const SelectServiceScreen({super.key});

  @override
  State<SelectServiceScreen> createState() => _SelectServiceScreenState();
}

class _SelectServiceScreenState extends State<SelectServiceScreen> {

  List<PickUPTimeModel> pickUpDate = [];

  List<String> listOfTimes = [];

  @override
  void initState() {

    pickUpDate.add(PickUPTimeModel(day: "Today", time: "22", isSelected: true));
    pickUpDate.add(PickUPTimeModel(day: "Tomorrow", time: "22", isSelected: false));
    pickUpDate.add(PickUPTimeModel(day: "Mon", time: "22", isSelected: false));
    pickUpDate.add(PickUPTimeModel(day: "Tue", time: "22", isSelected: false));
    pickUpDate.add(PickUPTimeModel(day: "Thurs", time: "22", isSelected: false));
    pickUpDate.add(PickUPTimeModel(day: "Fri", time: "22", isSelected: false));
    pickUpDate.add(PickUPTimeModel(day: "Satur", time: "22", isSelected: false));


    listOfTimes.add("in 30 MINS");
    listOfTimes.add("2 :00 PM");
    listOfTimes.add("2 :30 PM");
    listOfTimes.add("3 :00 PM");
    listOfTimes.add("3 :30 PM");
    listOfTimes.add("4 :00 PM");

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            commonAppBar(
                height : 105,
                context : context,
                child: Container(
                  padding: const EdgeInsets.only(top: 50),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: (){
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding: EdgeInsets.only(left: 16),
                          width: 40,
                          height: 35,
                          alignment: Alignment.center,
                          child: Icon(Icons.arrow_back_ios, color: Colors.white,),
                        ),
                      ),

                      SizedBox(width: 5,),

                      Text(
                        "Review Booking",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      Spacer(),
                    ],
                  ),
                )
            ),

            Container(
              padding: EdgeInsets.only(top: 16, bottom: 16),
              child: Column(
                children: [
                  _vehicleCard(),

                  const SizedBox(height: 10),
                  Container(color: HexColor("#F4F4F4"),height: 20,),
                  const SizedBox(height: 10),

                  _selectServiceSection(),

                  const SizedBox(height: 10),
                  Container(color: HexColor("#F4F4F4"),height: 20,),
                  const SizedBox(height: 10),
                  _selectGoodsSection(),
                  const SizedBox(height: 20),
                  Container(color: HexColor("#F4F4F4"),height: 20,),
                  const SizedBox(height: 14),
                  _pickupTimeSection(),
                  const SizedBox(height: 20),
                  Container(
                    margin: EdgeInsets.only(left: 16, right: 16),
                    width: MediaQuery.of(context).size.width,
                    child: Text("View all Slots",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                          color: HexColor("#2152C4"),
                        )
                    ),
                  ),
                  const SizedBox(height: 15),

                  Container(
                    padding: EdgeInsets.only(left: 16, right: 16,top: 20, bottom: 20),
                    width: MediaQuery.of(context).size.width,
                    color: HexColor("#F4F4F4"),
                    child: Text("Terms & conditions",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                          color: HexColor("#868687"),
                        )
                    ),
                  ),
                  const SizedBox(height: 15),
                  _fareSection(),
                  const SizedBox(height: 20),
                ],
              ),
            )
          ],
        ),
      ),

      // SafeArea(top: false): _bottomButton applies no inset of its own, so the
      // "Book 3 Wheeler" button sat under the gesture bar / nav buttons.
      bottomNavigationBar: SafeArea(top: false, child: _bottomButton()),
    );
  }

  Widget _vehicleCard() {
    return Container(
      margin: EdgeInsets.only(left: 16, right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Image.asset('assets/auto.png', height: 60),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('3 Wheeler', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                SizedBox(height: 4),
                Text('View Booking Details', style: TextStyle(fontSize: 12, color: Colors.blue)),
              ],
            ),
          ),
           Column(
             mainAxisAlignment: MainAxisAlignment.end,
             crossAxisAlignment: CrossAxisAlignment.end,
             children: [
               Text('₹603', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),

               Text('Vehicle fare', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w400, color: HexColor("#2A2A2A"))),
             ],
           ),
        ],
      ),
    );
  }

  Widget _selectServiceSection() {
    return Container(
      margin: EdgeInsets.only(left: 16, right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          const Text('Select Service', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          _toggleCard(title: 'Loading & unloading'),
          SizedBox(
            width: MediaQuery.of(context).size.width,
            child: Image.asset("assets/dotted_line.png", height: 1,),
          ),
          const SizedBox(height: 15),
          _floorSelection(title: 'Pickup details'),
          const SizedBox(height: 20),
          _floorSelection(title: 'Drop details'),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _toggleCard({required String title}) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            Image.asset("assets/delivery_man.png", width: 40,),
             SizedBox(width: 10),
            Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ]),
          Text('Change', style: TextStyle(color: Colors.blue, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _floorSelection({required String title}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        _yesNoRow('Pickup on ground floor?'),
        const SizedBox(height: 12),
        _yesNoRow('Lift available?'),
        const SizedBox(height: 12),
        _dropdownField(),
      ],
    );
  }

  Widget _yesNoRow(String label) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13)),
        Row(children: [
          _optionChip('Yes', false),
          const SizedBox(width: 10),
          _optionChip('No', true),
        ]),
      ],
    );
  }

  Widget _optionChip(String text, bool selected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: selected ? AppColors.appColor : HexColor("#E0E0E0")),
      ),
      child: Text(text, style: TextStyle(color: selected ? AppColors.appColor : HexColor("#E0E0E0"))),
    );
  }

  Widget _dropdownField() {
    return Container(
      margin: EdgeInsets.only(top: 7),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: HexColor("#E0E0E0")),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: const [
          Text('Select floor'),
          Icon(Icons.arrow_drop_down),
        ],
      ),
    );
  }

  Widget _selectGoodsSection() {
    return Container(
      margin: EdgeInsets.only(left: 16, right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 10,),
          const Text('Select type of goods', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 7),
          
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [

              Image.asset("assets/business_icon.png", width: 20,),

              SizedBox(width: 10,),

              Container(
                padding: EdgeInsets.only(top: 5),
                  child: Text('Business or Commercial goods')),
            ],
          ),

          const SizedBox(height: 18),

          Container(
            width: MediaQuery.of(context).size.width,
            height: 1.5,
            color: Colors.black.withOpacity(0.1),
          ),

          const SizedBox(height: 22),

          Row(
            children: [
              Text('Carton Box | Bag | Container | Bundle | Rolls', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),

              Spacer(),

              Text('Change', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: HexColor("#2A5CD0"))),
            ],
          ),

          const SizedBox(height: 12),

          Text('Quantity', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),

          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _goodsCard('1–10Kg', 5),
              _goodsCard('10–25Kg', 1),
            ],
          ),
        ],
      ),
    );
  }

  Widget _goodsCard(String weight, int qty) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.43,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          SizedBox(height: 10),
          Text(weight, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          SizedBox(height: 10),
          Image.asset('assets/quantity_icon.png', height: 60),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 32,
                height: 32,
                padding: EdgeInsets.only(left: 10, right: 10),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.grey.shade400),
                ),
                child: Center(child: Divider(color: Colors.black,height: 1,)),
              ),
              Text(qty.toString(), style: TextStyle(fontSize: 16)),
              _qtyBtn('+'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _qtyBtn(String text) {
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: Center(child: Text(text, style: const TextStyle(fontSize: 16))),
    );
  }

  Widget _pickupTimeSection() {
    return Container(
      margin: EdgeInsets.only(left: 16, right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Select pickup time', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),

          const Text("NOV 2025", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),

          const SizedBox(height: 16),

          SizedBox(
            height: 65,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: pickUpDate.length,
              itemBuilder: (context, index){
                return _timeChip(pickUpDate[index].day, pickUpDate[index].time, pickUpDate[index].isSelected,);
              },
            ),
          ),
          const SizedBox(height: 12),


          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: listOfTimes.length,
              itemBuilder: (context, index){
                return _timeChip(null, listOfTimes[index], index == 1,);
              },
            ),
          ),

          // Wrap(
          //   spacing: 10,
          //   children: [
          //     _timeChip('2:30 PM', true),
          //     _timeChip('3:30 PM', false),
          //   ],
          // ),
        ],
      ),
    );
  }

  Widget _timeChip(String? day,String time, bool selected) {
    return Container(
      margin: EdgeInsets.only(right: 7),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFFFEFE5) : Colors.white,
        border: Border.all(color: selected ? Colors.orange : Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if(day != null)
          Text(day, style: TextStyle(color: selected ? Colors.orange : Colors.black, fontSize: 12)),

          if(day != null)
            SizedBox(height: 2,),

          Text(time, style: TextStyle(color: selected ? Colors.orange : Colors.black,fontSize: 12)),
        ],
      )),
    );
  }

  Widget _fareSection() {
    return Container(
      margin: EdgeInsets.only(left: 16, right: 16),
      padding: const EdgeInsets.only(left: 16, right: 16, top: 5, bottom: 5),
      decoration: BoxDecoration(
        color: HexColor("#FFF7F3"),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Image.asset("assets/service_fare_icon.png", width: 55,),

          SizedBox(width: 10,),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Service fare: ₹288', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black),),
              SizedBox(height: 6),
              Text('1 Partner to load & unload', style: TextStyle(fontWeight: FontWeight.w300, fontSize: 13, color: Colors.black)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bottomButton() {
    return Container(
      height: 205,
      padding: const EdgeInsets.only(top: 2, bottom: 2, left: 16, right: 16),
      decoration: const BoxDecoration(color: Colors.white, boxShadow: [
        BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2)),
      ]),
      child: Column(
        children: [

          const SizedBox(height: 10),

          Container(
            decoration: BoxDecoration(
              color: HexColor("#F4F4F4"),
              borderRadius: BorderRadius.circular(10),
            ),
            margin: EdgeInsets.only(left: 20, right: 20),
            padding: EdgeInsets.only(left: 10, right: 10, bottom: 5, top: 5),
            child: Center(
              child: Text.rich(
                TextSpan(
                  text: "By booking you agree to our new ",
                  style: TextStyle(fontSize: 13, color: HexColor('#A0A0A0'), fontWeight: FontWeight.w500),
                  children: [
                    TextSpan(
                      text: "terms of services",
                      style:  TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: HexColor("#0082DF"),
                      ),
                    ),
                    TextSpan(
                      text: " and ",
                      style:  TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: HexColor("#A0A0A0"),
                      ),
                    ),
                    TextSpan(
                      text: "privacy policy",
                      style:  TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: HexColor("#0082DF"),
                      ),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          _paymentSection(context),
          const SizedBox(height: 15),

          Container(
            height: 45,
            width: MediaQuery.of(context).size.width,
            margin: EdgeInsets.only(left: 15, right: 15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(7),
              color: AppColors.appColor,
            ),
            child: Center(
              child: Text('Book 3 Wheeler', style: TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w600)
              ),
            )
          ),
        ],
      ),
    );
  }


  Widget _paymentSection(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      padding: const EdgeInsets.only(left: 2, right: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          Row(
            children: [
              Image.asset("assets/credit_card.png", width: 40,),
              SizedBox(width: 10),
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  const Text(
                    "Choose Payment Method",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),

                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("Cash", style: TextStyle(fontSize: 16)),
                      Icon(Icons.keyboard_arrow_down_rounded),
                    ],
                  ),

                ],
              ),

              Spacer(),

              Column(
                children: [
                  Text(
                    "₹1405.77",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "View Breackup",
                    style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.w500,
                        fontSize: 13
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

