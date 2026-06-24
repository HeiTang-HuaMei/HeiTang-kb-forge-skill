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
      TextEditingController(text: '真实输入知识问答技能');
  final TextEditingController _skillEditorController = TextEditingController();
  final TextEditingController _externalSkillPathController =
      TextEditingController();
  String savedSkillEditPath = '';

  bool get _zh => widget.localeCode == 'zh-CN';

  @override
  void dispose() {
    _skillNameController.dispose();
    _skillEditorController.dispose();
    _externalSkillPathController.dispose();
    super.dispose();
  }

  Rc6SkillGenerationConfig get _skillConfig => Rc6SkillGenerationConfig(
        customSkillName: _skillNameController.text,
        skillType: skillType,
        targetPlatform: targetPlatform,
        personalizationGoal: personalizationGoal,
      );

  String _skillTypeLabel(String value) => switch (value) {
        'writing' => _zh ? '写作技能' : 'Writing',
        'teaching' => _zh ? '教学技能' : 'Teaching',
        'product' => _zh ? '产品技能' : 'Product',
        'ops' => _zh ? '运营技能' : 'Operations',
        'legal' => _zh ? '法规技能' : 'Legal',
        'custom' => _zh ? '自定义技能' : 'Custom',
        _ => _zh ? '分析技能' : 'Analysis',
      };

  String _targetPlatformLabel(String value) => switch (value) {
        'claude_code' => 'Claude Code',
        'openclaw' => 'OpenClaw',
        'markdown' => 'Markdown',
        'internal_agent' => _zh ? '内置助手' : 'Internal Agent',
        _ => 'Codex',
      };

  String _personalizationGoalLabel(String value) => switch (value) {
        'domain_localization' => _zh ? '领域本地化' : 'Domain localization',
        'style_personalization' => _zh ? '用户风格化' : 'Style personalization',
        'platform_adaptation' => _zh ? '平台适配' : 'Platform adaptation',
        'task_customization' => _zh ? '任务定制' : 'Task customization',
        'enterprise_constraints' => _zh ? '企业知识约束' : 'Enterprise constraints',
        'agent_specific' => _zh ? '助手专属化' : 'Agent-specific',
        _ => _zh ? '未选择' : 'Not selected',
      };

  Future<void> _confirmAndDeleteSkill(Rc6RuntimeController? rc6) async {
    if (rc6 == null || rc6.state.running || !rc6.state.hasSkill) return;
    final confirmed = await _confirmDestructiveAction(
      context,
      title: _zh ? '删除技能产物？' : 'Delete Skill artifacts?',
      body: _zh
          ? '这会删除当前工作区里的技能，并清理依赖该技能的对话和联合讨论输出；助手配置、知识库和文档不会被删除。'
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
        ? ['从知识库生成', '导入模板技能', '版本操作', '检查导出']
        : [
            'Generate from KB',
            'Import Template Skill',
            'Version Operations',
            'Validate & Export'
          ];
    return _FigmaPageCanvas(children: [
      _FigmaFixedRow(
        height: 150,
        widths: const [540, 542],
        children: [
          _FigmaHighlightCard(
            keyName: 'skill-generate-from-kb-card',
            icon: Icons.extension_outlined,
            title: _zh ? '从知识库生成 Skill' : 'Generate Skill from KB',
            description: _zh
                ? '选择当前知识库，生成可检查、可导出的技能草稿。'
                : 'Use the current knowledge base to create a validated, exportable Skill draft.',
            actions: [
              SizedBox(
                width: 136,
                child: _PrimaryProductAction(
                  label: _zh ? '生成技能' : 'Generate Skill',
                  icon: Icons.extension_outlined,
                  onPressed: runtime.running || rc6 == null
                      ? null
                      : () {
                          setState(() {
                            selectedTab = 0;
                            configReady = true;
                            outputPreviewReady = true;
                          });
                          rc6.generateSkill(config: _skillConfig);
                        },
                ),
              ),
            ],
          ),
          _FigmaHighlightCard(
            keyName: 'skill-import-template-card',
            icon: Icons.merge_type_outlined,
            title: _zh ? '导入外部 Skill 并专属化' : 'Import and localize a Skill',
            description: _zh
                ? '外部 Skill 只作为模板技能导入，再结合当前知识库本土化。'
                : 'External Skills are imported as templates, then localized with the current knowledge base.',
            actions: [
              SizedBox(
                width: 136,
                child: _DisplayAction(
                  label: _zh ? '导入模板' : 'Import template',
                  icon: Icons.upload_file_outlined,
                  onPressed: runtime.running || rc6 == null
                      ? null
                      : () {
                          setState(() => selectedTab = 1);
                          rc6.pickAndImportExternalSkill();
                        },
                ),
              ),
            ],
          ),
        ],
      ),
      _PageTabs(
        tabs: tabs,
        selectedIndex: selectedTab,
        onSelected: (index) => setState(() => selectedTab = index),
      ),
      if (configReady || outputPreviewReady || validationReady) ...[
        _RuntimeFeedbackBanner(
          title: validationReady
              ? (_zh ? '技能草稿已生成' : 'Skill draft generated')
              : outputPreviewReady
                  ? (_zh ? '技能包结构已刷新' : 'Skill package structure refreshed')
                  : (_zh ? '技能配置已准备' : 'Skill config prepared'),
          detail: runtime.hasSkill
              ? runtime.skillPath
              : (_zh
                  ? '请先生成知识库，再生成真实技能包。'
                  : 'Build a KB first, then generate a real Skill package.'),
          tone: runtime.hasSkill ? _StatusTone.success : _StatusTone.warning,
          icon: Icons.extension_outlined,
        ),
        const SizedBox(height: _DesktopGrid.gutter),
      ],
      SizedBox(
        height: 500,
        child: LayoutBuilder(builder: (context, constraints) {
          final wide = constraints.maxWidth >= 920;
          final config = _ProductPanel(
            keyName: 'skill-metadata-source-config',
            icon: Icons.edit_note_outlined,
            title: _zh ? '从知识库生成技能' : 'Generate Skill from KB',
            children: [
              _ProductTable(
                columns:
                    _zh ? ['生成模式', '来源', '状态'] : ['Mode', 'Source', 'Status'],
                rows: _zh
                    ? [
                        [
                          '从知识库生成技能',
                          '当前知识库',
                          runtime.hasSkill
                              ? '已生成'
                              : runtime.hasKnowledgeBase
                                  ? '可生成'
                                  : '请先构建知识库'
                        ],
                        [
                          '导入模板技能',
                          'S0 + 当前知识库',
                          runtime.hasSkill
                              ? '已生成 S2'
                              : runtime.hasKnowledgeBase
                                  ? '可生成'
                                  : '请先构建知识库'
                        ],
                        [
                          '多知识库技能',
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
                          'Import template skill',
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
                  labelText: _zh ? '技能名称' : 'Skill name',
                  helperText: _zh
                      ? '写入技能草稿、配置、检查和导出清单。'
                      : 'Written to SKILL.md, config, validation, and export manifests.',
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 8),
              _FieldRow(
                  label: _zh ? '技能类型' : 'Skill type',
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
              TextField(
                key: const Key('external-skill-path-input'),
                controller: _externalSkillPathController,
                enabled: rc6 != null && !runtime.running,
                decoration: InputDecoration(
                  labelText: _zh ? '外部 Skill 路径' : 'External Skill path',
                  hintText: _zh
                      ? r'粘贴 SKILL.md 或 Skill 文件夹路径'
                      : r'Paste a SKILL.md file or Skill folder path',
                  helperText: _zh
                      ? '用于自动化真实导入；不会修改原始 Skill 文件。'
                      : 'Used for automated real import; original Skill files are not modified.',
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
              ),
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
                    onSelected: (_) =>
                        setState(() => personalizationGoal = item),
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
                            ? '加载技能草稿后可编辑。'
                            : 'Load SKILL.md, then edit the draft.')
                        : (_zh ? '请先生成技能草稿。' : 'Generate a Skill draft first.'),
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
                  label: _zh ? '生成技能' : 'Generate Skill',
                  icon: Icons.extension_outlined,
                  automationKey: 'workbench.skill.generate_button',
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
            title: _zh ? '导入模板技能' : 'Import Template Skill',
            subtitle: runtime.hasSkill
                ? _displayNameForPath(runtime.skillPath)
                : '${widget.workspace}/workbench_runs/skill/external_imported_skill',
            children: [
              _ProductTable(
                columns: _zh
                    ? ['对象', '业务含义', '状态']
                    : ['Object', 'Meaning', 'Status'],
                rows: _zh
                    ? [
                        [
                          '模板技能',
                          '导入外部写作方法论模板',
                          runtime.hasSkillGenerationManifest ? '已导入' : '等待导入'
                        ],
                        [
                          '本地化技能',
                          '模板 + 当前知识库融合',
                          runtime.hasLocalizedSkillManifest ? '已验证' : '等待知识库'
                        ],
                        [
                          '差异说明',
                          '记录本地化和助手绑定变化',
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
                          runtime.hasLocalizedSkillDiff
                              ? 'Generated'
                              : 'Waiting'
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
                          '模板技能',
                          '模板技能草稿',
                          runtime.hasSkillGenerationManifest ? '已导入' : '等待选择文件'
                        ],
                        [
                          '结构解析',
                          '模板技能结构',
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
                          '本地化技能草稿',
                          runtime.hasLocalizedSkillManifest ? '已生成' : '等待融合'
                        ],
                        [
                          '改动差异',
                          '差异说明',
                          runtime.hasLocalizedSkillDiff ? '可查看' : '等待生成'
                        ],
                        [
                          '检查导出绑定',
                          '检查 / 导出 / 绑定',
                          runtime.hasSkillAgentBindingManifest
                              ? '已生成绑定清单'
                              : runtime.hasSkillExport
                                  ? '已导出，等待助手'
                                  : '等待验证导出'
                        ],
                      ]
                    : [
                        [
                          'Template skill',
                          '模板技能草稿',
                          runtime.hasSkillGenerationManifest
                              ? 'Imported'
                              : 'Choose file'
                        ],
                        [
                          'Structure parsing',
                          'Template skill structure',
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
                    onSelected: (_) =>
                        setState(() => personalizationGoal = item),
                  ),
              ]),
              const SizedBox(height: _DesktopGrid.gutter),
              _EqualActionRow(children: [
                _PrimaryProductAction(
                  label: _zh ? '导入路径 Skill' : 'Import Skill path',
                  icon: Icons.merge_type_outlined,
                  automationKey: 'workbench.skill.import_path_button',
                  onPressed: runtime.running ||
                          rc6 == null ||
                          _externalSkillPathController.text.trim().isEmpty
                      ? null
                      : () {
                          setState(() {
                            configReady = true;
                            outputPreviewReady = true;
                            validationReady = true;
                          });
                          rc6.importExternalSkillPath(
                            _externalSkillPathController.text.trim(),
                          );
                        },
                ),
                _DisplayAction(
                  label: _zh ? '选择文件导入' : 'Choose file import',
                  icon: Icons.upload_file_outlined,
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
                      ? (_zh ? '查看模板技能结构' : 'View template skill structure')
                      : (_zh ? '等待导入模板技能' : 'Waiting template skill'),
                  icon: Icons.account_tree_outlined,
                  onPressed: runtime.hasSkillGenerationManifest
                      ? () => _showWorkspaceArtifactPreview(
                            context,
                            rc6: rc6,
                            title: _zh ? '模板技能结构' : 'Template skill structure',
                            path: externalManifestPath,
                            unavailableMessage: _zh
                                ? '尚未生成模板技能 结构清单。'
                                : 'No template skill structure has been generated.',
                            closeLabel: _zh ? '关闭' : 'Close',
                          )
                      : null,
                ),
                _DisplayAction(
                  label: runtime.hasLocalizedSkillManifest
                      ? (_zh ? '查看本地化技能草稿' : 'View localized skill draft')
                      : (_zh ? '等待本地化草稿' : 'Waiting localized draft'),
                  icon: Icons.article_outlined,
                  onPressed: runtime.hasLocalizedSkillManifest
                      ? () => _showWorkspaceArtifactPreview(
                            context,
                            rc6: rc6,
                            title: _zh ? '本地化技能草稿' : 'Localized skill draft',
                            path: localizedSkillDraftPath,
                            unavailableMessage: _zh
                                ? '尚未生成本地化技能草稿。'
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
            title: _zh ? '技能版本操作' : 'Skill Version Operations',
            subtitle: runtime.hasSkill
                ? _displayNameForPath(runtime.skillPath)
                : '${widget.workspace}/workbench_runs/skill',
            children: [
              _FileTreePreview(
                zh: _zh,
                rows: _zh
                    ? [
                        ['技能草稿', runtime.hasPrimarySkill ? '已生成' : '-'],
                        ['技能配置', runtime.hasSkillConfig ? '已生成' : '-'],
                        [
                          '验证报告',
                          runtime.hasSkillVerificationReport ? '已生成' : '-'
                        ],
                        [
                          '模板技能',
                          runtime.hasSkillGenerationManifest ? '已导入' : '-'
                        ],
                        [
                          '本地化 Skill',
                          runtime.hasLocalizedSkillManifest ? '已生成' : '-'
                        ],
                        [
                          '操作历史',
                          runtime.hasSkillOperationManifest ? '已生成' : '-'
                        ],
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
                          'Template skill',
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
                          '技能草稿',
                          runtime.hasPrimarySkill ? '可查看' : '等待生成'
                        ],
                        ['复制', '技能副本', runtime.hasSkill ? '已生成副本' : '等待生成'],
                        ['融合', '融合技能', runtime.hasSkill ? '已融合' : '等待生成'],
                        [
                          '导出',
                          '技能导出包',
                          runtime.hasSkillExport ? '可打开' : '等待生成'
                        ],
                        [
                          '绑定助手',
                          '助手绑定',
                          runtime.hasSkillAgentBindingManifest
                              ? (skillBindingStatus == 'bound' ? '已绑定' : '等待助手')
                              : '创建助手后绑定'
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
                label: _zh ? '生成技能' : 'Generate Skill',
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
                  value: runtime.hasSkillVerificationReport
                      ? _displayNameForPath(runtime.skillVerificationReportPath)
                      : validationReady
                          ? (_zh
                              ? '等待真实技能产物'
                              : 'Waiting for real Skill artifact')
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
                      : (_zh ? '等待技能包清单' : 'Waiting Skill package')),
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
                      : (_zh ? '等待生成技能' : 'Waiting Skill generation')),
              const SizedBox(height: 8),
              _FieldRow(
                  label: _zh ? '工厂审计' : 'Factory audit',
                  value: runtime.skillFactoryAuditPath.isNotEmpty
                      ? _displayNameForPath(runtime.skillFactoryAuditPath)
                      : (_zh ? '等待技能操作' : 'Waiting Skill operation')),
              const SizedBox(height: 8),
              _FieldRow(
                  label: _zh ? '导出包' : 'Export package',
                  value: runtime.hasSkillExport
                      ? _displayNameForPath(runtime.skillExportPath)
                      : validationReady
                          ? (_zh
                              ? '等待真实技能产物'
                              : 'Waiting for real Skill artifact')
                          : (_zh ? '等待报告' : 'Waiting for report')),
              const SizedBox(height: 8),
              _FieldRow(
                  label: _zh ? '助手绑定' : 'Agent binding',
                  value: runtime.hasSkillAgentBindingManifest
                      ? '${skillBindingStatus == 'bound' ? (_zh ? '已绑定' : 'bound') : (_zh ? '等待助手' : 'waiting Agent')} · ${_displayNameForPath(runtime.skillAgentBindingManifestPath)}'
                      : (_zh
                          ? '创建助手后生成绑定清单'
                          : 'Generated after Agent creation')),
              const SizedBox(height: 8),
              _FieldRow(
                  label: _zh ? '下一阶段' : 'Next stage',
                  value: _zh
                      ? '助手创建 / 绑定 / 导出'
                      : 'Agent creation / binding / export'),
              const SizedBox(height: 8),
              _EqualActionRow(children: [
                _PrimaryProductAction(
                  label: _zh ? '检查技能' : 'Validate Skill',
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
                  label: _zh ? '导出技能' : 'Export Skill',
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
                  label: _zh ? '更多技能操作' : 'More Skill actions',
                  actions: [
                    _MoreMenuAction(
                      label: _zh ? '复制技能' : 'Copy Skill',
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
                      label: _zh ? '融合技能' : 'Fuse Skill',
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
                      label: _zh ? '绑定助手' : 'Bind Agent',
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
                      label: _zh ? '查看技能内容' : 'View Skill content',
                      icon: Icons.article_outlined,
                      enabled: skillDraftPath.isNotEmpty,
                      onSelected: () => _showWorkspaceArtifactPreview(
                        context,
                        rc6: rc6,
                        title: _zh ? '技能内容预览' : 'Skill content preview',
                        path: skillDraftPath,
                        unavailableMessage: _zh
                            ? '尚未生成可预览技能。'
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
      ),
    ]);
  }
}
