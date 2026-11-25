import '../models/cifra.dart';
import '../utils/chord_utils.dart';
import 'base_vm.dart';

/// ViewModel do visualizador de cifra (transposição e zoom).
class ViewerVM extends BaseVM {
  ViewerVM(this.cifra);

  Cifra cifra;
  int semitons = 0;
  double escalaFonte = 1.0;

  String? get tomAtual => transporTom(cifra.tom, semitons);

  bool get preferirBemois =>
      tomUsaBemois(cifra.tom) || tomUsaBemois(tomAtual);

  bool get transposto => semitons % 12 != 0;

  String get rotuloTransposicao {
    if (semitons == 0) return '0';
    return semitons > 0 ? '+$semitons' : '$semitons';
  }

  void transpor(int delta) {
    final novo = semitons + delta;
    if (novo < -11 || novo > 11) return;
    semitons = novo;
    notificar();
  }

  void resetarTom() {
    semitons = 0;
    notificar();
  }

  void alterarZoom(double delta) {
    final novo = (escalaFonte + delta).clamp(0.75, 2.0).toDouble();
    if ((novo - escalaFonte).abs() < 0.001) return;
    escalaFonte = novo;
    notificar();
  }

  void definirEscala(double valor) {
    escalaFonte = valor.clamp(0.75, 2.0).toDouble();
    notificar();
  }

  void atualizarCifra(Cifra nova) {
    cifra = nova;
    notificar();
  }
}
