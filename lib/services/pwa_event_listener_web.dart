// ignore_for_file: deprecated_member_use

import 'dart:html' as html;

const List<String> _pwaEvents = <String>[
  'pwa-installable',
  'pwa-manifest-ready',
  'pwa-check-availability',
  'pwa-installed',
  'pwa-install-result',
];

void Function(html.Event)? _handler;

void listenForPwaEvents(void Function() onUpdate) {
  removePwaEventListeners(onUpdate);
  _handler = (_) => onUpdate();
  for (final String name in _pwaEvents) {
    html.window.addEventListener(name, _handler!);
  }
}

void removePwaEventListeners(void Function() onUpdate) {
  if (_handler == null) return;
  for (final String name in _pwaEvents) {
    html.window.removeEventListener(name, _handler!);
  }
  _handler = null;
}
