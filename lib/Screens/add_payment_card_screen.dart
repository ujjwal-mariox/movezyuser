import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:movezy_user_app/CommonWidgets/app_bar.dart';
import 'package:movezy_user_app/CommonWidgets/wallet_widget.dart';
import 'package:hexcolor/hexcolor.dart';


class AddPaymentCardScreen extends StatelessWidget {
  const AddPaymentCardScreen({super.key});

  @override
  Widget build(BuildContext context) {

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.dark,
    )
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            commonAppBar(
                height : 100,
                context : context,
                child: Container(
                  padding: const EdgeInsets.only(top: 45),
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
                      Text(
                        "Notification Management",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      Spacer(),

                      walletWidget(context),

                      SizedBox(width: 15,),
                    ],
                  ),
                )
            ),

            SizedBox(height: 3,),
            
            Container(
              padding: EdgeInsets.all(14),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCardItem(
                    icon: Image.asset(
                      'assets/payments/mastercard_icon.png',
                      height: 30,
                      width: 30,
                    ),
                    title: 'Credit Card',
                    subtitle: '**** **** **** 1234',
                  ),
                  _buildCardItem(
                    icon: Image.asset(
                      'assets/payments/visa_icon.png',
                      height: 30,
                      width: 30,
                    ),
                    title: 'Debit Card',
                    subtitle: '**** **** **** 1234',
                  ),
                  _buildCardItem(
                    icon: Image.asset(
                      'assets/payments/digital_wallet.png',
                      height: 30,
                      width: 30,
                    ),
                    title: 'Digital Wallet',
                    subtitle: 'abcd@paytm.com',
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Add New Card',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 10),
              
                  // Add Card Form
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical:13),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: EdgeInsets.only(left: 12, right: 12, top: 10, bottom: 10),
                          child: _buildDropdownField('Card name', 'Select your card'),
                        ),
                        const SizedBox(height: 12),
                        Container(
                            padding: EdgeInsets.only(left: 12, right: 12, top: 10, bottom: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: _buildCardNumberField()),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                  padding: EdgeInsets.only(left: 12, right: 12, top: 10, bottom: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: _buildTextField('Expiration', 'MM/YY')),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Container(
                                padding: EdgeInsets.only(left: 12, right: 12, top: 10, bottom: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: _buildTextField(
                                  'CVC',
                                  'CVC',
                                  suffix: Icon(
                                    Icons.credit_card,
                                    color: Colors.grey.shade600,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                            padding: EdgeInsets.only(left: 12, right: 12, top: 10, bottom: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: _buildDropdownField('ZIP / Postal Code', '*** ***')),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0A65C2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text(
                              'Add Card',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 17),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: HexColor("#A2BF49"),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'Done',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 4),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Card List Item
  Widget _buildCardItem({
    required Widget icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5C882), width: 1),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              icon,
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),

          Spacer(),

          Container(
            decoration: BoxDecoration(
              color: HexColor("#ADADAD").withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey)
            ),
              child: Icon(Icons.add, color: HexColor("#EDAE10"), size: 16)),

          SizedBox(width: 5,),

          Text(
            'Add',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),


          SizedBox(width: 15,)

        ],
      ),
    );
  }

  // Dropdown Field
  Widget _buildDropdownField(String label, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: Colors.black)),
        const SizedBox(height: 6),
        Container(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                hint,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
              const Icon(Icons.keyboard_arrow_down,
                  color: Colors.grey, size: 24),
            ],
          ),
        ),
      ],
    );
  }

  // Card Number Field
  Widget _buildCardNumberField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Card number',
            style: TextStyle(
                fontWeight: FontWeight.w500, fontSize: 14, color: Colors.black)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '#### #### #### ####',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              Row(
                children: [
                  Image.asset('assets/payments/visa_icon.png',width: 25, height: 25),
                  const SizedBox(width: 5),
                  Image.asset('assets/payments/mastercard_icon.png', width: 23, height: 23),
                  const SizedBox(width: 5),
                  Image.asset('assets/payments/amex_icon.png', width: 23, height: 23),
                  const SizedBox(width: 5),
                  Image.asset('assets/payments/digital_wallet.png', width: 23, height: 23),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Simple TextField
  Widget _buildTextField(String label, String hint, {Widget? suffix}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.w500, fontSize: 14, color: Colors.black)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(hint,
                  style:
                  TextStyle(color: Colors.grey.shade600, fontSize: 14)),
              if (suffix != null) suffix,
            ],
          ),
        ),
      ],
    );
  }
}
