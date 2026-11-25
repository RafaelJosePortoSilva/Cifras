import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

import '../config/app_config.dart';
import '../models/cifra.dart';
import '../models/metadata_cifra.dart';
import '../services/parser_service.dart';
import '../services/vault_service.dart';
import '../viewmodels/download_vm.dart';
import 'widgets/chord_display.dart';
import 'widgets/filtro_chip.dart';
import 'widgets/metadata_form.dart';

/// Importação de cifras por link, HTML colado ou arquivo `.md` local.
class ImportView extends StatefulWidget {
  const ImportView({super.key, this.urlInicial});

  /// URL recebida por intent/share; dispara a busca automaticamente.
  final String? urlInicial;

  @override
  State<ImportView> createState() => _ImportViewState();
}

class _ImportViewState extends State<ImportView>
    with SingleTickerProviderStateMixin {
  late final DownloadVM _vm;
  late final TabController _tabs;

  final TextEditingController _url = TextEditingController();
  final TextEditingController _html = TextEditingController();
  final TextEditingController _htmlUrl = TextEditingController();

  Cifra? _preview;
  String? _arquivoNome;
  String? _erroLocal;
  String? _erroSalvar;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    _vm = DownloadVM(context.read<ParserService>());
    _tabs = TabController(length: 3, vsync: this);
    final inicial = widget.urlInicial?.trim() ?? '';
    if (inicial.isNotEmpty) {
      _url.text = inicial;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _importarUrl();
      });
    }
  }

  @override
  void dispose() {
    _tabs.dispose();
    _vm.dispose();
    _url.dispose();
    _html.dispose();
    _htmlUrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _preview == null ? 'Importar cifra' : 'Revisar importação',
        ),
        leading: _preview == null
            ? null
            : IconButton(
                tooltip: 'Voltar para a importação',
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => setState(() {
                  _preview = null;
                  _erroSalvar = null;
                  _erroLocal = null;
                }),
              ),
        bottom: _preview == null
            ? TabBar(
                controller: _tabs,
                tabs: const [
                  Tab(text: 'Link'),
                  Tab(text: 'HTML'),
                  Tab(text: 'Arquivo'),
                ],
              )
            : null,
      ),
      body: AnimatedBuilder(
        animation: _vm,
        builder: (contexto, _) =>
            _preview == null ? _corpoAbas() : _corpoPreview(),
      ),
    );
  }

  Widget _corpoAbas() {
    return TabBarView(
      controller: _tabs,
      children: [
        _formLink(),
        _formHtml(),
        _formArquivo(),
      ],
    );
  }

  Widget _formLink() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
      children: [
        Text(
          'Cole o link da cifra',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          'Sites suportados: CifraClub, ClickGratis e CifraMaster. '
          'Outros sites também são tentados pelo bloco de acordes.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6),
              ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _url,
          keyboardType: TextInputType.url,
          textInputAction: TextInputAction.go,
          autocorrect: false,
          onSubmitted: (_) => _importarUrl(),
          decoration: InputDecoration(
            hintText: 'https://www.cifraclub.com.br/artista/musica/',
            prefixIcon: const Icon(Icons.link_rounded),
            suffixIcon: IconButton(
              tooltip: 'Colar da área de transferência',
              icon: const Icon(Icons.content_paste_rounded, size: 19),
              onPressed: _colarUrl,
            ),
          ),
        ),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: _vm.carregando ? null : _importarUrl,
          icon: _vm.carregando
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.download_rounded),
          label: Text(_vm.carregando ? 'Baixando...' : 'Buscar cifra'),
        ),
        if (_erroLocal != null) _avisoErro(_erroLocal!),
        if (_vm.erro != null) _avisoErro(_vm.erro!),
        const SizedBox(height: 18),
        _dica(
          'Dica: você também pode compartilhar um link do navegador '
          'direto para o CifraVault.',
        ),
      ],
    );
  }

  Widget _formHtml() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
      children: [
        Text(
          'Colar HTML ou texto da página',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          'Útil quando o site bloqueia o download automático. Abra a página '
          'no navegador, copie o código-fonte (ou a cifra) e cole abaixo.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6),
              ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _htmlUrl,
          keyboardType: TextInputType.url,
          autocorrect: false,
          decoration: const InputDecoration(
            labelText: 'URL de origem (opcional)',
            hintText: 'https://...',
            prefixIcon: Icon(Icons.link_rounded),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _html,
          minLines: 8,
          maxLines: 14,
          keyboardType: TextInputType.multiline,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          decoration: const InputDecoration(
            alignLabelWithHint: true,
            labelText: 'HTML ou conteúdo',
            hintText: '<html>... ou a cifra já formatada',
          ),
        ),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: _vm.carregando ? null : _importarHtml,
          icon: _vm.carregando
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.auto_fix_high_rounded),
          label: Text(_vm.carregando ? 'Processando...' : 'Extrair cifra'),
        ),
        if (_erroLocal != null) _avisoErro(_erroLocal!),
        if (_vm.erro != null) _avisoErro(_vm.erro!),
      ],
    );
  }

  Widget _formArquivo() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
      children: [
        Text(
          'Importar arquivo Markdown',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          'Selecione um arquivo `.md` já existente. O front-matter é lido '
          'quando presente e o arquivo é copiado para a pasta do vault.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6),
              ),
        ),
        const SizedBox(height: 16),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                Icon(
                  Icons.description_outlined,
                  size: 42,
                  color: _arquivoNome == null
                      ? Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.35)
                      : AppConfig.primaryColor,
                ),
                const SizedBox(height: 10),
                Text(
                  _arquivoNome ?? 'Nenhum arquivo selecionado',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _vm.carregando ? null : _escolherArquivo,
                  icon: const Icon(Icons.folder_open_rounded, size: 18),
                  label: const Text('Escolher arquivo .md'),
                ),
              ],
            ),
          ),
        ),
        if (_erroLocal != null) _avisoErro(_erroLocal!),
      ],
    );
  }

  Widget _corpoPreview() {
    final cifra = _preview!;
    final theme = Theme.of(context);
    final corSuave = theme.colorScheme.onSurface.withValues(alpha: 0.6);

    final chips = <String>[
      if ((cifra.tom ?? '').isNotEmpty) 'Tom ${cifra.tom}',
      cifra.tipo,
      ...cifra.momentos.take(3),
      ...cifra.temas.take(2),
      ...cifra.tags.take(3),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cifra.titulo,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  cifra.artista,
                  style: theme.textTheme.bodyMedium?.copyWith(color: corSuave),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final chip in chips) FiltroChip(label: chip, mini: true),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _metrica('${cifra.totalAcordes}', 'acordes'),
                    const SizedBox(width: 20),
                    _metrica('${cifra.secoes.length}', 'seções'),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _editarMetadados,
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Metadados'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Prévia',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          constraints: const BoxConstraints(maxHeight: 300),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: theme.dividerTheme.color ?? theme.colorScheme.outlineVariant,
            ),
          ),
          padding: const EdgeInsets.all(14),
          child: SingleChildScrollView(
            child: ChordDisplay(
              secoes: cifra.conteudo,
              mostrarTitulosSecao: false,
              escalaFonte: 0.9,
            ),
          ),
        ),
        if ((cifra.fonte ?? '').isNotEmpty || (cifra.url ?? '').isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            [
              if ((cifra.fonte ?? '').isNotEmpty) 'Fonte: ${cifra.fonte}',
              if ((cifra.url ?? '').isNotEmpty) cifra.url!,
            ].join(' • '),
            style: theme.textTheme.bodySmall?.copyWith(color: corSuave),
          ),
        ],
        if (_erroSalvar != null) _avisoErro(_erroSalvar!),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: _salvando ? null : _salvar,
          icon: _salvando
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_rounded),
          label: Text(_salvando ? 'Salvando...' : 'Salvar no Vault'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _salvando
              ? null
              : () => setState(() {
                    _preview = null;
                    _erroSalvar = null;
                    _erroLocal = null;
                  }),
          icon: const Icon(Icons.arrow_back_rounded, size: 18),
          label: const Text('Importar outra'),
        ),
      ],
    );
  }

  Widget _metrica(String valor, String rotulo) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          valor,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppConfig.primaryColor,
          ),
        ),
        Text(
          rotulo,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
          ),
        ),
      ],
    );
  }

  Widget _avisoErro(String mensagem) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.error.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 18,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                mensagem,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dica(String texto) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppConfig.accentColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.lightbulb_outline_rounded,
            size: 18,
            color: AppConfig.accentColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              texto,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _colarUrl() async {
    final dados = await Clipboard.getData(Clipboard.kTextPlain);
    final texto = dados?.text?.trim() ?? '';
    if (texto.isEmpty) return;
    _url.text = texto;
    if (mounted) setState(() {});
  }

  Future<void> _importarUrl() async {
    final url = _url.text.trim();
    if (url.isEmpty) {
      setState(() => _erroLocal = 'Informe o link da cifra.');
      return;
    }
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      setState(() => _erroLocal = 'O link precisa começar com http:// ou https://.');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _erroLocal = null);
    final ok = await _vm.importarUrl(url);
    if (!mounted) return;
    if (ok && _vm.cifra != null) {
      _definirPreview(_vm.cifra!, arquivo: null);
    }
  }

  Future<void> _importarHtml() async {
    final html = _html.text.trim();
    if (html.isEmpty) {
      setState(() => _erroLocal = 'Cole o HTML ou o texto da cifra.');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _erroLocal = null);
    final url = _htmlUrl.text.trim();
    final ok = await _vm.importarHtml(
      html,
      url: url.isEmpty ? null : url,
    );
    if (!mounted) return;
    if (ok && _vm.cifra != null) {
      _definirPreview(_vm.cifra!, arquivo: null);
    }
  }

  Future<void> _escolherArquivo() async {
    setState(() => _erroLocal = null);
    final parser = context.read<ParserService>();
    try {
      final arquivos = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['md', 'markdown', 'txt'],
      );
      if (arquivos.isEmpty) return;
      final arquivo = arquivos.single;

      final bytes = await arquivo.readAsBytes();
      final conteudo = _decodificar(bytes);

      final cifra = parser.parseCifraMarkdown(
        conteudo,
        id: p.basenameWithoutExtension(arquivo.name),
      );

      if (!mounted) return;
      setState(() => _arquivoNome = arquivo.name);
      _definirPreview(cifra, arquivo: arquivo.name);
    } catch (falha) {
      if (!mounted) return;
      setState(() => _erroLocal = 'Falha ao ler o arquivo: $falha');
    }
  }

  String _decodificar(List<int> bytes) {
    try {
      return utf8.decode(bytes);
    } on FormatException {
      return latin1.decode(bytes, allowInvalid: true);
    }
  }

  void _definirPreview(Cifra cifra, {required String? arquivo}) {
    setState(() {
      _preview = cifra;
      _arquivoNome = arquivo;
      _erroSalvar = null;
      _erroLocal = null;
    });
  }

  Future<void> _editarMetadados() async {
    final atual = _preview;
    if (atual == null) return;
    final dados = await showMetadataCifraSheet(
      context,
      inicial: MetadataCifraDados(
        titulo: atual.titulo,
        artista: atual.artista,
        tom: atual.tom ?? '',
        tipo: atual.tipo,
        fonte: atual.fonte ?? 'Manual',
        url: atual.url ?? '',
        momentos: atual.momentos,
        temas: atual.temas,
        tags: atual.tags,
      ),
    );
    if (dados == null || !mounted) return;
    setState(() {
      _preview = atual.copyWith(
        titulo: dados.titulo,
        artista: dados.artista,
        tom: dados.tom,
        tipo: dados.tipo,
        fonte: dados.fonte,
        url: dados.url,
        momentos: dados.momentos,
        temas: dados.temas,
        tags: dados.tags,
      );
    });
  }

  Future<void> _salvar() async {
    final cifra = _preview;
    if (cifra == null) return;
    if (cifra.titulo.trim().isEmpty) {
      setState(() => _erroSalvar = 'Informe o título antes de salvar.');
      return;
    }

    setState(() {
      _salvando = true;
      _erroSalvar = null;
    });

    try {
      final vault = context.read<VaultService>();
      final id = await vault.gerarIdUnico(cifra.titulo);
      final paraSalvar = cifra.copyWith(
        id: id,
        conteudo: parseSecoes(cifra.bodyRaw),
        caminho: null,
        dataImportacao: DateTime.now(),
      );
      await vault.salvarCifra(paraSalvar);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (falha) {
      if (!mounted) return;
      setState(() => _erroSalvar = 'Não foi possível salvar: $falha');
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }
}
