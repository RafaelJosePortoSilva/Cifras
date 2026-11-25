import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/app_config.dart';
import '../models/cifra.dart';
import '../models/filtros.dart';
import '../router/routes.dart';
import '../viewmodels/library_vm.dart';
import '../viewmodels/settings_vm.dart';
import 'widgets/cifra_list_tile.dart';
import 'widgets/header_widget.dart';

/// Tela principal: lista de todas as cifras do vault.
class LibraryView extends StatefulWidget {
  const LibraryView({super.key});

  @override
  State<LibraryView> createState() => _LibraryViewState();
}

class _LibraryViewState extends State<LibraryView>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<LibraryVM>().carregar();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      context.read<LibraryVM>().carregar(silencioso: true);
    }
  }

  Future<void> _abrirFiltros() async {
    final vm = context.read<LibraryVM>();
    final resultado = await Navigator.of(context).pushNamed(
      Routes.filtros,
      arguments: vm.filtros.clonar(),
    );
    if (resultado is FiltrosCifra) {
      vm.aplicarFiltros(resultado);
    }
  }

  Future<void> _abrirImportar() async {
    final salvou = await Navigator.of(context).pushNamed(Routes.importar);
    if (!mounted) return;
    if (salvou == true) {
      await context.read<LibraryVM>().carregar(silencioso: true);
    }
  }

  Future<void> _abrirCifra(Cifra cifra) async {
    final excluiu = await Navigator.of(context).pushNamed(
      Routes.viewer,
      arguments: cifra,
    );
    if (!mounted) return;
    if (excluiu == true) {
      await context.read<LibraryVM>().carregar(silencioso: true);
    }
  }

  Future<void> _abrirConfiguracoes() async {
    await Navigator.of(context).pushNamed(Routes.config);
    if (!mounted) return;
    await context.read<LibraryVM>().carregar(silencioso: true);
  }

  Future<void> _abrirEditorManual() async {
    final salva = await Navigator.of(context).pushNamed(
      Routes.editor,
      arguments: const EditorArgs(),
    );
    if (!mounted) return;
    if (salva is Cifra) {
      await context.read<LibraryVM>().carregar(silencioso: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LibraryVM>();

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            HeaderWidget(
              total: vm.totalCifras,
              filtrosAtivos: vm.filtrosAtivos,
              onChanged: vm.atualizarTermo,
              onFiltros: _abrirFiltros,
              onSetlists: () =>
                  Navigator.of(context).pushNamed(Routes.setlists),
              onConfiguracoes: _abrirConfiguracoes,
            ),
            if (vm.filtrosAtivos > 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 8, 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${vm.filtrosAtivos} filtro(s) ativo(s) • '
                        '${vm.resultados.length} de ${vm.totalCifras}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.6),
                            ),
                      ),
                    ),
                    TextButton(
                      onPressed: vm.limparFiltros,
                      child: const Text('Limpar'),
                    ),
                  ],
                ),
              ),
            Expanded(child: _conteudo(vm)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirImportar,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nova cifra'),
      ),
    );
  }

  Widget _conteudo(LibraryVM vm) {
    final theme = Theme.of(context);
    final corSuave = theme.colorScheme.onSurface.withValues(alpha: 0.6);

    if (vm.carregando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (vm.resultados.isEmpty) {
      final temErroVault = vm.erro != null && vm.filtrosAtivos == 0;
      return RefreshIndicator(
        onRefresh: () => vm.carregar(silencioso: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(28, 40, 28, 120),
          children: [
            Icon(
              temErroVault
                  ? Icons.folder_off_outlined
                  : vm.filtrosAtivos > 0
                      ? Icons.filter_alt_off_outlined
                      : Icons.library_music_outlined,
              size: 62,
              color: temErroVault
                  ? theme.colorScheme.error
                  : AppConfig.primaryColor,
            ),
            const SizedBox(height: 14),
            Text(
              temErroVault
                  ? 'Não foi possível ler a pasta do vault'
                  : vm.filtrosAtivos > 0
                      ? 'Nenhuma cifra com esses filtros'
                      : 'Sua biblioteca está vazia',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              temErroVault
                  ? vm.erro!
                  : (vm.filtrosAtivos > 0
                      ? 'Ajuste os filtros ou limpe a seleção.'
                      : 'Importe uma cifra por link ou crie uma do zero. '
                          'Tudo é salvo como arquivos .md na pasta do vault.'),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(color: corSuave),
            ),
            if (temErroVault) ...[
              const SizedBox(height: 16),
              Center(
                child: FilledButton.icon(
                  onPressed: () => vm.carregar(),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Tentar novamente'),
                ),
              ),
            ] else if (vm.filtrosAtivos > 0) ...[
              const SizedBox(height: 16),
              Center(
                child: OutlinedButton.icon(
                  onPressed: vm.limparFiltros,
                  icon: const Icon(Icons.clear_all_rounded),
                  label: const Text('Limpar filtros'),
                ),
              ),
            ] else ...[
              const SizedBox(height: 18),
              Center(
                child: FilledButton.icon(
                  onPressed: _abrirImportar,
                  icon: const Icon(Icons.add_link_rounded),
                  label: const Text('Importar cifra'),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton.icon(
                  onPressed: _abrirEditorManual,
                  icon: const Icon(Icons.edit_note_rounded),
                  label: const Text('Criar manualmente'),
                ),
              ),
              const SizedBox(height: 20),
              _CaminhoVault(),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => vm.carregar(silencioso: true),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 4, bottom: 110),
        itemCount: vm.resultados.length,
        itemBuilder: (contexto, indice) {
          final cifra = vm.resultados[indice];
          return CifraListTile(
            cifra: cifra,
            onTap: () => _abrirCifra(cifra),
          );
        },
      ),
    );
  }
}

class _CaminhoVault extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final caminho = context.watch<SettingsVM>().vaultPath;
    if (caminho == null || caminho.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        Text(
          'Pasta do vault',
          style: Theme.of(context).textTheme.labelSmall,
        ),
        const SizedBox(height: 2),
        SelectableText(
          caminho,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.55),
              ),
        ),
      ],
    );
  }
}

