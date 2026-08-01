import 'dart:html' as html;
import 'dart:typed_data';

Future<void> saveImageBytes(Uint8List bytes, String name) async {
  final blob = html.Blob([bytes]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', '$name.png')
    ..click();
  html.Url.revokeObjectUrl(url);
}
