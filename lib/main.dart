import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:percent_indicator/percent_indicator.dart';

void main() => runApp(SentinelaApp());

class SentinelaApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.blueAccent,
        scaffoldBackgroundColor: Color(0xFF0F172A), // Deep Navy
        cardColor: Color(0xFF1E293B),
      ),
      home: DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const platform = MethodChannel('com.sentinela.forensics/binary_scanner');

  File? _selectedImage;
  String _report = "No Analysis Performed";
  bool _isScanning = false;
  bool _sentinelActive = false;
  String _monitoredFolder = "None Selected";
  double _riskScore = 0.0;

  // --- 🛰️ SENTINEL FOLDER SELECTION ---
  Future<void> _selectFolder() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory != null) {
      setState(() => _monitoredFolder = selectedDirectory);
    }
  }

  // --- 📸 IMAGE ACQUISITION ---
  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _isScanning = true;
      });
      _runAnalysis(pickedFile.path);
    }
  }

  // --- 🧮 CUMULATIVE LOGIC ENGINE ---
  Future<void> _runAnalysis(String path) async {
    try {
      // 1. Trigger the Native Java Pipeline (Phase 4 -> Phase 6)
      final String result = await platform.invokeMethod('scanBinary', {"filePath": path});

      setState(() {
        _report = result;
        _isScanning = false;
        _riskScore = _calculateRiskScore(result);
      });
    } on PlatformException catch (e) {
      setState(() {
        _report = "Forensic Engine Error: ${e.message}";
        _isScanning = false;
      });
    }
  }

  double _calculateRiskScore(String report) {
    if (report.contains("🔴")) return 0.92; // High Threat
    if (report.contains("🟡")) return 0.45; // Caution/Modified
    if (report.contains("🟢")) return 0.05; // Verified Safe
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("SENTINELA-AI", style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            _buildCumulativeVerdictCard(),
            SizedBox(height: 20),
            _buildActionButtons(),
            SizedBox(height: 20),
            _buildSentinelControl(),
            SizedBox(height: 20),
            if (_selectedImage != null) _buildForensicBreakdown(),
          ],
        ),
      ),
    );
  }

  // --- UI COMPONENTS ---

  Widget _buildCumulativeVerdictCard() {
    Color statusColor = _riskScore > 0.7 ? Colors.redAccent : (_riskScore > 0.3 ? Colors.orangeAccent : Colors.greenAccent);
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          CircularPercentIndicator(
            radius: 80.0,
            lineWidth: 10.0,
            percent: _riskScore,
            center: Icon(Icons.security, size: 50, color: statusColor),
            progressColor: statusColor,
            backgroundColor: Colors.white10,
            circularStrokeCap: CircularStrokeCap.round,
            animation: true,
          ),
          SizedBox(height: 15),
          Text(
            _riskScore > 0.7 ? "AI THREAT DETECTED" : (_riskScore > 0.3 ? "MODIFICATION CAUTION" : "HUMAN ORIGIN VERIFIED"),
            style: TextStyle(color: statusColor, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Text("Integrity Confidence: ${((1 - _riskScore) * 100).toStringAsFixed(0)}%", style: TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: _actionButton(Icons.photo_library, "Gallery", () => _pickImage(ImageSource.gallery)),
        ),
        SizedBox(width: 15),
        Expanded(
          child: _actionButton(Icons.camera_alt, "Camera", () => _pickImage(ImageSource.camera)),
        ),
      ],
    );
  }

  Widget _actionButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(color: Colors.blueAccent, borderRadius: BorderRadius.circular(12)),
        child: Column(children: [Icon(icon), Text(label)]),
      ),
    );
  }

  Widget _buildSentinelControl() {
    return Container(
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(15)),
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.folder_open, color: Colors.blueAccent),
            title: Text("Sentinel Monitor"),
            subtitle: Text(_monitoredFolder, style: TextStyle(fontSize: 10)),
            trailing: IconButton(icon: Icon(Icons.settings), onPressed: _selectFolder),
          ),
          SwitchListTile(
            title: Text("Background Auto-Scan", style: TextStyle(fontSize: 14)),
            value: _sentinelActive,
            onChanged: (val) => setState(() => _sentinelActive = val),
            activeColor: Colors.blueAccent,
          )
        ],
      ),
    );
  }

  Widget _buildForensicBreakdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("FORENSIC LOGS", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white38)),
        SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(15),
          decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(12)),
          child: _isScanning
              ? Center(child: CircularProgressIndicator())
              : Text(_report, style: TextStyle(fontFamily: 'monospace', fontSize: 12)),
        ),
      ],
    );
  }
}