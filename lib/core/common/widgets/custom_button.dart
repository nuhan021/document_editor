import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../utils/constants/colors.dart';
import '../../utils/constants/icon_path.dart';
import '../styles/global_text_style.dart';

class CustomButton extends StatelessWidget {
  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isIcon = false,
    this.gradient,
    this.color,
    this.textColor,
    this.isLoading = false,
  });

  final String text;
  final VoidCallback onPressed;
  final bool? isIcon;
  final Gradient? gradient;
  final Color? color;
  final Color? textColor;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final effectiveGradient = gradient ?? const LinearGradient(
      begin: Alignment(-0.7, -0.8),
      end: Alignment(0.7, 0.8),
      colors: [
        Color(0xFFA78BFA),
        Color(0xFF5835C0),
      ],
      stops: [0.1541, 0.8459],
    );
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.maxFinite,
        height: 52.h,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(60.r),
          gradient: color != null ? null : effectiveGradient,
          // 2. The Box Shadow
        ),
        child: isLoading ? Center(child: CircularProgressIndicator(),) : Center(
          child: Text(
            text,
            style: getTextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}