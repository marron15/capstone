import 'package:web/web.dart' as web;

void setInputAttributes(String selector, Map<String, String> attributes) {
  final nodeList = web.document.querySelectorAll(selector);
  for (var i = 0; i < nodeList.length; i++) {
    final element = nodeList.item(i);
    if (element is! web.Element) continue;
    for (final entry in attributes.entries) {
      element.setAttribute(entry.key, entry.value);
    }
  }
}
