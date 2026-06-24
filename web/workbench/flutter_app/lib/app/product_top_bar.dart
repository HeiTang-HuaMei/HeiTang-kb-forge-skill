part of '../main.dart';

class _ProductTopBar extends StatelessWidget {
  const _ProductTopBar({
    required this.localeCode,
    required this.page,
    required this.contracts,
    this.compactForPage = false,
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
  final bool compactForPage;
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
    final dark = Theme.of(context).brightness == Brightness.dark;
    final visual = _HTKWTokens.visualTokens(Theme.of(context).brightness);
    final barHeight = compactForPage ? 48.0 : 72.0;
    return Container(
      key: const Key('desktop-topbar-single-row'),
      height: barHeight,
      decoration: BoxDecoration(
        color: visual.topBarBackground,
        border: Border(
          bottom: BorderSide(color: visual.borderSubtle),
        ),
        boxShadow: dark
            ? const []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.018),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: LayoutBuilder(builder: (context, constraints) {
        final width = constraints.maxWidth;
        final compact = compactForPage || width < 360;
        final searchWidth = width >= 900
            ? 420.0
            : width >= 760
                ? 360.0
                : 0.0;
        return Padding(
          padding: EdgeInsets.fromLTRB(
              compactForPage ? 18 : (compact ? 10 : 32),
              compactForPage ? 8 : 14,
              compactForPage ? 18 : (compact ? 10 : 28),
              compactForPage ? 8 : 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: compact
                    ? width.clamp(96.0, 150.0)
                    : width >= 1100
                        ? 330
                        : 240,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(page.title(localeCode, contracts),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            Theme.of(context).textTheme.headlineLarge?.copyWith(
                                  fontSize: compactForPage ? 17 : 22,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0,
                                  height: 1.05,
                                )),
                    if (!compact) ...[
                      const SizedBox(height: 4),
                      Tooltip(
                        message: page.description(localeCode),
                        child: Text(page.description(localeCode),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      fontSize: 12.5,
                                      color: colors.onSurfaceVariant,
                                      fontWeight: FontWeight.w500,
                                      height: 1.12,
                                    )),
                      ),
                    ],
                  ],
                ),
              ),
              if (!compact) const SizedBox(width: 28),
              if (searchWidth > 0)
                SizedBox(
                  width: searchWidth,
                  child: _TopBarSearchField(
                    label: _zh
                        ? '搜索资料、知识库、技能、助手'
                        : 'Search materials, knowledge bases, skills, assistants',
                    onPageChanged: onPageChanged,
                  ),
                ),
              const Spacer(),
              if (!compact) ...[
                _TopBarIconButton(
                  icon: Icons.refresh_outlined,
                  label: _zh ? '刷新' : 'Refresh',
                  onPressed: () {},
                ),
                const SizedBox(width: 8),
              ],
              if (onLocaleChanged != null && !compact)
                _TopBarLanguageToggle(
                  localeCode: localeCode,
                  onLocaleChanged: onLocaleChanged!,
                ),
              if (onLocaleChanged != null && !compact) const SizedBox(width: 8),
              if (isDark != null && onThemeChanged != null && !compact)
                _TopBarIconButton(
                  icon: isDark!
                      ? Icons.light_mode_outlined
                      : Icons.dark_mode_outlined,
                  label:
                      isDark! ? (_zh ? '浅色' : 'Light') : (_zh ? '深色' : 'Dark'),
                  onPressed: () => onThemeChanged!(
                      isDark! ? ThemeMode.light : ThemeMode.dark),
                ),
              if (isDark != null && onThemeChanged != null && !compact)
                const SizedBox(width: 8),
              if (!compact)
                _TopBarIconButton(
                  icon: Icons.settings_outlined,
                  label: _zh ? '设置' : 'Settings',
                  onPressed: () => onPageChanged(_pageIndexById('workspace')),
                ),
            ],
          ),
        );
      }),
    );
  }
}

class _TopBarSearchField extends StatefulWidget {
  const _TopBarSearchField({
    required this.label,
    required this.onPageChanged,
  });

  final String label;
  final ValueChanged<int> onPageChanged;

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
    final brightness = Theme.of(context).brightness;
    final visual = _HTKWTokens.visualTokens(brightness);
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
              constraints: const BoxConstraints(
                maxWidth: 560,
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
            height: 38,
            padding: const EdgeInsets.only(left: 10, right: 6),
            decoration: BoxDecoration(
              color: Color.alphaBlend(
                colors.primary.withValues(
                  alpha: brightness == Brightness.dark ? 0.035 : 0.018,
                ),
                _HTKWTokens.glassSurface(brightness),
              ),
              borderRadius: BorderRadius.circular(_DesktopGrid.radiusMedium),
              border: Border.all(
                  color: focused
                      ? borderColor.withValues(alpha: 0.72)
                      : visual.borderSubtle,
                  width: 1),
              boxShadow: [
                if (brightness == Brightness.light)
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.018),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: _HTKWTokens.moduleKnowledge.withValues(
                      alpha: brightness == Brightness.dark ? 0.14 : 0.08,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _HTKWTokens.moduleKnowledge.withValues(
                        alpha: brightness == Brightness.dark ? 0.16 : 0.1,
                      ),
                    ),
                  ),
                  child: Icon(Icons.search,
                      size: 15,
                      color: focused
                          ? _HTKWTokens.moduleKnowledge
                          : colors.onSurfaceVariant),
                ),
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
                          matched?.pageId ?? 'knowledge-package-management'));
                    },
                    decoration: InputDecoration(
                      hintText: widget.label,
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontSize: 13,
                          color: colors.onSurface,
                          fontWeight: FontWeight.w500,
                          height: 1.16,
                        ),
                  ),
                ),
                if (focused) ...[
                  const SizedBox(width: 6),
                  TextButton(
                    key: const Key('topbar-real-search-submit'),
                    onPressed: runtime?.running == true
                        ? null
                        : () {
                            final matched = _bestSearchSuggestion(suggestions,
                                _controller.text.trim().toLowerCase());
                            widget.onPageChanged(_pageIndexById(
                                matched?.pageId ??
                                    'knowledge-package-management'));
                          },
                    child: Text(statusText),
                  ),
                ],
                if (!focused) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: colors.surface.withValues(
                        alpha: brightness == Brightness.dark ? 0.08 : 0.66,
                      ),
                      borderRadius:
                          BorderRadius.circular(_DesktopGrid.radiusSmall),
                      border: Border.all(
                        color: _HTKWTokens.visualTokens(
                          Theme.of(context).brightness,
                        ).borderSubtle,
                      ),
                    ),
                    child: Text(
                      zh ? '快速定位' : 'Quick',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: colors.onSurfaceVariant,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
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
    title: zh ? '无匹配，前往知识库验证' : 'No match, verify a knowledge base',
    subtitle: zh ? '用当前输入查询知识库内容' : 'Use this query against KB content',
    category: zh ? '知识库' : 'Knowledge Base',
    pageId: 'retrieval-verification',
    icon: Icons.manage_search_outlined,
    isNoMatch: true,
  );
}

List<_TopBarSearchSuggestion> _topBarSearchSuggestions(
    Rc6RuntimeState? runtime, bool zh) {
  final suggestions = <_TopBarSearchSuggestion>[
    _TopBarSearchSuggestion(
      title: zh ? '添加资料' : 'Add materials',
      subtitle: zh
          ? '选择文件、文件夹或保存网页来源'
          : 'Choose files, folders, or save a web source',
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
      subtitle: zh ? '从已整理资料生成知识库' : 'Build from organized materials',
      category: zh ? '页面' : 'Page',
      pageId: 'knowledge-package-management',
      icon: Icons.storage_outlined,
      keywords: const ['kb', 'knowledge', 'manifest', '知识库'],
    ),
    _TopBarSearchSuggestion(
      title: zh ? '知识库验证' : 'Knowledge Base Verification',
      subtitle: zh ? '检索知识库内容和证据片段' : 'Search KB content and evidence',
      category: zh ? '知识库' : 'Knowledge Base',
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
      title: zh ? '技能生成' : 'Skill Builder',
      subtitle: zh ? '从知识库生成可复用技能' : 'Generate reusable skills from KBs',
      category: zh ? '页面' : 'Page',
      pageId: 'skill-factory',
      icon: Icons.extension_outlined,
      keywords: const ['skill', 'SKILL.md', '技能', '工厂'],
    ),
    _TopBarSearchSuggestion(
      title: zh ? '我的助手' : 'My Assistants',
      subtitle: zh
          ? '创建助手、发起对话，并通过工作小组处理复杂任务'
          : 'Create assistants, chat, and run work groups',
      category: zh ? '页面' : 'Page',
      pageId: 'agent-factory-runtime',
      icon: Icons.smart_toy_outlined,
      keywords: const ['assistant', 'chat', 'discussion', '助手', '对话'],
    ),
    _TopBarSearchSuggestion(
      title: zh ? '全部成果' : 'All Outputs',
      subtitle: zh
          ? '查看生成文档、知识库、技能、助手和讨论报告'
          : 'Browse documents, KBs, skills, assistants, and discussion reports',
      category: zh ? '成果' : 'Outputs',
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
            ? '${kb.type} · ${kb.chunkCount} 个片段 · ${kb.sourceCount} 来源'
            : '${kb.type} · ${kb.chunkCount} segments · ${kb.sourceCount} sources',
        category: zh ? '知识库' : 'Knowledge Base',
        pageId: 'knowledge-package-management',
        icon: Icons.account_tree_outlined,
        keywords: [kb.id, kb.operation, kb.status, kb.manifestPath],
      ));
    }
    if (runtime.hasKnowledgeBase) {
      suggestions.add(_TopBarSearchSuggestion(
        title: zh ? '真实输入知识库' : 'Real input Knowledge Base',
        subtitle:
            zh ? '${runtime.chunkCount} 个片段' : '${runtime.chunkCount} segments',
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
        title: zh ? '已生成技能' : 'Generated skill',
        subtitle: _displayNameForPath(runtime.skillPath),
        category: zh ? '技能' : 'Skill',
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
        title: zh ? '已创建助手' : 'Generated assistant',
        subtitle: _displayNameForPath(runtime.agentPath),
        category: zh ? '助手' : 'Assistant',
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
        title: zh ? '助手对话记录' : 'Assistant dialogue',
        subtitle: _displayNameForPath(runtime.agentDialoguePath),
        category: zh ? '助手' : 'Assistant',
        pageId: 'agent-factory-runtime',
        icon: Icons.chat_bubble_outline,
        keywords: [runtime.agentDialoguePath, runtime.agentDialogueHistoryPath],
      ));
    }
    if (runtime.hasAgentDialogueExport) {
      suggestions.add(_TopBarSearchSuggestion(
        title: zh ? '助手对话导出' : 'Assistant dialogue export',
        subtitle: _displayNameForPath(runtime.agentDialogueExportPath),
        category: zh ? '助手' : 'Assistant',
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
        title: zh ? '工作小组' : 'Work group',
        subtitle: _displayNameForPath(runtime.multiAgentDiscussionPath),
        category: zh ? '助手' : 'Assistant',
        pageId: 'agent-factory-runtime',
        icon: Icons.groups_2_outlined,
        keywords: [runtime.multiAgentDiscussionPath, 'discussion', '讨论'],
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
    final brightness = Theme.of(context).brightness;
    return Tooltip(
      message: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onPressed,
        child: Container(
          width: 38,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colors.surfaceContainerLow.withValues(
              alpha: brightness == Brightness.dark ? 0.18 : 0.2,
            ),
            borderRadius: BorderRadius.circular(_DesktopGrid.buttonRadius),
            border: Border.all(
              color: _HTKWTokens.visualTokens(Theme.of(context).brightness)
                  .borderSubtle,
            ),
          ),
          child: Icon(icon,
              size: 18, color: colors.onSurfaceVariant.withValues(alpha: 0.86)),
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
    final brightness = Theme.of(context).brightness;
    return Container(
      key: const Key('topbar-language-toggle'),
      height: 36,
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow.withValues(
          alpha: brightness == Brightness.dark ? 0.18 : 0.22,
        ),
        borderRadius: BorderRadius.circular(_DesktopGrid.buttonRadius),
        border: Border.all(
          color: _HTKWTokens.visualTokens(Theme.of(context).brightness)
              .borderSubtle,
        ),
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
    final brightness = Theme.of(context).brightness;
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 34,
        alignment: Alignment.center,
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: selected
              ? _HTKWTokens.moduleKnowledge.withValues(
                  alpha: brightness == Brightness.dark ? 0.92 : 0.88,
                )
              : Colors.transparent,
          borderRadius: BorderRadius.circular(_DesktopGrid.radiusSmall),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: selected ? colors.onPrimary : colors.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
    );
  }
}
