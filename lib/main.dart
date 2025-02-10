import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
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
      length: 4,
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
                // Open the link
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
              Tab(text: 'Gift Cards'),
              Tab(text: 'Others'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            Center(child: Text('Crypto Page')),
            Center(child: Text('Currencies Page')),
            Center(child: Text('Gift Cards Page')),
            Center(child: Text('Others Page')),
          ],
        ),
      ),
    );
  }

  void launch(String url) {
    // This is just a placeholder, use the 'url_launcher' package in a real app
    print('Opening URL: $url');
  }
}
