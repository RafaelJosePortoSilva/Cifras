import 'package:flutter/material.dart';

import '../models/cifra.dart';
import '../models/filtros.dart';
import '../models/setlist.dart';
import '../views/cifra_viewer_view.dart';
import '../views/editor_view.dart';
import '../views/filtros_view.dart';
import '../views/import_view.dart';
import '../views/library_view.dart';
import '../views/new_setlist_view.dart';
import '../views/setlist_detail_view.dart';
import '../views/setlist_view.dart';
import '../views/settings_view.dart';

/// Nomes de rotas e argumentos tipados usados pelo `Navigator`.
class Routes {
  Routes._();

  static const String inicial = '/';
  static const String viewer = '/cifra';
  static const String editor = '/editor';
  static const String setlists = '/setlists';
  static const String setlistNova = '/setlists/nova';
  static const String setlistDetalhe = '/setlists/detalhe';
  static const String filtros = '/filtros';
  static const String importar = '/importar';
  static const String config = '/config';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case inicial:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const LibraryView(),
        );

      case viewer:
        final argumento = settings.arguments;
        if (argumento is Cifra) {
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => CifraViewer(cifra: argumento),
          );
        }
        return _rotaInvalida(settings, 'Cifra não informada.');

      case editor:
        final argumento = settings.arguments;
        final args = argumento is EditorArgs ? argumento : const EditorArgs();
        return MaterialPageRoute<Cifra?>(
          settings: settings,
          builder: (_) => EditorView(cifra: args.cifra),
        );

      case setlists:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const SetlistsView(),
        );

      case setlistNova:
        final argumento = settings.arguments;
        final args = argumento is SetlistEditorArgs
            ? argumento
            : const SetlistEditorArgs();
        return MaterialPageRoute<Setlist?>(
          settings: settings,
          builder: (_) => NewSetlistView(setlist: args.setlist),
        );

      case setlistDetalhe:
        final argumento = settings.arguments;
        if (argumento is SetlistDetailArgs) {
          return MaterialPageRoute<bool>(
            settings: settings,
            builder: (_) => SetlistDetailView(setlist: argumento.setlist),
          );
        }
        return _rotaInvalida(settings, 'Setlist não informado.');

      case filtros:
        final argumento = settings.arguments;
        return MaterialPageRoute<Object?>(
          settings: settings,
          builder: (_) => FiltrosView(
            filtrosIniciais:
                argumento is FiltrosCifra ? argumento : null,
          ),
        );

      case importar:
        final argumento = settings.arguments;
        final url = argumento is ImportArgs ? argumento.url : null;
        return MaterialPageRoute<bool>(
          settings: settings,
          builder: (_) => ImportView(urlInicial: url),
        );

      case config:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const SettingsView(),
        );

      default:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const LibraryView(),
        );
    }
  }

  static Route<dynamic> _rotaInvalida(RouteSettings settings, String mensagem) {
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (contexto) => Scaffold(
        appBar: AppBar(title: const Text('CifraVault')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(mensagem, textAlign: TextAlign.center),
          ),
        ),
      ),
    );
  }
}

/// Argumentos da rota do editor (`null` = nova cifra).
class EditorArgs {
  const EditorArgs({this.cifra});

  final Cifra? cifra;
}

/// Argumentos da rota de criação/edição de setlist.
class SetlistEditorArgs {
  const SetlistEditorArgs({this.setlist});

  final Setlist? setlist;
}

/// Argumentos da rota de detalhe do setlist.
class SetlistDetailArgs {
  const SetlistDetailArgs({required this.setlist});

  final Setlist setlist;
}

/// Argumentos da importação (usado também pelo share handler).
class ImportArgs {
  const ImportArgs({this.url});

  final String? url;
}
