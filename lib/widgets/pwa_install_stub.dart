/// Implementación vacía para builds no-web (el botón "Descargar app"
/// solo tiene sentido en el navegador).
Future<bool> triggerPwaInstall() async => false;

bool get isPwaInstallSupported => false;

bool get isPwaAlreadyInstalled => false;
