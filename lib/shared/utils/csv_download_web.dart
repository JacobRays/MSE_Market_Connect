// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

Future<bool> downloadCsv(String filename, String csvContent) async {
  final bytes = html.Blob([csvContent], 'text/csv;charset=utf-8;');
  final url = html.Url.createObjectUrlFromBlob(bytes);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..click();
  html.Url.revokeObjectUrl(url);
  return true;
}
