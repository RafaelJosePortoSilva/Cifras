import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../config/app_config.dart';
import '../models/cifra.dart';
import '../models/setlist.dart';
import '../services/pdf_service.dart';
import '../services/vault_service.dart';
import '../utils/text_utils.dart';
import '../viewmodels/setlist_vm.dart';
import 'widgets/filtro_chip.dart';

/// Formulário de criação/edição de setlist.
class NewSetlistView extends StatelessWidget {
  const NewSetlistView({super.key, this.setlist});

  final Setlist? setlist;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SetlistEditorVM>(
      create: (contexto) => SetlistEditorVM(
        vault: contexto.read<VaultService>(),
        pdf: contexto.read<PdfService>(),
        setlist: setlist,
      )..carregar(),
      child: const _SetlistEditorBody(),
    );
  }
}

class _SetlistEditorBody extends StatelessWidget {
  const _SetlistEditorBody();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SetlistEditorVM>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(vm.editando ? 'Editar setlist' : 'Novo setlist'),
        actions: [
          IconButton(
            tooltip: 'Salvar setlist',
            onPressed: vm.salvando ? null : () => _salvar(context, vm),
            icon: vm.salvando
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(top: 6, bottom: 32),
        children: [
          _cardMetadados(context, vm),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 8, 2),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Momentos',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '${vm.totalMusicas} música(s) em ${vm.momentos.length} momento(s)',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _novoMomento(context, vm),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Momento'),
                ),
              ],
            ),
          ),
          if (vm.momentos.isEmpty)
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    Icon(
                      Icons.view_agenda_outlined,
                      size: 38,
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.35),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Nenhum momento ainda',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Adicione Abertura, Comunhão, Envio... e depois '
                      'selecione as músicas de cada momento.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          for (var i = 0; i < vm.momentos.length; i++)
            _cardMomento(context, vm, i),
          const SizedBox(height: 10),
          _acoesExportacao(context, vm),
        ],
      ),
    );
  }

  Widget _cardMetadados(BuildContext context, SetlistEditorVM vm) {
    final opcoesDia = <String>{
      '',
      ...AppConfig.diasLiturgicos,
      if (vm.diaLiturgico.isNotEmpty) vm.diaLiturgico,
    }.toList();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            TextFormField(
              initialValue: vm.titulo,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Título *',
                hintText: 'Ceia Materna - 29/11',
              ),
              onChanged: vm.definirTitulo,
            ),
            const SizedBox(height: 10),
            TextFormField(
              initialValue: vm.evento,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Evento',
                hintText: 'Ceia Materna - Casa Maria',
              ),
              onChanged: vm.definirEvento,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _escolherData(context, vm),
                    icon: const Icon(Icons.calendar_today_rounded, size: 17),
                    label: Text(formatarData(vm.dataEvento)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: vm.diaLiturgico,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Dia litúrgico',
                    ),
                    items: [
                      for (final dia in opcoesDia)
                        DropdownMenuItem(
                          value: dia,
                          child: Text(dia.isEmpty ? 'Não informado' : dia),
                        ),
                    ],
                    onChanged: (valor) =>
                        vm.definirDiaLiturgico(valor ?? ''),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<SetlistStatus>(
              initialValue: vm.status,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Status'),
              items: [
                for (final status in SetlistStatus.values)
                  DropdownMenuItem(
                    value: status,
                    child: Text(status.rotulo),
                  ),
              ],
              onChanged: (valor) =>
                  vm.definirStatus(valor ?? SetlistStatus.rascunho),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cardMomento(BuildContext context, SetlistEditorVM vm, int indice) {
    final momento = vm.momentos[indice];
    final theme = Theme.of(context);
    final corSuave = theme.colorScheme.onSurface.withValues(alpha: 0.58);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  AppConfig.emojiMomento(momento.nome),
                  style: const TextStyle(fontSize: 17),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    momento.nome,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Mover para cima',
                  visualDensity: VisualDensity.compact,
                  onPressed: indice == 0
                      ? null
                      : () => vm.moverMomento(indice, -1),
                  icon: const Icon(Icons.keyboard_arrow_up_rounded, size: 21),
                ),
                IconButton(
                  tooltip: 'Mover para baixo',
                  visualDensity: VisualDensity.compact,
                  onPressed: indice == vm.momentos.length - 1
                      ? null
                      : () => vm.moverMomento(indice, 1),
                  icon:
                      const Icon(Icons.keyboard_arrow_down_rounded, size: 21),
                ),
                IconButton(
                  tooltip: 'Remover momento',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => vm.removerMomento(indice),
                  icon: const Icon(Icons.delete_outline_rounded, size: 20),
                ),
              ],
            ),
            if (momento.itens.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 2, 4, 6),
                child: Text(
                  'Nenhuma música neste momento.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: corSuave,
                  ),
                ),
              )
            else
              for (var i = 0; i < momento.itens.length; i++)
                _ItemEditor(
                  item: momento.itens[i],
                  cifra: vm.cifraPorId(momento.itens[i].cifraId),
                  indice: i,
                  onTocado: (valor) =>
                      vm.alternarTocado(indice, i, valor),
                  onNota: () => _editarNota(context, vm, indice, i),
                  onMover: (delta) => vm.moverItem(indice, i, delta),
                  onRemover: () => vm.removerItem(indice, i),
                ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => _adicionarMusica(context, vm, indice),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Adicionar música'),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _acoesExportacao(BuildContext context, SetlistEditorVM vm) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Exportar',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _gerarPdf(context, vm),
                  icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                  label: const Text('PDF'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _copiar(context, vm),
                  icon: const Icon(Icons.copy_all_rounded, size: 18),
                  label: const Text('Copiar texto'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _compartilhar(context, vm),
                  icon: const Icon(Icons.share_outlined, size: 18),
                  label: const Text('Compartilhar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _salvar(BuildContext context, SetlistEditorVM vm) async {
    final salvo = await vm.salvar();
    if (!context.mounted) return;
    if (salvo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(vm.erro ?? 'Não foi possível salvar.')),
      );
      return;
    }
    Navigator.of(context).pop(salvo);
  }

  Future<void> _escolherData(
    BuildContext context,
    SetlistEditorVM vm,
  ) async {
    final escolhida = await showDatePicker(
      context: context,
      initialDate: vm.dataEvento,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (escolhida != null) vm.definirData(escolhida);
  }

  Future<void> _novoMomento(
    BuildContext context,
    SetlistEditorVM vm,
  ) async {
    final controller = TextEditingController();
    final nome = await showDialog<String>(
      context: context,
      builder: (dialogoContexto) => StatefulBuilder(
        builder: (dialogoContexto, setDialogState) => AlertDialog(
          title: const Text('Adicionar momento'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final sugestao in AppConfig.momentosLiturgicos)
                      FilterChip(
                        label: Text(sugestao),
                        selected: controller.text == sugestao,
                        onSelected: (_) {
                          controller.text = sugestao;
                          setDialogState(() {});
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: controller,
                  autofocus: false,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Nome do momento',
                    hintText: 'Ex.: Consagração',
                  ),
                  onSubmitted: (valor) =>
                      Navigator.of(dialogoContexto).pop(valor),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogoContexto).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(dialogoContexto).pop(controller.text),
              child: const Text('Adicionar'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();

    if (nome == null || nome.trim().isEmpty) return;
    final adicionou = vm.adicionarMomento(nome);
    if (!adicionou && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Esse momento já existe.')),
      );
    }
  }

  Future<void> _adicionarMusica(
    BuildContext context,
    SetlistEditorVM vm,
    int indiceMomento,
  ) async {
    if (vm.cifrasDisponiveis.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Nenhuma cifra no vault. Importe cifras antes de montar o setlist.',
          ),
        ),
      );
      return;
    }

    final selecionada = await showModalBottomSheet<Cifra>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.88,
        child: _SeletorCifras(cifras: vm.cifrasDisponiveis),
      ),
    );

    if (selecionada != null) {
      vm.adicionarCifra(indiceMomento, selecionada);
    }
  }

  Future<void> _editarNota(
    BuildContext context,
    SetlistEditorVM vm,
    int indiceMomento,
    int indiceItem,
  ) async {
    final item = vm.momentos[indiceMomento].itens[indiceItem];
    final controller = TextEditingController(text: item.nota);
    final nota = await showDialog<String>(
      context: context,
      builder: (dialogoContexto) => AlertDialog(
        title: const Text('Observação da música'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Ex.: Verso 1-2 + Refrão x2',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogoContexto).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogoContexto).pop(controller.text),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (nota != null) {
      vm.atualizarNota(indiceMomento, indiceItem, nota.trim());
    }
  }

  Future<void> _gerarPdf(
    BuildContext context,
    SetlistEditorVM vm,
  ) async {
    try {
      await vm.compartilharPdf();
    } catch (falha) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível gerar o PDF: $falha')),
      );
    }
  }

  Future<void> _copiar(BuildContext context, SetlistEditorVM vm) async {
    await Clipboard.setData(ClipboardData(text: vm.textoCompartilhavel));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Texto do setlist copiado.')),
    );
  }

  Future<void> _compartilhar(
    BuildContext context,
    SetlistEditorVM vm,
  ) async {
    try {
      await SharePlus.instance.share(
        ShareParams(
          subject: vm.titulo,
          text: vm.textoCompartilhavel,
        ),
      );
    } catch (falha) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível compartilhar: $falha')),
      );
    }
  }
}

class _ItemEditor extends StatelessWidget {
  const _ItemEditor({
    required this.item,
    required this.cifra,
    required this.indice,
    required this.onTocado,
    required this.onNota,
    required this.onMover,
    required this.onRemover,
  });

  final ItemSetlist item;
  final Cifra? cifra;
  final int indice;
  final ValueChanged<bool> onTocado;
  final VoidCallback onNota;
  final ValueChanged<int> onMover;
  final VoidCallback onRemover;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final corSuave = theme.colorScheme.onSurface.withValues(alpha: 0.58);

    return Container(
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.035),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.only(left: 2, right: 0),
        leading: SizedBox(
          width: 30,
          height: 30,
          child: Checkbox(
            value: item.estaTocado,
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            onChanged: (valor) => onTocado(valor ?? false),
          ),
        ),
        title: Text(
          cifra?.titulo ?? item.cifraId,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          [
            if (cifra?.artista != null && cifra!.artista.isNotEmpty)
              cifra!.artista,
            if (item.nota.trim().isNotEmpty) item.nota.trim(),
          ].join(' • '),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(color: corSuave),
        ),
        trailing: PopupMenuButton<String>(
          tooltip: 'Ações da música',
          icon: const Icon(Icons.more_vert_rounded, size: 20),
          onSelected: (valor) {
            switch (valor) {
              case 'nota':
                onNota();
                break;
              case 'cima':
                onMover(-1);
                break;
              case 'baixo':
                onMover(1);
                break;
              case 'remover':
                onRemover();
                break;
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(
              value: 'nota',
              child: Text('Editar observação'),
            ),
            PopupMenuItem(
              value: 'cima',
              child: Text('Mover para cima'),
            ),
            PopupMenuItem(
              value: 'baixo',
              child: Text('Mover para baixo'),
            ),
            PopupMenuDivider(),
            PopupMenuItem(value: 'remover', child: Text('Remover')),
          ],
        ),
      ),
    );
  }
}

class _SeletorCifras extends StatefulWidget {
  const _SeletorCifras({required this.cifras});

  final List<Cifra> cifras;

  @override
  State<_SeletorCifras> createState() => _SeletorCifrasState();
}

class _SeletorCifrasState extends State<_SeletorCifras> {
  final TextEditingController _controller = TextEditingController();
  String _busca = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final alvo = normalizarTexto(_busca);
    final filtradas = widget.cifras.where((cifra) {
      if (alvo.isEmpty) return true;
      return normalizarTexto(
        '${cifra.titulo} ${cifra.artista} ${cifra.tags.join(' ')}',
      ).contains(alvo);
    }).toList();

    final theme = Theme.of(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: TextField(
            controller: _controller,
            autofocus: false,
            onChanged: (valor) => setState(() => _busca = valor),
            decoration: const InputDecoration(
              isDense: true,
              hintText: 'Buscar cifra para adicionar',
              prefixIcon: Icon(Icons.search_rounded, size: 20),
            ),
          ),
        ),
        Expanded(
          child: filtradas.isEmpty
              ? Center(
                  child: Text(
                    'Nenhuma cifra encontrada.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.6),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: filtradas.length,
                  itemBuilder: (contexto, indice) {
                    final cifra = filtradas[indice];
                    return ListTile(
                      leading: TomBadge(tom: cifra.tom),
                      title: Text(
                        cifra.titulo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        [
                          cifra.artista,
                          if (cifra.momentos.isNotEmpty)
                            cifra.momentos.first,
                        ].join(' • '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: const Icon(Icons.add_circle_outline_rounded),
                      onTap: () => Navigator.of(context).pop(cifra),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
