import 'dart:convert';
import 'dart:typed_data';
import 'package:executor/executor.dart';
import 'package:http/http.dart' as http;

main(List<String> arguments) async {
  var url = 'https://jsonplaceholder.typicode.com/todos';

  var response = await http.get(url);
  if (response.statusCode == 200) {
    var jsonResponse = await decodeJson(response.bodyBytes);
    var itemCount = jsonResponse.length;
    print('Number of todos: $itemCount.');
  } else {
    print('Request failed with status: ${response.statusCode}.');
  }

  // shutdown executor when program exit
  await cachedExecutor.close();
}
int _max_bytes = 10 * 1024;

/// decoding fat-json
dynamic decodeJson(Uint8List bytes) async {
  if (bytes == null) return null;
  if (bytes.lengthInBytes <= _max_bytes) {
    return _decodeJsonBytes(bytes);
  }
  print("Decoding large json bytes in ${cachedExecutor.runtimeType}, bytes: ${bytes.lengthInBytes}");
  // decode large bytes in different isolate.
  return await cachedExecutor.run(_decodeJsonBytes, bytes);
}

dynamic _decodeJsonBytes(Uint8List bytes) {
  var str = utf8.decoder.convert(bytes);
  return json.decode(str);
}