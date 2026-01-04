import 'package:flutter/material.dart';
import 'package:remikit/services/rime_config_service.dart';
import 'package:yaml/yaml.dart';

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
      home: const MyHomePage(title: 'Remikit - Rime Config'),
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
  final _rimeConfigService = RimeConfigService();

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    setState(() {
      _configContent = 'Loading...';
      _parsedYaml = null;
    });

    final result = await _rimeConfigService.readConfig();
    setState(() {
      if (result != null) {
        _configPath = result.path;
        _configContent = result.content;
        try {
          _parsedYaml = loadYaml(result.content);
        } catch (e) {
          _parsedYaml = 'Error parsing YAML: $e';
        }
      } else {
        _configPath = null;
        _configContent = 'Config file not found.\n\nPlease ensure Rime is installed and configured.';
      }
    });
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
              Tab(text: 'Raw Content'),
              Tab(text: 'Parsed Info'),
            ],
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_configPath != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: SelectableText(
                    'Path: $_configPath',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              Expanded(
                child: TabBarView(
                  children: [
                    // Raw View
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(4),
                        color: Colors.grey[50],
                      ),
                      child: SingleChildScrollView(
                        child: SelectableText(_configContent, style: const TextStyle(fontFamily: 'monospace')),
                      ),
                    ),
                    // Parsed View
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: _buildParsedView(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _loadConfig,
          tooltip: 'Reload',
          child: const Icon(Icons.refresh),
        ),
      ),
    );
  }

  Widget _buildParsedView() {
    if (_parsedYaml == null) {
      return const Center(child: Text('No data'));
    }
    if (_parsedYaml is String) {
      return Center(child: Text(_parsedYaml));
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(8.0),
      child: _YamlNodeWidget(node: _parsedYaml),
    );
  }
}

class _YamlNodeWidget extends StatelessWidget {
  final dynamic node;

  const _YamlNodeWidget({required this.node});

  @override
  Widget build(BuildContext context) {
    if (node is YamlMap) {
      final map = node as YamlMap;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: map.entries.map((e) {
          return Padding(
            padding: const EdgeInsets.only(left: 16.0, top: 4.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${e.key}: ',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                ),
                Expanded(child: _YamlNodeWidget(node: e.value)),
              ],
            ),
          );
        }).toList(),
      );
    } else if (node is YamlList) {
      final list = node as YamlList;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: list.map((e) {
          return Padding(
            padding: const EdgeInsets.only(left: 16.0, top: 4.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '- ',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                ),
                Expanded(child: _YamlNodeWidget(node: e)),
              ],
            ),
          );
        }).toList(),
      );
    } else {
      return Text(node.toString());
    }
  }
}
