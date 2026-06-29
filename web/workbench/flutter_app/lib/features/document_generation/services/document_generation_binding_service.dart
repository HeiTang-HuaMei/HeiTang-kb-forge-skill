class DocumentGenerationBinding {
  const DocumentGenerationBinding({
    required this.selectedKbId,
    required this.selectedKbIds,
    required this.sourceKbIds,
    required this.sourceKbNames,
  });

  final String selectedKbId;
  final List<String> selectedKbIds;
  final List<String> sourceKbIds;
  final List<String> sourceKbNames;

  Map<String, Object?> toJson() {
    return {
      'selected_kb_id': selectedKbId,
      'selected_kb_ids': selectedKbIds,
      'source_kb_ids': sourceKbIds,
      'source_kb_names': sourceKbNames,
    };
  }
}

class DocumentGenerationSection {
  const DocumentGenerationSection({
    required this.id,
    required this.title,
    required this.purpose,
  });

  final String id;
  final String title;
  final String purpose;

  Map<String, String> toJson() {
    return {
      'id': id,
      'title': title,
      'purpose': purpose,
    };
  }
}

class DocumentGenerationStructure {
  const DocumentGenerationStructure({
    required this.title,
    required this.generationType,
    required this.templateMode,
    required this.sections,
    required this.requiredVariables,
    required this.templateEffects,
  });

  final String title;
  final String generationType;
  final String templateMode;
  final List<DocumentGenerationSection> sections;
  final List<String> requiredVariables;
  final List<String> templateEffects;

  List<String> get sectionTitles {
    return sections.map((section) => section.title).toList(growable: false);
  }

  Map<String, Object?> toJson() {
    return {
      'title': title,
      'generation_type': generationType,
      'template_mode': templateMode,
      'sections': sections.map((section) => section.toJson()).toList(),
      'section_titles': sectionTitles,
      'required_variables': requiredVariables,
      'template_effects': templateEffects,
      'type_structure_status': 'type_specific_sections_applied',
      'template_effect_status': 'template_mode_applied',
    };
  }
}

class DocumentGenerationStructureService {
  const DocumentGenerationStructureService();

  DocumentGenerationStructure resolve({
    required String title,
    required String generationType,
    required String templateMode,
  }) {
    return DocumentGenerationStructure(
      title: title,
      generationType: generationType,
      templateMode: templateMode,
      sections: _sectionsForType(generationType),
      requiredVariables: _requiredVariablesForTemplate(templateMode),
      templateEffects: _effectsForTemplate(templateMode),
    );
  }

  List<DocumentGenerationSection> _sectionsForType(String generationType) {
    return switch (generationType) {
      'summary' => const [
          DocumentGenerationSection(
            id: 'summary_points',
            title: '摘要重点',
            purpose: '提炼当前知识库中最需要先看的结论。',
          ),
          DocumentGenerationSection(
            id: 'source_coverage',
            title: '来源覆盖',
            purpose: '说明摘要覆盖了哪些来源资料。',
          ),
          DocumentGenerationSection(
            id: 'next_steps',
            title: '建议下一步',
            purpose: '给出基于摘要可以继续执行的动作。',
          ),
          DocumentGenerationSection(
            id: 'citations',
            title: '依据来源',
            purpose: '列出摘要引用的来源文件或片段。',
          ),
        ],
      'study_cards' => const [
          DocumentGenerationSection(
            id: 'learning_goal',
            title: '学习目标',
            purpose: '明确这组资料适合掌握的主题。',
          ),
          DocumentGenerationSection(
            id: 'knowledge_cards',
            title: '知识卡片',
            purpose: '把知识点整理成便于复习的卡片。',
          ),
          DocumentGenerationSection(
            id: 'self_check',
            title: '自测问题',
            purpose: '保留可用于复盘的问答。',
          ),
          DocumentGenerationSection(
            id: 'citations',
            title: '依据来源',
            purpose: '列出学习卡片对应的来源。',
          ),
        ],
      'structured_report' => const [
          DocumentGenerationSection(
            id: 'report_summary',
            title: '报告摘要',
            purpose: '先给出结构化报告结论。',
          ),
          DocumentGenerationSection(
            id: 'facts',
            title: '事实与证据',
            purpose: '按来源呈现可验证事实。',
          ),
          DocumentGenerationSection(
            id: 'gaps',
            title: '发现的问题',
            purpose: '标记证据缺口和需要补充的资料。',
          ),
          DocumentGenerationSection(
            id: 'recommendations',
            title: '建议补充资料',
            purpose: '给出下一轮补资料方向。',
          ),
          DocumentGenerationSection(
            id: 'citations',
            title: '依据来源',
            purpose: '列出报告引用的来源。',
          ),
        ],
      'ppt_outline' => const [
          DocumentGenerationSection(
            id: 'presentation_goal',
            title: '演示目标',
            purpose: '说明这份大纲要帮助听众理解什么。',
          ),
          DocumentGenerationSection(
            id: 'slide_outline',
            title: '幻灯片结构',
            purpose: '拆成可直接制作幻灯片的页面结构。',
          ),
          DocumentGenerationSection(
            id: 'talking_points',
            title: '关键讲述点',
            purpose: '保留每页可以展开讲述的证据。',
          ),
          DocumentGenerationSection(
            id: 'citations',
            title: '资料引用',
            purpose: '列出演示材料对应的来源。',
          ),
        ],
      'operation_plan' => const [
          DocumentGenerationSection(
            id: 'goal_scope',
            title: '目标和范围',
            purpose: '明确行动方案适用的资料和目标。',
          ),
          DocumentGenerationSection(
            id: 'actions',
            title: '执行动作',
            purpose: '把知识库结论转成可执行事项。',
          ),
          DocumentGenerationSection(
            id: 'risks',
            title: '风险和依赖',
            purpose: '指出执行前需要确认的条件。',
          ),
          DocumentGenerationSection(
            id: 'checkpoints',
            title: '检查点',
            purpose: '列出执行后的复盘节点。',
          ),
          DocumentGenerationSection(
            id: 'citations',
            title: '依据来源',
            purpose: '列出行动方案引用的资料。',
          ),
        ],
      'product_analysis' => const [
          DocumentGenerationSection(
            id: 'product_problem',
            title: '产品问题',
            purpose: '把资料中的产品问题或用户需求显性化。',
          ),
          DocumentGenerationSection(
            id: 'user_scenarios',
            title: '用户 / 场景证据',
            purpose: '从知识库中提取用户、场景、约束证据。',
          ),
          DocumentGenerationSection(
            id: 'opportunities_risks',
            title: '机会与风险',
            purpose: '区分可以推进的机会和需要核查的风险。',
          ),
          DocumentGenerationSection(
            id: 'recommendations',
            title: '建议方案',
            purpose: '把分析转成可执行产品建议。',
          ),
          DocumentGenerationSection(
            id: 'citations',
            title: '依据来源',
            purpose: '列出分析使用的来源片段。',
          ),
        ],
      'qa_script' => const [
          DocumentGenerationSection(
            id: 'scenario',
            title: '适用场景',
            purpose: '说明问答稿面向的使用场景。',
          ),
          DocumentGenerationSection(
            id: 'qa_script',
            title: '问题脚本',
            purpose: '整理可直接使用的问题和回答。',
          ),
          DocumentGenerationSection(
            id: 'answer_evidence',
            title: '回答依据',
            purpose: '把回答和知识库来源对应起来。',
          ),
          DocumentGenerationSection(
            id: 'followups',
            title: '追问建议',
            purpose: '给出下一轮可追问的问题。',
          ),
          DocumentGenerationSection(
            id: 'citations',
            title: '依据来源',
            purpose: '列出问答稿引用的来源。',
          ),
        ],
      _ => const [
          DocumentGenerationSection(
            id: 'core_summary',
            title: '核心摘要',
            purpose: '概括当前资料的主要内容。',
          ),
          DocumentGenerationSection(
            id: 'source_outline',
            title: '章节 / 主题结构',
            purpose: '按来源资料呈现主题结构。',
          ),
          DocumentGenerationSection(
            id: 'key_concepts',
            title: '关键概念',
            purpose: '列出知识库中抽取出的概念或主题。',
          ),
          DocumentGenerationSection(
            id: 'actions',
            title: '可执行行动项',
            purpose: '把资料结论转成下一步动作。',
          ),
          DocumentGenerationSection(
            id: 'agent_use_points',
            title: '适合后续 Agent 使用的要点',
            purpose: '保留可供助手回答使用的问题和证据。',
          ),
          DocumentGenerationSection(
            id: 'citations',
            title: '引用来源或文件名',
            purpose: '列出文档使用的来源文件或片段。',
          ),
        ],
    };
  }

  List<String> _requiredVariablesForTemplate(String templateMode) {
    return switch (templateMode) {
      'custom' => const [
          'document_title',
          'selected_kb_ids',
          'custom_template_sections',
          'citation_list',
        ],
      'agent' => const [
          'document_title',
          'selected_kb_ids',
          'agent_use_boundary',
          'citation_list',
        ],
      _ => const [
          'document_title',
          'selected_kb_ids',
          'source_summary',
          'citation_list',
        ],
    };
  }

  List<String> _effectsForTemplate(String templateMode) {
    return switch (templateMode) {
      'custom' => const [
          'custom_section_contract',
          'required_variable_check',
          'citation_boundary_check',
        ],
      'agent' => const [
          'agent_use_scaffold',
          'kb_boundary_instruction',
          'citation_required_instruction',
        ],
      _ => const [
          'built_in_document_scaffold',
          'source_summary_block',
          'citation_required_instruction',
        ],
    };
  }
}

class DocumentGenerationMarkdownService {
  const DocumentGenerationMarkdownService();

  String render({
    required DocumentGenerationStructure structure,
    required String generationTypeLabel,
    required String templateModeLabel,
    required String outputFormatLabel,
    required String citationStrategyLabel,
    required int sourceCount,
    required int chunkCount,
    required int cardCount,
    required int qaPairCount,
    required List<String> sources,
    required List<Map<String, dynamic>> topCards,
    required List<Map<String, dynamic>> topQa,
    required List<Map<String, dynamic>> topChunks,
  }) {
    final buffer = StringBuffer()
      ..writeln('# ${structure.title}')
      ..writeln()
      ..writeln('## 生成配置')
      ..writeln('- 文档类型：$generationTypeLabel')
      ..writeln('- 模板模式：$templateModeLabel')
      ..writeln('- 输出格式：$outputFormatLabel')
      ..writeln('- 来源显示方式：$citationStrategyLabel')
      ..writeln()
      ..writeln('## 模板效果');
    for (final effect in structure.templateEffects) {
      buffer.writeln('- $effect');
    }
    buffer
      ..writeln()
      ..writeln('## 模板变量');
    for (final variable in structure.requiredVariables) {
      buffer.writeln('- $variable');
    }
    buffer
      ..writeln()
      ..writeln('## 知识库概况')
      ..writeln('- 来源资料：$sourceCount 个。')
      ..writeln(
          '- 知识库包含 $chunkCount 个 chunks、$cardCount 张 cards、$qaPairCount 个 QA pairs。')
      ..writeln('- 内容来自真实解析产物和知识库索引，不是固定演示文本。');
    for (final section in structure.sections) {
      buffer
        ..writeln()
        ..writeln('## ${section.title}')
        ..writeln('- 结构目的：${section.purpose}');
      _writeSectionContent(
        buffer,
        section,
        sources: sources,
        topCards: topCards,
        topQa: topQa,
        topChunks: topChunks,
      );
    }
    return buffer.toString();
  }

  static void _writeSectionContent(
    StringBuffer buffer,
    DocumentGenerationSection section, {
    required List<String> sources,
    required List<Map<String, dynamic>> topCards,
    required List<Map<String, dynamic>> topQa,
    required List<Map<String, dynamic>> topChunks,
  }) {
    switch (section.id) {
      case 'source_outline':
      case 'source_coverage':
        if (sources.isEmpty) {
          buffer.writeln('- 暂无来源资料。');
        } else {
          for (final source in sources) {
            buffer.writeln('- $source');
          }
        }
      case 'key_concepts':
      case 'knowledge_cards':
      case 'facts':
      case 'user_scenarios':
      case 'opportunities_risks':
        if (topCards.isEmpty) {
          buffer.writeln('- 暂无可用知识卡片。');
        } else {
          for (final card in topCards) {
            buffer
                .writeln('- ${_compact(card['title'] ?? card['summary'] ?? card)}');
          }
        }
      case 'agent_use_points':
      case 'self_check':
      case 'qa_script':
      case 'answer_evidence':
        if (topQa.isEmpty) {
          buffer.writeln('- 暂无可用问答记录。');
        } else {
          for (final qa in topQa) {
            buffer.writeln(
                '- Q: ${_compact(qa['question'] ?? qa['prompt'] ?? qa)} / A: ${_compact(qa['answer'] ?? qa['response'] ?? '')}');
          }
        }
      case 'citations':
        if (topChunks.isEmpty) {
          buffer.writeln('- 暂无可用引用来源。');
        } else {
          for (final chunk in topChunks) {
            buffer.writeln(
                '- ${_compact(chunk['source_path'] ?? chunk['citation'] ?? '')}');
          }
        }
      default:
        buffer
          ..writeln('- 把每个主题拆成可检索问题，优先使用带 citation 的 chunk。')
          ..writeln('- 对 OCR/Parser 噪声较高的段落标记 review_required。')
          ..writeln('- 将输出限制为引用知识库证据的摘要、问答、质检和运营分析。');
    }
  }

  static String _compact(Object? value, {int maxLength = 180}) {
    final text = value?.toString().replaceAll(RegExp(r'\s+'), ' ').trim() ?? '';
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }
}

class DocumentExportSource {
  const DocumentExportSource({
    required this.path,
    required this.kind,
    required this.priority,
  });

  final String path;
  final String kind;
  final int priority;

  Map<String, Object?> toJson() {
    return {
      'path': path,
      'kind': kind,
      'priority': priority,
    };
  }
}

class DocumentExportSourceResolver {
  const DocumentExportSourceResolver();

  DocumentExportSource resolve({
    required bool hasEditedDocument,
    required bool hasReadingNotes,
    required bool hasGeneratedMarkdown,
    required String editedDocumentPath,
    required String readingNotesPath,
    required String generatedMarkdownPath,
  }) {
    if (hasEditedDocument) {
      return DocumentExportSource(
        path: editedDocumentPath,
        kind: 'edited_document',
        priority: 1,
      );
    }
    if (hasReadingNotes) {
      return DocumentExportSource(
        path: readingNotesPath,
        kind: 'reading_notes',
        priority: 2,
      );
    }
    if (hasGeneratedMarkdown) {
      return DocumentExportSource(
        path: generatedMarkdownPath,
        kind: 'generated_markdown',
        priority: 3,
      );
    }
    return const DocumentExportSource(
      path: '',
      kind: 'missing',
      priority: 0,
    );
  }

  List<String> get priorityOrder {
    return const [
      'edited_document',
      'reading_notes',
      'generated_markdown',
    ];
  }
}

class DocumentCitationPolicyResult {
  const DocumentCitationPolicyResult({
    required this.passed,
    required this.status,
    required this.reason,
    required this.usableCitationCount,
  });

  final bool passed;
  final String status;
  final String reason;
  final int usableCitationCount;

  Map<String, Object?> toJson() {
    return {
      'passed': passed,
      'status': status,
      'reason': reason,
      'usable_citation_count': usableCitationCount,
    };
  }
}

class DocumentCitationPolicyService {
  const DocumentCitationPolicyService();

  DocumentCitationPolicyResult validate({
    required String citationStrategy,
    required List<Map<String, Object?>> citations,
  }) {
    final usableCitationCount = citations.where(_hasUsableEvidence).length;
    if (citationStrategy != 'strict_citation') {
      return DocumentCitationPolicyResult(
        passed: true,
        status: 'not_required',
        reason: '',
        usableCitationCount: usableCitationCount,
      );
    }
    if (usableCitationCount > 0) {
      return DocumentCitationPolicyResult(
        passed: true,
        status: 'pass',
        reason: '',
        usableCitationCount: usableCitationCount,
      );
    }
    return const DocumentCitationPolicyResult(
      passed: false,
      status: 'blocked_missing_source_evidence',
      reason: '严格引用模式需要至少一条可追溯来源证据。',
      usableCitationCount: 0,
    );
  }

  static bool _hasUsableEvidence(Map<String, Object?> citation) {
    final citationText = _stringValue(citation['citation']);
    final kbId = _stringValue(citation['kb_id']);
    final sourceTraceId = _stringValue(citation['source_trace_id']);
    final chunkId = _stringValue(citation['chunk_id']);
    final sourceDocId = _stringValue(citation['source_doc_id']);
    final traceComplete = citation['trace_complete'] == true;
    return citationText.isNotEmpty &&
        (traceComplete ||
            (kbId.isNotEmpty &&
                (sourceTraceId.isNotEmpty ||
                    chunkId.isNotEmpty ||
                    sourceDocId.isNotEmpty)));
  }

  static String _stringValue(Object? value) {
    return value?.toString().trim() ?? '';
  }
}

class DocumentGenerationBindingService {
  const DocumentGenerationBindingService();

  DocumentGenerationBinding resolve({
    required Map<String, dynamic> queryReport,
    required List<Map<String, dynamic>> knowledgeBaseRecords,
  }) {
    final querySelectedIds = _stringList(queryReport['selected_kb_ids']);
    final queryResultIds = _idsFromRows(
      queryReport['selected'] ??
          queryReport['results'] ??
          queryReport['records'],
    );
    final catalogIds = knowledgeBaseRecords
        .map((record) => (record['kb_id'] ?? '').toString().trim())
        .where((id) => id.isNotEmpty)
        .toList(growable: false);
    final selectedKbIds = querySelectedIds.isNotEmpty
        ? querySelectedIds
        : queryResultIds.isNotEmpty
            ? queryResultIds
            : catalogIds.isNotEmpty
                ? _unique(catalogIds)
                : const ['current_kb'];
    final catalogNameById = {
      for (final record in knowledgeBaseRecords)
        if ((record['kb_id'] ?? '').toString().trim().isNotEmpty)
          (record['kb_id'] ?? '').toString().trim():
              (record['kb_name'] ?? record['kb_id'] ?? '').toString().trim(),
    };
    final resultNameById = _namesFromRows(
      queryReport['selected'] ??
          queryReport['results'] ??
          queryReport['records'],
    );
    final sourceKbNames = selectedKbIds
        .map((id) => resultNameById[id] ?? catalogNameById[id] ?? id)
        .where((name) => name.trim().isNotEmpty)
        .toList(growable: false);
    return DocumentGenerationBinding(
      selectedKbId: selectedKbIds.first,
      selectedKbIds: selectedKbIds,
      sourceKbIds: selectedKbIds,
      sourceKbNames: sourceKbNames,
    );
  }

  static List<String> _stringList(Object? value) {
    if (value is! List) return const <String>[];
    return _unique(value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty));
  }

  static List<String> _idsFromRows(Object? rows) {
    if (rows is! List) return const <String>[];
    return _unique(rows
        .whereType<Map>()
        .map((row) => (row['kb_id'] ?? '').toString().trim())
        .where((id) => id.isNotEmpty));
  }

  static Map<String, String> _namesFromRows(Object? rows) {
    if (rows is! List) return const <String, String>{};
    return {
      for (final row in rows.whereType<Map>())
        if ((row['kb_id'] ?? '').toString().trim().isNotEmpty)
          (row['kb_id'] ?? '').toString().trim():
              (row['kb_name'] ?? row['kb_id'] ?? '').toString().trim(),
    };
  }

  static List<String> _unique(Iterable<String> values) {
    final seen = <String>{};
    final result = <String>[];
    for (final value in values) {
      final trimmed = value.trim();
      if (trimmed.isEmpty || seen.contains(trimmed)) continue;
      seen.add(trimmed);
      result.add(trimmed);
    }
    return List<String>.unmodifiable(result);
  }
}

class DocumentCitationTraceService {
  const DocumentCitationTraceService();

  List<Map<String, Object?>> fromQueryReport(Map<String, dynamic> queryReport) {
    final rows = queryReport['selected'] ??
        queryReport['results'] ??
        queryReport['records'];
    if (rows is! List) return const <Map<String, Object?>>[];
    return rows
        .whereType<Map>()
        .map((row) => _citationFromRow(row))
        .where((row) => row['citation']!.toString().trim().isNotEmpty)
        .toList(growable: false);
  }

  Map<String, Object?> _citationFromRow(Map row) {
    final sourceDocId = _stringValue(row['source_doc_id'] ??
        row['source_document_id'] ??
        row['document_id']);
    final sourceDocument = _stringValue(
        row['source_document'] ?? row['source_path'] ?? row['source_name']);
    return {
      'text': _compact(row['text'] ?? row['excerpt'] ?? row['title']),
      'citation': _stringValue(row['citation'] ?? row['source_path']),
      'kb_id': _stringValue(row['kb_id']),
      'kb_name': _stringValue(row['kb_name']),
      'chunk_id': _stringValue(row['chunk_id']),
      'source_trace_id': _stringValue(row['source_trace_id']),
      'source_doc_id': sourceDocId,
      'source_document': sourceDocument,
      'source_path': _stringValue(row['source_path']),
      'page_number': row['page_number'],
      'section_id': _stringValue(row['section_id']),
      'block_ids': _stringList(row['block_ids']),
      'heading_path': _stringList(row['heading_path']),
      'lineage': row['lineage'] is Map
          ? Map<String, Object?>.from(row['lineage'] as Map)
          : const <String, Object?>{},
      'trace_complete': _stringValue(row['source_trace_id']).isNotEmpty &&
          _stringValue(row['chunk_id']).isNotEmpty &&
          sourceDocId.isNotEmpty,
    };
  }

  static String _stringValue(Object? value) {
    return value?.toString().trim() ?? '';
  }

  static List<String> _stringList(Object? value) {
    if (value is! List) return const <String>[];
    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  static String _compact(Object? value, {int maxLength = 180}) {
    final text = value?.toString().replaceAll(RegExp(r'\s+'), ' ').trim() ?? '';
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }
}
