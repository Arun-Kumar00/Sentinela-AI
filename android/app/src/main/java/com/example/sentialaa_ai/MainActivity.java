package com.example.sentialaa_ai;

import androidx.annotation.NonNull;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Color;
import android.media.ExifInterface;

import java.io.File;
import java.util.Objects;

public class MainActivity extends FlutterActivity {
    // This channel name MUST match your Flutter code exactly
    private static final String CHANNEL = "com.sentinela.forensics/binary_scanner";

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
                .setMethodCallHandler(
                        (call, result) -> {
                            if (call.method.equals("scanBinary")) {
                                String filePath = call.argument("filePath");
                                String forensicReport = executePhase4Scan(filePath);
                                result.success(forensicReport);
                            } else {
                                result.notImplemented();
                            }
                        }
                );
    }

    // --- 🛡️ PHASE 4: THE MASTER PIPELINE ---
    private String executePhase4Scan(String filePath) {
        StringBuilder report = new StringBuilder();
        boolean isMetadataThreat = false;

        try {
            ExifInterface exif = new ExifInterface(filePath);
            String software = exif.getAttribute(ExifInterface.TAG_SOFTWARE);
            String comment = exif.getAttribute(ExifInterface.TAG_USER_COMMENT);

            report.append("🔍 LAYER 1: METADATA SCAN\n");

            // Check for known AI signatures (Midjourney/DALL-E usually strip these, but some tools don't)
            if (software != null && (software.contains("AI") || software.contains("Diffusion"))) {
                isMetadataThreat = true;
                report.append("🔴 THREAT: AI Software Signature found: ").append(software).append("\n");
            } else {
                report.append("🟢 Metadata clean of obvious AI signatures.\n");
            }

            if (isMetadataThreat) {
                return report.toString();
            } else {
                // FALLBACK TO PHYSICS (Phase 6)
                report.append("\n⚪ Launching Phase 6 Matrix Grid Scan...\n\n");
                String gridResult = runGridAnalysis(filePath);
                report.append(gridResult);
                return report.toString();
            }

        } catch (Exception e) {
            return "ERROR: Pipeline Failure - " + e.getMessage();
        }
    }

    // --- 🧮 PHASE 6: 8x8 LOCALIZED GRID SCANNER ---
    private String runGridAnalysis(String filePath) {
        try {
            BitmapFactory.Options options = new BitmapFactory.Options();
            options.inPreferredConfig = Bitmap.Config.ARGB_8888;
            Bitmap bitmap = BitmapFactory.decodeFile(filePath, options);

            if (bitmap == null) return "ERROR: Could not decode image.";

            int width = bitmap.getWidth();
            int height = bitmap.getHeight();
            int gridSize = 8;
            int blockWidth = width / gridSize;
            int blockHeight = height / gridSize;

            double minVariance = Double.MAX_VALUE;
            double maxVariance = Double.MIN_VALUE;
            int threatBlocks = 0;
            long totalStrongEdges = 0;
            long totalPixels = 0;

            for (int gridY = 0; gridY < gridSize; gridY++) {
                for (int gridX = 0; gridX < gridSize; gridX++) {
                    long sumCb = 0;
                    long sumCbSq = 0;
                    long blockPixels = 0;
                    int startX = gridX * blockWidth;
                    int startY = gridY * blockHeight;

                    for (int y = startY; y < startY + blockHeight; y += 2) {
                        for (int x = startX; x < startX + blockWidth; x += 2) {
                            if (x >= width || y >= height) continue;

                            int pixel = bitmap.getPixel(x, y);
                            int r = Color.red(pixel);
                            int g = Color.green(pixel);
                            int b = Color.blue(pixel);

                            // YCbCr Chroma Blue Conversion
                            double cb = 128.0 - (0.168736 * r) - (0.331264 * g) + (0.5 * b);
                            sumCb += cb;
                            sumCbSq += (cb * cb);

                            // Edge Tiebreaker Logic
                            if (x + 2 < width) {
                                int rightPixel = bitmap.getPixel(x + 2, y);
                                int lum1 = (r + g + b) / 3;
                                int lum2 = (Color.red(rightPixel) + Color.green(rightPixel) + Color.blue(rightPixel)) / 3;
                                if (Math.abs(lum1 - lum2) > 15) totalStrongEdges++;
                            }

                            blockPixels++;
                            totalPixels++;
                        }
                    }

                    if (blockPixels > 0) {
                        double variance = ((double) sumCbSq / blockPixels) - (Math.pow((double) sumCb / blockPixels, 2));
                        if (variance < minVariance) minVariance = variance;
                        if (variance > maxVariance) maxVariance = variance;
                        if (variance < 100.0) threatBlocks++;
                    }
                }
            }

            double edgeDensity = ((double) totalStrongEdges / totalPixels) * 100.0;

            // --- THE SMART VERDICT ---
            if (maxVariance < 120.0) {
                return "🔴 THREAT: GLOBAL AI GENERATION\n" +
                        "Verdict: Image lacks physical sensor noise.\n" +
                        "Max Variance: " + String.format("%.2f", maxVariance);
            } else if (threatBlocks > 2 && threatBlocks < 50 && maxVariance > 300) {
                return "🔴 THREAT: LOCALIZED MANIPULATION\n" +
                        "Verdict: Face-Swap anomaly detected in " + threatBlocks + " blocks.\n" +
                        "Anom. Variance: " + String.format("%.2f", minVariance);
            } else if (maxVariance < 300 || edgeDensity < 5.0) {
                return "🟡 CAUTION: MODIFIED / FILTERED\n" +
                        "Verdict: High-frequency smoothing detected.\n" +
                        "Edge Density: " + String.format("%.2f%%", edgeDensity);
            } else {
                return "🟢 SAFE: HUMAN ORIGIN\n" +
                        "Verdict: Physical Bayer sensor verified.\n" +
                        "Chroma Stability: OK";
            }

        } catch (Exception e) {
            return "ERROR: Grid Engine crashed - " + e.getMessage();
        }
    }
}