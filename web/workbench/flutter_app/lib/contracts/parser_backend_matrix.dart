import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

class ParserBackendMatrix {
  const ParserBackendMatrix({
    required this.schemaVersion,
    required this.releaseVersion,
    required this.releaseTitle,
    required this.runtimeBaselineCommit,
    required this.baselineHygieneCommit,
    required this.v400TagExpectedCommit,
    required this.defaultHeavyDependenciesBundled,
    required this.defaultCoreParserChanged,
    required this.staticWorkbenchRuntimeExecutionClaimed,
    required this.acceptanceReportPath,
    required this.knownLimitationReportPath,
    required this.backends,
  });

  final String schemaVersion;
  final String releaseVersion;
  final String releaseTitle;
  final String runtimeBaselineCommit;
  final String baselineHygieneCommit;
  final String v400TagExpectedCommit;
  final bool defaultHeavyDependenciesBundled;
  final bool defaultCoreParserChanged;
  final bool staticWorkbenchRuntimeExecutionClaimed;
  final String acceptanceReportPath;
  final String knownLimitationReportPath;
  final List<ParserBackendRecord> backends;

  factory ParserBackendMatrix.fromJsonString(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException(
          'Parser backend matrix must be a JSON object.');
    }
    return ParserBackendMatrix.fromJson(decoded);
  }

  factory ParserBackendMatrix.fromJson(Map<String, dynamic> json) {
    return ParserBackendMatrix(
      schemaVersion: _string(json['schema_version']),
      releaseVersion: _string(json['release_version']),
      releaseTitle: _string(json['release_title']),
      runtimeBaselineCommit: _string(json['runtime_baseline_commit']),
      baselineHygieneCommit: _string(json['baseline_hygiene_commit']),
      v400TagExpectedCommit: _string(json['v4_0_0_tag_expected_commit']),
      defaultHeavyDependenciesBundled:
          _bool(json['default_heavy_dependencies_bundled']),
      defaultCoreParserChanged: _bool(json['default_core_parser_changed']),
      staticWorkbenchRuntimeExecutionClaimed:
          _bool(json['static_workbench_runtime_execution_claimed']),
      acceptanceReportPath: _string(json['acceptance_report_path']),
      knownLimitationReportPath: _string(json['known_limitation_report_path']),
      backends: _list(json['backends'])
          .map((item) => ParserBackendRecord.fromJson(_map(item)))
          .toList(growable: false),
    );
  }

  ParserBackendRecord? backend(String backendId) {
    for (final backend in backends) {
      if (backend.backendId == backendId) {
        return backend;
      }
    }
    return null;
  }

  int get realRuntimeIntegratedCount => backends
      .where((backend) =>
          backend.workbenchState.contains('real_runtime_integrated'))
      .length;

  int get optionalDependencyGatedCount => backends
      .where((backend) =>
          backend.workbenchState.contains('optional_dependency_gated'))
      .length;

  int get limitedSurfaceCount => backends
      .where((backend) => backend.workbenchState.contains('limited_surface'))
      .length;
}

class ParserBackendRecord {
  const ParserBackendRecord({
    required this.backendId,
    required this.displayName,
    required this.dependencyMode,
    required this.optionalExtra,
    required this.defaultInstallAvailable,
    required this.currentEnvironmentAvailable,
    required this.dependencyAvailable,
    required this.runtimeInvoked,
    required this.sampleInputType,
    required this.validatedStableSurface,
    required this.adapterSupportedExtensions,
    required this.knownLimitations,
    required this.status,
    required this.workbenchState,
    required this.evidencePath,
    required this.fallbackBehavior,
    required this.staticWorkbenchExecutable,
  });

  final String backendId;
  final String displayName;
  final String dependencyMode;
  final String? optionalExtra;
  final bool defaultInstallAvailable;
  final bool currentEnvironmentAvailable;
  final bool dependencyAvailable;
  final bool runtimeInvoked;
  final String sampleInputType;
  final List<String> validatedStableSurface;
  final List<String> adapterSupportedExtensions;
  final List<String> knownLimitations;
  final String status;
  final List<String> workbenchState;
  final String evidencePath;
  final String fallbackBehavior;
  final bool staticWorkbenchExecutable;

  BackendInstallMode get installMode => BackendInstallMode(
        dependencyMode: dependencyMode,
        optionalExtra: optionalExtra,
        defaultInstallAvailable: defaultInstallAvailable,
      );

  BackendEvidence get evidence => BackendEvidence(
        status: lastAcceptanceStatus,
        dependencyAvailable: dependencyAvailable,
        runtimeInvoked: runtimeInvoked,
        sampleInputType: sampleInputType,
        evidencePath: evidencePath,
      );

  BackendCapabilityBoundary get capabilityBoundary => BackendCapabilityBoundary(
        validatedStableSurface: validatedStableSurface,
        adapterSupportedExtensions: adapterSupportedExtensions,
        workbenchState: workbenchState,
        staticWorkbenchExecutable: staticWorkbenchExecutable,
      );

  BackendFallbackBehavior get fallback =>
      BackendFallbackBehavior(description: fallbackBehavior);

  List<BackendLimitation> get limitations => knownLimitations
      .map((limitation) => BackendLimitation(description: limitation))
      .toList(growable: false);

  String get lastAcceptanceStatus {
    if (status == 'builtin_passed') {
      return 'pass';
    }
    if (dependencyAvailable && runtimeInvoked) {
      return 'pass';
    }
    if (!dependencyAvailable) {
      return 'blocked_by_dependency';
    }
    return 'not_invoked';
  }

  bool get isOptionalDependencyGated =>
      workbenchState.contains('optional_dependency_gated');

  bool get isLimitedSurface => workbenchState.contains('limited_surface');

  bool get isRealRuntimeIntegrated =>
      workbenchState.contains('real_runtime_integrated');

  factory ParserBackendRecord.fromJson(Map<String, dynamic> json) {
    return ParserBackendRecord(
      backendId: _string(json['backend_id']),
      displayName: _string(json['display_name']),
      dependencyMode: _string(json['dependency_mode']),
      optionalExtra: json['optional_extra'] == null
          ? null
          : _string(json['optional_extra']),
      defaultInstallAvailable: _bool(json['default_install_available']),
      currentEnvironmentAvailable: _bool(json['current_environment_available']),
      dependencyAvailable: _bool(json['dependency_available']),
      runtimeInvoked: _bool(json['runtime_invoked']),
      sampleInputType: _string(json['sample_input_type']),
      validatedStableSurface: _strings(json['validated_stable_surface']),
      adapterSupportedExtensions:
          _strings(json['adapter_supported_extensions']),
      knownLimitations: _strings(json['known_limitations']),
      status: _string(json['status']),
      workbenchState: _strings(json['workbench_state']),
      evidencePath: _string(json['evidence_path']),
      fallbackBehavior: _string(json['fallback_behavior']),
      staticWorkbenchExecutable: _bool(json['static_workbench_executable']),
    );
  }
}

typedef ParserBackendStatus = ParserBackendRecord;

class BackendEvidence {
  const BackendEvidence({
    required this.status,
    required this.dependencyAvailable,
    required this.runtimeInvoked,
    required this.sampleInputType,
    required this.evidencePath,
  });

  final String status;
  final bool dependencyAvailable;
  final bool runtimeInvoked;
  final String sampleInputType;
  final String evidencePath;
}

class BackendCapabilityBoundary {
  const BackendCapabilityBoundary({
    required this.validatedStableSurface,
    required this.adapterSupportedExtensions,
    required this.workbenchState,
    required this.staticWorkbenchExecutable,
  });

  final List<String> validatedStableSurface;
  final List<String> adapterSupportedExtensions;
  final List<String> workbenchState;
  final bool staticWorkbenchExecutable;
}

class BackendFallbackBehavior {
  const BackendFallbackBehavior({required this.description});

  final String description;
}

class BackendLimitation {
  const BackendLimitation({required this.description});

  final String description;
}

class BackendInstallMode {
  const BackendInstallMode({
    required this.dependencyMode,
    required this.optionalExtra,
    required this.defaultInstallAvailable,
  });

  final String dependencyMode;
  final String? optionalExtra;
  final bool defaultInstallAvailable;

  String get label => optionalExtra ?? dependencyMode;
}

class ParserBackendMatrixLoader {
  const ParserBackendMatrixLoader();

  Future<ParserBackendMatrix> loadFromAsset(String path) async {
    return ParserBackendMatrix.fromJsonString(
        await rootBundle.loadString(path));
  }
}

final sampleParserBackendMatrix = ParserBackendMatrix.fromJson({
  'schema_version': 'p2.1.parser_backend_matrix.v1',
  'release_version': 'v4.1.0',
  'release_title':
      'HeiTang KB Forge v4.1.0 Parser/OCR Pluggable Backend Runtime',
  'runtime_baseline_commit': '576a62075dc1ecbe00388bb0569fd1fc767be7cb',
  'baseline_hygiene_commit': '13640d5',
  'v4_0_0_tag_expected_commit': '0217e54b162871e7c40c31ff3d0cc72e8ba78f06',
  'default_heavy_dependencies_bundled': false,
  'default_core_parser_changed': false,
  'static_workbench_runtime_execution_claimed': false,
  'acceptance_report_path':
      'docs/audits/parser_runtime_acceptance/parser_runtime_acceptance_report.json',
  'known_limitation_report_path':
      'docs/audits/p2_1_parser_ocr_backends/backend_capability_boundaries.md',
  'backends': [
    _sampleBackend(
      'builtin',
      'Built-in parser fallback',
      'default',
      null,
      ['.md', '.txt'],
      'builtin_passed',
      ['builtin_passed'],
      'Preserved default parser path; used when optional backend is missing or not selected.',
    ),
    _sampleBackend(
      'docling',
      'Docling local runtime adapter',
      'optional_extra',
      'parser-docling',
      ['.md', '.txt'],
      'real_runtime_integrated',
      [
        'real_runtime_integrated',
        'optional_dependency_gated',
        'limited_surface'
      ],
      'If parser-docling is missing or runtime fails, builtin fallback guidance is preserved.',
    ),
    _sampleBackend(
      'paddleocr',
      'PaddleOCR local OCR runtime adapter',
      'optional_extra',
      'parser-paddleocr',
      ['.png'],
      'real_runtime_integrated',
      [
        'real_runtime_integrated',
        'optional_dependency_gated',
        'limited_surface'
      ],
      'If parser-paddleocr or model/runtime is missing, builtin fallback guidance is preserved.',
    ),
    _sampleBackend(
      'unstructured',
      'Unstructured local runtime adapter',
      'optional_extra',
      'parser-unstructured',
      ['.md', '.txt'],
      'real_runtime_integrated',
      [
        'real_runtime_integrated',
        'optional_dependency_gated',
        'limited_surface'
      ],
      'If parser-unstructured is missing or runtime fails, builtin fallback guidance is preserved.',
      knownLimitations: [
        'Stable P2.1 surface is explicitly limited to .md/.txt.'
      ],
    ),
  ],
});

Map<String, Object?> _sampleBackend(
  String backendId,
  String displayName,
  String dependencyMode,
  String? optionalExtra,
  List<String> stableSurface,
  String status,
  List<String> workbenchState,
  String fallbackBehavior, {
  List<String> knownLimitations = const [
    'Optional backend evidence is limited to the release acceptance surface.'
  ],
}) {
  return {
    'backend_id': backendId,
    'display_name': displayName,
    'dependency_mode': dependencyMode,
    'optional_extra': optionalExtra,
    'default_install_available': backendId == 'builtin',
    'current_environment_available': backendId == 'builtin',
    'dependency_available': true,
    'runtime_invoked': true,
    'sample_input_type': backendId == 'paddleocr'
        ? 'PNG OCR image in live acceptance replay'
        : 'Markdown/TXT document source in live acceptance replay',
    'validated_stable_surface': stableSurface,
    'adapter_supported_extensions': stableSurface,
    'known_limitations': knownLimitations,
    'status': status,
    'workbench_state': workbenchState,
    'evidence_path':
        'docs/audits/parser_runtime_acceptance/parser_runtime_acceptance_report.json',
    'fallback_behavior': fallbackBehavior,
    'static_workbench_executable': false,
  };
}

Map<String, dynamic> _map(Object? value) =>
    value is Map<String, dynamic> ? value : <String, dynamic>{};

List<dynamic> _list(Object? value) => value is List ? value : <dynamic>[];

List<String> _strings(Object? value) =>
    _list(value).map((item) => item.toString()).toList(growable: false);

String _string(Object? value) => value?.toString() ?? '';

bool _bool(Object? value) =>
    value is bool ? value : value?.toString().toLowerCase() == 'true';
