import 'package:flutter/material.dart';

import '../../config/app_config.dart';
import '../../models/cifra.dart';
import '../../models/setlist.dart';

/// Card expansível de um momento litúrgico com suas músicas.
class MomentoCard extends StatelessWidget {
  const MomentoCard({
    super.key,
    required this.momento,
    required this.cifras,
    this.onAbrirCifra,
    this.onAlternarTocado,
    this.inicialmenteExpandido = false,
  });

  final MomentoLiturgo momento;
  final Map<String, Cifra?> cifras;
  final void Function(Cifra cifra)? onAbrirCifra;
  final void Function(int indice, bool valor)? onAlternarTocado;
  final bool inicialmenteExpandido;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final corSuave = theme.colorScheme.onSurface.withValues(alpha: 0.6);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      clipBehavior: Clip.antiAlias,
      color: theme.colorScheme.surface.withValues(alpha: 0.65),
      child: ExpansionTile(
        initiallyExpanded: inicialmenteExpandido,
        shape: const Border(),
        collapsedShape: const Border(),
        leading: Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppConfig.primaryColor.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            AppConfig.emojiMomento(momento.nome),
            style: const TextStyle(fontSize: 18),
          ),
        ),
        title: Text(
          momento.nome,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          momento.itens.isEmpty
              ? 'Sem músicas'
              : '${momento.itens.length} música(s)',
          style: theme.textTheme.bodySmall?.copyWith(color: corSuave),
        ),
        childrenPadding: const EdgeInsets.only(bottom: 6),
        children: [
          if (momento.itens.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Nenhuma música neste momento.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: corSuave,
                  ),
                ),
              ),
            )
          else
            for (var i = 0; i < momento.itens.length; i++)
              _ItemMomento(
                item: momento.itens[i],
                cifra: cifras[momento.itens[i].cifraId],
                indice: i,
                onAbrirCifra: onAbrirCifra,
                onAlternarTocado: onAlternarTocado,
              ),
        ],
      ),
    );
  }
}

class _ItemMomento extends StatelessWidget {
  const _ItemMomento({
    required this.item,
    required this.cifra,
    required this.indice,
    this.onAbrirCifra,
    this.onAlternarTocado,
  });

  final ItemSetlist item;
  final Cifra? cifra;
  final int indice;
  final void Function(Cifra cifra)? onAbrirCifra;
  final void Function(int indice, bool valor)? onAlternarTocado;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final corSuave = theme.colorScheme.onSurface.withValues(alpha: 0.6);
    final subtitulo = [
      if (cifra != null) cifra!.artista,
      if (item.nota.trim().isNotEmpty) item.nota.trim(),
    ].where((texto) => texto.isNotEmpty).join(' • ');

    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.only(left: 60, right: 12),
      leading: onAlternarTocado != null
          ? SizedBox(
              width: 28,
              height: 28,
              child: Checkbox(
                value: item.estaTocado,
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                onChanged: (valor) =>
                    onAlternarTocado!(indice, valor ?? false),
              ),
            )
          : CircleAvatar(
              radius: 12,
              backgroundColor: AppConfig.primaryColor.withValues(alpha: 0.16),
              child: Text(
                '${indice + 1}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppConfig.primaryColor,
                ),
              ),
            ),
      title: Text(
        cifra?.titulo ?? item.cifraId,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
          decoration: item.estaTocado ? TextDecoration.lineThrough : null,
          color: item.estaTocado ? corSuave : null,
        ),
      ),
      subtitle: subtitulo.isEmpty
          ? null
          : Text(
              subtitulo,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(color: corSuave),
            ),
      trailing: cifra == null
          ? Icon(
              Icons.link_off_rounded,
              size: 18,
              color: theme.colorScheme.error,
            )
          : IconButton(
              tooltip: 'Abrir cifra',
              icon: const Icon(Icons.chevron_right_rounded, size: 22),
              onPressed: () => onAbrirCifra?.call(cifra!),
            ),
      onTap: cifra == null ? null : () => onAbrirCifra?.call(cifra!),
    );
  }
}
