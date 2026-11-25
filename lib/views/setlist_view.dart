import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../config/app_config.dart';
import '../models/setlist.dart';
import '../router/routes.dart';
import '../services/pdf_service.dart';
import '../utils/text_utils.dart';
import '../viewmodels/setlist_vm.dart';
import 'widgets/filtro_chip.dart';

/// Lista de setlists salvos no vault.
class SetlistsView extends StatefulWidget {
  const SetlistsView({super.key});

  @override
  State<SetlistsView> createState() => _SetlistsViewState();
}

class _SetlistsViewState extends State<SetlistsView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<SetlistVM>().carregar();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SetlistVM>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Setlists'),
        actions: [
          IconButton(
            tooltip: 'Recarregar',
            onPressed: vm.carregar,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _conteudo(vm),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirNova(),
        icon: const Icon(Icons.playlist_add_rounded),
        label: const Text('Novo setlist'),
      ),
    );
  }

  Widget _conteudo(SetlistVM vm) {
    final theme = Theme.of(context);

    if (vm.carregando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (vm.erro != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 44,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 10),
              Text(vm.erro!, textAlign: TextAlign.center),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: vm.carregar,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    if (vm.setlists.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.queue_music_rounded,
                size: 58,
                color: AppConfig.primaryColor,
              ),
              const SizedBox(height: 12),
              Text(
                'Nenhum setlist ainda',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Monte o roteiro da celebração organizando as cifras por '
                'momento (Abertura, Comunhão, Envio...).',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => _abrirNova(),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Criar setlist'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: vm.carregar,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 6, bottom: 110),
        itemCount: vm.setlists.length,
        itemBuilder: (contexto, indice) {
          final setlist = vm.setlists[indice];
          return _SetlistCard(
            setlist: setlist,
            onTap: () => _abrirDetalhe(setlist),
            onEditar: () => _editar(setlist),
            onPdf: () => _exportarPdf(setlist),
            onCompartilhar: () => _compartilharTexto(setlist),
            onExcluir: () => _excluir(setlist),
          );
        },
      ),
    );
  }

  Future<void> _abrirNova() async {
    final salvo = await Navigator.of(context).pushNamed(Routes.setlistNova);
    if (!mounted) return;
    if (salvo is Setlist) await context.read<SetlistVM>().carregar();
  }

  Future<void> _editar(Setlist setlist) async {
    final atualizado = await Navigator.of(context).pushNamed(
      Routes.setlistNova,
      arguments: SetlistEditorArgs(setlist: setlist),
    );
    if (!mounted) return;
    if (atualizado is Setlist) await context.read<SetlistVM>().carregar();
  }

  Future<void> _abrirDetalhe(Setlist setlist) async {
    final alterou = await Navigator.of(context).pushNamed(
      Routes.setlistDetalhe,
      arguments: SetlistDetailArgs(setlist: setlist),
    );
    if (!mounted) return;
    if (alterou == true) await context.read<SetlistVM>().carregar();
  }

  Future<void> _exportarPdf(Setlist setlist) async {
    try {
      final vm = context.read<SetlistVM>();
      final pdf = context.read<PdfService>();
      final arquivo = await pdf.gerarPdfSetlist(
        setlist,
        cifras: vm.resolver(setlist),
      );
      await pdf.compartilharPdf(arquivo);
    } catch (falha) {
      _avisar('Não foi possível gerar o PDF: $falha');
    }
  }

  Future<void> _compartilharTexto(Setlist setlist) async {
    try {
      final vm = context.read<SetlistVM>();
      final pdf = context.read<PdfService>();
      await SharePlus.instance.share(
        ShareParams(
          subject: setlist.titulo,
          text: pdf.textoSetlist(setlist, vm.resolver(setlist)),
        ),
      );
    } catch (falha) {
      _avisar('Não foi possível compartilhar: $falha');
    }
  }

  Future<void> _excluir(Setlist setlist) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogoContexto) => AlertDialog(
        title: const Text('Excluir setlist?'),
        content: Text(
          'O arquivo "${setlist.titulo}.md" será apagado do vault.',
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
    await context.read<SetlistVM>().deletar(setlist);
  }

  void _avisar(String mensagem) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem)),
    );
  }
}

class _SetlistCard extends StatelessWidget {
  const _SetlistCard({
    required this.setlist,
    required this.onTap,
    required this.onEditar,
    required this.onPdf,
    required this.onCompartilhar,
    required this.onExcluir,
  });

  final Setlist setlist;
  final VoidCallback onTap;
  final VoidCallback onEditar;
  final VoidCallback onPdf;
  final VoidCallback onCompartilhar;
  final VoidCallback onExcluir;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final corSuave = theme.colorScheme.onSurface.withValues(alpha: 0.6);
    final partes = formatarData(setlist.data).split('/');
    final dia = partes.isNotEmpty ? partes[0] : '--';
    final mes = partes.length > 1 ? partes[1] : '--';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      clipBehavior: Clip.antiAlias,
      color: theme.colorScheme.surface.withValues(alpha: 0.65),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 50,
                height: 52,
                decoration: BoxDecoration(
                  color: AppConfig.primaryColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      dia,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppConfig.primaryColor,
                      ),
                    ),
                    Text(
                      '/$mes',
                      style: TextStyle(fontSize: 10, color: corSuave),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      setlist.titulo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (setlist.evento.trim().isNotEmpty)
                      Text(
                        setlist.evento,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            theme.textTheme.bodySmall?.copyWith(color: corSuave),
                      ),
                    const SizedBox(height: 7),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        FiltroChip(
                          label: setlist.status.rotulo,
                          mini: true,
                          cor: _corStatus(setlist.status),
                        ),
                        FiltroChip(
                          label: '${setlist.totalMomentos} momento(s)',
                          mini: true,
                        ),
                        FiltroChip(
                          label: '${setlist.totalMusicas} música(s)',
                          mini: true,
                        ),
                        if (setlist.diaLiturgico.trim().isNotEmpty)
                          FiltroChip(
                            label: setlist.diaLiturgico,
                            mini: true,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Ações',
                onSelected: (valor) {
                  switch (valor) {
                    case 'editar':
                      onEditar();
                      break;
                    case 'pdf':
                      onPdf();
                      break;
                    case 'compartilhar':
                      onCompartilhar();
                      break;
                    case 'excluir':
                      onExcluir();
                      break;
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'editar', child: Text('Editar')),
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
        ),
      ),
    );
  }

  Color _corStatus(SetlistStatus status) {
    switch (status) {
      case SetlistStatus.rascunho:
        return const Color(0xFF9E9E9E);
      case SetlistStatus.confirmado:
        return const Color(0xFF42A5F5);
      case SetlistStatus.finalizado:
        return const Color(0xFF66BB6A);
    }
  }
}
