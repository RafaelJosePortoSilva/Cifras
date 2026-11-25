import 'package:cifravault/router/routes.dart';
import 'package:flutter_test/flutter_test.dart';

/// Compila o grafo de rotas/telas e garante que as constantes não mudem.
void main() {
  test('rotas nomeadas estão definidas', () {
    expect(Routes.inicial, '/');
    expect(Routes.viewer, '/cifra');
    expect(Routes.editor, '/editor');
    expect(Routes.setlists, '/setlists');
    expect(Routes.setlistNova, '/setlists/nova');
    expect(Routes.setlistDetalhe, '/setlists/detalhe');
    expect(Routes.filtros, '/filtros');
    expect(Routes.importar, '/importar');
    expect(Routes.config, '/config');
  });
}
