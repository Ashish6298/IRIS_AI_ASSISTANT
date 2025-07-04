// //  //giving reply of hello,time and weather



// // import 'package:flutter/material.dart';
// // import 'package:speech_to_text/speech_to_text.dart';
// // import 'package:http/http.dart' as http;
// // import 'package:flutter_tts/flutter_tts.dart';
// // import 'dart:convert';

// // void main() {
// //   runApp(const VoiceAssistantApp());
// // }

// // class VoiceAssistantApp extends StatelessWidget {
// //   const VoiceAssistantApp({super.key});

// //   @override
// //   Widget build(BuildContext context) {
// //     return MaterialApp(
// //       title: 'Zen AI',
// //       theme: ThemeData(primarySwatch: Colors.blue),
// //       home: const VoiceAssistantHomePage(),
// //     );
// //   }
// // }

// // class VoiceAssistantHomePage extends StatefulWidget {
// //   const VoiceAssistantHomePage({super.key});

// //   @override
// //   _VoiceAssistantHomePageState createState() => _VoiceAssistantHomePageState();
// // }

// // class _VoiceAssistantHomePageState extends State<VoiceAssistantHomePage> {
// //   final SpeechToText _speech = SpeechToText();
// //   final FlutterTts _flutterTts = FlutterTts();
// //   bool _isListening = false;
// //   String _transcribedText = '';
// //   String _assistantResponse = '';
// //   bool _isInitialized = false;

// //   @override
// //   void initState() {
// //     super.initState();
// //     _initSpeech();
// //     _initTts();
// //   }

// //   // Initialize speech-to-text
// //   Future<void> _initSpeech() async {
// //     bool available = await _speech.initialize(
// //       onStatus: (status) => setState(() => _isListening = status == 'listening'),
// //       onError: (error) {
// //         print('Speech recognition error: $error');
// //         setState(() {
// //           _isListening = false;
// //           _assistantResponse = 'Speech recognition error: $error';
// //         });
// //         _startListening(); // Restart listening after error
// //       },
// //     );
// //     if (available) {
// //       setState(() => _isInitialized = true);
// //       _startListening(); // Start listening on app launch
// //     }
// //   }

// //   // Initialize text-to-speech
// //   Future<void> _initTts() async {
// //     await _flutterTts.setLanguage('en-US');
// //     await _flutterTts.setSpeechRate(0.5);
// //     // Set completion handler to restart listening after TTS finishes
// //     _flutterTts.setCompletionHandler(() {
// //       _startListening();
// //     });
// //   }

// //   // Start listening for voice input
// //   void _startListening() async {
// //     if (!_isInitialized) return;

// //     setState(() {
// //       _isListening = true;
// //       _transcribedText = '';
// //       _assistantResponse = '';
// //     });

// //     _speech.listen(
// //       onResult: (result) async {
// //         setState(() {
// //           _transcribedText = result.recognizedWords; // Always update transcribed text
// //         });

// //         if (result.finalResult) {
// //           _speech.stop();
// //           setState(() => _isListening = false);
// //           String text = _transcribedText.toLowerCase().trim();
// //           if (text.contains('hello') || text.contains('time') || text.contains('weather') || text.contains('thank you')) {
// //             await _sendToBackend(_transcribedText); // Send full transcribed text to backend
// //           } else {
// //             _startListening(); // Restart listening if no valid command
// //           }
// //         }
// //       },
// //       listenFor: const Duration(seconds: 10), // Listen for up to 10 seconds
// //     );
// //   }

// //   // Send transcribed text to Flask backend
// //   Future<void> _sendToBackend(String text) async {
// //     try {
// //       final response = await http.post(
// //         Uri.parse('http://192.168.1.109:5000/voice'), // Backend URL for Android emulator
// //         headers: {'Content-Type': 'application/json'},
// //         body: jsonEncode({'message': text}),
// //       );

// //       if (response.statusCode == 200) {
// //         final data = jsonDecode(response.body);
// //         setState(() {
// //           _assistantResponse = data['response'];
// //         });
// //         await _flutterTts.speak(_assistantResponse);
// //       } else {
// //         setState(() {
// //           _assistantResponse = 'Error communicating with server';
// //         });
// //         _startListening(); // Restart listening after error
// //       }
// //     } catch (e) {
// //       setState(() {
// //         _assistantResponse = 'Network error: $e';
// //       });
// //       _startListening(); // Restart listening after error
// //     }
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       body: Container(
// //         decoration: const BoxDecoration(
// //           gradient: LinearGradient(
// //             begin: Alignment.topLeft,
// //             end: Alignment.bottomRight,
// //             colors: [
// //               Color(0xFF1A237E), // Deep indigo
// //               Color(0xFF0D47A1), // Dark blue
// //               Color(0xFF4FC3F7), // Cyan accent
// //             ],
// //           ),
// //         ),
// //         child: Center(
// //           child: Column(
// //             mainAxisAlignment: MainAxisAlignment.center,
// //             children: [
// //               // Glowing microphone button
// //               GestureDetector(
// //                 onTap: _startListening, // Manual trigger to start listening
// //                 child: AnimatedContainer(
// //                   duration: const Duration(milliseconds: 300),
// //                   padding: const EdgeInsets.all(20),
// //                   decoration: BoxDecoration(
// //                     shape: BoxShape.circle,
// //                     color: _isListening ? Colors.redAccent : Colors.blueAccent,
// //                     boxShadow: [
// //                       BoxShadow(
// //                         color: _isListening
// //                             ? Colors.redAccent.withOpacity(0.5)
// //                             : Colors.blueAccent.withOpacity(0.5),
// //                         blurRadius: 20,
// //                         spreadRadius: 5,
// //                       ),
// //                     ],
// //                   ),
// //                   child: Icon(
// //                     Icons.mic,
// //                     size: 50,
// //                     color: Colors.white,
// //                   ),
// //                 ),
// //               ),
// //               const SizedBox(height: 20),
// //               // Transcribed text with neon effect
// //               Text(
// //                 _transcribedText.isEmpty ? 'Say "Hello", "Time", "Weather", or "Thank you"' : 'You said: $_transcribedText',
// //                 style: TextStyle(
// //                   fontSize: 18,
// //                   color: Colors.white,
// //                   fontWeight: FontWeight.w400,
// //                   shadows: [
// //                     Shadow(
// //                       blurRadius: 10.0,
// //                       color: Colors.cyanAccent.withOpacity(0.8),
// //                       offset: const Offset(0, 0),
// //                     ),
// //                   ],
// //                 ),
// //                 textAlign: TextAlign.center,
// //               ),
// //               const SizedBox(height: 20),
// //               // Assistant response in a futuristic card
// //               if (_assistantResponse.isNotEmpty)
// //                 Container(
// //                   padding: const EdgeInsets.all(16),
// //                   margin: const EdgeInsets.symmetric(horizontal: 20),
// //                   decoration: BoxDecoration(
// //                     color: Colors.white.withOpacity(0.1),
// //                     borderRadius: BorderRadius.circular(15),
// //                     border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
// //                     boxShadow: [
// //                       BoxShadow(
// //                         color: Colors.cyanAccent.withOpacity(0.2),
// //                         blurRadius: 15,
// //                         spreadRadius: 5,
// //                       ),
// //                     ],
// //                   ),
// //                   child: Text(
// //                     'Zeni: $_assistantResponse',
// //                     style: TextStyle(
// //                       fontSize: 18,
// //                       color: Colors.white,
// //                       fontWeight: FontWeight.bold,
// //                       shadows: [
// //                         Shadow(
// //                           blurRadius: 10.0,
// //                           color: Colors.cyanAccent.withOpacity(0.8),
// //                           offset: const Offset(0, 0),
// //                         ),
// //                       ],
// //                     ),
// //                     textAlign: TextAlign.center,
// //                   ),
// //                 ),
// //             ],
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// // }









// import 'package:flutter/material.dart';
// import 'package:speech_to_text/speech_to_text.dart';
// import 'package:http/http.dart' as http;
// import 'package:flutter_tts/flutter_tts.dart';
// import 'dart:convert';
// import 'splash_screen.dart'; // Import the separate splash screen

// void main() {
//   runApp(const VoiceAssistantApp());
// }

// class VoiceAssistantApp extends StatelessWidget {
//   const VoiceAssistantApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Zen AI',
//       theme: ThemeData(
//         primarySwatch: Colors.blue,
//         scaffoldBackgroundColor: Colors.transparent,
//       ),
//       home: const SplashScreen(),
//     );
//   }
// }

// class VoiceAssistantHomePage extends StatefulWidget {
//   const VoiceAssistantHomePage({super.key});

//   @override
//   _VoiceAssistantHomePageState createState() => _VoiceAssistantHomePageState();
// }

// class _VoiceAssistantHomePageState extends State<VoiceAssistantHomePage> with SingleTickerProviderStateMixin {
//   final SpeechToText _speech = SpeechToText();
//   final FlutterTts _flutterTts = FlutterTts();
//   bool _isListening = false;
//   String _transcribedText = '';
//   String _assistantResponse = '';
//   bool _isInitialized = false;
//   late AnimationController _animationController;
//   late Animation<double> _pulseAnimation;

//   @override
//   void initState() {
//     super.initState();
//     _initSpeech();
//     _initTts();
//     _animationController = AnimationController(
//       duration: const Duration(seconds: 2),
//       vsync: this,
//     )..repeat(reverse: true);
//     _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
//       CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
//     );
//   }

//   @override
//   void dispose() {
//     _animationController.dispose();
//     super.dispose();
//   }

//   // Initialize speech-to-text
//   Future<void> _initSpeech() async {
//     bool available = await _speech.initialize(
//       onStatus: (status) => setState(() => _isListening = status == 'listening'),
//       onError: (e) {
//         print('Speech recognition error: $e');
//         setState(() {
//           _isListening = false;
//           _assistantResponse = 'Speech recognition error: $e';
//         });
//         _startListening(); // Restart listening after error
//       },
//     );
//     if (available) {
//       setState(() {
//         _isInitialized = true;
//         _startListening(); // Start listening on app launch
//       });
//     }
//   }

//   // Initialize text-to-speech
//   Future<void> _initTts() async {
//     await _flutterTts.setLanguage('en-US');
//     await _flutterTts.setSpeechRate(0.5);
//     _flutterTts.setCompletionHandler(() {
//       _startListening();
//     });
//   }

//   // Start listening for voice input
//   void _startListening() async {
//     if (!_isInitialized) return;

//     setState(() {
//       _isListening = true;
//       _transcribedText = '';
//       _assistantResponse = '';
//     });

//     _speech.listen(
//       onResult: (result) async {
//         setState(() {
//           _transcribedText = result.recognizedWords; // Always update transcribed text
//         });

//         if (result.finalResult) {
//           _speech.stop();
//           setState(() => _isListening = false);
//           String text = _transcribedText.toLowerCase().trim();
//           if (text.contains('hello') || text.contains('time') || text.contains('weather') || text.contains('thank you')) {
//             await _sendToBackend(_transcribedText); // Send full transcribed text to backend
//           } else {
//             _startListening(); // Restart listening if no valid command
//           }
//         }
//       },
//       listenFor: const Duration(seconds: 10), // Listen for up to 10 seconds
//     );
//   }

//   // Send transcribed text to Flask backend
//   Future<void> _sendToBackend(String text) async {
//     try {
//       final response = await http.post(
//         Uri.parse('http://192.168.1.109:5000/voice'), // Backend URL for Android emulator
//         headers: {'Content-Type': 'application/json'},
//         body: jsonEncode({'message': text}),
//       );

//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         setState(() {
//           _assistantResponse = data['response'];
//         });
//         await _flutterTts.speak(_assistantResponse);
//       } else {
//         setState(() {
//           _assistantResponse = 'Error communicating with server';
//         });
//         _startListening(); // Restart listening after error
//       }
//     } catch (e) {
//       setState(() {
//         _assistantResponse = 'Network error: $e';
//       });
//       _startListening(); // Restart listening after error
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Container(
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [
//               Color(0xFF0D1B2A), // Deep space black
//               Color(0xFF1B263B), // Dark nebula blue
//               Color(0xFF00D4FF), // Neon cyan
//             ],
//           ),
//         ),
//         child: Column(
//           children: [
//             const SizedBox(height: 50),
//             // ZENI Title
//             Text(
//               'ZENI',
//               style: TextStyle(
//                 fontSize: 48,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.white,
//                 fontFamily: 'Orbitron',
//                 shadows: [
//                   Shadow(
//                     blurRadius: 20.0,
//                     color: Colors.cyanAccent.withOpacity(0.8),
//                     offset: const Offset(0, 0),
//                   ),
//                   Shadow(
//                     blurRadius: 40.0,
//                     color: Colors.blueAccent.withOpacity(0.5),
//                     offset: const Offset(0, 0),
//                   ),
//                 ],
//               ),
//             ),
//             Expanded(
//               child: Center(
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     // Pulsating microphone button
//                     GestureDetector(
//                       onTap: _startListening,
//                       child: ScaleTransition(
//                         scale: _pulseAnimation,
//                         child: Container(
//                           padding: const EdgeInsets.all(30),
//                           decoration: BoxDecoration(
//                             shape: BoxShape.circle,
//                             color: _isListening ? Colors.redAccent : Colors.blueAccent,
//                             boxShadow: [
//                               BoxShadow(
//                                 color: _isListening
//                                     ? Colors.redAccent.withOpacity(0.6)
//                                     : Colors.blueAccent.withOpacity(0.6),
//                                 blurRadius: 30,
//                                 spreadRadius: 10,
//                               ),
//                               BoxShadow(
//                                 color: Colors.cyanAccent.withOpacity(0.3),
//                                 blurRadius: 50,
//                                 spreadRadius: 20,
//                               ),
//                             ],
//                             border: Border.all(
//                               color: Colors.cyanAccent.withOpacity(0.5),
//                               width: 2,
//                             ),
//                           ),
//                           child: Icon(
//                             Icons.mic,
//                             size: 60,
//                             color: Colors.white,
//                           ),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 30),
//                     // Transcribed text with neon effect
//                     Text(
//                       _transcribedText.isEmpty
//                           ? 'Say "Hello", "Time", "Weather", or "Thank you"'
//                           : 'You said: $_transcribedText',
//                       style: TextStyle(
//                         fontSize: 20,
//                         color: Colors.white,
//                         fontWeight: FontWeight.w500,
//                         fontFamily: 'Orbitron',
//                         shadows: [
//                           Shadow(
//                             blurRadius: 15.0,
//                             color: Colors.cyanAccent.withOpacity(0.8),
//                             offset: const Offset(0, 0),
//                           ),
//                         ],
//                       ),
//                       textAlign: TextAlign.center,
//                     ),
//                     const SizedBox(height: 30),
//                     // Assistant response in a futuristic card
//                     if (_assistantResponse.isNotEmpty)
//                       Container(
//                         padding: const EdgeInsets.all(20),
//                         margin: const EdgeInsets.symmetric(horizontal: 30),
//                         decoration: BoxDecoration(
//                           color: Colors.white.withOpacity(0.05),
//                           borderRadius: BorderRadius.circular(20),
//                           border: Border.all(color: Colors.cyanAccent.withOpacity(0.4), width: 2),
//                           boxShadow: [
//                             BoxShadow(
//                               color: Colors.cyanAccent.withOpacity(0.3),
//                               blurRadius: 20,
//                               spreadRadius: 5,
//                             ),
//                             BoxShadow(
//                               color: Colors.blueAccent.withOpacity(0.2),
//                               blurRadius: 30,
//                               spreadRadius: 10,
//                             ),
//                           ],
//                         ),
//                         child: Text(
//                           'Zeni: $_assistantResponse',
//                           style: TextStyle(
//                             fontSize: 20,
//                             color: Colors.white,
//                             fontWeight: FontWeight.bold,
//                             fontFamily: 'Orbitron',
//                             shadows: [
//                               Shadow(
//                                 blurRadius: 15.0,
//                                 color: Colors.cyanAccent.withOpacity(0.8),
//                                 offset: const Offset(0, 0),
//                               ),
//                             ],
//                           ),
//                           textAlign: TextAlign.center,
//                         ),
//                       ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }






import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:convert';
import 'dart:math';
import 'splash_screen.dart'; // Import the separate splash screen

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
  String _transcribedText = '';
  String _assistantResponse = '';
  bool _isInitialized = false;
  
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
        setState(() {
          _isListening = false;
          _assistantResponse = 'Speech recognition error: $e';
        });
        _startListening(); // Restart listening after error
      },
    );
    if (available) {
      setState(() {
        _isInitialized = true;
        _startListening(); // Start listening on app launch
      });
    }
  }

  // Initialize text-to-speech
  Future<void> _initTts() async {
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setSpeechRate(0.5);
    _flutterTts.setCompletionHandler(() {
      _startListening();
    });
  }

  // Start listening for voice input
  void _startListening() async {
    if (!_isInitialized) return;

    setState(() {
      _isListening = true;
      _transcribedText = '';
      _assistantResponse = '';
    });

    _speech.listen(
      onResult: (result) async {
        setState(() {
          _transcribedText = result.recognizedWords; // Always update transcribed text
        });

        if (result.finalResult) {
          _speech.stop();
          setState(() => _isListening = false);
          String text = _transcribedText.toLowerCase().trim();
          if (text.contains('hello') || text.contains('time') || text.contains('weather') || text.contains('thank you')) {
            await _sendToBackend(_transcribedText); // Send full transcribed text to backend
          } else {
            _startListening(); // Restart listening if no valid command
          }
        }
      },
      listenFor: const Duration(seconds: 10), // Listen for up to 10 seconds
    );
  }

  // Send transcribed text to Flask backend
  Future<void> _sendToBackend(String text) async {
    try {
      final response = await http.post(
        Uri.parse('http://192.168.1.109:5000/voice'), // Backend URL for Android emulator
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
        _startListening(); // Restart listening after error
      }
    } catch (e) {
      setState(() {
        _assistantResponse = 'Network error: $e';
      });
      _startListening(); // Restart listening after error
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
                // AI Grid Pattern Background
                CustomPaint(
                  painter: AIGridPainter(_gridAnimation.value),
                  size: Size(MediaQuery.of(context).size.width, MediaQuery.of(context).size.height),
                ),
                
                // Main content
                Column(
                  children: [
                    const SizedBox(height: 60),
                    // ZENI Title with enhanced effects
                    Text(
                      'ZENI',
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
                            // Enhanced microphone button with AI circle
                            GestureDetector(
                              onTap: _startListening,
                              child: Container(
                                width: 120,
                                height: 120,
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
                                    size: 50,
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
                                      color: _isListening ? Colors.redAccent : Colors.greenAccent,
                                      boxShadow: [
                                        BoxShadow(
                                          color: _isListening 
                                            ? Colors.redAccent.withOpacity(0.6)
                                            : Colors.greenAccent.withOpacity(0.6),
                                          blurRadius: 4,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _isListening ? 'LISTENING...' : 'READY',
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
                                    ? 'Say "Hello", "Time", "Weather", or "Thank you"'
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
                                          'ZENI RESPONSE',
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

// Custom painter for AI grid background (same as splash screen)
class AIGridPainter extends CustomPainter {
  final double animationValue;

  AIGridPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.cyanAccent.withOpacity(0.1)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final spacing = 40.0;
    final rows = (size.height / spacing).ceil();
    final cols = (size.width / spacing).ceil();

    // Draw grid lines
    for (int i = 0; i <= rows; i++) {
      final y = i * spacing;
      final opacity = 0.1 + (sin(animationValue * 2 * pi + i * 0.1) * 0.05);
      paint.color = Colors.cyanAccent.withOpacity(opacity);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    for (int i = 0; i <= cols; i++) {
      final x = i * spacing;
      final opacity = 0.1 + (sin(animationValue * 2 * pi + i * 0.1) * 0.05);
      paint.color = Colors.cyanAccent.withOpacity(opacity);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Draw some random glowing dots
    final dotPaint = Paint()
      ..color = Colors.cyanAccent.withOpacity(0.4)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 20; i++) {
      final random = Random(i);
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final pulseOffset = sin(animationValue * 2 * pi + i) * 0.3;
      dotPaint.color = Colors.cyanAccent.withOpacity(0.2 + pulseOffset);
      canvas.drawCircle(Offset(x, y), 2, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}