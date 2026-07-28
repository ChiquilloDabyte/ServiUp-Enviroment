import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_colors.dart';

/// ServiUp's primary brand lockup.
///
/// The mark is drawn as vectors so it remains sharp without requiring
/// resolution-specific image assets.
class ServiUpLogo extends StatelessWidget {
  const ServiUpLogo({super.key, this.height = 96, this.showWordmark = true});

  final double height;
  final bool showWordmark;

  @override
  Widget build(BuildContext context) {
    final symbol = SizedBox(
      width: height * _ServiUpMarkPainter.aspectRatio,
      height: height,
      child: const CustomPaint(painter: _ServiUpMarkPainter()),
    );

    return Semantics(
      image: true,
      label: AppConstants.appName,
      child: ExcludeSemantics(
        child:
            showWordmark
                ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    symbol,
                    SizedBox(width: height * 0.12),
                    Text.rich(
                      TextSpan(
                        children: [
                          const TextSpan(
                            text: 'Servi',
                            style: TextStyle(color: _brandInk),
                          ),
                          TextSpan(
                            text: 'Up',
                            style: TextStyle(color: AppColors.primaryContainer),
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.visible,
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: height * 0.53,
                        height: 1,
                        fontWeight: FontWeight.w800,
                        letterSpacing: height * -0.025,
                      ),
                    ),
                  ],
                )
                : symbol,
      ),
    );
  }
}

const _brandInk = Color(0xFF303A40);

class _ServiUpMarkPainter extends CustomPainter {
  const _ServiUpMarkPainter();

  static const aspectRatio = 0.56;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 168, size.height / 300);

    final paint =
        Paint()
          ..color = AppColors.primaryContainer
          ..style = PaintingStyle.stroke
          ..strokeWidth = 21
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;

    final wrenchAndStem =
        Path()
          ..moveTo(53, 12)
          ..lineTo(53, 55)
          ..cubicTo(53, 75, 66, 85, 84, 85)
          ..cubicTo(102, 85, 115, 75, 115, 55)
          ..lineTo(115, 12)
          ..cubicTo(143, 27, 157, 50, 157, 75)
          ..cubicTo(157, 98, 147, 116, 132, 130)
          ..moveTo(53, 12)
          ..cubicTo(25, 27, 11, 50, 11, 75)
          ..cubicTo(11, 104, 25, 123, 41, 136)
          ..cubicTo(49, 143, 53, 153, 53, 166)
          ..lineTo(53, 255)
          ..cubicTo(53, 274, 66, 288, 84, 288)
          ..cubicTo(102, 288, 115, 274, 115, 255)
          ..lineTo(115, 183);

    canvas.drawPath(wrenchAndStem, paint);

    final arrow =
        Path()
          ..moveTo(88, 199)
          ..lineTo(115, 165)
          ..lineTo(142, 199);
    canvas.drawPath(arrow, paint);
  }

  @override
  bool shouldRepaint(covariant _ServiUpMarkPainter oldDelegate) => false;
}
