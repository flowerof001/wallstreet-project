import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../i18n/i18n_service.dart';
import '../providers/stock_provider.dart';
import '../providers/auth_provider.dart';
import '../models/stock.dart';

/// 自选股票搜索页 — 实时搜索 + 结果列表
class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({super.key});

  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen> {
  final _searchController = TextEditingController();
  List<Stock> _results = [];
  bool _isSearching = false;
  String? _error;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _onSearch(String keyword) async {
    if (keyword.trim().isEmpty) {
      setState(() {
        _results = [];
        _error = null;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      final prov = context.read<StockProvider>();
      final stocks = await prov.searchStocks(keyword.trim());
      if (mounted) {
        setState(() {
          _results = stocks;
          _isSearching = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(t('watchlist'))),
      body: Column(
        children: [
          // 搜索框
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearch,
              decoration: InputDecoration(
                hintText: t('search_stock'),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _results.clear();
                            _error = null;
                          });
                        },
                      )
                    : null,
              ),
            ),
          ),
          // 搜索结果
          if (_isSearching)
            const Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _error!,
                style: const TextStyle(color: Color(0xFFFF5757)),
              ),
            ),
          if (!_isSearching && _error == null)
            Expanded(
              child: _results.isEmpty && _searchController.text.isNotEmpty
                  ? const Center(
                      child: Text(
                        'No results found',
                        style: TextStyle(color: Color(0xFF8899AA)),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _results.length,
                      itemBuilder: (context, index) {
                        final stock = _results[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFF0A2E67),
                            child: Text(
                              stock.code.isNotEmpty ? stock.code[0] : '?',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          title: Text(stock.name.isNotEmpty ? stock.name : stock.code),
                          subtitle: Text(
                            stock.code,
                            style: const TextStyle(
                              color: Color(0xFF8899AA),
                              fontSize: 12,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.chevron_right,
                            color: Color(0xFF556677),
                          ),
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              '/stock-detail',
                              arguments: stock.code,
                            );
                          },
                        );
                      },
                    ),
            ),
        ],
      ),
    );
  }
}
