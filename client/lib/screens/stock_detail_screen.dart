import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../i18n/i18n_service.dart';
import '../models/stock.dart';
import '../providers/auth_provider.dart';
import '../providers/stock_provider.dart';
import '../services/user_service.dart';

/// 股票详情页
class StockDetailScreen extends StatefulWidget {
  StockDetailScreen({super.key});

  @override
  State<StockDetailScreen> createState() => _StockDetailScreenState();
}

class _StockDetailScreenState extends State<StockDetailScreen> {
  bool _isInWatchlist = false;
  bool _isToggling = false;

  @override
  Widget build(BuildContext context) {
    final stockCode =
        ModalRoute.of(context)?.settings.arguments as String? ?? '000001';
    final stockProv = context.watch<StockProvider>();
    final auth = context.watch<AuthProvider>();
    final stock = stockProv.getStock(stockCode);

    // Check if in watchlist
    if (auth.isLoggedIn && auth.user.watchlist.contains(stockCode)) {
      _isInWatchlist = true;
    }

    final isAShare = ['sh', 'sz', 'bj'].contains(stock?.market ?? 'sh');
    final isRise = stock?.isRise ?? true;
    final priceColor = isRise
        ? (isAShare ? const Color(0xFFFF5757) : const Color(0xFF2FAC00))
        : (isAShare ? const Color(0xFF2FAC00) : const Color(0xFFFF5757));

    return Scaffold(
      appBar: AppBar(
        title: Text(stock?.name ?? stockCode),
        actions: [
          // Add/remove watchlist
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
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          stockCode,
                          style: Theme.of(context).textTheme.headlineLarge,
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
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      // Chart type tabs
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _ChartTypeBtn(label: t('time_sharing'), active: true),
                          _ChartTypeBtn(label: t('daily_k')),
                          _ChartTypeBtn(label: t('monthly_k')),
                          _ChartTypeBtn(label: t('yearly_k')),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF0A2740),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Center(
                            child: Text(
                              '走势图加载中...',
                              style: TextStyle(color: Color(0xFF556677)),
                            ),
                          ),
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

  Widget _detailItem(String label, double value) {
    final formatted = value >= 1000000
        ? '${(value / 1000000).toStringAsFixed(1)}M'
        : value.toStringAsFixed(2);
    return Column(
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11, color: Color(0xFF667788))),
        const SizedBox(height: 4),
        Text(formatted,
            style: const TextStyle(
                fontSize: 13, color: Color(0xFFBADBFF))),
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

  const _ChartTypeBtn({required this.label, this.active = false});

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}
