import 'package:flutter/material.dart';
import 'package:rate2ng/crypto.dart';
import 'package:rate2ng/currencies.dart';
import 'package:rate2ng/vpn.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _borderColor;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _borderColor =
        ColorTween(begin: Colors.blue, end: Colors.red).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Rate2NG',
            style: TextStyle(
              color: Color(0xFF009605),
              fontWeight: FontWeight.w700,
            ),
          ),
          actions: [
            InkWell(
              onTap: () {
                launch('https://t.me/rate2ng');
              },
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Container(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: _borderColor.value ?? Colors.blue, width: 4),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      'Join Channel',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  );
                },
              ),
            ),
            SizedBox(width: 20),
          ],
          bottom: TabBar(
            tabs: [
              Tab(text: 'Crypto'),
              Tab(text: 'Currencies'),
              Tab(text: 'News'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            CryptoPage(),
            CurrencyPage(),
            Center(child: Text('Others Page')),
          ],
        ),
      ),
    );
  }

  void launch(String url) {
    print('Opening URL: $url');
  }
}
