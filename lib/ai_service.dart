// // import 'package:tflite_flutter/tflite_flutter.dart';
// // import 'package:image/image.dart' as img;
// // import 'dart:io';
// //
// // class AIService {
// //   static Interpreter? _interpreter;
// //
// //   // 1. WAKE UP THE AI BRAIN
// //   static Future<void> loadModel() async {
// //     try {
// //       // NOTE: Make sure your downloaded model is named exactly this!
// //       _interpreter = await Interpreter.fromAsset('assets/models/deepfake_model.tflite');
// //       print("🟢 AI Model Loaded Successfully");
// //     } catch (e) {
// //       print("🔴 Error loading AI model: $e");
// //     }
// //   }
// //
// //   // 2. SCAN THE IMAGE
// //   static Future<String> scanImage(String filePath) async {
// //     if (_interpreter == null) return "ERROR: AI Model is offline or missing.";
// //
// //     try {
// //       // A. Load and resize the image to 224x224 pixels
// //       File file = File(filePath);
// //       img.Image? rawImage = img.decodeImage(file.readAsBytesSync());
// //       if (rawImage == null) return "ERROR: Failed to read image pixels.";
// //       img.Image resizedImage = img.copyResize(rawImage, width: 224, height: 224);
// //
// //       // B. Convert the image into a mathematical matrix (1 x 224 x 224 x 3)
// //       var input = List.generate(1, (i) => List.generate(224, (j) => List.generate(224, (k) => List.filled(3, 0.0))));
// //       for (int y = 0; y < 224; y++) {
// //         for (int x = 0; x < 224; x++) {
// //           img.Pixel pixel = resizedImage.getPixel(x, y);
// //           // Normalize RGB values from 0-255 down to 0.0-1.0
// //           input[0][y][x][0] = pixel.r / 255.0;
// //           input[0][y][x][1] = pixel.g / 255.0;
// //           input[0][y][x][2] = pixel.b / 255.0;
// //         }
// //       }
// //
// //       // C. Prepare the output matrix (Assuming the model returns [Real_Prob, Fake_Prob])
// //       var output = List.filled(1 * 2, 0.0).reshape([1, 2]);
// //
// //       // D. Run the neural network!
// //       _interpreter!.run(input, output);
// //
// //       // E. Interpret the results
// //       double fakeProb = output[0][1];
// //
// //       if (fakeProb > 0.60) {
// //         return "🔴 AI VISUAL THREAT: ${(fakeProb * 100).toStringAsFixed(1)}% likely to be AI-Generated.";
// //       } else {
// //         return "🟢 VISUAL SAFE: Natural pixel structure detected.";
// //       }
// //     } catch (e) {
// //       return "ERROR: Visual scan failed - $e";
// //     }
// //   }
// // }
// import 'package:tflite_flutter/tflite_flutter.dart';
// import 'package:image/image.dart' as img;
// import 'dart:io';
//
// class AIService {
//   static Interpreter? _interpreter;
//
//   // 1. WAKE UP THE AI BRAIN
//   static Future<void> loadModel() async {
//     try {
//       _interpreter = await Interpreter.fromAsset('assets/models/deepfake_model.tflite');
//
//       // 🟢 DIAGNOSTICS: Let's see what the model actually wants!
//       var inputShape = _interpreter!.getInputTensor(0).shape;
//       var outputShape = _interpreter!.getOutputTensor(0).shape;
//       print("====================================");
//       print("🧠 AI MODEL SUCCESSFULLY LOADED");
//       print("📥 IT WANTS AN IMAGE SHAPED LIKE: $inputShape");
//       print("📤 IT WILL OUTPUT A RESULT SHAPED: $outputShape");
//       print("====================================");
//
//     } catch (e) {
//       print("🔴 Error loading AI model: $e");
//     }
//   }
//   static Future<String> scanImageHD(String filePath) async {
//     if (_interpreter == null) return "ERROR: AI offline.";
//
//     // 1. Get Model Shape Requirements
//     var inputTensor = _interpreter!.getInputTensor(0);
//     int patchWidth = inputTensor.shape[1]; // e.g., 32 or 224
//     int patchHeight = inputTensor.shape[2];
//
//     // 2. Load the Original HD Image
//     File file = File(filePath);
//     img.Image? rawImage = img.decodeImage(file.readAsBytesSync());
//     if (rawImage == null) return "ERROR: Failed to read image.";
//
//     // 3. Prepare the Grid Analytics
//     int columns = rawImage.width ~/ patchWidth;
//     int rows = rawImage.height ~/ patchHeight;
//     int totalPatches = columns * rows;
//     int threatCount = 0;
//     List<String> threatCoordinates = [];
//
//     print("Starting HD Grid Scan: $columns x $rows ($totalPatches patches)");
//
//     // 4. THE SLIDING WINDOW LOOP
//     for (int y = 0; y < rows; y++) {
//       for (int x = 0; x < columns; x++) {
//
//         // Cut out a perfect 32x32 HD square from the grid
//         img.Image patch = img.copyCrop(
//             rawImage,
//             x: x * patchWidth,
//             y: y * patchHeight,
//             width: patchWidth,
//             height: patchHeight
//         );
//
//         // Run this specific patch through your TFLite model
//         // (Assuming you extract your TFLite logic into a helper function)
//         double patchThreatScore = await runModelOnPatch(patch);
//
//         // If this specific square is a Deepfake, log it!
//         if (patchThreatScore > 0.60) {
//           threatCount++;
//           threatCoordinates.add("[Row: $y, Col: $x]");
//         }
//       }
//     }
//
//     // 5. Final Forensic Verdict
//     if (threatCount > 0) {
//       double percentageInfected = (threatCount / totalPatches) * 100;
//       return "🔴 THREAT: ${percentageInfected.toStringAsFixed(1)}% of image area is AI-Generated.\n"
//           "Anomalies found at: ${threatCoordinates.join(', ')}";
//     } else {
//       return "🟢 SAFE: HD Grid Scan complete. 0 anomalies found.";
//     }
//   }
//   // 2. SCAN THE IMAGE
//   static Future<String> scanImage(String filePath) async {
//     if (_interpreter == null) return "ERROR: AI Model is offline.";
//
//     try {
//       // A. Ask the model for its required height and width (usually index 1 and 2 of the shape)
//       var inputTensor = _interpreter!.getInputTensor(0);
//       int expectedHeight = inputTensor.shape[1]; // Will likely read '32'
//       int expectedWidth = inputTensor.shape[2];  // Will likely read '32'
//
//       // B. Load and resize the image dynamically!
//       File file = File(filePath);
//       img.Image? rawImage = img.decodeImage(file.readAsBytesSync());
//       if (rawImage == null) return "ERROR: Failed to read image pixels.";
//
//       img.Image resizedImage = img.copyResize(rawImage, width: expectedWidth, height: expectedHeight);
//
//       // C. Build the dynamic input matrix
//       var input = List.generate(1, (i) => List.generate(expectedHeight, (j) => List.generate(expectedWidth, (k) => List.filled(3, 0.0))));
//       for (int y = 0; y < expectedHeight; y++) {
//         for (int x = 0; x < expectedWidth; x++) {
//           img.Pixel pixel = resizedImage.getPixel(x, y);
//           // Normalize RGB values from 0-255 down to 0.0-1.0
//           input[0][y][x][0] = pixel.r / 255.0;
//           input[0][y][x][1] = pixel.g / 255.0;
//           input[0][y][x][2] = pixel.b / 255.0;
//         }
//       }
//
//       // D. Check the output shape (Is it 1 number or 2 numbers?)
//       var outputTensor = _interpreter!.getOutputTensor(0);
//       int outputSize = outputTensor.shape.last; // Will read '1' or '2'
//
//       var output = List.filled(1 * outputSize, 0.0).reshape([1, outputSize]);
//
//       // E. Run the neural network!
//       _interpreter!.run(input, output);
//
//       // F. Interpret the results dynamically
//       double aiScore = 0.0;
//       if (outputSize == 1) {
//         // Model spits out a single probability [0.0 to 1.0]
//         aiScore = output[0][0];
//       } else {
//         // Model spits out two probabilities [Real, Fake]
//         aiScore = output[0][1];
//       }
//
//       // Format the result for the UI (Converting 0.85 to 85.0%)
//       String percentage = (aiScore * 100).toStringAsFixed(1);
//
//       // (Note: Depending on how the Kaggle author labeled their data, 100% might mean Real and 0% might mean Fake.
//       //  We are assuming standard logic here: High score = Fake).
//       if (aiScore > 0.60) {
//         return "🔴 AI VISUAL THREAT: $percentage% AI-Generated Frequency Noise Detected.";
//       } else {
//         return "🟢 VISUAL SAFE: Natural pixel structure ($percentage% anomaly variance).";
//       }
//     } catch (e) {
//       return "ERROR: Visual scan failed - $e";
//     }
//   }
// }
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'dart:io';

class AIService {
  static Interpreter? _interpreter;

  // 1. WAKE UP THE AI BRAIN
  static Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/models/deepfake_detector.tflite');
      var inputShape = _interpreter!.getInputTensor(0).shape;
      print("🟢 HD AI MODEL LOADED. Expected Patch Shape: $inputShape");
    } catch (e) {
      print("🔴 Error loading AI model: $e");
    }
  }

  // 2. THE HD MULTI-PATCH SCANNER (Sliding Window)
  static Future<String> scanImage(String filePath) async {
    if (_interpreter == null) return "ERROR: AI Model is offline.";

    try {
      // A. Get Model Shape Requirements
      var inputTensor = _interpreter!.getInputTensor(0);
      int patchHeight = inputTensor.shape[1]; // Usually 32
      int patchWidth = inputTensor.shape[2];  // Usually 32

      // B. Load the Original HD Image
      File file = File(filePath);
      img.Image? rawImage = img.decodeImage(file.readAsBytesSync());
      if (rawImage == null) return "ERROR: Failed to read image.";

      // C. Prepare the Grid Analytics
      int columns = rawImage.width ~/ patchWidth;
      int rows = rawImage.height ~/ patchHeight;
      int totalPatches = columns * rows;
      int threatCount = 0;
      List<String> threatCoordinates = [];

      print("Starting HD Grid Scan: $columns x $rows ($totalPatches total patches to scan)");

      // D. THE SLIDING WINDOW LOOP
      for (int y = 0; y < rows; y++) {
        for (int x = 0; x < columns; x++) {

          // 1. Cut out the perfect square from the grid
          img.Image patch = img.copyCrop(
              rawImage,
              x: x * patchWidth,
              y: y * patchHeight,
              width: patchWidth,
              height: patchHeight
          );

          // 2. Run the helper function on this specific square
          double patchThreatScore = _runModelOnPatch(patch, patchHeight, patchWidth);

          // 3. If this specific square is a Deepfake, log it!
          // Note: Adjusting the threshold up to 0.75 to reduce false positives in high-contrast patches
          if (patchThreatScore > 0.75) {
            threatCount++;
            // Only save the first few coordinates so the UI doesn't overflow
            if (threatCoordinates.length < 5) {
              threatCoordinates.add("[R:$y, C:$x]");
            }
          }
        }
        // SENIOR DEV TRICK: Yield to the UI thread for 1 millisecond after every row.
        // This prevents the app from completely freezing while doing heavy math!
        await Future.delayed(const Duration(milliseconds: 1));
      }

      // E. Final Forensic Verdict
      if (threatCount > 0) {
        double percentageInfected = (threatCount / totalPatches) * 100;
        return "🔴 AI VISUAL THREAT: ${percentageInfected.toStringAsFixed(1)}% of image area is AI-Generated.\n"
            "Anomalies found at: ${threatCoordinates.join(', ')}...";
      } else {
        return "🟢 VISUAL SAFE: HD Grid Scan complete. 0 anomalies found.";
      }
    } catch (e) {
      return "ERROR: Visual scan failed - $e";
    }
  }

  // 3. THE MISSING HELPER FUNCTION
  // This takes a single cut-out patch, converts it to math, and gets the score.
  static double _runModelOnPatch(img.Image patch, int expectedHeight, int expectedWidth) {
    if (_interpreter == null) return 0.0;

    // Convert the image patch into a mathematical matrix
    var input = List.generate(1, (i) => List.generate(expectedHeight, (j) => List.generate(expectedWidth, (k) => List.filled(3, 0.0))));

    for (int y = 0; y < expectedHeight; y++) {
      for (int x = 0; x < expectedWidth; x++) {
        img.Pixel pixel = patch.getPixel(x, y);
        input[0][y][x][0] = pixel.r / 255.0;
        input[0][y][x][1] = pixel.g / 255.0;
        input[0][y][x][2] = pixel.b / 255.0;
      }
    }

    // Check output shape and run inference
    var outputTensor = _interpreter!.getOutputTensor(0);
    int outputSize = outputTensor.shape.last;
    var output = List.filled(1 * outputSize, 0.0).reshape([1, outputSize]);

    _interpreter!.run(input, output);

    // Return the probability score
    if (outputSize == 1) {
      return output[0][0];
    } else {
      return output[0][1];
    }
  }
}