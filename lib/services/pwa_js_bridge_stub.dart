bool isInstallAvailable() => false;

String installReason() => 'unavailable';

bool isStandalone() => false;

bool isInstalled() => false;

bool triggerInstallPromptSync() => false;

Future<String> getInstallOutcome() async => 'unavailable';

Future<bool> triggerInstall() async => false;
