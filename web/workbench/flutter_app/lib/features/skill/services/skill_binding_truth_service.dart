class SkillBindingTruth {
  const SkillBindingTruth({
    required this.sourceKbIds,
    required this.primarySkillId,
    required this.externalSkillId,
    required this.localizedSkillId,
    required this.fusedSkillId,
    required this.helperSkillIds,
    required this.legacyAliases,
  });

  final List<String> sourceKbIds;
  final String primarySkillId;
  final String externalSkillId;
  final String localizedSkillId;
  final String fusedSkillId;
  final List<String> helperSkillIds;
  final Map<String, String> legacyAliases;

  List<String> get generatedSkillIds => [
        primarySkillId,
        localizedSkillId,
        ...helperSkillIds,
        fusedSkillId,
      ];

  List<String> get fusedSourceSkillIds => [
        primarySkillId,
        'operation_conversion_skill',
        'product_analysis_skill',
      ];
}

class SkillBindingTruthService {
  const SkillBindingTruthService();

  SkillBindingTruth resolve({
    required Iterable<Map<String, dynamic>> catalogRecords,
    required Iterable<String> stateKnowledgeBaseIds,
  }) {
    final sourceKbIds = _uniqueStrings([
      ...catalogRecords
          .where((record) => !_isDeleted(record))
          .map((record) => record['kb_id']),
      ...stateKnowledgeBaseIds,
    ]);
    return SkillBindingTruth(
      sourceKbIds: sourceKbIds.isEmpty ? const ['current_kb'] : sourceKbIds,
      primarySkillId: 'knowledge_qa_skill',
      externalSkillId: 'external_imported_skill',
      localizedSkillId: 'localized_writing_skill',
      fusedSkillId: 'fused_product_ops_skill',
      helperSkillIds: const [
        'reading_summary_skill',
        'quality_check_skill',
        'operation_conversion_skill',
        'product_analysis_skill',
      ],
      legacyAliases: const {
        'S0': 'external_imported_skill',
        'S1': 'knowledge_qa_skill',
        'S2': 'localized_writing_skill',
      },
    );
  }

  static bool _isDeleted(Map<String, dynamic> record) {
    final status = record['status']?.toString().trim().toLowerCase();
    return record['is_deleted'] == true || status == 'deleted';
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
}
