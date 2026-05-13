import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';

class SkyLoader extends StatefulWidget {
  final String? message;
  const SkyLoader({super.key, this.message});

  @override
  State<SkyLoader> createState() => _SkyLoaderState();
}

class _SkyLoaderState extends State<SkyLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pos;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
    _pos = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 200,
            height: 90,
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (context, _) {
                final t = _pos.value;
                // Black bunny ahead
                final blackX = t * 140.0;
                // White bunny chases 36px behind
                final whiteX = ((t - 0.14) * 140.0).clamp(0.0, 140.0);
                // Hop Y
                final pi = 3.14159;
                final blackY = (8 - (t * 2 * pi * 2).abs() % (2 * pi) < pi
                    ? 12.0 * (1 - (((t * 4) % 1) - 0.5).abs() * 2).clamp(0.0, 1.0)
                    : 0.0);
                final hopBlack = 12.0 * (1 - ((t * 2 % 1) - 0.5).abs() * 2).clamp(0.0, 1.0);
                final hopWhite = 12.0 * (1 - (((t + 0.1) * 2 % 1) - 0.5).abs() * 2).clamp(0.0, 1.0);

                return Stack(
                  children: [
                    // Track
                    Positioned(
                      bottom: 4,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    // Black bunny (túi tiền)
                    Positioned(
                      left: blackX,
                      bottom: 8 + hopBlack,
                      child: CustomPaint(
                        size: const Size(56, 70),
                        painter: _BlackBunnyPainter(),
                      ),
                    ),
                    // White bunny
                    Positioned(
                      left: whiteX,
                      bottom: 8 + hopWhite,
                      child: CustomPaint(
                        size: const Size(50, 64),
                        painter: _WhiteBunnyPainter(),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          if (widget.message != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(widget.message!, style: AppTextStyles.caption),
          ],
        ],
      ),
    );
  }
}

// ─── Black Bunny Painter ────────────────────────────────
class _BlackBunnyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 56;
    final p = Paint()..isAntiAlias = true;

    // Túi tiền vàng — vẽ trước (phía sau)
    p.color = const Color(0xFFF5C518);
    canvas.drawCircle(Offset(46*s, 14*s), 12*s, p);
    p.color = const Color(0xFF7A5800);
    p.style = PaintingStyle.stroke;
    p.strokeWidth = 2*s;
    canvas.drawCircle(Offset(46*s, 14*s), 12*s, p);
    // Miệng túi
    p.strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(40*s, 4*s), Offset(52*s, 4*s), p);
    // Ký hiệu $
    p.style = PaintingStyle.fill;
    p.color = const Color(0xFF7A5800);
    final tp = TextPainter(
      text: TextSpan(text: '\$', style: TextStyle(fontSize: 11*s, fontWeight: FontWeight.bold, color: const Color(0xFF7A5800))),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(41*s, 9*s));
    // Ánh sáng túi
    p.color = Colors.white.withOpacity(0.25);
    canvas.drawOval(Rect.fromCenter(center: Offset(42*s, 10*s), width: 6*s, height: 9*s), p);
    // Dây túi
    p.color = const Color(0xFF7A5800);
    p.style = PaintingStyle.stroke;
    p.strokeWidth = 2*s;
    p.strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(36*s, 22*s), Offset(44*s, 4*s), p);

    // Tai trái
    p.style = PaintingStyle.fill;
    p.color = const Color(0xFF2A2A2A);
    canvas.drawOval(Rect.fromCenter(center: Offset(14*s, 14*s), width: 10*s, height: 26*s), p);
    p.color = const Color(0xFF5C2D38);
    canvas.drawOval(Rect.fromCenter(center: Offset(14*s, 15*s), width: 6*s, height: 18*s), p);
    // Tai phải
    p.color = const Color(0xFF2A2A2A);
    canvas.drawOval(Rect.fromCenter(center: Offset(28*s, 12*s), width: 10*s, height: 24*s), p);
    p.color = const Color(0xFF5C2D38);
    canvas.drawOval(Rect.fromCenter(center: Offset(28*s, 13*s), width: 6*s, height: 16*s), p);

    // Nơ đỏ giữa tai
    p.color = const Color(0xFFE63030);
    final bowL = Path()..moveTo(18*s, 22*s)..lineTo(12*s, 17*s)..lineTo(18*s, 27*s)..close();
    final bowR = Path()..moveTo(18*s, 22*s)..lineTo(24*s, 17*s)..lineTo(18*s, 27*s)..close();
    canvas.drawPath(bowL, p);
    canvas.drawPath(bowR, p);
    p.color = const Color(0xFFFF5555);
    canvas.drawCircle(Offset(18*s, 17*s), 3*s, p);

    // Đầu
    p.color = const Color(0xFF2A2A2A);
    canvas.drawOval(Rect.fromCenter(center: Offset(22*s, 38*s), width: 38*s, height: 32*s), p);
    p.color = const Color(0xFF3A3A3A);
    canvas.drawOval(Rect.fromCenter(center: Offset(22*s, 40*s), width: 28*s, height: 24*s), p);
    // Má
    p.color = const Color(0xFFDD6677).withOpacity(0.4);
    canvas.drawOval(Rect.fromCenter(center: Offset(10*s, 42*s), width: 10*s, height: 7*s), p);
    canvas.drawOval(Rect.fromCenter(center: Offset(34*s, 42*s), width: 10*s, height: 7*s), p);
    // Mắt
    p.color = const Color(0xFF1C1C1C);
    canvas.drawCircle(Offset(15*s, 37*s), 5*s, p);
    p.color = Colors.white.withOpacity(0.6);
    canvas.drawOval(Rect.fromCenter(center: Offset(17*s, 34*s), width: 3*s, height: 3.5*s), p);
    p.color = const Color(0xFF1C1C1C);
    canvas.drawCircle(Offset(29*s, 37*s), 5*s, p);
    p.color = Colors.white.withOpacity(0.6);
    canvas.drawOval(Rect.fromCenter(center: Offset(31*s, 34*s), width: 3*s, height: 3.5*s), p);
    // Mũi
    p.color = const Color(0xFFBB7788);
    final noseP = Path()..moveTo(19*s, 44*s)..lineTo(22*s, 41*s)..lineTo(25*s, 44*s)..lineTo(22*s, 48*s)..close();
    canvas.drawPath(noseP, p);
    // Miệng
    p.color = const Color(0xFF666666);
    p.style = PaintingStyle.stroke;
    p.strokeWidth = 1.5*s;
    p.strokeCap = StrokeCap.round;
    canvas.drawPath(Path()..moveTo(18*s, 49*s)..quadraticBezierTo(22*s, 53*s, 26*s, 49*s), p);

    // Khăn đỏ
    p.style = PaintingStyle.fill;
    p.color = const Color(0xFFD32F2F);
    canvas.drawOval(Rect.fromCenter(center: Offset(22*s, 56*s), width: 36*s, height: 10*s), p);

    // Thân
    p.color = const Color(0xFF2A2A2A);
    canvas.drawOval(Rect.fromCenter(center: Offset(22*s, 66*s), width: 32*s, height: 20*s), p);

    // Chân trước (giơ lên)
    p.color = const Color(0xFF2A2A2A);
    canvas.save();
    canvas.translate(34*s, 62*s);
    canvas.rotate(-0.5);
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 10*s, height: 16*s), p);
    // Bàn chân
    canvas.drawOval(Rect.fromCenter(center: Offset(0, 10*s), width: 12*s, height: 7*s), p);
    canvas.restore();

    // Chân sau (đạp ra)
    canvas.save();
    canvas.translate(8*s, 68*s);
    canvas.rotate(0.4);
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 12*s, height: 18*s), p);
    canvas.drawOval(Rect.fromCenter(center: Offset(0, 11*s), width: 14*s, height: 7*s), p);
    canvas.restore();

    // Đuôi bông
    p.color = const Color(0xFF3A3A3A);
    canvas.drawCircle(Offset(6*s, 64*s), 7*s, p);
    p.color = const Color(0xFF484848);
    canvas.drawCircle(Offset(6*s, 64*s), 5*s, p);

    // Outline đầu + thân
    p.color = const Color(0xFF111111);
    p.style = PaintingStyle.stroke;
    p.strokeWidth = 2*s;
    canvas.drawOval(Rect.fromCenter(center: Offset(22*s, 38*s), width: 38*s, height: 32*s), p);
    canvas.drawOval(Rect.fromCenter(center: Offset(22*s, 66*s), width: 32*s, height: 20*s), p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─── White Bunny Painter ────────────────────────────────
class _WhiteBunnyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 50;
    final p = Paint()..isAntiAlias = true;

    // Tai trái
    p.color = const Color(0xFFEFEFEF);
    canvas.drawOval(Rect.fromCenter(center: Offset(14*s, 13*s), width: 10*s, height: 24*s), p);
    p.color = const Color(0xFFFFD0DC);
    canvas.drawOval(Rect.fromCenter(center: Offset(14*s, 14*s), width: 6*s, height: 16*s), p);
    // Tai phải
    p.color = const Color(0xFFEFEFEF);
    canvas.drawOval(Rect.fromCenter(center: Offset(28*s, 11*s), width: 10*s, height: 22*s), p);
    p.color = const Color(0xFFFFD0DC);
    canvas.drawOval(Rect.fromCenter(center: Offset(28*s, 12*s), width: 6*s, height: 14*s), p);

    // Băng đô xanh da trời
    p.color = const Color(0xFF29B6F6);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(21*s, 21*s), width: 34*s, height: 7*s), Radius.circular(3.5*s)),
      p,
    );
    p.color = const Color(0xFF81D4FA);
    p.style = PaintingStyle.stroke;
    p.strokeWidth = 1.5*s;
    p.strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(5*s, 20*s), Offset(37*s, 20*s), p);
    // Nơ băng đô
    p.style = PaintingStyle.fill;
    p.color = const Color(0xFF0288D1);
    final nb1 = Path()..moveTo(34*s, 19*s)..lineTo(40*s, 14*s)..lineTo(34*s, 24*s)..close();
    final nb2 = Path()..moveTo(40*s, 19*s)..lineTo(46*s, 14*s)..lineTo(40*s, 24*s)..close();
    canvas.drawPath(nb1, p);
    canvas.drawPath(nb2, p);
    p.color = const Color(0xFF29B6F6);
    canvas.drawCircle(Offset(40*s, 14*s), 3*s, p);

    // Đầu
    p.color = const Color(0xFFF5F5F5);
    canvas.drawOval(Rect.fromCenter(center: Offset(21*s, 36*s), width: 36*s, height: 30*s), p);
    p.color = const Color(0xFFFAFAFA);
    canvas.drawOval(Rect.fromCenter(center: Offset(21*s, 38*s), width: 26*s, height: 22*s), p);
    // Má
    p.color = const Color(0xFFFFB0C8).withOpacity(0.45);
    canvas.drawOval(Rect.fromCenter(center: Offset(9*s, 41*s), width: 10*s, height: 7*s), p);
    canvas.drawOval(Rect.fromCenter(center: Offset(33*s, 41*s), width: 10*s, height: 7*s), p);
    // Mắt
    p.color = const Color(0xFF4E342E);
    canvas.drawCircle(Offset(14*s, 35*s), 5*s, p);
    p.color = const Color(0xFF2C1810);
    canvas.drawCircle(Offset(14*s, 35*s), 3.5*s, p);
    p.color = Colors.white.withOpacity(0.65);
    canvas.drawOval(Rect.fromCenter(center: Offset(16*s, 32*s), width: 2.5*s, height: 3*s), p);
    p.color = const Color(0xFF4E342E);
    canvas.drawCircle(Offset(28*s, 35*s), 5*s, p);
    p.color = const Color(0xFF2C1810);
    canvas.drawCircle(Offset(28*s, 35*s), 3.5*s, p);
    p.color = Colors.white.withOpacity(0.65);
    canvas.drawOval(Rect.fromCenter(center: Offset(30*s, 32*s), width: 2.5*s, height: 3*s), p);
    // Mũi
    p.color = const Color(0xFFFFB0C0);
    final noseP = Path()..moveTo(18*s, 43*s)..lineTo(21*s, 40*s)..lineTo(24*s, 43*s)..lineTo(21*s, 47*s)..close();
    canvas.drawPath(noseP, p);
    // Miệng
    p.color = const Color(0xFFBBAAAA);
    p.style = PaintingStyle.stroke;
    p.strokeWidth = 1.5*s;
    p.strokeCap = StrokeCap.round;
    canvas.drawPath(Path()..moveTo(17*s, 48*s)..quadraticBezierTo(21*s, 52*s, 25*s, 48*s), p);

    // Khăn xanh da trời
    p.style = PaintingStyle.fill;
    p.color = const Color(0xFF29B6F6);
    canvas.drawOval(Rect.fromCenter(center: Offset(21*s, 54*s), width: 34*s, height: 10*s), p);
    // Đầu khăn thòng
    p.color = const Color(0xFF0288D1);
    canvas.drawOval(Rect.fromCenter(center: Offset(14*s, 59*s), width: 6*s, height: 8*s), p);

    // Thân
    p.color = const Color(0xFFF0F0F0);
    canvas.drawOval(Rect.fromCenter(center: Offset(21*s, 63*s), width: 30*s, height: 18*s), p);
    p.color = const Color(0xFFFAFAFA);
    canvas.drawOval(Rect.fromCenter(center: Offset(21*s, 63*s), width: 20*s, height: 13*s), p);

    // Chân trước (giơ lên)
    p.color = const Color(0xFFEFEFEF);
    canvas.save();
    canvas.translate(32*s, 60*s);
    canvas.rotate(-0.45);
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 9*s, height: 14*s), p);
    canvas.drawOval(Rect.fromCenter(center: Offset(0, 9*s), width: 11*s, height: 6*s), p);
    canvas.restore();

    // Chân sau (đạp ra)
    canvas.save();
    canvas.translate(8*s, 65*s);
    canvas.rotate(0.4);
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 11*s, height: 16*s), p);
    canvas.drawOval(Rect.fromCenter(center: Offset(0, 10*s), width: 13*s, height: 6*s), p);
    canvas.restore();

    // Đuôi bông
    p.color = Colors.white;
    canvas.drawCircle(Offset(5*s, 61*s), 7*s, p);
    p.color = const Color(0xFFF5F5F5);
    canvas.drawCircle(Offset(5*s, 61*s), 5*s, p);

    // Outline
    p.color = const Color(0xFFCACAC5);
    p.style = PaintingStyle.stroke;
    p.strokeWidth = 1.8*s;
    canvas.drawOval(Rect.fromCenter(center: Offset(21*s, 36*s), width: 36*s, height: 30*s), p);
    canvas.drawOval(Rect.fromCenter(center: Offset(21*s, 63*s), width: 30*s, height: 18*s), p);
    canvas.drawOval(Rect.fromCenter(center: Offset(14*s, 13*s), width: 10*s, height: 24*s), p);
    canvas.drawOval(Rect.fromCenter(center: Offset(28*s, 11*s), width: 10*s, height: 22*s), p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}