import 'dart:isolate';
import 'dart:math' as math;

import 'package:executor/executor.dart';
import 'package:test/test.dart';

void main() {
  group("executor", testExecutor);
  group("cached executor", testCachedExecutor);
}

testExecutor() {
  test("create close", () {
    return Executor.spawn().then((Executor executor) {
      return executor.close();
    });
  });

  test("create run close", () {
    return Executor.spawn().then((Executor executor) {
      return executor.run(increase, 2).then((v) {
        expect(v, 3);
        return executor.close();
      });
    });
  });

  test('create run-future close', () {
    return Executor.spawn().then((Executor executor) {
      return executor.run(f, 32).then((v) {
        expect(v, 33);
        return executor.close();
      });
    });
  });

  test('create run-error close', () {
    return Executor.spawn().then((Executor executor) {
      return executor.run(error, 'hehe');
    }).then((_) {
      fail("should not run here");
    }, onError: (e) {
      expect(e.runtimeType, RemoteError);
      print(e);
    });
  });
}

testCachedExecutor() {
  test("run", () {
    var exec = CachedExecutor(const Duration(milliseconds: 1));
    return exec.run(increase, 2).then((v) {
      expect(v, 3);
    }).whenComplete(exec.close);
  });

  test("run after auto release", () {
    var exec = CachedExecutor(const Duration(milliseconds: 1));
    return exec
        .run(f, 32)
        .then((v) => expect(v, 33))
        .then((_) => Future.delayed(exec.idleTimeOut * 2))
        .then((_) => exec.run(increase, 2).then((v) => expect(v, 3)));
  });

  test("run multiple task", () async {
    var exec = CachedExecutor(const Duration(milliseconds: 1));
    await exec.run(f, 16).then((v) => expect(v, 17));
    await exec.run(f, 4).then((v) => expect(v, 5));
    await exec
        .run(error, 4)
        .then((_) => fail("should not run here"))
        .catchError((e) => expect(e.runtimeType, RemoteError));
  });
}

increase(x) => x + 1;

Future<dynamic> f(x) => Future.sync(() {
      var a = 1;
      final b = math.pow(2, x) - 1;
      for (var i = 0; i < b; i++) {
        a += i;
      }
      print(a);
      return increase(x);
    });

error(x) => throw Exception(x.toString());
