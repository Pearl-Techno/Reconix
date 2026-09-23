import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

void downloadFileWeb(String content, String fileName) {
  final bytes = utf8.encode(content);
  // ignore: deprecated_member_use
  final blob = html.Blob([bytes], 'text/csv;charset=utf-8');
  // ignore: deprecated_member_use
  final url = html.Url.createObjectUrlFromBlob(blob);
  // ignore: deprecated_member_use
  final anchor = html.document.createElement('a') as html.AnchorElement
    ..href = url
    ..style.display = 'none'
    ..download = fileName;
  // ignore: deprecated_member_use
  html.document.body?.children.add(anchor);
  anchor.click();
  // ignore: deprecated_member_use
  html.document.body?.children.remove(anchor);
  // ignore: deprecated_member_use
  html.Url.revokeObjectUrl(url);
}

void openExternalUrl(String url) {
  // ignore: deprecated_member_use
  html.window.open(url, '_blank');
}
