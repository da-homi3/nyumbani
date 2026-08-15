sealed class AppFailure implements Exception {
  const AppFailure(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => message;
}

class NetworkFailure extends AppFailure {
  const NetworkFailure([
    super.message = 'No internet connection. Check your connection and try again.',
  ]);
}

class UnauthorizedFailure extends AppFailure {
  // ignore: use_super_parameters
  const UnauthorizedFailure([
    String message = 'Please sign in to continue.',
  ]) : super(message, code: 'UNAUTHORIZED');
}

class ServerFailure extends AppFailure {
  const ServerFailure(super.message, {super.code});
}

class UnexpectedFailure extends AppFailure {
  const UnexpectedFailure([
    super.message = 'Something went wrong. Please try again.',
  ]);
}
