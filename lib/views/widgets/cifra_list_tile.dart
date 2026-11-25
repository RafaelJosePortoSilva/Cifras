import 'package:flutter/material.dart';

import '../../models/cifra.dart';
import 'filtro_chip.dart';

/// Item da lista de cifras da biblioteca.
class CifraListTile extends StatelessWidget {
  const CifraListTile({
    super.key,
    required this.cifra,
    required this.onTap,
  });

  final Cifra cifra;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final corSuave = theme.colorScheme.onSurface.withValues(alpha: 0.6);

    final chips = <String>[
      if (cifra.momentos.isNotEmpty) cifra.momentos.first,
      ...cifra.temas.take(2),
    ];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      clipBehavior: Clip.antiAlias,
      color: theme.colorScheme.surface.withValues(alpha: 0.65),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TomBadge(tom: cifra.tom),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cifra.titulo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      cifra.artista,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: corSuave,
                      ),
                    ),
                    if (chips.isNotEmpty) ...[
                      const SizedBox(height: 7),
                      MiniChips(itens: chips),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                color: corSuave,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
