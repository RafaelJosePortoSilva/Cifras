import 'package:cifravault/services/parser_service.dart';
import 'package:cifravault/utils/text_utils.dart';
import 'package:flutter_test/flutter_test.dart';

const String _cifraMarkdown = '''---
titulo: Glória a Deus Nas Alturas
artista: Banda Shalom
fonte: CifraClub
url: https://www.cifraclub.com.br/banda-shalom/gloria/
tom: D
momentos: [Abertura, Gloria]
temas: [Eucaristia, Louvor]
tipo: Congregação
data_importacao: 2026-11-24
tags: [gospel, missa]
---

# Glória a Deus Nas Alturas - Banda Shalom

[Intro]
D  A  Bm  G

[Verso 1]
D            A
Glória, glória a Deus nas alturas
Bm           G
e paz na terra aos homens

[Refrão]
D        A        Bm       G
Glória a Deus, glória a Deus
''';

const String _setlistMarkdown = '''---
titulo: Ceia Materna - 29/11
evento: "Ceia Materna - Casa Maria"
data: 2026-11-29
diaLiturgico: ""
criadoEm: 2026-11-28T20:00:00.000
status: rascunho
---

# Ceia Materna - 29/11

## 🕊️ Abertura
- Cifra: "gloria_a_deus"
  Nota: "Versos completos + Refrão x2"
  Tocado: true

## ✝️ Ato Penitencial
- Cifra: "confesso_senhor"
  Nota: "Verso 1 e 2"
''';

void main() {
  final parser = ParserService();

  group('parseCifraMarkdown', () {
    test('lê front-matter e metadados', () {
      final cifra = parser.parseCifraMarkdown(
        _cifraMarkdown,
        id: 'gloria_a_deus',
      );

      expect(cifra.id, 'gloria_a_deus');
      expect(cifra.titulo, 'Glória a Deus Nas Alturas');
      expect(cifra.artista, 'Banda Shalom');
      expect(cifra.tom, 'D');
      expect(cifra.tipo, 'Congregação');
      expect(cifra.fonte, 'CifraClub');
      expect(cifra.momentos, containsAll(['Abertura', 'Gloria']));
      expect(cifra.temas, containsAll(['Eucaristia', 'Louvor']));
      expect(cifra.tags, containsAll(['gospel', 'missa']));
      expect(cifra.dataImportacao, DateTime(2026, 11, 24));
    });

    test('estrutura seções e agrupa acordes com a letra', () {
      final cifra = parser.parseCifraMarkdown(_cifraMarkdown);
      expect(cifra.secoes, ['Intro', 'Verso 1', 'Refrão']);

      final intro = cifra.conteudo.first;
      expect(intro.titulo, 'Intro');
      expect(intro.linhas, hasLength(1));
      expect(intro.linhas.first.acordes, 'D  A  Bm  G');
      expect(intro.linhas.first.temTexto, isFalse);

      final verso = cifra.conteudo[1];
      expect(verso.linhas, hasLength(2));
      expect(verso.linhas.first.acordes, 'D            A');
      expect(verso.linhas.first.texto, 'Glória, glória a Deus nas alturas');
      expect(verso.linhas.last.acordes, 'Bm           G');
      expect(verso.linhas.last.texto, 'e paz na terra aos homens');
    });

    test('serializa e relê mantendo os dados principais', () {
      final cifra = parser.parseCifraMarkdown(_cifraMarkdown);
      final markdown = cifra.toMarkdown();
      final recarregada = parser.parseCifraMarkdown(markdown);

      expect(recarregada.titulo, cifra.titulo);
      expect(recarregada.artista, cifra.artista);
      expect(recarregada.tom, cifra.tom);
      expect(recarregada.momentos, cifra.momentos);
      expect(recarregada.temas, cifra.temas);
      expect(recarregada.tags, cifra.tags);
      expect(recarregada.secoes, cifra.secoes);
      expect(markdown, contains('data_importacao: 2026-11-24'));
    });

    test('bodyRaw preserva o conteúdo após o título H1', () {
      final cifra = parser.parseCifraMarkdown(_cifraMarkdown);
      expect(cifra.bodyRaw, contains('[Intro]'));
      expect(cifra.bodyRaw, isNot(contains('# Glória a Deus Nas Alturas')));
      expect(cifra.totalAcordes, greaterThan(10));
    });
  });

  group('parseSetlistMarkdown', () {
    test('lê momentos, notas e status de tocado', () {
      final setlist = parser.parseSetlistMarkdown(
        _setlistMarkdown,
        id: 'ceia_materna',
      );

      expect(setlist.titulo, 'Ceia Materna - 29/11');
      expect(setlist.evento, 'Ceia Materna - Casa Maria');
      expect(setlist.data, DateTime(2026, 11, 29));
      expect(setlist.status.name, 'rascunho');
      expect(setlist.momentos, hasLength(2));

      final abertura = setlist.momentos.first;
      expect(abertura.nome, 'Abertura');
      expect(abertura.itens, hasLength(1));
      expect(abertura.itens.first.cifraId, 'gloria_a_deus');
      expect(abertura.itens.first.nota, 'Versos completos + Refrão x2');
      expect(abertura.itens.first.estaTocado, isTrue);

      expect(setlist.momentos[1].nome, 'Ato Penitencial');
      expect(setlist.totalMusicas, 2);
    });

    test('serializa e relê preservando momentos', () {
      final setlist = parser.parseSetlistMarkdown(_setlistMarkdown);
      final markdown = setlist.toMarkdown();
      final recarregado = parser.parseSetlistMarkdown(markdown);

      expect(recarregado.titulo, setlist.titulo);
      expect(recarregado.evento, setlist.evento);
      expect(recarregado.totalMomentos, setlist.totalMomentos);
      expect(recarregado.totalMusicas, setlist.totalMusicas);
      expect(recarregado.momentos.first.nome, 'Abertura');
      expect(recarregado.momentos.first.itens.first.estaTocado, isTrue);
    });
  });

  group('parseHtmlToCifra', () {
    test('extrai título, artista, tom e corpo de um HTML simples', () async {
      const html = '''
<html>
  <head><title>Minha Canção - Artista Teste - Cifra Club</title></head>
  <body>
    <h1 class="t1">Minha Canção</h1>
    <h2 class="t3"><a>Artista Teste</a></h2>
    <div class="cifra_cnt">
      <pre>Tom: G

[Intro]
G  D  Em  C

[Verso 1]
G            D
Esta é a letra da canção
Em           C
com acordes acima</pre>
    </div>
  </body>
</html>
''';

      final cifra = await parser.parseHtmlToCifra(
        html,
        'https://www.cifraclub.com.br/artista-teste/minha-cancao/',
      );

      expect(cifra, isNotNull);
      expect(cifra!.titulo, 'Minha Canção');
      expect(cifra.artista, 'Artista Teste');
      expect(cifra.tom, 'G');
      expect(cifra.fonte, 'CifraClub');
      expect(cifra.bodyRaw, contains('[Intro]'));
      expect(cifra.hasAcordes, isTrue);
    });
  });

  group('text_utils', () {
    test('slugify e yaml', () {
      expect(slugify('Glória a Deus!'), 'gloria_a_deus');
      expect(slugify('  '), 'sem_titulo');
      expect(yamlValor('Ação'), 'Ação');
      expect(yamlValor('true'), '"true"');
      expect(yamlLista(['a', 'b']), '[a, b]');
      expect(listaYaml('[a, b]'), {'a', 'b'});
    });
  });
}
