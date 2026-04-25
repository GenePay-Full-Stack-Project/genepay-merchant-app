import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  final Color _navy = const Color(0xFF1E1E8B);
  final Color _muted = const Color(0xFF6F6F96);
  final Color _accent = const Color(0xFFFF5722);
  final Color _cardBg = const Color(0xFFF8F9FF);
  final Color _success = const Color(0xFF4CAF50);

  late final AnimationController _ctl;
  String _period = 'Weekly';
  bool _exporting = false;

  final Map<String, List<double>> _salesSeries = {
    'Daily': [120, 160, 200, 240, 300, 360, 420],
    'Weekly': [520, 610, 700, 780, 840, 920, 980],
    'Monthly': [2500, 2600, 2800, 3000, 3200, 3600, 4100],
  };

  final Map<String, List<double>> _compareSeries = {
    'Daily': [100, 140, 180, 220, 260, 300, 340],
    'Weekly': [480, 560, 640, 700, 760, 820, 880],
    'Monthly': [2300, 2400, 2500, 2700, 2900, 3300, 3600],
  };

  @override
  void initState() {
    super.initState();
    _ctl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _ctl.forward();

    // Set the system status bar color to navy and icons to light
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: _navy,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ));
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  String _formatCurrency(double v) => '€${v.toStringAsFixed(2)}';
  double _sum(List<double> arr) => arr.fold(0.0, (p, e) => p + e);

  Widget _segPill(String label) {
    final active = _period == label;
    return GestureDetector(
      onTap: () {
        if (_period == label) return;
        setState(() {
          _period = label;
          _ctl.forward(from: 0.0);
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? _accent : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? _accent : Colors.transparent, width: 1.5),
          boxShadow: active ? [
            BoxShadow(
              color: _accent.withOpacity(0.25),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ] : [],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: active ? Colors.white : _navy.withOpacity(0.7),
              fontWeight: active ? FontWeight.w800 : FontWeight.w600,
              fontSize: 14,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sales = _salesSeries[_period]!;
    final compare = _compareSeries[_period]!;
    final total = _formatCurrency(_sum(sales));
    final pct = _calcPct(sales);

    return Scaffold(
      backgroundColor: Colors.white,
      
      // CUSTOM BOTTOM NAVIGATION (Export Button)
      bottomNavigationBar: FadeTransition(
        opacity: CurvedAnimation(parent: _ctl, curve: const Interval(0.7, 1.0, curve: Curves.easeOut)),
        child: Padding(
          padding: EdgeInsets.fromLTRB(18, 8, 18, MediaQuery.of(context).padding.bottom + 12),
          child: SizedBox(
            height: 56,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFFF5722), Color(0xFFFF7A66)]),
                borderRadius: BorderRadius.circular(32),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 18, offset: const Offset(0, 8))],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(32),
                  onTap: () async {
                    setState(() => _exporting = true);
                    await Future.delayed(const Duration(milliseconds: 700));
                    if (!mounted) return;
                    setState(() => _exporting = false);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Export complete')));
                  },
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.print, color: Colors.white),
                        const SizedBox(width: 12),
                        Text(_exporting ? 'Exporting...' : 'Export Reports',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),

      body: SingleChildScrollView( 
        child: Column(
          children: [
          // TOP GRADIENT HEADER
          Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_navy, const Color(0xFF2A2ABF)],
                ),
                borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: _navy.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 26), 
                          onPressed: () => Navigator.maybePop(context)
                        ),
                        const Spacer(),
                        const Text(
                          'Analytics & Reports', 
                          style: TextStyle(
                            color: Colors.white, 
                            fontSize: 22, 
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          )
                        ),
                        const Spacer(),
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.insert_chart_outlined, color: Colors.white, size: 22),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    FadeTransition(
                      opacity: CurvedAnimation(parent: _ctl, curve: const Interval(0.0, 0.25, curve: Curves.easeOut)),
                      child: Container(
                        width: double.infinity,
                        height: 48,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(child: _segPill('Daily')),
                            const SizedBox(width: 6),
                            Expanded(child: _segPill('Weekly')),
                            const SizedBox(width: 6),
                            Expanded(child: _segPill('Monthly')),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

          // OVERLAPPING CARD WITH CHART
          Transform.translate(
            offset: const Offset(0, -20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18.0),
              child: Column(
                children: [
                  FadeTransition(
                    opacity: CurvedAnimation(parent: _ctl, curve: const Interval(0.2, 0.55, curve: Curves.easeOut)),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: _navy.withOpacity(0.08),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(18.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "This Week's Sales",
                              style: TextStyle(
                                color: _muted,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                letterSpacing: 0.3,
                              )
                            ),
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  total,
                                  style: TextStyle(
                                    color: _navy,
                                    fontSize: 32,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.5,
                                  )
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: pct >= 0 ? _success.withOpacity(0.12) : Colors.red.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${pct >= 0 ? '+' : ''}${pct.toStringAsFixed(0)}%',
                                    style: TextStyle(
                                      color: pct >= 0 ? _success : Colors.red,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // LEGEND BOX (blue/red meaning)
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                              decoration: BoxDecoration(
                                color: _cardBg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: _navy.withOpacity(0.05), width: 1),
                              ),
                              child: Row(
                                children: [
                                  _legendDot(Colors.blue.shade400, 'Current (${_period.toLowerCase()})'),
                                  const SizedBox(width: 16),
                                  _legendDot(Colors.redAccent.shade200, 'Previous'),
                                  const Spacer(),
                                  Text('Units', style: TextStyle(color: _muted, fontSize: 12, fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ),

                            const SizedBox(height: 14),

                            // CHART AREA
                            SizedBox(
                              height: 170,
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: const Color.fromRGBO(30, 30, 139, 0.02),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                  Positioned.fill(
                                    child: CustomPaint(
                                      painter: SmoothChartPainter(
                                        points: sales,
                                        compare: compare,
                                        gradientStart: Colors.blue.shade300,
                                        gradientEnd: Colors.blue.shade50,
                                        lineColor: Colors.blue.shade400,
                                        compareColor: Colors.redAccent.shade200,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    left: 8,
                                    right: 8,
                                    bottom: 8,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: ['Mon','Tue','Wed','Thu','Fri','Sat','Sun']
                                          .map((d) => Text(d, style: TextStyle(color: _muted, fontSize: 11, fontWeight: FontWeight.w500)))
                                          .toList(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // AVERAGE ORDER - full width card
                  SizedBox(
                    width: double.infinity,
                    child: _averageOrderCard(),
                  ),

                  const SizedBox(height: 16),

                  // Peak Hours Analysis - full width card
                  SizedBox(
                    width: double.infinity,
                    height: 120,
                    child: _featureCard(
                      icon: Icons.access_time_filled,
                      label: 'Peak Hours Analysis',
                      subtitle: null,
                      onTap: () => _openFeature('peak')
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          ],
        ),
      ),
    );
  }

  double _calcPct(List<double> s) {
    if (s.length < 2) return 0;
    final last = s.last;
    final prev = s[s.length - 2];
    if (prev == 0) return 0;
    return ((last - prev) / prev) * 100;
  }

  Widget _legendDot(Color c, String label) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: c,
            borderRadius: BorderRadius.circular(5),
            boxShadow: [
              BoxShadow(
                color: c.withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: _navy,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _featureCard({required IconData icon, required String label, String? subtitle, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_navy, const Color(0xFF2626A0)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _navy.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ), 
              child: Icon(icon, color: _accent, size: 22),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _averageOrderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _navy.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Average Order',
                style: TextStyle(
                  color: _muted,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '€12.40',
                style: TextStyle(
                  color: _navy,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '+8% vs last',
                  style: TextStyle(
                    color: _success,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.receipt_long_rounded, color: _accent, size: 28),
          ),
        ],
      ),
    );
  }

  void _openFeature(String key) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) {
        return SizedBox(
          height: 260,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(key == 'customers' ? 'Customer Statistics' : 'Peak Hours Analysis', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                Text('Detailed analytics will appear here. Connect backend to load real data.', style: TextStyle(color: _muted)),
                const Spacer(),
                Align(
                  alignment: Alignment.bottomRight,
                  child: ElevatedButton(onPressed: () => Navigator.pop(context), style: ElevatedButton.styleFrom(backgroundColor: _accent), child: const Text('Close')),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Custom painter that draws a smooth (cubic) line, a compare line, and gradient/wave fill under main line.
class SmoothChartPainter extends CustomPainter {
  final List<double> points;
  final List<double> compare;
  final Color gradientStart;
  final Color gradientEnd;
  final Color lineColor;
  final Color compareColor;

  SmoothChartPainter({
    required this.points,
    required this.compare,
    required this.gradientStart,
    required this.gradientEnd,
    required this.lineColor,
    required this.compareColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final pMax = (points + compare).reduce((a, b) => a > b ? a : b);
    final pad = 12.0;
    final usableW = size.width - pad * 2;
    final usableH = size.height - pad * 2;

    // Build normalized points (0..1)
    final norm = (List<double>.from(points.map((v) => v / pMax)));
    final normComp = (List<double>.from(compare.map((v) => v / pMax)));

    // Helper to map index to Offset
    Offset mapPoint(int i, double t) {
      final dx = pad + (usableW) * (i / (points.length - 1));
      final dy = pad + usableH * (1 - t);
      return Offset(dx, dy);
    }

    // Build smooth path via cubic Bezier approximation
    Path buildSmoothPath(List<double> values) {
      final path = Path();
      if (values.isEmpty) return path;
      final n = values.length;
      final pts = List.generate(n, (i) => mapPoint(i, values[i]));
      path.moveTo(pts.first.dx, pts.first.dy);
      for (var i = 0; i < pts.length - 1; i++) {
        final p0 = pts[i];
        final p1 = pts[i + 1];

        final midX = (p0.dx + p1.dx) / 2;
        final c1 = Offset(midX, p0.dy);
        final c2 = Offset(midX, p1.dy);

        path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p1.dx, p1.dy);
      }
      return path;
    }

    // Blue main path + gradient fill
    final mainPath = buildSmoothPath(norm);
    final mainPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round
      ..color = lineColor;

    // Create gradient under main path (wave fill)
    final fillPath = Path.from(mainPath)
      ..lineTo(pad + usableW, pad + usableH + 6)
      ..lineTo(pad, pad + usableH + 6)
      ..close();

    final shader = ui.Gradient.linear(
      Offset(0, pad),
      Offset(0, size.height),
      [gradientStart.withOpacity(0.45), gradientEnd.withOpacity(0.05)],
    );

    final fillPaint = Paint()..shader = shader;

    // Slight blur for the compare line for depth
    final comparePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = compareColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2)
      ..strokeCap = StrokeCap.round;

    // Draw fill, main line and compare line
    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(mainPath, mainPaint);

    final compPath = buildSmoothPath(normComp);
    canvas.drawPath(compPath, comparePaint);

    // Draw subtle circles on data points for main line
    final dotPaint = Paint()..color = lineColor;
    for (var i = 0; i < norm.length; i++) {
      final o = mapPoint(i, norm[i]);
      canvas.drawCircle(o, 3.0, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}