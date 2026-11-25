import '../config/app_config.dart';
import 'cifra.dart';
import '../utils/text_utils.dart';

enum SetlistStatus {
  rascunho,
  confirmado,
  finalizado;

  String get rotulo {
    switch (this) {
      case SetlistStatus.rascunho:
        return 'Rascunho';
      case SetlistStatus.confirmado:
        return 'Confirmado';
      case SetlistStatus.finalizado:
        return 'Finalizado';
    }
  }

  static SetlistStatus de(String? valor) {
    switch ((valor ?? '').trim().toLowerCase()) {
      case 'confirmado':
        return SetlistStatus.confirmado;
      case 'finalizado':
        return SetlistStatus.finalizado;
      default:
        return SetlistStatus.rascunho;
    }
  }
}

/// Item de um momento litúrgico do setlist.
class ItemSetlist {
  ItemSetlist({
    required this.cifraId,
    this.nota = '',
    this.estaTocado = false,
  });

  final String cifraId;
  String nota;
  bool estaTocado;

  ItemSetlist copiar() => ItemSetlist(
        cifraId: cifraId,
        nota: nota,
        estaTocado: estaTocado,
      );

  ItemSetlist copyWith({
    String? cifraId,
    String? nota,
    bool? estaTocado,
  }) {
    return ItemSetlist(
      cifraId: cifraId ?? this.cifraId,
      nota: nota ?? this.nota,
      estaTocado: estaTocado ?? this.estaTocado,
    );
  }
}

/// Momento litúrgico (Abertura, Comunhão, ...) dentro de um setlist.
class MomentoLiturgo {
  MomentoLiturgo({
    required this.nome,
    List<ItemSetlist>? itens,
    this.estaCompleto = false,
  }) : itens = itens ?? <ItemSetlist>[];

  final String nome;
  final List<ItemSetlist> itens;
  bool estaCompleto;

  MomentoLiturgo copiar() => MomentoLiturgo(
        nome: nome,
        itens: itens.map((item) => item.copiar()).toList(),
        estaCompleto: estaCompleto,
      );

  MomentoLiturgo copyWith({
    String? nome,
    List<ItemSetlist>? itens,
    bool? estaCompleto,
  }) {
    return MomentoLiturgo(
      nome: nome ?? this.nome,
      itens: itens ?? this.itens,
      estaCompleto: estaCompleto ?? this.estaCompleto,
    );
  }
}

/// Modelo completo de um setlist litúrgico.
class Setlist {
  Setlist({
    required this.id,
    required this.titulo,
    required this.evento,
    required this.data,
    this.diaLiturgico = '',
    DateTime? criadoEm,
    this.status = SetlistStatus.rascunho,
    List<MomentoLiturgo>? momentos,
    this.caminho,
  })  : criadoEm = criadoEm ?? DateTime.now(),
        momentos = momentos ?? <MomentoLiturgo>[];

  final String id;
  final String titulo;
  final String evento;
  final DateTime data;
  final String diaLiturgico;
  final DateTime criadoEm;
  SetlistStatus status;
  final List<MomentoLiturgo> momentos;
  final String? caminho;

  int get totalMusicas =>
      momentos.fold(0, (total, momento) => total + momento.itens.length);

  int get totalMomentos => momentos.length;

  /// Resolve cada referência de cifra usando uma lista já carregada do vault.
  Map<String, Cifra?> resolverCifras(List<Cifra> disponiveis) {
    final porId = {for (final cifra in disponiveis) cifra.id: cifra};
    final resolvidas = <String, Cifra?>{};
    for (final momento in momentos) {
      for (final item in momento.itens) {
        resolvidas[item.cifraId] = porId[item.cifraId];
      }
    }
    return resolvidas;
  }

  factory Setlist.fromYaml(
    Map<String, dynamic> yaml,
    String rawBody, {
    String id = '',
    String? caminho,
  }) {
    final corpo = removerTituloH1(rawBody);
    final titulo = _texto(yaml['titulo']) ??
        _texto(primeiroTituloH1(rawBody)) ??
        'Setlist sem título';

    return Setlist(
      id: id.trim().isNotEmpty ? id.trim() : slugify(titulo),
      titulo: titulo,
      evento: _texto(yaml['evento']) ?? '',
      data: parseData(yaml['data'], padrao: DateTime.now())!,
      diaLiturgico: _texto(yaml['diaLiturgico'] ?? yaml['dia_liturgico']) ?? '',
      criadoEm: parseData(
        yaml['criadoEm'] ?? yaml['criado_em'],
        padrao: DateTime.now(),
      )!,
      status: SetlistStatus.de(_texto(yaml['status'])),
      momentos: parseMomentos(corpo),
      caminho: caminho,
    );
  }

  static String? _texto(dynamic valor) {
    if (valor == null) return null;
    final texto = valor.toString().trim();
    return texto.isEmpty ? null : texto;
  }

  /// Serializa o setlist de volta para Markdown.
  String toMarkdown() {
    final buffer = StringBuffer()
      ..writeln('---')
      ..writeln('titulo: ${yamlValor(titulo)}')
      ..writeln('evento: ${yamlValor(evento)}')
      ..writeln('data: ${formatarDataIso(data)}')
      ..writeln('diaLiturgico: ${yamlValor(diaLiturgico)}')
      ..writeln('criadoEm: ${criadoEm.toIso8601String()}')
      ..writeln('status: ${status.name}')
      ..writeln('---')
      ..writeln()
      ..writeln('# $titulo');

    for (final momento in momentos) {
      buffer
        ..writeln()
        ..writeln('## ${AppConfig.emojiMomento(momento.nome)} ${momento.nome}');
      for (final item in momento.itens) {
        buffer.writeln('- Cifra: ${yamlValor(item.cifraId)}');
        if (item.nota.trim().isNotEmpty) {
          buffer.writeln('  Nota: ${yamlValor(item.nota)}');
        }
        if (item.estaTocado) {
          buffer.writeln('  Tocado: true');
        }
      }
    }

    return '${buffer.toString().trimRight()}\n';
  }

  Setlist copyWith({
    String? id,
    String? titulo,
    String? evento,
    DateTime? data,
    String? diaLiturgico,
    DateTime? criadoEm,
    SetlistStatus? status,
    List<MomentoLiturgo>? momentos,
    String? caminho,
  }) {
    return Setlist(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      evento: evento ?? this.evento,
      data: data ?? this.data,
      diaLiturgico: diaLiturgico ?? this.diaLiturgico,
      criadoEm: criadoEm ?? this.criadoEm,
      status: status ?? this.status,
      momentos: momentos ?? this.momentos,
      caminho: caminho ?? this.caminho,
    );
  }

  @override
  String toString() => '$titulo (${formatarData(data)})';
}

/// Remove emojis/símbolos do começo de um nome de momento.
String limparNomeMomento(String valor) {
  final texto = valor.trim();
  final runes = texto.runes.toList();
  var inicio = 0;
  for (var i = 0; i < runes.length; i++) {
    final rune = runes[i];
    if (rune == 0x20 ||
        rune == 0xFE0F ||
        rune == 0x200D ||
        rune == 0x20E3 ||
        _ehEmoji(rune)) {
      inicio = i + 1;
    } else {
      break;
    }
  }
  final nome = String.fromCharCodes(runes.sublist(inicio)).trim();
  return nome.isEmpty ? texto : nome;
}

bool _ehEmoji(int rune) =>
    (rune >= 0x1F000 && rune <= 0x1FAFF) ||
    (rune >= 0x2600 && rune <= 0x27BF) ||
    (rune >= 0x2B00 && rune <= 0x2BFF) ||
    (rune >= 0x2190 && rune <= 0x21FF) ||
    (rune >= 0x2300 && rune <= 0x23FF);

String _limparValor(String valor) {
  var texto = valor.trim();
  if (texto.length >= 2) {
    final primeiro = texto[0];
    final ultimo = texto[texto.length - 1];
    if ((primeiro == '"' && ultimo == '"') ||
        (primeiro == "'" && ultimo == "'") ||
        (primeiro == '`' && ultimo == '`')) {
      texto = texto.substring(1, texto.length - 1);
    }
  }
  return texto.trim();
}

/// Converte o corpo do setlist em momentos com itens.
List<MomentoLiturgo> parseMomentos(String corpo) {
  final momentos = <MomentoLiturgo>[];
  MomentoLiturgo? momentoAtual;
  ItemSetlist? itemAtual;

  MomentoLiturgo garantirMomento([String nome = 'Geral']) {
    final existente = momentoAtual;
    if (existente != null) return existente;
    final novo = MomentoLiturgo(nome: nome);
    momentos.add(novo);
    momentoAtual = novo;
    return novo;
  }

  final linhas =
      corpo.replaceAll('\r\n', '\n').replaceAll('\r', '\n').split('\n');

  for (final linha in linhas) {
    final texto = linha.trim();
    if (texto.isEmpty) continue;

    final header = RegExp(r'^#{2,6}\s+(.+)$').firstMatch(texto);
    if (header != null) {
      final novo = MomentoLiturgo(nome: limparNomeMomento(header.group(1)!));
      momentoAtual = novo;
      momentos.add(novo);
      itemAtual = null;
      continue;
    }

    final cifraMatch =
        RegExp(r'^[-*]\s*Cifra\s*:\s*(.+)$', caseSensitive: false)
            .firstMatch(texto);
    if (cifraMatch != null) {
      final cifraId = _limparValor(cifraMatch.group(1)!);
      if (cifraId.isNotEmpty) {
        final atual = garantirMomento();
        itemAtual = ItemSetlist(cifraId: cifraId);
        atual.itens.add(itemAtual);
      }
      continue;
    }

    final notaMatch = RegExp(r'^Nota\s*:\s*(.+)$', caseSensitive: false)
        .firstMatch(texto);
    if (notaMatch != null) {
      itemAtual?.nota = _limparValor(notaMatch.group(1)!);
      continue;
    }

    final tocadoMatch = RegExp(r'^Tocado\s*:\s*(.+)$', caseSensitive: false)
        .firstMatch(texto);
    if (tocadoMatch != null) {
      final valor = _limparValor(tocadoMatch.group(1)!).toLowerCase();
      itemAtual?.estaTocado = valor == 'true' || valor == 'sim' || valor == '1';
      continue;
    }

    // Aceita também bullets simples: "- Nome_da_Cifra"
    final bullet = RegExp(r'^[-*]\s+(.+)$').firstMatch(texto);
    if (bullet != null) {
      final cifraId = _limparValor(bullet.group(1)!);
      if (cifraId.isNotEmpty) {
        final atual = garantirMomento();
        itemAtual = ItemSetlist(cifraId: cifraId);
        atual.itens.add(itemAtual);
      }
      continue;
    }

    // Nome da seção sem `##` (fallback tolerante).
    if (itemAtual == null && texto.length < 40) {
      final atual = momentoAtual;
      if (atual == null || atual.itens.isNotEmpty) {
        final novo = MomentoLiturgo(nome: limparNomeMomento(texto));
        momentoAtual = novo;
        momentos.add(novo);
      }
    }
  }

  return momentos;
}
