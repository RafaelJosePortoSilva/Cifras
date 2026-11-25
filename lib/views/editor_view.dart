import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/app_config.dart';
import '../models/cifra.dart';
import '../services/parser_service.dart';
import '../services/vault_service.dart';
import '../viewmodels/editor_vm.dart';
import 'widgets/filtro_chip.dart';
import 'widgets/metadata_form.dart';

/// Editor de cifra em tela cheia, com destaque de acordes.
class EditorView extends StatelessWidget {
  const EditorView({super.key, this.cifra});

  final Cifra? cifra;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<EditorVM>(
      create: (contexto) => EditorVM(
        vault: contexto.read<VaultService>(),
        parser: contexto.read<ParserService>(),
        cifra: cifra,
      ),
      child: const _EditorBody(),
    );
  }
}

class _EditorBody extends StatelessWidget {
  const _EditorBody();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<EditorVM>();
    final theme = Theme.of(context);
    final corSuave = theme.colorScheme.onSurface.withValues(alpha: 0.6);

    return Scaffold(
      appBar: AppBar(
        title: Text(vm.editando ? 'Editar cifra' : 'Nova cifra'),
        actions: [
          IconButton(
            tooltip: 'Salvar',
            onPressed: vm.salvando ? null : () => _salvar(context),
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
      body: Column(
        children: [
          InkWell(
            onTap: () => _abrirMetadados(context, vm),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 12, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppConfig.primaryColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.edit_note_rounded,
                      color: AppConfig.primaryColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vm.titulo.trim().isEmpty
                              ? 'Sem título'
                              : vm.titulo,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          [
                            if (vm.artista.trim().isNotEmpty) vm.artista,
                            if (vm.tom.trim().isNotEmpty) 'Tom ${vm.tom}',
                            if (vm.tipo.trim().isNotEmpty) vm.tipo,
                          ].join(' • '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: corSuave,
                          ),
                        ),
                        if (vm.momentos.isNotEmpty || vm.temas.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 5,
                            runSpacing: 4,
                            children: [
                              for (final momento in vm.momentos.take(3))
                                FiltroChip(label: momento, mini: true),
                              for (final tema in vm.temas.take(2))
                                FiltroChip(
                                  label: tema,
                                  mini: true,
                                  cor: AppConfig.accentColor,
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: corSuave, size: 22),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
              child: TextField(
                controller: vm.corpo,
                expands: true,
                maxLines: null,
                minLines: null,
                textAlignVertical: TextAlignVertical.top,
                keyboardType: TextInputType.multiline,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontFamilyFallback: ['Roboto Mono', 'Courier New'],
                  fontSize: 15,
                  height: 1.5,
                ),
                decoration: const InputDecoration(
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  hintText: 'Escreva os acordes sobre a letra.\n'
                      'Use [Intro], [Refrão] etc. para separar seções.',
                ),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: theme.dividerTheme.color ?? Colors.black12,
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Text(
                        'Inserir:',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: corSuave,
                        ),
                      ),
                      const SizedBox(width: 8),
                      for (final nome in const [
                        'Intro',
                        'Verso 1',
                        'Refrão',
                        'Ponte',
                        'Final',
                      ])
                        Padding(
                          padding: const EdgeInsets.only(right: 5),
                          child: ActionChip(
                            label: Text(nome),
                            onPressed: () => _inserirSecao(vm, nome),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _abrirMetadados(BuildContext context, EditorVM vm) async {
    final dados = await showMetadataCifraSheet(
      context,
      inicial: vm.metadados,
    );
    if (dados != null) vm.aplicarMetadados(dados);
  }

  Future<void> _salvar(BuildContext context) async {
    final vm = context.read<EditorVM>();
    final cifra = await vm.salvar();
    if (!context.mounted) return;
    if (cifra == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(vm.erro ?? 'Não foi possível salvar.')),
      );
      return;
    }
    Navigator.of(context).pop(cifra);
  }

  void _inserirSecao(EditorVM vm, String nome) {
    final controller = vm.corpo;
    final texto = controller.text;
    final selecao = controller.selection;
    final inicio = selecao.isValid ? selecao.start : texto.length;
    final fim = selecao.isValid ? selecao.end : texto.length;
    final insercao = '\n\n[$nome]\n';

    controller.value = TextEditingValue(
      text: texto.replaceRange(inicio, fim, insercao),
      selection: TextSelection.collapsed(offset: inicio + insercao.length),
    );
  }
}
