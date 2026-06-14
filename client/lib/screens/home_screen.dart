import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../i18n/i18n_service.dart';
import '../models/stock.dart';
import '../providers/auth_provider.dart';
import '../providers/stock_provider.dart';
import '../providers/locale_provider.dart';
import '../i18n/app_locale.dart';
import '../widgets/stock_chart.dart';
import '../widgets/chart_card.dart';

/// 首页 — Tab栏展示沪深/北证/港股/美股指数走势
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _tabs = [
    'market_shanghai_shenzhen',
    'market_beijing',
    'market_hongkong',
    'market_us',
  ];

  static const _marketCodes = [
    ['000001', '399001', '399006', '000688'], // 沪深
    ['899050'], // 北证
    ['HSI', 'HSCCI', 'HSCEI', 'VHSI'], // 港股
    ['DJI', 'IXIC', 'GSPC'], // 美股
  ];

  static const _marketNames = [
    ['上证指数', '深证成指', '创业板指', '科创50'],
    ['北证50'],
    ['恒生指数', '红筹指数', '国企指数', '恒指波幅指数'],
    ['道琼斯工业指数', '纳斯达克综合指数', '标普500指数'],
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Future.delayed(Duration.zero, () {
      context.read<AuthProvider>().checkSessionDuration();
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(t('market_overview')),
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: () => _showCountryPicker(context),
            tooltip: t('country_code'),
          ),
          Consumer<AuthProvider>(
            builder: (context, auth, _) {
              if (auth.isLoggedIn) {
                return PopupMenuButton<String>(
                  icon: const Icon(Icons.account_circle),
                  onSelected: (value) {
                    if (value == 'logout') {
                      auth.logout();
                    } else if (value == 'password') {
                      _showChangePasswordDialog(context);
                    } else if (value == 'delete') {
                      _showDeleteAccountDialog(context);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      enabled: false,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${auth.user.countryCode} ${auth.user.phone}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Color(0xFFBADBFF),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'password',
                      child: ListTile(
                        leading: Icon(Icons.lock_outline, size: 20),
                        title: Text('修改登录密码', style: TextStyle(fontSize: 13)),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'logout',
                      child: ListTile(
                        leading: Icon(Icons.logout, size: 20),
                        title: Text('退出登录', style: TextStyle(fontSize: 13)),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(Icons.delete_forever, size: 20, color: Color(0xFFFF5757)),
                        title: Text('注销帐号', style: TextStyle(fontSize: 13, color: Color(0xFFFF5757))),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: false,
          indicatorColor: const Color(0xFF5DA3F3),
          labelColor: const Color(0xFF5DA3F3),
          unselectedLabelColor: const Color(0xFF8899AA),
          tabs: _tabs.map((key) => Tab(text: t(key))).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: List.generate(_tabs.length, (tabIndex) {
          final codes = _marketCodes[tabIndex];
          final names = _marketNames[tabIndex];
          return Padding(
            padding: const EdgeInsets.all(12),
            child: ListView.builder(
              itemCount: codes.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _IndexChartCard(
                    code: codes[index],
                    name: names[index],
                  ),
                );
              },
            ),
          );
        }),
      ),
    );
  }
}

/// 指数走势图卡片
class _IndexChartCard extends StatelessWidget {
  final String code;
  final String name;

  const _IndexChartCard({required this.code, required this.name});

  @override
  Widget build(BuildContext context) {
    final stockProv = context.watch<StockProvider>();
    final stock = stockProv.getStock(code);
    final isRise = stock?.isRise ?? true;
    final colorRise = const Color(0xFFFF5757);
    final colorFall = const Color(0xFF2FAC00);

    return Card(
      color: const Color(0xFF1C3045),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFF2A4058)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header: name, price, change
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFBADBFF),
                      ),
                    ),
                    Text(
                      code,
                      style: const TextStyle(
                        fontSize: 11,
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
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isRise ? colorRise : colorFall,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            isRise ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                            size: 16,
                            color: isRise ? colorRise : colorFall,
                          ),
                          Text(
                            '${stock.changePercent.toStringAsFixed(2)}%',
                            style: TextStyle(
                              fontSize: 13,
                              color: isRise ? colorRise : colorFall,
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
                          style: TextStyle(fontSize: 20, color: Color(0xFF8899AA))),
                      Text('--.--%',
                          style: TextStyle(fontSize: 13, color: Color(0xFF8899AA))),
                    ],
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            // Price details
            if (stock != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _priceLabel('开', stock.open),
                  _priceLabel('高', stock.high),
                  _priceLabel('低', stock.low),
                  _priceLabel('昨收', stock.preClose),
                ],
              ),
            const SizedBox(height: 8),
            // Mini chart
            SizedBox(
              height: 180,
              child: stock != null
                  ? StockChart(
                      chartType: 'time_sharing',
                      isAShare: ['sh', 'sz', 'bj'].contains(stock.market),
                      preClose: stock.preClose,
                      timeSharingPoints: _generateSimulatedPoints(stock),
                    )
                  : const Center(
                      child: Text(
                        '数据加载中...',
                        style: TextStyle(color: Color(0xFF556677)),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  List<TimeSharingPoint> _generateSimulatedPoints(Stock stock) {
    final base = stock.preClose > 0 ? stock.preClose : 100.0;
    final points = <TimeSharingPoint>[];
    for (var i = 0; i < 60; i++) {
      final hour = 9 + i ~/ 10;
      final min = (i % 10) * 6;
      final t = '${hour.toString().padLeft(2, '0')}:${min.toString().padLeft(2, '0')}';
      final offset = (i - 5).toDouble() * (stock.change / stock.preClose * base * 2);
      points.add(TimeSharingPoint(time: t, price: base + offset));
    }
    // Ensure the last point matches current price
    if (points.isNotEmpty) {
      points.last = TimeSharingPoint(time: points.last.time, price: stock.currentPrice);
    }
    return points;
  }

  Widget _priceLabel(String label, double value) {
    final formatted = value.toStringAsFixed(2);
    return Column(
      children: [
        Text(label,
            style: const TextStyle(fontSize: 10, color: Color(0xFF667788))),
        Text(formatted,
            style: const TextStyle(fontSize: 11, color: Color(0xFF8899AA))),
      ],
    );
  }
}

// ---- Dialogs ----

void _showCountryPicker(BuildContext context) {
  final localeProv = context.read<LocaleProvider>();
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF1C3045),
      title: const Text('选择国家/语言', style: TextStyle(color: Color(0xFFBADBFF))),
      content: SizedBox(
        width: 300,
        child: ListView(
          shrinkWrap: true,
          children: AppLocale.values.map((locale) {
            return ListTile(
              title: Text(
                '${locale.nativeName} (${locale.englishName})',
                style: const TextStyle(color: Color(0xFFBADBFF)),
              ),
              leading: localeProv.locale == locale
                  ? const Icon(Icons.check, color: Color(0xFF5DA3F3))
                  : null,
              onTap: () {
                localeProv.setLocale(locale);
                Navigator.pop(ctx);
              },
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('取消'),
        ),
      ],
    ),
  );
}

void _showChangePasswordDialog(BuildContext context) {
  final auth = context.read<AuthProvider>();
  final oldPwdCtrl = TextEditingController();
  final newPwdCtrl = TextEditingController();
  final confirmPwdCtrl = TextEditingController();
  final hasOldPassword = true; // simplified

  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF1C3045),
      title: const Text('修改登录密码', style: TextStyle(color: Color(0xFFBADBFF))),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasOldPassword)
            TextField(
              controller: oldPwdCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: '输入原来的密码'),
            ),
          TextField(
            controller: newPwdCtrl,
            obscureText: true,
            decoration: const InputDecoration(labelText: '输入新密码'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: confirmPwdCtrl,
            obscureText: true,
            decoration: const InputDecoration(labelText: '再次输入新密码'),
          ),
          const SizedBox(height: 8),
          const Text(
            '密码为6-32位英文字母、数字和特殊符号',
            style: TextStyle(fontSize: 11, color: Color(0xFF8899AA)),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: () async {
            final result = await auth.changePassword(
              oldPassword: hasOldPassword ? oldPwdCtrl.text : null,
              newPassword: newPwdCtrl.text,
              confirmPassword: confirmPwdCtrl.text,
            );
            if (ctx.mounted) {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(result['message'] ?? '操作完成'),
                ),
              );
            }
          },
          child: const Text('提交'),
        ),
      ],
    ),
  );
}

void _showDeleteAccountDialog(BuildContext context) {
  final auth = context.read<AuthProvider>();
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF1C3045),
      title: const Text('您确定要注销帐号吗？',
          style: TextStyle(color: Color(0xFFFF5757))),
      content: const Text('注销后无法恢复，请谨慎操作。',
          style: TextStyle(color: Color(0xFF8899AA))),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: () async {
            final success = await auth.deleteAccount();
            if (ctx.mounted) {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(success ? '帐号已注销' : '注销失败'),
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF5757),
          ),
          child: const Text('确定'),
        ),
      ],
    ),
  );
}
