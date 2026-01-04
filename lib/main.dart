import 'dart:io';

import 'package:flutter/material.dart';
import 'package:remikit/services/rime_config_service.dart';
import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Remikit',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple), useMaterial3: true),
      home: const MyHomePage(title: 'Remikit Home Page'),
    );
  }
}

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
  void initState() {
    super.initState();
    _loadConfig();
  }

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

class ConfigEditorWidget extends StatelessWidget {
  final dynamic node;
  final List<dynamic> path;
  final Function(List<dynamic> path, dynamic value) onChanged;

  const ConfigEditorWidget({super.key, required this.node, required this.path, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return _YamlNodeWidget(node: node, path: path, onChanged: onChanged);
  }
}

class _YamlNodeWidget extends StatelessWidget {
  final dynamic node;
  final List<dynamic> path;
  final Function(List<dynamic> path, dynamic value) onChanged;

  const _YamlNodeWidget({required this.node, required this.path, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    if (node is YamlMap) {
      final map = node as YamlMap;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: map.entries.map((e) {
          return Padding(
            padding: const EdgeInsets.only(left: 16.0, top: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 12.0, right: 8.0),
                  child: Text('${e.key}: ', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: _YamlNodeWidget(node: e.value, path: [...path, e.key], onChanged: onChanged),
                ),
              ],
            ),
          );
        }).toList(),
      );
    } else if (node is YamlList) {
      final list = node as YamlList;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: list.asMap().entries.map((e) {
          return Padding(
            padding: const EdgeInsets.only(left: 16.0, top: 4.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 12.0, right: 8.0),
                  child: Text(
                    '- ',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                ),
                Expanded(
                  child: _YamlNodeWidget(node: e.value, path: [...path, e.key], onChanged: onChanged),
                ),
              ],
            ),
          );
        }).toList(),
      );
    } else if (node is bool) {
      return Row(
        children: [Switch(value: node as bool, onChanged: (value) => onChanged(path, value))],
      );
    } else {
      // String, int, double, null, etc.
      return _ScalarEditor(value: node, onChanged: (value) => onChanged(path, value));
    }
  }
}

class _ScalarEditor extends StatefulWidget {
  final dynamic value;
  final ValueChanged<dynamic> onChanged;

  const _ScalarEditor({required this.value, required this.onChanged});

  @override
  State<_ScalarEditor> createState() => _ScalarEditorState();
}

class _ScalarEditorState extends State<_ScalarEditor> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value?.toString() ?? '');
  }

  @override
  void didUpdateWidget(covariant _ScalarEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value.toString() != _controller.text) {
      _controller.text = widget.value?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true, contentPadding: EdgeInsets.all(8)),
      onSubmitted: (value) => _submit(value),
      onEditingComplete: () {
        FocusScope.of(context).unfocus();
        _submit(_controller.text);
      },
    );
  }

  void _submit(String value) {
    dynamic finalValue = value;
    // Try to preserve type
    if (widget.value is int) {
      finalValue = int.tryParse(value) ?? value;
    } else if (widget.value is double) {
      finalValue = double.tryParse(value) ?? value;
    }

    if (finalValue != widget.value) {
      widget.onChanged(finalValue);
    }
  }
}
