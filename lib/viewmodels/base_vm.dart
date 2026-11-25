import 'package:flutter/foundation.dart';

/// Base para os ViewModels: evita `notifyListeners` após o descarte.
abstract class BaseVM extends ChangeNotifier {
  bool _descartado = false;

  bool get descartado => _descartado;

  void notificar() {
    if (!_descartado) notifyListeners();
  }

  @override
  void dispose() {
    _descartado = true;
    super.dispose();
  }
}
