/// Filtros combináveis da biblioteca.
///
/// A classe é mutável de propósito para simplificar o binding com os chips da
/// tela de filtros; use [clonar] antes de aplicar para não alterar o estado
/// exibido.
class FiltrosCifra {
  FiltrosCifra({
    this.termo = '',
    Set<String>? momentos,
    Set<String>? temas,
    Set<String>? tons,
    this.tipo,
    Set<String>? fontes,
  })  : momentos = {...?momentos},
        temas = {...?temas},
        tons = {...?tons},
        fontes = {...?fontes};

  String termo;
  Set<String> momentos;
  Set<String> temas;
  Set<String> tons;
  String? tipo;
  Set<String> fontes;

  bool get vazio => totalAtivos == 0;

  int get totalAtivos =>
      momentos.length +
      temas.length +
      tons.length +
      fontes.length +
      (tipo == null || tipo!.isEmpty ? 0 : 1);

  FiltrosCifra clonar() => FiltrosCifra(
        termo: termo,
        momentos: momentos,
        temas: temas,
        tons: tons,
        tipo: tipo,
        fontes: fontes,
      );

  void limpar() {
    momentos.clear();
    temas.clear();
    tons.clear();
    fontes.clear();
    tipo = null;
  }

  /// Rótulos exibidos no resumo de filtros ativos.
  List<String> get rotulosAtivos => [
        ...momentos,
        ...temas,
        ...tons.map((t) => 'Tom $t'),
        ...fontes,
        if (tipo != null && tipo!.isNotEmpty) tipo!,
      ];

  /// Filtros pré-aplicados para abrir a biblioteca a partir de um momento.
  factory FiltrosCifra.paraMomento(String momento) =>
      FiltrosCifra(momentos: {momento});

  /// Lista de opções padrão usada para popular os filtros quando o vault está
  /// vazio ou ainda carregando.
  static List<String> opcoesPadrao(Set<String> disponiveis, List<String> padrao) {
    final opcoes = <String>{...padrao, ...disponiveis, if (disponiveis.isEmpty) ...padrao};
    opcoes.removeWhere((e) => e.trim().isEmpty);
    return opcoes.toList()..sort();
  }
}
