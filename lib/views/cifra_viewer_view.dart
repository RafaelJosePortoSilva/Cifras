import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../config/app_config.dart';
import '../models/cifra.dart';
import '../router/routes.dart';
import '../services/pdf_service.dart';
import '../services/vault_service.dart';
import '../viewmodels/viewer_vm.dart';
import 'widgets/chord_display.dart';
import 'widgets/filtro_chip.dart';

/// Tela de visualização de uma cifra, com transposição e zoom.
class CifraViewer extends StatefulWidget {
  const CifraViewer({super.key, required this.cifra});

  final Cifra cifra;

  @override
  State<CifraViewer> createState() => _CifraViewerState();
}

class _CifraViewerState extends State<CifraViewer> {
  late final ViewerVM _vm;

  @override
  void initState() {
    super.initState();
    _vm = ViewerVM(widget.cifra);
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ViewerVM>.value(
      value: _vm,
      child: Consumer<ViewerVM>(
        builder: (contexto, vm, _) => Scaffold(
          appBar: AppBar(
            title: Text(
              vm.cifra.titulo,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            actions: [
              PopupMenuButton<String>(
                tooltip: 'Mais ações',
                onSelected: (valor) => _executarAcao(valor),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'editar', child: Text('Editar cifra')),
                  PopupMenuItem(value: 'pdf', child: Text('Exportar PDF')),
                  PopupMenuItem(
                    value: 'compartilhar',
                    child: Text('Compartilhar texto'),
                  ),
                  PopupMenuDivider(),
                  PopupMenuItem(value: 'excluir', child: Text('Excluir')),
                ],
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CabecalhoCifra(
                  cifra: vm.cifra,
                  tomAtual: vm.tomAtual,
                ),
                const SizedBox(height: 10),
                ChordDisplay(
                  secoes: vm.cifra.conteudo,
                  semitons: vm.semitons,
                  escalaFonte: vm.escalaFonte,
                  preferirBemois: vm.preferirBemois,
                ),
                if ((vm.cifra.fonte ?? '').isNotEmpty ||
                    (vm.cifra.url ?? '').isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 6),
                  Text(
                    [
                      if ((vm.cifra.fonte ?? '').isNotEmpty)
                        'Fonte: ${vm.cifra.fonte}',
                      if ((vm.cifra.url ?? '').isNotEmpty)
                        'Importado de ${vm.cifra.url}',
                    ].join(' • '),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.5),
                        ),
                  ),
                ],
              ],
            ),
          ),
          bottomNavigationBar: _BarraFerramentas(vm: vm, onAcoes: _abrirAcoes),
        ),
      ),
    );
  }

  Future<void> _executarAcao(String valor) async {
    switch (valor) {
      case 'editar':
        await _editar();
        break;
      case 'pdf':
        await _exportarPdf();
        break;
      case 'compartilhar':
        await _compartilharTexto();
        break;
      case 'excluir':
        await _excluir();
        break;
    }
  }

  void _abrirAcoes() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (contexto) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Editar cifra'),
              onTap: () {
                Navigator.of(contexto).pop();
                _editar();
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined),
              title: const Text('Exportar PDF'),
              onTap: () {
                Navigator.of(contexto).pop();
                _exportarPdf();
              },
            ),
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: const Text('Compartilhar texto'),
              onTap: () {
                Navigator.of(contexto).pop();
                _compartilharTexto();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _editar() async {
    final atualizada = await Navigator.of(context).pushNamed(
      Routes.editor,
      arguments: EditorArgs(cifra: _vm.cifra),
    );
    if (!mounted || atualizada is! Cifra) return;
    _vm
      ..atualizarCifra(atualizada)
      ..resetarTom();
  }

  Future<void> _exportarPdf() async {
    try {
      final pdf = context.read<PdfService>();
      final arquivo = await pdf.gerarPdfCifra(
        _vm.cifra,
        semitons: _vm.semitons,
      );
      await pdf.compartilharPdf(arquivo);
    } catch (falha) {
      _avisar('Não foi possível gerar o PDF: $falha');
    }
  }

  Future<void> _compartilharTexto() async {
    try {
      await SharePlus.instance.share(
        ShareParams(
          subject: '${_vm.cifra.titulo} - ${_vm.cifra.artista}',
          text: _vm.cifra.toTextoCompartilhavel(),
        ),
      );
    } catch (falha) {
      _avisar('Não foi possível compartilhar: $falha');
    }
  }

  Future<void> _excluir() async {
    final caminho = _vm.cifra.caminho;
    if (caminho == null || caminho.isEmpty) {
      _avisar('Esta cifra ainda não está salva no vault.');
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogoContexto) => AlertDialog(
        title: const Text('Excluir cifra?'),
        content: Text(
          'O arquivo "${_vm.cifra.titulo}.md" será apagado do vault. '
          'Essa ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogoContexto).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogoContexto).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;

    try {
      await context.read<VaultService>().deletar(caminho);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (falha) {
      _avisar('Não foi possível excluir: $falha');
    }
  }

  void _avisar(String mensagem) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem)),
    );
  }
}

class _CabecalhoCifra extends StatelessWidget {
  const _CabecalhoCifra({required this.cifra, required this.tomAtual});

  final Cifra cifra;
  final String? tomAtual;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final corSuave = theme.colorScheme.onSurface.withValues(alpha: 0.62);
    final tags = <String>[
      if (tomAtual != null && tomAtual!.isNotEmpty) 'Tom $tomAtual',
      cifra.tipo,
      ...cifra.momentos.take(3),
      ...cifra.temas.take(2),
    ];

    return Column(
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
        if (tags.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (var i = 0; i < tags.length; i++)
                FiltroChip(
                  label: tags[i],
                  mini: true,
                  cor: i == 0 ? AppConfig.primaryColor : null,
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _BarraFerramentas extends StatelessWidget {
  const _BarraFerramentas({required this.vm, required this.onAcoes});

  final ViewerVM vm;
  final VoidCallback onAcoes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final corSuave = theme.colorScheme.onSurface.withValues(alpha: 0.55);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.dividerTheme.color ?? Colors.black12),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _BotaoCompacto(
                    icone: Icons.remove_circle_outline_rounded,
                    tooltip: 'Descer meio tom',
                    onPressed: () => vm.transpor(-1),
                  ),
                  Tooltip(
                    message: 'Toque para voltar ao tom original',
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: vm.resetarTom,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              vm.tomAtual ?? '—',
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: AppConfig.primaryColor,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              '${vm.rotuloTransposicao} st',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: corSuave,
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  _BotaoCompacto(
                    icone: Icons.add_circle_outline_rounded,
                    tooltip: 'Subir meio tom',
                    onPressed: () => vm.transpor(1),
                  ),
                ],
              ),
            ),
            Container(
              width: 1,
              height: 28,
              color: theme.dividerTheme.color ?? Colors.black12,
            ),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _BotaoCompacto(
                    icone: Icons.zoom_out_rounded,
                    tooltip: 'Diminuir letra',
                    onPressed: () => vm.alterarZoom(-0.1),
                  ),
                  Text(
                    '${(vm.escalaFonte * 100).round()}%',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: corSuave,
                    ),
                  ),
                  _BotaoCompacto(
                    icone: Icons.zoom_in_rounded,
                    tooltip: 'Aumentar letra',
                    onPressed: () => vm.alterarZoom(0.1),
                  ),
                  _BotaoCompacto(
                    icone: Icons.more_horiz_rounded,
                    tooltip: 'Ações',
                    onPressed: onAcoes,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BotaoCompacto extends StatelessWidget {
  const _BotaoCompacto({
    required this.icone,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icone;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icone, size: 21),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
    );
  }
}
