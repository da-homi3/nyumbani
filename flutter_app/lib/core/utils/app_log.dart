import 'package:logger/logger.dart';

/// App logger that redacts bearer tokens and secrets.
class AppLog {
  AppLog._();

  static final Logger _logger = Logger(
    printer: PrettyPrinter(methodCount: 0, errorMethodCount: 4),
  );

  static String _redact(String input) {
    return input
        .replaceAll(RegExp(r'Bearer\s+[A-Za-z0-9\-._~+/]+=*', caseSensitive: false), 'Bearer ***')
        .replaceAll(RegExp(r'eyJ[A-Za-z0-9\-_]+\.[A-Za-z0-9\-_]+\.[A-Za-z0-9\-_]+'), '***jwt***');
  }

  static void d(String message) => _logger.d(_redact(message));
  static void i(String message) => _logger.i(_redact(message));
  static void w(String message) => _logger.w(_redact(message));
  static void e(String message, [Object? error, StackTrace? stack]) {
    _logger.e(_redact(message), error: error, stackTrace: stack);
  }
}
