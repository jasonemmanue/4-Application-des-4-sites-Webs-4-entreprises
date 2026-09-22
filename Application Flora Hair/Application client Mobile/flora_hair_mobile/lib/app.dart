import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/routes.dart';
import 'config/theme.dart';

class FloraHairApp extends ConsumerWidget {
  const FloraHairApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Flora Hair',
      debugShowCheckedModeBanner: false,
      theme: FloraTheme.light,
      darkTheme: FloraTheme.dark,
      themeMode: ThemeMode.light,
      routerConfig: router,
    );
  }
}
