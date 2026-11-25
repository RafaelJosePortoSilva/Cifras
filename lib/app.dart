import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'config/app_config.dart';
import 'config/theme.dart';
import 'router/routes.dart';
import 'services/share_service.dart';
import 'viewmodels/settings_vm.dart';

/// `MaterialApp` do CifraVault, com tema reativo e roteamento nomeado.
class CifraVaultApp extends StatefulWidget {
  const CifraVaultApp({super.key, required this.share});

  final ShareHandler share;

  @override
  State<CifraVaultApp> createState() => _CifraVaultAppState();
}

class _CifraVaultAppState extends State<CifraVaultApp> {
  final GlobalKey<NavigatorState> _navegador = GlobalKey<NavigatorState>();
  bool _linkInicialLido = false;

  @override
  void initState() {
    super.initState();
    widget.share.escutar(_tratarLink);
    WidgetsBinding.instance.addPostFrameCallback((_) => _lerLinkInicial());
  }

  Future<void> _lerLinkInicial() async {
    if (_linkInicialLido) return;
    _linkInicialLido = true;
    final uri = await widget.share.linkInicial();
    if (uri != null) _tratarLink(uri);
  }

  void _tratarLink(Uri uri) {
    if (!mounted) return;
    if (uri.scheme != 'http' && uri.scheme != 'https') return;
    final navegador = _navegador.currentState;
    if (navegador == null) return;
    navegador.pushNamed(
      Routes.importar,
      arguments: ImportArgs(url: uri.toString()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsVM>();

    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      navigatorKey: _navegador,
      theme: AppTheme.claro(),
      darkTheme: AppTheme.escuro(),
      themeMode: settings.themeMode,
      initialRoute: Routes.inicial,
      onGenerateRoute: Routes.onGenerateRoute,
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [
        Locale('pt', 'BR'),
        Locale('pt'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
