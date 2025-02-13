import 'dart:async';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CurrencyPage extends StatefulWidget {
  const CurrencyPage({super.key});

  @override
  CurrencyPageState createState() => CurrencyPageState();
}

class CurrencyPageState extends State<CurrencyPage>
    with AutomaticKeepAliveClientMixin<CurrencyPage> {
  @override
  bool get wantKeepAlive => true;
  late Timer _timer;
  Map<String, dynamic> _cachedCurrencies = {};
  Map<String, dynamic> _cachedRates = {};
  bool _isActive = true;
  String _lastFetchTime = '';

  Future<Map<String, dynamic>> fetchCurrencyMetadata() async {
    try {
      final res = await http
          .get(Uri.parse('http://127.0.0.1:8000/'))
          .timeout(Duration(seconds: 10));
      if (res.statusCode == 200) {
        final jsonData = json.decode(res.body);
        saveMetadataToCache(jsonData);
        return jsonData;
      }
    } catch (_) {}
    return loadMetadataFromCache();
  }

  Future<Map<String, dynamic>> fetchCurrencyRates() async {
    try {
      final res = await http
          .get(Uri.parse('http://127.0.0.1:8000/rates?api_key=uhmmmmmmmmm'))
          .timeout(Duration(seconds: 10));
      if (res.statusCode == 200) {
        final jsonData = json.decode(res.body);
        setState(() {
          _lastFetchTime =
              DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
        });
        saveRatesToCache(jsonData);
        return jsonData;
      }
    } catch (_) {}
    return loadRatesFromCache();
  }

  Future<void> saveMetadataToCache(Map<String, dynamic> metadata) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cachedMetadata', json.encode(metadata));
  }

  Future<Map<String, dynamic>> loadMetadataFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final metadataJson = prefs.getString('cachedMetadata');
    if (metadataJson != null) {
      return json.decode(metadataJson);
    }
    return {};
  }

  Future<void> saveRatesToCache(Map<String, dynamic> rates) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cachedRates', json.encode(rates));
    await prefs.setString('lastFetchTime_rate',
        DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()));
  }

  Future<Map<String, dynamic>> loadRatesFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final ratesJson = prefs.getString('cachedRates');
    setState(() {
      _lastFetchTime = prefs.getString('lastFetchTime_rate') ?? '';
    });
    if (ratesJson != null) {
      return json.decode(ratesJson);
    }
    return {};
  }

  void startAutoRefresh() {
    _timer = Timer.periodic(Duration(seconds: 2), (_) async {
      if (mounted && _isActive) {
        final newRates = await fetchCurrencyRates();
        if (mounted) {
          setState(() {
            _cachedRates = newRates;
          });
        }
      }
    });
  }

  @override
  void initState() {
    super.initState();
    loadMetadataFromCache().then((metadata) {
      if (metadata.isNotEmpty) {
        setState(() {
          _cachedCurrencies = metadata;
        });
      } else {
        fetchCurrencyMetadata().then((metadata) {
          setState(() {
            _cachedCurrencies = metadata;
          });
        });
      }
    });
    loadRatesFromCache().then((rates) {
      if (rates.isNotEmpty) {
        setState(() {
          _cachedRates = rates;
        });
      } else {
        fetchCurrencyRates().then((rates) {
          setState(() {
            _cachedRates = rates;
          });
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
          final rates = await fetchCurrencyRates();
          setState(() {
            _cachedRates = rates;
          });
        },
        child: ListView.builder(
          addAutomaticKeepAlives: true,
          physics: BouncingScrollPhysics(),
          itemCount: _cachedCurrencies.length,
          itemBuilder: (context, index) {
            final currencyKey = _cachedCurrencies.keys.elementAt(index);
            final currency = _cachedCurrencies[currencyKey];
            final rate = _cachedRates[currencyKey]?['price'] ??
                {'current': '0', 'last24hrs': '0'};
            final current =
                double.tryParse(rate["current"]?.replaceAll(',', '') ?? '');
            final last24hrs =
                double.tryParse(rate["last24hrs"]?.replaceAll(',', '') ?? '');

            final formattedValue = (current != null && last24hrs != null)
                ? '${(current - last24hrs) >= 0 ? '+' : ''}${(current - last24hrs).toStringAsFixed(2)}'
                : '+0.00';

            return Card(
              margin: EdgeInsets.all(8.0),
              child: ListTile(
                onTap: () => showCurrencyOverlay(context, currency, rate),
                leading: CachedNetworkImage(
                  cacheKey: 'currency_image_${currency["abbr"]}',
                  imageUrl:
                      'https://raw.githubusercontent.com/devfemibadmus/rate2ng-api/refs/heads/main/assets/currencies/${currency["abbr"] ?? 'default'}.jpg',
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) => Icon(Icons.error),
                ),
                title: Text('${currency["abbr"]}'),
                subtitle: Text('${currency["name"]}'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₦${rate["current"]}',
                      style:
                          TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                    Text(
                      formattedValue,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                        color: current! < last24hrs!
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

class CurrencyDetailsOverlay extends StatelessWidget {
  final Map<String, dynamic> currency;
  final Map<String, dynamic> rate;

  const CurrencyDetailsOverlay(
      {super.key, required this.currency, required this.rate});

  @override
  Widget build(BuildContext context) {
    final current = double.tryParse(rate["current"]?.replaceAll(',', '') ?? '');
    final last24hrs =
        double.tryParse(rate["last24hrs"]?.replaceAll(',', '') ?? '');
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
                        cacheKey: 'currency_image_${currency["abbr"]}',
                        imageUrl:
                            'https://raw.githubusercontent.com/devfemibadmus/rate2ng-api/refs/heads/main/assets/currencies/${currency["abbr"] ?? 'default'}.jpg',
                        width: 200,
                        height: 200,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) => Icon(Icons.error),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('${currency["name"]}',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    _buildDetailRow(last24hrs!, 'Current Rate', current!),
                    _buildDetailRow(current, 'Last Close', last24hrs),
                    const SizedBox(height: 16),
                    Text('About',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text('${currency["about"]}',
                        style: TextStyle(fontSize: 14)),
                  ],
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(double other, String key, double value) {
    return Row(
      children: [
        Text(
          '$key: ',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Expanded(
          child: Text(
            '₦${value.toStringAsFixed(2).replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), ',')}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: other > value
                  ? const Color.fromARGB(255, 160, 11, 0)
                  : const Color.fromARGB(255, 0, 121, 4),
            ),
          ),
        ),
      ],
    );
  }
}

void showCurrencyOverlay(BuildContext context, Map<String, dynamic> currency,
    Map<String, dynamic> rate) {
  showDialog(
    context: context,
    builder: (context) =>
        CurrencyDetailsOverlay(currency: currency, rate: rate),
  );
}
