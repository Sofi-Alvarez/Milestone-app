import 'dart:js_interop';

/// Puente a las funciones JS definidas en web/index.html —
/// `beforeinstallprompt` solo se puede capturar/disparar desde JS, así
/// que Dart solo pide el resultado.
@JS('pwaInstallAvailable')
external JSBoolean _pwaInstallAvailable();

@JS('triggerPwaInstall')
external JSPromise<JSBoolean> _triggerPwaInstall();

@JS('pwaAlreadyInstalled')
external JSBoolean _pwaAlreadyInstalled();

/// true si el navegador guardó el evento `beforeinstallprompt` (Chrome/
/// Edge/Android) — ahí "Descargar app" puede abrir el diálogo nativo
/// de instalación directamente.
bool get isPwaInstallSupported {
  try {
    return _pwaInstallAvailable().toDart;
  } catch (_) {
    return false;
  }
}

/// true si ya se está corriendo como app instalada (standalone) — no
/// tiene sentido ofrecer instalarla de nuevo.
bool get isPwaAlreadyInstalled {
  try {
    return _pwaAlreadyInstalled().toDart;
  } catch (_) {
    return false;
  }
}

/// Dispara el diálogo nativo de instalación y espera la elección del
/// usuario. Devuelve `true` solo si aceptó instalar.
Future<bool> triggerPwaInstall() async {
  try {
    final accepted = await _triggerPwaInstall().toDart;
    return accepted.toDart;
  } catch (_) {
    return false;
  }
}
