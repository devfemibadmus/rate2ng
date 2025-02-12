import 'dart:async';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CryptoPage extends StatefulWidget {
  const CryptoPage({super.key});

  @override
  CryptoPageState createState() => CryptoPageState();
}

class CryptoPageState extends State<CryptoPage>
    with AutomaticKeepAliveClientMixin<CryptoPage> {
  @override
  bool get wantKeepAlive => true;
  late Timer _timer;
  List<dynamic> _cachedCoins = [];
  bool _isActive = true;
  String _lastFetchTime = '';

  Future<List<dynamic>> fetchCoins() async {
    try {
      final res = await http
          .get(Uri.parse('https://api.coinlore.net/api/tickers/'))
          .timeout(Duration(seconds: 10));
      if (res.statusCode == 200) {
        final jsonData = json.decode(res.body);
        setState(() {
          _lastFetchTime =
              DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
        });
        saveCoinsToCache((jsonData['data'] as List).take(10).toList());
        return (jsonData['data'] as List).take(10).toList();
      }
    } catch (_) {}
    return loadCoinsFromCache();
  }

  Future<void> saveCoinsToCache(List<dynamic> coins) async {
    final prefs = await SharedPreferences.getInstance();
    final coinsJson = json.encode(coins);
    await prefs.setString('cachedCoins', coinsJson);
    await prefs.setString('lastFetchTime',
        DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()));
  }

  Future<List<dynamic>> loadCoinsFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final coinsJson = prefs.getString('cachedCoins');
    setState(() {
      _lastFetchTime = prefs.getString('lastFetchTime') ?? '';
    });
    if (coinsJson != null) {
      final List<dynamic> cachedCoins = json.decode(coinsJson);
      return cachedCoins;
    } else {
      return [];
    }
  }

  void startAutoRefresh() {
    _timer = Timer.periodic(Duration(seconds: 2), (_) async {
      if (mounted && _isActive) {
        final newCoins = await fetchCoins();
        if (mounted) {
          setState(() {
            for (var oldCoin in _cachedCoins) {
              final newCoin = newCoins.firstWhere(
                (c) => c["id"] == oldCoin["id"],
                orElse: () => oldCoin,
              );
              oldCoin["price_usd"] = newCoin["price_usd"];
              oldCoin["percent_change_24h"] = newCoin["percent_change_24h"];
            }
          });
        }
      }
    });
  }

  @override
  void initState() {
    print("reinit");
    super.initState();
    loadCoinsFromCache().then((coins) {
      if (coins.isNotEmpty) {
        setState(() {
          _cachedCoins = coins;
        });
      } else {
        fetchCoins().then((coins) {
          setState(() {
            _cachedCoins = coins;
          });
          saveCoinsToCache(coins);
        });
      }
    });
    startAutoRefresh();
  }

  @override
  void dispose() {
    _isActive = false;
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Top 10 🔥', style: TextStyle(fontSize: 18)),
        actions: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Text(
                _lastFetchTime.isEmpty ? 'Loading...' : _lastFetchTime,
                style: TextStyle(fontSize: 14),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final coins = await fetchCoins();
          setState(() {
            _cachedCoins = coins;
          });
          saveCoinsToCache(coins);
        },
        child: ListView.builder(
          addAutomaticKeepAlives: true,
          physics: BouncingScrollPhysics(),
          itemCount: _cachedCoins.length,
          itemBuilder: (context, index) {
            final coin = _cachedCoins[index];
            return InkWell(
              onTap: () => showCoinOverlay(context, coin),
              child: Card(
                child: ListTile(
                  leading: CachedNetworkImage(
                    cacheKey: 'coin_image_${coin["nameid"]}',
                    imageUrl:
                        'https://raw.githubusercontent.com/devfemibadmus/rate2ng-api/refs/heads/main/assets/${coin["nameid"] ?? 'default'}.png',
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) => Icon(Icons.error),
                  ),
                  title: Row(
                    children: [
                      Text('${coin['symbol']}'),
                    ],
                  ),
                  subtitle: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${coin['name']}'),
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$${double.parse(coin["price_usd"]).toStringAsFixed(2).replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), ',')}',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 13),
                      ),
                      Text(
                        '${(double.tryParse(coin["percent_change_24h"]) ?? 0) < 0 ? '' : '+'}${coin["percent_change_24h"]}%',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                          color: (double.tryParse(coin["percent_change_24h"]) ??
                                      0) <
                                  0
                              ? const Color.fromARGB(255, 160, 11, 0)
                              : const Color.fromARGB(255, 0, 121, 4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class CoinDetailsOverlay extends StatelessWidget {
  final Map<String, dynamic> coin;
  final VoidCallback onClose;

  const CoinDetailsOverlay(
      {super.key, required this.coin, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      child: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 226, 226, 226),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Stack(
            children: [
              SingleChildScrollView(
                physics: BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: CachedNetworkImage(
                        cacheKey: 'coin_image_${coin["nameid"]}',
                        imageUrl:
                            'https://raw.githubusercontent.com/devfemibadmus/rate2ng-api/refs/heads/main/assets/${coin["nameid"] ?? 'default'}.png',
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.error),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(height: 8),
                    _buildDetailRow('Rank', '#${coin['rank'] ?? ''}'),
                    _buildDetailRow('Current Price',
                        '\$${double.tryParse(coin["price_usd"] ?? '0')?.toStringAsFixed(2).replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), ',') ?? ''}'),
                    _buildDetailRow('Market Cap',
                        '\$${double.tryParse(coin["market_cap_usd"] ?? '0')?.toStringAsFixed(2).replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), ',') ?? ''}'),
                    _buildDetailRow('Circulating Supply',
                        '\$${double.tryParse(coin["csupply"] ?? '0')?.toStringAsFixed(2).replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), ',') ?? ''} ${coin['symbol'] ?? ''}'),
                    Divider(),
                    SizedBox(height: 8),
                    Text(
                      '24-Hour Performance',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    SizedBox(height: 8),
                    _buildDetailRow(
                      'Price Change (1h)',
                      '${(double.tryParse(coin["percent_change_1h"] ?? '0') ?? 0) < 0 ? '' : '+'}${coin["percent_change_1h"] ?? ''}%',
                      style: TextStyle(
                        color: (double.tryParse(
                                        coin["percent_change_1h"] ?? '0') ??
                                    0) <
                                0
                            ? const Color.fromARGB(255, 160, 11, 0)
                            : const Color.fromARGB(255, 0, 121, 4),
                      ),
                    ),
                    _buildDetailRow(
                      'Price Change (24h)',
                      '${(double.tryParse(coin["percent_change_24h"] ?? '0') ?? 0) < 0 ? '' : '+'}${coin["percent_change_24h"] ?? ''}%',
                      style: TextStyle(
                        color: (double.tryParse(
                                        coin["percent_change_24h"] ?? '0') ??
                                    0) <
                                0
                            ? const Color.fromARGB(255, 160, 11, 0)
                            : const Color.fromARGB(255, 0, 121, 4),
                      ),
                    ),
                    _buildDetailRow(
                      'Price Change (7d)',
                      '${(double.tryParse(coin["percent_change_7d"] ?? '0') ?? 0) < 0 ? '' : '+'}${coin["percent_change_7d"] ?? ''}%',
                      style: TextStyle(
                        color: (double.tryParse(
                                        coin["percent_change_7d"] ?? '0') ??
                                    0) <
                                0
                            ? const Color.fromARGB(255, 160, 11, 0)
                            : const Color.fromARGB(255, 0, 121, 4),
                      ),
                    ),
                    Divider(),
                    SizedBox(height: 8),
                    Text(
                      'Supply Details',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    SizedBox(height: 8),
                    _buildDetailRow('Total Supply',
                        '\$${double.tryParse(coin["tsupply"] ?? '0')?.toStringAsFixed(2).replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), ',') ?? ''} ${coin['symbol'] ?? ''}'),
                    _buildDetailRow('Max Supply',
                        '\$${double.tryParse(coin["msupply"] ?? '0')?.toStringAsFixed(2).replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), ',') ?? ''} ${coin['symbol'] ?? ''}'),
                    Divider(),
                    SizedBox(height: 8),
                    Text(
                      'Market Data',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    SizedBox(height: 8),
                    _buildDetailRow('24h Trading Volume',
                        '\$${double.tryParse(coin['volume24']?.toString() ?? '0')?.toStringAsFixed(2).replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), ',') ?? ''}'),
                  ],
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: IconButton(
                    icon: const Icon(Icons.close), onPressed: onClose),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String key, String value, {TextStyle? style}) {
    return Row(
      children: [
        Text('$key: ',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Expanded(
          child: Text(value,
              style: style ?? const TextStyle(fontSize: 16),
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}

void showCoinOverlay(BuildContext context, Map<String, dynamic> coin) {
  late OverlayEntry overlayEntry;
  double opacity = 1.0;

  overlayEntry = OverlayEntry(
    builder: (context) => AnimatedOpacity(
      opacity: opacity,
      duration: Duration(milliseconds: 300),
      child: CoinDetailsOverlay(
        coin: coin,
        onClose: () {
          opacity = 0.0;
          overlayEntry.markNeedsBuild();
          Future.delayed(
              Duration(milliseconds: 300), () => overlayEntry.remove());
        },
      ),
    ),
  );

  Overlay.of(context).insert(overlayEntry);
}
