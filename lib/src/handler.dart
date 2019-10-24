// Copyright (c) 2019 Yrom Wang. Use of this source code is governed by a
// MIT license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:isolate';

import 'util.dart';

void sendFutureResult(Future<dynamic> future, SendPort resultPort) {
  future.then((value) {
    resultPort.send(list1(value));
  }, onError: (error, stack) {
    resultPort.send(list2("$error", "$stack"));
  });
}

Future<R> receiveFutureResult<R>(List<dynamic> response) {
  if (response.length == 2) {
    final error = RemoteError(response[0], response[1]);
    return Future.error(error, error.stackTrace);
  }
  R result = response[0];
  return Future<R>.value(result);
}

