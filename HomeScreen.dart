import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseReference _ref = FirebaseDatabase.instance.ref("scans");
  List<Map<String, dynamic>> _scans = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _listenFirebase();
  }

  // ✅ Change 1 — Safe cast + safe sort
  void _listenFirebase() {
    _ref.onValue.listen((event) {
      final data = event.snapshot.value as Map?;
      if (data != null) {
        List<Map<String, dynamic>> temp = [];
        data.forEach((key, val) {
          try {
            temp.add(Map<String, dynamic>.from(val as Map));
          } catch (e) {
            // skip malformed entries
          }
        });

        // ✅ Safe sort using toDouble()
        temp.sort((a, b) {
          final aDate = a['dateTime']?.toString() ?? '';
          final bDate = b['dateTime']?.toString() ?? '';
          return bDate.compareTo(aDate); // newest first
        });
        setState(() {
          _scans = temp;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    });
  }

  // ✅ Change 2 — Fixed timestamp formatting with fallback
  String formatTimestamp(dynamic raw) {
    if (raw == null) return "No Date";
    try {
      if (raw is String && raw.contains("-")) {
        DateTime date = DateTime.parse(raw);
        return DateFormat('dd MMM yyyy hh:mm a').format(date);
      }
      DateTime date = DateTime.fromMillisecondsSinceEpoch(
          int.parse(raw.toString()));
      return DateFormat('dd MMM yyyy hh:mm a').format(date);
    } catch (e) {
      return "No Date";
    }
  }

  Color _getStatusColor(String verdict) {
    final v = verdict.toUpperCase();
    if (v.contains("SAFE"))         return Colors.green;
    if (v.contains("DO NOT EAT"))   return Colors.red;
    if (v.contains("WARNING"))      return Colors.red[700]!;
    if (v.contains("CAUTION"))      return Colors.orange;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final latest = _scans.isNotEmpty ? _scans[0] : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          "Produce Chemical Screening",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.green[700],
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 1. HERO STATUS CARD
            _buildHero(latest),
            const SizedBox(height: 20),

            // 2. GAUGES
            Row(
              children: [
                Expanded(
                  child: _buildGauge(
                    "Temperature",
                    latest?['temperature'] ?? 0,
                    "°C",
                    Colors.orange,
                    0,
                    50,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildGauge(
                    "Humidity",
                    latest?['humidity'] ?? 0,
                    "%",
                    Colors.blue,
                    0,
                    100,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 3. VOC CHART
            _buildChartSection(),
            const SizedBox(height: 20),

            // 4. HISTORY LIST
            _buildHistoryList(),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildHero(Map? scan) {
    Color statusColor = _getStatusColor(scan?['verdict'] ?? "");

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
        gradient: LinearGradient(
          colors: [statusColor, statusColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          const Text(
            "ANALYSIS RESULT",
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            scan?['verdict'] ?? "OFFLINE",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            scan?['reason'] ?? "Connect your device to begin screening",
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontStyle: FontStyle.italic,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 15),
          const Divider(color: Colors.white24),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Gas VOC
              Column(
                children: [
                  const Icon(Icons.air, color: Colors.white70, size: 16),
                  const SizedBox(height: 4),
                  Text(
                    "${((scan?['gasVOC'] ?? 0) / 1000).toStringAsFixed(1)}K Ω",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    "Gas VOC",
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
              // Pressure
              Column(
                children: [
                  const Icon(Icons.compress, color: Colors.white70, size: 16),
                  const SizedBox(height: 4),
                  Text(
                    "${(scan?['pressure'] ?? 0).toStringAsFixed(1)} hPa",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    "Pressure",
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
              // ✅ Change 3 — dateTime with timestamp fallback
              Column(
                children: [
                  const Icon(Icons.calendar_month,
                      color: Colors.white70, size: 16),
                  const SizedBox(height: 4),
                  Text(
                    formatTimestamp(
                      scan?['dateTime'] ?? scan?['timestamp'], // ✅ fallback
                    ),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 11,
                    ),
                  ),
                  const Text(
                    "Last Scan",
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGauge(String title, dynamic val, String unit,
      Color color, double min, double max) {
    double value = double.tryParse(val.toString()) ?? 0;
    value = value.clamp(min, max);

    return Container(
      height: 170,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: SfRadialGauge(
        title: GaugeTitle(
          text: title,
          textStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        axes: <RadialAxis>[
          RadialAxis(
            minimum: min,
            maximum: max,
            showLabels: false,
            showTicks: false,
            axisLineStyle: AxisLineStyle(
              thickness: 8,
              color: color.withOpacity(0.1),
              cornerStyle: CornerStyle.bothCurve,
            ),
            pointers: <GaugePointer>[
              RangePointer(
                value: value,
                width: 8,
                color: color,
                cornerStyle: CornerStyle.bothCurve,
              ),
            ],
            annotations: <GaugeAnnotation>[
              GaugeAnnotation(
                widget: Text(
                  "${value.toStringAsFixed(1)}$unit",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                angle: 90,
                positionFactor: 0.1,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartSection() {
    final chartData = _scans.reversed.toList().take(20).toList();

    return Container(
      height: 280,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "GAS VOC HISTORY (Last 20 Scans)",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 25),
          Expanded(
            child: chartData.isEmpty
                ? const Center(child: Text("No data yet"))
                : LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) =>
                      FlLine(color: Colors.grey[100], strokeWidth: 1),
                ),
                titlesData: FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    // ✅ Change 4 — Safe null for gasVOC
                    spots: chartData.asMap().entries.map((e) {
                      return FlSpot(
                        e.key.toDouble(),
                        double.tryParse(
                          (e.value['gasVOC'] ?? 0).toString(),
                        ) ??
                            0,
                      );
                    }).toList(),
                    isCurved: true,
                    color: Colors.green[600],
                    barWidth: 4,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          Colors.green.withOpacity(0.2),
                          Colors.green.withOpacity(0.0),
                        ],
                      ),
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

  Widget _buildHistoryList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Text(
              "SCAN HISTORY",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                fontSize: 11,
              ),
            ),
          ),
          const Divider(height: 1),
          _scans.isEmpty
              ? const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: Text("No scan history yet")),
          )
              : ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _scans.length > 10 ? 10 : _scans.length,
            separatorBuilder: (_, __) =>
            const Divider(height: 1, indent: 16, endIndent: 16),
            itemBuilder: (context, index) {
              final scan = _scans[index];
              final color = _getStatusColor(scan['verdict'] ?? "");
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: color.withOpacity(0.15),
                  child: Icon(Icons.science, color: color, size: 20),
                ),
                title: Text(
                  scan['verdict'] ?? "-",
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // ✅ dateTime with timestamp fallback in history too
                subtitle: Text(
                  formatTimestamp(
                    scan['dateTime'] ?? scan['timestamp'],
                  ),
                  style: const TextStyle(fontSize: 11),
                ),
                trailing: Text(
                  "${((scan['gasVOC'] ?? 0) / 1000).toStringAsFixed(1)}K Ω",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}