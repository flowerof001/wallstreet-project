import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'i18n/i18n_service.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/watchlist_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/login_screen.dart';
import 'screens/stock_detail_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/stock_provider.dart';
import 'providers/locale_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await I18nService().init();

  // 初始化 auth（恢复之前的登录会籍）
  final authProvider = AuthProvider();
  await authProvider.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => StockProvider()..connect()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ],
      child: const WallstreetApp(),
    ),
  );
}

class WallstreetApp extends StatelessWidget {
  const WallstreetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wallstreet',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const MainShell(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/stock-detail': (context) => StockDetailScreen(),
      },
    );
  }
}

/// 主体框架：左侧菜单 + 右侧内容
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomeScreen(),
    WatchlistScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // 左侧菜单栏
          NavigationRail(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              setState(() => _currentIndex = index);
            },
            backgroundColor: const Color(0xFF0A2740),
            indicatorColor: const Color(0xFF003EA5),
            labelType: NavigationRailLabelType.all,
            destinations: [
              NavigationRailDestination(
                icon: const Icon(Icons.home_outlined),
                selectedIcon: const Icon(Icons.home),
                label: Text(t('home')),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.star_outline),
                selectedIcon: const Icon(Icons.star),
                label: Text(t('watchlist')),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.settings_outlined),
                selectedIcon: const Icon(Icons.settings),
                label: Text(t('settings')),
              ),
            ],
          ),
          const VerticalDivider(width: 1),
          // 右侧内容区域
          Expanded(
            child: _pages[_currentIndex],
          ),
        ],
      ),
    );
  }
}
