import 'dart:js_interop';

@JS('isPwaInstallAvailable')
external JSAny? _isPwaInstallAvailable();

@JS('triggerPwaInstall')
external JSPromise<JSAny?> _triggerPwaInstall();

bool isInstallAvailable() => _coerceBool(_isPwaInstallAvailable());

Future<bool> triggerInstall() async {
  final JSAny? result = await _triggerPwaInstall().toDart;
  return _coerceBool(result, acceptAcceptedString: true);
}

bool _coerceBool(JSAny? value, {bool acceptAcceptedString = false}) {
  if (value == null) return false;
  if (value is JSBoolean) return value.toDart;
  if (acceptAcceptedString && value is JSString) {
    final String normalized = value.toDart.toLowerCase();
    return normalized == 'accepted' || normalized == 'true';
  }
  return false;
}
