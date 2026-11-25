import '../models/cifra.dart';
import '../services/parser_service.dart';
import 'base_vm.dart';

/// ViewModel do fluxo de importação por link/HTML.
class DownloadVM extends BaseVM {
  DownloadVM(this._parser);

  final ParserService _parser;

  bool carregando = false;
  String? erro;
  Cifra? cifra;
  String? ultimaUrl;

  Future<bool> importarUrl(String url) async {
    if (carregando) return false;
    carregando = true;
    erro = null;
    cifra = null;
    ultimaUrl = url.trim();
    notificar();

    try {
      final resultado = await _parser.fetchFromSite(url);
      if (resultado == null) {
        erro = 'Nenhuma cifra encontrada nessa página.';
        return false;
      }
      cifra = resultado;
      return true;
    } on ImportacaoException catch (falha) {
      erro = falha.mensagem;
      return false;
    } catch (falha) {
      erro = 'Não foi possível importar: $falha';
      return false;
    } finally {
      carregando = false;
      notificar();
    }
  }

  Future<bool> importarHtml(String html, {String? url}) async {
    if (carregando) return false;
    carregando = true;
    erro = null;
    cifra = null;
    ultimaUrl = url;
    notificar();

    try {
      final resultado = await _parser.parseHtmlToCifra(
        html,
        url?.trim().isNotEmpty == true ? url!.trim() : 'https://manual.local',
      );
      if (resultado == null) {
        erro = 'O HTML não contém uma cifra reconhecível.';
        return false;
      }
      cifra = resultado;
      return true;
    } catch (falha) {
      erro = 'Não foi possível processar o HTML: $falha';
      return false;
    } finally {
      carregando = false;
      notificar();
    }
  }

  void limpar() {
    erro = null;
    cifra = null;
    ultimaUrl = null;
    carregando = false;
    notificar();
  }
}
