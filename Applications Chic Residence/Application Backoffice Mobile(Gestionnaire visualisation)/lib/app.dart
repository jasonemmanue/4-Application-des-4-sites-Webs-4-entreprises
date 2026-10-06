import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/routes.dart';
import 'config/theme.dart';

class BackofficeApp extends ConsumerStatefulWidget {
  const BackofficeApp({super.key});

  @override
  ConsumerState<BackofficeApp> createState() => _BackofficeAppState();
}

class _BackofficeAppState extends ConsumerState<BackofficeApp> {
  late final _router = buildRouter(ref);

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Chic Residence Backoffice',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: _router,
    );
  }
}
