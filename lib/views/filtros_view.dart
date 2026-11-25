import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/filtros.dart';
import '../services/search_service.dart';
import '../viewmodels/filters_vm.dart';
import 'widgets/filtro_chip.dart';

/// Tela de filtros combinados da biblioteca.
class FiltrosView extends StatelessWidget {
  const FiltrosView({super.key, this.filtrosIniciais});

  final FiltrosCifra? filtrosIniciais;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<FiltersVM>(
      create: (contexto) => FiltersVM(
        search: contexto.read<SearchService>(),
        inicial: filtrosIniciais,
      ),
      child: const _FiltrosBody(),
    );
  }
}

class _FiltrosBody extends StatelessWidget {
  const _FiltrosBody();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FiltersVM>();
    final filtros = vm.filtros;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Filtros'),
        actions: [
          TextButton(
            onPressed: vm.totalAtivos == 0 ? null : vm.limpar,
            child: const Text('Limpar'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          _Grupo(
            titulo: 'Momento',
            descricao: 'A cifra precisa ter todos os momentos selecionados.',
            child: Wrap(
              spacing: 7,
              runSpacing: 6,
              children: [
                for (final momento in vm.momentosDisponiveis)
                  FiltroChip(
                    label: momento,
                    selecionado: filtros.momentos.contains(momento),
                    onTap: () => vm.alternarMomento(momento),
                  ),
              ],
            ),
          ),
          _Grupo(
            titulo: 'Tom',
            descricao: 'Exibe cifras em qualquer um dos tons selecionados.',
            child: Wrap(
              spacing: 7,
              runSpacing: 6,
              children: [
                for (final tom in vm.tonsDisponiveis)
                  FiltroChip(
                    label: tom,
                    selecionado: filtros.tons.contains(tom),
                    onTap: () => vm.alternarTom(tom),
                    cor: const Color(0xFF66BB6A),
                  ),
              ],
            ),
          ),
          _Grupo(
            titulo: 'Tema',
            descricao: 'Tempo litúrgico ou tema da música.',
            child: Wrap(
              spacing: 7,
              runSpacing: 6,
              children: [
                for (final tema in vm.temasDisponiveis)
                  FiltroChip(
                    label: tema,
                    selecionado: filtros.temas.contains(tema),
                    onTap: () => vm.alternarTema(tema),
                    cor: const Color(0xFFBA68C8),
                  ),
              ],
            ),
          ),
          _Grupo(
            titulo: 'Tipo',
            descricao: 'Selecione um tipo de música (opcional).',
            child: Wrap(
              spacing: 7,
              runSpacing: 6,
              children: [
                for (final tipo in vm.tiposDisponiveis)
                  FiltroChip(
                    label: tipo,
                    selecionado: filtros.tipo == tipo,
                    onTap: () => vm.selecionarTipo(tipo),
                    cor: const Color(0xFF4DB6AC),
                  ),
              ],
            ),
          ),
          _Grupo(
            titulo: 'Fonte',
            descricao: 'Onde a cifra foi importada.',
            child: Wrap(
              spacing: 7,
              runSpacing: 6,
              children: [
                for (final fonte in vm.fontesDisponiveis)
                  FiltroChip(
                    label: fonte,
                    selecionado: filtros.fontes.contains(fonte),
                    onTap: () => vm.alternarFonte(fonte),
                    cor: const Color(0xFF9E9E9E),
                  ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton.icon(
            onPressed: () =>
                Navigator.of(context).pop(vm.filtros.clonar()),
            icon: const Icon(Icons.filter_alt_rounded),
            label: Text(
              vm.totalAtivos == 0
                  ? 'Aplicar filtros'
                  : 'Aplicar ${vm.totalAtivos} filtro(s)',
            ),
          ),
        ),
      ),
    );
  }
}

class _Grupo extends StatelessWidget {
  const _Grupo({
    required this.titulo,
    required this.descricao,
    required this.child,
  });

  final String titulo;
  final String descricao;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            descricao,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
