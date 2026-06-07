import 'dart:js_interop';

@JS('isPwaStandalone')
external JSFunction? get _isPwaStandaloneRef;

@JS('isPwaInstalled')
external JSFunction? get _isPwaInstalledRef;

@JS('isPwaInstallAvailable')
external JSFunction? get _isPwaInstallAvailableRef;

@JS('getPwaInstallReason')
external JSFunction? get _getPwaInstallReasonRef;

@JS('triggerPwaInstallPromptSync')
external JSFunction? get _triggerPwaInstallPromptSyncRef;

@JS('getPwaInstallOutcome')
external JSFunction? get _getPwaInstallOutcomeRef;

bool isStandalone() => _callGlobalBool(_isPwaStandaloneRef);

bool isInstalled() => _callGlobalBool(_isPwaInstalledRef);

bool isInstallAvailable() => _callGlobalBool(_isPwaInstallAvailableRef);

String installReason() {
  try {
    final JSFunction? fn = _getPwaInstallReasonRef;
    if (fn == null) return 'unavailable';
    return _coerceString(fn.callAsFunction()) ?? 'unavailable';
  } catch (_) {
    return 'unavailable';
  }
}

/// Calls [prompt()] synchronously — must run directly inside the click handler.
bool triggerInstallPromptSync() =>
    _callGlobalBool(_triggerPwaInstallPromptSyncRef);

Future<String> getInstallOutcome() async {
  try {
    final JSFunction? fn = _getPwaInstallOutcomeRef;
    if (fn == null) return 'unavailable';
    final JSAny? raw = fn.callAsFunction();
    if (raw == null) return 'unavailable';
    if (raw is JSPromise<JSAny?>) {
      final JSAny? result = await raw.toDart;
      return _coerceString(result) ?? 'unavailable';
    }
    return _coerceString(raw) ?? 'unavailable';
  } catch (_) {
    return 'unavailable';
  }
}

Future<bool> triggerInstall() async {
  if (!triggerInstallPromptSync()) return false;
  final String outcome = await getInstallOutcome();
  return outcome == 'accepted';
}

bool _callGlobalBool(JSFunction? fn) {
  try {
    if (fn == null) return false;
    return _coerceBool(fn.callAsFunction());
  } catch (_) {
    return false;
  }
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

String? _coerceString(JSAny? value) {
  if (value == null) return null;
  if (value is JSString) return value.toDart;
  return null;
}
