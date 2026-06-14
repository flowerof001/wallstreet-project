import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../i18n/i18n_service.dart';
import '../models/stock.dart';
import '../providers/auth_provider.dart';
import '../providers/stock_provider.dart';
import '../services/user_service.dart';
import '../widgets/stock_chart.dart';

/// 股票详情页
class StockDetailScreen extends StatefulWidget {
  StockDetailScreen({super.key});

  @override
  State<StockDetailScreen> createState() => _StockDetailScreenState();
}

class _StockDetailScreenState extends State<StockDetailScreen> {
  bool _isInWatchlist = false;
  bool _isToggling = false;
  String _chartType = 'time_sharing';
  List<KLineData>? _kLines;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final stockCode =
        ModalRoute.of(context)?.settings.arguments as String? ?? '000001';
    final auth = context.read<AuthProvider>();
    if (auth.isLoggedIn && auth.user.watchlist.contains(stockCode)) {
      _isInWatchlist = true;
    }
  }

  Future<void> _loadKLineData(String code, String period) async {
    try {
      final data = await UserService.getKLineHistory(
          code, period: period, count: 60);
      if (mounted) {
        setState(() {
          _kLines = data.map((m) => KLineData.fromJson(m)).toList();
        });
      }
    } catch (_) {
      // Silently fail, chart will show placeholder
    }
  }

  @override
  Widget build(BuildContext context) {
    final stockCode =
        ModalRoute.of(context)?.settings.arguments as String? ?? '000001';
    final stockProv = context.watch<StockProvider>();
    final auth = context.watch<AuthProvider>();
    final stock = stockProv.getStock(stockCode);

    final isAShare = ['sh', 'sz', 'bj'].contains(stock?.market ?? 'sh');
    final isRise = stock?.isRise ?? true;
    final priceColor = isRise
        ? (isAShare ? const Color(0xFFFF5757) : const Color(0xFF2FAC00))
        : (isAShare ? const Color(0xFF2FAC00) : const Color(0xFFFF5757));

    return Scaffold(
      appBar: AppBar(
        title: Text(stock?.name ?? stockCode),
        actions: [
          if (auth.isLoggedIn)
            TextButton.icon(
              onPressed: _isToggling ? null : () => _toggleWatchlist(stockCode),
              icon: Icon(
                _isInWatchlist ? Icons.star : Icons.star_outline,
                color: _isInWatchlist
                    ? const Color(0xFF5DA3F3)
                    : const Color(0xFF003EA5),
              ),
              label: Text(
                _isInWatchlist ? t('added') : t('add_to_watchlist'),
                style: TextStyle(
                  color: _isInWatchlist
                      ? const Color(0xFF5DA3F3)
                      : const Color(0xFF003EA5),
                ),
              ),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF003EA5),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 股票基本信息卡片
            Card(
              color: const Color(0xFF1C3045),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: Color(0xFF2A4058)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              stock?.name ?? stockCode,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFBADBFF),
                              ),
                            ),
                            Text(
                              stockCode,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF8899AA),
                              ),
                            ),
                          ],
                        ),
                        if (stock != null) ...[
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                stock.currentPrice.toStringAsFixed(2),
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: priceColor,
                                ),
                              ),
                              Row(
                                children: [
                                  Icon(
                                    isRise
                                        ? Icons.arrow_drop_up
                                        : Icons.arrow_drop_down,
                                    size: 20,
                                    color: priceColor,
                                  ),
                                  Text(
                                    '${stock.change.toStringAsFixed(2)}  '
                                    '(${stock.changePercent.toStringAsFixed(2)}%)',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: priceColor,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ] else ...[
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('--.--',
                                  style: TextStyle(
                                      fontSize: 32, color: Color(0xFF8899AA))),
                              Text('--.-- (--.--%)',
                                  style: TextStyle(
                                      fontSize: 16, color: Color(0xFF8899AA))),
                            ],
                          ),
                        ],
                      ],
                    ),
                    if (stock != null) ...[
                      const SizedBox(height: 16),
                      const Divider(color: Color(0xFF1A3A5C)),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _detailItem('开', stock.open),
                          _detailItem('高', stock.high),
                          _detailItem('低', stock.low),
                          _detailItem('昨收', stock.preClose),
                          _detailItem('量', stock.volume.toDouble()),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // 走势图
            SizedBox(
              height: 450,
              child: Card(
                color: const Color(0xFF1C3045),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: Color(0xFF2A4058)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      // Chart type tabs
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _ChartTypeBtn(
                            label: t('time_sharing'),
                            active: _chartType == 'time_sharing',
                            onTap: () {
                              setState(() {
                                _chartType = 'time_sharing';
                                _kLines = null;
                              });
                            },
                          ),
                          _ChartTypeBtn(
                            label: t('daily_k'),
                            active: _chartType == 'daily_k',
                            onTap: () {
                              setState(() => _chartType = 'daily_k');
                              _loadKLineData(stockCode, 'daily');
                            },
                          ),
                          _ChartTypeBtn(
                            label: t('monthly_k'),
                            active: _chartType == 'monthly_k',
                            onTap: () {
                              setState(() => _chartType = 'monthly_k');
                              _loadKLineData(stockCode, 'monthly');
                            },
                          ),
                          _ChartTypeBtn(
                            label: t('yearly_k'),
                            active: _chartType == 'yearly_k',
                            onTap: () {
                              setState(() => _chartType = 'yearly_k');
                              _loadKLineData(stockCode, 'yearly');
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF0A2740),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: _buildChart(stock, stockCode),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(Stock? stock, String code) {
    if (_chartType == 'time_sharing') {
      if (stock != null) {
        final base = stock.preClose > 0 ? stock.preClose : 100.0;
        final points = <TimeSharingPoint>[];
        for (var i = 0; i < 60; i++) {
          final hour = 9 + i ~/ 10;
          final min = (i % 10) * 6;
          final t =
              '${hour.toString().padLeft(2, '0')}:${min.toString().padLeft(2, '0')}';
          final offset =
              (i - 5).toDouble() * (stock.change / stock.preClose * base * 2);
          points.add(TimeSharingPoint(time: t, price: base + offset));
        }
        if (points.isNotEmpty) {
          points.last =
              TimeSharingPoint(time: points.last.time, price: stock.currentPrice);
        }
        return StockChart(
          chartType: 'time_sharing',
          isAShare: ['sh', 'sz', 'bj'].contains(stock.market),
          preClose: stock.preClose,
          timeSharingPoints: points,
        );
      }
    } else if (_kLines != null && _kLines!.isNotEmpty) {
      return StockChart(
        chartType: _chartType,
        isAShare: ['sh', 'sz', 'bj'].contains(stock?.market ?? 'sh'),
        kLines: _kLines,
      );
    }
    return StockChart(
      chartType: _chartType,
      isAShare: true,
    );
  }

  Widget _detailItem(String label, double value) {
    final formatted = value >= 1000000
        ? '${(value / 1000000).toStringAsFixed(1)}M'
        : value.toStringAsFixed(2);
    return Column(
      children: [
        Text(label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF667788))),
        const SizedBox(height: 4),
        Text(formatted,
            style: const TextStyle(fontSize: 13, color: Color(0xFFBADBFF))),
      ],
    );
  }

  Future<void> _toggleWatchlist(String stockCode) async {
    setState(() => _isToggling = true);
    try {
      final auth = context.read<AuthProvider>();
      final watchlist = List<String>.from(auth.user.watchlist);
      if (_isInWatchlist) {
        watchlist.remove(stockCode);
      } else {
        if (!watchlist.contains(stockCode)) {
          watchlist.add(stockCode);
        }
      }
      await UserService.syncWatchlist(watchlist);
      setState(() {
        _isInWatchlist = !_isInWatchlist;
        _isToggling = false;
      });
    } catch (e) {
      setState(() => _isToggling = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失败: $e')),
        );
      }
    }
  }
}

class _ChartTypeBtn extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ChartTypeBtn({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF003EA5).withOpacity(0.3) : null,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: active ? const Color(0xFF5DA3F3) : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? const Color(0xFF5DA3F3) : const Color(0xFF8899AA),
            fontSize: 13,
            fontWeight: active ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
