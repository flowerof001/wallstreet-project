import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

/// 股票走势图 Widget
///
/// 支持4种图表类型:
/// - time_sharing: 分时图（线图 + 底部成交量柱状图）
/// - daily_k: 日K线（蜡烛图）
/// - monthly_k: 月K线（蜡烛图）
/// - yearly_k: 年K线（蜡烛图）
///
/// A股: 涨红跌绿 (red up, green down)
/// 其他市场: 涨绿跌红 (green up, red down)
class StockChart extends StatelessWidget {
  /// 图表类型
  final String chartType;

  /// K线数据
  final List<KLineData>? kLines;

  /// 分时数据 (time, price)
  final List<TimeSharingPoint>? timeSharingPoints;

  /// 是否 A 股市场
  final bool isAShare;

  /// 昨日收盘价（分时图基准价）
  final double? preClose;

  const StockChart({
    super.key,
    required this.chartType,
    this.kLines,
    this.timeSharingPoints,
    this.isAShare = true,
    this.preClose,
  });

  @override
  Widget build(BuildContext context) {
    if (chartType == 'time_sharing') {
      return _buildTimeSharingChart();
    }
    return _buildCandlestickChart();
  }

  /// 分时图 — 线图 + 成交量
  Widget _buildTimeSharingChart() {
    if (timeSharingPoints == null || timeSharingPoints!.isEmpty) {
      return _emptyPlaceholder();
    }

    final points = timeSharingPoints!;
    final lineSpots = <FlSpot>[];
    for (var i = 0; i < points.length; i++) {
      lineSpots.add(FlSpot(i.toDouble(), points[i].price));
    }

    final upColor =
        isAShare ? const Color(0xFFFF5757) : const Color(0xFF2FAC00);
    final downColor =
        isAShare ? const Color(0xFF2FAC00) : const Color(0xFFFF5757);

    final firstPrice = points.first.price;
    final lastPrice = points.last.price;
    final isRise = lastPrice >= firstPrice;

    return Padding(
      padding: const EdgeInsets.only(top: 4, right: 8, bottom: 4, left: 4),
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: (points.length - 1).toDouble(),
          minY: points.map((p) => p.price).reduce(
                  (a, b) => a < b ? a : b) -
              2,
          maxY: points.map((p) => p.price).reduce(
                  (a, b) => a > b ? a : b) +
              2,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 1,
            getDrawingHorizontalLine: (value) => FlLine(
              color: const Color(0xFF1A3A5C),
              strokeWidth: 0.5,
            ),
          ),
          titlesData: const FlTitlesData(
            show: true,
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 50,
                getTitlesWidget: _leftTitleWidget,
                interval: 1,
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: _bottomTimeTitleWidget,
                interval: 30, // every ~30 points = ~1h
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: lineSpots,
              isCurved: false,
              color: isRise ? upColor : downColor,
              barWidth: 1.5,
              preventCurveOverShooting: true,
              belowBarData: BarAreaData(
                show: true,
                color: (isRise ? upColor : downColor).withOpacity(0.1),
              ),
              dotData: const FlDotData(show: false),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  return LineTooltipItem(
                    '${points[spot.spotIndex].price.toStringAsFixed(2)}\n${points[spot.spotIndex].time}',
                    TextStyle(
                      color: spot.bar.color,
                      fontSize: 12,
                    ),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }

  /// K线图（日K/月K/年K）
  Widget _buildCandlestickChart() {
    if (kLines == null || kLines!.isEmpty) {
      return _emptyPlaceholder();
    }

    final lines = kLines!;
    final upColor =
        isAShare ? const Color(0xFFFF5757) : const Color(0xFF2FAC00);
    final downColor =
        isAShare ? const Color(0xFF2FAC00) : const Color(0xFFFF5757);


    final bars = <BarChartGroupData>[];
    for (var i = 0; i < lines.length; i++) {
      final k = lines[i];
      final isUp = k.close >= k.open;
      bars.add(
        BarChartGroupData(
          x: i,
          barRods: [
            // Wick (high-low)
            BarChartRodData(
              toY: k.high,
              fromY: k.low,
              width: 1,
              color: isUp ? upColor : downColor,
            ),
            // Body (open-close)
            BarChartRodData(
              toY: isUp ? k.close : k.open,
              fromY: isUp ? k.open : k.close,
              width: 5,
              color: isUp ? upColor : downColor,
            ),
          ],
        ),
      );
    }

    final minY = lines
            .map((k) => k.low)
            .reduce((a, b) => a < b ? a : b) *
        0.995;
    final maxY = lines
            .map((k) => k.high)
            .reduce((a, b) => a > b ? a : b) *
        1.005;

    return Padding(
      padding: const EdgeInsets.only(top: 4, right: 8, bottom: 4, left: 4),
      child: BarChart(
        BarChartData(
          minY: minY,
          maxY: maxY,
          barGroups: bars,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: (maxY - minY) / 5,
            getDrawingHorizontalLine: (value) => FlLine(
              color: const Color(0xFF1A3A5C),
              strokeWidth: 0.5,
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 50,
                getTitlesWidget: _leftTitleWidget,
                interval: 1,
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx >= 0 && idx < lines.length && idx % 10 == 0) {
                    return _kDateLabel(lines[idx].date);
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIdx, rod, rodIdx) {
                if (rodIdx != 0) return null;
                final k = lines[group.x.toInt()];
                return BarTooltipItem(
                  '${k.date}\nO:${k.open.toStringAsFixed(2)} H:${k.high.toStringAsFixed(2)}\nL:${k.low.toStringAsFixed(2)} C:${k.close.toStringAsFixed(2)}',
                  const TextStyle(fontSize: 11),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _emptyPlaceholder() {
    return const Center(
      child: Text(
        '走势图加载中...',
        style: TextStyle(color: Color(0xFF556677)),
      ),
    );
  }
}

Widget _leftTitleWidget(double value, TitleMeta meta) {
  return Padding(
    padding: const EdgeInsets.only(right: 4),
    child: Text(
      value.toStringAsFixed(2),
      style: const TextStyle(fontSize: 10, color: Color(0xFF556677)),
    ),
  );
}

Widget _bottomTimeTitleWidget(double value, TitleMeta meta) {
  // Time labels for the current index
  return Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Text(
      '${value.toInt()}',
      style: const TextStyle(fontSize: 10, color: Color(0xFF556677)),
    ),
  );
}

Widget _kDateLabel(String date) {
  // Shorten date for display
  final short =
      date.length > 5 ? date.substring(date.length - 5, date.length) : date;
  return Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Text(
      short,
      style: const TextStyle(fontSize: 10, color: Color(0xFF556677)),
    ),
  );
}

/// K线数据点
class KLineData {
  final String date;
  final double open;
  final double close;
  final double high;
  final double low;
  final int volume;
  final double amount;

  const KLineData({
    required this.date,
    required this.open,
    required this.close,
    required this.high,
    required this.low,
    required this.volume,
    required this.amount,
  });

  factory KLineData.fromJson(Map<String, dynamic> json) {
    return KLineData(
      date: json['date'] as String,
      open: (json['open'] as num).toDouble(),
      close: (json['close'] as num).toDouble(),
      high: (json['high'] as num).toDouble(),
      low: (json['low'] as num).toDouble(),
      volume: json['volume'] as int,
      amount: (json['amount'] as num).toDouble(),
    );
  }
}

/// 分时数据点
class TimeSharingPoint {
  final String time;
  final double price;

  const TimeSharingPoint({
    required this.time,
    required this.price,
  });
}
