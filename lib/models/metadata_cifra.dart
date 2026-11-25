/// Dados editáveis de metadados de uma cifra.
///
/// Vive em `models` para ser compartilhado entre o editor, a importação e os
/// widgets de formulário sem acoplar ViewModels a Views.
class MetadataCifraDados {
  MetadataCifraDados({
    required this.titulo,
    required this.artista,
    required this.tom,
    required this.tipo,
    required this.fonte,
    required this.url,
    Set<String>? momentos,
    Set<String>? temas,
    List<String>? tags,
  })  : momentos = {...?momentos},
        temas = {...?temas},
        tags = [...?tags];

  String titulo;
  String artista;
  String tom;
  String tipo;
  String fonte;
  String url;
  Set<String> momentos;
  Set<String> temas;
  List<String> tags;

  MetadataCifraDados copiar() => MetadataCifraDados(
        titulo: titulo,
        artista: artista,
        tom: tom,
        tipo: tipo,
        fonte: fonte,
        url: url,
        momentos: momentos,
        temas: temas,
        tags: tags,
      );
}
