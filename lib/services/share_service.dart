import 'package:flutter/services.dart';

import '../models/cifra.dart';
import 'parser_service.dart';

/// Ponte com o Android para receber links compartilhados/abertos no app.
///
/// O canal `cifravault/intents` é implementado em `MainActivity.kt`. Em
/// plataformas sem o canal (desktop/testes), os métodos falham de forma
/// silenciosa e retornam `null`.
class ShareHandler {
  ShareHandler({required ParserService parser}) : _parser = parser;

  static const MethodChannel _canal = MethodChannel('cifravault/intents');

  final ParserService _parser;

  final Set<String> _hostsConhecidos = const {
    'cifraclub.com.br',
    'clickgratis.com.br',
    'ciframaster.com.br',
  };

  /// Retorna a URL que abriu o app (se houver).
  Future<Uri?> linkInicial() async {
    try {
      final link = await _canal.invokeMethod<String>('getInitialUrl');
      final texto = link?.trim() ?? '';
      if (texto.isEmpty) return null;
      return Uri.tryParse(texto);
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  /// Android 11+: verifica se o app tem "Acesso a todos os arquivos".
  /// Em outras plataformas retorna true.
  Future<bool> temAcessoTodosArquivos() async {
    try {
      final ok = await _canal.invokeMethod<bool>('hasAllFilesAccess');
      return ok ?? true;
    } on PlatformException {
      return true;
    } on MissingPluginException {
      return true;
    }
  }

  /// Abre a tela do sistema para conceder "Acesso a todos os arquivos".
  Future<void> solicitarAcessoTodosArquivos() async {
    try {
      await _canal.invokeMethod<void>('requestAllFilesAccess');
    } catch (_) {}
  }

  Future<void> abrirConfiguracoesApp() async {
    try {
      await _canal.invokeMethod<void>('openAppSettings');
    } catch (_) {}
  }

  /// Escuta novos links recebidos enquanto o app está aberto.
  void escutar(void Function(Uri uri) aoReceber) {
    _canal.setMethodCallHandler((chamada) async {
      if (chamada.method != 'onShare') return;
      final link = chamada.arguments as String?;
      final uri = link == null ? null : Uri.tryParse(link);
      if (uri != null) aoReceber(uri);
    });
  }

  /// Verifica se a URL pertence a um site de cifras suportado.
  bool isKnownMusicSite(Uri uri) {
    final host = uri.host.toLowerCase();
    return _hostsConhecidos.any(
      (dominio) => host == dominio || host.endsWith('.$dominio'),
    );
  }

  /// Processa um link recebido e devolve a cifra importada (sem salvar).
  Future<Cifra?> processShareUri(Uri uri) async {
    if (uri.scheme != 'http' && uri.scheme != 'https') return null;
    return _parser.fetchFromSite(uri.toString());
  }
}
