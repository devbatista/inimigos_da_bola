import '../api/api_exception.dart';
import '../api/clients/auth_api_client.dart';
import 'auth_tokens.dart';
import 'token_storage.dart';

class AuthRepository {
  const AuthRepository({
    required AuthApiClient authApiClient,
    required TokenStorage tokenStorage,
    this.enableBackendAuth = false,
  }) : _authApiClient = authApiClient,
       _tokenStorage = tokenStorage;

  static const devEmail = 'admin@inimigosdabola.dev';
  static const devPassword = 'inimigos123';

  final AuthApiClient _authApiClient;
  final TokenStorage _tokenStorage;
  final bool enableBackendAuth;

  Future<bool> hasStoredSession() async {
    final tokens = await _tokenStorage.read();
    return tokens != null;
  }

  Future<void> signIn({required String email, required String password}) async {
    final tokens = enableBackendAuth
        ? await _signInWithBackend(email: email, password: password)
        : _signInWithDevCredential(email: email, password: password);

    await _tokenStorage.save(tokens);
  }

  Future<void> signOut() async {
    try {
      await _authApiClient.signOut();
    } finally {
      await _tokenStorage.clear();
    }
  }

  bool _isDevCredential({required String email, required String password}) {
    return email.trim().toLowerCase() == devEmail && password == devPassword;
  }

  AuthTokens _signInWithDevCredential({
    required String email,
    required String password,
  }) {
    if (_isDevCredential(email: email, password: password)) {
      return const AuthTokens(
        accessToken: 'dev-access-token',
        refreshToken: 'dev-refresh-token',
      );
    }

    throw const ApiException(
      code: 'invalid_credentials',
      message: 'Email ou senha inválidos.',
      statusCode: 401,
    );
  }

  Future<AuthTokens> _signInWithBackend({
    required String email,
    required String password,
  }) async {
    return _authApiClient.signIn(email: email, password: password);
  }
}

class InMemoryTokenStorage implements TokenStorage {
  InMemoryTokenStorage([this._tokens]);

  AuthTokens? _tokens;
  String? _currentUserId;

  @override
  Future<AuthTokens?> read() async => _tokens;

  @override
  Future<void> save(AuthTokens tokens) async {
    _tokens = tokens;
  }

  @override
  Future<void> clear() async {
    _tokens = null;
    _currentUserId = null;
  }

  @override
  Future<String?> readCurrentUserId() async => _currentUserId;

  @override
  Future<void> saveCurrentUserId(String userId) async {
    _currentUserId = userId;
  }
}
