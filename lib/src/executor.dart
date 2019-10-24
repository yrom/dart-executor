// Copyright (c) 2019 Yrom Wang. Use of this source code is governed by a
// MIT license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:isolate';

import 'handler.dart';
import 'util.dart';

/// Executor like java single thread pool.
/// Should call [close] when everything are done.
///
abstract class Executor {

  /// Execute `computation(argument)` in the [isolate] and return the result.
  ///
  /// Example:
  /// ```
  /// Executor exe = await Executor.spawn();
  /// try {
  ///   return await exe.run(heavyComputation, argument);
  /// } finally {
  ///   await exe.close();
  /// }
  /// ```
  ///
  /// Note: the [computation] should be a top level function or static function
  Future<R> run<Q, R>(FutureOr<R> computation(Q argument), Q argument);

  /// Close this executor.
  ///
  /// Should not call [run] after this method called, in general.
  Future<void> close();

  /// Create a new [Executor]
  static Future<Executor> spawn({String debugName = 'Executor'}) async {
    // for receiving command port of remote isolate
    final resultPort = ReceivePort();

    final isolate = await Isolate.spawn(IsolateExecutorRemote._create, resultPort.sendPort,
      // The Executor can be used to run multiple independent functions.
      // Should not be terminated when uncaught error occurred.
      errorsAreFatal: false,
      debugName: debugName);

    final forPing = ReceivePort();
    isolate.ping(forPing.sendPort, response: 'P', priority: Isolate.immediate);
    // The first message is the port of remote isolate.
    final commandPort = await resultPort.first;

    var p = await forPing.first;
    assert(p == 'P');

    // clean up the ports.
    resultPort.close();
    forPing.close();

    return IsolateExecutor(isolate, commandPort, debugName: debugName);
  }
}


// commands for _Remote
const _shutdown = 1;
const _run = 2;

/// Execute heavy computation on another [isolate].
class IsolateExecutor implements Executor {
  final Isolate isolate;

  final String debugName;
  /// Command port for the [IsolateExecutorRemote].
  final SendPort _commandPort;

  IsolateExecutor(this.isolate, SendPort commandPort, {this.debugName}) : this._commandPort = commandPort;

  /// Close and kill the underlying [isolate]
  Future<void> close() async {
    final resultPort = ReceivePort();
    _commandPort.send(list2(_shutdown, resultPort.sendPort));
    try {
      await resultPort.first.timeout(const Duration(milliseconds: 10));
    } on TimeoutException catch (_) {
    }
  }


  /// Execute `computation(argument)` in the [isolate] and return the result.
  ///
  /// Example:
  /// ```
  /// Executor exe = await Executor.spawn();
  /// try {
  ///   return await exe.run(heavyComputation, argument);
  /// } finally {
  ///   await exe.close();
  /// }
  /// ```
  Future<R> run<Q, R>(FutureOr<R> computation(Q argument), Q argument) async {
    final resultPort = ReceivePort();
    _commandPort.send(list4(_run, computation, argument, resultPort.sendPort));
    final response = await resultPort.first as List;
    resultPort.close();
    return receiveFutureResult(response);
  }

  @override
  String toString() {
    return '$debugName-${isolate.hashCode}';
  }
}

/// Wrap a [SendPort] for handling command in independent [Isolate]
class IsolateExecutorRemote {
  final RawReceivePort _commandPort = RawReceivePort();

  IsolateExecutorRemote() {
    _commandPort.handler = _handleCommand;
  }

  SendPort get port => _commandPort.sendPort;

  /// Should be called by [Isolate.spawn]
  ///
  /// note that, the param [data] should be a [SendPort]
  static void _create(dynamic data) {
    SendPort initPort = data;
    // this object is living in the new isolate
    final remote = IsolateExecutorRemote();
    // response the command port
    initPort.send(remote.port);
  }

  void _handleCommand(List<dynamic> args) {
    switch (args[0]) {
      case _shutdown:
        _commandPort.close();
        (args[1] as SendPort)?.send(null);
        break;
      case _run:
        var function = args[1] as Function;
        var argument = args[2];
        var responsePort = args[3] as SendPort;

        sendFutureResult(Future.sync(() => function(argument)), responsePort);
        break;
      default:
        throw UnsupportedError("unsupported command ${args[0]}");
        break;
    }
  }
}
