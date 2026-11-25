import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/app_config.dart';
import '../viewmodels/library_vm.dart';
import '../viewmodels/setlist_vm.dart';
import '../viewmodels/settings_vm.dart';

/// Configurações do app: tema, pasta do vault e informações.
class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<SettingsVM>().carregar();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SettingsVM>();
    final theme = Theme.of(context);
    final corSuave = theme.colorScheme.onSurface.withValues(alpha: 0.6);

    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: vm.carregando
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 28),
              children: [
                _titulo('Aparência'),
                Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: SwitchListTile(
                    value: vm.themeMode == ThemeMode.dark,
                    onChanged: (escuro) => vm.definirTemaEscuro(escuro),
                    secondary: Icon(
                      vm.themeMode == ThemeMode.dark
                          ? Icons.dark_mode_rounded
                          : Icons.light_mode_rounded,
                      color: AppConfig.primaryColor,
                    ),
                    title: const Text('Tema escuro'),
                    subtitle: const Text(
                      'Recomendado para uso durante celebrações.',
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _titulo('Pasta do vault'),
                Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.folder_open_rounded,
                              size: 20,
                              color: AppConfig.accentColor,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Local dos arquivos',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SelectableText(
                          vm.vaultPath ?? 'Carregando...',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: corSuave,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          AppConfig.descricaoVault,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: corSuave,
                          ),
                        ),
                        if (!vm.temAcessoTodosArquivos) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.errorContainer
                                  .withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Acesso a todos os arquivos desativado',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: theme.colorScheme.error,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'No Android 11+, o app precisa dessa permissão '
                                  'para ler arquivos .md em pastas externas '
                                  '(como Documents). Ative e volte ao app.',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: corSuave,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                FilledButton.tonalIcon(
                                  onPressed: _solicitarAcessoArquivos,
                                  icon: const Icon(Icons.security_rounded, size: 18),
                                  label: const Text('Permitir acesso a arquivos'),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (vm.erro != null) ...[
                          const SizedBox(height: 10),
                          Text(
                            vm.erro!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.error,
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            FilledButton.icon(
                              onPressed: _escolherPasta,
                              icon: const Icon(
                                Icons.drive_folder_upload_outlined,
                                size: 18,
                              ),
                              label: const Text('Alterar pasta'),
                            ),
                            OutlinedButton.icon(
                              onPressed: _restaurarPadrao,
                              icon: const Icon(
                                Icons.settings_backup_restore_rounded,
                                size: 18,
                              ),
                              label: const Text('Pasta padrão'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _titulo('Estrutura'),
                Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _linhaEstrutura(
                          '${AppConfig.vaultSubDirCifras}/',
                          'Arquivos .md de cifras',
                        ),
                        const SizedBox(height: 8),
                        _linhaEstrutura(
                          '${AppConfig.vaultSubDirSetlists}/',
                          'Arquivos .md de setlists',
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'As pastas são criadas automaticamente. Não há banco '
                          'de dados: os arquivos Markdown são a fonte de verdade '
                          'e podem ser editados em qualquer editor de texto.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: corSuave,
                          ),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: _recarregarTudo,
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: const Text('Recarregar biblioteca'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _titulo('Sobre'),
                Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: AppConfig.primaryColor
                                    .withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.library_music_rounded,
                                color: AppConfig.primaryColor,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppConfig.appName,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  'Versão ${AppConfig.version}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: corSuave,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Gerenciador local de cifras e setlists em Markdown, '
                          'com transposição, filtros litúrgicos, importação de '
                          'sites e exportação em PDF.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: corSuave,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Limitações: o acesso a pastas externas depende do '
                          'seletor de diretórios do Android (SAF). Alguns sites '
                          'podem bloquear o download automático; nesse caso use '
                          'a aba HTML da importação.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: corSuave,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _titulo(String texto) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 4, 6, 4),
      child: Text(
        texto.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.55),
            ),
      ),
    );
  }

  Widget _linhaEstrutura(String pasta, String descricao) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.folder_outlined,
          size: 17,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              children: [
                TextSpan(
                  text: pasta,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextSpan(text: '  $descricao'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _escolherPasta() async {
    final vm = context.read<SettingsVM>();
    try {
      // ignore: deprecated_member_use
      final pasta = await FilePicker.getDirectoryPath(
        dialogTitle: 'Escolha a pasta do vault',
      );
      if (pasta == null || pasta.trim().isEmpty) return;
      final ok = await vm.alterarVault(pasta);
      if (!mounted) return;
      if (ok) {
        await _recarregarTudo();
        if (!mounted) return;
        final lib = context.read<LibraryVM>();
        final msg = lib.cifras.isEmpty
            ? 'Pasta atualizada, mas nenhuma cifra .md foi encontrada. '
              'Verifique se a pasta contém cifras/*.md ou arquivos .md.'
            : 'Pasta atualizada. ${lib.cifras.length} cifra(s) carregada(s).';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    } catch (falha) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível abrir o seletor: $falha')),
      );
    }
  }

  Future<void> _restaurarPadrao() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogoContexto) => AlertDialog(
        title: const Text('Usar pasta padrão?'),
        content: const Text(
          'O app voltará a usar a pasta CifraVault nos documentos do '
          'dispositivo. Os arquivos da pasta atual não serão apagados.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogoContexto).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogoContexto).pop(true),
            child: const Text('Usar padrão'),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;

    final ok = await context.read<SettingsVM>().usarVaultPadrao();
    if (!mounted) return;
    if (ok) {
      await _recarregarTudo();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pasta padrão restaurada.')),
      );
    }
  }

  Future<void> _solicitarAcessoArquivos() async {
    final vm = context.read<SettingsVM>();
    await vm.solicitarAcessoTodosArquivos();
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogoContexto) => AlertDialog(
        title: const Text('Permissão necessária'),
        content: const Text(
          'Na tela do sistema, ative "Permitir acesso para gerenciar '
          'todos os arquivos" para o CifraVault e volte ao app.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogoContexto).pop(),
            child: const Text('Já ativei'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    await vm.atualizarPermissaoArquivos();
    await _recarregarTudo();
  }

  Future<void> _recarregarTudo() async {
    if (!mounted) return;
    await context.read<SettingsVM>().atualizarPermissaoArquivos();
    if (!mounted) return;
    await context.read<LibraryVM>().carregar(silencioso: true);
    if (!mounted) return;
    await context.read<SetlistVM>().carregar();
  }
}
