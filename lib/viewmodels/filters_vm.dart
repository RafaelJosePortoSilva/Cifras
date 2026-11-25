import '../models/filtros.dart';
import '../services/search_service.dart';
import 'base_vm.dart';

/// ViewModel da tela/modal de filtros combinados.
class FiltersVM extends BaseVM {
  FiltersVM({required SearchService search, FiltrosCifra? inicial})
      : _search = search,
        filtros = inicial?.clonar() ?? FiltrosCifra();

  final SearchService _search;
  FiltrosCifra filtros;

  int get totalAtivos => filtros.totalAtivos;

  Set<String> get momentosDisponiveis => _search.obterMomentosDisponiveis();
  Set<String> get temasDisponiveis => _search.obterTemasDisponiveis();
  Set<String> get tonsDisponiveis => _search.obterTonsDisponiveis();
  Set<String> get tiposDisponiveis => _search.obterTiposDisponiveis();
  Set<String> get fontesDisponiveis => _search.obterFontesDisponiveis();

  void alternarMomento(String valor) {
    _alternar(filtros.momentos, valor);
    notificar();
  }

  void alternarTema(String valor) {
    _alternar(filtros.temas, valor);
    notificar();
  }

  void alternarTom(String valor) {
    _alternar(filtros.tons, valor);
    notificar();
  }

  void alternarFonte(String valor) {
    _alternar(filtros.fontes, valor);
    notificar();
  }

  void selecionarTipo(String valor) {
    filtros.tipo = filtros.tipo == valor ? null : valor;
    notificar();
  }

  void limpar() {
    filtros.limpar();
    notificar();
  }

  void _alternar(Set<String> conjunto, String valor) {
    if (conjunto.contains(valor)) {
      conjunto.remove(valor);
    } else {
      conjunto.add(valor);
    }
  }
}
