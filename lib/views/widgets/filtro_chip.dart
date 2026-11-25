import 'package:flutter/material.dart';

import '../../config/app_config.dart';

/// Chip de filtro reutilizável (selecionável) e sua variante compacta.
class FiltroChip extends StatelessWidget {
  const FiltroChip({
    super.key,
    required this.label,
    this.selecionado = false,
    this.onTap,
    this.mini = false,
    this.cor,
  });

  final String label;
  final bool selecionado;
  final VoidCallback? onTap;
  final bool mini;
  final Color? cor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final corBase = cor ?? theme.colorScheme.primary;

    if (mini) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: corBase.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: corBase.withValues(alpha: 0.35)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            height: 1.2,
            fontWeight: FontWeight.w600,
            color: corBase,
          ),
        ),
      );
    }

    return FilterChip(
      label: Text(label),
      selected: selecionado,
      onSelected: onTap == null ? null : (_) => onTap!(),
      showCheckmark: false,
      selectedColor: corBase.withValues(alpha: 0.22),
      backgroundColor: theme.colorScheme.surface,
      side: BorderSide(
        color: selecionado
            ? corBase
            : theme.dividerTheme.color ?? theme.colorScheme.outlineVariant,
      ),
      shape: const StadiumBorder(),
      labelStyle: TextStyle(
        fontSize: 12.5,
        fontWeight: selecionado ? FontWeight.w700 : FontWeight.w500,
        color: selecionado ? corBase : theme.colorScheme.onSurface,
      ),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

/// Linha de mini-chips usada nos cards da biblioteca.
class MiniChips extends StatelessWidget {
  const MiniChips({super.key, required this.itens, this.cor});

  final List<String> itens;
  final Color? cor;

  @override
  Widget build(BuildContext context) {
    if (itens.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        for (final item in itens)
          FiltroChip(label: item, mini: true, cor: cor),
      ],
    );
  }
}

/// Indicador pequeno de tom (usado nos cards de cifra).
class TomBadge extends StatelessWidget {
  const TomBadge({super.key, required this.tom});

  final String? tom;

  @override
  Widget build(BuildContext context) {
    final texto = (tom == null || tom!.trim().isEmpty) ? '?' : tom!.trim();
    return Container(
      width: 46,
      height: 46,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppConfig.primaryColor.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppConfig.primaryColor.withValues(alpha: 0.4),
        ),
      ),
      child: Text(
        texto,
        maxLines: 1,
        overflow: TextOverflow.fade,
        style: const TextStyle(
          color: AppConfig.primaryColor,
          fontWeight: FontWeight.w800,
          fontSize: 15,
        ),
      ),
    );
  }
}
