// Web: real in-browser downloads and printing (package:web, no dart:html).
import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

void downloadFile(
  String filename,
  String content, {
  String mimeType = 'text/plain;charset=utf-8',
}) {
  final bytes = utf8.encode(content);
  final blob = web.Blob([bytes.toJS].toJS, web.BlobPropertyBag(type: mimeType));
  final url = web.URL.createObjectURL(blob);
  web.HTMLAnchorElement()
    ..href = url
    ..download = filename
    ..click();
  web.URL.revokeObjectURL(url);
}

void triggerBrowserPrint() {
  web.window.print();
}

/// Ikkilik fayl (masalan .xlsx) yuklab olish.
void downloadBytes(String filename, List<int> bytes, {required String mimeType}) {
  final data = Uint8List.fromList(bytes);
  final blob = web.Blob([data.toJS].toJS, web.BlobPropertyBag(type: mimeType));
  final url = web.URL.createObjectURL(blob);
  web.HTMLAnchorElement()
    ..href = url
    ..download = filename
    ..click();
  web.URL.revokeObjectURL(url);
}
