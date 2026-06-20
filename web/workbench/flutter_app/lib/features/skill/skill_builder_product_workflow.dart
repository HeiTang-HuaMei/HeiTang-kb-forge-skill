part of '../../main.dart';

class _SkillBuilderProductWorkflow extends StatefulWidget {
  const _SkillBuilderProductWorkflow({
    required this.localeCode,
    required this.workspace,
  });

  final String localeCode;
  final String workspace;

  @override
  State<_SkillBuilderProductWorkflow> createState() =>
      _SkillBuilderProductWorkflowState();
}

class _SkillBuilderProductWorkflowState
    extends State<_SkillBuilderProductWorkflow> {
  bool configReady = false;
  bool outputPreviewReady = false;
  bool validationReady = false;
  int selectedTab = 0;
  String skillType = 'analysis';
  String targetPlatform = 'codex';
  String personalizationGoal = '';
  final TextEditingController _skillNameController =
      TextEditingController(text: '真实输入知识问答 Skill');
  final TextEditingController _skillEditorController = TextEditingController();
  String savedSkillEditPath = '';

  bool get _zh => widget.localeCode == 'zh-CN';

  @override
  void dispose() {
    _skillNameController.dispose();
    _skillEditorController.dispose();
    super.dispose();
  }

  Rc6SkillGenerationConfig get _skillConfig => Rc6SkillGenerationConfig(
        customSkillName: _skillNameController.text,
        skillType: skillType,
        targetPlatform: targetPlatform,
        personalizationGoal: personalizationGoal,
      );

  String _skillTypeLabel(String value) => switch (value) {
        'writing' => _zh ? '写作 Skill' : 'Writing',
        'teaching' => _zh ? '教学 Skill' : 'Teaching',
        'product' => _zh ? '产品 Skill' : 'Product',
        'ops' => _zh ? '运营 Skill' : 'Operations',
        'legal' => _zh ? '法规 Skill' : 'Legal',
        'custom' => _zh ? '自定义 Skill' : 'Custom',
        _ => _zh ? '分析 Skill' : 'Analysis',
      };

  String _targetPlatformLabel(String value) => switch (value) {
        'claude_code' => 'Claude Code',
        'openclaw' => 'OpenClaw',
        'markdown' => 'Markdown',
        'internal_agent' => _zh ? '内置 Agent' : 'Internal Agent',
        _ => 'Codex',
      };

  String _personalizationGoalLabel(String value) => switch (value) {
        'domain_localization' => _zh ? '领域本地化' : 'Domain localization',
        'style_personalization' => _zh ? '用户风格化' : 'Style personalization',
        'platform_adaptation' => _zh ? '平台适配' : 'Platform adaptation',
        'task_customization' => _zh ? '任务定制' : 'Task customization',
        'enterprise_constraints' => _zh ? '企业知识约束' : 'Enterprise constraints',
        'agent_specific' => _zh ? 'Agent 专属化' : 'Agent-specific',
        _ => _zh ? '未选择' : 'Not selected',
      };

  Future<void> _confirmAndDeleteSkill(Rc6RuntimeController? rc6) async {
    if (rc6 == null || rc6.state.running || !rc6.state.hasSkill) return;
    final confirmed = await _confirmDestructiveAction(
      context,
      title: _zh ? '删除 Skill 产物？' : 'Delete Skill artifacts?',
      body: _zh
          ? '这会删除当前工作区里的 Skill，并清理依赖该 Skill 的对话和联合讨论输出；Agent 配置、知识库和文档不会被删除。'
          : 'This deletes Skill artifacts and clears dialogue/discussion outputs that depend on that Skill; Agent config, KB, and documents are kept.',
    );
    if (!confirmed) return;
    await rc6.clearSkillArtifacts();
  }

  @override
  Widget build(BuildContext context) {
    final rc6 = _Rc6RuntimeScope.of(context);
    final runtime = rc6?.state ?? Rc6RuntimeState.initial();
    final skillDraftPath = runtime.primarySkillPath.isNotEmpty
        ? runtime.primarySkillPath
        : runtime.skillPath.isNotEmpty
            ? '${runtime.skillPath}/knowledge_qa_skill/SKILL.md'
            : '';
    final skillBindingStatus = runtime.skillAgentBindingStatus.isNotEmpty
        ? runtime.skillAgentBindingStatus
        : runtime.hasAgent
            ? 'bound'
            : 'waiting_agent';
    final skillOperationStatus = runtime.skillOperationStatus.isNotEmpty
        ? runtime.skillOperationStatus
        : runtime.hasSkillOperationManifest
            ? 'pass'
            : '';
    Future<void> loadSkillDraft() async {
      if (rc6 == null || skillDraftPath.isEmpty) return;
      final content = await rc6.readWorkspaceTextArtifact(skillDraftPath);
      if (!mounted) return;
      setState(() {
        _skillEditorController.text = content;
        outputPreviewReady = true;
      });
    }

    Future<void> saveSkillDraft() async {
      if (rc6 == null) return;
      final path = await rc6.saveEditedSkill(_skillEditorController.text);
      if (!mounted) return;
      setState(() {
        savedSkillEditPath = path;
        validationReady = path.isNotEmpty;
      });
    }

    final tabs = _zh
        ? ['从知识库生成', '外部本地化', '版本操作', '验证导出']
        : [
            'Generate from KB',
            'External Localization',
            'Version Operations',
            'Validate & Export'
          ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _ProductHeader(
        icon: Icons.extension_outlined,
        title: _zh ? 'Skill 工厂' : 'Skill Factory',
        description: _zh
            ? '选择知识库，配置生成方式和元数据，验证后生成 Skill 草稿，用于 Agent 创建、绑定和导出。'
            : 'Select a Knowledge Base, configure generation and metadata, validate, then use the Skill draft for Agent creation, binding, and export.',
      ),
      const SizedBox(height: _DesktopGrid.gutter),
      _PageTabs(
        tabs: tabs,
        selectedIndex: selectedTab,
        onSelected: (index) => setState(() => selectedTab = index),
      ),
      const SizedBox(height: _DesktopGrid.gutter),
      _MetricStrip(
        items: [
          _MetricDatum(
              label: _zh ? '生成模式' : 'Generation modes',
              value: '2',
              detail: _zh ? '知识库 / 外部本地化' : 'KB / external fusion',
              icon: Icons.alt_route_outlined),
          _MetricDatum(
              label: _zh ? '目标平台' : 'Target platforms',
              value: '5',
              detail: _zh ? 'Codex 等' : 'Codex and more',
              icon: Icons.dashboard_customize_outlined),
          _MetricDatum(
              label: _zh ? '治理报告' : 'Governance',
              value: runtime.hasSkill ? 'pass' : 'ready',
              detail: runtime.hasSkill
                  ? (_zh ? '已生成' : 'Generated')
                  : (_zh ? '等待知识库' : 'Waiting KB'),
              icon: Icons.rule_folder_outlined),
        ],
      ),
      const SizedBox(height: _DesktopGrid.gutter),
      if (configReady || outputPreviewReady || validationReady) ...[
        _RuntimeFeedbackBanner(
          title: validationReady
              ? (_zh ? 'Skill 草稿已生成' : 'Skill draft generated')
              : outputPreviewReady
                  ? (_zh ? 'Skill 包结构已刷新' : 'Skill package structure refreshed')
                  : (_zh ? 'Skill 配置已准备' : 'Skill config prepared'),
          detail: runtime.hasSkill
              ? runtime.skillPath
              : (_zh
                  ? '请先构建知识库，再生成真实 Skill package。'
                  : 'Build a KB first, then generate a real Skill package.'),
          tone: runtime.hasSkill ? _StatusTone.success : _StatusTone.warning,
          icon: Icons.extension_outlined,
        ),
        const SizedBox(height: _DesktopGrid.gutter),
      ],
      LayoutBuilder(builder: (context, constraints) {
        final wide = constraints.maxWidth >= 920;
        final config = _ProductPanel(
          keyName: 'skill-metadata-source-config',
          icon: Icons.edit_note_outlined,
          title: _zh ? '从知识库生成 Skill' : 'Generate Skill from KB',
          children: [
            _ProductTable(
              columns:
                  _zh ? ['生成模式', '来源', '状态'] : ['Mode', 'Source', 'Status'],
              rows: _zh
                  ? [
                      [
                        '从知识库生成 Skill',
                        '当前知识库',
                        runtime.hasSkill
                            ? '已生成'
                            : runtime.hasKnowledgeBase
                                ? '可生成'
                                : '请先构建知识库'
                      ],
                      [
                        '外部 Skill 本地化',
                        'S0 + 当前知识库',
                        runtime.hasSkill
                            ? '已生成 S2'
                            : runtime.hasKnowledgeBase
                                ? '可生成'
                                : '请先构建知识库'
                      ],
                      [
                        '多知识库 Skill',
                        '当前 KB Catalog',
                        runtime.hasSkill
                            ? '已生成'
                            : runtime.hasKnowledgeBase
                                ? '可生成'
                                : '请先构建知识库'
                      ],
                    ]
                  : [
                      [
                        'Generate Skill from KB',
                        'Current KB',
                        runtime.hasSkill
                            ? 'Generated'
                            : runtime.hasKnowledgeBase
                                ? 'Ready'
                                : 'Build KB first'
                      ],
                      [
                        'External Skill localization',
                        'S0 + current KB',
                        runtime.hasSkill
                            ? 'S2 generated'
                            : runtime.hasKnowledgeBase
                                ? 'Ready'
                                : 'Build KB first'
                      ],
                      [
                        'Multi-KB Skill',
                        'Current KB catalog',
                        runtime.hasSkill
                            ? 'Generated'
                            : runtime.hasKnowledgeBase
                                ? 'Ready'
                                : 'Build KB first'
                      ],
                    ],
            ),
            const SizedBox(height: 8),
            _FieldRow(
                label: _zh ? '上游承接物' : 'Upstream input',
                value: runtime.kbManifestPath.isNotEmpty
                    ? _displayNameForPath(runtime.kbManifestPath)
                    : (_zh ? '等待真实知识库' : 'Waiting for real Knowledge Base')),
            const SizedBox(height: 8),
            TextField(
              key: const Key('skill-name-input'),
              controller: _skillNameController,
              enabled: rc6 != null && !runtime.running,
              decoration: InputDecoration(
                labelText: _zh ? 'Skill 名称' : 'Skill name',
                helperText: _zh
                    ? '写入 SKILL.md、配置、验证和导出清单。'
                    : 'Written to SKILL.md, config, validation, and export manifests.',
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            _FieldRow(
                label: _zh ? 'Skill 类型' : 'Skill type',
                value: _skillTypeLabel(skillType)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final item in const [
                'analysis',
                'writing',
                'teaching',
                'product',
                'ops',
                'legal',
                'custom',
              ])
                ChoiceChip(
                  label: Text(_skillTypeLabel(item)),
                  selected: skillType == item,
                  onSelected: (_) => setState(() => skillType = item),
                ),
            ]),
            const SizedBox(height: 8),
            _FieldRow(
                label: _zh ? '目标平台' : 'Target platform',
                value: _targetPlatformLabel(targetPlatform)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final item in const [
                'codex',
                'claude_code',
                'openclaw',
                'markdown',
                'internal_agent',
              ])
                ChoiceChip(
                  label: Text(_targetPlatformLabel(item)),
                  selected: targetPlatform == item,
                  onSelected: (_) => setState(() => targetPlatform = item),
                ),
            ]),
            const SizedBox(height: 8),
            _FieldRow(
                label: _zh ? '个性化目标' : 'Personalization goal',
                value: _personalizationGoalLabel(personalizationGoal)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final item in const [
                '',
                'domain_localization',
                'style_personalization',
                'platform_adaptation',
                'task_customization',
                'enterprise_constraints',
                'agent_specific',
              ])
                ChoiceChip(
                  label: Text(_personalizationGoalLabel(item)),
                  selected: personalizationGoal == item,
                  onSelected: (_) => setState(() => personalizationGoal = item),
                ),
            ]),
            const SizedBox(height: 8),
            _FieldRow(
                label: _zh ? '样例任务验证' : 'Sample task validation',
                value: runtime.hasSkillVerificationReport
                    ? (_zh
                        ? _displayNameForPath(
                            runtime.skillVerificationReportPath)
                        : _displayNameForPath(
                            runtime.skillVerificationReportPath))
                    : (_zh ? '生成后执行本地样例校验' : 'Runs after local generation')),
            const SizedBox(height: 8),
            SizedBox(
              height: 144,
              child: TextField(
                key: const Key('skill-draft-editor'),
                controller: _skillEditorController,
                maxLines: null,
                expands: true,
                enabled: rc6 != null,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: runtime.hasSkill
                      ? (_zh
                          ? '加载 SKILL.md 后可编辑草稿。'
                          : 'Load SKILL.md, then edit the draft.')
                      : (_zh
                          ? '请先生成 Skill 草稿。'
                          : 'Generate a Skill draft first.'),
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 13,
                      height: 1.22,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            const SizedBox(height: 8),
            _EqualActionRow(children: [
              _PrimaryProductAction(
                label: _zh ? '生成 Skill' : 'Generate Skill',
                icon: Icons.extension_outlined,
                onPressed: runtime.running || rc6 == null
                    ? null
                    : () {
                        setState(() {
                          configReady = true;
                          outputPreviewReady = true;
                        });
                        rc6.generateSkill(config: _skillConfig);
                      },
              ),
              _DisplayAction(
                label: _zh ? '加载草稿' : 'Load draft',
                icon: Icons.article_outlined,
                onPressed: rc6 == null || skillDraftPath.isEmpty
                    ? null
                    : loadSkillDraft,
              ),
              _PrimaryProductAction(
                label: _zh ? '保存编辑' : 'Save edit',
                icon: Icons.save_outlined,
                onPressed: rc6 == null ||
                        runtime.running ||
                        !runtime.hasSkill ||
                        _skillEditorController.text.trim().isEmpty
                    ? null
                    : saveSkillDraft,
              ),
            ]),
            if (savedSkillEditPath.isNotEmpty) ...[
              const SizedBox(height: 8),
              _FieldRow(
                  label: _zh ? '编辑稿' : 'Edited draft',
                  value: _displayNameForPath(savedSkillEditPath)),
            ],
          ],
        );
        final externalManifestPath = runtime.skillGenerationManifestPath;
        final localizedSkillDraftPath = runtime.hasLocalizedSkillManifest
            ? '${runtime.workspacePath}/skill/localized_writing_skill/S2/SKILL.md'
            : '';
        final localization = _ProductPanel(
          keyName: 'skill-external-localization',
          icon: Icons.merge_type_outlined,
          title: _zh ? '外部 Skill 本地化' : 'External Skill Localization',
          subtitle: runtime.hasSkill
              ? _displayNameForPath(runtime.skillPath)
              : '${widget.workspace}/workbench_runs/skill/external_imported_skill',
          children: [
            _ProductTable(
              columns:
                  _zh ? ['对象', '业务含义', '状态'] : ['Object', 'Meaning', 'Status'],
              rows: _zh
                  ? [
                      [
                        'S0 外部 Skill',
                        '导入外部写作方法论',
                        runtime.hasSkillGenerationManifest ? '已导入' : '等待导入'
                      ],
                      [
                        'S2 本地化 Skill',
                        'S0 + 当前知识库融合',
                        runtime.hasLocalizedSkillManifest ? '已验证' : '等待知识库'
                      ],
                      [
                        '差异说明',
                        '记录本地化和 Agent 绑定变化',
                        runtime.hasLocalizedSkillDiff ? '已生成' : '等待生成'
                      ],
                    ]
                  : [
                      [
                        'S0 external Skill',
                        'Imported writing methodology',
                        runtime.hasSkillGenerationManifest
                            ? 'Imported'
                            : 'Waiting import'
                      ],
                      [
                        'S2 localized Skill',
                        'S0 + current KB fusion',
                        runtime.hasLocalizedSkillManifest
                            ? 'Validated'
                            : 'Waiting KB'
                      ],
                      [
                        'Diff summary',
                        'Localization and Agent-binding changes',
                        runtime.hasLocalizedSkillDiff ? 'Generated' : 'Waiting'
                      ],
                    ],
            ),
            const SizedBox(height: 8),
            _ProductTable(
              columns: _zh
                  ? ['能力项', '承接产物', '状态']
                  : ['Capability', 'Artifact', 'Status'],
              rows: _zh
                  ? [
                      [
                        '外部 Skill',
                        'S0 / SKILL.md',
                        runtime.hasSkillGenerationManifest ? '已导入' : '等待选择文件'
                      ],
                      [
                        '结构解析',
                        '外部 Skill 结构',
                        runtime.hasSkillGenerationManifest ? '可查看' : '等待导入'
                      ],
                      [
                        '本地知识库',
                        runtime.kbManifestPath.isNotEmpty
                            ? _displayNameForPath(runtime.kbManifestPath)
                            : '当前知识库',
                        runtime.hasKnowledgeBase ? '已绑定' : '等待知识库'
                      ],
                      [
                        '个性化目标',
                        _personalizationGoalLabel(personalizationGoal),
                        personalizationGoal.isEmpty ? '可选' : '已选择'
                      ],
                      [
                        '本地化草稿',
                        '本地化 Skill 草稿',
                        runtime.hasLocalizedSkillManifest ? '已生成' : '等待融合'
                      ],
                      [
                        '改动差异',
                        '差异说明',
                        runtime.hasLocalizedSkillDiff ? '可查看' : '等待生成'
                      ],
                      [
                        '验证导出绑定',
                        '验证 / 导出 / 绑定',
                        runtime.hasSkillAgentBindingManifest
                            ? '已生成绑定清单'
                            : runtime.hasSkillExport
                                ? '已导出，等待 Agent'
                                : '等待验证导出'
                      ],
                    ]
                  : [
                      [
                        'External Skill',
                        'S0 / SKILL.md',
                        runtime.hasSkillGenerationManifest
                            ? 'Imported'
                            : 'Choose file'
                      ],
                      [
                        'Structure parsing',
                        'External Skill structure',
                        runtime.hasSkillGenerationManifest
                            ? 'Viewable'
                            : 'Waiting import'
                      ],
                      [
                        'Local KB',
                        runtime.kbManifestPath.isNotEmpty
                            ? _displayNameForPath(runtime.kbManifestPath)
                            : 'Current KB',
                        runtime.hasKnowledgeBase ? 'Bound' : 'Waiting KB'
                      ],
                      [
                        'Personalization goal',
                        _personalizationGoalLabel(personalizationGoal),
                        personalizationGoal.isEmpty ? 'Optional' : 'Selected'
                      ],
                      [
                        'Localized draft',
                        'Localized Skill draft',
                        runtime.hasLocalizedSkillManifest
                            ? 'Generated'
                            : 'Waiting fusion'
                      ],
                      [
                        'Change diff',
                        'Diff summary',
                        runtime.hasLocalizedSkillDiff ? 'Viewable' : 'Waiting'
                      ],
                      [
                        'Validate export bind',
                        'Validation / export / binding',
                        runtime.hasSkillAgentBindingManifest
                            ? 'Binding manifest ready'
                            : runtime.hasSkillExport
                                ? 'Exported, waiting Agent'
                                : 'Waiting validation'
                      ],
                    ],
            ),
            const SizedBox(height: 8),
            _FieldRow(
                label: _zh ? '本地知识库' : 'Local Knowledge Base',
                value: runtime.kbManifestPath.isNotEmpty
                    ? _displayNameForPath(runtime.kbManifestPath)
                    : (_zh ? '请先构建知识库' : 'Build a Knowledge Base first')),
            const SizedBox(height: 8),
            _FieldRow(
                label: _zh ? '个性化目标' : 'Personalization goal',
                value: _personalizationGoalLabel(personalizationGoal)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final item in const [
                'domain_localization',
                'style_personalization',
                'platform_adaptation',
                'task_customization',
                'enterprise_constraints',
                'agent_specific',
              ])
                ChoiceChip(
                  label: Text(_personalizationGoalLabel(item)),
                  selected: personalizationGoal == item,
                  onSelected: (_) => setState(() => personalizationGoal = item),
                ),
            ]),
            const SizedBox(height: _DesktopGrid.gutter),
            _EqualActionRow(children: [
              _PrimaryProductAction(
                label: _zh ? '导入并本地化 Skill' : 'Import and localize Skill',
                icon: Icons.merge_type_outlined,
                onPressed: runtime.running || rc6 == null
                    ? null
                    : () {
                        setState(() {
                          configReady = true;
                          outputPreviewReady = true;
                          validationReady = true;
                        });
                        rc6.pickAndImportExternalSkill();
                      },
              ),
              _DisplayAction(
                label: runtime.hasSkillGenerationManifest
                    ? (_zh ? '查看外部 Skill 结构' : 'View external Skill structure')
                    : (_zh ? '等待导入外部 Skill' : 'Waiting external Skill'),
                icon: Icons.account_tree_outlined,
                onPressed: runtime.hasSkillGenerationManifest
                    ? () => _showWorkspaceArtifactPreview(
                          context,
                          rc6: rc6,
                          title:
                              _zh ? '外部 Skill 结构' : 'External Skill structure',
                          path: externalManifestPath,
                          unavailableMessage: _zh
                              ? '尚未生成外部 Skill 结构清单。'
                              : 'No external Skill manifest has been generated.',
                          closeLabel: _zh ? '关闭' : 'Close',
                        )
                    : null,
              ),
              _DisplayAction(
                label: runtime.hasLocalizedSkillManifest
                    ? (_zh ? '查看本地化 Skill 草稿' : 'View localized Skill draft')
                    : (_zh ? '等待本地化草稿' : 'Waiting localized draft'),
                icon: Icons.article_outlined,
                onPressed: runtime.hasLocalizedSkillManifest
                    ? () => _showWorkspaceArtifactPreview(
                          context,
                          rc6: rc6,
                          title: _zh ? '本地化 Skill 草稿' : 'Localized Skill draft',
                          path: localizedSkillDraftPath,
                          unavailableMessage: _zh
                              ? '尚未生成本地化 Skill 草稿。'
                              : 'No localized Skill draft has been generated.',
                          closeLabel: _zh ? '关闭' : 'Close',
                        )
                    : null,
              ),
              _DisplayAction(
                label: runtime.hasLocalizedSkillDiff
                    ? (_zh ? '查看改动差异' : 'View change diff')
                    : (_zh ? '等待差异说明' : 'Waiting diff summary'),
                icon: Icons.difference_outlined,
                onPressed: runtime.hasLocalizedSkillDiff
                    ? () => _showWorkspaceArtifactPreview(
                          context,
                          rc6: rc6,
                          title: _zh ? '本地化改动差异' : 'Localization diff',
                          path: runtime.localizedSkillDiffPath,
                          unavailableMessage: _zh
                              ? '尚未生成本地化差异说明。'
                              : 'No localization diff has been generated.',
                          closeLabel: _zh ? '关闭' : 'Close',
                        )
                    : null,
              ),
            ]),
          ],
        );
        final output = _ProductPanel(
          keyName: 'skill-output-preview',
          icon: Icons.folder_zip_outlined,
          title: _zh ? 'Skill 版本操作' : 'Skill Version Operations',
          subtitle: runtime.hasSkill
              ? _displayNameForPath(runtime.skillPath)
              : '${widget.workspace}/workbench_runs/skill',
          children: [
            _FileTreePreview(
              zh: _zh,
              rows: _zh
                  ? [
                      ['Skill 草稿', runtime.hasPrimarySkill ? '已生成' : '-'],
                      ['Skill 配置', runtime.hasSkillConfig ? '已生成' : '-'],
                      [
                        '验证报告',
                        runtime.hasSkillVerificationReport ? '已生成' : '-'
                      ],
                      [
                        '外部 Skill',
                        runtime.hasSkillGenerationManifest ? '已导入' : '-'
                      ],
                      [
                        '本地化 Skill',
                        runtime.hasLocalizedSkillManifest ? '已生成' : '-'
                      ],
                      ['操作历史', runtime.hasSkillOperationManifest ? '已生成' : '-'],
                      ['导出包', runtime.hasSkillExport ? '已导出' : '-'],
                      ['编辑稿', savedSkillEditPath.isNotEmpty ? '已保存' : '-'],
                    ]
                  : [
                      [
                        'Skill draft',
                        runtime.hasPrimarySkill ? 'written' : '-'
                      ],
                      [
                        'Skill config',
                        runtime.hasSkillConfig ? 'written' : '-'
                      ],
                      [
                        'Validation report',
                        runtime.hasSkillVerificationReport ? 'written' : '-'
                      ],
                      [
                        'External Skill',
                        runtime.hasSkillGenerationManifest ? 'imported' : '-'
                      ],
                      [
                        'Localized Skill',
                        runtime.hasLocalizedSkillManifest ? 'written' : '-'
                      ],
                      [
                        'Operation history',
                        runtime.hasSkillOperationManifest ? 'written' : '-'
                      ],
                      [
                        'Export package',
                        runtime.hasSkillExport ? 'exported' : '-'
                      ],
                      [
                        'Edited draft',
                        savedSkillEditPath.isNotEmpty ? 'saved' : '-'
                      ],
                    ],
            ),
            const SizedBox(height: _DesktopGrid.gutter),
            _ProductTable(
              columns: _zh
                  ? ['操作', '真实产物', '状态']
                  : ['Operation', 'Artifact', 'Status'],
              rows: _zh
                  ? [
                      [
                        '查看',
                        'Skill 草稿',
                        runtime.hasPrimarySkill ? '可查看' : '等待生成'
                      ],
                      ['复制', 'Skill 副本', runtime.hasSkill ? '已生成副本' : '等待生成'],
                      ['融合', '融合 Skill', runtime.hasSkill ? '已融合' : '等待生成'],
                      [
                        '导出',
                        'Skill 导出包',
                        runtime.hasSkillExport ? '可打开' : '等待生成'
                      ],
                      [
                        '绑定 Agent',
                        'Agent 绑定',
                        runtime.hasSkillAgentBindingManifest
                            ? (skillBindingStatus == 'bound'
                                ? '已绑定'
                                : '等待 Agent')
                            : '创建 Agent 后绑定'
                      ],
                    ]
                  : [
                      [
                        'View',
                        'Skill draft',
                        runtime.hasPrimarySkill ? 'Openable' : 'Waiting'
                      ],
                      [
                        'Copy',
                        'Skill copy',
                        runtime.hasSkill ? 'Copied' : 'Waiting'
                      ],
                      [
                        'Fuse',
                        'Fused Skill',
                        runtime.hasSkill ? 'Fused' : 'Waiting'
                      ],
                      [
                        'Export',
                        'Skill export package',
                        runtime.hasSkillExport ? 'Openable' : 'Waiting'
                      ],
                      [
                        'Bind Agent',
                        'Agent binding',
                        runtime.hasSkillAgentBindingManifest
                            ? (skillBindingStatus == 'bound'
                                ? 'Bound'
                                : 'Waiting Agent')
                            : 'After Agent creation'
                      ],
                    ],
            ),
            const SizedBox(height: _DesktopGrid.gutter),
            _PrimaryProductAction(
              label: _zh ? '生成 Skill' : 'Generate Skill',
              icon: Icons.folder_zip_outlined,
              onPressed: runtime.running || rc6 == null
                  ? null
                  : () {
                      setState(() {
                        configReady = true;
                        outputPreviewReady = true;
                      });
                      rc6.generateSkill(config: _skillConfig);
                    },
            ),
          ],
        );
        final validation = _ProductPanel(
          keyName: 'skill-validation-summary',
          icon: Icons.rule_outlined,
          title: _zh ? '验证与导出' : 'Validation and Export',
          children: [
            _MetricStrip(
              items: [
                _MetricDatum(
                    label: _zh ? '覆盖率' : 'Coverage',
                    value: runtime.hasSkillGenerationManifest ? 'real' : '-',
                    detail: _zh ? '本地产物' : 'local artifact',
                    icon: Icons.pie_chart_outline),
                _MetricDatum(
                    label: _zh ? '可安装性' : 'Installability',
                    value: runtime.hasSkillExport ? 'ready' : '-',
                    detail: _zh ? '已写出' : 'written',
                    icon: Icons.verified_outlined),
              ],
            ),
            const SizedBox(height: 8),
            _FieldRow(
                label: _zh ? '验证结果' : 'Validation result',
                value: validationReady
                    ? (runtime.hasSkillVerificationReport
                        ? _displayNameForPath(
                            runtime.skillVerificationReportPath)
                        : '等待真实 Skill 产物')
                    : (_zh ? '等待报告' : 'Waiting for report')),
            const SizedBox(height: 8),
            _FieldRow(
                label: _zh ? '操作清单' : 'Operation manifest',
                value: runtime.hasSkillOperationManifest
                    ? '${skillOperationStatus.isEmpty ? 'pass' : skillOperationStatus} · ${_displayNameForPath(runtime.skillOperationManifestPath)}'
                    : (_zh ? '等待生成操作产物' : 'Waiting operation artifact')),
            const SizedBox(height: 8),
            _FieldRow(
                label: _zh ? '包清单' : 'Package manifest',
                value: runtime.hasSkillPackageManifest
                    ? _displayNameForPath(runtime.skillPackageManifestPath)
                    : (_zh ? '等待 Skill 包清单' : 'Waiting Skill package')),
            const SizedBox(height: 8),
            _FieldRow(
                label: _zh ? '工厂验证' : 'Factory validation',
                value: runtime.hasSkillValidationReport
                    ? _displayNameForPath(runtime.skillValidationReportPath)
                    : (_zh ? '等待工厂验证报告' : 'Waiting factory validation')),
            const SizedBox(height: 8),
            _FieldRow(
                label: _zh ? '草稿编辑' : 'Draft edit',
                value: savedSkillEditPath.isNotEmpty
                    ? _displayNameForPath(savedSkillEditPath)
                    : (_zh ? '等待保存编辑稿' : 'Waiting edited draft')),
            const SizedBox(height: 8),
            _FieldRow(
                label: _zh ? '版本记录' : 'Version history',
                value: runtime.hasSkillVersions
                    ? (_zh
                        ? '${runtime.skillVersionCount} 个版本'
                        : '${runtime.skillVersionCount} versions')
                    : (_zh ? '等待生成 Skill' : 'Waiting Skill generation')),
            const SizedBox(height: 8),
            _FieldRow(
                label: _zh ? '工厂审计' : 'Factory audit',
                value: runtime.skillFactoryAuditPath.isNotEmpty
                    ? _displayNameForPath(runtime.skillFactoryAuditPath)
                    : (_zh ? '等待 Skill 操作' : 'Waiting Skill operation')),
            const SizedBox(height: 8),
            _FieldRow(
                label: _zh ? '导出包' : 'Export package',
                value: validationReady
                    ? (runtime.hasSkillExport
                        ? _displayNameForPath(runtime.skillExportPath)
                        : (_zh
                            ? '等待真实 Skill 产物'
                            : 'Waiting for real Skill artifact'))
                    : (_zh ? '等待报告' : 'Waiting for report')),
            const SizedBox(height: 8),
            _FieldRow(
                label: _zh ? 'Agent 绑定' : 'Agent binding',
                value: runtime.hasSkillAgentBindingManifest
                    ? '${skillBindingStatus == 'bound' ? (_zh ? '已绑定' : 'bound') : (_zh ? '等待 Agent' : 'waiting Agent')} · ${_displayNameForPath(runtime.skillAgentBindingManifestPath)}'
                    : (_zh
                        ? '创建 Agent 后生成绑定清单'
                        : 'Generated after Agent creation')),
            const SizedBox(height: 8),
            _FieldRow(
                label: _zh ? '下一阶段' : 'Next stage',
                value: _zh
                    ? 'Agent 创建 / 绑定 / 导出'
                    : 'Agent creation / binding / export'),
            const SizedBox(height: 8),
            _EqualActionRow(children: [
              _PrimaryProductAction(
                label: _zh ? '校验 Skill' : 'Validate Skill',
                onPressed: runtime.running || rc6 == null
                    ? null
                    : () {
                        setState(() {
                          configReady = true;
                          outputPreviewReady = true;
                          validationReady = true;
                        });
                        rc6.runSkillOperation('validate');
                      },
                icon: Icons.verified_outlined,
              ),
              _PrimaryProductAction(
                label: _zh ? '导出 Skill' : 'Export Skill',
                icon: Icons.file_download_outlined,
                onPressed: runtime.running || rc6 == null
                    ? null
                    : () {
                        setState(() {
                          outputPreviewReady = true;
                          validationReady = true;
                        });
                        rc6.runSkillOperation('export');
                      },
              ),
              _MoreActionsButton(
                label: _zh ? '更多 Skill 操作' : 'More Skill actions',
                actions: [
                  _MoreMenuAction(
                    label: _zh ? '复制 Skill' : 'Copy Skill',
                    icon: Icons.content_copy_outlined,
                    enabled: !runtime.running && rc6 != null,
                    onSelected: () {
                      setState(() {
                        outputPreviewReady = true;
                        validationReady = true;
                      });
                      rc6?.runSkillOperation('copy');
                    },
                  ),
                  _MoreMenuAction(
                    label: _zh ? '融合 Skill' : 'Fuse Skill',
                    icon: Icons.merge_type_outlined,
                    enabled: !runtime.running && rc6 != null,
                    onSelected: () {
                      setState(() {
                        outputPreviewReady = true;
                        validationReady = true;
                      });
                      rc6?.runSkillOperation('fusion');
                    },
                  ),
                  _MoreMenuAction(
                    label: _zh ? '绑定 Agent' : 'Bind Agent',
                    icon: Icons.link_outlined,
                    enabled: !runtime.running && rc6 != null,
                    onSelected: () {
                      setState(() {
                        outputPreviewReady = true;
                        validationReady = true;
                      });
                      rc6?.runSkillOperation('bind_agent');
                    },
                  ),
                  _MoreMenuAction(
                    label: _zh ? '查看 Skill 内容' : 'View Skill content',
                    icon: Icons.article_outlined,
                    enabled: skillDraftPath.isNotEmpty,
                    onSelected: () => _showWorkspaceArtifactPreview(
                      context,
                      rc6: rc6,
                      title: _zh ? 'Skill 内容预览' : 'Skill content preview',
                      path: skillDraftPath,
                      unavailableMessage: _zh
                          ? '尚未生成可预览 Skill。'
                          : 'No previewable Skill has been generated.',
                      closeLabel: _zh ? '关闭' : 'Close',
                    ),
                  ),
                  _MoreMenuAction(
                    label: _zh ? '删除 Skill 产物' : 'Delete Skill artifacts',
                    icon: Icons.delete_outline,
                    destructive: true,
                    enabled: runtime.hasSkill,
                    onSelected: () => _confirmAndDeleteSkill(rc6),
                  ),
                ],
              ),
            ]),
          ],
        );
        if (!wide) {
          return Column(children: [
            config,
            const SizedBox(height: _DesktopGrid.gutter),
            output,
            const SizedBox(height: _DesktopGrid.gutter),
            validation
          ]);
        }
        return switch (selectedTab) {
          1 => localization,
          2 => output,
          3 => validation,
          _ => config,
        };
      }),
    ]);
  }
}
