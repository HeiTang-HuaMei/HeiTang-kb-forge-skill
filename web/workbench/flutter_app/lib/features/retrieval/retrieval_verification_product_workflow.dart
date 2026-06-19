part of '../../main.dart';

class _RetrievalVerificationView extends StatefulWidget {
  const _RetrievalVerificationView({required this.zh});

  final bool zh;

  @override
  State<_RetrievalVerificationView> createState() =>
      _RetrievalVerificationViewState();
}

class _RetrievalVerificationViewState
    extends State<_RetrievalVerificationView> {
  bool retrievalPrepared = false;
  final Set<String> selectedKbIds = <String>{};
  String selectedStage = 'rewrite';
  String validationReportPath = '';
  final Map<int, String> correctionState = <int, String>{};
  final TextEditingController _queryController =
      TextEditingController(text: 'heitang-rc6-needle');

  bool get zh => widget.zh;

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rc6 = _Rc6RuntimeScope.of(context);
    final runtime = rc6?.state ?? Rc6RuntimeState.initial();
    final realResults = [...runtime.searchResults]..sort((a, b) =>
        (double.tryParse(b.score) ?? 0)
            .compareTo(double.tryParse(a.score) ?? 0));
    final citedCount =
        realResults.where((result) => result.citation.trim().isNotEmpty).length;
    final faithfulness = realResults.isEmpty
        ? 0
        : ((citedCount / realResults.length) * 100).round();
    final uniqueCitationCount = realResults
        .map((result) => result.citation.trim())
        .where((citation) => citation.isNotEmpty)
        .toSet()
        .length;
    final selectedEvidenceCount =
        runtime.searchStatus == Rc6SearchStatus.success
            ? realResults.length
            : 0;
    final kbOptions = runtime.knowledgeBases.isNotEmpty
        ? runtime.knowledgeBases
            .map((kb) => _KbSelectionOption(
                  kb.id,
                  kb.name,
                  '${kb.chunkCount} chunks · ${kb.operation}',
                  kb.status == 'searchable' && kb.chunkCount > 0,
                ))
            .toList(growable: false)
        : [
            _KbSelectionOption(
              'default_kb',
              zh ? '当前知识库' : 'Current KB',
              runtime.hasKnowledgeBase
                  ? '${runtime.chunkCount} chunks'
                  : (zh ? '请先构建' : 'Build first'),
              runtime.hasKnowledgeBase,
            ),
          ];
    final enabledKbIds =
        kbOptions.where((option) => option.enabled).map((option) => option.id);
    selectedKbIds.removeWhere((id) => !enabledKbIds.contains(id));
    if (selectedKbIds.isEmpty && enabledKbIds.isNotEmpty) {
      selectedKbIds.add(enabledKbIds.first);
    }
    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 900;
      final extraWide = constraints.maxWidth >= 1180;
      final feedback = runtime.searchStatus != Rc6SearchStatus.idle
          ? _RuntimeFeedbackBanner(
              title: runtime.searchStatus == Rc6SearchStatus.success
                  ? (zh ? '真实检索已返回结果' : 'Real retrieval returned results')
                  : runtime.searchStatus == Rc6SearchStatus.empty
                      ? (zh ? '真实检索无结果' : 'Real retrieval returned no results')
                      : runtime.searchStatus == Rc6SearchStatus.error
                          ? (zh ? '检索失败' : 'Search failed')
                          : (zh ? '检索中' : 'Searching'),
              detail: runtime.queryResultPath.isEmpty
                  ? runtime.lastMessage
                  : runtime.queryResultPath,
              tone: runtime.searchStatus == Rc6SearchStatus.success
                  ? _StatusTone.success
                  : runtime.searchStatus == Rc6SearchStatus.error
                      ? _StatusTone.danger
                      : _StatusTone.warning,
              icon: Icons.manage_search_outlined,
            )
          : null;
      final query = _ProductPanel(
        keyName: 'retrieval-workflow',
        icon: Icons.manage_search_outlined,
        title: zh ? '查询控制台' : 'Query Console',
        minHeight: 430,
        subtitle: zh
            ? '本页查询只检索所选知识库；顶部全局搜索用于快速定位文档、知识库、Skill 和 Agent。'
            : 'This page searches the selected KB only; top search locates docs, KBs, Skills, and Agents.',
        children: [
          _SectionCaption(zh ? '所选知识库' : 'Selected knowledge bases'),
          const SizedBox(height: 6),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final option in kbOptions)
              FilterChip(
                label: Text('${option.label} · ${option.detail}'),
                selected: selectedKbIds.contains(option.id),
                onSelected: option.enabled
                    ? (selected) => setState(() {
                          if (selected) {
                            selectedKbIds.add(option.id);
                          } else {
                            selectedKbIds.remove(option.id);
                          }
                        })
                    : null,
              ),
          ]),
          const SizedBox(height: 8),
          TextField(
            key: const Key('retrieval-real-query-input'),
            controller: _queryController,
            enabled: !runtime.running,
            onSubmitted: (value) =>
                rc6?.searchKnowledgeBases(value, selectedKbIds.toList()),
            decoration: InputDecoration(
              labelText: zh ? '真实搜索关键词' : 'Real search keyword',
              helperText: zh
                  ? '输入关键词后返回知识库证据片段、引用来源和评分。'
                  : 'Enter keywords to return KB evidence, citations, and score.',
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          _RetrievalStageButtons(
            zh: zh,
            selectedStage: selectedStage,
            onSelected: (value) => setState(() => selectedStage = value),
          ),
          const SizedBox(height: 8),
          _RuntimeFeedbackBanner(
            title: _retrievalStageLabel(selectedStage, zh),
            detail: _retrievalStageDetail(selectedStage, zh),
            tone: _StatusTone.neutral,
            icon: Icons.account_tree_outlined,
          ),
          const SizedBox(height: _DesktopGrid.gutter),
          _ProductTable(
            columns: zh
                ? ['证据片段', '知识库', '引用来源', '评分', '证据选择', '人工纠偏']
                : [
                    'Evidence snippet',
                    'Knowledge Base',
                    'Citation',
                    'Score',
                    'Evidence',
                    'Correction'
                  ],
            rows: realResults.isEmpty
                ? [
                    [
                      zh ? '等待真实检索结果' : 'Waiting for real result',
                      selectedKbIds.isEmpty
                          ? (zh ? '请先选择知识库' : 'Select a KB first')
                          : selectedKbIds.join(', '),
                      runtime.hasKnowledgeBase
                          ? (zh ? '本地知识库' : 'Local KB')
                          : (zh ? '未构建' : 'Not built'),
                      '-',
                      runtime.searchStatus == Rc6SearchStatus.empty
                          ? (zh ? '无结果' : 'Empty')
                          : (zh ? '未搜索' : 'Not searched'),
                      runtime.lastError.isEmpty
                          ? (zh ? '待处理' : 'Pending')
                          : runtime.lastError,
                    ]
                  ]
                : [
                    for (var index = 0; index < realResults.length; index++)
                      [
                        realResults[index].excerpt.isEmpty
                            ? realResults[index].title
                            : realResults[index].excerpt,
                        realResults[index].kbName.isNotEmpty
                            ? realResults[index].kbName
                            : realResults[index].kbId,
                        realResults[index].citation.isEmpty
                            ? (zh ? '无引用' : 'No citation')
                            : realResults[index].citation,
                        realResults[index].score.isEmpty
                            ? '-'
                            : realResults[index].score,
                        zh ? '已选证据' : 'Selected evidence',
                        _correctionLabel(correctionState[index], zh),
                      ],
                  ],
          ),
          if (realResults.isNotEmpty) ...[
            const SizedBox(height: 8),
            _CorrectionActionStrip(
              zh: zh,
              selectedIndex: 0,
              onCorrection: (value) =>
                  setState(() => correctionState[0] = value),
            ),
          ],
        ],
      );
      final metrics = _ProductPanel(
        icon: Icons.analytics_outlined,
        title: zh ? '验证指标与边界' : 'Verification Metrics and Boundary',
        gap: true,
        minHeight: 430,
        children: [
          _MetricGrid(
            columns: 2,
            items: [
              _MetricDatum(
                  label: zh ? '准确率' : 'Accuracy',
                  value: runtime.searchStatus == Rc6SearchStatus.success
                      ? '${realResults.length}/${runtime.chunkCount}'
                      : '-',
                  detail: zh ? '命中证据 / 返回证据' : 'matched / returned',
                  icon: Icons.verified_outlined),
              _MetricDatum(
                  label: zh ? '忠实度' : 'Faithfulness',
                  value: runtime.searchStatus == Rc6SearchStatus.success
                      ? '$faithfulness%'
                      : '-',
                  detail: zh ? '有引用答案 / 全部答案' : 'cited / all',
                  icon: Icons.link_outlined),
              _MetricDatum(
                  label: zh ? '覆盖率' : 'Coverage',
                  value: uniqueCitationCount.toString(),
                  detail: zh ? '命中引用来源数' : 'citation sources',
                  icon: Icons.pie_chart_outline),
              _MetricDatum(
                  label: zh ? '矛盾项' : 'Contradictions',
                  value: runtime.searchStatus == Rc6SearchStatus.success
                      ? correctionState.values
                          .where((value) =>
                              value == 'conflict' || value == 'contradiction')
                          .length
                          .toString()
                      : '-',
                  detail: zh ? '人工可纠偏' : 'manual correction',
                  icon: Icons.warning_amber_outlined),
            ],
          ),
          const SizedBox(height: _DesktopGrid.gutter),
          _FieldRow(
            label: zh ? '评分公式' : 'Scoring rule',
            value: zh
                ? '相关性 = 关键词命中 50% + chunk 分数 35% + 来源覆盖 15%'
                : 'Relevance = keyword match 50% + chunk score 35% + source coverage 15%',
          ),
          const SizedBox(height: 8),
          _EqualActionRow(children: [
            _PrimaryProductAction(
              label: zh ? '运行真实检索' : 'Run real retrieval',
              onPressed: runtime.running || rc6 == null
                  ? null
                  : () {
                      setState(() => retrievalPrepared = true);
                      rc6.searchKnowledgeBases(
                          _queryController.text, selectedKbIds.toList());
                    },
              icon: Icons.play_arrow_outlined,
            ),
            _PrimaryProductAction(
              label: zh ? '保存验证报告' : 'Save validation report',
              onPressed: runtime.queryResultPath.isEmpty || rc6 == null
                  ? null
                  : () async {
                      final path = await rc6
                          .saveRetrievalValidationReport(correctionState);
                      if (mounted && path.isNotEmpty) {
                        setState(() => validationReportPath = path);
                      }
                    },
              icon: Icons.save_alt_outlined,
            ),
          ]),
          const SizedBox(height: 8),
          _EqualActionRow(children: [
            _RuntimeFeedbackBanner(
              title: zh ? '外部事实验证未启用' : 'External fact checking is not enabled',
              detail: zh
                  ? '需要在设置中配置联网 Provider、Tool Adapter 和显式 opt-in；当前检索只使用本地知识库证据。'
                  : 'Requires network Provider, Tool Adapter, and explicit opt-in in Settings; current retrieval uses local KB evidence only.',
              tone: _StatusTone.neutral,
              icon: Icons.public_off_outlined,
            ),
          ]),
          if (validationReportPath.isNotEmpty) ...[
            const SizedBox(height: 8),
            _RuntimeFeedbackBanner(
              title: zh ? '验证报告已保存' : 'Validation report saved',
              detail: validationReportPath,
              tone: _StatusTone.success,
              icon: Icons.fact_check_outlined,
            ),
          ],
          const SizedBox(height: 8),
          _FieldRow(
            label: zh ? '外部验证边界' : 'External verification boundary',
            value: zh
                ? '联网 Provider、Tool Adapter 和显式 opt-in 配齐后启用'
                : 'Enabled only after network Provider, Tool Adapter, and explicit opt-in are configured',
          ),
        ],
      );
      final reasoning = _ProductPanel(
        keyName: 'retrieval-reasoning-panel',
        icon: Icons.account_tree_outlined,
        title: zh ? '证据选择与推理' : 'Evidence Selection and Reasoning',
        children: [
          _ProductTable(
            columns: zh ? ['阶段', '结果', '说明'] : ['Stage', 'Result', 'Note'],
            rows: zh
                ? [
                    [
                      '查询改写',
                      runtime.retrievalPlanPath.isNotEmpty ? '完成' : '等待',
                      runtime.retrievalPlanPath.isNotEmpty
                          ? _displayNameForPath(runtime.retrievalPlanPath)
                          : '保留原问题边界'
                    ],
                    [
                      '检索规划',
                      runtime.retrievalPlanPath.isNotEmpty ? '混合检索' : '等待',
                      '向量 + 关键词'
                    ],
                    [
                      '重排',
                      runtime.retrievalRerankReportPath.isNotEmpty
                          ? '完成'
                          : '等待',
                      runtime.retrievalRerankReportPath.isNotEmpty
                          ? _displayNameForPath(
                              runtime.retrievalRerankReportPath)
                          : '按评分与引用完整性排序'
                    ],
                    [
                      '证据选择',
                      retrievalPrepared ? '$selectedEvidenceCount 条' : '等待',
                      '只引用本地证据'
                    ],
                    [
                      '交叉验证',
                      runtime.externalValidationBoundaryPath.isNotEmpty
                          ? '本地边界已记录'
                          : '等待',
                      runtime.externalValidationBoundaryPath.isNotEmpty
                          ? _displayNameForPath(
                              runtime.externalValidationBoundaryPath)
                          : '授权联网后与外部来源逐条比对'
                    ],
                  ]
                : [
                    [
                      'Query rewrite',
                      runtime.retrievalPlanPath.isNotEmpty ? 'Done' : 'Waiting',
                      runtime.retrievalPlanPath.isNotEmpty
                          ? _displayNameForPath(runtime.retrievalPlanPath)
                          : 'Keeps original scope'
                    ],
                    [
                      'Retrieval planning',
                      runtime.retrievalPlanPath.isNotEmpty
                          ? 'Hybrid'
                          : 'Waiting',
                      'Vector + keyword'
                    ],
                    [
                      'Rerank',
                      runtime.retrievalRerankReportPath.isNotEmpty
                          ? 'Done'
                          : 'Waiting',
                      runtime.retrievalRerankReportPath.isNotEmpty
                          ? _displayNameForPath(
                              runtime.retrievalRerankReportPath)
                          : 'Sort by score and citation completeness'
                    ],
                    [
                      'Evidence selection',
                      retrievalPrepared
                          ? '$selectedEvidenceCount selected'
                          : 'Waiting',
                      'Local evidence only'
                    ],
                    [
                      'Cross validation',
                      runtime.externalValidationBoundaryPath.isNotEmpty
                          ? 'Boundary recorded'
                          : 'Waiting',
                      runtime.externalValidationBoundaryPath.isNotEmpty
                          ? _displayNameForPath(
                              runtime.externalValidationBoundaryPath)
                          : 'Compare with external sources after authorization'
                    ],
                  ],
          ),
        ],
      );
      if (!wide) {
        return Column(children: [
          if (feedback != null) ...[
            feedback,
            const SizedBox(height: _DesktopGrid.gutter),
          ],
          query,
          const SizedBox(height: _DesktopGrid.gutter),
          reasoning,
          const SizedBox(height: _DesktopGrid.gutter),
          metrics
        ]);
      }
      if (extraWide) {
        return Column(children: [
          if (feedback != null) ...[
            feedback,
            const SizedBox(height: _DesktopGrid.gutter),
          ],
          _EqualHeightRow(
            height: 430,
            flexes: const [8, 4],
            children: [query, metrics],
          ),
          const SizedBox(height: _DesktopGrid.gutter),
          reasoning,
        ]);
      }
      return Column(children: [
        if (feedback != null) ...[
          feedback,
          const SizedBox(height: _DesktopGrid.gutter),
        ],
        _EqualHeightRow(
          height: 430,
          flexes: const [7, 5],
          children: [query, metrics],
        ),
        const SizedBox(height: _DesktopGrid.gutter),
        reasoning,
      ]);
    });
  }
}

class _KbSelectionOption {
  const _KbSelectionOption(this.id, this.label, this.detail, this.enabled);

  final String id;
  final String label;
  final String detail;
  final bool enabled;
}

class _RetrievalStageButtons extends StatelessWidget {
  const _RetrievalStageButtons({
    required this.zh,
    required this.selectedStage,
    required this.onSelected,
  });

  final bool zh;
  final String selectedStage;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    const stages = ['rewrite', 'planning', 'hybrid', 'rerank', 'verify'];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final stage in stages)
          ChoiceChip(
            label: Text(_retrievalStageLabel(stage, zh)),
            selected: selectedStage == stage,
            onSelected: (_) => onSelected(stage),
          ),
      ],
    );
  }
}

String _retrievalStageLabel(String stage, bool zh) {
  return switch (stage) {
    'planning' => zh ? '检索规划' : 'Retrieval planning',
    'hybrid' => zh ? '混合检索' : 'Hybrid retrieval',
    'rerank' => zh ? '重排' : 'Rerank',
    'verify' => zh ? '证据验证' : 'Evidence verification',
    _ => zh ? '查询改写' : 'Query rewrite',
  };
}

String _retrievalStageDetail(String stage, bool zh) {
  return switch (stage) {
    'planning' => zh
        ? '选择知识库范围、关键词策略和返回数量。'
        : 'Choose KB scope, keyword strategy, and result count.',
    'hybrid' => zh
        ? '结合本地关键词和 chunks/cards 索引。'
        : 'Combine local keywords with chunks/cards indexes.',
    'rerank' => zh
        ? '按相关性、来源覆盖和引用完整性排序。'
        : 'Sort by relevance, source coverage, and citation completeness.',
    'verify' => zh
        ? '逐条保留、忽略或标记矛盾；外部验证需授权。'
        : 'Keep, ignore, or mark contradictions one by one; external checking requires authorization.',
    _ => zh
        ? '保留用户原意，展开同义词和文件名线索。'
        : 'Preserve intent while expanding synonyms and filename hints.',
  };
}

String _correctionLabel(String? value, bool zh) {
  return switch (value) {
    'contradiction' => zh ? '已标记矛盾' : 'Contradiction marked',
    'ignore' => zh ? '已忽略' : 'Ignored',
    'review' => zh ? '待人工复核' : 'Needs review',
    'keep' => zh ? '已保留' : 'Kept',
    _ => zh ? '待纠偏' : 'Pending correction',
  };
}

class _CorrectionActionStrip extends StatelessWidget {
  const _CorrectionActionStrip({
    required this.zh,
    required this.selectedIndex,
    required this.onCorrection,
  });

  final bool zh;
  final int selectedIndex;
  final ValueChanged<String> onCorrection;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _DisplayAction(
          label: zh
              ? '保留第 ${selectedIndex + 1} 条'
              : 'Keep result ${selectedIndex + 1}',
          icon: Icons.check_circle_outline,
          onPressed: () => onCorrection('keep'),
        ),
        _DisplayAction(
          label: zh ? '标记矛盾' : 'Mark contradiction',
          icon: Icons.warning_amber_outlined,
          onPressed: () => onCorrection('contradiction'),
        ),
        _DisplayAction(
          label: zh ? '忽略' : 'Ignore',
          icon: Icons.visibility_off_outlined,
          onPressed: () => onCorrection('ignore'),
        ),
        _DisplayAction(
          label: zh ? '人工复核' : 'Manual review',
          icon: Icons.rate_review_outlined,
          onPressed: () => onCorrection('review'),
        ),
      ],
    );
  }
}

class _RetrievalVerificationProductWorkflow extends StatefulWidget {
  const _RetrievalVerificationProductWorkflow({required this.localeCode});

  final String localeCode;

  @override
  State<_RetrievalVerificationProductWorkflow> createState() =>
      _RetrievalVerificationProductWorkflowState();
}

class _RetrievalVerificationProductWorkflowState
    extends State<_RetrievalVerificationProductWorkflow> {
  bool get _zh => widget.localeCode == 'zh-CN';

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _ProductHeader(
        icon: Icons.manage_search_outlined,
        title: _zh ? '检索与验证' : 'Retrieval & Verification',
        description: _zh
            ? '先选择知识库，再查询；证据片段、引用、评分、纠偏和授权外部验证都在同一查询台完成。'
            : 'Select a KB first, then query; evidence, citations, scoring, correction, and authorized external checking stay in one console.',
      ),
      const SizedBox(height: _DesktopGrid.gutter),
      _RetrievalVerificationView(zh: _zh),
    ]);
  }
}
