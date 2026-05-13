import 'package:flutter/material.dart';

// ==============================================================================
// 1. Chú Mèo (MascotCat) - Premium
// ==============================================================================
class MascotCat extends StatelessWidget {
  final double size;
  const MascotCat({super.key, this.size = 80});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _CatPainterV2()),
    );
  }
}

class _CatPainterV2 extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 80;
    final p = Paint()..isAntiAlias = true;

    // Màu sắc
    const whiteMascot = Color(0xFFFFFFFF);
    const pinkEar = Color(0xFFFFBCC9);
    const blueEye = Color(0xFF42A5F5);
    const pillowGray = Color(0xFFB0BEC5); // Vẫn giữ logic cái gối từ mã cũ
    const blackOutline = Color(0xFF111111);

    // --- 1. Cơ thể & Đuôi cuộn tròn ---
    p.color = whiteMascot;
    final bodyPath = Path()
      ..moveTo(40 * s, 75 * s)
      ..quadraticBezierTo(10 * s, 75 * s, 5 * s, 50 * s)
      ..quadraticBezierTo(5 * s, 15 * s, 40 * s, 15 * s)
      ..quadraticBezierTo(75 * s, 15 * s, 75 * s, 50 * s)
      ..quadraticBezierTo(75 * s, 75 * s, 40 * s, 75 * s)
      ..close();
    canvas.drawPath(bodyPath, p);

    // --- 2. Đầu bờm xờm ---
    final headPath = Path()
      ..moveTo(20 * s, 35 * s)
      ..cubicTo(10 * s, 20 * s, 25 * s, 5 * s, 40 * s, 20 * s)
      ..cubicTo(55 * s, 5 * s, 70 * s, 20 * s, 60 * s, 35 * s)
      ..quadraticBezierTo(75 * s, 50 * s, 60 * s, 60 * s)
      ..quadraticBezierTo(40 * s, 70 * s, 20 * s, 60 * s)
      ..quadraticBezierTo(5 * s, 50 * s, 20 * s, 35 * s)
      ..close();
    canvas.drawPath(headPath, p);

    // --- 3. Tai ---
    final leftEar = Path()..moveTo(20*s, 28*s)..lineTo(12*s, 5*s)..lineTo(35*s, 22*s)..close();
    final rightEar = Path()..moveTo(60*s, 28*s)..lineTo(68*s, 5*s)..lineTo(45*s, 22*s)..close();
    canvas.drawPath(leftEar, p); canvas.drawPath(rightEar, p);
    p.color = pinkEar;
    canvas.drawPath(Path()..moveTo(22*s, 26*s)..lineTo(16*s, 9*s)..lineTo(33*s, 22*s)..close(), p);
    canvas.drawPath(Path()..moveTo(58*s, 26*s)..lineTo(64*s, 9*s)..lineTo(47*s, 22*s)..close(), p);

    // --- 4. Gối ---
    p.color = pillowGray;
    final pillowPath = Path()
      ..moveTo(55*s, 50*s)..quadraticBezierTo(45*s, 42*s, 58*s, 40*s)
      ..quadraticBezierTo(70*s, 38*s, 72*s, 48*s)..quadraticBezierTo(75*s, 58*s, 65*s, 60*s)
      ..quadraticBezierTo(55*s, 62*s, 55*s, 50*s)..close();
    canvas.drawPath(pillowPath, p);

    // --- 5. Đôi mắt & Chi tiết ---
    p.color = blueEye;
    canvas.drawOval(Rect.fromCenter(center: Offset(55*s, 40*s), width: 8*s, height: 12*s), p);
    
    p.color = blackOutline; p.style = PaintingStyle.stroke; p.strokeWidth = 1.2*s;
    canvas.drawPath(Path()..moveTo(25*s, 38*s)..quadraticBezierTo(35*s, 34*s, 45*s, 38*s), p); // Mắt nhắm
    canvas.drawPath(Path()..moveTo(40*s, 45*s)..lineTo(40*s, 48*s), p); // Mũi/miệng

    // --- 6. Đường viền ---
    p.strokeWidth = 1.8*s;
    canvas.drawPath(bodyPath, p); canvas.drawPath(headPath, p);
    canvas.drawPath(leftEar, p); canvas.drawPath(rightEar, p); canvas.drawPath(pillowPath, p);
  }
  @override bool shouldRepaint(CustomPainter old) => false;
}

// ==============================================================================
// 2. Chú Chó (MascotDog) - Premium
// ==============================================================================
class MascotDog extends StatelessWidget {
  final double size;
  const MascotDog({super.key, this.size = 80});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _DogPainterV2()),
    );
  }
}

class _DogPainterV2 extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 80;
    final p = Paint()..isAntiAlias = true;

    // Colors
    const darkBody = Color(0xFF424242);
    const lightFace = Color(0xFFEEEEEE);
    const bandanaColor = Color(0xFF1E88E5);
    const blackOutline = Color(0xFF111111);

    // Body
    p.color = darkBody;
    final body = Path()
      ..moveTo(20*s, 70*s)..quadraticBezierTo(40*s, 78*s, 60*s, 70*s)
      ..lineTo(65*s, 50*s)..quadraticBezierTo(40*s, 45*s, 15*s, 50*s)..close();
    canvas.drawPath(body, p);

    // Head
    final head = Path()
      ..moveTo(22*s, 50*s)..cubicTo(10*s, 25*s, 25*s, 5*s, 40*s, 10*s)
      ..cubicTo(55*s, 5*s, 70*s, 25*s, 58*s, 50*s)..close();
    canvas.drawPath(head, p);

    // Face Patch
    p.color = lightFace;
    canvas.drawOval(Rect.fromCenter(center: Offset(40*s, 40*s), width: 30*s, height: 20*s), p);

    // Bandana
    p.color = bandanaColor;
    final bandana = Path()..moveTo(22*s, 50*s)..quadraticBezierTo(40*s, 60*s, 58*s, 50*s)..lineTo(40*s, 65*s)..close();
    canvas.drawPath(bandana, p);

    // Eyes & Nose
    p.color = blackOutline;
    canvas.drawCircle(Offset(32*s, 35*s), 2.5*s, p);
    canvas.drawCircle(Offset(48*s, 35*s), 2.5*s, p);
    canvas.drawOval(Rect.fromCenter(center: Offset(40*s, 42*s), width: 4*s, height: 3*s), p);

    // Outline
    p.style = PaintingStyle.stroke; p.strokeWidth = 1.8*s;
    canvas.drawPath(body, p); canvas.drawPath(head, p); canvas.drawPath(bandana, p);
  }
  @override bool shouldRepaint(CustomPainter old) => false;
}

// ==============================================================================
// 3. Thỏ Hồng (MascotPinkBunny) - Premium
// ==============================================================================
class MascotPinkBunny extends StatelessWidget {
  final double size;
  const MascotPinkBunny({super.key, this.size = 80});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _PinkBunnyPainterV2()),
    );
  }
}

class _PinkBunnyPainterV2 extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 80;
    final p = Paint()..isAntiAlias = true;

    // Colors
    const bunnyPink = Color(0xFFF8BBD9);
    const innerPink = Color(0xFFF48FB1);
    const bowColor = Color(0xFFB71C1C);
    const blackOutline = Color(0xFF111111);

    // Body
    p.color = bunnyPink;
    final body = Path()
      ..moveTo(25*s, 70*s)..quadraticBezierTo(40*s, 75*s, 55*s, 70*s)
      ..lineTo(58*s, 45*s)..quadraticBezierTo(40*s, 40*s, 22*s, 45*s)..close();
    canvas.drawPath(body, p);

    // Head
    final head = Path()
      ..moveTo(22*s, 45*s)..cubicTo(10*s, 25*s, 25*s, 10*s, 40*s, 15*s)
      ..cubicTo(55*s, 10*s, 70*s, 25*s, 58*s, 45*s)..close();
    canvas.drawPath(head, p);

    // Ears
    final leftEar = Path()
      ..moveTo(22*s, 25*s)..lineTo(15*s, 0*s)..lineTo(30*s, 18*s)..close();
    final rightEar = Path()
      ..moveTo(58*s, 25*s)..lineTo(65*s, 0*s)..lineTo(50*s, 18*s)..close();
    canvas.drawPath(leftEar, p); canvas.drawPath(rightEar, p);
    
    p.color = innerPink;
    canvas.drawPath(Path()..moveTo(23*s, 23*s)..lineTo(18*s, 5*s)..lineTo(29*s, 19*s)..close(), p);
    canvas.drawPath(Path()..moveTo(57*s, 23*s)..lineTo(62*s, 5*s)..lineTo(51*s, 19*s)..close(), p);

    // Bow
    p.color = bowColor;
    final bow = Path()
      ..moveTo(40*s, 50*s)..lineTo(32*s, 42*s)..lineTo(40*s, 58*s)..close();
    final bowR = Path()
      ..moveTo(40*s, 50*s)..lineTo(48*s, 42*s)..lineTo(40*s, 58*s)..close();
    canvas.drawPath(bow, p); canvas.drawPath(bowR, p);

    // Eyes
    p.color = blackOutline;
    canvas.drawCircle(Offset(32*s, 32*s), 2*s, p);
    canvas.drawCircle(Offset(48*s, 32*s), 2*s, p);

    // Outline
    p.style = PaintingStyle.stroke; p.strokeWidth = 1.8*s;
    canvas.drawPath(body, p); canvas.drawPath(head, p); canvas.drawPath(leftEar, p); canvas.drawPath(rightEar, p);
  }
  @override bool shouldRepaint(CustomPainter old) => false;
}

// ==============================================================================
// 4. Cáo (MascotFox) - Premium
// ==============================================================================
class MascotFox extends StatelessWidget {
  final double size;
  const MascotFox({super.key, this.size = 80});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _FoxPainterV2()),
    );
  }
}

class _FoxPainterV2 extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 80;
    final p = Paint()..isAntiAlias = true;

    const wolfRed = Color(0xFFB71C1C);
    const whiteChest = Color(0xFFFFF9C4);
    const blackOutline = Color(0xFF111111);

    // Spiky Head (Đầu lông nhọn)
    p.color = wolfRed;
    final head = Path()
      ..moveTo(20*s, 50*s)..lineTo(15*s, 30*s)..lineTo(30*s, 35*s) // Tai trái
      ..lineTo(40*s, 15*s) // Tóc dựng
      ..lineTo(50*s, 35*s)..lineTo(65*s, 30*s) // Tai phải
      ..lineTo(60*s, 50*s)..quadraticBezierTo(40*s, 65*s, 20*s, 50*s)..close();
    canvas.drawPath(head, p);

    // Chest
    p.color = whiteChest;
    canvas.drawPath(Path()..moveTo(30*s, 55*s)..quadraticBezierTo(40*s, 68*s, 50*s, 55*s)..close(), p);

    // Angry/Sharp Eyes
    p.color = blackOutline;
    p.style = PaintingStyle.stroke; p.strokeWidth = 1.5*s;
    canvas.drawPath(Path()..moveTo(28*s, 40*s)..lineTo(38*s, 43*s)..lineTo(28*s, 45*s), p);
    canvas.drawPath(Path()..moveTo(52*s, 40*s)..lineTo(42*s, 43*s)..lineTo(52*s, 45*s), p);

    // Outline
    p.strokeWidth = 1.8*s;
    canvas.drawPath(head, p);
  }
  @override bool shouldRepaint(CustomPainter old) => false;
}

// ==============================================================================
// 5. Thỏ Đen (MascotBlackBunny) - Premium
// ==============================================================================
class MascotBlackBunny extends StatelessWidget {
  final double size;
  const MascotBlackBunny({super.key, this.size = 50}); // Vẫn giữ size 50

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _BlackBunnyPainterV2()),
    );
  }
}

class _BlackBunnyPainterV2 extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 50;
    final p = Paint()..isAntiAlias = true;

    // Colors
    const blackBunny = Color(0xFF424242);
    const bowColor = Color(0xFFB71C1C);
    const moneyBagColor = Color(0xFFFFB300); // Vẫn giữ logic túi tiền
    const blackOutline = Color(0xFF111111);

    // Head
    p.color = blackBunny;
    final head = Path()
      ..moveTo(15*s, 25*s)..cubicTo(5*s, 10*s, 15*s, 0*s, 25*s, 5*s)
      ..cubicTo(35*s, 0*s, 45*s, 10*s, 35*s, 25*s)..close();
    canvas.drawPath(head, p);

    // Ears
    final leftEar = Path()..moveTo(15*s, 15*s)..lineTo(10*s, 0*s)..lineTo(20*s, 10*s)..close();
    final rightEar = Path()..moveTo(35*s, 15*s)..lineTo(40*s, 0*s)..lineTo(30*s, 10*s)..close();
    canvas.drawPath(leftEar, p); canvas.drawPath(rightEar, p);

    // Money Bag (on back)
    p.color = moneyBagColor;
    canvas.drawCircle(Offset(40*s, 30*s), 8*s, p);

    // Bow
    p.color = bowColor;
    canvas.drawPath(Path()..moveTo(25*s, 35*s)..lineTo(20*s, 30*s)..lineTo(25*s, 40*s)..close(), p);
    canvas.drawPath(Path()..moveTo(25*s, 35*s)..lineTo(30*s, 30*s)..lineTo(25*s, 40*s)..close(), p);

    // Eyes
    p.color = const Color(0xFFEEEEEE); // Mắt trắng trên nền đen
    canvas.drawCircle(Offset(20*s, 20*s), 1.5*s, p);
    canvas.drawCircle(Offset(30*s, 20*s), 1.5*s, p);

    // Outline
    p.color = blackOutline; p.style = PaintingStyle.stroke; p.strokeWidth = 1.2*s;
    canvas.drawPath(head, p); canvas.drawPath(leftEar, p); canvas.drawPath(rightEar, p);
    canvas.drawCircle(Offset(40*s, 30*s), 8*s, p); // Viền túi tiền
  }
  @override bool shouldRepaint(CustomPainter old) => false;
}

// ==============================================================================
// 6. Hươu, Cú (Giữ nguyên cấu trúc Oval từ mã cũ vì code cũ đã khá rõ)
// ==============================================================================
// ─── Deer ───────────────────────────────────────────────
class MascotDeer extends StatelessWidget {
  final double size;
  const MascotDeer({super.key, this.size = 80});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _DeerPainterV2()), // Sửa thành PainterV2
    );
  }
}

class _DeerPainterV2 extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 80;
    final p = Paint()..isAntiAlias = true;

    const deerColor = Color(0xFFD7CCC8);
    const antlerColor = Color(0xFF5D4037);
    const blackOutline = Color(0xFF111111);

    // Antlers (Sừng)
    p.color = antlerColor; p.style = PaintingStyle.stroke; p.strokeWidth = 2*s; p.strokeCap = StrokeCap.round;
    canvas.drawPath(Path()..moveTo(30*s, 20*s)..lineTo(20*s, 5*s)..lineTo(10*s, 10*s), p);
    canvas.drawPath(Path()..moveTo(50*s, 20*s)..lineTo(60*s, 5*s)..lineTo(70*s, 10*s), p);

    // Head & Body
    p.style = PaintingStyle.fill; p.color = deerColor;
    final head = Path()
      ..moveTo(25*s, 50*s)..quadraticBezierTo(15*s, 25*s, 40*s, 20*s)
      ..quadraticBezierTo(65*s, 25*s, 55*s, 50*s)..close();
    canvas.drawPath(head, p);

    // Bowtie (Nơ đen)
    p.color = blackOutline;
    canvas.drawCircle(Offset(40*s, 60*s), 3*s, p);

    // Eyes (Điềm tĩnh)
    canvas.drawOval(Rect.fromCenter(center: Offset(33*s, 38*s), width: 6*s, height: 8*s), p);
    canvas.drawOval(Rect.fromCenter(center: Offset(47*s, 38*s), width: 6*s, height: 8*s), p);

    // Outline
    p.style = PaintingStyle.stroke; p.strokeWidth = 1.8*s;
    canvas.drawPath(head, p);
  }
  @override bool shouldRepaint(CustomPainter old) => false;
}

// ─── Owl ────────────────────────────────────────────────
class MascotOwl extends StatelessWidget {
  final double size;
  const MascotOwl({super.key, this.size = 80});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _OwlPainterV2()), // Sửa thành PainterV2
    );
  }
}

class _OwlPainterV2 extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 80;
    final p = Paint()..isAntiAlias = true;

    p.color = const Color(0xFF8D6E63);
    canvas.drawOval(Rect.fromCenter(center: Offset(40*s, 50*s), width: 50*s, height: 60*s), p);
    canvas.drawOval(Rect.fromCenter(center: Offset(40*s, 25*s), width: 45*s, height: 40*s), p);

    p.color = const Color(0xFFD7CCC8);
    canvas.drawOval(Rect.fromCenter(center: Offset(40*s, 25*s), width: 35*s, height: 30*s), p);

    p.color = const Color(0xFF5D4037); p.style = PaintingStyle.stroke; p.strokeWidth = 1.5*s;
    canvas.drawCircle(Offset(32*s, 25*s), 7*s, p);
    canvas.drawCircle(Offset(48*s, 25*s), 7*s, p);

    p.color = const Color(0xFFFFB300); p.style = PaintingStyle.fill;
    canvas.drawPath(Path()..moveTo(40*s, 30*s)..lineTo(36*s, 35*s)..lineTo(44*s, 35*s)..close(), p);

    p.color = const Color(0xFF111111); p.style = PaintingStyle.stroke; p.strokeWidth = 1.8*s;
    canvas.drawOval(Rect.fromCenter(center: Offset(40*s, 50*s), width: 50*s, height: 60*s), p);
    canvas.drawOval(Rect.fromCenter(center: Offset(40*s, 25*s), width: 45*s, height: 40*s), p);
  }
  @override bool shouldRepaint(CustomPainter old) => false;
}

// ─── White Bunny (loading) (Giữ nguyên cấu trúc từ mã cũ vì nó dùng Oval khá ổn) ───
class MascotWhiteBunny extends StatelessWidget {
  final double size;
  const MascotWhiteBunny({super.key, this.size = 50}); // Size 50

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _WhiteBunnyPainterV2()), // Sửa thành PainterV2
    );
  }
}

class _WhiteBunnyPainterV2 extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 50;
    final p = Paint()..isAntiAlias = true;

    p.color = Colors.white;
    canvas.drawOval(Rect.fromCenter(center: Offset(25*s, 30*s), width: 35*s, height: 30*s), p);
    canvas.drawOval(Rect.fromCenter(center: Offset(18*s, 10*s), width: 8*s, height: 20*s), p);
    canvas.drawOval(Rect.fromCenter(center: Offset(32*s, 10*s), width: 8*s, height: 20*s), p);

    p.color = const Color(0xFFB0BEC5); // Headband
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(25*s, 18*s), width: 28*s, height: 5*s), Radius.circular(3*s)), p);

    p.color = const Color(0xFF5D4037); // Eyes
    canvas.drawCircle(Offset(21*s, 28*s), 1.5*s, p);
    canvas.drawCircle(Offset(29*s, 28*s), 1.5*s, p);

    p.color = const Color(0xFFEF9A9A); // Scarf
    canvas.drawOval(Rect.fromCenter(center: Offset(25*s, 38*s), width: 32*s, height: 6*s), p);

    p.color = const Color(0xFF111111); p.style = PaintingStyle.stroke; p.strokeWidth = 1.2*s;
    canvas.drawOval(Rect.fromCenter(center: Offset(25*s, 30*s), width: 35*s, height: 30*s), p);
  }
  @override bool shouldRepaint(CustomPainter old) => false;
}