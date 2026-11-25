import 'package:flutter/material.dart';

import '../../config/app_config.dart';
import '../../models/cifra.dart';
import '../../utils/chord_utils.dart';

/// Widget principal de renderização da cifra: acordes sobre a letra.
///
/// Mantém as linhas de acordes em fonte monoespaçada, com transposição
/// aplicada linha a linha sem perder as colunas originais. O conteúdo rola
/// horizontalmente quando a linha é maior que a tela.
class ChordDisplay extends StatelessWidget {
  const ChordDisplay({
    super.key,
    required this.secoes,
    this.semitons = 0,
    this.escalaFonte = 1.0,
    this.preferirBemois = false,
    this.mostrarTitulosSecao = true,
    this.corAcorde,
  });

  final List<CifraSecao> secoes;
  final int semitons;
  final double escalaFonte;
  final bool preferirBemois;
  final bool mostrarTitulosSecao;
  final Color? corAcorde;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final escuro = theme.brightness == Brightness.dark;
    final cor = corAcorde ??
        (escuro ? AppConfig.accentColor : const Color(0xFF1565C0));

    final secoesVisiveis =
        secoes.where((secao) => secao.linhas.isNotEmpty).toList();
    if (secoesVisiveis.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Esta cifra ainda não tem conteúdo.',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontStyle: FontStyle.italic,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      );
    }

    final exibirTitulos = mostrarTitulosSecao &&
        !(secoesVisiveis.length == 1 && secoesVisiveis.first.titulo == 'Cifra');

    final estiloAcorde = TextStyle(
      fontFamily: 'monospace',
      fontFamilyFallback: const ['Roboto Mono', 'Courier New'],
      fontSize: 15 * escalaFonte,
      height: 1.3,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.3,
      color: cor,
    );
    final estiloLetra = TextStyle(
      fontSize: 15 * escalaFonte,
      height: 1.45,
      color: theme.colorScheme.onSurface,
    );
    final estiloTitulo = TextStyle(
      fontSize: 12.5 * escalaFonte,
      height: 1.2,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.8,
      color: escuro ? AppConfig.primaryColor : const Color(0xFFE65100),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final larguraMinima =
            constraints.maxWidth.isFinite ? constraints.maxWidth : 320.0;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: larguraMinima),
            child: SelectionArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < secoesVisiveis.length; i++) ...[
                    if (i > 0) SizedBox(height: 12 * escalaFonte),
                    if (exibirTitulos)
                      _TituloSecao(
                        titulo: secoesVisiveis[i].titulo,
                        estilo: estiloTitulo,
                        cor: cor,
                      ),
                    for (final linha in secoesVisiveis[i].linhas)
                      _LinhaCifra(
                        linha: linha,
                        semitons: semitons,
                        preferirBemois: preferirBemois,
                        estiloAcorde: estiloAcorde,
                        estiloLetra: estiloLetra,
                        escala: escalaFonte,
                      ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TituloSecao extends StatelessWidget {
  const _TituloSecao({
    required this.titulo,
    required this.estilo,
    required this.cor,
  });

  final String titulo;
  final TextStyle estilo;
  final Color cor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 3,
            height: 15,
            decoration: BoxDecoration(
              color: cor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 7),
          Text(titulo.toUpperCase(), style: estilo),
        ],
      ),
    );
  }
}

class _LinhaCifra extends StatelessWidget {
  const _LinhaCifra({
    required this.linha,
    required this.semitons,
    required this.preferirBemois,
    required this.estiloAcorde,
    required this.estiloLetra,
    required this.escala,
  });

  final CifraLinha linha;
  final int semitons;
  final bool preferirBemois;
  final TextStyle estiloAcorde;
  final TextStyle estiloLetra;
  final double escala;

  @override
  Widget build(BuildContext context) {
    if (linha.isBlank) {
      return SizedBox(height: 9 * escala);
    }

    final acordes = linha.temAcordes
        ? (semitons % 12 == 0
            ? linha.acordes!
            : transporLinhaAcordes(
                linha.acordes!,
                semitons,
                preferirBemois: preferirBemois,
              ))
        : null;

    return Padding(
      padding: EdgeInsets.only(bottom: 7 * escala),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (acordes != null)
            Text(
              acordes,
              softWrap: false,
              style: estiloAcorde,
            ),
          if (linha.temTexto)
            Text(
              linha.texto,
              softWrap: false,
              style: estiloLetra,
            ),
        ],
      ),
    );
  }
}
