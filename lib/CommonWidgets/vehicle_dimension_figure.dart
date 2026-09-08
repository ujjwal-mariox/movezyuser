import 'package:flutter/material.dart';
import 'package:movezy_user_app/ApiUrls/api_urls.dart';
import 'package:movezy_user_app/Utils/AppColors/app_colors.dart';

/// The vehicle picture with its length drawn above it and its height beside
/// it, the way marketplace listings show a truck ("10ft" over the body,
/// "6ft" down the side). Both figures come from the admin's vehicle type;
/// a bracket is only drawn when its value is known, so a type without
/// dimensions still shows a clean picture.
class VehicleDimensionFigure extends StatelessWidget {
  final String? imageUrl;
  final double lengthFt;
  final double heightFt;
  final double width;
  final double height;

  const VehicleDimensionFigure({
    super.key,
    required this.imageUrl,
    this.lengthFt = 0,
    this.heightFt = 0,
    this.width = 118,
    this.height = 86,
  });

  static String fmt(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final showLength = lengthFt > 0;
    final showHeight = heightFt > 0;
    // Gutters for the brackets and their labels.
    final leftGutter = showHeight ? 34.0 : 0.0;
    final topGutter = showLength ? 22.0 : 0.0;
    final imageW = width - leftGutter;
    final imageH = height - topGutter;

    final image = (imageUrl != null && imageUrl!.isNotEmpty)
        ? Image.network(
            ApiUrls.imageProxyUrl(imageUrl!),
            width: imageW,
            height: imageH,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) =>
                Icon(Icons.local_shipping, size: imageH * 0.7, color: AppColors.appColor),
          )
        : Icon(Icons.local_shipping, size: imageH * 0.7, color: AppColors.appColor);

    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _DimensionPainter(
          lengthLabel: showLength ? '${fmt(lengthFt)}ft' : null,
          heightLabel: showHeight ? '${fmt(heightFt)}ft' : null,
          leftGutter: leftGutter,
          topGutter: topGutter,
        ),
        child: Padding(
          padding: EdgeInsets.only(left: leftGutter, top: topGutter),
          child: Center(child: image),
        ),
      ),
    );
  }
}

class _DimensionPainter extends CustomPainter {
  final String? lengthLabel;
  final String? heightLabel;
  final double leftGutter;
  final double topGutter;

  _DimensionPainter({
    required this.lengthLabel,
    required this.heightLabel,
    required this.leftGutter,
    required this.topGutter,
  });

  static const _lineColor = Color(0xFF9CA3AF);
  static const _textColor = Color(0xFF6B7280);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _lineColor
      ..strokeWidth = 1.1
      ..style = PaintingStyle.stroke;
    const tick = 4.0;
    const inset = 6.0; // brackets sit slightly inside the picture box edges

    if (lengthLabel != null) {
      final y = topGutter - 8;
      final x1 = leftGutter + inset;
      final x2 = size.width - inset;
      canvas.drawLine(Offset(x1, y), Offset(x2, y), paint);
      canvas.drawLine(Offset(x1, y - tick), Offset(x1, y + tick), paint);
      canvas.drawLine(Offset(x2, y - tick), Offset(x2, y + tick), paint);
      final tp = TextPainter(
        text: TextSpan(
          text: lengthLabel,
          style: const TextStyle(fontSize: 11, color: _textColor, fontWeight: FontWeight.w500),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      // Label sits on the line with a white pad so it reads over the stroke.
      final lx = (x1 + x2) / 2 - tp.width / 2;
      final ly = y - tp.height / 2;
      canvas.drawRect(
        Rect.fromLTWH(lx - 3, ly, tp.width + 6, tp.height),
        Paint()..color = Colors.white.withValues(alpha: 0.92),
      );
      tp.paint(canvas, Offset(lx, ly));
    }

    if (heightLabel != null) {
      final x = leftGutter - 6;
      final y1 = topGutter + inset;
      final y2 = size.height - inset;
      canvas.drawLine(Offset(x, y1), Offset(x, y2), paint);
      canvas.drawLine(Offset(x - tick, y1), Offset(x + tick, y1), paint);
      canvas.drawLine(Offset(x - tick, y2), Offset(x + tick, y2), paint);
      final tp = TextPainter(
        text: TextSpan(
          text: heightLabel,
          style: const TextStyle(fontSize: 11, color: _textColor, fontWeight: FontWeight.w500),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: leftGutter - 8);
      tp.paint(canvas, Offset((x - 8 - tp.width).clamp(0.0, x), (y1 + y2) / 2 - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _DimensionPainter old) =>
      old.lengthLabel != lengthLabel ||
      old.heightLabel != heightLabel ||
      old.leftGutter != leftGutter ||
      old.topGutter != topGutter;
}
