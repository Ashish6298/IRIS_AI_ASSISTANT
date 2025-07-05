 //added turn off feature









// Added turn off feature

import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:convert';
import 'dart:math';
import 'splash_screen.dart'; // Import the separate splash screen
import 'dart:async';

void main() {
  runApp(const VoiceAssistantApp());
}

class VoiceAssistantApp extends StatelessWidget {
  const VoiceAssistantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zen AI',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.transparent,
      ),
      home: const SplashScreen(),
    );
  }
}

class VoiceAssistantHomePage extends StatefulWidget {
  const VoiceAssistantHomePage({super.key});

  @override
  _VoiceAssistantHomePageState createState() => _VoiceAssistantHomePageState();
}

class _VoiceAssistantHomePageState extends State<VoiceAssistantHomePage> with TickerProviderStateMixin {
  final SpeechToText _speech = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  bool _isListening = false;
  bool _isAssistantActive = true; // Now acts as a sleep mode toggle
  String _transcribedText = '';
  String _assistantResponse = '';
  bool _isInitialized = false;
  
  Timer? _sleepModeTimer; // Timer for sleep mode polling
  Timer? _listeningTimer; // Timer to stop listening after specified duration
  
  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _micController;
  late AnimationController _gridController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _micAnimation;
  late Animation<double> _gridAnimation;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _initTts();
    _initAnimations();
  }

  void _initAnimations() {
    // Pulse animation for background effects
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    // Microphone animation
    _micController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    // Grid animation
    _gridController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _micAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _micController, curve: Curves.easeInOut),
    );

    _gridAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _gridController, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _sleepModeTimer?.cancel();
    _listeningTimer?.cancel();
    _pulseController.dispose();
    _micController.dispose();
    _gridController.dispose();
    super.dispose();
  }

  // Initialize speech-to-text
  Future<void> _initSpeech() async {
    bool available = await _speech.initialize(
      onStatus: (status) => setState(() => _isListening = status == 'listening'),
      onError: (e) {
        print('Speech recognition error: $e');
        
        // Handle the specific error that occurs in sleep mode
        if (!_isAssistantActive && e.errorMsg == 'error_no_match') {
          // In sleep mode, silently schedule next listening without showing error
          _scheduleSleepModeListening();
          return;
        }
        
        // For other errors or when active, show the error and restart
        setState(() {
          _isListening = false;
          if (_isAssistantActive) {
            _assistantResponse = 'Speech recognition error: $e';
          }
        });
        
        if (_isAssistantActive) {
          _startContinuousListening(); // Continuous listening when active
        } else {
          _scheduleSleepModeListening(); // Interval listening in sleep mode
        }
      },
    );

    if (available) {
      setState(() {
        _isInitialized = true;
        _startContinuousListening(); // Start with continuous listening
      });
    }
  }

  // Initialize text-to-speech
  Future<void> _initTts() async {
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setSpeechRate(0.5);
    _flutterTts.setCompletionHandler(() {
      if (_isAssistantActive) {
        _startContinuousListening(); // Continuous when active
      } else {
        _scheduleSleepModeListening(); // Interval when in sleep mode
      }
    });
  }

  // Continuous listening for active mode
  void _startContinuousListening() async {
    if (!_isInitialized) return;
    
    // Cancel sleep mode timer if it's running
    _sleepModeTimer?.cancel();
    _listeningTimer?.cancel();
    
    setState(() {
      _isListening = true;
      _transcribedText = '';
      if (_isAssistantActive) {
        _assistantResponse = ''; // Only clear response when active
      }
    });

    _speech.listen(
      onResult: (result) async {
        setState(() {
          _transcribedText = result.recognizedWords;
        });

        if (result.finalResult) {
          _speech.stop();
          setState(() => _isListening = false);
          String text = _transcribedText.toLowerCase().trim();
          
          // Handle turn off command (enter sleep mode)
          if (text.contains('turn off')) {
            setState(() {
              _isAssistantActive = false;
              _assistantResponse = 'Entering sleep mode. Say "Hey iris" or "Hello iris" to wake me up.';
            });
            await _flutterTts.speak(_assistantResponse);
            _scheduleSleepModeListening(); // Switch to interval listening
          } 
          // Normal command processing when active
          else if (_isAssistantActive && (text.contains('hello') || text.contains('time') || text.contains('weather') || text.contains('thank you'))) {
            await _sendToBackend(_transcribedText);
          } 
          // Restart continuous listening if active
          else if (_isAssistantActive) {
            _startContinuousListening();
          }
        }
      },
      listenFor: const Duration(seconds: 10), // Continuous listening for 10 seconds
    );
  }

  // Polling-based listening for sleep mode only
  void _startSleepModeListening() async {
    if (!_isInitialized || _isAssistantActive) return;
    
    setState(() {
      _isListening = true;
      _transcribedText = '';
    });

    // Listen for 3-5 seconds (using 4 seconds as middle ground)
    _speech.listen(
      onResult: (result) async {
        setState(() {
          _transcribedText = result.recognizedWords;
        });

        if (result.finalResult) {
          _speech.stop();
          _listeningTimer?.cancel();
          setState(() => _isListening = false);
          String text = _transcribedText.toLowerCase().trim();
          
          // Handle wake-up from sleep mode - looking for "Hey iris" or "Hello iris"
          if (!_isAssistantActive && (text.contains('hey iris') || text.contains('hello iris'))) {
            setState(() {
              _isAssistantActive = true;
              _assistantResponse = 'Hi again! I was just resting. How can I help?';
            });
            await _flutterTts.speak(_assistantResponse);
            _startContinuousListening(); // Switch to continuous listening
            return; // Exit sleep mode, don't schedule next sleep listening
          }
          
          // If wake phrase not detected, schedule next polling session
          _scheduleSleepModeListening();
        }
      },
      listenFor: const Duration(seconds: 4), // Listen for 4 seconds in sleep mode
    );

    // Auto-stop listening after 4 seconds and schedule next session
    _listeningTimer = Timer(const Duration(seconds: 4), () {
      if (_speech.isListening) {
        _speech.stop();
        setState(() => _isListening = false);
      }
      _scheduleSleepModeListening();
    });
  }

  // Schedule the next sleep mode listening session after 5-10 seconds pause
  void _scheduleSleepModeListening() {
    if (_isAssistantActive) return; // Don't schedule if assistant became active
    
    _sleepModeTimer?.cancel();
    _listeningTimer?.cancel();
    
    // Random delay between 5-10 seconds (using 7 seconds as middle ground)
    final random = Random();
    final delaySeconds = 5 + random.nextInt(6); // 5 to 10 seconds
    
    _sleepModeTimer = Timer(Duration(seconds: delaySeconds), () {
      if (mounted && !_isAssistantActive) {
        _startSleepModeListening();
      }
    });
  }

  // Main listening method that chooses the appropriate mode
  void _startListening() async {
    if (_isAssistantActive) {
      _startContinuousListening();
    } else {
      _startSleepModeListening();
    }
  }

  // Send transcribed text to Flask backend
  Future<void> _sendToBackend(String text) async {
    try {
      final response = await http.post(
        Uri.parse('http://192.168.1.102:5000/voice'), // Backend URL for Android emulator
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'message': text}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _assistantResponse = data['response'];
        });
        await _flutterTts.speak(_assistantResponse);
      } else {
        setState(() {
          _assistantResponse = 'Error communicating with server';
        });
        _startListening(); // Restart appropriate listening mode
      }
    } catch (e) {
      setState(() {
        _assistantResponse = 'Network error: $e';
      });
      _startListening(); // Restart appropriate listening mode
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([_pulseAnimation, _micAnimation, _gridAnimation]),
        builder: (context, child) {
          return Container(
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
                  painter: AIGridPainter(_gridAnimation.value),
                  size: Size(MediaQuery.of(context).size.width, MediaQuery.of(context).size.height),
                ),
                
                // Main content
                Column(
                  children: [
                    const SizedBox(height: 60),
                    // iris Title with enhanced effects
                    Text(
                      'iris',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w300,
                        color: Colors.white,
                        fontFamily: 'Orbitron',
                        letterSpacing: 8.0,
                        shadows: [
                          Shadow(
                            color: Colors.cyanAccent.withOpacity(0.8 + _pulseAnimation.value * 0.2),
                            blurRadius: 15.0 + _pulseAnimation.value * 10,
                            offset: const Offset(0, 0),
                          ),
                          Shadow(
                            color: Colors.blueAccent.withOpacity(0.5),
                            blurRadius: 25.0,
                            offset: const Offset(0, 0),
                          ),
                        ],
                      ),
                    ),
                    
                    // Subtitle
                    Text(
                      'VOICE ASSISTANT',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.cyanAccent.withOpacity(0.8),
                        fontFamily: 'Orbitron',
                        letterSpacing: 3.0,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Enhanced microphone button with AI circle (smaller size)
                            GestureDetector(
                              onTap: _startListening,
                              child: Container(
                                width: 50, // Reduced from 120
                                height: 50, // Reduced from 120
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.cyanAccent.withOpacity(0.5 + _pulseAnimation.value * 0.3),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _isListening
                                          ? Colors.redAccent.withOpacity(0.3 + _pulseAnimation.value * 0.2)
                                          : Colors.cyanAccent.withOpacity(0.3 + _pulseAnimation.value * 0.2),
                                      blurRadius: 20 + _pulseAnimation.value * 10,
                                      spreadRadius: _pulseAnimation.value * 5,
                                    ),
                                  ],
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _isListening ? Colors.redAccent : Colors.blueAccent,
                                    boxShadow: [
                                      BoxShadow(
                                        color: _isListening
                                            ? Colors.redAccent.withOpacity(0.6)
                                            : Colors.blueAccent.withOpacity(0.6),
                                        blurRadius: 15,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.mic,
                                    size: 40, // Reduced from 50
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 40),
                            
                            // Status indicator
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.cyanAccent.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _isAssistantActive ? (_isListening ? Colors.redAccent : Colors.greenAccent) : Colors.grey,
                                      boxShadow: [
                                        BoxShadow(
                                          color: _isAssistantActive
                                              ? (_isListening
                                                  ? Colors.redAccent.withOpacity(0.6)
                                                  : Colors.greenAccent.withOpacity(0.6))
                                              : Colors.grey.withOpacity(0.6),
                                          blurRadius: 4,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _isAssistantActive
                                        ? (_isListening ? 'LISTENING...' : 'READY')
                                        : 'SLEEP MODE',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white.withOpacity(0.8),
                                      fontFamily: 'Orbitron',
                                      letterSpacing: 2.0,
                                      fontWeight: FontWeight.w300,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 30),
                            
                            // Transcribed text with enhanced styling
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 30),
                              child: Text(
                                _transcribedText.isEmpty
                                    ? _isAssistantActive
                                        ? 'Say "Hello", "Time", "Weather", "Thank you", or "Turn off"'
                                        : 'Say "Hey iris" or "Hello iris" to wake up'
                                    : 'You said: $_transcribedText',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white.withOpacity(0.9),
                                  fontWeight: FontWeight.w400,
                                  fontFamily: 'Orbitron',
                                  letterSpacing: 1.0,
                                  shadows: [
                                    Shadow(
                                      blurRadius: 10.0,
                                      color: Colors.cyanAccent.withOpacity(0.6),
                                      offset: const Offset(0, 0),
                                    ),
                                  ],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            
                            const SizedBox(height: 30),
                            
                            // Enhanced assistant response
                            if (_assistantResponse.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.all(20),
                                margin: const EdgeInsets.symmetric(horizontal: 30),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.03),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.cyanAccent.withOpacity(0.4 + _pulseAnimation.value * 0.2),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.cyanAccent.withOpacity(0.2 + _pulseAnimation.value * 0.1),
                                      blurRadius: 20,
                                      spreadRadius: 5,
                                    ),
                                    BoxShadow(
                                      color: Colors.blueAccent.withOpacity(0.1),
                                      blurRadius: 30,
                                      spreadRadius: 10,
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    // Response header
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: 6,
                                          height: 6,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.cyanAccent,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.cyanAccent.withOpacity(0.6),
                                                blurRadius: 4,
                                                spreadRadius: 1,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          'iris RESPONSE',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.cyanAccent.withOpacity(0.8),
                                            fontFamily: 'Orbitron',
                                            letterSpacing: 2.0,
                                            fontWeight: FontWeight.w300,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Container(
                                          width: 6,
                                          height: 6,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.cyanAccent,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.cyanAccent.withOpacity(0.6),
                                                blurRadius: 4,
                                                spreadRadius: 1,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 15),
                                    // Response text
                                    Text(
                                      _assistantResponse,
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w400,
                                        fontFamily: 'Orbitron',
                                        letterSpacing: 1.0,
                                        shadows: [
                                          Shadow(
                                            blurRadius: 10.0,
                                            color: Colors.cyanAccent.withOpacity(0.6),
                                            offset: const Offset(0, 0),
                                          ),
                                        ],
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// Custom painter for AI neural lines background (same as splash screen)
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