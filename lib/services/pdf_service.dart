import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../config/app_config.dart';
import '../models/cifra.dart';
import '../models/setlist.dart';
import '../utils/chord_utils.dart';
import '../utils/text_utils.dart';

/// Geração de PDFs e texto compartilhável de cifras e setlists.
///
/// Usa o pacote `pdf` para montar documentos A4 nativos (sem WebView) e o
/// `printing` para abrir a folha de compartilhamento/impressão do sistema.
class PdfService {
  /// Gera o PDF de uma cifra, opcionalmente transposta.
  Future<File> gerarPdfCifra(Cifra cifra, {int semitons = 0}) async {
    final documento = pw.Document();
    documento.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(36, 36, 36, 34),
        footer: _rodape,
        build: (_) => _conteudoCifra(cifra, semitons: semitons),
      ),
    );
    return _salvarPdf(documento, 'cifra_${slugify(cifra.titulo)}');
  }

  /// Gera o PDF de um setlist completo (resumo + cifras na ordem).
  Future<File> gerarPdfSetlist(
    Setlist setlist, {
    required Map<String, Cifra?> cifras,
    int semitons = 0,
  }) async {
    final documento = pw.Document();
    final cifrasUsadas = _cifrasUnicasNaOrdem(setlist, cifras);

    documento.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(36, 36, 36, 34),
        footer: _rodape,
        build: (_) => [
          _cabecalhoSetlist(setlist),
          pw.SizedBox(height: 14),
          ..._resumoMomentos(setlist, cifras),
          for (final cifra in cifrasUsadas) ...[
            pw.NewPage(),
            ..._conteudoCifra(cifra, semitons: semitons),
            pw.SizedBox(height: 18),
          ],
        ],
      ),
    );

    return _salvarPdf(documento, 'setlist_${slugify(setlist.titulo)}');
  }

  /// Abre a folha de compartilhamento do sistema com o PDF gerado.
  Future<void> compartilharPdf(File arquivo) async {
    final bytes = await arquivo.readAsBytes();
    await Printing.sharePdf(bytes: bytes, filename: p.basename(arquivo.path));
  }

  /// Texto formatado para colar no WhatsApp/Telegram.
  String textoSetlist(Setlist setlist, Map<String, Cifra?> cifras) {
    final buffer = StringBuffer()
      ..writeln('🎵 ${setlist.titulo}')
      ..writeln(
        '📅 ${formatarData(setlist.data)}'
        '${setlist.evento.trim().isEmpty ? '' : ' • ${setlist.evento}'}',
      );
    if (setlist.diaLiturgico.trim().isNotEmpty) {
      buffer.writeln('📖 ${setlist.diaLiturgico}');
    }
    buffer.writeln('Status: ${setlist.status.rotulo}');

    for (final momento in setlist.momentos) {
      buffer
        ..writeln()
        ..writeln('${AppConfig.emojiMomento(momento.nome)} ${momento.nome}');
      for (var i = 0; i < momento.itens.length; i++) {
        final item = momento.itens[i];
        final cifra = cifras[item.cifraId];
        final titulo = cifra?.titulo ?? item.cifraId;
        final tom = cifra?.tom;
        buffer.write('${i + 1}. $titulo');
        if (tom != null && tom.isNotEmpty) buffer.write(' (Tom: $tom)');
        if (item.estaTocado) buffer.write(' ✅');
        buffer.writeln();
        if (item.nota.trim().isNotEmpty) {
          buffer.writeln('   ↳ ${item.nota.trim()}');
        }
      }
    }
    return buffer.toString().trim();
  }

  /// HTML simples (A4) usado para exportar/visualizar uma cifra.
  String renderHtmlCifra(Cifra cifra, {int semitons = 0}) {
    final tom = transporTom(cifra.tom, semitons);
    final buffer = StringBuffer()
      ..writeln('<!DOCTYPE html>')
      ..writeln('<html lang="pt-BR"><head><meta charset="utf-8">')
      ..writeln('<title>${_escapar(cifra.titulo)}</title>')
      ..writeln('<style>$_css</style></head><body>')
      ..writeln('<h1>${_escapar(cifra.titulo)}</h1>')
      ..writeln('<p class="artista">${_escapar(cifra.artista)}</p>');
    if (tom != null && tom.isNotEmpty) {
      buffer.writeln('<p class="tom">Tom: ${_escapar(tom)}</p>');
    }

    for (final secao in cifra.conteudo) {
      buffer
        ..writeln('<h3>${_escapar(secao.titulo)}</h3>')
        ..writeln('<pre class="cifra">');
      for (final linha in secao.linhas) {
        if (linha.isBlank) {
          buffer.writeln();
          continue;
        }
        if (linha.temAcordes) {
          final acordes = semitons == 0
              ? linha.acordes!
              : transporLinhaAcordes(
                  linha.acordes!,
                  semitons,
                  preferirBemois: tomUsaBemois(cifra.tom),
                );
          buffer.writeln('<span class="acorde">${_escapar(acordes)}</span>');
        }
        if (linha.temTexto) {
          buffer.writeln('<span class="letra">${_escapar(linha.texto)}</span>');
        }
      }
      buffer.writeln('</pre>');
    }
    buffer.writeln('</body></html>');
    return buffer.toString();
  }

  /// HTML simples (A4) de um setlist com o resumo dos momentos.
  String renderHtmlSetlist(
    Setlist setlist, {
    Map<String, Cifra?> cifras = const <String, Cifra?>{},
  }) {
    final buffer = StringBuffer()
      ..writeln('<!DOCTYPE html>')
      ..writeln('<html lang="pt-BR"><head><meta charset="utf-8">')
      ..writeln('<title>${_escapar(setlist.titulo)}</title>')
      ..writeln('<style>$_css</style></head><body>')
      ..writeln('<h1>${_escapar(setlist.titulo)}</h1>')
      ..writeln(
        '<p class="artista">${_escapar(formatarData(setlist.data))}'
        '${setlist.evento.isEmpty ? '' : ' • ${_escapar(setlist.evento)}'}</p>',
      );

    for (final momento in setlist.momentos) {
      buffer
        ..writeln('<h3>${_escapar(momento.nome)}</h3>')
        ..writeln('<ul>');
      for (final item in momento.itens) {
        final cifra = cifras[item.cifraId];
        final titulo = cifra?.titulo ?? item.cifraId;
        buffer.write('<li>${_escapar(titulo)}');
        if (cifra?.tom != null) {
          buffer.write(' <strong>(Tom: ${_escapar(cifra!.tom!)})</strong>');
        }
        if (item.nota.trim().isNotEmpty) {
          buffer.write('<br><small>${_escapar(item.nota)}</small>');
        }
        buffer.writeln('</li>');
      }
      buffer.writeln('</ul>');
    }
    buffer.writeln('</body></html>');
    return buffer.toString();
  }

  // ---------------------------------------------------------------------------
  // Internos
  // ---------------------------------------------------------------------------

  pw.Widget _rodape(pw.Context contexto) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 8),
      child: pw.Text(
        'CifraVault • ${contexto.pageNumber}/${contexto.pagesCount}',
        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
      ),
    );
  }

  Future<File> _salvarPdf(pw.Document documento, String nome) async {
    final diretorio = await getTemporaryDirectory();
    final arquivo = File(
      p.join(diretorio.path, 'cifravault_pdf', '$nome.pdf'),
    );
    await arquivo.parent.create(recursive: true);
    await arquivo.writeAsBytes(await documento.save(), flush: true);
    return arquivo;
  }

  List<pw.Widget> _conteudoCifra(Cifra cifra, {int semitons = 0}) {
    final tom = transporTom(cifra.tom, semitons);
    final widgets = <pw.Widget>[
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  cifra.titulo,
                  style: pw.TextStyle(
                    fontSize: 21,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  cifra.artista,
                  style: const pw.TextStyle(
                    fontSize: 11,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
            ),
          ),
          if (tom != null && tom.isNotEmpty)
            pw.Container(
              margin: const pw.EdgeInsets.only(left: 12),
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              decoration: pw.BoxDecoration(
                color: PdfColors.amber100,
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Text(
                'Tom: $tom',
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.orange900,
                ),
              ),
            ),
        ],
      ),
      pw.SizedBox(height: 8),
      pw.Divider(color: PdfColors.grey400),
    ];

    for (final secao in cifra.conteudo) {
      widgets
        ..add(pw.SizedBox(height: 10))
        ..add(
          pw.Text(
            secao.titulo.toUpperCase(),
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blueGrey700,
            ),
          ),
        )
        ..add(pw.SizedBox(height: 4));

      for (final linha in secao.linhas) {
        if (linha.isBlank) {
          widgets.add(pw.SizedBox(height: 6));
          continue;
        }
        if (linha.temAcordes) {
          final acordes = semitons == 0
              ? linha.acordes!
              : transporLinhaAcordes(
                  linha.acordes!,
                  semitons,
                  preferirBemois: tomUsaBemois(cifra.tom),
                );
          widgets.add(
            pw.Text(
              acordes,
              style: pw.TextStyle(
                font: pw.Font.courier(),
                fontSize: 9.5,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue800,
              ),
            ),
          );
        }
        if (linha.temTexto) {
          widgets.add(
            pw.Text(
              linha.texto,
              style: pw.TextStyle(
                font: pw.Font.courier(),
                fontSize: 9.5,
              ),
            ),
          );
        }
        widgets.add(pw.SizedBox(height: 3));
      }
    }

    if (cifra.momentos.isNotEmpty || cifra.temas.isNotEmpty) {
      widgets
        ..add(pw.SizedBox(height: 10))
        ..add(pw.Divider(color: PdfColors.grey300))
        ..add(
          pw.Text(
            [
              if (cifra.momentos.isNotEmpty)
                'Momentos: ${cifra.momentos.join(', ')}',
              if (cifra.temas.isNotEmpty) 'Temas: ${cifra.temas.join(', ')}',
            ].join(' • '),
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
        );
    }

    return widgets;
  }

  pw.Widget _cabecalhoSetlist(Setlist setlist) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          setlist.titulo,
          style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          '${formatarData(setlist.data)}'
          '${setlist.evento.isEmpty ? '' : ' • ${setlist.evento}'}',
          style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
        ),
        if (setlist.diaLiturgico.isNotEmpty)
          pw.Text(
            'Dia litúrgico: ${setlist.diaLiturgico}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
        pw.SizedBox(height: 4),
        pw.Text(
          'Status: ${setlist.status.rotulo} • '
          '${setlist.totalMusicas} música(s) em ${setlist.totalMomentos} momento(s)',
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 8),
        pw.Divider(color: PdfColors.grey400),
      ],
    );
  }

  List<pw.Widget> _resumoMomentos(
    Setlist setlist,
    Map<String, Cifra?> cifras,
  ) {
    final widgets = <pw.Widget>[];
    for (final momento in setlist.momentos) {
      widgets
        ..add(pw.SizedBox(height: 10))
        ..add(
          pw.Text(
            momento.nome,
            style: pw.TextStyle(
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blueGrey800,
            ),
          ),
        )
        ..add(pw.SizedBox(height: 2));

      if (momento.itens.isEmpty) {
        widgets.add(
          pw.Text(
            'Sem músicas',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        );
        continue;
      }

      for (final item in momento.itens) {
        final cifra = cifras[item.cifraId];
        final titulo = cifra?.titulo ?? item.cifraId;
        final tom = cifra?.tom;
        widgets.add(
          pw.Container(
            margin: const pw.EdgeInsets.only(left: 8, bottom: 3),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  '• $titulo${tom == null ? '' : '  (Tom: $tom)'}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
                if (item.nota.trim().isNotEmpty)
                  pw.Text(
                    '   ${item.nota.trim()}',
                    style: const pw.TextStyle(
                      fontSize: 8.5,
                      color: PdfColors.grey600,
                    ),
                  ),
              ],
            ),
          ),
        );
      }
    }
    return widgets;
  }

  List<Cifra> _cifrasUnicasNaOrdem(
    Setlist setlist,
    Map<String, Cifra?> cifras,
  ) {
    final vistas = <String>{};
    final resultado = <Cifra>[];
    for (final momento in setlist.momentos) {
      for (final item in momento.itens) {
        final cifra = cifras[item.cifraId];
        if (cifra != null && vistas.add(cifra.id)) {
          resultado.add(cifra);
        }
      }
    }
    return resultado;
  }

  String _escapar(String texto) => const HtmlEscape().convert(texto);

  static const String _css = '''
  * { box-sizing: border-box; }
  body { font-family: Roboto, Arial, sans-serif; color: #1b1b1b;
         margin: 32px; line-height: 1.4; }
  h1 { font-size: 26px; margin: 0 0 4px; }
  .artista { color: #666; margin: 0 0 8px; }
  .tom { display: inline-block; background: #ffe0b2; color: #e65100;
         padding: 4px 10px; border-radius: 6px; font-weight: bold; }
  h3 { margin: 22px 0 6px; font-size: 13px; text-transform: uppercase;
       color: #455a64; border-bottom: 1px solid #ddd; padding-bottom: 3px; }
  pre.cifra { font-family: "Fira Code", "Courier New", monospace;
              font-size: 13px; margin: 0; white-space: pre-wrap; }
  .acorde { color: #1565c0; font-weight: bold; }
  .letra { color: #212121; }
  ul { margin-top: 4px; }
  @media print { h3 { page-break-after: avoid; } }
  ''';
}
