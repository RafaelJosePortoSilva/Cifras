import 'dart:async';
import 'dart:convert';

import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;
import 'package:yaml/yaml.dart';

import '../models/cifra.dart';
import '../models/setlist.dart';
import '../utils/chord_utils.dart';
import '../utils/text_utils.dart';

/// Erro amigável para falhas de importação.
class ImportacaoException implements Exception {
  ImportacaoException(this.mensagem);

  final String mensagem;

  @override
  String toString() => mensagem;
}

class _DocumentoMarkdown {
  _DocumentoMarkdown(this.dados, this.corpo);

  final Map<String, dynamic> dados;
  final String corpo;
}

/// Parseia Markdown local e HTML de sites de cifras.
class ParserService {
  static const Map<String, String> _headers = {
    'User-Agent':
        'Mozilla/5.0 (Linux; Android 14; Pixel 7) AppleWebKit/537.36 '
            '(KHTML, like Gecko) Chrome/124.0 Mobile Safari/537.36',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
    'Accept-Language': 'pt-BR,pt;q=0.9,en;q=0.6',
  };

  /// Converte um arquivo `.md` em [Cifra].
  Cifra parseCifraMarkdown(String conteudo, {String? id, String? caminho}) {
    final documento = _separarFrontmatter(conteudo);
    return Cifra.fromYaml(
      documento.dados,
      documento.corpo,
      id: id ?? '',
      caminho: caminho,
    );
  }

  /// Converte um arquivo `.md` em [Setlist].
  Setlist parseSetlistMarkdown(String conteudo, {String? id, String? caminho}) {
    final documento = _separarFrontmatter(conteudo);
    return Setlist.fromYaml(
      documento.dados,
      documento.corpo,
      id: id ?? '',
      caminho: caminho,
    );
  }

  /// Baixa uma página e tenta extrair a cifra.
  Future<Cifra?> fetchFromSite(String url) async {
    final uri = Uri.tryParse(url.trim());
    if (uri == null ||
        !uri.hasScheme ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      throw ImportacaoException('Informe uma URL válida começando com http(s).');
    }

    try {
      final resposta = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 25));

      if (resposta.statusCode < 200 || resposta.statusCode >= 300) {
        throw ImportacaoException(
          'O site respondeu com status ${resposta.statusCode}.',
        );
      }

      final html = _decodificarResposta(resposta);
      final cifra = await parseHtmlToCifra(html, uri.toString());
      if (cifra == null) {
        throw ImportacaoException(
          'Não foi possível localizar a cifra nesta página. '
          'Você pode colar o HTML manualmente.',
        );
      }
      return cifra;
    } on ImportacaoException {
      rethrow;
    } on TimeoutException {
      throw ImportacaoException(
        'O download demorou demais. Verifique sua conexão e tente de novo.',
      );
    } on http.ClientException catch (erro) {
      throw ImportacaoException('Falha de rede: ${erro.message}');
    } catch (erro) {
      throw ImportacaoException('Erro inesperado ao importar: $erro');
    }
  }

  /// Extrai uma cifra de um HTML já baixado (ou colado pelo usuário).
  Future<Cifra?> parseHtmlToCifra(String html, String url) async {
    final documento = html_parser.parse(html);
    documento
        .querySelectorAll('script, style, noscript, svg, iframe')
        .forEach((elemento) => elemento.remove());

    final bloco = _melhorBloco(documento);
    if (bloco == null) return null;

    final corpo = _normalizarCorpo(_textoComQuebras(bloco));
    if (corpo.isEmpty) return null;

    final linhas = corpo.split('\n').where((l) => l.trim().isNotEmpty).toList();
    final temAcordes = linhas.any(isLinhaDeAcordes);
    if (!temAcordes && linhas.length < 8) return null;

    final titulo = _limparTitulo(_tituloDocumento(documento)) ?? 'Sem título';
    final artista = _limparArtista(_artistaDocumento(documento)) ?? 'Desconhecido';
    final tom = _detectarTom(documento, corpo);

    return Cifra(
      id: sanitizeFilename(titulo, artista),
      titulo: titulo,
      artista: artista,
      tom: tom,
      tipo: 'Congregação',
      fonte: fonteParaUrl(url),
      url: url,
      dataImportacao: DateTime.now(),
      conteudo: parseSecoes(corpo),
      bodyRaw: corpo,
      tags: const <String>[],
    );
  }

  /// Sanitiza o título/artista em um nome de arquivo seguro.
  String sanitizeFilename(String title, String artist) {
    final base = title.trim().isNotEmpty
        ? title
        : (artist.trim().isNotEmpty ? artist : 'cifra');
    return slugify(base);
  }

  /// Descobre a fonte a partir do host da URL.
  String fonteParaUrl(String url) {
    final host = Uri.tryParse(url)?.host.toLowerCase() ?? '';
    if (host.contains('cifraclub')) return 'CifraClub';
    if (host.contains('clickgratis')) return 'ClickGratis';
    if (host.contains('ciframaster')) return 'CifraMaster';
    return 'Outro';
  }

  // ---------------------------------------------------------------------------
  // Front-matter
  // ---------------------------------------------------------------------------

  _DocumentoMarkdown _separarFrontmatter(String conteudo) {
    final texto = conteudo.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    if (!texto.startsWith('---')) {
      return _DocumentoMarkdown(<String, dynamic>{}, texto);
    }

    final linhas = texto.split('\n');
    var fim = -1;
    for (var i = 1; i < linhas.length; i++) {
      if (linhas[i].trim() == '---') {
        fim = i;
        break;
      }
    }
    if (fim == -1) {
      return _DocumentoMarkdown(<String, dynamic>{}, texto);
    }

    var dados = <String, dynamic>{};
    try {
      final yaml = loadYaml(linhas.sublist(1, fim).join('\n'));
      if (yaml is YamlMap) dados = _converterMapa(yaml);
    } catch (_) {
      dados = <String, dynamic>{};
    }

    return _DocumentoMarkdown(
      dados,
      linhas.sublist(fim + 1).join('\n'),
    );
  }

  Map<String, dynamic> _converterMapa(YamlMap mapa) {
    final resultado = <String, dynamic>{};
    mapa.forEach((chave, valor) {
      resultado[chave.toString()] = _converterValor(valor);
    });
    return resultado;
  }

  dynamic _converterValor(dynamic valor) {
    if (valor is YamlMap) return _converterMapa(valor);
    if (valor is YamlList) {
      return valor.map(_converterValor).toList();
    }
    return valor;
  }

  // ---------------------------------------------------------------------------
  // HTML
  // ---------------------------------------------------------------------------

  String _decodificarResposta(http.Response resposta) {
    final contentType = resposta.headers['content-type'] ?? '';
    final charset = RegExp(r'charset=([\w-]+)', caseSensitive: false)
        .firstMatch(contentType)
        ?.group(1)
        ?.toLowerCase();
    if (charset == 'iso-8859-1' ||
        charset == 'latin1' ||
        charset == 'windows-1252') {
      return latin1.decode(resposta.bodyBytes, allowInvalid: true);
    }
    return utf8.decode(resposta.bodyBytes, allowMalformed: true);
  }

  dom.Element? _melhorBloco(dom.Document documento) {
    const seletores = [
      'pre',
      '.cifra_cnt pre',
      '#cifra_cnt pre',
      '.cifra_cnt',
      '#cifra_cnt',
      '.chord-sheet',
      '.cifra',
      '[data-chord-sheet]',
      'code',
    ];

    dom.Element? melhor;
    var melhorPontuacao = 0.0;
    final visitados = <dom.Element>{};

    for (final seletor in seletores) {
      for (final elemento in documento.querySelectorAll(seletor)) {
        if (!visitados.add(elemento)) continue;
        final texto = _textoComQuebras(elemento);
        final pontuacao = _pontuarBloco(texto);
        if (pontuacao > melhorPontuacao) {
          melhor = elemento;
          melhorPontuacao = pontuacao;
        }
      }
    }

    if (melhor != null && melhorPontuacao >= 20) return melhor;

    // Fallback: o corpo inteiro da página.
    final corpo = documento.body;
    if (corpo == null) return melhor;
    final texto = _normalizarCorpo(_textoComQuebras(corpo));
    if (_pontuarBloco(texto) >= 20) return corpo;
    return melhor;
  }

  double _pontuarBloco(String texto) {
    final linhas =
        texto.split('\n').where((linha) => linha.trim().isNotEmpty).toList();
    if (linhas.length < 3) return 0;
    final acordes = linhas.where(isLinhaDeAcordes).length;
    if (acordes == 0) return linhas.length * 0.1;
    return acordes * 20 + linhas.length + (acordes / linhas.length) * 100;
  }

  String _textoComQuebras(dom.Element elemento) {
    var conteudo = elemento.innerHtml;
    conteudo = conteudo.replaceAll(
      RegExp(r'<br\s*/?>', caseSensitive: false),
      '\n',
    );
    conteudo = conteudo.replaceAll(
      RegExp(r'</(?:p|div|li|tr|h[1-6]|section|article)>',
          caseSensitive: false),
      '\n',
    );
    final fragmento = html_parser.parseFragment(conteudo);
    return fragmento.text ?? '';
  }

  String _normalizarCorpo(String texto) {
    var conteudo = texto
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .replaceAll('\u00A0', ' ')
        .replaceAll('\t', '    ');

    final linhas = conteudo
        .split('\n')
        .map((linha) => linha.replaceFirst(RegExp(r'\s+$'), ''))
        .toList();

    final saida = <String>[];
    var vaziasSeguidas = 0;
    for (final linha in linhas) {
      if (linha.trim().isEmpty) {
        vaziasSeguidas++;
        if (vaziasSeguidas > 1) continue;
        saida.add('');
      } else {
        vaziasSeguidas = 0;
        saida.add(linha);
      }
    }
    while (saida.isNotEmpty && saida.first.trim().isEmpty) {
      saida.removeAt(0);
    }
    while (saida.isNotEmpty && saida.last.trim().isEmpty) {
      saida.removeLast();
    }
    return saida.join('\n');
  }

  String? _tituloDocumento(dom.Document documento) {
    const seletores = [
      'h1.t1',
      'h1',
      'meta[property="og:title"]',
      'meta[name="twitter:title"]',
    ];
    for (final seletor in seletores) {
      final elemento = documento.querySelector(seletor);
      if (elemento == null) continue;
      final valor = elemento.localName == 'meta'
          ? elemento.attributes['content']
          : elemento.text;
      if (valor != null && valor.trim().isNotEmpty) return valor.trim();
    }
    final titulo = documento.querySelector('title')?.text.trim();
    return titulo == null || titulo.isEmpty ? null : titulo;
  }

  String? _artistaDocumento(dom.Document documento) {
    const seletores = [
      'h2.t3 a',
      'h2.t3',
      '.artista a',
      '.artist-name',
      '.artist a',
      '[class*="artist"] a',
      '[class*="artista"] a',
    ];
    for (final seletor in seletores) {
      final elemento = documento.querySelector(seletor);
      final texto = elemento?.text.trim();
      if (texto != null && texto.isNotEmpty) return texto;
    }

    final tituloPagina = documento.querySelector('title')?.text.trim() ?? '';
    final partes = tituloPagina.split(' - ');
    if (partes.length >= 3) return partes[1].trim();
    if (partes.length == 2 && !_pareceSite(partes[1])) return partes[1].trim();
    return null;
  }

  String? _limparTitulo(String? bruto) {
    if (bruto == null) return null;
    var titulo = bruto.split(RegExp(r'\s+[|•]\s+')).first.trim();
    for (final sufixo in [
      ' - Cifra Club',
      ' | Cifra Club',
      ' - CifraClub',
      ' - ClickGrátis',
      ' - ClickGratis',
      ' - Cifra Master',
      ' - CifraMaster',
    ]) {
      titulo = titulo.replaceAll(sufixo, '');
    }
    final partes = titulo.split(' - ');
    if (partes.length >= 3) titulo = partes.first.trim();
    return titulo.trim().isEmpty ? null : titulo.trim();
  }

  String? _limparArtista(String? bruto) {
    if (bruto == null) return null;
    var artista = bruto.trim();
    for (final sufixo in [
      ' - Cifra Club',
      ' | Cifra Club',
      ' - CifraClub',
      'Cifra Club',
    ]) {
      artista = artista.replaceAll(sufixo, '');
    }
    artista = artista.trim();
    if (artista.isEmpty || _pareceSite(artista)) return null;
    return artista;
  }

  bool _pareceSite(String texto) {
    final minusculo = texto.toLowerCase();
    return minusculo.contains('cifra club') ||
        minusculo.contains('cifraclub') ||
        minusculo.contains('clickgratis') ||
        minusculo.contains('cifra master') ||
        minusculo.contains('ciframaster');
  }

  String? _detectarTom(dom.Document documento, String corpo) {
    final textoPagina = documento.body?.text ?? '';
    final match = RegExp(
      r'(?:Tom|Tonalidade)\s*:?\s*([A-G][#b]?m?)',
      caseSensitive: false,
    ).firstMatch(textoPagina);
    if (match != null) return match.group(1);

    for (final linha in corpo.split('\n')) {
      if (!isLinhaDeAcordes(linha)) continue;
      for (final token in linha.split(RegExp(r'\s+'))) {
        if (!isAcorde(token)) continue;
        final limpo = token.replaceAll(RegExp(r'^[|:(\[]+'), '');
        final tom = RegExp(r'^([A-G][#b]?)').firstMatch(limpo)?.group(1);
        if (tom != null) return tom;
      }
    }
    return null;
  }
}
