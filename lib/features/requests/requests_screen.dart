import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class RequestsScreen extends StatelessWidget {
  const RequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Requests'),
      ),
      body: const Center(
        child: Text('Requests — coming soon',
            style: TextStyle(color: AppColors.textSecondary)),
      ),
    );
  }
}
