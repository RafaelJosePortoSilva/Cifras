import 'package:flutter/material.dart';

import '../config/app_config.dart';
import 'chord_utils.dart';

/// Controller de texto que colore linhas de acordes e cabeçalhos de seção.
class ChordHighlightController extends TextEditingController {
  ChordHighlightController({super.text});

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final base = style ?? const TextStyle();
    final escuro = Theme.of(context).brightness == Brightness.dark;
    final corAcorde =
        escuro ? AppConfig.accentColor : const Color(0xFF1565C0);
    final corSecao =
        escuro ? AppConfig.primaryColor : const Color(0xFFE65100);

    final linhas = text.split('\n');
    final filhos = <TextSpan>[];

    for (var i = 0; i < linhas.length; i++) {
      final linha = linhas[i];
      final limpa = linha.trim();

      final ehSecao = limpa.startsWith('[') && limpa.endsWith(']');
      final ehAcorde = !ehSecao &&
          limpa.isNotEmpty &&
          isLinhaDeAcordes(linha);

      filhos.add(
        TextSpan(
          text: linha,
          style: ehSecao
              ? base.copyWith(color: corSecao, fontWeight: FontWeight.w700)
              : ehAcorde
                  ? base.copyWith(
                      color: corAcorde,
                      fontWeight: FontWeight.w600,
                    )
                  : null,
        ),
      );

      if (i != linhas.length - 1) {
        filhos.add(const TextSpan(text: '\n'));
      }
    }

    return TextSpan(style: base, children: filhos);
  }
}
