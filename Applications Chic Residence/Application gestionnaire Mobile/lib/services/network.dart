import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

/// Coupure et retour du réseau, sur le modèle de Prepaxia :
///
/// - une **lecture** (GET) qui échoue faute de réseau est retentée toutes les
///   3 s pendant 2 minutes, et aussitôt que la connexion revient ;
/// - un **enregistrement** n'est jamais rejoué tout seul : il a pu arriver au
///   serveur, et le rejouer créerait un doublon (réservation, paiement) ;
/// - un bandeau signale la coupure, et les écrans se rechargent au retour.
class NetworkStatus {
  NetworkStatus._();

  static final online = ValueNotifier<bool>(true);
  static final _reconnect = StreamController<void>.broadcast();
  static StreamSubscription<List<ConnectivityResult>>? _sub;

  /// Émet à chaque retour de la connexion.
  static Stream<void> get onReconnect => _reconnect.stream;

  static Future<void> start() async {
    if (_sub != null) return;
    try {
      online.value = _isOnline(await Connectivity().checkConnectivity());
      _sub = Connectivity().onConnectivityChanged.listen((r) {
        final now = _isOnline(r);
        if (now && !online.value) _reconnect.add(null);
        online.value = now;
      });
    } catch (_) {
      // Surveillance indisponible : les requêtes échoueront simplement.
    }
  }

  static bool _isOnline(List<ConnectivityResult> r) =>
      r.any((x) => x != ConnectivityResult.none);
}

bool _isNetworkFailure(DioException e) {
  if (e.response != null) return false;
  switch (e.type) {
    case DioExceptionType.connectionError:
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.receiveTimeout:
      return true;
    case DioExceptionType.unknown:
      final t = '${e.error}';
      return t.contains('SocketException') ||
          t.contains('Failed host lookup') ||
          t.contains('Network is unreachable') ||
          t.contains('Connection refused');
    default:
      return false;
  }
}

/// Intercepteur à poser **en premier** sur le client Dio.
class RetryOnNetwork extends Interceptor {
  RetryOnNetwork(this._dio);
  final Dio _dio;

  static const _flag = '_retry_network';
  static const _window = Duration(minutes: 2);

  @override
  Future<void> onError(
      DioException err, ErrorInterceptorHandler handler) async {
    final o = err.requestOptions;
    if (o.method.toUpperCase() != 'GET' ||
        o.extra[_flag] == true ||
        !_isNetworkFailure(err)) {
      return handler.next(err);
    }
    final started = DateTime.now();
    var last = err;
    while (DateTime.now().difference(started) < _window) {
      await _wait(const Duration(seconds: 3));
      try {
        final r = await _dio.fetch<dynamic>(
            o.copyWith(extra: {...o.extra, _flag: true}));
        return handler.resolve(r);
      } on DioException catch (e) {
        if (!_isNetworkFailure(e)) return handler.next(e);
        last = e;
      }
    }
    handler.next(last);
  }

  /// Attend `d`, ou moins si la connexion revient.
  static Future<void> _wait(Duration d) {
    final c = Completer<void>();
    final timer = Timer(d, () {
      if (!c.isCompleted) c.complete();
    });
    final sub = NetworkStatus.onReconnect.listen((_) {
      if (!c.isCompleted) c.complete();
    });
    return c.future.whenComplete(() {
      timer.cancel();
      sub.cancel();
    });
  }
}

/// Bandeau « Hors connexion » posé au-dessus de toute l'application.
class NetworkBanner extends StatelessWidget {
  const NetworkBanner({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: NetworkStatus.online,
      builder: (context, online, _) => Column(
        children: [
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            child: online
                ? const SizedBox(width: double.infinity)
                : Material(
                    color: const Color(0xFF12294B),
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Row(
                          children: const [
                            Icon(Icons.wifi_off_rounded,
                                color: Colors.white, size: 18),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Hors connexion. Reprise automatique dès le retour du réseau.',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 12.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
          Expanded(
            child: MediaQuery.removePadding(
              context: context,
              removeTop: !online,
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}
