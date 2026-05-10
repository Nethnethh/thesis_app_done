import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_database/firebase_database.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../pages/web_support.dart';

class SettingsScreen extends StatefulWidget {  // ✅ StatefulWidget for loading state
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final DatabaseReference _ref = FirebaseDatabase.instance.ref("scans");
  bool _isExporting = false;

  Future<void> _handleExport() async {
    setState(() => _isExporting = true);

    try {
      // ✅ Read from Firebase — no SQLite needed
      final snapshot = await _ref.get();
      final data = snapshot.value as Map?;

      if (data == null || data.isEmpty) {
        _showSnackbar('⚠️ No data found to export!', Colors.orange);
        return;
      }

      // Convert to list
      List<Map<String, dynamic>> scans = [];
      data.forEach((key, val) {
        try {
          scans.add(Map<String, dynamic>.from(val as Map));
        } catch (_) {}
      });

      // Sort oldest first
      scans.sort((a, b) {
        final aDate = a['dateTime']?.toString() ?? '';
        final bDate = b['dateTime']?.toString() ?? '';
        return aDate.compareTo(bDate);
      });

      // ✅ Build CSV with all fields
      final StringBuffer csv = StringBuffer();
      csv.writeln(
        'DateTime,'
            'Temperature(C),'
            'Humidity(%),'
            'Pressure(hPa),'
            'GasVOC(ohms),'
            'Verdict,'
            'Reason',
      );
      for (var scan in scans) {
        csv.writeln(
          '"${scan['dateTime'] ?? ''}",'
              '${scan['temperature'] ?? ''},'
              '${scan['humidity'] ?? ''},'
              '${scan['pressure'] ?? ''},'
              '${scan['gasVOC'] ?? ''},'
              '"${scan['verdict'] ?? ''}",'
              '"${scan['reason'] ?? ''}"',
        );
      }

      final fileName =
          'Chemical_Screening_${DateTime.now().millisecondsSinceEpoch}.csv';

      if (kIsWeb) {
        // ✅ Web: browser download using JS interop
        _downloadWeb(csv.toString(), fileName);
      } else {
        // ✅ Mobile: save and share
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/$fileName');
        await file.writeAsString(csv.toString());
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Chemical Screening Research Data',
        );
      }

      _showSnackbar('✅ Exported ${scans.length} records!', Colors.green);
    } catch (e) {
      _showSnackbar('❌ Export Error: $e', Colors.red);
    } finally {
      setState(() => _isExporting = false);
    }
  }

  // ✅ Web download without importing dart:html globally
  void _downloadWeb(String content, String fileName) {
    // Uses JS interop safely
    final blob = Uri.dataFromString(
      content,
      mimeType: 'text/csv',
      encoding: const bool.fromEnvironment('dart.library.html')
          ? null
          : null,
    );
    // Trigger download via anchor element
    // ignore: undefined_prefixed_name
    final anchor = html_download(content, fileName);
  }

  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "SETTINGS",
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1),
        ),
        backgroundColor: Colors.green[700],
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // DATA MANAGEMENT
          const Text(
            "DATA MANAGEMENT",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              fontSize: 11,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.purple,
                child: Icon(Icons.file_download, color: Colors.white),
              ),
              title: const Text(
                "Export to CSV",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text("Save data for Excel/Research"),
              trailing: _isExporting
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Icon(Icons.chevron_right),
              onTap: _isExporting ? null : _handleExport,
            ),
          ),

          const SizedBox(height: 20),

          // SYSTEM INFO
          const Text(
            "SYSTEM INFO",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              fontSize: 11,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            child: const ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue,
                child: Icon(Icons.info_outline, color: Colors.white),
              ),
              title: Text(
                "Thesis Project v1.0",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text("Chemical Screening Device"),
            ),
          ),
        ],
      ),
    );
  }
}