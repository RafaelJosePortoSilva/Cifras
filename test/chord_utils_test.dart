import 'package:cifravault/utils/chord_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isAcorde', () {
    test('reconhece acordes simples e com sufixos', () {
      expect(isAcorde('C'), isTrue);
      expect(isAcorde('D/F#'), isTrue);
      expect(isAcorde('Bm7'), isTrue);
      expect(isAcorde('A9'), isTrue);
      expect(isAcorde('Gsus4'), isTrue);
      expect(isAcorde('F#m7(b5)'), isTrue);
      expect(isAcorde('N.C.'), isTrue);
    });

    test('rejeita palavras e cabeçalhos', () {
      expect(isAcorde('Glória'), isFalse);
      expect(isAcorde('[Intro]'), isFalse);
      expect(isAcorde('x2'), isFalse);
      expect(isAcorde(''), isFalse);
    });
  });

  group('isLinhaDeAcordes', () {
    test('aceita linha apenas com acordes e marcações', () {
      expect(isLinhaDeAcordes('D  A/C#  Bm7  G'), isTrue);
      expect(isLinhaDeAcordes('| D | A | Bm | G |'), isTrue);
      expect(isLinhaDeAcordes('A'), isTrue);
      expect(isLinhaDeAcordes('D  A  x2'), isTrue);
    });

    test('rejeita letra e cabeçalho de seção', () {
      expect(isLinhaDeAcordes('Glória, glória a Deus nas alturas'), isFalse);
      expect(isLinhaDeAcordes('[Refrão]'), isFalse);
      expect(isLinhaDeAcordes(''), isFalse);
    });
  });

  group('transporAcorde', () {
    test('sobe e desce semitons preservando sufixos', () {
      expect(transporAcorde('D/F#', 2), 'E/G#');
      expect(transporAcorde('Bm7', 2), 'C#m7');
      expect(transporAcorde('A9', -2), 'G9');
      expect(transporAcorde('Gsus4', 5), 'Csus4');
      expect(transporAcorde('C', 0), 'C');
    });

    test('respeita bemóis quando solicitado', () {
      expect(transporAcorde('C', 1, preferirBemois: true), 'Db');
      expect(transporAcorde('F', 1, preferirBemois: true), 'Gb');
      expect(transporAcorde('Bb', 2), 'C');
    });

    test('não altera tokens que não são acordes', () {
      expect(transporAcorde('x2', 2), 'x2');
      expect(transporAcorde('Glória', 2), 'Glória');
    });
  });

  group('transporLinhaAcordes', () {
    test('preserva espaços e alinhamento', () {
      expect(
        transporLinhaAcordes('D  A/C#  Bm7  G', 2),
        'E  B/D#  C#m7  A',
      );
      expect(
        transporLinhaAcordes('Em       D/F#       G', -1),
        'D#m       C#/F       F#',
      );
    });

    test('mantém marcadores de compasso', () {
      expect(
        transporLinhaAcordes('| D | A | Bm | G |', 2),
        '| E | B | C#m | A |',
      );
    });
  });

  group('tons', () {
    test('transporTom usa a grafia do tom original', () {
      expect(transporTom('D', 2), 'E');
      expect(transporTom('Bb', 2), 'C');
      expect(transporTom(null, 2), isNull);
      expect(transporTom('', 2), isNull);
    });

    test('tomUsaBemois', () {
      expect(tomUsaBemois('F'), isTrue);
      expect(tomUsaBemois('Bb'), isTrue);
      expect(tomUsaBemois('D'), isFalse);
      expect(tomUsaBemois(null), isFalse);
    });
  });

  test('contarAcordes ignora letras', () {
    expect(contarAcordes(['D  A  Bm  G']), 4);
    expect(contarAcordes(['Glória a Deus', 'D  A']), 2);
    expect(contarAcordes(['[Intro]']), 0);
  });
}
