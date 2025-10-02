import 'package:flutter/material.dart';
import 'package:nostr_rust/src/rust/api/nostr.dart';
import 'package:nostr_rust/src/rust/frb_generated.dart';

Future<void> main() async {
  await RustLib.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Nostr Rust Plugin')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Nostr Rust Plugin loaded'),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  try {
                    final keys = generateKeys();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Keys generated successfully: ${keys.publicKey.substring(0, 16)}...')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to generate keys: $e')),
                    );
                  }
                },
                child: Text('Test Generate Keys'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
