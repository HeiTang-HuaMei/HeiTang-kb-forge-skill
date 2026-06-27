class AgentBindingTruth {
  const AgentBindingTruth({
    required this.kbIds,
    required this.skillIds,
    required this.status,
    required this.missingBindingReasons,
  });

  final List<String> kbIds;
  final List<String> skillIds;
  final String status;
  final List<String> missingBindingReasons;
}

class AgentBindingTruthService {
  const AgentBindingTruthService();

  AgentBindingTruth resolveLegacyManifest(Map<String, dynamic> manifest) {
    final kbIds = _stringList(
      manifest['kb_ids'] ?? manifest['bound_knowledge_base_ids'],
    );
    final skillIds = _stringList(
      manifest['skill_ids'] ?? manifest['bound_skill_ids'],
    );
    final missing = <String>[
      if (kbIds.isEmpty) 'missing_kb_binding',
      if (skillIds.isEmpty) 'missing_skill_binding',
    ];
    final status = missing.isEmpty
        ? 'bound'
        : missing.length == 2
            ? 'unbound'
            : 'partially_bound';
    return AgentBindingTruth(
      kbIds: kbIds,
      skillIds: skillIds,
      status: status,
      missingBindingReasons: missing,
    );
  }

  static List<String> _stringList(Object? value) {
    if (value is! List) return const <String>[];
    final seen = <String>{};
    final result = <String>[];
    for (final item in value) {
      final text = item.toString().trim();
      if (text.isNotEmpty && seen.add(text)) {
        result.add(text);
      }
    }
    return result;
  }
}
