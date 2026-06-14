import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../i18n/i18n_service.dart';
import '../i18n/app_locale.dart';
import '../models/stock.dart';
import '../providers/auth_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/stock_provider.dart';
import '../providers/stock_provider.dart';
import '../services/user_service.dart';

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

  // Market indices grouped by tab
  static const _marketCodes = [
    ['000001', '399001', '399006', '000688'], // 沪深
    ['899050'], // 北证
    ['HSI', 'HSCCI', 'HSCEI', 'VHSI'], // 港股
    ['DJI', 'IXIC', 'GSPC'], // 美股
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
    // Check guest session duration
    Future.delayed(Duration.zero, () {
      context.read<AuthProvider>().checkSessionDuration();
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(t('market_overview')),
        actions: [
          // IP/国家选择器
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: () => _showCountryPicker(context),
            tooltip: t('country_code'),
          ),
          // 个人中心
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
                        leading: Icon(Icons.delete_forever, size: 20, color: Colors.red),
                        title: Text('注销帐号', style: TextStyle(fontSize: 13, color: Colors.red)),
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
          tabs: _tabs.map((key) {
            final idx = _tabs.indexOf(key);
            return Tab(text: t(key));
          }).toList(),
        ),
      ),
      body: Column(
        children: [
          // 页面管理栏
          _buildPageBar(context),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: List.generate(
                _tabs.length,
                (tabIdx) => _buildMarketGrid(context, tabIdx),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageBar(BuildContext context) {
    final stockProv = context.watch<StockProvider>();

    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF0A2740),
        border: Border(bottom: BorderSide(color: Color(0xFF1A3A5C))),
      ),
      child: Row(
        children: [
          // Page tabs
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: stockProv.pages.length,
              itemBuilder: (context, idx) {
                final page = stockProv.pages[idx];
                final isActive = page.id == stockProv.currentPageId;
                return GestureDetector(
                  onTap: () => stockProv.switchPage(page.id),
                  child: Container(
                    margin: const EdgeInsets.only(right: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isActive ? const Color(0xFF003EA5) : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      page.name,
                      style: TextStyle(
                        color: isActive ? Colors.white : const Color(0xFF8899AA),
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Add page button
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.add, size: 20, color: Color(0xFF5DA3F3)),
            onPressed: () => _showAddPageDialog(context),
            tooltip: t('add_chart'),
          ),
        ],
      ),
    );
  }

  Widget _buildMarketGrid(BuildContext context, int tabIdx) {
    final stockProv = context.watch<StockProvider>();
    final codes = _marketCodes[tabIdx];

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 500,
        mainAxisExtent: 300,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: codes.length,
      itemBuilder: (context, idx) {
        final code = codes[idx];
        final stock = stockProv.getStock(code);
        return ChartCard(
          stockCode: code,
          stock: stock,
        );
      },
    );
  }

  void _showCountryPicker(BuildContext context) {
    final countryMap = {
      '+86': '中国',
      '+852': '香港',
      '+853': '澳门',
      '+886': '台湾',
      '+1': '美国/加拿大',
      '+44': '英国',
      '+81': '日本',
      '+82': '韩国',
      '+84': '越南',
      '+63': '菲律宾',
      '+60': '马来西亚',
      '+971': '阿联酋',
      '+33': '法国',
      '+49': '德国',
      '+34': '西班牙',
      '+39': '意大利',
      '+7': '俄罗斯',
      '+91': '印度',
    };

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t('country_code')),
        content: SizedBox(
          width: 300,
          child: ListView(
            shrinkWrap: true,
            children: countryMap.entries.map((entry) {
              return ListTile(
                title: Text('${entry.key}  ${entry.value}'),
                onTap: () {
                  Navigator.pop(ctx);
                  // Auto-set language based on country
                  _setLanguageForCountry(context, entry.key);
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  void _setLanguageForCountry(BuildContext context, String countryCode) {
    // Map country codes to app locales
    final Map<String, String> countryToLocale = {
      '+86': 'zhCN',
      '+852': 'zhTW',
      '+853': 'zhTW',
      '+886': 'zhTW',
      '+1': 'en',
      '+44': 'en',
      '+81': 'ja',
      '+82': 'ko',
      '+84': 'vi',
      '+63': 'fil',
      '+60': 'ms',
      '+971': 'ar',
      '+33': 'fr',
      '+49': 'de',
      '+34': 'es',
      '+39': 'it',
      '+7': 'ru',
      '+91': 'hi',
    };

    final localeStr = countryToLocale[countryCode];
    if (localeStr != null) {
      final locale = AppLocale.values.firstWhere(
        (l) => l.name == localeStr,
        orElse: () => AppLocale.en,
      );
      context.read<LocaleProvider>().setLocale(locale);
    }
  }

  void _showAddPageDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t('add_chart')),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: '${t('page')} name',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t('cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                context.read<StockProvider>().addPage(name);
              }
              Navigator.pop(ctx);
            },
            child: Text(t('confirm')),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final oldPwdCtl = TextEditingController();
    final newPwdCtl = TextEditingController();
    final confirmCtl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t('change_password')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldPwdCtl,
              obscureText: true,
              decoration: InputDecoration(labelText: t('current_password')),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: newPwdCtl,
              obscureText: true,
              decoration: InputDecoration(labelText: t('new_password')),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: confirmCtl,
              obscureText: true,
              decoration: InputDecoration(labelText: t('confirm_password')),
            ),
            const SizedBox(height: 4),
            Text(
              t('password_rule'),
              style: const TextStyle(fontSize: 11, color: Color(0xFF8899AA)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t('cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              final auth = context.read<AuthProvider>();
              final result = await auth.changePassword(
                oldPassword: oldPwdCtl.text.isEmpty ? null : oldPwdCtl.text,
                newPassword: newPwdCtl.text,
                confirmPassword: confirmCtl.text,
              );
              if (mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result?['message'] ?? 'Done'),
                  ),
                );
              }
            },
            child: Text(t('submit')),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t('delete_account_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t('cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC13636),
            ),
            onPressed: () async {
              final auth = context.read<AuthProvider>();
              await auth.deleteAccount();
              if (mounted) Navigator.pop(ctx);
            },
            child: Text(t('confirm')),
          ),
        ],
      ),
    );
  }
}

/// 走势图卡片 Widget — 实时数据显示版
class ChartCard extends StatelessWidget {
  final String stockCode;
  final Stock? stock;

  const ChartCard({
    super.key,
    required this.stockCode,
    this.stock,
  });

  @override
  Widget build(BuildContext context) {
    final isAShare = ['sh', 'sz', 'bj'].contains(stock?.market ?? '');
    final isRise = stock?.isRise ?? true;
    // A-share: red = up, green = down. Others: green = up, red = down
    final up = isAShare ? 'red' : 'green';
    final colorRise = isAShare
        ? const Color(0xFFFF5757)
        : const Color(0xFF2FAC00);
    final colorFall = isAShare
        ? const Color(0xFF2FAC00)
        : const Color(0xFFFF5757);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: name + price + change
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stock?.name ?? stockCode,
                        style: Theme.of(context).textTheme.titleMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        stockCode,
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
                        stock!.currentPrice.toStringAsFixed(2),
                        style: TextStyle(
                          fontSize: 18,
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
                            '${stock!.changePercent.toStringAsFixed(2)}%',
                            style: TextStyle(
                              fontSize: 13,
                              color: isRise ? colorRise : colorFall,
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
                          style: TextStyle(fontSize: 18, color: Color(0xFF8899AA))),
                      Text('--.--%',
                          style: TextStyle(fontSize: 13, color: Color(0xFF8899AA))),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 8),
            // Price details
            if (stock != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _priceLabel('O', stock!.open),
                  _priceLabel('H', stock!.high),
                  _priceLabel('L', stock!.low),
                  _priceLabel('V', stock!.volume.toDouble()),
                ],
              ),
            const SizedBox(height: 8),
            // Chart body
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
            const SizedBox(height: 8),
            // Chart type tabs
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ChartTypeChip(label: t('time_sharing'), active: true),
                _ChartTypeChip(label: t('daily_k')),
                _ChartTypeChip(label: t('monthly_k')),
                _ChartTypeChip(label: t('yearly_k')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _priceLabel(String label, double value) {
    final formatted =
        value >= 1000000 ? '${(value / 1000000).toStringAsFixed(1)}M' : value.toStringAsFixed(1);
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

class _ChartTypeChip extends StatelessWidget {
  final String label;
  final bool active;

  const _ChartTypeChip({required this.label, this.active = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: active ? const Color(0xFF003EA5) : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: active ? const Color(0xFF5DA3F3) : const Color(0xFF334455),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: active ? const Color(0xFFBADBFF) : const Color(0xFF8899AA),
          fontSize: 12,
        ),
      ),
    );
  }
}
