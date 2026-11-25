# CifraVault

**CifraVault** é um aplicativo Android em Flutter para organizar cifras e setlists litúrgicos usando **arquivos Markdown locais** como única fonte de verdade. A proposta é ser um “Obsidian para cifras”: você mantém o acervo em uma pasta do dispositivo, edita os `.md` como quiser e o app lê/escreve diretamente neles.

## Recursos

- Biblioteca de cifras com busca por título, artista ou tag.
- Filtros combinados por momento litúrgico, tom, tema, tipo e fonte.
- Visualizador com acordes sobre a letra, transposição de ±11 semitons e zoom.
- Editor Markdown com destaque visual de acordes e cabeçalhos de seção.
- Metadados editáveis: título, artista, tom, tipo, fonte, URL, momentos, temas e tags.
- Importação por link (CifraClub, ClickGratis, CifraMaster e fallback genérico), HTML colado ou arquivo `.md`.
- Recebimento de links compartilhados do navegador/outros apps via intents Android.
- Setlists com momentos litúrgicos, músicas, notas, status e marcação de “tocado”.
- Exportação de cifras e setlists em **PDF A4** e compartilhamento em texto.
- Tema escuro por padrão (com modo claro opcional) e Material You.
- Sem banco de dados, sem conta e sem nuvem: tudo em arquivos `.md`.

## Requisitos

| Item | Versão |
|---|---|
| Flutter | `>= 3.38.0` |
| Dart | `^3.9.0` |
| Android | API 24 (Android 7.0) ou superior |
| Java/JDK para build Android | 17 |

O projeto foi desenvolvido e validado com Flutter **3.50.1** / Dart **3.14**.

## Como compilar

### 1. Pré-requisitos

- **Flutter** `>= 3.38.0` (Dart `^3.9.0` incluso) — https://flutter.dev/docs/get-started/install
- **Android SDK** com Platform Tools, Build Tools e uma plataforma Android (API 24+). Android Studio facilita, mas o SDK command-line também funciona.
- **JDK 17** para o build Android.

Verifique o ambiente:

```bash
flutter doctor
```

### 2. Clonar e instalar dependências

```bash
git clone git@github.com:RafaelJosePortoSilva/Cifras.git
cd Cifras
flutter pub get
```

### 3. Rodar em desenvolvimento

```bash
# com um dispositivo/emulador conectado
flutter devices
flutter run
```

### 4. Gerar APK de release

```bash
flutter build apk --release
# saída: build/app/outputs/flutter-apk/app-release.apk
```

Instalar via ADB:

```bash
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

### 5. Gerar App Bundle (Play Store)

```bash
flutter build appbundle --release
# saída: build/app/outputs/bundle/release/app-release.aab
```

> **Assinatura:** o release atual usa a chave de debug para facilitar testes locais. Para publicar, configure um keystore e o `signingConfig` de release em `android/app/build.gradle.kts`.

### 6. Testes e análise

```bash
flutter analyze
flutter test
```

Os testes cobrem detecção/transposição de acordes, parser de front-matter, seções, setlists, importação de HTML e utilitários de texto.

## Estrutura do projeto

```text
lib/
├── main.dart                  # Providers + entrada do app
├── app.dart                   # MaterialApp, tema e share handler
├── config/
│   ├── app_config.dart        # Constantes, listas litúrgicas e template
│   └── theme.dart             # Temas claro/escuro Material 3
├── models/
│   ├── cifra.dart             # Cifra, seções, linhas e parser do corpo
│   ├── setlist.dart           # Setlist, momentos, itens e parser
│   ├── filtros.dart           # Filtros combinados
│   └── metadata_cifra.dart    # Dados do formulário de metadados
├── services/
│   ├── vault_service.dart     # CRUD dos .md no vault
│   ├── search_service.dart    # Índice em memória e busca multi-critério
│   ├── parser_service.dart    # Markdown + HTML dos sites
│   ├── pdf_service.dart       # PDF nativo e texto compartilhável
│   └── share_service.dart     # Ponte com intents Android
├── viewmodels/                # MVVM com ChangeNotifier/provider
├── views/
│   ├── widgets/               # ChordDisplay, cards, chips, formulários
│   └── ...                    # Telas de biblioteca, cifra, editor, setlists...
└── router/routes.dart         # Rotas nomeadas e argumentos tipados

android/                       # Scaffold Android + MainActivity customizada
test/                          # Testes unitários
assets/icons/                  # Ícone-fonte do app
exemplo_vault/                 # Vault de exemplo para copiar ao dispositivo
```

## Vault e arquivos

Por padrão, o vault fica em:

```text
<documentos do app>/CifraVault/
├── cifras/
│   └── *.md
└── setlists/
    └── *.md
```

As duas subpastas são criadas automaticamente. O caminho pode ser alterado em **Configurações → Pasta do vault**; a escolha é persistida em `SharedPreferences` (`cifravault.vault_path`).

> **Android e armazenamento:** o app usa o sistema de arquivos via `dart:io`. Em dispositivos Android modernos, pastas fora do armazenamento do app estão sujeitas ao scoped storage. O seletor de diretórios pode retornar caminhos não graváveis dependendo do fabricante. A pasta padrão do app sempre funciona. Suporte completo a `DocumentFile`/SAF persistente é uma melhoria futura.

### Formato de cifra

```markdown
---
titulo: Glória a Deus Nas Alturas
artista: Banda Shalom
fonte: CifraClub
url: https://www.cifraclub.com.br/banda-shalom/gloria-a-deus-nas-alturas/
tom: D
momentos: [Abertura, Gloria]
temas: [Eucaristia, Louvor]
tipo: Congregação
data_importacao: 2026-11-24
tags: [gospel, missa, coral]
---

# Glória a Deus Nas Alturas - Banda Shalom

[Intro]
D  A  Bm  G

[Verso 1]
D            A
Glória, glória a Deus nas alturas
Bm           G
e paz na terra aos homens
```

Regras do parser:

- O front-matter entre `---` é YAML; campos ausentes são tolerados.
- O H1 do título é ignorado no corpo e regenerado ao salvar.
- `[Seção]` e `## Seção` iniciam uma nova seção.
- Uma linha composta só por acordes é agrupada com a linha de letra imediatamente seguinte.
- Espaços horizontais são preservados para manter os acordes alinhados sobre a sílaba correta.

### Formato de setlist

```markdown
---
titulo: Ceia Materna - 29/11
evento: "Ceia Materna - Casa Maria"
data: 2026-11-29
diaLiturgico: ""
criadoEm: 2026-11-28T20:00:00.000
status: rascunho
---

# Ceia Materna - 29/11

## 🕊️ Abertura
- Cifra: "gloria_a_deus"
  Nota: "Versos completos + Refrão x2"
  Tocado: true

## ✝️ Ato Penitencial
- Cifra: "confesso_senhor"
  Nota: "Verso 1 e 2"
```

O `Cifra` referencia o nome do arquivo sem `.md` em `cifras/`. Se o arquivo for renomeado, o vínculo do setlist deixa de ser encontrado e o app mostra um indicador de link quebrado.

## Fluxo de uso

1. **Configurar o vault** em Configurações (opcional; o padrão já funciona).
2. **Importar** uma cifra pelo botão “Nova cifra”:
   - cole um link de site suportado;
   - ou cole o HTML/texto da página;
   - ou selecione um `.md` existente.
3. **Revisar metadados** e salvar no vault.
4. Na biblioteca, **buscar/filtrar** por momento, tom, tema, tipo ou fonte.
5. Abrir a cifra para **transpor**, ajustar o zoom, editar, compartilhar ou exportar PDF.
6. Criar um **setlist**, adicionar momentos e escolher músicas da biblioteca.
7. Durante o ensaio/celebração, abrir o setlist e **marcar como tocado**; o progresso é salvo no `.md`.
8. Exportar o setlist em **PDF** ou compartilhar o roteiro em texto.

## Importação de sites e compartilhamento

Sites com extração dedicada/fallback:

- `cifraclub.com.br`
- `clickgratis.com.br`
- `ciframaster.com.br`

O parser procura blocos `pre`, `.cifra_cnt`, `.chord-sheet`, entre outros, e usa o corpo da página como fallback. Como os sites mudam com frequência, a aba **HTML** permite colar o conteúdo manualmente.

O `AndroidManifest.xml` inclui:

- permissão de `INTERNET`;
- intent-filters para abrir links `https` dos sites de cifras e links `https`/`http` genéricos;
- intent-filter `ACTION_SEND` com `text/plain` para receber URLs compartilhadas;
- permissões de armazenamento legado até API 32.

O `MainActivity.kt` expõe o canal `cifravault/intents`:

- `getInitialUrl` → URL que abriu o app;
- `onShare` → URL recebida com o app já aberto.

## PDF

O PDF é montado nativamente com os pacotes `pdf` e `printing` (sem WebView):

- A4, margens, rodapé com numeração;
- título, artista e badge de tom;
- acordes em Courier bold azul e letra em Courier;
- quebras de página entre cifras de um setlist;
- compartilhamento via folha do sistema (`Printing.sharePdf`).

Os métodos `renderHtmlCifra` e `renderHtmlSetlist` também estão disponíveis para pré-visualização/exportação HTML.

## Dependências principais

| Pacote | Uso |
|---|---|
| `provider` | Estado MVVM leve |
| `file_picker` | Selecionar pasta e arquivos `.md` |
| `http` + `html` | Download e parsing dos sites |
| `yaml` | Front-matter |
| `intl` | Datas em pt-BR |
| `path_provider` + `path` | Caminhos do vault |
| `shared_preferences` | Tema e caminho do vault |
| `share_plus` | Compartilhar texto |
| `pdf` + `printing` | Gerar e compartilhar PDF |

## Limitações conhecidas

- Não há banco de dados por design; o desempenho é adequado para acervos pessoais (centenas a alguns milhares de cifras).
- A importação depende da estrutura HTML do site; use a aba HTML quando necessário.
- O acesso a pastas externas no Android pode ser limitado pelo SAF/scoped storage (ver seção do vault).
- O PDF usa fontes padrão do pacote `pdf` (Courier), sem fontes customizadas embutidas.
- O app não baixa áudio, não faz playback e não sincroniza com serviços externos.

## Vault de exemplo

A pasta `exemplo_vault/` contém uma cifra e um setlist prontos. Para testar:

```bash
# exemplo com adb (ajuste o caminho de documentos do app)
adb push exemplo_vault/. /sdcard/Android/data/com.cifravault.cifravault/files/CifraVault/
```

Ou copie os arquivos manualmente para a pasta escolhida em Configurações.

## Licença

Uso pessoal e educacional. As cifras importadas pertencem aos seus respectivos autores e sites de origem; respeite os termos de uso de cada fonte.
