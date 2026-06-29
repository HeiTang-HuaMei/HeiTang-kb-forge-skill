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

class AgentLegacyBindingTruth {
  const AgentLegacyBindingTruth({
    required this.kbIds,
    required this.skillIds,
    required this.legacyKbAliases,
    required this.legacySkillAliases,
  });

  final List<String> kbIds;
  final List<String> skillIds;
  final Map<String, String> legacyKbAliases;
  final Map<String, String> legacySkillAliases;

  String kbAt(int index) {
    if (kbIds.isEmpty) return 'current_kb';
    if (index >= 0 && index < kbIds.length) return kbIds[index];
    return kbIds.first;
  }

  String skillOrFallback(String preferred) {
    if (skillIds.contains(preferred)) return preferred;
    return skillIds.isEmpty ? preferred : skillIds.first;
  }
}

class AgentBindingTruthService {
  const AgentBindingTruthService();

  AgentBindingTruth resolveLegacyManifest(Map<String, dynamic> manifest) {
    return resolveManifests(agentManifest: manifest);
  }

  AgentBindingTruth resolveManifests({
    required Map<String, dynamic> agentManifest,
    Map<String, dynamic> skillBindingManifest = const <String, dynamic>{},
  }) {
    final kbIds = _stringList(
      agentManifest['kb_ids'] ?? agentManifest['bound_knowledge_base_ids'],
    );
    final aliases = _stringMap(
      skillBindingManifest['legacy_skill_aliases'] ??
          agentManifest['legacy_skill_aliases'],
    );
    final bindingSkillIds = _stringList(
      skillBindingManifest['skill_ids'] ??
          skillBindingManifest['bound_skill_ids'],
    );
    final agentSkillIds = _stringList(
      agentManifest['skill_ids'] ?? agentManifest['bound_skill_ids'],
    );
    final skillIds = kbIds.isEmpty
        ? const <String>[]
        : _resolveAliases(
            bindingSkillIds.isNotEmpty ? bindingSkillIds : agentSkillIds,
            aliases,
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

  AgentLegacyBindingTruth resolveLegacyPackageBinding({
    required Iterable<String> sourceKbIds,
    required Iterable<String> generatedSkillIds,
    Map<String, String> legacySkillAliases = const <String, String>{},
  }) {
    final kbIds = _uniqueStrings(sourceKbIds);
    final effectiveKbIds = kbIds.isEmpty ? const ['current_kb'] : kbIds;
    final skillIds = _uniqueStrings(
      _resolveAliases(generatedSkillIds, legacySkillAliases),
    );
    final effectiveSkillIds =
        skillIds.isEmpty ? const ['knowledge_qa_skill'] : skillIds;
    return AgentLegacyBindingTruth(
      kbIds: effectiveKbIds,
      skillIds: effectiveSkillIds,
      legacyKbAliases: {
        'K1': effectiveKbIds.first,
        'K2': effectiveKbIds.length > 1 ? effectiveKbIds[1] : effectiveKbIds.first,
        'K3': effectiveKbIds.length > 2 ? effectiveKbIds[2] : effectiveKbIds.first,
      },
      legacySkillAliases: legacySkillAliases,
    );
  }

  static Map<String, String> _stringMap(Object? value) {
    if (value is! Map) return const <String, String>{};
    final result = <String, String>{};
    for (final entry in value.entries) {
      final key = entry.key.toString().trim();
      final mapped = entry.value.toString().trim();
      if (key.isNotEmpty && mapped.isNotEmpty) {
        result[key] = mapped;
      }
    }
    return result;
  }

  static List<String> _stringList(Object? value) {
    if (value is! List) return const <String>[];
    return _uniqueStrings(value.map((item) => item.toString()));
  }

  static List<String> _uniqueStrings(Iterable<Object?> values) {
    final seen = <String>{};
    final result = <String>[];
    for (final value in values) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty && seen.add(text)) {
        result.add(text);
      }
    }
    return result;
  }

  static List<String> _resolveAliases(
    Iterable<String> ids,
    Map<String, String> aliases,
  ) {
    final seen = <String>{};
    final result = <String>[];
    for (final id in ids) {
      final resolved = aliases[id]?.trim().isNotEmpty == true
          ? aliases[id]!.trim()
          : id.trim();
      if (resolved.isNotEmpty && seen.add(resolved)) {
        result.add(resolved);
      }
    }
    return result;
  }
}
