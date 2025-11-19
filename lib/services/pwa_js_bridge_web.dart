import 'dart:js_interop';

@JS('isPwaInstallAvailable')
external JSAny? _isPwaInstallAvailable();

@JS('triggerPwaInstall')
external JSAny? _triggerPwaInstall();

bool isInstallAvailable() => _coerceBool(_isPwaInstallAvailable());

Future<bool> triggerInstall() async =>
    _coerceBool(_triggerPwaInstall(), acceptAcceptedString: true);

bool _coerceBool(JSAny? value, {bool acceptAcceptedString = false}) {
  if (value == null) return false;
  if (value is JSBoolean) return value.toDart;
  if (acceptAcceptedString && value is JSString) {
    final normalized = value.toDart.toLowerCase();
    return normalized == 'accepted' || normalized == 'true';
  }
  return false;
}
