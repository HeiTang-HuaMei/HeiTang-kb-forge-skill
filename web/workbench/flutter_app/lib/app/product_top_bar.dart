part of '../main.dart';

class _ProductTopBar extends StatelessWidget {
  const _ProductTopBar({
    required this.localeCode,
    required this.page,
    required this.contracts,
    required this.showTitleBlock,
    required this.isDark,
    required this.windowState,
    required this.onWindowStateChanged,
    required this.onThemeChanged,
    required this.onLocaleChanged,
    required this.onPageChanged,
  });

  final String localeCode;
  final WorkbenchPage page;
  final WorkbenchContracts contracts;
  final bool showTitleBlock;
  final bool? isDark;
  final _DesktopWindowPreviewState windowState;
  final ValueChanged<_DesktopWindowPreviewState> onWindowStateChanged;
  final ValueChanged<ThemeMode>? onThemeChanged;
  final ValueChanged<String>? onLocaleChanged;
  final ValueChanged<int> onPageChanged;

  bool get _zh => localeCode == 'zh-CN';

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 900;
        final showTitle = showTitleBlock && constraints.maxWidth >= 1180;
        final showUtilityChips = constraints.maxWidth >= 1240;
        final showWorkspaceChip = constraints.maxWidth >= 1320;
        final showLanguageToggle = constraints.maxWidth >= 680;
        return Row(
          key: const Key('desktop-topbar-single-row'),
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (showTitle) ...[
              SizedBox(
                width: compact ? 220 : 312,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(page.title(localeCode, contracts),
                        style:
                            Theme.of(context).textTheme.headlineLarge?.copyWith(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0,
                                  height: 1.05,
                                )),
                    const SizedBox(height: 3),
                    Text(page.description(localeCode),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontSize: 14,
                              color: colors.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                              height: 1.16,
                            )),
                  ],
                ),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: _TopBarSearchField(
                label: _zh
                    ? '搜索文档、知识库、Skill、Agent'
                    : 'Search docs, KBs, Skills, Agents',
                compact: constraints.maxWidth < 900,
                onPageChanged: onPageChanged,
              ),
            ),
            if (showUtilityChips) ...[
              const SizedBox(width: 6),
              _TopBarChip(
                icon: Icons.receipt_long_outlined,
                label: _zh ? '本地日志' : 'Local logs',
              ),
              const SizedBox(width: 6),
              _TopBarChip(
                icon: Icons.notifications_none_outlined,
                label: _zh ? '通知' : 'Notifications',
              ),
            ],
            const SizedBox(width: 6),
            _TopBarIconButton(
              icon: Icons.refresh_outlined,
              label: _zh ? '刷新' : 'Refresh',
              onPressed: () {},
            ),
            if (showWorkspaceChip) ...[
              const SizedBox(width: 6),
              _TopBarChip(
                icon: Icons.space_dashboard_outlined,
                label: _zh ? '桌面工作区' : 'Desktop workspace',
                compact: true,
              ),
            ],
            if (showLanguageToggle) const SizedBox(width: 6),
            if (showLanguageToggle && onLocaleChanged != null)
              _TopBarLanguageToggle(
                localeCode: localeCode,
                onLocaleChanged: onLocaleChanged!,
              ),
            if (!compact) const SizedBox(width: 6),
            if (!compact && isDark != null && onThemeChanged != null)
              _TopBarIconButton(
                icon: isDark!
                    ? Icons.light_mode_outlined
                    : Icons.dark_mode_outlined,
                label: isDark! ? (_zh ? '浅色' : 'Light') : (_zh ? '深色' : 'Dark'),
                onPressed: () =>
                    onThemeChanged!(isDark! ? ThemeMode.light : ThemeMode.dark),
              ),
          ],
        );
      },
    );
  }
}

class _TopBarSearchField extends StatefulWidget {
  const _TopBarSearchField({
    required this.label,
    required this.onPageChanged,
    this.compact = false,
  });

  final String label;
  final ValueChanged<int> onPageChanged;
  final bool compact;

  @override
  State<_TopBarSearchField> createState() => _TopBarSearchFieldState();
}

class _TopBarSearchFieldState extends State<_TopBarSearchField> {
  bool focused = false;
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final zh = Localizations.localeOf(context).languageCode == 'zh';
    final rc6 = _Rc6RuntimeScope.of(context);
    final runtime = rc6?.state;
    final suggestions = _topBarSearchSuggestions(runtime, zh);
    final borderColor = focused ? colors.primary : colors.outlineVariant;
    final statusText = switch (runtime?.searchStatus) {
      Rc6SearchStatus.loading => zh ? '搜索中' : 'Searching',
      Rc6SearchStatus.success => zh ? '真实结果' : 'Results',
      Rc6SearchStatus.empty => zh ? '无结果' : 'Empty',
      Rc6SearchStatus.error => zh ? '错误' : 'Error',
      _ => zh ? '定位' : 'Open',
    };
    return RawAutocomplete<_TopBarSearchSuggestion>(
      key: const Key('topbar-search-menu'),
      textEditingController: _controller,
      focusNode: _focusNode,
      displayStringForOption: (suggestion) => suggestion.title,
      optionsBuilder: (value) {
        final query = value.text.trim().toLowerCase();
        if (query.isEmpty) return suggestions.take(8);
        final filtered = suggestions
            .where((item) => item.matches(query))
            .take(8)
            .toList(growable: false);
        return filtered.isEmpty ? [_noMatchSearchSuggestion(zh)] : filtered;
      },
      onSelected: (suggestion) {
        if (!suggestion.isNoMatch) {
          _controller.text = suggestion.title;
        }
        widget.onPageChanged(_pageIndexById(suggestion.pageId));
        setState(() => focused = false);
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: widget.compact ? 340 : 560,
                maxHeight: 360,
              ),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 6),
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final item = options.elementAt(index);
                  return ListTile(
                    key: Key('topbar-search-option-${item.pageId}'),
                    dense: true,
                    leading: Icon(item.icon, size: 18),
                    title: Text(item.title, overflow: TextOverflow.ellipsis),
                    subtitle: Text('${item.category} · ${item.subtitle}',
                        overflow: TextOverflow.ellipsis),
                    onTap: () => onSelected(item),
                  );
                },
              ),
            ),
          ),
        );
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return Semantics(
          textField: true,
          label: widget.label,
          child: Container(
            key: const Key('topbar-search-field'),
            constraints: const BoxConstraints(minWidth: 120),
            height: 40,
            padding: const EdgeInsets.only(left: 12, right: 6),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor, width: focused ? 1.4 : 1),
            ),
            child: Row(
              children: [
                Icon(Icons.search,
                    size: 17,
                    color: focused ? colors.primary : colors.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    key: const Key('topbar-real-search-input'),
                    enabled: rc6 != null,
                    onTap: () => setState(() => focused = true),
                    onChanged: (_) => setState(() => focused = true),
                    onSubmitted: (value) {
                      final matched = _bestSearchSuggestion(
                          suggestions, value.trim().toLowerCase());
                      widget.onPageChanged(_pageIndexById(
                          matched?.pageId ?? 'retrieval-verification'));
                    },
                    decoration: InputDecoration(
                      hintText: widget.label,
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontSize: 13,
                          color: colors.onSurface,
                          fontWeight: FontWeight.w700,
                          height: 1.16,
                        ),
                  ),
                ),
                if (!widget.compact || focused) ...[
                  const SizedBox(width: 6),
                  TextButton(
                    key: const Key('topbar-real-search-submit'),
                    onPressed: runtime?.running == true
                        ? null
                        : () {
                            final matched = _bestSearchSuggestion(suggestions,
                                _controller.text.trim().toLowerCase());
                            widget.onPageChanged(_pageIndexById(
                                matched?.pageId ?? 'retrieval-verification'));
                          },
                    child: Text(statusText),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TopBarSearchSuggestion {
  const _TopBarSearchSuggestion({
    required this.title,
    required this.subtitle,
    required this.category,
    required this.pageId,
    required this.icon,
    this.keywords = const [],
    this.isNoMatch = false,
  });

  final String title;
  final String subtitle;
  final String category;
  final String pageId;
  final IconData icon;
  final List<String> keywords;
  final bool isNoMatch;

  bool matches(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return true;
    final haystack = [
      title,
      subtitle,
      category,
      ...keywords,
    ].join(' ').toLowerCase();
    return haystack.contains(normalized);
  }
}

_TopBarSearchSuggestion _noMatchSearchSuggestion(bool zh) {
  return _TopBarSearchSuggestion(
    title: zh ? '无匹配，前往查询控制台' : 'No match, open Query Console',
    subtitle: zh ? '用当前输入查询知识库内容' : 'Use this query against KB content',
    category: zh ? '查询控制台' : 'Query Console',
    pageId: 'retrieval-verification',
    icon: Icons.manage_search_outlined,
    isNoMatch: true,
  );
}

List<_TopBarSearchSuggestion> _topBarSearchSuggestions(
    Rc6RuntimeState? runtime, bool zh) {
  final suggestions = <_TopBarSearchSuggestion>[
    _TopBarSearchSuggestion(
      title: zh ? '文档库导入资料' : 'Import into Document Library',
      subtitle: zh ? '选择文件、解析、OCR、分块' : 'Choose files, parse, OCR, chunk',
      category: zh ? '文档库' : 'Document Library',
      pageId: 'document-library',
      icon: Icons.file_upload_outlined,
      keywords: const ['import', 'parse', 'ocr', 'chunk', '导入', '解析', '分块'],
    ),
    _TopBarSearchSuggestion(
      title: zh ? '文档库' : 'Document Library',
      subtitle: zh ? '查看已导入文件和预览' : 'View imported files and previews',
      category: zh ? '页面' : 'Page',
      pageId: 'document-library',
      icon: Icons.library_books_outlined,
      keywords: const ['document', 'source', 'preview', '文档', '来源', '预览'],
    ),
    _TopBarSearchSuggestion(
      title: zh ? '知识库' : 'Knowledge Base',
      subtitle: zh ? '构建本地知识库和向量索引' : 'Build local KB and vector index',
      category: zh ? '页面' : 'Page',
      pageId: 'knowledge-package-management',
      icon: Icons.storage_outlined,
      keywords: const ['kb', 'knowledge', 'vector', 'manifest', '知识库', '向量'],
    ),
    _TopBarSearchSuggestion(
      title: zh ? '查询控制台' : 'Query Console',
      subtitle: zh ? '检索知识库内容和证据片段' : 'Search KB content and evidence',
      category: zh ? '页面' : 'Page',
      pageId: 'retrieval-verification',
      icon: Icons.manage_search_outlined,
      keywords: const ['search', 'query', 'retrieval', 'evidence', '检索', '查询'],
    ),
    _TopBarSearchSuggestion(
      title: zh ? '文档生成' : 'Document Generation',
      subtitle: zh ? '生成并导出文档' : 'Generate and export documents',
      category: zh ? '页面' : 'Page',
      pageId: 'document-generation',
      icon: Icons.edit_document,
      keywords: const ['generate', 'export', 'markdown', 'docx', 'pdf', '文档生成'],
    ),
    _TopBarSearchSuggestion(
      title: zh ? 'Skill 工厂' : 'Skill Factory',
      subtitle: zh
          ? '从知识库生成 Skill，并绑定给 Agent'
          : 'Generate Skills from KBs and bind them to Agents',
      category: zh ? '页面' : 'Page',
      pageId: 'skill-factory',
      icon: Icons.extension_outlined,
      keywords: const ['skill', 'SKILL.md', '技能', '工厂'],
    ),
    _TopBarSearchSuggestion(
      title: zh ? 'Agent 工作台' : 'Agent Workbench',
      subtitle: zh
          ? 'Agent 总览、单 Agent、多 Agent / A2A 和运行审计'
          : 'Agent overview, single Agent, Multi-Agent / A2A, and run audit',
      category: zh ? '页面' : 'Page',
      pageId: 'agent-factory-runtime',
      icon: Icons.smart_toy_outlined,
      keywords: const ['agent', 'chat', 'a2a', 'discussion', '智能体', '对话'],
    ),
    _TopBarSearchSuggestion(
      title: zh ? '产物中心' : 'Artifact Center',
      subtitle: zh
          ? '查看生成文档、知识库、Skill、Agent 和对话产物'
          : 'Browse generated documents, KB, Skill, Agent, and dialogue artifacts',
      category: zh ? '治理' : 'Governance',
      pageId: 'artifact-center',
      icon: Icons.folder_copy_outlined,
      keywords: const ['artifact', 'output', '产物', '导出', '清单'],
    ),
  ];
  if (runtime != null) {
    for (final name in runtime.sourceNames.take(8)) {
      suggestions.add(_TopBarSearchSuggestion(
        title: name,
        subtitle: zh ? '来源文档' : 'Source document',
        category: zh ? '来源文档' : 'Source Document',
        pageId: 'document-library',
        icon: Icons.article_outlined,
        keywords: [name, _displayNameForPath(name), 'document', 'source', '文档'],
      ));
    }
    for (final kb in runtime.knowledgeBases.take(8)) {
      suggestions.add(_TopBarSearchSuggestion(
        title: kb.name,
        subtitle: zh
            ? '${kb.type} · ${kb.chunkCount} chunks · ${kb.sourceCount} 来源'
            : '${kb.type} · ${kb.chunkCount} chunks · ${kb.sourceCount} sources',
        category: zh ? '知识库' : 'Knowledge Base',
        pageId: 'knowledge-package-management',
        icon: Icons.account_tree_outlined,
        keywords: [kb.id, kb.operation, kb.status, kb.manifestPath],
      ));
    }
    if (runtime.hasKnowledgeBase) {
      suggestions.add(_TopBarSearchSuggestion(
        title: zh ? '真实输入知识库' : 'Real input Knowledge Base',
        subtitle: '${runtime.chunkCount} chunks',
        category: zh ? '知识库' : 'Knowledge Base',
        pageId: 'knowledge-package-management',
        icon: Icons.account_tree_outlined,
        keywords: [runtime.kbManifestPath, runtime.qualityReportPath],
      ));
    }
    for (final result in runtime.searchResults.take(8)) {
      suggestions.add(_TopBarSearchSuggestion(
        title: result.title,
        subtitle: result.kbName.isNotEmpty
            ? '${result.kbName} · ${result.citation}'
            : result.citation,
        category: zh ? '证据片段' : 'Evidence',
        pageId: 'retrieval-verification',
        icon: Icons.fact_check_outlined,
        keywords: [result.excerpt, result.kbId, result.score],
      ));
    }
    if (runtime.hasMarkdown) {
      suggestions.add(_TopBarSearchSuggestion(
        title: zh ? '读书笔记 Markdown' : 'Reading notes Markdown',
        subtitle: _displayNameForPath(runtime.generatedMarkdownPath),
        category: zh ? '生成文档' : 'Generated Document',
        pageId: 'document-generation',
        icon: Icons.notes_outlined,
        keywords: [runtime.generatedMarkdownPath, runtime.readingNotesPath],
      ));
    }
    if (runtime.hasExportedDocument) {
      suggestions.add(_TopBarSearchSuggestion(
        title: zh ? '已导出文档' : 'Exported document',
        subtitle: _displayNameForPath(runtime.exportedDocumentPath),
        category: zh ? '生成文档' : 'Generated Document',
        pageId: 'document-generation',
        icon: Icons.file_download_done_outlined,
        keywords: [runtime.exportedDocumentPath, runtime.exportManifestPath],
      ));
    }
    if (runtime.hasSkill) {
      suggestions.add(_TopBarSearchSuggestion(
        title: zh ? '已生成 Skill' : 'Generated Skill',
        subtitle: _displayNameForPath(runtime.skillPath),
        category: 'Skill',
        pageId: 'skill-factory',
        icon: Icons.extension_outlined,
        keywords: [
          runtime.skillPath,
          'SKILL.md',
          'knowledge_qa_skill',
          'localized_writing_skill'
        ],
      ));
    }
    if (runtime.hasAgent) {
      suggestions.add(_TopBarSearchSuggestion(
        title: zh ? '已生成 Agent' : 'Generated Agent',
        subtitle: _displayNameForPath(runtime.agentPath),
        category: 'Agent',
        pageId: 'agent-factory-runtime',
        icon: Icons.smart_toy_outlined,
        keywords: [
          runtime.agentPath,
          'agent_generation_manifest',
          'W_A',
          'W_M'
        ],
      ));
    }
    if (runtime.hasAgentDialogue) {
      suggestions.add(_TopBarSearchSuggestion(
        title: zh ? 'Agent 对话记录' : 'Agent dialogue',
        subtitle: _displayNameForPath(runtime.agentDialoguePath),
        category: 'Agent',
        pageId: 'agent-factory-runtime',
        icon: Icons.chat_bubble_outline,
        keywords: [runtime.agentDialoguePath, runtime.agentDialogueHistoryPath],
      ));
    }
    if (runtime.hasAgentDialogueExport) {
      suggestions.add(_TopBarSearchSuggestion(
        title: zh ? 'Agent 对话导出' : 'Agent dialogue export',
        subtitle: _displayNameForPath(runtime.agentDialogueExportPath),
        category: 'Agent',
        pageId: 'agent-factory-runtime',
        icon: Icons.file_download_done_outlined,
        keywords: [
          runtime.agentDialogueExportPath,
          'agent_dialogue_export',
          'dialogue export',
          '对话导出'
        ],
      ));
    }
    if (runtime.hasMultiAgentDiscussion) {
      suggestions.add(_TopBarSearchSuggestion(
        title: zh ? '多 Agent 联合讨论' : 'Multi-agent discussion',
        subtitle: _displayNameForPath(runtime.multiAgentDiscussionPath),
        category: 'Agent',
        pageId: 'agent-factory-runtime',
        icon: Icons.groups_2_outlined,
        keywords: [runtime.multiAgentDiscussionPath, 'A2A', 'discussion'],
      ));
    }
  }
  return suggestions;
}

_TopBarSearchSuggestion? _bestSearchSuggestion(
    List<_TopBarSearchSuggestion> suggestions, String query) {
  if (suggestions.isEmpty) return null;
  if (query.isEmpty) return suggestions.first;
  for (final suggestion in suggestions) {
    if (suggestion.title.toLowerCase().contains(query)) {
      return suggestion;
    }
  }
  for (final suggestion in suggestions) {
    if (suggestion.matches(query)) {
      return suggestion;
    }
  }
  return null;
}

class _TopBarIconButton extends StatelessWidget {
  const _TopBarIconButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Tooltip(
      message: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onPressed,
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Icon(icon, size: 18),
        ),
      ),
    );
  }
}

class _TopBarLanguageToggle extends StatelessWidget {
  const _TopBarLanguageToggle({
    required this.localeCode,
    required this.onLocaleChanged,
  });

  final String localeCode;
  final ValueChanged<String> onLocaleChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      key: const Key('topbar-language-toggle'),
      height: 40,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _TopBarLanguageButton(
            label: '中',
            selected: localeCode == 'zh-CN',
            onTap: () => onLocaleChanged('zh-CN'),
          ),
          _TopBarLanguageButton(
            label: 'EN',
            selected: localeCode == 'en-US',
            onTap: () => onLocaleChanged('en-US'),
          ),
        ],
      ),
    );
  }
}

class _TopBarLanguageButton extends StatelessWidget {
  const _TopBarLanguageButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: selected ? colors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: selected ? colors.onPrimary : colors.onSurfaceVariant,
                fontWeight: FontWeight.w900,
              ),
        ),
      ),
    );
  }
}

class _TopBarChip extends StatelessWidget {
  const _TopBarChip({
    required this.icon,
    required this.label,
    this.compact = false,
  });

  final IconData icon;
  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: compact ? 104 : 86),
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 17),
            const SizedBox(width: 7),
            Flexible(
              child: Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      )),
            ),
          ],
        ),
      ),
    );
  }
}
