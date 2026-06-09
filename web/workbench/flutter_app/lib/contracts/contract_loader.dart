import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'contract_models.dart';

class WorkbenchContractLoader {
  const WorkbenchContractLoader();

  WorkbenchContracts loadFromBundleJson(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Workbench contract bundle must be a JSON object.');
    }
    return WorkbenchContracts.fromJson(decoded);
  }

  Future<WorkbenchContracts> loadFromAsset(String path) async {
    return loadFromBundleJson(await rootBundle.loadString(path));
  }

  WorkbenchContracts loadFromContracts({
    required String manifest,
    required String navigation,
    required String actions,
    required String assets,
    required String status,
    required String agent,
    required String hierarchy,
    required String memory,
    required String storage,
    required String errors,
  }) {
    return WorkbenchContracts.fromJson({
      'manifest': _decodeMap(manifest, 'manifest'),
      'navigation': _decodeMap(navigation, 'navigation'),
      'actions': _decodeMap(actions, 'actions'),
      'assets': _decodeMap(assets, 'assets'),
      'status': _decodeMap(status, 'status'),
      'agent': _decodeMap(agent, 'agent'),
      'hierarchy': _decodeMap(hierarchy, 'hierarchy'),
      'memory': _decodeMap(memory, 'memory'),
      'storage': _decodeMap(storage, 'storage'),
      'errors': _decodeMap(errors, 'errors'),
    });
  }

  Map<String, dynamic> _decodeMap(String source, String name) {
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic>) {
      throw FormatException('$name contract must be a JSON object.');
    }
    return decoded;
  }
}
