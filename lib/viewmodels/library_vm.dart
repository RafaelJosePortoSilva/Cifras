import 'dart:async';

import '../models/cifra.dart';
import '../models/filtros.dart';
import '../services/search_service.dart';
import '../services/vault_service.dart';
import 'base_vm.dart';

/// ViewModel da tela principal (biblioteca).
class LibraryVM extends BaseVM {
  LibraryVM({
    required VaultService vault,
    required SearchService search,
  })  : _vault = vault,
        _search = search;

  Timer? _debounceBusca;

  final VaultService _vault;
  final SearchService _search;

  List<Cifra> cifras = const <Cifra>[];
  List<Cifra> resultados = const <Cifra>[];
  FiltrosCifra filtros = FiltrosCifra();
  bool carregando = true;
  String? erro;

  bool _ocupado = false;

  int get totalCifras => cifras.length;
  int get filtrosAtivos => filtros.totalAtivos;
  SearchService get search => _search;

  Future<void> carregar({bool silencioso = false}) async {
    if (_ocupado) return;
    _ocupado = true;
    if (!silencioso) {
      carregando = true;
      notificar();
    }

    try {
      cifras = await _vault.carregarCifras();
      _search.atualizar(cifras);
      final msgVault = _vault.ultimoErro;
      erro = cifras.isEmpty ? msgVault : null;
      _aplicar();
    } catch (falha) {
      erro = 'Não foi possível ler o vault.\n$falha';
    } finally {
      carregando = false;
      _ocupado = false;
      notificar();
    }
  }

  void atualizarTermo(String termo) {
    filtros.termo = termo;
    _debounceBusca?.cancel();
    _debounceBusca = Timer(const Duration(milliseconds: 180), _aplicar);
  }

  void aplicarFiltros(FiltrosCifra novos) {
    _debounceBusca?.cancel();
    final termoAtual = filtros.termo;
    filtros = novos.clonar()..termo = termoAtual;
    _aplicar();
  }

  void limparFiltros() {
    _debounceBusca?.cancel();
    final termoAtual = filtros.termo;
    filtros = FiltrosCifra(termo: termoAtual);
    _aplicar();
  }

  void _aplicar() {
    resultados = _search.buscarSync(
      termo: filtros.termo,
      momentos: filtros.momentos,
      temas: filtros.temas,
      tons: filtros.tons,
      tipo: filtros.tipo,
      fontes: filtros.fontes,
    );
    notificar();
  }

  Cifra? cifraPorId(String id) {
    for (final cifra in cifras) {
      if (cifra.id == id) return cifra;
    }
    return null;
  }

  @override
  void dispose() {
    _debounceBusca?.cancel();
    super.dispose();
  }

  Set<String> get momentosDisponiveis => _search.obterMomentosDisponiveis();
  Set<String> get temasDisponiveis => _search.obterTemasDisponiveis();
  Set<String> get tonsDisponiveis => _search.obterTonsDisponiveis();
  Set<String> get tiposDisponiveis => _search.obterTiposDisponiveis();
  Set<String> get fontesDisponiveis => _search.obterFontesDisponiveis();
}
