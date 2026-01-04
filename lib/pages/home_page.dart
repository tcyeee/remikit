import 'dart:io';

import 'package:flutter/material.dart';
import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';
import '../services/rime_config_service.dart';
import '../widgets/yaml_editor/config_editor.dart';

/// The main home page of the application.
///
/// This page displays the configuration editor and the raw source code view.
/// It handles loading and saving the configuration using [RimeConfigService].
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _configContent = 'Loading...';
  String? _configPath;
  dynamic _parsedYaml;
  YamlEditor? _yamlEditor;
  final _rimeConfigService = RimeConfigService();
  bool _isSaving = false;

  @override
  /// Initializes the state of the home page.
  ///
  /// This method calls [_loadConfig] to load the initial configuration.
  void initState() {
    super.initState();
    _loadConfig();
  }

  /// Loads the configuration from the file system.
  Future<void> _loadConfig() async {
    setState(() {
      _configContent = 'Loading...';
      _parsedYaml = null;
      _yamlEditor = null;
    });

    final result = await _rimeConfigService.readConfig();

    if (mounted) {
      setState(() {
        if (result != null) {
          _configPath = result.path;
          _configContent = result.content;
          try {
            _yamlEditor = YamlEditor(result.content);
            _parsedYaml = loadYaml(result.content);
          } catch (e) {
            _configContent = 'Error parsing YAML: $e\n\n${result.content}';
          }
        } else {
          _configPath = null;
          _configContent = 'Config file not found.\n\nPlease ensure Rime is installed and configured.';
        }
      });
    }
  }

  /// Updates a value in the configuration at the specified path.
  void _updateConfig(List<dynamic> path, dynamic value) {
    if (_yamlEditor == null) return;
    try {
      _yamlEditor!.update(path, value);
      setState(() {
        _configContent = _yamlEditor!.toString();
        // Reload parsed yaml to reflect changes in UI
        _parsedYaml = loadYaml(_configContent);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating config: $e')));
    }
  }

  /// Saves the current configuration to disk.
  Future<void> _saveConfig() async {
    if (_configPath == null || _configContent.isEmpty) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final file = File(_configPath!);
      await file.writeAsString(_configContent);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved successfully')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  /// Builds the UI for the home page.
  ///
  /// Displays a tab bar with two views: "Visual Editor" and "Source Code".
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text(widget.title),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Visual Editor'),
              Tab(text: 'Source Code'),
            ],
          ),
          actions: [
            if (_configPath != null)
              IconButton(
                icon: _isSaving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.save),
                onPressed: _isSaving ? null : _saveConfig,
              ),
          ],
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_configPath != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: SelectableText(
                  'Path: $_configPath',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            Expanded(
              child: TabBarView(
                children: [
                  // Editor View
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: _buildEditorView(),
                  ),
                  // Source View
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8.0),
                    child: SingleChildScrollView(
                      child: SelectableText(_configContent, style: const TextStyle(fontFamily: 'monospace')),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the visual editor view.
  ///
  /// Returns a [ConfigEditorWidget] if data is loaded, or a message if not.
  Widget _buildEditorView() {
    if (_parsedYaml == null) {
      return const Center(child: Text('No data'));
    }
    if (_parsedYaml is String) {
      return Center(child: Text(_parsedYaml));
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(8.0),
      child: ConfigEditorWidget(node: _parsedYaml, path: const [], onChanged: _updateConfig),
    );
  }
}
