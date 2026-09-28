import 'dart:convert';
import 'dart:typed_data';
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

String? downloadFileWeb(dynamic content, String fileName) {
  final List<int> bytes = content is String
      ? utf8.encode(content)
      : (content is Uint8List ? content : List<int>.from(content as List));
  final mimeType = fileName.endsWith('.xlsx')
      ? 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
      : (fileName.endsWith('.pdf') ? 'application/pdf' : 'text/csv;charset=utf-8');
  // ignore: deprecated_member_use
  final blob = html.Blob([bytes], mimeType);
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
  return null;
}

void openExternalUrl(String url) {
  // ignore: deprecated_member_use
  html.window.open(url, '_blank');
}
