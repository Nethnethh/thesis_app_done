import 'dart:html' as html;

void html_download(String content, String fileName) {
  final blob = html.Blob([content], 'text/csv');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..click();
  html.Url.revokeObjectUrl(url);
}