import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import '../models/cifra.dart';
import '../models/setlist.dart';
import '../utils/text_utils.dart';
import 'parser_service.dart';

/// CRUD dos arquivos Markdown do vault (cifras e setlists).
///
/// Não há banco de dados: toda leitura/escrita acontece diretamente nos
/// arquivos `.md`. As pastas são criadas automaticamente quando necessário.
class VaultService {
  VaultService({ParserService? parser, String? vaultPath})
      : _parser = parser ?? ParserService(),
        _caminhoForcado = vaultPath;

  final ParserService _parser;
  final String? _caminhoForcado;

  String? _cacheCaminho;
  String? _ultimoErro;

  String? get ultimoErro => _ultimoErro;

  /// Caminho atual do vault (cria as pastas se ainda não existirem).
  Future<String> obterVaultPath() async {
    final cache = _cacheCaminho;
    if (cache != null) return cache;

    String caminho;
    final forcado = _caminhoForcado?.trim() ?? '';
    if (forcado.isNotEmpty) {
      caminho = forcado;
    } else {
      final prefs = await SharedPreferences.getInstance();
      final salvo = prefs.getString(AppConfig.prefVaultPath)?.trim() ?? '';
      if (salvo.isNotEmpty) {
        caminho = salvo;
      } else {
        final documentos = await getApplicationDocumentsDirectory();
        caminho = p.join(documentos.path, AppConfig.appName);
      }
    }

    _cacheCaminho = caminho;
    await _garantirPastas();
    return caminho;
  }

  /// Define uma nova pasta para o vault (persistida em SharedPreferences).
  ///
  /// Aceita tanto a raiz do vault (contendo `cifras/` e `setlists/`) quanto
  /// uma das subpastas ou uma pasta com arquivos `.md` diretamente.
  Future<void> definirVaultPath(String caminho) async {
    final limpo = await _normalizarCaminhoVault(caminho.trim());
    if (limpo.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConfig.prefVaultPath, limpo);
    _cacheCaminho = limpo;
    await _garantirPastas();
  }

  /// Normaliza o caminho escolhido para a raiz do vault.
  ///
  /// - Se o usuário escolheu `.../cifras` ou `.../setlists`, usa a pasta pai.
  /// - Se a pasta contém `.md` diretamente (sem subpastas do vault), usa a
  ///   própria pasta como raiz e os `.md` serão lidos da subpasta `cifras/`
  ///   criada automaticamente; nesse caso também tentamos detectar a raiz pai.
  Future<String> _normalizarCaminhoVault(String caminho) async {
    if (caminho.isEmpty) return caminho;
    var dir = Directory(caminho);
    if (!await dir.exists()) return caminho;

    final nome = p.basename(caminho).toLowerCase();
    if (nome == AppConfig.vaultSubDirCifras ||
        nome == AppConfig.vaultSubDirSetlists) {
      return p.dirname(caminho);
    }

    final temCifras =
        await Directory(p.join(caminho, AppConfig.vaultSubDirCifras)).exists();
    final temSetlists =
        await Directory(p.join(caminho, AppConfig.vaultSubDirSetlists)).exists();
    if (temCifras || temSetlists) return caminho;

    // Pasta sem estrutura de vault: se tiver .md, pode ser a pasta de cifras.
    final temMdNaRaiz = await _contemMarkdown(dir);
    if (temMdNaRaiz) {
      // Mantém a pasta escolhida como raiz; carregarCifras fará fallback.
      return caminho;
    }

    return caminho;
  }

  Future<bool> _contemMarkdown(Directory dir) async {
    try {
      await for (final entidade in dir.list(followLinks: false)) {
        if (entidade is File && entidade.path.toLowerCase().endsWith('.md')) {
          return true;
        }
      }
    } catch (_) {}
    return false;
  }

  /// Volta a usar a pasta padrão do app (documentos/CifraVault).
  Future<String> usarVaultPadrao() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConfig.prefVaultPath);
    final documentos = await getApplicationDocumentsDirectory();
    _cacheCaminho = p.join(documentos.path, AppConfig.appName);
    await _garantirPastas();
    return _cacheCaminho!;
  }

  Future<void> _garantirPastas() async {
    final base = _cacheCaminho;
    if (base == null) return;
    for (final subpasta in const [
      AppConfig.vaultSubDirCifras,
      AppConfig.vaultSubDirSetlists,
    ]) {
      await Directory(p.join(base, subpasta)).create(recursive: true);
    }
  }

  Future<Directory> _pasta(String subpasta) async {
    if (p.isAbsolute(subpasta)) return Directory(subpasta);
    final vault = await obterVaultPath();
    return Directory(p.join(vault, subpasta));
  }

  /// Lista os arquivos `.md` de uma subpasta (`cifras`, `setlists`) ou de um
  /// caminho absoluto.
  Future<List<File>> listarArquivos(String pasta) async {
    final diretorio = await _pasta(pasta);
    if (!await diretorio.exists()) {
      try {
        await diretorio.create(recursive: true);
      } catch (erro) {
        _registrarErro('Não foi possível criar ${diretorio.path}: $erro');
      }
      return <File>[];
    }

    final arquivos = <File>[];
    try {
      await for (final entidade in diretorio.list(followLinks: false)) {
        if (entidade is File && entidade.path.toLowerCase().endsWith('.md')) {
          arquivos.add(entidade);
        }
      }
    } catch (erro) {
      _registrarErro('Não foi possível listar ${diretorio.path}: $erro');
      return <File>[];
    }
    arquivos.sort(
      (a, b) => p
          .basename(a.path)
          .toLowerCase()
          .compareTo(p.basename(b.path).toLowerCase()),
    );
    return arquivos;
  }

  Future<Cifra> lerCifra(String caminho) async {
    final conteudo = await _lerTexto(File(caminho));
    return _parser.parseCifraMarkdown(
      conteudo,
      id: p.basenameWithoutExtension(caminho),
      caminho: caminho,
    );
  }

  Future<Setlist> lerSetlist(String caminho) async {
    final conteudo = await _lerTexto(File(caminho));
    return _parser.parseSetlistMarkdown(
      conteudo,
      id: p.basenameWithoutExtension(caminho),
      caminho: caminho,
    );
  }

  /// Salva a cifra e devolve o caminho completo do arquivo.
  Future<String> salvarCifra(Cifra cifra) async {
    final pasta = await _pasta(AppConfig.vaultSubDirCifras);
    await pasta.create(recursive: true);

    final idBruto = cifra.id.trim().isEmpty ? cifra.titulo : cifra.id;
    final id = slugify(idBruto);
    final caminhoExistente = cifra.caminho?.trim() ?? '';
    final caminho = caminhoExistente.isNotEmpty
        ? caminhoExistente
        : p.join(pasta.path, '$id.md');

    final arquivo = File(caminho);
    await arquivo.parent.create(recursive: true);
    await arquivo.writeAsString(cifra.toMarkdown(), flush: true);
    return caminho;
  }

  /// Salva o setlist e devolve o caminho completo do arquivo.
  Future<String> salvarSetlist(Setlist setlist) async {
    final pasta = await _pasta(AppConfig.vaultSubDirSetlists);
    await pasta.create(recursive: true);

    final idBruto = setlist.id.trim().isEmpty ? setlist.titulo : setlist.id;
    final id = slugify(idBruto);
    final caminhoExistente = setlist.caminho?.trim() ?? '';
    final caminho = caminhoExistente.isNotEmpty
        ? caminhoExistente
        : p.join(pasta.path, '$id.md');

    final arquivo = File(caminho);
    await arquivo.parent.create(recursive: true);
    await arquivo.writeAsString(setlist.toMarkdown(), flush: true);
    return caminho;
  }

  Future<void> deletar(String caminho) async {
    final arquivo = File(caminho);
    if (await arquivo.exists()) {
      await arquivo.delete();
    }
  }

  /// Carrega todas as cifras do vault.
  ///
  /// Se a subpasta `cifras/` estiver vazia, também procura `.md` diretamente na
  /// raiz do vault (fallback para pastas selecionadas sem a estrutura padrão).
  Future<List<Cifra>> carregarCifras() async {
    _ultimoErro = null;
    final caminhoVault = await obterVaultPath();
    var arquivos = await listarArquivos(AppConfig.vaultSubDirCifras);
    if (arquivos.isEmpty) {
      arquivos = await _listarMarkdownDireto(Directory(caminhoVault));
    }
    final cifras = <Cifra>[];

    for (final arquivo in arquivos) {
      try {
        cifras.add(await lerCifra(arquivo.path));
      } catch (erro) {
        _registrarErro('Falha ao ler ${p.basename(arquivo.path)}: $erro');
      }
    }

    cifras.sort(
      (a, b) => normalizarTexto(a.titulo).compareTo(normalizarTexto(b.titulo)),
    );
    if (cifras.isEmpty) {
      final msg = _ultimoErro;
      if (msg != null && msg.isNotEmpty) {
        _ultimoErro =
            '$msg\nPasta do vault: $caminhoVault';
      } else {
        _ultimoErro =
            'Nenhum arquivo .md encontrado em $caminhoVault '
            '(ou em ${p.join(caminhoVault, AppConfig.vaultSubDirCifras)}). '
            'Verifique a pasta selecionada e as permissões de acesso.';
      }
    }
    return cifras;
  }

  /// Lista `.md` diretamente em um diretório (sem recursão em subpastas de vault).
  Future<List<File>> _listarMarkdownDireto(Directory diretorio) async {
    if (!await diretorio.exists()) return <File>[];
    final arquivos = <File>[];
    await for (final entidade in diretorio.list(followLinks: false)) {
      if (entidade is File && entidade.path.toLowerCase().endsWith('.md')) {
        arquivos.add(entidade);
      }
    }
    arquivos.sort(
      (a, b) => p
          .basename(a.path)
          .toLowerCase()
          .compareTo(p.basename(b.path).toLowerCase()),
    );
    return arquivos;
  }

  /// Carrega todos os setlists do vault.
  Future<List<Setlist>> carregarSetlists() async {
    var arquivos = await listarArquivos(AppConfig.vaultSubDirSetlists);
    if (arquivos.isEmpty) {
      final raiz = await obterVaultPath();
      // fallback: .md na raiz que pareçam setlist (contêm "momentos" ou "data:")
      final candidatos = await _listarMarkdownDireto(Directory(raiz));
      for (final f in candidatos) {
        try {
          final txt = await _lerTexto(f);
          if (txt.contains('momentos:') || txt.contains('tipo:')) {
            arquivos.add(f);
          }
        } catch (_) {}
      }
    }
    final setlists = <Setlist>[];

    for (final arquivo in arquivos) {
      try {
        setlists.add(await lerSetlist(arquivo.path));
      } catch (erro) {
        _registrarErro('Falha ao ler ${p.basename(arquivo.path)}: $erro');
      }
    }

    setlists.sort((a, b) => b.data.compareTo(a.data));
    return setlists;
  }

  /// Busca por prefixo/substring no título, artista ou tags.
  Future<List<Cifra>> buscarPorNome(String query) async {
    final alvo = normalizarTexto(query);
    final cifras = await carregarCifras();
    if (alvo.isEmpty) return cifras;
    return cifras
        .where(
          (cifra) => normalizarTexto(
            '${cifra.titulo} ${cifra.artista} ${cifra.tags.join(' ')}',
          ).contains(alvo),
        )
        .toList();
  }

  /// Gera um id/nome de arquivo ainda não utilizado.
  Future<String> gerarIdUnico(
    String titulo, {
    String pasta = AppConfig.vaultSubDirCifras,
  }) async {
    final diretorio = await _pasta(pasta);
    await diretorio.create(recursive: true);

    final base = slugify(titulo.trim().isEmpty ? 'sem_titulo' : titulo);
    var id = base;
    var contador = 2;
    while (await File(p.join(diretorio.path, '$id.md')).exists()) {
      id = '${base}_$contador';
      contador++;
    }
    return id;
  }

  /// Observa o vault por mudanças (polling com assinatura de arquivos).
  ///
  /// `Directory.watch` não funciona de forma consistente no Android, então
  /// usamos uma comparação de nome/tamanho/data de modificação.
  Stream<List<Cifra>> ouvirMudancas({
    Duration intervalo = const Duration(seconds: 5),
  }) async* {
    String? assinaturaAnterior;
    while (true) {
      try {
        final assinatura = await _assinaturaCifras();
        if (assinatura != assinaturaAnterior) {
          assinaturaAnterior = assinatura;
          yield await carregarCifras();
        }
      } catch (erro) {
        _registrarErro('Falha ao observar o vault: $erro');
      }
      await Future<void>.delayed(intervalo);
    }
  }

  Future<String> _assinaturaCifras() async {
    final arquivos = await listarArquivos(AppConfig.vaultSubDirCifras);
    final partes = <String>[];
    for (final arquivo in arquivos) {
      final info = await arquivo.stat();
      partes.add(
        '${arquivo.path}|${info.modified.millisecondsSinceEpoch}|${info.size}',
      );
    }
    return partes.join(';');
  }

  Future<String> _lerTexto(File arquivo) async {
    final bytes = await arquivo.readAsBytes();
    try {
      return utf8.decode(bytes);
    } on FormatException {
      return latin1.decode(bytes);
    }
  }

  void _registrarErro(String mensagem) {
    _ultimoErro = mensagem;
    developer.log(mensagem, name: 'CifraVault.VaultService');
  }
}
