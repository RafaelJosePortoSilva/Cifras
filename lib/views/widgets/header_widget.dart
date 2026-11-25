import 'package:flutter/material.dart';

import '../../config/app_config.dart';

/// Cabeçalho da biblioteca: marca, busca e atalhos.
class HeaderWidget extends StatefulWidget {
  const HeaderWidget({
    super.key,
    required this.onChanged,
    required this.onFiltros,
    required this.filtrosAtivos,
    required this.onSetlists,
    required this.onConfiguracoes,
    required this.total,
  });

  final ValueChanged<String> onChanged;
  final VoidCallback onFiltros;
  final int filtrosAtivos;
  final VoidCallback onSetlists;
  final VoidCallback onConfiguracoes;
  final int total;

  @override
  State<HeaderWidget> createState() => _HeaderWidgetState();
}

class _HeaderWidgetState extends State<HeaderWidget> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final corSuave = theme.colorScheme.onSurface.withValues(alpha: 0.6);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppConfig.primaryColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.library_music_rounded,
                  color: AppConfig.primaryColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppConfig.appName,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                    ),
                    Text(
                      widget.total == 1
                          ? '1 cifra no vault'
                          : '${widget.total} cifras no vault',
                      style: theme.textTheme.bodySmall?.copyWith(color: corSuave),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Setlists',
                onPressed: widget.onSetlists,
                icon: const Icon(Icons.queue_music_rounded),
              ),
              IconButton(
                tooltip: 'Configurações',
                onPressed: widget.onConfiguracoes,
                icon: const Icon(Icons.settings_outlined),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _controller,
            textInputAction: TextInputAction.search,
            onChanged: widget.onChanged,
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Buscar título, artista ou tag',
              prefixIcon: const Icon(Icons.search_rounded, size: 21),
              suffixIcon: _controller.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Limpar busca',
                      icon: const Icon(Icons.close_rounded, size: 19),
                      onPressed: () {
                        _controller.clear();
                        setState(() {});
                        widget.onChanged('');
                      },
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: widget.onFiltros,
                icon: const Icon(Icons.tune_rounded, size: 18),
                label: Text(
                  widget.filtrosAtivos == 0
                      ? 'Filtros'
                      : 'Filtros · ${widget.filtrosAtivos}',
                ),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  side: BorderSide(
                    color: widget.filtrosAtivos == 0
                        ? (theme.dividerTheme.color ??
                            theme.colorScheme.outlineVariant)
                        : AppConfig.primaryColor,
                  ),
                  foregroundColor: widget.filtrosAtivos == 0
                      ? theme.colorScheme.onSurface
                      : AppConfig.primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
