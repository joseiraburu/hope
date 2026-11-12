// HOPE – registro visual del dolor neuropático crónico.
// Copyright (C) 2026 joseiraburu y colaboradores. Licencia GPL-3.0-or-later.

import 'package:flutter/material.dart';

import '../services/ai_analysis.dart';
import '../state/app_controller.dart';

/// Ajustes del análisis con IA del informe completo: desactivado por
/// defecto y con consentimiento expreso antes de activarlo.
class AiSettingsScreen extends StatefulWidget {
  const AiSettingsScreen({super.key});

  @override
  State<AiSettingsScreen> createState() => _AiSettingsScreenState();
}

class _AiSettingsScreenState extends State<AiSettingsScreen> {
  late final TextEditingController _endpoint;
  late final TextEditingController _model;
  late final TextEditingController _key;
  bool _ready = false;
  bool _testing = false;
  String? _testResult;
  bool _testOk = false;
  bool _showKey = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ready) return;
    _ready = true;
    final settings = AppScope.read(context).settings;
    _endpoint = TextEditingController(text: settings.aiEndpoint);
    _model = TextEditingController(text: settings.aiModel);
    _key = TextEditingController(text: settings.aiKey);
  }

  @override
  void dispose() {
    _endpoint.dispose();
    _model.dispose();
    _key.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final app = AppScope.read(context);
    await app.updateSettings(app.settings.copyWith(
      aiEndpoint: _endpoint.text.trim(),
      aiModel: _model.text.trim(),
      aiKey: _key.text.trim(),
    ));
  }

  Future<bool> _askConsent() async {
    final s = AppScope.read(context).strings;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.privacy_tip_outlined),
        title: Text(s.aiConsentTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.aiWhatIsSent, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(s.aiWhatIsSentBody),
              const SizedBox(height: 12),
              Text(s.aiPrivacyNotice),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(s.cancel)),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(s.aiConsentAccept)),
        ],
      ),
    );
    return ok ?? false;
  }

  Future<void> _toggle(bool on) async {
    final app = AppScope.read(context);
    if (on && !await _askConsent()) return;
    if (!mounted) return;
    await app.updateSettings(app.settings.copyWith(aiEnabled: on));
  }

  Future<void> _test() async {
    final s = AppScope.read(context).strings;
    await _save();
    setState(() {
      _testing = true;
      _testResult = null;
    });
    final config = AiConfig(endpoint: _endpoint.text, model: _model.text, apiKey: _key.text);
    if (!config.isComplete) {
      setState(() {
        _testing = false;
        _testOk = false;
        _testResult = s.aiNotConfigured;
      });
      return;
    }
    try {
      await requestAiAnalysis(
        config,
        system: 'Reply with the single word OK.',
        user: 'OK?',
        timeout: const Duration(seconds: 30),
      );
      if (!mounted) return;
      setState(() {
        _testOk = true;
        _testResult = s.aiTestOk;
      });
    } on AiException catch (e) {
      if (!mounted) return;
      setState(() {
        _testOk = false;
        _testResult = s.aiError(e.message);
      });
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final s = app.strings;
    final theme = Theme.of(context);
    final on = app.settings.aiEnabled;
    return Scaffold(
      appBar: AppBar(title: Text(s.aiTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 32),
        children: [
          SwitchListTile(
            key: const ValueKey('ai-switch'),
            title: Text(s.aiOptional),
            subtitle: Text(s.aiHelp),
            value: on,
            onChanged: _toggle,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.aiWhatIsSent, style: theme.textTheme.titleSmall),
                    const SizedBox(height: 6),
                    Text(s.aiWhatIsSentBody, style: theme.textTheme.bodyMedium),
                    const SizedBox(height: 10),
                    Text(s.aiPrivacyNotice, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _endpoint,
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                  decoration: InputDecoration(
                    labelText: s.aiEndpoint,
                    hintText: s.aiEndpointHint,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (_) => _save(),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _model,
                  autocorrect: false,
                  decoration: InputDecoration(
                    labelText: s.aiModel,
                    hintText: s.aiModelHint,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (_) => _save(),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _key,
                  autocorrect: false,
                  enableSuggestions: false,
                  obscureText: !_showKey,
                  decoration: InputDecoration(
                    labelText: s.aiKey,
                    helperText: s.aiKeyHelp,
                    helperMaxLines: 2,
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(_showKey ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                      onPressed: () => setState(() => _showKey = !_showKey),
                    ),
                  ),
                  onChanged: (_) => _save(),
                ),
                const SizedBox(height: 12),
                Text(s.aiExamples, style: theme.textTheme.bodySmall),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _testing ? null : _test,
                  icon: _testing
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.wifi_tethering),
                  label: Text(s.aiTest),
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                ),
                if (_testResult != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _testResult!,
                      style: TextStyle(color: _testOk ? theme.colorScheme.primary : theme.colorScheme.error),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
