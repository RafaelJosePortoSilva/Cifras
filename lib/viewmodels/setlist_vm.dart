import '../config/app_config.dart';
import '../models/cifra.dart';
import '../models/setlist.dart';
import '../services/pdf_service.dart';
import '../services/vault_service.dart';
import '../utils/text_utils.dart';
import 'base_vm.dart';

/// ViewModel da lista de setlists.
class SetlistVM extends BaseVM {
  SetlistVM({required VaultService vault}) : _vault = vault;

  final VaultService _vault;

  List<Setlist> setlists = const <Setlist>[];
  List<Cifra> cifras = const <Cifra>[];
  bool carregando = true;
  String? erro;

  bool _ocupado = false;

  Future<void> carregar() async {
    if (_ocupado) return;
    _ocupado = true;
    carregando = true;
    notificar();
    try {
      cifras = await _vault.carregarCifras();
      setlists = await _vault.carregarSetlists();
      erro = null;
    } catch (falha) {
      erro = 'Não foi possível carregar os setlists.\n$falha';
    } finally {
      carregando = false;
      _ocupado = false;
      notificar();
    }
  }

  Future<void> deletar(Setlist setlist) async {
    final caminho = setlist.caminho;
    if (caminho != null && caminho.isNotEmpty) {
      await _vault.deletar(caminho);
    }
    await carregar();
  }

  Map<String, Cifra?> resolver(Setlist setlist) =>
      setlist.resolverCifras(cifras);

  Cifra? cifraPorId(String id) {
    for (final cifra in cifras) {
      if (cifra.id == id) return cifra;
    }
    return null;
  }
}

/// ViewModel de criação/edição de um setlist, com momentos e músicas.
class SetlistEditorVM extends BaseVM {
  SetlistEditorVM({
    required VaultService vault,
    required PdfService pdf,
    Setlist? setlist,
  })  : _vault = vault,
        _pdf = pdf,
        original = setlist,
        titulo = setlist?.titulo ?? '',
        evento = setlist?.evento ?? '',
        diaLiturgico = setlist?.diaLiturgico ?? '',
        dataEvento = setlist?.data ?? DateTime.now(),
        criadoEm = setlist?.criadoEm ?? DateTime.now(),
        status = setlist?.status ?? SetlistStatus.rascunho,
        momentos = setlist == null
            ? <MomentoLiturgo>[]
            : setlist.momentos
                .map((momento) => momento.copiar())
                .toList();

  final VaultService _vault;
  final PdfService _pdf;
  final Setlist? original;

  String titulo;
  String evento;
  String diaLiturgico;
  DateTime dataEvento;
  DateTime criadoEm;
  SetlistStatus status;
  List<MomentoLiturgo> momentos;

  List<Cifra> cifrasDisponiveis = const <Cifra>[];
  bool carregando = true;
  bool salvando = false;
  String? erro;
  Setlist? setlistSalva;

  String? _idSalvo;
  String? _caminhoSalvo;

  bool get editando => original != null;
  int get totalMusicas =>
      momentos.fold(0, (total, momento) => total + momento.itens.length);

  Map<String, Cifra?> get mapaCifras =>
      {for (final cifra in cifrasDisponiveis) cifra.id: cifra};

  Cifra? cifraPorId(String id) => mapaCifras[id];

  Future<void> carregar() async {
    carregando = true;
    notificar();
    try {
      cifrasDisponiveis = await _vault.carregarCifras();
      erro = null;
    } catch (falha) {
      erro = 'Não foi possível carregar a biblioteca.\n$falha';
    } finally {
      carregando = false;
      notificar();
    }
  }

  void definirTitulo(String valor) {
    titulo = valor;
  }

  void definirEvento(String valor) {
    evento = valor;
  }

  void definirDiaLiturgico(String valor) {
    diaLiturgico = valor;
    notificar();
  }

  void definirData(DateTime valor) {
    dataEvento = valor;
    notificar();
  }

  void definirStatus(SetlistStatus valor) {
    status = valor;
    notificar();
  }

  /// Adiciona um momento (ignora duplicados e nomes vazios).
  bool adicionarMomento(String nome) {
    final limpo = nome.trim();
    if (limpo.isEmpty) return false;
    final existe = momentos.any(
      (momento) => normalizarTexto(momento.nome) == normalizarTexto(limpo),
    );
    if (existe) return false;
    momentos.add(MomentoLiturgo(nome: limpo));
    notificar();
    return true;
  }

  void removerMomento(int indice) {
    if (indice < 0 || indice >= momentos.length) return;
    momentos.removeAt(indice);
    notificar();
  }

  void moverMomento(int indice, int delta) {
    final destino = indice + delta;
    if (indice < 0 ||
        indice >= momentos.length ||
        destino < 0 ||
        destino >= momentos.length) {
      return;
    }
    final momento = momentos.removeAt(indice);
    momentos.insert(destino, momento);
    notificar();
  }

  void adicionarCifra(int indiceMomento, Cifra cifra) {
    if (indiceMomento < 0 || indiceMomento >= momentos.length) return;
    momentos[indiceMomento].itens.add(ItemSetlist(cifraId: cifra.id));
    notificar();
  }

  void removerItem(int indiceMomento, int indiceItem) {
    if (indiceMomento < 0 || indiceMomento >= momentos.length) return;
    final itens = momentos[indiceMomento].itens;
    if (indiceItem < 0 || indiceItem >= itens.length) return;
    itens.removeAt(indiceItem);
    notificar();
  }

  void moverItem(int indiceMomento, int indiceItem, int delta) {
    if (indiceMomento < 0 || indiceMomento >= momentos.length) return;
    final itens = momentos[indiceMomento].itens;
    final destino = indiceItem + delta;
    if (indiceItem < 0 ||
        indiceItem >= itens.length ||
        destino < 0 ||
        destino >= itens.length) {
      return;
    }
    final item = itens.removeAt(indiceItem);
    itens.insert(destino, item);
    notificar();
  }

  void atualizarNota(int indiceMomento, int indiceItem, String nota) {
    if (indiceMomento < 0 || indiceMomento >= momentos.length) return;
    final itens = momentos[indiceMomento].itens;
    if (indiceItem < 0 || indiceItem >= itens.length) return;
    itens[indiceItem] = itens[indiceItem].copyWith(nota: nota);
    notificar();
  }

  void alternarTocado(int indiceMomento, int indiceItem, bool valor) {
    if (indiceMomento < 0 || indiceMomento >= momentos.length) return;
    final itens = momentos[indiceMomento].itens;
    if (indiceItem < 0 || indiceItem >= itens.length) return;
    itens[indiceItem] = itens[indiceItem].copyWith(estaTocado: valor);
    notificar();
  }

  Setlist construirSetlist({String? id, String? caminho}) {
    final tituloFinal =
        titulo.trim().isEmpty ? 'Novo setlist' : titulo.trim();
    return Setlist(
      id: id ?? _idSalvo ?? original?.id ?? slugify(tituloFinal),
      titulo: tituloFinal,
      evento: evento.trim(),
      data: dataEvento,
      diaLiturgico: diaLiturgico,
      criadoEm: criadoEm,
      status: status,
      momentos: momentos.map((momento) => momento.copiar()).toList(),
      caminho: caminho ?? _caminhoSalvo ?? original?.caminho,
    );
  }

  Future<Setlist?> salvar() async {
    if (titulo.trim().isEmpty) {
      erro = 'Informe um título para o setlist.';
      notificar();
      return null;
    }

    salvando = true;
    erro = null;
    notificar();

    try {
      final id = _idSalvo ??
          original?.id ??
          await _vault.gerarIdUnico(
            titulo,
            pasta: AppConfig.vaultSubDirSetlists,
          );
      final setlist = construirSetlist(id: id);
      final caminho = await _vault.salvarSetlist(setlist);
      final salva = setlist.copyWith(caminho: caminho);
      _idSalvo = id;
      _caminhoSalvo = caminho;
      setlistSalva = salva;
      return salva;
    } catch (falha) {
      erro = 'Não foi possível salvar o setlist.\n$falha';
      return null;
    } finally {
      salvando = false;
      notificar();
    }
  }

  String get textoCompartilhavel =>
      _pdf.textoSetlist(construirSetlist(), mapaCifras);

  Future<void> compartilharPdf() async {
    final setlist = construirSetlist();
    final arquivo = await _pdf.gerarPdfSetlist(
      setlist,
      cifras: mapaCifras,
    );
    await _pdf.compartilharPdf(arquivo);
  }
}
