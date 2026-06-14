/// 走势图卡片 Widget — 实时数据显示 + 图表 + 交互
///
/// 替代原始的 _StockChartCard inline widget。
/// 支持拖拽排序、缩放和删除。
import 'package:flutter/material.dart';
import '../models/stock.dart' as model;
import '../widgets/stock_chart.dart';
import '../i18n/i18n_service.dart';

class ChartCard extends StatefulWidget {
  final String stockCode;
  final model.Stock? stock;
  final String chartType;
  final double width;
  final double height;
  final VoidCallback? onRemove;
  final VoidCallback? onResize;
  final Function(String chartType)? onChartTypeChanged;
  final bool showActions;

  const ChartCard({
    super.key,
    required this.stockCode,
    this.stock,
    this.chartType = 'time_sharing',
    this.width = 400,
    this.height = 300,
    this.onRemove,
    this.onResize,
    this.onChartTypeChanged,
    this.showActions = true,
  });

  @override
  State<ChartCard> createState() => _ChartCardState();
}

class _ChartCardState extends State<ChartCard> {
  late String _chartType;

  @override
  void initState() {
    super.initState();
    _chartType = widget.chartType;
  }

  @override
  Widget build(BuildContext context) {
    final stock = widget.stock;
    final isAShare = ['sh', 'sz', 'bj'].contains(stock?.market ?? 'sh');
    final isRise = stock?.isRise ?? true;

    final priceColor = isRise
        ? (isAShare ? const Color(0xFFFF5757) : const Color(0xFF2FAC00))
        : (isAShare ? const Color(0xFF2FAC00) : const Color(0xFFFF5757));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            _buildHeader(stock, priceColor, isRise),
            const SizedBox(height: 6),
            // Price details row
            if (stock != null) _buildPriceDetails(stock),
            const SizedBox(height: 6),
            // Chart area
            Expanded(
              child: _buildChart(stock, isAShare),
            ),
            const SizedBox(height: 6),
            // Chart type tabs
            _buildChartTabs(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(model.Stock? stock, Color priceColor, bool isRise) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                stock?.name ?? widget.stockCode,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFBADBFF),
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                widget.stockCode,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF8899AA),
                ),
              ),
            ],
          ),
        ),
        if (stock != null)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                stock.currentPrice.toStringAsFixed(2),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: priceColor,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isRise ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                    size: 14,
                    color: priceColor,
                  ),
                  Text(
                    '${stock.changePercent.toStringAsFixed(2)}%',
                    style: TextStyle(
                      fontSize: 11,
                      color: priceColor,
                    ),
                  ),
                ],
              ),
            ],
          )
        else
          const Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('--.--',
                  style:
                      TextStyle(fontSize: 16, color: Color(0xFF8899AA))),
              Text('--.--%',
                  style:
                      TextStyle(fontSize: 11, color: Color(0xFF8899AA))),
            ],
          ),
        // Actions menu
        if (widget.showActions)
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert,
                size: 16, color: Color(0xFF556677)),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onSelected: (value) {
              if (value == 'remove') {
                widget.onRemove?.call();
              } else if (value == 'timeline' ||
                  value == 'daily' ||
                  value == 'monthly' ||
                  value == 'yearly') {
                setState(() => _chartType = value);
                widget.onChartTypeChanged?.call(value);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'timeline',
                child: Text(t('time_sharing'), style: TextStyle(fontSize: 12)),
              ),
              const PopupMenuItem(
                value: 'daily',
                child: Text(t('daily_k'), style: TextStyle(fontSize: 12)),
              ),
              const PopupMenuItem(
                value: 'monthly',
                child: Text(t('monthly_k'), style: TextStyle(fontSize: 12)),
              ),
              const PopupMenuItem(
                value: 'yearly',
                child: Text(t('yearly_k'), style: TextStyle(fontSize: 12)),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'remove',
                child: Text(t('remove_chart'),
                    style: TextStyle(fontSize: 12, color: Color(0xFFFF5757))),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildPriceDetails(model.Stock stock) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _priceChip('O', stock.open),
        _priceChip('H', stock.high),
        _priceChip('L', stock.low),
        _priceChip('V', stock.volume.toDouble()),
      ],
    );
  }

  Widget _priceChip(String label, double value) {
    final formatted = value >= 1000000
        ? '${(value / 1000000).toStringAsFixed(1)}M'
        : value >= 10000
            ? '${(value / 10000).toStringAsFixed(1)}万'
            : value.toStringAsFixed(1);
    return Column(
      children: [
        Text(label,
            style: const TextStyle(fontSize: 9, color: Color(0xFF667788))),
        Text(formatted,
            style: const TextStyle(fontSize: 10, color: Color(0xFF8899AA))),
      ],
    );
  }

  Widget _buildChart(model.Stock? stock, bool isAShare) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A2740),
        borderRadius: BorderRadius.circular(4),
      ),
      child: StockChart(
        chartType: _chartType,
        isAShare: isAShare,
        preClose: stock?.preClose,
      ),
    );
  }

  Widget _buildChartTabs() {
    final tabs = [
      ('time_sharing', t('time_sharing')),
      ('daily_k', t('daily_k')),
      ('monthly_k', t('monthly_k')),
      ('yearly_k', t('yearly_k')),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: tabs.map((tab) {
        final active = _chartType == tab.$1;
        return GestureDetector(
          onTap: () {
            setState(() => _chartType = tab.$1);
            widget.onChartTypeChanged?.call(tab.$1);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: active
                  ? const Color(0xFF003EA5).withOpacity(0.3)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: active
                    ? const Color(0xFF5DA3F3)
                    : const Color(0xFF334455),
              ),
            ),
            child: Text(
              tab.$2,
              style: TextStyle(
                fontSize: 11,
                color: active
                    ? const Color(0xFFBADBFF)
                    : const Color(0xFF8899AA),
                fontWeight: active ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
