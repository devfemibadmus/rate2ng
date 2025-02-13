import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SwapPage extends StatefulWidget {
  const SwapPage({super.key});

  @override
  SwapPageState createState() => SwapPageState();
}

class SwapPageState extends State<SwapPage>
    with AutomaticKeepAliveClientMixin<SwapPage> {
  @override
  bool get wantKeepAlive => true;
  List<Map<String, dynamic>> _currencies = [];
  List<Map<String, dynamic>> _coins = [];
  String? _selectedFromType;
  String? _selectedFromId;
  double _fromAmount = 0.0;
  double _toAmount = 0.0;

  @override
  void initState() {
    super.initState();
    _loadCachedData();
  }

  Future<void> _loadCachedData() async {
    final prefs = await SharedPreferences.getInstance();
    final ratesJson = prefs.getString('cachedRates');
    final coinsJson = prefs.getString('cachedCoins');

    if (ratesJson != null) {
      final ratesData = json.decode(ratesJson) as Map<String, dynamic>;
      _currencies = ratesData.entries.map<Map<String, dynamic>>((entry) {
        return {
          'type': 'currency',
          'id': entry.key,
          'name': entry.key.replaceAll('-NGN', ''),
          'price': double.tryParse(
                  entry.value['price']['current'].replaceAll(',', '')) ??
              0.0,
        };
      }).toList();
    }

    if (coinsJson != null) {
      final coinsData = json.decode(coinsJson) as List<dynamic>;
      _coins = coinsData.map<Map<String, dynamic>>((coin) {
        return {
          'type': 'coin',
          'id': coin['id'],
          'name': coin['name'],
          'price': double.tryParse(coin['price_usd']) ?? 0.0,
        };
      }).toList();
    }

    setState(() {});
  }

  void _calculateSwap() {
    if (_selectedFromType == null ||
        _selectedFromId == null ||
        _fromAmount <= 0) {
      setState(() {
        _toAmount = 0.0;
      });
      return;
    }

    double fromPrice = 0.0;

    if (_selectedFromType == 'currency') {
      final selectedCurrency = _currencies.firstWhere(
        (currency) => currency['id'] == _selectedFromId,
        orElse: () => {'price': 0.0},
      );
      fromPrice = selectedCurrency['price'];
    } else if (_selectedFromType == 'coin') {
      final selectedCoin = _coins.firstWhere(
        (coin) => coin['id'] == _selectedFromId,
        orElse: () => {'price': 0.0},
      );
      final usdCurrency = _currencies.firstWhere(
        (currency) => currency['id'] == "USD-NGN",
        orElse: () => {'price': 0.0},
      );
      fromPrice = selectedCoin['price'] * usdCurrency['price'];
    }

    setState(() {
      _toAmount = _fromAmount * fromPrice;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Swap to NGN', style: TextStyle(fontSize: 18)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('From',
                        style: TextStyle(fontSize: 14, color: Colors.grey)),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButton<String>(
                            value: _selectedFromType,
                            hint: Text('Select Type'),
                            onChanged: (String? value) {
                              setState(() {
                                _selectedFromType = value;
                                _selectedFromId = null;
                              });
                              _calculateSwap();
                            },
                            items: [
                              DropdownMenuItem(
                                value: 'currency',
                                child: Text('Currency'),
                              ),
                              DropdownMenuItem(
                                value: 'coin',
                                child: Text('Coin'),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: DropdownButton<String>(
                            value: _selectedFromId,
                            hint: Text('Select Asset'),
                            onChanged: (String? value) {
                              setState(() {
                                _selectedFromId = value;
                              });
                              _calculateSwap();
                            },
                            items: _selectedFromType == 'currency'
                                ? _currencies
                                    .map<DropdownMenuItem<String>>((currency) {
                                    return DropdownMenuItem<String>(
                                      value: currency['id'].toString(),
                                      child: Text('${currency['name']}'),
                                    );
                                  }).toList()
                                : _selectedFromType == 'coin'
                                    ? _coins
                                        .map<DropdownMenuItem<String>>((coin) {
                                        return DropdownMenuItem<String>(
                                          value: coin['id'].toString(),
                                          child: Text('${coin['name']}'),
                                        );
                                      }).toList()
                                    : [],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Amount',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        setState(() {
                          _fromAmount = double.tryParse(value) ?? 0.0;
                        });
                        _calculateSwap();
                      },
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('To',
                        style: TextStyle(fontSize: 14, color: Colors.grey)),
                    SizedBox(height: 8),
                    Text('NGN', style: TextStyle(fontSize: 16)),
                    SizedBox(height: 16),
                    Text(
                      'Amount: ₦${_toAmount.toStringAsFixed(2).replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), ',')}',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
