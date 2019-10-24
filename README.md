# executor

Like the Java single thread pool based on Isolate.

## Example


``` dart
import 'package:executor/executor.dart';

```

Use the global `cachedExecutor`:

``` dart
int _max_bytes = 10 * 1024;

/// decoding fat-json
Future<dynamic> decodeJson(Uint8List bytes) async {
  if (bytes == null) return null;
  if (bytes.lengthInBytes <= _max_bytes) {
    return _decodeJsonBytes(bytes);
  }
  // decode large bytes in different isolate.
  return await cachedExecutor.run(_decodeJsonBytes, bytes);
}

dynamic _decodeJsonBytes(Uint8List bytes) {
  var str = utf8.decoder.convert(bytes);
  return json.decode(str);
}
```

Use the `Executor`:

``` dart
// spawn an new Executor instance
var exec = await Executor.spawn(debugName: 'MyExecutor');

// compute in Executor
var result = await exec.run(_decodeJsonBytes, bytes);

// close when done.
await exec.close();
```