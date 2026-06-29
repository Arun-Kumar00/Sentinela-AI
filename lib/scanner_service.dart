import 'package:flutter/services.dart';

// class ScannerService {
//   // 🟢 THE BRIDGE TO JAVA
//   static const MethodChannel _platform = MethodChannel('sentinela.dev/security');
//
//   // Function to trigger the Java malware scan
//   static Future<String> runBinaryScan(String filePath) async {
//     try {
//       // Send the file path to Java
//       final String result = await _platform.invokeMethod('startForensicScan', {"path": filePath});
//       return result;
//     } on PlatformException catch (e) {
//       return "ERROR: Failed to talk to Java Sandbox: '${e.message}'.";
//     } catch (e) {
//       return "ERROR: An unexpected error occurred.";
//     }
//   }
// }
class ScannerService {
  // Must match the Java channel exactly
  static const MethodChannel _channel = MethodChannel('com.sentinela.forensics/binary_scanner');

  static Future<String> runBinaryScan(String filePath) async {
    try {
      // Calls the Java executePhase4Scan method and passes the file path
      final String result = await _channel.invokeMethod('scanBinary', {'filePath': filePath});
      return result;
    } catch (e) {
      return "ERROR: Bridge to Java Sandbox failed - $e";
    }
  }
}