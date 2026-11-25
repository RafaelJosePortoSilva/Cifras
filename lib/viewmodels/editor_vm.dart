import '../config/app_config.dart';
import '../models/cifra.dart';
import '../models/metadata_cifra.dart';
import '../services/parser_service.dart';
import '../services/vault_service.dart';
import '../utils/chord_highlight_controller.dart';
import '../utils/text_utils.dart';
import 'base_vm.dart';

/// ViewModel do editor de cifra (corpo + metadados).
class EditorVM extends BaseVM {
  EditorVM({
    required VaultService vault,
    required ParserService parser,
    Cifra? cifra,
  })  : _vault = vault,
        _parser = parser,
        original = cifra,
        titulo = cifra?.titulo ?? '',
        artista = cifra?.artista ?? '',
        tom = cifra?.tom ?? '',
        tipo = cifra?.tipo ?? 'Congregação',
        fonte = cifra?.fonte ?? 'Manual',
        url = cifra?.url ?? '',
        momentos = {...?cifra?.momentos},
        temas = {...?cifra?.temas},
        tags = [...?cifra?.tags] {
    corpo = ChordHighlightController(
      text: cifra?.bodyRaw ?? AppConfig.corpoTemplate,
    );
  }

  final VaultService _vault;
  final ParserService _parser;
  final Cifra? original;

  late final ChordHighlightController corpo;

  String titulo;
  String artista;
  String tom;
  String tipo;
  String fonte;
  String url;
  Set<String> momentos;
  Set<String> temas;
  List<String> tags;

  bool salvando = false;
  String? erro;
  Cifra? cifraSalva;

  String? _idSalvo;
  String? _caminhoSalvo;

  bool get editando => original != null;

  MetadataCifraDados get metadados => MetadataCifraDados(
        titulo: titulo,
        artista: artista,
        tom: tom,
        tipo: tipo,
        fonte: fonte,
        url: url,
        momentos: momentos,
        temas: temas,
        tags: tags,
      );

  void aplicarMetadados(MetadataCifraDados dados) {
    titulo = dados.titulo.trim();
    artista = dados.artista.trim();
    tom = dados.tom.trim();
    tipo = dados.tipo;
    fonte = dados.fonte;
    url = dados.url.trim();
    momentos = {...dados.momentos};
    temas = {...dados.temas};
    tags = [...dados.tags];
    notificar();
  }

  String _montarMarkdown() {
    final dataImportacao =
        original?.dataImportacao ?? DateTime.now();
    final buffer = StringBuffer()
      ..writeln('---')
      ..writeln('titulo: ${yamlValor(titulo)}')
      ..writeln('artista: ${yamlValor(artista)}')
      ..writeln('fonte: ${yamlValor(fonte)}')
      ..writeln('url: ${yamlValor(url)}')
      ..writeln('tom: ${yamlValor(tom)}')
      ..writeln('momentos: ${yamlLista(momentos)}')
      ..writeln('temas: ${yamlLista(temas)}')
      ..writeln('tipo: ${yamlValor(tipo)}')
      ..writeln('data_importacao: ${formatarDataIso(dataImportacao)}')
      ..writeln('tags: ${yamlLista(tags)}')
      ..writeln('---')
      ..writeln()
      ..writeln('# $titulo${artista.isEmpty ? '' : ' - $artista'}')
      ..writeln()
      ..write(corpo.text.trimRight());

    return buffer.toString();
  }

  Future<Cifra?> salvar() async {
    if (titulo.trim().isEmpty) {
      erro = 'Informe o título da cifra antes de salvar.';
      notificar();
      return null;
    }
    if (corpo.text.trim().isEmpty) {
      erro = 'A cifra está vazia. Adicione acordes e/ou letra.';
      notificar();
      return null;
    }

    salvando = true;
    erro = null;
    notificar();

    try {
      final id = _idSalvo ??
          original?.id ??
          await _vault.gerarIdUnico(titulo);
      final caminhoAnterior = _caminhoSalvo ?? original?.caminho;
      final base = _parser.parseCifraMarkdown(
        _montarMarkdown(),
        id: id,
        caminho: caminhoAnterior,
      );
      final caminho = await _vault.salvarCifra(base);
      final salva = base.copyWith(caminho: caminho);
      _idSalvo = id;
      _caminhoSalvo = caminho;
      cifraSalva = salva;
      return salva;
    } catch (falha) {
      erro = 'Não foi possível salvar a cifra.\n$falha';
      return null;
    } finally {
      salvando = false;
      notificar();
    }
  }

  @override
  void dispose() {
    corpo.dispose();
    super.dispose();
  }
}
