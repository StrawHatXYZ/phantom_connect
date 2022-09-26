import 'package:flutter/material.dart';
import 'package:phantom_connect/phantom_connect.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  MyApp({super.key});

  // Initialize the PhantomConnect object
  final PhantomConnect phantomConnect = PhantomConnect(
    appUrl: "https://solana.com",
    deepLink: "samepl://exampledeeplink.io",
  );

  void connect() {
    Uri connectUrl = phantomConnect.generateConnectUri(cluster: 'devnet');
    // Open the url using url_launcher
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SafeArea(
        child: Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => connect(),
              child: const Text("Connect"),
            ),
          ),
        ),
      ),
    );
  }
}
