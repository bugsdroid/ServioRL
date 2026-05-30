import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Helper navigasi global — pakai ini daripada Navigator.of(context)
/// agar konsisten dengan GoRouter
class AppNav {
  static void toSettings(BuildContext context) => context.push('/settings');
  static void toMovies(BuildContext context) => context.push('/movies');
  static void toTv(BuildContext context) => context.push('/tv');
  static void toSubtitles(BuildContext context) => context.push('/subtitles');
  static void back(BuildContext context) => context.pop();
}
