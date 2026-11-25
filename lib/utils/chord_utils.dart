/// Utilitários de acordes: detecção, transposição e contagem.
///
/// O parser trabalha com linhas "cruas" de acordes (como no CifraClub), para
/// preservar o alinhamento acorde/letra. A transposição reposiciona os acordes
/// mantendo as colunas originais sempre que possível.
library;

const List<String> notasSustenidos = [
  'C',
  'C#',
  'D',
  'D#',
  'E',
  'F',
  'F#',
  'G',
  'G#',
  'A',
  'A#',
  'B',
];

const List<String> notasBemois = [
  'C',
  'Db',
  'D',
  'Eb',
  'E',
  'F',
  'Gb',
  'G',
  'Ab',
  'A',
  'Bb',
  'B',
];

const Map<String, int> _indiceNotas = {
  'C': 0,
  'B#': 0,
  'C#': 1,
  'Db': 1,
  'D': 2,
  'D#': 3,
  'Eb': 3,
  'E': 4,
  'Fb': 4,
  'E#': 5,
  'F': 5,
  'F#': 6,
  'Gb': 6,
  'G': 7,
  'G#': 8,
  'Ab': 8,
  'A': 9,
  'A#': 10,
  'Bb': 10,
  'B': 11,
  'Cb': 11,
};

final RegExp _regexAcorde = RegExp(
  r'^[A-G][#b]?'
  r'(?:maj|min|dim|aug|sus|add|alt|m|M|°|º|ø|\+|Δ)?'
  r'(?:[0-9]{1,2})?'
  r'(?:maj|min|sus|add|m|M|b|#|\+|-)?'
  r'(?:[0-9]{1,2})?'
  r'(?:\([^)]*\))?'
  r'(?:\/[A-G][#b]?)?$',
);

const Set<String> _tokensIgnorados = {
  'x2',
  '2x',
  'x3',
  '3x',
  'x4',
  '4x',
  'x5',
  '5x',
  'x6',
  '6x',
  'bis',
  'repete',
  'repete:',
  '%',
  'n.c',
  'nc',
  '...',
};

/// Remove invólucros comuns de um token de acorde: `|`, `(`, `[`, `:`.
String _nucleoAcorde(String token) {
  var texto = token.trim();
  if (texto.isEmpty) return '';
  texto = texto.replaceAll(RegExp(r'^[|:]+'), '');
  texto = texto.replaceAll(RegExp(r'[|:,;.]+$'), '');
  // Remove parênteses/colchetes que envolvem o acorde inteiro: (D) / [D]
  while (texto.length >= 2 &&
      ((texto.startsWith('(') && texto.endsWith(')')) ||
          (texto.startsWith('[') && texto.endsWith(']')))) {
    texto = texto.substring(1, texto.length - 1);
  }
  return texto;
}

/// Retorna `true` se o token representa um acorde.
bool isAcorde(String token) {
  final nucleo = _nucleoAcorde(token);
  if (nucleo.isEmpty) return false;
  final minusculo = nucleo.toLowerCase();
  if (minusculo == 'n.c.' || minusculo == 'n.c' || nucleo == '%') return true;
  return _regexAcorde.hasMatch(nucleo);
}

/// Retorna `true` quando a linha contém apenas acordes (e marcações de
/// repetição), como `D  A/C#  Bm7  G`.
bool isLinhaDeAcordes(String linha) {
  final texto = linha.trim();
  if (texto.isEmpty) return false;

  // Cabeçalho de seção não é linha de acordes.
  if (texto.startsWith('[') && texto.endsWith(']') && texto.length > 2) {
    return false;
  }

  final tokens = texto.split(RegExp(r'\s+'));
  var encontrados = 0;
  for (final token in tokens) {
    final nucleo = _nucleoAcorde(token);
    if (nucleo.isEmpty) continue;
    if (_tokensIgnorados.contains(nucleo.toLowerCase())) continue;
    if (!isAcorde(nucleo)) return false;
    encontrados++;
  }
  return encontrados > 0;
}

String _nomeNota(int indice, bool bemol) {
  final normalizado = ((indice % 12) + 12) % 12;
  return bemol ? notasBemois[normalizado] : notasSustenidos[normalizado];
}

/// Transpõe um acorde em [semitons] semitons.
///
/// Preserva sufixos (`m7`, `sus4`, `add9`, `(b5)`, ...) e baixo invertido
/// (`/F#`). Ex.: `D/F#` + 2 -> `E/G#`.
String transporAcorde(
  String acorde,
  int semitons, {
  bool preferirBemois = false,
}) {
  if (semitons % 12 == 0) return acorde;
  final texto = acorde.trim();
  if (!isAcorde(texto)) return acorde;
  final match = RegExp(r'^([A-G][#b]?)([^/]*)?(?:\/([A-G][#b]?))?$')
      .firstMatch(texto);
  if (match == null) return acorde;

  final base = match.group(1)!;
  final sufixo = match.group(2) ?? '';
  final baixo = match.group(3);
  final indiceBase = _indiceNotas[base];
  if (indiceBase == null) return acorde;

  final usarBemois = preferirBemois || base.contains('b');
  final resultado = StringBuffer(
    '${_nomeNota(indiceBase + semitons, usarBemois)}$sufixo',
  );

  if (baixo != null) {
    final indiceBaixo = _indiceNotas[baixo];
    if (indiceBaixo != null) {
      resultado.write('/${_nomeNota(indiceBaixo + semitons, usarBemois)}');
    }
  }
  return resultado.toString();
}

String _transporToken(String token, int semitons, bool preferirBemois) {
  if (token.isEmpty) return token;

  var prefixo = '';
  var sufixo = '';
  var nucleo = token;

  while (nucleo.isNotEmpty && '|:'.contains(nucleo[0])) {
    prefixo += nucleo[0];
    nucleo = nucleo.substring(1);
  }
  while (nucleo.isNotEmpty && '|:,;.'.contains(nucleo[nucleo.length - 1])) {
    sufixo = nucleo[nucleo.length - 1] + sufixo;
    nucleo = nucleo.substring(0, nucleo.length - 1);
  }
  while (nucleo.length >= 2 &&
      ((nucleo.startsWith('(') && nucleo.endsWith(')')) ||
          (nucleo.startsWith('[') && nucleo.endsWith(']')))) {
    prefixo += nucleo[0];
    sufixo = nucleo[nucleo.length - 1] + sufixo;
    nucleo = nucleo.substring(1, nucleo.length - 1);
  }

  if (!isAcorde(nucleo)) return token;
  return '$prefixo${transporAcorde(nucleo, semitons, preferirBemois: preferirBemois)}$sufixo';
}

/// Transpõe todos os acordes de uma linha, preservando o espaçamento.
String transporLinhaAcordes(
  String linha,
  int semitons, {
  bool preferirBemois = false,
}) {
  if (semitons % 12 == 0) return linha;

  final buffer = StringBuffer();
  var ultimo = 0;
  for (final match in RegExp(r'\S+').allMatches(linha)) {
    buffer.write(linha.substring(ultimo, match.start));
    buffer.write(
      _transporToken(match.group(0)!, semitons, preferirBemois),
    );
    ultimo = match.end;
  }
  buffer.write(linha.substring(ultimo));
  return buffer.toString();
}

/// Transpõe apenas a tonalidade (usada no badge "Tom").
String? transporTom(String? tom, int semitons) {
  if (tom == null || tom.trim().isEmpty) return null;
  return transporAcorde(tom, semitons,
      preferirBemois: tom.contains('b'));
}

/// Chaves enarmônicas que costumam ser escritas com bemóis.
bool tomUsaBemois(String? tom) {
  if (tom == null) return false;
  return tom.contains('b') || const {'F', 'Bb', 'Eb', 'Ab', 'Db', 'Gb'}.contains(tom);
}

/// Conta quantos acordes existem em um conjunto de linhas.
int contarAcordes(Iterable<String> linhas) {
  var total = 0;
  for (final linha in linhas) {
    if (!isLinhaDeAcordes(linha)) continue;
    for (final token in linha.split(RegExp(r'\s+'))) {
      if (isAcorde(_nucleoAcorde(token))) total++;
    }
  }
  return total;
}
