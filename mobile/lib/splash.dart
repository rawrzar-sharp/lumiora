import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'main.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _mainController;
  
  late Animation<double> _logoFade;
  late Animation<double> _logoScale;
  late Animation<double> _textFade;
  
  final Color primaryGreen = const Color(0xFF7B8C2A);
  final Color lightMatcha = const Color(0xFFC3D668);
  final Color baseCream = const Color(0xFFEBE5D9);
  final Color textDark = const Color(0xFF2C3028);

  final List<Map<String, dynamic>> _blockConfigs = [
    {'align': const Alignment(-1.2, -1.2), 'w': 0.35, 'h': 0.25, 'color': const Color(0xFFDCE2B9), 'start': 0.0, 'end': 0.3, 'offset': const Offset(-1, -1), 'rot': -0.5},
    {'align': const Alignment(1.2, -0.85), 'w': 0.45, 'h': 0.2, 'color': const Color(0xFF7B8C2A).withOpacity(0.8), 'start': 0.1, 'end': 0.4, 'offset': const Offset(1, -1), 'rot': 0.3},
    {'align': const Alignment(-0.9, -0.3), 'w': 0.2, 'h': 0.3, 'color': const Color(0xFF4A4D4A).withOpacity(0.08), 'start': 0.2, 'end': 0.5, 'offset': const Offset(-1, 0), 'rot': -0.2},
    {'align': const Alignment(1.2, -0.2), 'w': 0.3, 'h': 0.35, 'color': const Color(0xFFDCE2B9).withOpacity(0.6), 'start': 0.3, 'end': 0.6, 'offset': const Offset(1, 0), 'rot': 0.4},
    {'align': const Alignment(-1.1, 0.5), 'w': 0.4, 'h': 0.2, 'color': const Color(0xFF7B8C2A).withOpacity(0.9), 'start': 0.4, 'end': 0.7, 'offset': const Offset(-1, 1), 'rot': -0.4},
    {'align': const Alignment(0.9, 0.6), 'w': 0.25, 'h': 0.25, 'color': const Color(0xFF4A4D4A).withOpacity(0.12), 'start': 0.5, 'end': 0.8, 'offset': const Offset(1, 1), 'rot': 0.2},
    {'align': const Alignment(-0.6, 1.2), 'w': 0.45, 'h': 0.3, 'color': const Color(0xFFDCE2B9), 'start': 0.6, 'end': 0.9, 'offset': const Offset(0, 1), 'rot': -0.3},
    {'align': const Alignment(1.2, 1.2), 'w': 0.5, 'h': 0.25, 'color': const Color(0xFF7B8C2A), 'start': 0.7, 'end': 1.0, 'offset': const Offset(1, 1), 'rot': 0.5},
  ];

  late List<Animation<Offset>> _blockSlides;
  late List<Animation<double>> _blockFades;
  late List<Animation<double>> _blockRotations;
  late List<Animation<double>> _blockScales;
@override
void initState() {
  super.initState();

  // 1. Inisialisasi Controller
  _mainController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  );

  // 2. Definisi Animasi DULU
  _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
    CurvedAnimation(parent: _mainController, curve: const Interval(0.2, 0.4, curve: Curves.easeIn)),
  );
  _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
    CurvedAnimation(parent: _mainController, curve: const Interval(0.2, 0.5, curve: Curves.elasticOut)),
  );
  _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
    CurvedAnimation(parent: _mainController, curve: const Interval(0.4, 0.6, curve: Curves.easeIn)),
  );

  // 3. Tambahkan listener untuk navigasi saat animasi selesai
  _mainController.addStatusListener((status) {
    if (status == AnimationStatus.completed) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  });

  // 4. Jalankan animasi
  _mainController.forward();



    _blockSlides = [];
    _blockFades = [];
    _blockRotations = [];
    _blockScales = [];

    for (var config in _blockConfigs) {
      final curve = CurvedAnimation(
        parent: _mainController,
        curve: Interval(config['start'], config['end'], curve: Curves.easeOutQuart),
      );

      _blockSlides.add(Tween<Offset>(begin: config['offset'], end: Offset.zero).animate(curve));
      _blockFades.add(Tween<double>(begin: 0.0, end: 1.0).animate(curve));
      _blockRotations.add(Tween<double>(begin: config['rot'], end: 0.0).animate(curve));
      _blockScales.add(Tween<double>(begin: 0.5, end: 1.0).animate(curve));
    }

    _mainController.forward();

    _mainController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const HomeScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 1000), 
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: baseCream,
      body: Stack(
        children: [
          // 1. LIQUID WAVE BACKGROUND (Continuous Animation)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _mainController,
              builder: (context, _) {
                return CustomPaint(
                  painter: FluidWavePainter(progress: _mainController.value),
                );
              },
            ),
          ),

          // 2. STAGGERED GEOMETRIC BLOCKS
          ...List.generate(_blockConfigs.length, (index) {
            final config = _blockConfigs[index];
            return Align(
              alignment: config['align'],
              child: SlideTransition(
                position: _blockSlides[index],
                child: FadeTransition(
                  opacity: _blockFades[index],
                  child: RotationTransition(
                    turns: _blockRotations[index],
                    child: ScaleTransition(
                      scale: _blockScales[index],
                      child: Container(
                        width: size.width * config['w'],
                        height: size.height * config['h'],
                        decoration: BoxDecoration(
                          color: config['color'],
                          borderRadius: BorderRadius.circular(40), // Softer, organic corners
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),

          // 3. CENTER CONTENT (Logo, Typography, Pulse)
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo Container with Heartbeat Pulse
                AnimatedBuilder(
                  animation: _mainController,
                  builder: (context, child) {
                    // Calculate a subtle heartbeat pulse after the initial scale finishes
                    double heartbeat = 1.0;
                    if (_mainController.value > 0.3) {
                      heartbeat = 1.0 + (math.sin((_mainController.value - 0.3) * math.pi * 30) * 0.03);
                    }
                    return FadeTransition(
                      opacity: _logoFade,
                      child: Transform.scale(
                        scale: _logoScale.value * heartbeat,
                        child: child,
                      ),
                    );
                  },
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6F4EE),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 35,
                          spreadRadius: 5,
                          offset: const Offset(0, 15),
                        )
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/logo_lumiora.png', 
                        fit: BoxFit.cover, 
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                
                // Typography
                FadeTransition(
                  opacity: _textFade,
                  child: Column(
                    children: [
                      Text(
                        'L U M I O R A',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 10.0,
                          color: textDark,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Freshly Baked & Brewed Daily',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: textDark.withOpacity(0.6),
                          letterSpacing: 3.0,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 70),
                
                // Loader
                FadeTransition(
                  opacity: _textFade,
                  child: SizedBox(
                    width: 30,
                    height: 30,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.0,
                      valueColor: AlwaysStoppedAnimation<Color>(primaryGreen),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 4. HALAL BADGE (Fades in slowly at bottom left)
          Positioned(
            left: 24,
            bottom: 32,
            child: FadeTransition(
              opacity: _textFade,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.verified_user_rounded, // Replace with your Halal asset if preferred
                    color: Color(0xFF384319),
                    size: 34,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'HALAL\nINDONESIA',
                    style: TextStyle(
                      fontFamily: 'Sans-Serif',
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF384319),
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom Painter that creates "Liquid" moving waves and shifting dot patterns
class FluidWavePainter extends CustomPainter {
  final double progress; // Ranges from 0.0 to 1.0 over 20 seconds

  FluidWavePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    final Paint lightMatcha = Paint()..color = const Color(0xFFC3D668).withOpacity(0.6);
    final Paint darkForest = Paint()..color = const Color(0xFF384319).withOpacity(0.8);

    // Oscillation values for organic movement
    // math.pi * 8 means it will wave back and forth 4 times over the 20 seconds
    double wave1 = math.sin(progress * math.pi * 8); 
    double wave2 = math.cos(progress * math.pi * 6);

    // 1. Top Right Liquid Wave
    final Path topPath = Path()
      ..moveTo(w * 0.2, 0)
      ..cubicTo(
        w * 0.5 + (wave1 * 40), h * 0.1 + (wave2 * 20), 
        w * 0.8 + (wave2 * 30), h * 0.15 + (wave1 * 30), 
        w, h * 0.25
      )
      ..lineTo(w, 0)
      ..close();
    canvas.drawPath(topPath, lightMatcha);

    // 2. Bottom Left Dark Liquid Wave
    final Path bottomPath = Path()
      ..moveTo(0, h * 0.65)
      ..cubicTo(
        w * 0.3 + (wave2 * 40), h * 0.7 + (wave1 * 30), 
        w * 0.5 + (wave1 * 30), h * 0.9 + (wave2 * 20), 
        w * 0.8, h
      )
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(bottomPath, darkForest);

    // 3. Parallax Floating Dots (They drift slowly downwards and leftwards)
    final Paint dotPaint = Paint()..color = const Color(0xFF536122).withOpacity(0.15);
    
    double driftX = progress * 100; // Drift left
    double driftY = progress * 150; // Drift down

    for (int i = -2; i < 10; i++) {
      for (int j = -2; j < 12; j++) {
        // Create a matrix that wraps around smoothly
        double xPos = (w * 0.5 + (i * 25) - driftX) % (w * 1.5);
        double yPos = (h * 0.1 + (j * 25) + driftY) % (h * 1.2);
        
        // Only draw dots in certain areas to mimic the reference image
        if (xPos > w * 0.4 || yPos < h * 0.4) {
          // Add a slight pulse to the dot radius
          double pulseRadius = 2.5 + (math.sin((progress * math.pi * 20) + i + j) * 1.0);
          canvas.drawCircle(Offset(xPos, yPos), pulseRadius, dotPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant FluidWavePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}