import 'package:flutter/material.dart';
import 'package:movezy_user_app/Utils/AppColors/app_colors.dart';

class ButtonWidget extends StatelessWidget {
  final VoidCallback? onTap;
  final String text;
  final double? height;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final Color? textColor;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final TextStyle? textStyle;
  final LinearGradient? linearGradient;
  final bool? isEnabled;
  final bool? showBorder;
  final Border? border;



  const ButtonWidget({
        super.key,
        this.onTap,
        required this.text,
        this.height,
        this.borderRadius,
        this.backgroundColor,
        this.textColor,
        this.padding,
        this.margin,
        this.textStyle,
        this.linearGradient,
        this.isEnabled,
        this.showBorder,
        this.border});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap ?? () {},
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Container(
        padding: padding ?? const EdgeInsets.all(0),
        width: MediaQuery.of(context).size.width,
        margin: margin ?? const EdgeInsets.all(0),
        height: height ?? 50,
        decoration: BoxDecoration(
            // Brand orange, not the olive #A2BF49 this defaulted to. That green
            // was a template leftover — nothing in the app ever selected it
            // deliberately (it appeared only here and in its own declaration),
            // yet it painted every primary button that did not pass a colour:
            // Save & Continue on both address screens, Booking Confirmation,
            // Payment Success, UPI Checkout, Profile Edit and FAQ.
            color: backgroundColor ?? AppColors.appColor,
            borderRadius: borderRadius ?? BorderRadius.circular(20),
            border: border
        ),
        child: Center(
          child: Text(
            text,
            style: textStyle ??
                TextStyle(
                    color: textColor ?? Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500),
          ),
        ),
      ),
    );
  }
}
