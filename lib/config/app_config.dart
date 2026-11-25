import 'package:flutter/material.dart';

/// Configurações centrais do CifraVault.
///
/// Mantém constantes de caminhos, metadados litúrgicos, cores e chaves de
/// preferências. Nada aqui depende de estado de runtime, exceto os helpers
/// estáticos de emoji.
class AppConfig {
  AppConfig._();

  static const String appName = 'CifraVault';
  static const String version = '1.0.0';

  // Chaves de SharedPreferences
  static const String prefVaultPath = 'cifravault.vault_path';
  static const String prefThemeMode = 'cifravault.theme_mode';

  // Subpastas do vault
  static const String vaultSubDirCifras = 'cifras';
  static const String vaultSubDirSetlists = 'setlists';

  // Cores da identidade visual
  static const Color primaryColor = Color(0xFFFFA726);
  static const Color accentColor = Color(0xFF42A5F5);
  static const Color chorusAccent = Color(0xFFEF5350);
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color cardDark = Color(0xFF232323);
  static const Color textoClaro = Color(0xFFE0E0E0);
  static const Color textoSecundario = Color(0xFF9E9E9E);

  static const Color backgroundLight = Color(0xFFF7F5F2);
  static const Color surfaceLight = Color(0xFFFFFFFF);

  static const List<String> momentosLiturgicos = [
    'Abertura',
    'Entrada',
    'Ato Penitencial',
    'Glória',
    'Ofertório',
    'Comunhão',
    'Envio/Bênção Final',
    'Encerramento',
    'Celebração',
    'Processional',
  ];

  static const List<String> temasLiturgicos = [
    'Advento',
    'Natal',
    'Quaresma',
    'Páscoa',
    'Pentecostes',
    'Tempo Comum',
    'Maria',
    'Misericórdia',
    'Esperança',
    'Eucaristia',
    'Gratidão',
    'Louvor',
    'Adoração',
    'Evangelização',
    'Jovens',
    'Casais',
    'Crianças',
  ];

  static const List<String> tiposMusica = [
    'Coro',
    'Congregação',
    'Instrumental',
    'Reflexão',
  ];

  static const List<String> fontesDisponiveis = [
    'CifraClub',
    'ClickGratis',
    'CifraMaster',
    'Manual',
    'Outro',
  ];

  static const List<String> diasLiturgicos = [
    '',
    'Normal',
    'Advento',
    'Natal',
    'Quaresma',
    'Páscoa',
    'Pentecostes',
    'Tempo Comum',
    'Solenidade',
  ];

  /// Tons usados nos seletores (enarmônicos com sustenidos).
  static const List<String> tonsDisponiveis = [
    'C',
    'C#',
    'D',
    'D#',
    'E',
    'F',
    'F#',
    'G',
    'G#',
    'A',
    'A#',
    'B',
  ];

  /// Corpo inicial de uma cifra criada manualmente.
  static const String corpoTemplate = '''[Intro]
D  A  Bm  G

[Verso 1]
D            A
Escreva a letra aqui
Bm           G
e os acordes acima dela.
''';

  static const Map<String, String> _emojisMomentos = {
    'Abertura': '🕊️',
    'Entrada': '🚪',
    'Ato Penitencial': '✝️',
    'Glória': '✨',
    'Ofertório': '🍞',
    'Comunhão': '🍇',
    'Envio/Bênção Final': '🙏',
    'Encerramento': '🌙',
    'Celebração': '🎉',
    'Processional': '🎺',
  };

  /// Emoji usado ao escrever o nome do momento no Markdown do setlist.
  static String emojiMomento(String nome) {
    return _emojisMomentos[nome] ?? '🎵';
  }

  /// Descrição curta exibida na tela de configurações.
  static String get descricaoVault => 'Pasta onde ficam os arquivos .md de '
      'cifras e setlists.';
}
