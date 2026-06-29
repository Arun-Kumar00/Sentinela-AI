import 'package:flutter/material.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'dart:io';
import 'ai_service.dart';
import 'scanner_service.dart'; // 🟢 Imports your new service

class ForensicDashboard extends StatefulWidget {
  const ForensicDashboard({super.key});

  @override
  State<ForensicDashboard> createState() => _ForensicDashboardState();
}

class _ForensicDashboardState extends State<ForensicDashboard> {
  File? _sharedFile;
  String _fileStatus = "Safe Mode Active. Waiting for a file...";
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();

    ReceiveSharingIntent.instance.getMediaStream().listen((List<SharedMediaFile> value) {
      if (value.isNotEmpty) {
        setState(() {
          _sharedFile = File(value.first.path);
          _fileStatus = "File loaded into Secure Sandbox.";
          _isScanning = false;
        });
      }
    }, onError: (err) {
      print("🔴 INTENT STREAM ERROR: $err");
    });

    ReceiveSharingIntent.instance.getInitialMedia().then((List<SharedMediaFile> value) {
      if (value.isNotEmpty) {
        setState(() {
          _sharedFile = File(value.first.path);
          _fileStatus = "File loaded into Secure Sandbox.";
          _isScanning = false;
        });
      }
    });
  }

  // 🟢 FUNCTION THAT CALLS YOUR SCANNER SERVICE
  // Future<void> _startScan() async {
  //   if (_sharedFile == null) return;
  //
  //   setState(() {
  //     _isScanning = true;
  //     _fileStatus = "Analyzing binary headers in Sandbox...";
  //   });
  //
  //   // Talk to Java via the Scanner Service
  //   String result = await ScannerService.runBinaryScan(_sharedFile!.path);
  //
  //   setState(() {
  //     _isScanning = false;
  //     _fileStatus = result;
  //   });
  //
  //   // Show result popup
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     SnackBar(
  //       content: Text(result, style: const TextStyle(fontWeight: FontWeight.bold)),
  //       backgroundColor: result.contains("THREAT") ? Colors.red : Colors.green,
  //       duration: const Duration(seconds: 4),
  //     ),
  //   );
  // }
  // 🟢 Make sure you import the AI service at the top of the file!
  // import 'ai_service.dart';

  // 🟢 THE MULTIMODAL SCAN ENGINE
  Future<void> _startScan() async {
    if (_sharedFile == null) return;

    setState(() {
      _isScanning = true;
      _fileStatus = "Running Multimodal Security Scan...\nAnalyzing Pixels & Binary...";
    });

    // 1. Fire Phase 1: Java Binary & Metadata Scan
    String binaryResult = await ScannerService.runBinaryScan(_sharedFile!.path);

    // 2. Fire Phase 2: AI Visual Pixel Scan
    String aiResult = await AIService.scanImage(_sharedFile!.path);

    setState(() {
      _isScanning = false;
      // Combine both results on the screen
      _fileStatus = "🛡️ FORENSIC REPORT 🛡️\n\n"
          "1️⃣ Binary/Metadata Layer:\n$binaryResult\n\n"
          "2️⃣ Visual AI Layer:\n$aiResult";
    });

    // Determine overall threat level (If either scanner finds a threat, turn red!)
    bool isThreat = binaryResult.contains("THREAT") || aiResult.contains("THREAT");

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Scan Complete. Check Dashboard for full report.", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: isThreat ? Colors.red : Colors.green,
        duration: const Duration(seconds: 4),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Sentinela-AI Scanner", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueGrey[900],
        foregroundColor: Colors.white,
      ),
      // 🟢 Added a SingleChildScrollView so the screen doesn't overflow on small phones
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: _sharedFile == null
                ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 100), // Spacing for empty state
                Icon(Icons.security, size: 100, color: Colors.blueGrey[300]),
                const SizedBox(height: 20),
                Text(
                  _fileStatus,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            )
                : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: _fileStatus.contains("THREAT") ? Colors.red : Colors.blueAccent,
                        width: 3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: Image.file(
                      _sharedFile!,
                      height: 250, // Slightly reduced height to fit the report
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 250,
                          color: Colors.grey[300],
                          alignment: Alignment.center,
                          child: const Text("Image secured in Sandbox.", style: TextStyle(color: Colors.red)),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "File Name:\n${_sharedFile!.path.split('/').last}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                // 🟢 THE MISSING PIECE: THE FORENSIC REPORT TERMINAL
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _fileStatus.contains("THREAT") ? Colors.redAccent : Colors.greenAccent,
                      width: 2,
                    ),
                  ),
                  child: Text(
                    _fileStatus,
                    style: TextStyle(
                      color: _fileStatus.contains("THREAT") ? Colors.red[300] : Colors.green[300],
                      fontFamily: 'monospace', // Gives it that cybersecurity terminal look
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 🟢 UPDATED BUTTON TO TRIGGER SCAN
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey[900],
                      foregroundColor: Colors.white,
                    ),
                    icon: _isScanning
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.radar),
                    label: Text(_isScanning ? "SCANNING..." : "INITIATE DEEP SCAN", style: const TextStyle(fontSize: 16)),
                    onPressed: _isScanning ? null : _startScan,
                  ),
                ),

                const SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _sharedFile = null;
                      _fileStatus = "Safe Mode Active. Waiting for a file...";
                    });
                  },
                  child: const Text("Discard File", style: TextStyle(color: Colors.red)),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     backgroundColor: Colors.grey[100],
  //     appBar: AppBar(
  //       title: const Text("Sentinela-AI Scanner", style: TextStyle(fontWeight: FontWeight.bold)),
  //       backgroundColor: Colors.blueGrey[900],
  //       foregroundColor: Colors.white,
  //     ),
  //     body: Center(
  //       child: Padding(
  //         padding: const EdgeInsets.all(20.0),
  //         child: _sharedFile == null
  //             ? Column(
  //           mainAxisAlignment: MainAxisAlignment.center,
  //           children: [
  //             Icon(Icons.security, size: 100, color: Colors.blueGrey[300]),
  //             const SizedBox(height: 20),
  //             Text(
  //               _fileStatus,
  //               textAlign: TextAlign.center,
  //               style: const TextStyle(fontSize: 18, color: Colors.grey),
  //             ),
  //           ],
  //         )
  //             : Column(
  //           mainAxisAlignment: MainAxisAlignment.center,
  //           children: [
  //             Container(
  //               decoration: BoxDecoration(
  //                 border: Border.all(
  //                     color: _fileStatus.contains("THREAT") ? Colors.red : Colors.blueAccent,
  //                     width: 3),
  //                 borderRadius: BorderRadius.circular(10),
  //               ),
  //               child: ClipRRect(
  //                 borderRadius: BorderRadius.circular(7),
  //                 child: Image.file(
  //                   _sharedFile!,
  //                   height: 300,
  //                   fit: BoxFit.cover,
  //                   errorBuilder: (context, error, stackTrace) {
  //                     return Container(
  //                       height: 300,
  //                       color: Colors.grey[300],
  //                       alignment: Alignment.center,
  //                       child: const Text("Image secured in Sandbox.", style: TextStyle(color: Colors.red)),
  //                     );
  //                   },
  //                 ),
  //               ),
  //             ),
  //             const SizedBox(height: 20),
  //             Text(
  //               "File Name:\n${_sharedFile!.path.split('/').last}",
  //               textAlign: TextAlign.center,
  //               style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
  //             ),
  //             const SizedBox(height: 30),
  //
  //             // 🟢 UPDATED BUTTON TO TRIGGER SCAN
  //             SizedBox(
  //               width: double.infinity,
  //               height: 55,
  //               child: ElevatedButton.icon(
  //                 style: ElevatedButton.styleFrom(
  //                   backgroundColor: Colors.blueGrey[900],
  //                   foregroundColor: Colors.white,
  //                 ),
  //                 icon: _isScanning
  //                     ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
  //                     : const Icon(Icons.radar),
  //                 label: Text(_isScanning ? "SCANNING..." : "INITIATE DEEP SCAN", style: const TextStyle(fontSize: 16)),
  //                 onPressed: _isScanning ? null : _startScan,
  //               ),
  //             ),
  //
  //             const SizedBox(height: 15),
  //             TextButton(
  //               onPressed: () {
  //                 setState(() {
  //                   _sharedFile = null;
  //                   _fileStatus = "Safe Mode Active. Waiting for a file...";
  //                 });
  //               },
  //               child: const Text("Discard File", style: TextStyle(color: Colors.red)),
  //             )
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }
}