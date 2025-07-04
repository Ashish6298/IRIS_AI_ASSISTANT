import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'main.dart'; // Import main.dart for navigation to VoiceAssistantHomePage

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _typewriterController;
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;
  
  String _displayText = "";
  final String _fullText = "IRIS";
  int _currentIndex = 0;
  Timer? _typewriterTimer;

  @override
  void initState() {
    super.initState();
    
    // Typewriter animation controller
    _typewriterController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Fade out animation controller
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Pulse animation for AI effect
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Start pulse animation
    _pulseController.repeat(reverse: true);
    
    // Start typewriter effect
    _startTypewriter();
  }

  void _startTypewriter() {
    _typewriterTimer = Timer.periodic(const Duration(milliseconds: 400), (timer) {
      if (_currentIndex < _fullText.length) {
        setState(() {
          _displayText += _fullText[_currentIndex];
          _currentIndex++;
        });
      } else {
        timer.cancel();
        // Wait a bit, then start fade transition
        Timer(const Duration(milliseconds: 1500), () {
          _startTransition();
        });
      }
    });
  }

  void _startTransition() {
    _fadeController.forward();
    
    // Navigate after fade completes
    Timer(const Duration(milliseconds: 800), () {
      if (mounted) {
        try {
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => const VoiceAssistantHomePage(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
              transitionDuration: const Duration(milliseconds: 600),
            ),
          );
          print('Navigation to VoiceAssistantHomePage triggered');
        } catch (e) {
          print('Navigation error: $e');
        }
      }
    });
  }

  @override
  void dispose() {
    _typewriterTimer?.cancel();
    _typewriterController.dispose();
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([_fadeAnimation, _pulseAnimation]),
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF0A0E1A), // Deep space black
                    Color(0xFF1A1A2E), // Dark purple
                    Color(0xFF16213E), // Navy blue
                  ],
                ),
              ),
              child: Stack(
                children: [
                  // AI Neural Lines Background
                  CustomPaint(
                    painter: AIGridPainter(_pulseAnimation.value),
                    size: Size(MediaQuery.of(context).size.width, MediaQuery.of(context).size.height),
                  ),
                  
                  // Main content
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // AI Circle Animation
                        Container(
                          width: 120,
                          height: 120,
                          margin: const EdgeInsets.only(bottom: 40),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.cyanAccent.withOpacity(0.5 + _pulseAnimation.value * 0.5),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.cyanAccent.withOpacity(0.3 + _pulseAnimation.value * 0.3),
                                blurRadius: 20,
                                spreadRadius: _pulseAnimation.value * 5,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.cyanAccent.withOpacity(0.8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.cyanAccent.withOpacity(0.6),
                                    blurRadius: 15,
                                    spreadRadius: 3,
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.psychology,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                          ),
                        ),
                        
                        // Typewriter text
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _displayText,
                              style: TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.w300,
                                color: Colors.white,
                                fontFamily: 'Orbitron',
                                letterSpacing: 12.0,
                                shadows: [
                                  Shadow(
                                    color: Colors.cyanAccent.withOpacity(0.8),
                                    blurRadius: 10.0,
                                    offset: const Offset(0, 0),
                                  ),
                                ],
                              ),
                            ),
                            // Futuristic cursor
                            if (_currentIndex < _fullText.length)
                              AnimatedOpacity(
                                opacity: (DateTime.now().millisecondsSinceEpoch ~/ 500) % 2 == 0 ? 1.0 : 0.0,
                                duration: const Duration(milliseconds: 50),
                                child: Container(
                                  width: 3,
                                  height: 48,
                                  margin: const EdgeInsets.only(left: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.cyanAccent,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.cyanAccent.withOpacity(0.8),
                                        blurRadius: 8.0,
                                        spreadRadius: 2.0,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                        
                        const SizedBox(height: 30),
                        
                        // AI Status indicator
                        AnimatedOpacity(
                          opacity: _currentIndex >= _fullText.length ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 800),
                          child: Column(
                            children: [
                              Text(
                                'ARTIFICIAL INTELLIGENCE',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.cyanAccent.withOpacity(0.8),
                                  fontFamily: 'Orbitron',
                                  letterSpacing: 3.0,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                              const SizedBox(height: 20),
                              // Loading progress bar
                              Container(
                                width: 200,
                                height: 2,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(1),
                                ),
                                child: Stack(
                                  children: [
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 1500),
                                      width: _currentIndex >= _fullText.length ? 200 : 0,
                                      height: 2,
                                      decoration: BoxDecoration(
                                        color: Colors.cyanAccent,
                                        borderRadius: BorderRadius.circular(1),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.cyanAccent.withOpacity(0.8),
                                            blurRadius: 4.0,
                                            spreadRadius: 1.0,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'INITIALIZING...',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.6),
                                  fontFamily: 'Orbitron',
                                  letterSpacing: 2.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// Custom painter for AI neural lines background
class AIGridPainter extends CustomPainter {
  final double animationValue;
  AIGridPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final nodePaint = Paint()
      ..style = PaintingStyle.fill;

    // Generate neural network nodes
    final nodes = <Offset>[];
    final random = Random(42); // Fixed seed for consistent positions
    
    // Create nodes across the screen
    for (int i = 0; i < 25; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      
      // Add some movement to nodes
      final moveX = sin(animationValue * 2 * pi + i * 0.5) * 20;
      final moveY = cos(animationValue * 2 * pi + i * 0.3) * 15;
      
      nodes.add(Offset(x + moveX, y + moveY));
    }

    // Draw connections between nearby nodes
    for (int i = 0; i < nodes.length; i++) {
      for (int j = i + 1; j < nodes.length; j++) {
        final distance = (nodes[i] - nodes[j]).distance;
        
        if (distance < 150) { // Only connect nearby nodes
          final opacity = (1 - distance / 150) * 0.3;
          final pulseEffect = sin(animationValue * 4 * pi + i + j) * 0.1;
          
          paint.color = Colors.cyanAccent.withOpacity(opacity + pulseEffect);
          canvas.drawLine(nodes[i], nodes[j], paint);
        }
      }
    }

    // Draw neural nodes
    for (int i = 0; i < nodes.length; i++) {
      final pulseSize = 2 + sin(animationValue * 3 * pi + i * 0.7) * 1;
      final opacity = 0.4 + sin(animationValue * 2 * pi + i * 0.4) * 0.3;
      
      nodePaint.color = Colors.cyanAccent.withOpacity(opacity);
      canvas.drawCircle(nodes[i], pulseSize, nodePaint);
      
      // Add glow effect for some nodes
      if (i % 3 == 0) {
        nodePaint.color = Colors.cyanAccent.withOpacity(opacity * 0.3);
        canvas.drawCircle(nodes[i], pulseSize * 2, nodePaint);
      }
    }

    // Add some random data flow lines
    for (int i = 0; i < 8; i++) {
      final startNode = nodes[i % nodes.length];
      final endNode = nodes[(i + 3) % nodes.length];
      
      final flowProgress = (animationValue + i * 0.2) % 1.0;
      final flowPoint = Offset.lerp(startNode, endNode, flowProgress)!;
      
      // Draw flowing data point
      final flowPaint = Paint()
        ..color = Colors.white.withOpacity(0.8)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(flowPoint, 1.5, flowPaint);
      
      // Add trail effect
      for (int t = 1; t <= 3; t++) {
        final trailProgress = (flowProgress - t * 0.05).clamp(0.0, 1.0);
        final trailPoint = Offset.lerp(startNode, endNode, trailProgress)!;
        final trailOpacity = (0.4 - t * 0.1).clamp(0.0, 1.0);
        
        flowPaint.color = Colors.cyanAccent.withOpacity(trailOpacity);
        canvas.drawCircle(trailPoint, 1.0, flowPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}