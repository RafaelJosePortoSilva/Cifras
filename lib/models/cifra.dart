import '../utils/chord_utils.dart';
import '../utils/text_utils.dart';

/// Uma linha de cifra.
///
/// `acordes` guarda a linha "crua" de acordes (preservando espaços, que são o
/// alinhamento sobre a letra) e `texto` a letra correspondente. Uma linha pode
/// ter apenas acordes (instrumental), apenas texto ou ambos.
class CifraLinha {
  const CifraLinha({this.acordes, this.texto = ''});

  const CifraLinha.vazia()
      : acordes = null,
        texto = '';

  final String? acordes;
  final String texto;

  bool get temAcordes => acordes != null && acordes!.trim().isNotEmpty;
  bool get temTexto => texto.trim().isNotEmpty;
  bool get isBlank => !temAcordes && !temTexto;
}

/// Uma seção da cifra (Intro, Verso, Refrão, ...).
class CifraSecao {
  const CifraSecao({required this.titulo, required this.linhas});

  final String titulo;
  final List<CifraLinha> linhas;

  bool get temAcordes => linhas.any((linha) => linha.temAcordes);
  bool get vazia => linhas.isEmpty;
}

/// Modelo completo de uma cifra em Markdown.
class Cifra {
  Cifra({
    required this.id,
    required this.titulo,
    required this.artista,
    this.tom,
    Set<String>? momentos,
    Set<String>? temas,
    this.tipo = 'Congregação',
    this.fonte,
    this.url,
    DateTime? dataImportacao,
    required this.conteudo,
    required this.bodyRaw,
    List<String>? tags,
    this.caminho,
  })  : momentos = Set<String>.of(momentos ?? const <String>{}),
        temas = Set<String>.of(temas ?? const <String>{}),
        tags = List<String>.of(tags ?? const <String>[]),
        dataImportacao = dataImportacao ?? DateTime.now(),
        secoes = conteudo.map((secao) => secao.titulo).toList();

  static const Object _naoInformado = Object();

  /// `filename.stem`, usado como referência em setlists.
  final String id;
  final String titulo;
  final String artista;
  final String? tom;
  final Set<String> momentos;
  final Set<String> temas;
  final String tipo;
  final String? fonte;
  final String? url;
  final DateTime dataImportacao;
  final List<String> secoes;
  final List<CifraSecao> conteudo;
  final String bodyRaw;
  final List<String> tags;
  final String? caminho;

  bool get hasAcordes => conteudo.any((secao) => secao.temAcordes);

  int get totalAcordes {
    var total = 0;
    for (final secao in conteudo) {
      for (final linha in secao.linhas) {
        if (linha.temAcordes) total += contarAcordes([linha.acordes!]);
      }
    }
    return total;
  }

  /// Cria a cifra a partir do front-matter já convertido em `Map` e do corpo.
  factory Cifra.fromYaml(
    Map<String, dynamic> yaml,
    String rawBody, {
    String id = '',
    String? caminho,
  }) {
    final corpo = removerTituloH1(rawBody);
    final cabecalho = primeiroTituloH1(rawBody);

    var titulo = _texto(yaml['titulo']) ?? '';
    var artista = _texto(yaml['artista']) ?? '';

    if (cabecalho != null) {
      final partes = cabecalho.split(' - ');
      if (titulo.isEmpty) titulo = partes.first.trim();
      if (artista.isEmpty && partes.length > 1) {
        artista = partes.sublist(1).join(' - ').trim();
      }
    }
    if (titulo.isEmpty) titulo = 'Sem título';
    if (artista.isEmpty) artista = 'Desconhecido';

    final secoes = parseSecoes(corpo);
    final idFinal = id.trim().isNotEmpty ? id.trim() : slugify(titulo);

    return Cifra(
      id: idFinal,
      titulo: titulo,
      artista: artista,
      tom: _texto(yaml['tom']),
      momentos: listaYaml(yaml['momentos']),
      temas: listaYaml(yaml['temas']),
      tipo: _texto(yaml['tipo']) ?? 'Congregação',
      fonte: _texto(yaml['fonte']),
      url: _texto(yaml['url']),
      dataImportacao: parseData(
        yaml['data_importacao'] ?? yaml['dataImportacao'],
        padrao: DateTime.now(),
      )!,
      conteudo: secoes,
      bodyRaw: corpo,
      tags: listaYaml(yaml['tags']).toList(),
      caminho: caminho,
    );
  }

  static String? _texto(dynamic valor) {
    if (valor == null) return null;
    final texto = valor.toString().trim();
    return texto.isEmpty ? null : texto;
  }

  /// Serializa a cifra de volta para Markdown com front-matter.
  String toMarkdown() {
    final buffer = StringBuffer()
      ..writeln('---')
      ..writeln('titulo: ${yamlValor(titulo)}')
      ..writeln('artista: ${yamlValor(artista)}')
      ..writeln('fonte: ${yamlValor(fonte ?? 'Manual')}')
      ..writeln('url: ${yamlValor(url)}')
      ..writeln('tom: ${yamlValor(tom)}')
      ..writeln('momentos: ${yamlLista(momentos)}')
      ..writeln('temas: ${yamlLista(temas)}')
      ..writeln('tipo: ${yamlValor(tipo)}')
      ..writeln('data_importacao: ${formatarDataIso(dataImportacao)}')
      ..writeln('tags: ${yamlLista(tags)}')
      ..writeln('---')
      ..writeln()
      ..writeln('# $titulo${artista.isEmpty ? '' : ' - $artista'}')
      ..writeln()
      ..write(_corpoParaMarkdown());

    return '${buffer.toString().trimRight()}\n';
  }

  String _corpoParaMarkdown() {
    if (bodyRaw.trim().isNotEmpty) return bodyRaw.trim();
    final buffer = StringBuffer();
    for (final secao in conteudo) {
      buffer.writeln('[${secao.titulo}]');
      for (final linha in secao.linhas) {
        if (linha.temAcordes) buffer.writeln(linha.acordes!.trimRight());
        if (linha.temTexto) buffer.writeln(linha.texto.trimRight());
      }
      buffer.writeln();
    }
    return buffer.toString().trim();
  }

  /// Texto plano para compartilhar em mensageiros.
  String toTextoCompartilhavel({bool incluirMetadados = true}) {
    final buffer = StringBuffer()
      ..writeln('$titulo - $artista');
    if (incluirMetadados) {
      if (tom != null && tom!.isNotEmpty) buffer.writeln('Tom: $tom');
      if (momentos.isNotEmpty) {
        buffer.writeln('Momentos: ${momentos.join(', ')}');
      }
      if (temas.isNotEmpty) buffer.writeln('Temas: ${temas.join(', ')}');
      if (url != null && url!.isNotEmpty) buffer.writeln('Fonte: $url');
    }
    buffer
      ..writeln()
      ..write(bodyRaw.trim());
    return buffer.toString().trim();
  }

  Cifra copyWith({
    String? id,
    String? titulo,
    String? artista,
    Object? tom = _naoInformado,
    Set<String>? momentos,
    Set<String>? temas,
    String? tipo,
    Object? fonte = _naoInformado,
    Object? url = _naoInformado,
    DateTime? dataImportacao,
    List<CifraSecao>? conteudo,
    String? bodyRaw,
    List<String>? tags,
    Object? caminho = _naoInformado,
  }) {
    return Cifra(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      artista: artista ?? this.artista,
      tom: identical(tom, _naoInformado) ? this.tom : tom as String?,
      momentos: momentos ?? this.momentos,
      temas: temas ?? this.temas,
      tipo: tipo ?? this.tipo,
      fonte:
          identical(fonte, _naoInformado) ? this.fonte : fonte as String?,
      url: identical(url, _naoInformado) ? this.url : url as String?,
      dataImportacao: dataImportacao ?? this.dataImportacao,
      conteudo: conteudo ?? this.conteudo,
      bodyRaw: bodyRaw ?? this.bodyRaw,
      tags: tags ?? this.tags,
      caminho: identical(caminho, _naoInformado)
          ? this.caminho
          : caminho as String?,
    );
  }

  @override
  String toString() => '$titulo - $artista';
}

/// Converte o corpo Markdown em seções estruturadas.
///
/// Reconhece cabeçalhos `## Seção` e `[Seção]`, ignora o H1 do título e agrupa
/// uma linha de acordes com a linha de letra imediatamente seguinte.
List<CifraSecao> parseSecoes(String corpo) {
  final linhas =
      corpo.replaceAll('\r\n', '\n').replaceAll('\r', '\n').split('\n');
  final secoes = <CifraSecao>[];
  var tituloAtual = 'Cifra';
  var atuais = <CifraLinha>[];

  void fecharSecao() {
    while (atuais.isNotEmpty && atuais.first.isBlank) {
      atuais.removeAt(0);
    }
    while (atuais.isNotEmpty && atuais.last.isBlank) {
      atuais.removeLast();
    }
    if (atuais.isNotEmpty) {
      secoes.add(
        CifraSecao(
          titulo: tituloAtual,
          linhas: List<CifraLinha>.unmodifiable(atuais),
        ),
      );
    }
    atuais = <CifraLinha>[];
  }

  for (var i = 0; i < linhas.length; i++) {
    final original = linhas[i].replaceAll('\t', '    ');
    final texto = original.trim();

    if (texto.isEmpty) {
      if (atuais.isNotEmpty) atuais.add(const CifraLinha.vazia());
      continue;
    }

    // Título H1 é renderizado pelo cabeçalho do visualizador.
    if (texto.startsWith('# ')) continue;

    final headerMarkdown = RegExp(r'^#{2,6}\s+(.+)$').firstMatch(texto);
    if (headerMarkdown != null) {
      fecharSecao();
      tituloAtual = headerMarkdown.group(1)!.trim();
      continue;
    }

    final headerColchete = RegExp(r'^\[([^\]]+)\]\s*(.*)$').firstMatch(texto);
    if (headerColchete != null) {
      fecharSecao();
      tituloAtual = headerColchete.group(1)!.trim();
      final resto = headerColchete.group(2)!.trim();
      if (resto.isNotEmpty) {
        final deAcordes = isLinhaDeAcordes(resto);
        atuais.add(
          CifraLinha(
            acordes: deAcordes ? resto : null,
            texto: deAcordes ? '' : resto,
          ),
        );
      }
      continue;
    }

    if (isLinhaDeAcordes(original)) {
      var letra = '';
      if (i + 1 < linhas.length) {
        final proximaOriginal = linhas[i + 1].replaceAll('\t', '    ');
        final proxima = proximaOriginal.trim();
        final proximaEhCabecalho =
            proxima.startsWith('#') || proxima.startsWith('[');
        if (proxima.isNotEmpty &&
            !proximaEhCabecalho &&
            !isLinhaDeAcordes(proximaOriginal)) {
          letra = proximaOriginal.trimRight();
          i++;
        }
      }
      atuais.add(CifraLinha(acordes: original.trimRight(), texto: letra));
    } else {
      atuais.add(CifraLinha(texto: original.trimRight()));
    }
  }
  fecharSecao();

  if (secoes.isEmpty) {
    return [const CifraSecao(titulo: 'Cifra', linhas: <CifraLinha>[])];
  }
  return secoes;
}
