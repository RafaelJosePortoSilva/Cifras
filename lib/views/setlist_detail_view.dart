import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../config/app_config.dart';
import '../models/cifra.dart';
import '../models/setlist.dart';
import '../router/routes.dart';
import '../services/pdf_service.dart';
import '../services/vault_service.dart';
import '../utils/text_utils.dart';
import 'widgets/filtro_chip.dart';
import 'widgets/momento_card.dart';

/// Detalhe de um setlist: músicas por momento, marcação de "tocado" e export.
class SetlistDetailView extends StatefulWidget {
  const SetlistDetailView({super.key, required this.setlist});

  final Setlist setlist;

  @override
  State<SetlistDetailView> createState() => _SetlistDetailViewState();
}

class _SetlistDetailViewState extends State<SetlistDetailView> {
  late Setlist _setlist;
  List<Cifra> _cifras = const <Cifra>[];
  bool _carregando = true;
  bool _salvando = false;
  String? _erro;
  bool _alterou = false;

  @override
  void initState() {
    super.initState();
    _setlist = widget.setlist;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _carregar();
    });
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final vault = context.read<VaultService>();
      final cifras = await vault.carregarCifras();
      var atual = _setlist;
      final caminho = _setlist.caminho;
      if (caminho != null && caminho.isNotEmpty) {
        try {
          atual = await vault.lerSetlist(caminho);
        } catch (_) {
          // Mantém o objeto recebido se o arquivo tiver sido movido.
        }
      }
      if (!mounted) return;
      setState(() {
        _cifras = cifras;
        _setlist = atual;
        _carregando = false;
      });
    } catch (falha) {
      if (!mounted) return;
      setState(() {
        _erro = 'Não foi possível carregar o setlist.\n$falha';
        _carregando = false;
      });
    }
  }

  Map<String, Cifra?> get _mapaCifras => _setlist.resolverCifras(_cifras);

  int get _totalTocadas {
    var total = 0;
    for (final momento in _setlist.momentos) {
      for (final item in momento.itens) {
        if (item.estaTocado) total++;
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(_alterou);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _setlist.titulo,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            IconButton(
              tooltip: 'Editar setlist',
              onPressed: _carregando ? null : _editar,
              icon: const Icon(Icons.edit_outlined),
            ),
            PopupMenuButton<String>(
              tooltip: 'Exportar',
              onSelected: _executarAcao,
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'pdf', child: Text('Exportar PDF')),
                PopupMenuItem(
                  value: 'texto',
                  child: Text('Compartilhar texto'),
                ),
              ],
            ),
          ],
        ),
        body: _corpo(theme),
      ),
    );
  }

  Widget _corpo(ThemeData theme) {
    if (_carregando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_erro != null) {
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
              Text(_erro!, textAlign: TextAlign.center),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: _carregar,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    final total = _setlist.totalMusicas;
    final progresso = total == 0 ? 0.0 : _totalTocadas / total;

    return ListView(
      padding: const EdgeInsets.only(top: 8, bottom: 28),
      children: [
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _setlist.titulo,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                if (_setlist.evento.trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    _setlist.evento,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    FiltroChip(
                      label: formatarData(_setlist.data),
                      mini: true,
                      cor: AppConfig.primaryColor,
                    ),
                    if (_setlist.diaLiturgico.trim().isNotEmpty)
                      FiltroChip(
                        label: _setlist.diaLiturgico,
                        mini: true,
                        cor: AppConfig.accentColor,
                      ),
                    FiltroChip(
                      label: '${_setlist.totalMomentos} momento(s)',
                      mini: true,
                    ),
                    FiltroChip(
                      label: '$total música(s)',
                      mini: true,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: LinearProgressIndicator(
                          value: progresso,
                          minHeight: 7,
                          backgroundColor:
                              theme.colorScheme.onSurface.withValues(alpha: 0.1),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '$_totalTocadas/$total',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<SetlistStatus>(
                  initialValue: _setlist.status,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    isDense: true,
                  ),
                  items: [
                    for (final status in SetlistStatus.values)
                      DropdownMenuItem(
                        value: status,
                        child: Text(status.rotulo),
                      ),
                  ],
                  onChanged: _salvando
                      ? null
                      : (valor) {
                          if (valor == null) return;
                          setState(() => _setlist.status = valor);
                          _persistir();
                        },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (_setlist.momentos.isEmpty)
          Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                Icon(
                  Icons.view_agenda_outlined,
                  size: 46,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
                ),
                const SizedBox(height: 10),
                Text(
                  'Este setlist ainda não tem momentos.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _editar,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Adicionar músicas'),
                ),
              ],
            ),
          )
        else
          for (var i = 0; i < _setlist.momentos.length; i++)
            _momentoComAcoes(context, i),
      ],
    );
  }

  Widget _momentoComAcoes(BuildContext context, int indice) {
    final momento = _setlist.momentos[indice];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MomentoCard(
          momento: momento,
          cifras: _mapaCifras,
          inicialmenteExpandido: true,
          onAbrirCifra: _abrirCifra,
          onAlternarTocado: (indiceItem, valor) {
            setState(() {
              momento.itens[indiceItem].estaTocado = valor;
              _alterou = true;
            });
            _persistir();
          },
        ),
        if (momento.itens.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(26, 0, 20, 6),
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  setState(() {
                    for (final item in momento.itens) {
                      item.estaTocado = true;
                    }
                    _alterou = true;
                  });
                  _persistir();
                },
                icon: const Icon(Icons.done_all_rounded, size: 17),
                label: const Text('Marcar momento como tocado'),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _persistir() async {
    final caminho = _setlist.caminho;
    if (caminho == null || caminho.isEmpty) return;
    setState(() => _salvando = true);
    try {
      await context.read<VaultService>().salvarSetlist(_setlist);
    } catch (falha) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível salvar o progresso: $falha')),
      );
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Future<void> _abrirCifra(Cifra cifra) async {
    await Navigator.of(context).pushNamed(Routes.viewer, arguments: cifra);
  }

  Future<void> _editar() async {
    final atualizado = await Navigator.of(context).pushNamed(
      Routes.setlistNova,
      arguments: SetlistEditorArgs(setlist: _setlist),
    );
    if (!mounted) return;
    if (atualizado is Setlist) {
      setState(() {
        _setlist = atualizado;
        _alterou = true;
      });
      await _carregar();
    }
  }

  Future<void> _executarAcao(String valor) async {
    switch (valor) {
      case 'pdf':
        await _exportarPdf();
        break;
      case 'texto':
        await _compartilharTexto();
        break;
    }
  }

  Future<void> _exportarPdf() async {
    try {
      final pdf = context.read<PdfService>();
      final arquivo = await pdf.gerarPdfSetlist(
        _setlist,
        cifras: _mapaCifras,
      );
      await pdf.compartilharPdf(arquivo);
    } catch (falha) {
      _avisar('Não foi possível gerar o PDF: $falha');
    }
  }

  Future<void> _compartilharTexto() async {
    try {
      final pdf = context.read<PdfService>();
      await SharePlus.instance.share(
        ShareParams(
          subject: _setlist.titulo,
          text: pdf.textoSetlist(_setlist, _mapaCifras),
        ),
      );
    } catch (falha) {
      _avisar('Não foi possível compartilhar: $falha');
    }
  }

  void _avisar(String mensagem) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem)),
    );
  }
}
