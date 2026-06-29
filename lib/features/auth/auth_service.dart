import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Auth con magic link (passwordless email).
/// El link de Firebase redirige a [continueUrl] y la app lo captura
/// via deep link (ver app_links en main.dart) para completar el sign-in.
///
/// Si [auth] es null (Firebase todavía no está configurado con
/// `flutterfire configure`), el servicio entra en modo demo: no manda
/// emails reales ni autentica, solo simula los tiempos de espera para
/// poder navegar el onboarding sin backend.
class AuthService {
  AuthService(this.auth);

  final FirebaseAuth? auth;

  // `flutter run -d chrome --web-port=5000` sirve la app en este origen;
  // Firebase Auth autoriza `localhost` por defecto, así que el magic link
  // abre la misma pestaña y la app lo captura al recargar (ver main.dart).
  // En producción esto debe ser el dominio real de la app (ej. Firebase
  // Hosting), agregado en Authentication > Settings > Authorized domains.
  static const _continueUrl = 'http://localhost:5000';
  static const _androidPackageName = 'com.hitoapp.hito';
  static const _iosBundleId = 'com.hitoapp.hito';
  static const _pendingEmailKey = 'hito_pending_magic_link_email';

  bool get isDemoMode => auth == null;

  Stream<User?> get authStateChanges =>
      auth?.authStateChanges() ?? const Stream<User?>.empty();
  User? get currentUser => auth?.currentUser;

  Future<void> sendMagicLink(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pendingEmailKey, email);

    final auth = this.auth;
    if (auth == null) return; // modo demo: no hay email real que enviar

    final actionCodeSettings = ActionCodeSettings(
      url: _continueUrl,
      handleCodeInApp: true,
      androidPackageName: _androidPackageName,
      androidInstallApp: true,
      iOSBundleId: _iosBundleId,
    );
    await auth.sendSignInLinkToEmail(
      email: email,
      actionCodeSettings: actionCodeSettings,
    );
  }

  bool isSignInLink(String link) => auth?.isSignInWithEmailLink(link) ?? false;

  Future<String?> consumePendingEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_pendingEmailKey);
    await prefs.remove(_pendingEmailKey);
    return email;
  }

  Future<UserCredential?> signInWithMagicLink({
    required String email,
    required String link,
  }) {
    final auth = this.auth;
    if (auth == null) return Future.value(null);
    return auth.signInWithEmailLink(email: email, emailLink: link);
  }

  Future<void> signOut() async => auth?.signOut();

  /// Garantiza que haya un usuario de Firebase Auth (anónimo si no hay
  /// sesión real todavía) para que Firestore tenga un uid dueño de los
  /// datos. Independiente del flujo de magic link — no requiere email.
  Future<String?> ensureSignedIn() async {
    final auth = this.auth;
    if (auth == null) return null; // modo demo: sin Firebase, sin Firestore
    if (auth.currentUser != null) return auth.currentUser!.uid;
    final credential = await auth.signInAnonymously();
    return credential.user?.uid;
  }
}
