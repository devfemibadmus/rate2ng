import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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

  Future<List<dynamic>> fetchCoins() async {
    final res =
        await http.get(Uri.parse('https://api.coinlore.net/api/tickers/'));
    if (res.statusCode == 200) {
      final jsonData = json.decode(res.body);
      return (jsonData['data'] as List).take(10).toList();
    } else {
      throw Exception('Failed to load coins');
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
    super.initState();
    fetchCoins().then((coins) {
      setState(() {
        _cachedCoins = coins;
      });
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
          TextButton(onPressed: () {}, child: Text('Sell')),
          TextButton(onPressed: () {}, child: Text('Buy')),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final coins = await fetchCoins();
          setState(() {
            _cachedCoins = coins;
          });
        },
        child: ListView.builder(
          physics: BouncingScrollPhysics(),
          itemCount: _cachedCoins.length,
          itemBuilder: (context, index) {
            final coin = _cachedCoins[index];
            final imageUrl =
                'https://raw.githubusercontent.com/devfemibadmus/rate2ng/refs/heads/main/assets/${coin["nameid"]}.png';
            return Card(
              child: ListTile(
                leading: Image.network(
                  imageUrl,
                  width: 40,
                  height: 40,
                  errorBuilder: (_, __, ___) => Icon(Icons.error),
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
                      style:
                          TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                    Text(
                      '${(double.tryParse(coin["percent_change_24h"]) ?? 0) < 0 ? '' : '+'}${coin["percent_change_24h"]}%',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                        color:
                            (double.tryParse(coin["percent_change_24h"]) ?? 0) <
                                    0
                                ? const Color.fromARGB(255, 160, 11, 0)
                                : const Color.fromARGB(255, 0, 121, 4),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
