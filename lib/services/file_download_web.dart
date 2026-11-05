// Web platform implementation for real in-browser downloads and printing
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:convert';

void downloadFile(
  String filename,
  String content, {
  String mimeType = 'text/plain;charset=utf-8',
}) {
  final bytes = utf8.encode(content);
  final blob = html.Blob([bytes], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..click();
  html.Url.revokeObjectUrl(url);
}

void triggerBrowserPrint() {
  html.window.print();
}

