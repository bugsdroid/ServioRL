import 'package:flutter/material.dart';

class TvScreen extends StatelessWidget {
  const TvScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('TV Series')),
        body: const Center(child: Text('TV Series — coming soon')),
      );
}
