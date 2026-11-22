import 'dart:async';

import 'package:flutter/foundation.dart';

void detachFirestoreWrite<T>(Future<T> write, {required String operation}) {
  unawaited(
    write.then<void>(
      (_) {},
      onError: (Object error, StackTrace stackTrace) {
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: error,
            stack: stackTrace,
            library: 'Firestore write',
            context: ErrorDescription(operation),
          ),
        );
      },
    ),
  );
}
