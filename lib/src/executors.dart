// Copyright (c) 2019 Yrom Wang. Use of this source code is governed by a
// MIT license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:isolate';

import 'package:executor/executor.dart';

/// The default instance
final CachedExecutor cachedExecutor = CachedExecutor(const Duration(minutes: 2));

/// The cached executor.
class CachedExecutor implements Executor {
  final Duration idleTimeOut;

  /// Specify [idleTimeOut] for auto shutting down underlying [Isolate] when it become idle, default is 60s
  CachedExecutor([this.idleTimeOut = const Duration(seconds: 60)]);

  Future<Executor> get executor async {
    if (_executor != null) return _executor;
    _executor = Executor.spawn(debugName: 'CachedExecutor');
    return _executor;
  }

  /// Run [computation] on cached executor.
  ///
  /// Call [run] will [spawn] an new [Executor] if this executor has been [close]d or not initialized yet.
  @override
  Future<R> run<Q, R>(FutureOr<R> computation(Q argument), Q argument) async {
    _cancelShutdown();
    var exec = await executor;
    R result = await exec.run(computation, argument);
    _scheduleShutdown(exec);
    return result;
  }

  @override
  Future<void> close() async {
    _cancelShutdown();
    var executor = _executor;
    if (executor != null) {
      _executor = null;
      return executor.then((exec) => exec.close());
    }
  }

  Timer _autoShutdown;
  Future<Executor> _executor;

  void _cancelShutdown() {
    if (_autoShutdown != null && _autoShutdown.isActive) {
      _autoShutdown.cancel();
    }
  }

  void _scheduleShutdown(Executor exec) {
    _cancelShutdown();
    this._autoShutdown = Timer(idleTimeOut, () {
      this._executor = null;
      exec.close().whenComplete(() => print('$exec auto closed'));
    });
  }
}
