import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class VPNsPage extends StatefulWidget {
  const VPNsPage({super.key});

  @override
  State<VPNsPage> createState() => _VPNsPageState();
}

class _VPNsPageState extends State<VPNsPage> {
  List<dynamic> vpnsJson = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchVPNs();
  }

  Future<void> _fetchVPNs() async {
    final prefs = await SharedPreferences.getInstance();
    final lastFetchDate = prefs.getString('lastFetchDate');
    final today = DateTime.now().toIso8601String().split('T')[0];

    if (lastFetchDate == today) {
      final savedData = prefs.getString('vpnsJson');
      if (savedData != null) {
        setState(() {
          vpnsJson = json.decode(savedData);
          isLoading = false;
        });
        return;
      }
    }

    try {
      final response = await http.get(Uri.parse(
          'https://raw.githubusercontent.com/devfemibadmus/rate2ng-api/refs/heads/main/assets/vpns/list.json'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await prefs.setString('vpnsJson', json.encode(data));
        await prefs.setString('lastFetchDate', today);
        setState(() {
          vpnsJson = data;
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('VPN List'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: vpnsJson.length,
              itemBuilder: (context, index) {
                final vpn = vpnsJson[index];
                return Card(
                  margin: EdgeInsets.all(8.0),
                  child: ListTile(
                    title: Text(vpn['name'] as String),
                    trailing: Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => VPNDetailPage(vpn: vpn),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}

class VPNDetailPage extends StatelessWidget {
  final Map<String, dynamic> vpn;

  const VPNDetailPage({super.key, required this.vpn});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(vpn['name'] as String),
      ),
      body: ListView.builder(
        itemCount: (vpn['plans'] as List).length,
        itemBuilder: (context, index) {
          final plan = vpn['plans'][index];
          return Card(
            margin: EdgeInsets.all(8.0),
            child: ListTile(
              title: Text(plan['name'] as String),
              subtitle: Text(
                  '\$${(plan['price'] as double).toStringAsFixed(2)}/month'),
            ),
          );
        },
      ),
    );
  }
}
