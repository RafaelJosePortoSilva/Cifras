import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import '../services/share_service.dart';
import '../services/vault_service.dart';
import 'base_vm.dart';

/// ViewModel de configurações (tema e pasta do vault).
class SettingsVM extends BaseVM {
  SettingsVM(this._vault, this._share);

  final VaultService _vault;
  final ShareHandler _share;

  ThemeMode themeMode = ThemeMode.dark;
  String? vaultPath;
  String? erro;
  bool carregando = true;
  bool temAcessoTodosArquivos = true;

  Future<void> carregar() async {
    carregando = true;
    notificar();
    try {
      final prefs = await SharedPreferences.getInstance();
      final modo = prefs.getString(AppConfig.prefThemeMode);
      themeMode = modo == 'light' ? ThemeMode.light : ThemeMode.dark;
      vaultPath = await _vault.obterVaultPath();
      temAcessoTodosArquivos = await _share.temAcessoTodosArquivos();
      erro = null;
    } catch (falha) {
      erro = 'Não foi possível abrir a pasta do vault.\n$falha';
    } finally {
      carregando = false;
      notificar();
    }
  }

  Future<void> atualizarPermissaoArquivos() async {
    temAcessoTodosArquivos = await _share.temAcessoTodosArquivos();
    notificar();
  }

  Future<void> solicitarAcessoTodosArquivos() async {
    await _share.solicitarAcessoTodosArquivos();
  }

  Future<void> abrirConfiguracoesApp() async {
    await _share.abrirConfiguracoesApp();
  }

  Future<void> definirTemaEscuro(bool escuro) async {
    themeMode = escuro ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      AppConfig.prefThemeMode,
      escuro ? 'dark' : 'light',
    );
    notificar();
  }

  Future<bool> alterarVault(String caminho) async {
    try {
      await _vault.definirVaultPath(caminho);
      vaultPath = await _vault.obterVaultPath();
      erro = null;
      notificar();
      return true;
    } catch (falha) {
      erro = 'Não foi possível usar essa pasta.\n$falha';
      notificar();
      return false;
    }
  }

  Future<bool> usarVaultPadrao() async {
    try {
      vaultPath = await _vault.usarVaultPadrao();
      erro = null;
      notificar();
      return true;
    } catch (falha) {
      erro = 'Não foi possível restaurar a pasta padrão.\n$falha';
      notificar();
      return false;
    }
  }
}
