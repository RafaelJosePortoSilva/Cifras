import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'services/parser_service.dart';
import 'services/pdf_service.dart';
import 'services/search_service.dart';
import 'services/share_service.dart';
import 'services/vault_service.dart';
import 'viewmodels/library_vm.dart';
import 'viewmodels/setlist_vm.dart';
import 'viewmodels/settings_vm.dart';

/// Ponto de entrada do CifraVault.
///
/// Todos os serviços são criados uma única vez e injetados via `provider`.
/// O vault é lido do sistema de arquivos sob demanda; não há banco de dados.
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final parser = ParserService();
  final vault = VaultService(parser: parser);
  final search = SearchService();
  final pdf = PdfService();
  final share = ShareHandler(parser: parser);

  runApp(
    MultiProvider(
      providers: [
        Provider<ParserService>.value(value: parser),
        Provider<VaultService>.value(value: vault),
        Provider<SearchService>.value(value: search),
        Provider<PdfService>.value(value: pdf),
        Provider<ShareHandler>.value(value: share),
        ChangeNotifierProvider<LibraryVM>(
          create: (_) => LibraryVM(vault: vault, search: search),
        ),
        ChangeNotifierProvider<SetlistVM>(
          create: (_) => SetlistVM(vault: vault),
        ),
        ChangeNotifierProvider<SettingsVM>(
          create: (_) => SettingsVM(vault, share)..carregar(),
        ),
      ],
      child: CifraVaultApp(share: share),
    ),
  );
}
