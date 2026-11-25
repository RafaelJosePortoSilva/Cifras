import 'package:flutter/material.dart';

import '../../config/app_config.dart';
import '../../models/metadata_cifra.dart';
import 'filtro_chip.dart';

/// Abre a folha de edição de metadados e devolve os dados aplicados.
Future<MetadataCifraDados?> showMetadataCifraSheet(
  BuildContext context, {
  required MetadataCifraDados inicial,
}) {
  return showModalBottomSheet<MetadataCifraDados>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    builder: (contextoModal) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(contextoModal).viewInsets.bottom,
      ),
      child: FractionallySizedBox(
        heightFactor: 0.92,
        child: _MetadataSheet(inicial: inicial),
      ),
    ),
  );
}

class _MetadataSheet extends StatefulWidget {
  const _MetadataSheet({required this.inicial});

  final MetadataCifraDados inicial;

  @override
  State<_MetadataSheet> createState() => _MetadataSheetState();
}

class _MetadataSheetState extends State<_MetadataSheet> {
  late final TextEditingController _titulo;
  late final TextEditingController _artista;
  late final TextEditingController _url;
  late final TextEditingController _tags;

  late String _tom;
  late String _tipo;
  late String _fonte;
  late Set<String> _momentos;
  late Set<String> _temas;

  final Set<String> _momentosExtras = <String>{};
  final Set<String> _temasExtras = <String>{};

  String? _erroTitulo;

  @override
  void initState() {
    super.initState();
    final inicial = widget.inicial;
    _titulo = TextEditingController(text: inicial.titulo);
    _artista = TextEditingController(text: inicial.artista);
    _url = TextEditingController(text: inicial.url);
    _tags = TextEditingController(text: inicial.tags.join(', '));
    _tom = inicial.tom.trim();
    _tipo = inicial.tipo.trim().isEmpty ? 'Congregação' : inicial.tipo;
    _fonte = inicial.fonte.trim().isEmpty ? 'Manual' : inicial.fonte;
    _momentos = {...inicial.momentos};
    _temas = {...inicial.temas};
  }

  @override
  void dispose() {
    _titulo.dispose();
    _artista.dispose();
    _url.dispose();
    _tags.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final corSuave = theme.colorScheme.onSurface.withValues(alpha: 0.6);

    return Column(
      children: [
        const SizedBox(height: 8),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: corSuave.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 8, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Metadados da cifra',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _titulo,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: 'Título *',
                    errorText: _erroTitulo,
                  ),
                  onChanged: (_) {
                    if (_erroTitulo != null) {
                      setState(() => _erroTitulo = null);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _artista,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Artista'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _tom,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Tom'),
                        items: [
                          for (final tom in _opcoesTom)
                            DropdownMenuItem(
                              value: tom,
                              child: Text(tom.isEmpty ? 'Sem tom' : tom),
                            ),
                        ],
                        onChanged: (valor) =>
                            setState(() => _tom = valor ?? ''),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _tipo,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Tipo'),
                        items: [
                          for (final tipo in _opcoesTipo)
                            DropdownMenuItem(value: tipo, child: Text(tipo)),
                        ],
                        onChanged: (valor) => setState(
                          () => _tipo = valor ?? 'Congregação',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _fonte,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Fonte'),
                        items: [
                          for (final fonte in _opcoesFonte)
                            DropdownMenuItem(value: fonte, child: Text(fonte)),
                        ],
                        onChanged: (valor) =>
                            setState(() => _fonte = valor ?? 'Manual'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _url,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'URL da fonte (opcional)',
                  ),
                ),
                const SizedBox(height: 18),
                _grupoChips(
                  titulo: 'Momentos',
                  opcoes: _opcoesMomento,
                  selecionadas: _momentos,
                  onAlternar: (valor) => setState(() {
                    if (!_momentos.remove(valor)) _momentos.add(valor);
                  }),
                  onAdicionar: () => _adicionarPersonalizado(
                    'Novo momento',
                    _momentosExtras,
                    _momentos,
                  ),
                ),
                const SizedBox(height: 14),
                _grupoChips(
                  titulo: 'Temas',
                  opcoes: _opcoesTema,
                  selecionadas: _temas,
                  onAlternar: (valor) => setState(() {
                    if (!_temas.remove(valor)) _temas.add(valor);
                  }),
                  onAdicionar: () => _adicionarPersonalizado(
                    'Novo tema',
                    _temasExtras,
                    _temas,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _tags,
                  decoration: const InputDecoration(
                    labelText: 'Tags (separadas por vírgula)',
                    hintText: 'gospel, missa, coral',
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Campos marcados com * são obrigatórios.',
                  style: theme.textTheme.bodySmall?.copyWith(color: corSuave),
                ),
              ],
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _aplicar,
                icon: const Icon(Icons.check_rounded),
                label: const Text('Aplicar metadados'),
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<String> get _opcoesTom {
    final conjunto = <String>{'', ...AppConfig.tonsDisponiveis};
    if (_tom.isNotEmpty) conjunto.add(_tom);
    return conjunto.toList();
  }

  List<String> get _opcoesTipo {
    final conjunto = <String>{...AppConfig.tiposMusica};
    if (_tipo.isNotEmpty) conjunto.add(_tipo);
    return conjunto.toList();
  }

  List<String> get _opcoesFonte {
    final conjunto = <String>{...AppConfig.fontesDisponiveis};
    if (_fonte.isNotEmpty) conjunto.add(_fonte);
    return conjunto.toList();
  }

  List<String> get _opcoesMomento {
    final conjunto = <String>{
      ...AppConfig.momentosLiturgicos,
      ..._momentosExtras,
    };
    for (final momento in _momentos) {
      conjunto.add(momento);
    }
    return conjunto.toList();
  }

  List<String> get _opcoesTema {
    final conjunto = <String>{
      ...AppConfig.temasLiturgicos,
      ..._temasExtras,
    };
    for (final tema in _temas) {
      conjunto.add(tema);
    }
    return conjunto.toList();
  }

  Widget _grupoChips({
    required String titulo,
    required List<String> opcoes,
    required Set<String> selecionadas,
    required ValueChanged<String> onAlternar,
    required VoidCallback onAdicionar,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              titulo,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: onAdicionar,
              icon: const Icon(Icons.add_rounded, size: 17),
              label: const Text('Novo'),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
        Wrap(
          spacing: 7,
          runSpacing: 6,
          children: [
            for (final opcao in opcoes)
              FiltroChip(
                label: opcao,
                selecionado: selecionadas.contains(opcao),
                onTap: () => onAlternar(opcao),
              ),
          ],
        ),
      ],
    );
  }

  Future<void> _adicionarPersonalizado(
    String titulo,
    Set<String> extras,
    Set<String> selecionadas,
  ) async {
    final nome = await _pedirNome(titulo);
    if (nome == null || nome.trim().isEmpty) return;
    setState(() {
      extras.add(nome.trim());
      selecionadas.add(nome.trim());
    });
  }

  Future<String?> _pedirNome(String titulo) async {
    final controller = TextEditingController();
    final resultado = await showDialog<String>(
      context: context,
      builder: (dialogoContexto) => AlertDialog(
        title: Text(titulo),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(hintText: 'Ex.: Consagração'),
          onSubmitted: (valor) =>
              Navigator.of(dialogoContexto).pop(valor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogoContexto).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogoContexto).pop(controller.text),
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
    controller.dispose();
    return resultado;
  }

  void _aplicar() {
    if (_titulo.text.trim().isEmpty) {
      setState(() => _erroTitulo = 'Informe o título');
      return;
    }

    final tags = _tags.text
        .split(RegExp(r'[,;]'))
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList();

    Navigator.of(context).pop(
      MetadataCifraDados(
        titulo: _titulo.text.trim(),
        artista: _artista.text.trim(),
        tom: _tom.trim(),
        tipo: _tipo,
        fonte: _fonte,
        url: _url.text.trim(),
        momentos: _momentos,
        temas: _temas,
        tags: tags,
      ),
    );
  }
}
