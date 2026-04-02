import 'dart:math' as math;
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ENTRY POINT
// ─────────────────────────────────────────────────────────────────────────────
void main() => runApp(const _App());

class _App extends StatelessWidget {
  const _App();
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(useMaterial3: true),
    home: const AiMatchingScreen(),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// static design colour
// ─────────────────────────────────────────────────────────────────────────────
class _C {
  static const primary      = Color(0xFF2D3FE0);
  static const primaryLight = Color(0xFFEEF0FC);
  static const primarySoft  = Color(0xFFDFE3FA);
  static const textDark     = Color(0xFF0F1020);
  static const textSub      = Color(0xFF5C5F7A);
  static const border       = Color(0xFFE8E9F0);
  static const bg           = Color(0xFFF5F6FA);
  static const white        = Color(0xFFFFFFFF);
  static const ringOuter    = Color(0xFFB0B8EC);
  static const ringInner    = Color(0xFFC8CEEE);
}

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class AiMatchingScreen extends StatefulWidget {
  const AiMatchingScreen({super.key});
  @override
  State<AiMatchingScreen> createState() => _AiMatchingScreenState();
}

class _AiMatchingScreenState extends State<AiMatchingScreen>
    with TickerProviderStateMixin {
  late final AnimationController _rotate = AnimationController(
      vsync: this, duration: const Duration(seconds: 20))
    ..repeat();
  late final AnimationController _float = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2800))
    ..repeat(reverse: true);
  int _navIndex = 0;

  @override
  void dispose() {
    _rotate.dispose();
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        backgroundColor: _C.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: _C.textDark),
          onPressed: () {},
        ),
        title: Text('AI Matching',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _C.textDark)),
        bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(height: 1, color: _C.border)),
      ),
      body: Column(children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(children: [
              const SizedBox(height: 16),
              _HeroCard(rotate: _rotate, float: _float),
              const SizedBox(height: 20),
              Text('How JobBuddy Works',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: _C.textDark)),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'Our AI-powered engine analyzes millions of data points to find your perfect career match.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 13, color: _C.textSub, height: 1.6),
                ),
              ),
              const SizedBox(height: 24),
              const _StepsList(),
            ]),
          ),
        ),
        Container(
          color: _C.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: _PrimaryButton(
            label: 'Start Matching Now',
            trailing: const Icon(Icons.arrow_forward_rounded,
                color: _C.white, size: 18),
            onTap: () {},
          ),
        ),
        _BottomNav(
            current: _navIndex,
            onTap: (i) => setState(() => _navIndex = i)),
      ]),
    );
  }
}

// HERO CARD
class _HeroCard extends StatelessWidget {
  final AnimationController rotate;
  final AnimationController float;
  const _HeroCard({required this.rotate, required this.float});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 168,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_C.primaryLight, _C.primarySoft],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(alignment: Alignment.center, children: [
          // Outer ring (clockwise)
          AnimatedBuilder(
            animation: rotate,
            builder: (_, __) => Transform.rotate(
              angle: rotate.value * 2 * math.pi,
              child: CustomPaint(
                size: const Size(180, 180),
                painter: _DashedRing(radius: 90, color: _C.ringOuter),
              ),
            ),
          ),
          // Inner ring (counter-clockwise)
          AnimatedBuilder(
            animation: rotate,
            builder: (_, __) => Transform.rotate(
              angle: -rotate.value * 2 * math.pi * 1.3,
              child: CustomPaint(
                size: const Size(300, 120),
                painter: _DashedRing(radius: 60, color: _C.ringInner),
              ),
            ),
          ),
          // Floating center icon
          AnimatedBuilder(
            animation: float,
            builder: (_, child) => Transform.translate(
                offset: Offset(0, -6 + float.value * 6), child: child),
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: _C.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                      color: _C.primary.withOpacity(0.2),
                      blurRadius: 24,
                      offset: const Offset(0, 8))
                ],
              ),
              child: const Icon(Icons.hub_rounded, color: _C.primary, size: 34),
            ),
          ),
          Positioned(
              top: 28,
              right: 52,
              child: _Badge(icon: Icons.description_rounded)),
          Positioned(
              bottom: 28,
              left: 52,
              child: _Badge(icon: Icons.auto_awesome_rounded)),
        ]),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  const _Badge({required this.icon});
  @override
  Widget build(BuildContext context) => Container(
    width: 30,
    height: 30,
    decoration: BoxDecoration(
        color: _C.primary, borderRadius: BorderRadius.circular(8)),
    child: Icon(icon, color: _C.white, size: 16),
  );
}

class _DashedRing extends CustomPainter {
  final double radius;
  final Color color;
  const _DashedRing({required this.radius, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    const count = 20;
    const step = 2 * math.pi / count;
    const gap = 0.4;
    final center = Offset(size.width / 2, size.height / 2);
    for (int i = 0; i < count; i++) {
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
          i * step, step * (1 - gap), false, paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// STEPS
class _StepsList extends StatelessWidget {
  const _StepsList();

  static const _data = [
    (
    num: '1',
    icon: Icons.storage_rounded,
    title: 'Data Collection',
    desc:
    'We securely aggregate your experience, skills, and preferences from your uploaded documents and profile.'
    ),
    (
    num: '2',
    icon: Icons.psychology_rounded,
    title: 'Deep Analysis',
    desc:
    'Our ML models identify hidden patterns in your career trajectory and cross-reference them with market trends.'
    ),
    (
    num: '3',
    icon: Icons.auto_fix_high_rounded,
    title: 'Smart Prediction',
    desc:
    'Receive a curated list of opportunities with a "Match Score" that predicts your success and satisfaction.'
    ),
  ];

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Column(children: [
      for (int i = 0; i < _data.length; i++)
        _Step(data: _data[i], isLast: i == _data.length - 1),
    ]),
  );
}

class _Step extends StatelessWidget {
  final ({String num, IconData icon, String title, String desc}) data;
  final bool isLast;
  const _Step({required this.data, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Column(children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
                color: _C.primary,
                borderRadius: BorderRadius.circular(10)),
            alignment: Alignment.center,
            child: Text(data.num,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _C.white)),
          ),
          if (!isLast)
            Expanded(
                child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: _C.border)),
        ]),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: 4, bottom: isLast ? 0 : 20),
            child:
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(data.icon, color: _C.primary, size: 22),
                const SizedBox(width: 8),
                Text(data.title,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _C.textDark)),
              ]),
              const SizedBox(height: 6),
              Text(data.desc,
                  style: TextStyle(
                      fontSize: 12.5, color: _C.textSub, height: 1.6)),
            ]),
          ),
        ),
      ]),
    );
  }
}

// SHARED WIDGETS
class _PrimaryButton extends StatelessWidget {
  final String label;
  final Widget? trailing;
  final VoidCallback? onTap;
  const _PrimaryButton({required this.label, this.trailing, this.onTap});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: Material(
      color: _C.primary,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: _C.primary.withOpacity(0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 8))
            ],
          ),
          child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _C.white)),
                if (trailing != null) ...[
                  const SizedBox(width: 8),
                  trailing!
                ],
              ]),
        ),
      ),
    ),
  );
}

class _BottomNav extends StatelessWidget {
  final int current;
  final ValueChanged<int> onTap;
  const _BottomNav({required this.current, required this.onTap});

  static const _items = [
    (icon: Icons.home_rounded, label: 'Home'),
    (icon: Icons.bookmark_outline_rounded, label: 'Saved'),
    (icon: Icons.work_outline_rounded, label: 'Applied'),
    (icon: Icons.person_outline_rounded, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
        color: _C.white,
        border: Border(top: BorderSide(color: _C.border))),
    child: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(children: [
          for (int i = 0; i < _items.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => onTap(i),
                behavior: HitTestBehavior.opaque,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(_items[i].icon,
                      color:
                      i == current ? _C.primary : _C.textSub,
                      size: 22),
                  const SizedBox(height: 3),
                  Text(_items[i].label,
                      style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: i == current
                              ? _C.primary
                              : _C.textSub)),
                ]),
              ),
            ),
        ]),
      ),
    ),
  );
}