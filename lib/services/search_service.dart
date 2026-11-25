import '../config/app_config.dart';
import '../models/cifra.dart';
import '../utils/chord_utils.dart';
import '../utils/text_utils.dart';

class _CifraIndex {
  _CifraIndex(this.cifra)
      : busca = normalizarTexto(
          '${cifra.titulo} ${cifra.artista} ${cifra.tags.join(' ')}',
        ),
        tituloNormalizado = normalizarTexto(cifra.titulo),
        tom = (cifra.tom ?? '').trim(),
        tipo = cifra.tipo.trim().toLowerCase(),
        fonte = (cifra.fonte ?? '').trim().toLowerCase();

  final Cifra cifra;
  final String busca;
  final String tituloNormalizado;
  final String tom;
  final String tipo;
  final String fonte;
}

/// Índice em memória e busca multi-critério das cifras do vault.
///
/// Pré-normaliza campos de busca e facetas ao carregar a pasta, evitando
/// normalização repetida durante digitação/filtros.
class SearchService {
  List<_CifraIndex> _indice = const <_CifraIndex>[];
  List<Cifra> _cifras = const <Cifra>[];

  Set<String> _tiposDisponiveis = <String>{...AppConfig.tiposMusica};
  Set<String> _tonsDisponiveis = <String>{...AppConfig.tonsDisponiveis};
  Set<String> _temasDisponiveis = <String>{...AppConfig.temasLiturgicos};
  Set<String> _fontesDisponiveis = <String>{...AppConfig.fontesDisponiveis};
  Set<String> _momentosDisponiveis = <String>{...AppConfig.momentosLiturgicos};

  List<Cifra> get todas => _cifras;

  /// Indexa a lista de cifras em memória.
  void atualizar(List<Cifra> cifras) {
    _cifras = List<Cifra>.unmodifiable(cifras);
    _indice = cifras.map(_CifraIndex.new).toList(growable: false);
    _reconstruirFacetas();
  }

  /// Busca combinando termo textual, momentos, tons, temas, tipo e fontes.
  Future<List<Cifra>> buscar({
    String? termo,
    Set<String>? momentos,
    Set<String>? temas,
    Set<String>? tons,
    String? tom,
    String? tipo,
    Set<String>? fontes,
    String? fonte,
  }) async {
    return buscarSync(
      termo: termo,
      momentos: momentos,
      temas: temas,
      tons: tons,
      tom: tom,
      tipo: tipo,
      fontes: fontes,
      fonte: fonte,
    );
  }

  /// Busca síncrona sobre o índice já carregado.
  List<Cifra> buscarSync({
    String? termo,
    Set<String>? momentos,
    Set<String>? temas,
    Set<String>? tons,
    String? tom,
    String? tipo,
    Set<String>? fontes,
    String? fonte,
  }) {
    final alvo = normalizarTexto(termo ?? '');

    final tonsEfetivos = <String>{
      ...?tons,
      if (tom != null && tom.trim().isNotEmpty) tom.trim(),
    };
    final fontesEfetivas = <String>{
      ...?fontes,
      if (fonte != null && fonte.trim().isNotEmpty) fonte.trim().toLowerCase(),
    };
    final momentosEfetivos = momentos ?? const <String>{};
    final temasEfetivos = temas ?? const <String>{};
    final tipoNormalizado = (tipo ?? '').trim().toLowerCase();

    final resultado = <_CifraIndex>[];
    for (final item in _indice) {
      final cifra = item.cifra;
      if (alvo.isNotEmpty && !item.busca.contains(alvo)) continue;
      if (momentosEfetivos.isNotEmpty &&
          !momentosEfetivos.every(cifra.momentos.contains)) {
        continue;
      }
      if (temasEfetivos.isNotEmpty &&
          !temasEfetivos.any(cifra.temas.contains)) {
        continue;
      }
      if (tonsEfetivos.isNotEmpty && !tonsEfetivos.contains(item.tom)) {
        continue;
      }
      if (tipoNormalizado.isNotEmpty && item.tipo != tipoNormalizado) {
        continue;
      }
      if (fontesEfetivas.isNotEmpty && !fontesEfetivas.contains(item.fonte)) {
        continue;
      }
      resultado.add(item);
    }

    resultado.sort((a, b) => a.tituloNormalizado.compareTo(b.tituloNormalizado));
    return resultado.map((e) => e.cifra).toList(growable: false);
  }

  Set<String> obterTiposDisponiveis() => _tiposDisponiveis;
  Set<String> obterTonsDisponiveis() => _tonsDisponiveis;
  Set<String> obterTemasDisponiveis() => _temasDisponiveis;
  Set<String> obterFontesDisponiveis() => _fontesDisponiveis;
  Set<String> obterMomentosDisponiveis() => _momentosDisponiveis;

  void _reconstruirFacetas() {
    _tiposDisponiveis = _unir(
      AppConfig.tiposMusica,
      _cifras.map((cifra) => cifra.tipo),
    );

    final tons = <String>{
      ...AppConfig.tonsDisponiveis,
      ..._cifras.map((cifra) => cifra.tom).whereType<String>(),
      ..._cifras
          .map((cifra) => cifra.tom)
          .whereType<String>()
          .map((tom) => transporAcorde(tom, 0)),
    }..removeWhere((tom) => tom.trim().isEmpty);
    final listaTons = tons.toList()..sort(_compararTons);
    _tonsDisponiveis = listaTons.toSet();

    _temasDisponiveis = _unir(
      AppConfig.temasLiturgicos,
      _cifras.expand((cifra) => cifra.temas),
    );
    _fontesDisponiveis = _unir(
      AppConfig.fontesDisponiveis,
      _cifras.map((cifra) => cifra.fonte).whereType<String>(),
    );
    _momentosDisponiveis = _unir(
      AppConfig.momentosLiturgicos,
      _cifras.expand((cifra) => cifra.momentos),
    );
  }

  Set<String> _unir(List<String> padrao, Iterable<String> extras) {
    final conjunto = <String>{};
    for (final item in [...padrao, ...extras]) {
      final limpo = item.trim();
      if (limpo.isNotEmpty) conjunto.add(limpo);
    }
    return conjunto;
  }

  int _compararTons(String a, String b) {
    const ordem = [
      'C',
      'C#',
      'Db',
      'D',
      'D#',
      'Eb',
      'E',
      'F',
      'F#',
      'Gb',
      'G',
      'G#',
      'Ab',
      'A',
      'A#',
      'Bb',
      'B',
    ];
    final indiceA = ordem.indexOf(a);
    final indiceB = ordem.indexOf(b);
    if (indiceA == -1 && indiceB == -1) return a.compareTo(b);
    if (indiceA == -1) return 1;
    if (indiceB == -1) return -1;
    return indiceA.compareTo(indiceB);
  }
}
