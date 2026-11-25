import 'package:intl/intl.dart';

const Map<String, String> _acentos = {
  'á': 'a',
  'à': 'a',
  'â': 'a',
  'ã': 'a',
  'ä': 'a',
  'å': 'a',
  'Á': 'A',
  'À': 'A',
  'Â': 'A',
  'Ã': 'A',
  'Ä': 'A',
  'é': 'e',
  'è': 'e',
  'ê': 'e',
  'ë': 'e',
  'É': 'E',
  'È': 'E',
  'Ê': 'E',
  'Ë': 'E',
  'í': 'i',
  'ì': 'i',
  'î': 'i',
  'ï': 'i',
  'Í': 'I',
  'Ì': 'I',
  'Î': 'I',
  'Ï': 'I',
  'ó': 'o',
  'ò': 'o',
  'ô': 'o',
  'õ': 'o',
  'ö': 'o',
  'Ó': 'O',
  'Ò': 'O',
  'Ô': 'O',
  'Õ': 'O',
  'Ö': 'O',
  'ú': 'u',
  'ù': 'u',
  'û': 'u',
  'ü': 'u',
  'Ú': 'U',
  'Ù': 'U',
  'Û': 'U',
  'Ü': 'U',
  'ç': 'c',
  'Ç': 'C',
  'ñ': 'n',
  'Ñ': 'N',
  'ý': 'y',
  'ÿ': 'y',
  'Ý': 'Y',
};

/// Remove acentos mantendo o restante do texto intacto.
String removerAcentos(String texto) {
  final buffer = StringBuffer();
  for (var i = 0; i < texto.length; i++) {
    final caractere = texto[i];
    buffer.write(_acentos[caractere] ?? caractere);
  }
  return buffer.toString();
}

/// Texto normalizado para busca (minúsculo e sem acentos).
String normalizarTexto(String texto) =>
    removerAcentos(texto.toLowerCase()).trim();

/// Converte um título em um nome de arquivo seguro.
///
/// Ex.: "Glória a Deus!" -> "gloria_a_deus"
String slugify(String texto, {int limite = 90}) {
  var slug = removerAcentos(texto.toLowerCase())
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+'), '')
      .replaceAll(RegExp(r'_+$'), '');
  if (slug.isEmpty) {
    slug = 'sem_titulo';
  }
  if (slug.length > limite) {
    slug = slug.substring(0, limite);
    slug = slug.replaceAll(RegExp(r'_+$'), '');
  }
  return slug;
}

/// Escapa uma string para uso em YAML (front-matter).
String yamlValor(String? valor) {
  final texto = (valor ?? '').replaceAll(RegExp(r'[\r\n]+'), ' ').trim();
  if (texto.isEmpty) return '""';

  final precisaDeAspas = RegExp(
    r'''^[\s\-?:,\[\]{}#&*!|>'"%@`]|:\s|\s#''',
  ).hasMatch(texto);
  final pareceLiteral = RegExp(
    r'^(true|false|null|yes|no|on|off|~|-?\d+(\.\d+)?)$',
    caseSensitive: false,
  ).hasMatch(texto);

  if (precisaDeAspas || pareceLiteral) {
    return '"${texto.replaceAll('"', r'\"')}"';
  }
  return texto;
}

/// Serializa uma lista de strings no formato YAML inline.
String yamlLista(Iterable<String> valores) {
  final itens = valores
      .map((v) => v.trim())
      .where((v) => v.isNotEmpty)
      .map(yamlValor)
      .toList();
  return '[${itens.join(', ')}]';
}

/// Converte um valor YAML (lista ou string separada por vírgulas) em `Set`.
Set<String> listaYaml(dynamic valor) {
  if (valor == null) return <String>{};
  if (valor is Iterable) {
    return valor
        .map((e) => e.toString().trim())
        .where((e) => e.isNotEmpty)
        .toSet();
  }
  final texto = valor.toString().trim();
  if (texto.isEmpty) return <String>{};
  final semColchetes = texto.startsWith('[') && texto.endsWith(']')
      ? texto.substring(1, texto.length - 1)
      : texto;
  return semColchetes
      .split(RegExp(r'[,;]'))
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toSet();
}

/// Lê datas em formatos comuns encontrados no front-matter.
DateTime? parseData(dynamic valor, {DateTime? padrao}) {
  if (valor == null) return padrao;
  if (valor is DateTime) return valor;
  final texto = valor.toString().trim();
  if (texto.isEmpty) return padrao;

  final iso = DateTime.tryParse(texto);
  if (iso != null) return iso;

  for (final formato in ['dd/MM/yyyy', 'dd/MM/yyyy HH:mm', 'yyyy-MM-dd HH:mm']) {
    try {
      return DateFormat(formato).parseStrict(texto);
    } catch (_) {
      // tenta o próximo formato
    }
  }
  return padrao;
}

String formatarData(DateTime data) => DateFormat('dd/MM/yyyy').format(data);

String formatarDataHora(DateTime data) =>
    DateFormat('dd/MM/yyyy HH:mm').format(data);

String formatarDataIso(DateTime data) =>
    DateFormat('yyyy-MM-dd').format(data);

String formatarDataHoraIso(DateTime data) =>
    DateFormat('yyyy-MM-dd HH:mm:ss').format(data);

/// Remove o primeiro título H1 do corpo (ele é regenerado na escrita).
String removerTituloH1(String corpo) {
  final linhas = corpo.replaceAll('\r\n', '\n').split('\n');
  final indice = linhas.indexWhere((l) => l.trimLeft().startsWith('# '));
  if (indice < 0) return corpo.trim();
  linhas.removeAt(indice);
  return linhas.join('\n').trim();
}

String? primeiroTituloH1(String corpo) {
  for (final linha in corpo.replaceAll('\r\n', '\n').split('\n')) {
    final texto = linha.trim();
    if (texto.startsWith('# ')) {
      return texto.substring(2).trim();
    }
  }
  return null;
}
