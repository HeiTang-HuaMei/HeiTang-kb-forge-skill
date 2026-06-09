class WorkbenchContracts {
  const WorkbenchContracts({
    required this.manifest,
    required this.navigation,
    required this.actions,
    required this.assets,
    required this.status,
    required this.agent,
    required this.hierarchy,
    required this.memory,
    required this.storage,
    required this.errors,
    required this.capabilities,
    required this.reports,
    required this.taskSchema,
    required this.templates,
    required this.gate,
    required this.source,
  });

  final ContractManifest manifest;
  final NavigationContract navigation;
  final ActionContract actions;
  final AssetContract assets;
  final StatusContract status;
  final AgentContract agent;
  final HierarchyContract hierarchy;
  final MemoryContract memory;
  final StorageContract storage;
  final ErrorContract errors;
  final CapabilityContract capabilities;
  final ReportContract reports;
  final TaskSchemaContract taskSchema;
  final TemplateContract templates;
  final GateContract gate;
  final ContractSource source;

  factory WorkbenchContracts.fromJson(Map<String, dynamic> json) {
    return WorkbenchContracts(
      manifest: ContractManifest.fromJson(_map(json['manifest'])),
      navigation: NavigationContract.fromJson(_map(json['navigation'])),
      actions: ActionContract.fromJson(_map(json['actions'])),
      assets: AssetContract.fromJson(_map(json['assets'])),
      status: StatusContract.fromJson(_map(json['status'])),
      agent: AgentContract.fromJson(_map(json['agent'])),
      hierarchy: HierarchyContract.fromJson(_map(json['hierarchy'])),
      memory: MemoryContract.fromJson(_map(json['memory'])),
      storage: StorageContract.fromJson(_map(json['storage'])),
      errors: ErrorContract.fromJson(_map(json['errors'])),
      capabilities: CapabilityContract.fromJson(_map(json['capabilities'])),
      reports: ReportContract.fromJson(_map(json['reports'])),
      taskSchema: TaskSchemaContract.fromJson(_map(json['task_schema'])),
      templates: TemplateContract.fromJson(_map(json['templates'])),
      gate: GateContract.fromJson(_map(json['gate'])),
      source: ContractSource.fromJson(_map(json['source'])),
    );
  }
}

class ContractManifest {
  const ContractManifest({required this.projectName, required this.status, required this.outputFiles});

  final String projectName;
  final String status;
  final List<String> outputFiles;

  factory ContractManifest.fromJson(Map<String, dynamic> json) {
    return ContractManifest(
      projectName: _string(json['project_name'], 'HeiTang Workbench'),
      status: _string(json['status'], 'empty'),
      outputFiles: _strings(json['output_files']),
    );
  }
}

class NavigationContract {
  const NavigationContract({required this.views});

  final List<ContractView> views;

  factory NavigationContract.fromJson(Map<String, dynamic> json) {
    return NavigationContract(views: _list(json['views']).map((item) => ContractView.fromJson(_map(item))).toList());
  }
}

class ContractView {
  const ContractView({required this.id, required this.label, required this.assetTypes, required this.corePageId, required this.zhLabel});

  final String id;
  final String label;
  final List<String> assetTypes;
  final String corePageId;
  final String zhLabel;

  factory ContractView.fromJson(Map<String, dynamic> json) {
    return ContractView(
      id: _string(json['id'], 'view'),
      label: _string(json['label'], 'View'),
      assetTypes: _strings(json['asset_types']),
      corePageId: _string(json['core_page_id'], _string(json['id'], 'view')),
      zhLabel: _string(json['label_zh'], _string(json['label'], 'View')),
    );
  }
}

class ActionContract {
  const ActionContract({required this.actions});

  final List<ContractAction> actions;

  factory ActionContract.fromJson(Map<String, dynamic> json) {
    return ActionContract(actions: _list(json['actions']).map((item) => ContractAction.fromJson(_map(item))).toList());
  }
}

class ContractAction {
  const ContractAction({
    required this.id,
    required this.label,
    required this.command,
    required this.requires,
    required this.pageId,
    required this.status,
    required this.commandKind,
    required this.blockedReason,
    required this.desktopEnabled,
    required this.webEnabled,
    required this.desktopBlockedReason,
    required this.webBlockedReason,
    required this.reportIds,
    required this.artifactIds,
    required this.errorCodes,
  });

  final String id;
  final String label;
  final String command;
  final List<String> requires;
  final String pageId;
  final String status;
  final String commandKind;
  final String blockedReason;
  final bool desktopEnabled;
  final bool webEnabled;
  final String desktopBlockedReason;
  final String webBlockedReason;
  final List<String> reportIds;
  final List<String> artifactIds;
  final List<String> errorCodes;

  factory ContractAction.fromJson(Map<String, dynamic> json) {
    return ContractAction(
      id: _string(json['id'], _string(json['action_id'], 'action')),
      label: _string(json['label'], 'Action'),
      command: _string(json['command'], ''),
      requires: _strings(json['requires']),
      pageId: _string(json['page_id'], ''),
      status: _string(json['status'], 'reserved'),
      commandKind: _string(json['command_kind'], ''),
      blockedReason: _string(json['blocked_reason'], _string(json['ui_blocked_reason'], '')),
      desktopEnabled: _bool(json['desktop_enabled']),
      webEnabled: _bool(json['web_enabled']),
      desktopBlockedReason: _string(json['desktop_blocked_reason'], ''),
      webBlockedReason: _string(json['web_blocked_reason'], ''),
      reportIds: _strings(json['report_ids']),
      artifactIds: _strings(json['artifact_ids']),
      errorCodes: _strings(json['error_codes']),
    );
  }
}

class AssetContract {
  const AssetContract({required this.assets});

  final List<ContractAsset> assets;

  factory AssetContract.fromJson(Map<String, dynamic> json) {
    return AssetContract(assets: _list(json['assets']).map((item) => ContractAsset.fromJson(_map(item))).toList());
  }
}

class ContractAsset {
  const ContractAsset({required this.id, required this.type, required this.path, required this.pageId});

  final String id;
  final String type;
  final String path;
  final String pageId;

  factory ContractAsset.fromJson(Map<String, dynamic> json) {
    return ContractAsset(
      id: _string(json['asset_id'], 'asset'),
      type: _string(json['asset_type'], 'report'),
      path: _string(json['path'], _string(json['deterministic_fixture_path'], '')),
      pageId: _string(json['page_id'], ''),
    );
  }
}

class StatusContract {
  const StatusContract({
    required this.status,
    required this.assetCount,
    required this.reportCount,
    required this.storageBackend,
    required this.compactionStatus,
    required this.backupExportStatus,
  });

  final String status;
  final int assetCount;
  final int reportCount;
  final String storageBackend;
  final String compactionStatus;
  final String backupExportStatus;

  factory StatusContract.fromJson(Map<String, dynamic> json) {
    return StatusContract(
      status: _string(json['status'], 'empty'),
      assetCount: _int(json['asset_count']),
      reportCount: _int(json['report_count']),
      storageBackend: _string(json['storage_backend'], 'local_workspace'),
      compactionStatus: _string(json['compaction_status'], 'not_required'),
      backupExportStatus: _string(json['backup_export_status'], 'available_local_export'),
    );
  }
}

class AgentContract {
  const AgentContract({
    required this.supportedModes,
    required this.standaloneRequired,
    required this.kbBoundRequired,
    required this.validationStates,
    required this.errorStates,
  });

  final List<String> supportedModes;
  final List<String> standaloneRequired;
  final List<String> kbBoundRequired;
  final List<String> validationStates;
  final List<String> errorStates;

  factory AgentContract.fromJson(Map<String, dynamic> json) {
    return AgentContract(
      supportedModes: _strings(json['supported_agent_modes']),
      standaloneRequired: _strings(_map(json['standalone_agent_schema'])['required']),
      kbBoundRequired: _strings(_map(json['kb_bound_agent_schema'])['required']),
      validationStates: _strings(json['validation_states']),
      errorStates: _strings(json['error_states']),
    );
  }
}

class HierarchyContract {
  const HierarchyContract({required this.roles, required this.bindingFields, required this.traceFiles});

  final List<String> roles;
  final List<String> bindingFields;
  final List<String> traceFiles;

  factory HierarchyContract.fromJson(Map<String, dynamic> json) {
    final entities = _map(json['entities']);
    return HierarchyContract(
      roles: _strings(_map(entities['child_agents'])['modes']),
      bindingFields: _strings(_map(_map(entities['parent_child_binding']))['required_fields']),
      traceFiles: _strings(json['trace_files']),
    );
  }
}

class MemoryContract {
  const MemoryContract({required this.policy, required this.lifecycleFields, required this.writebackActions, required this.statusFiles});

  final Map<String, dynamic> policy;
  final List<String> lifecycleFields;
  final List<String> writebackActions;
  final List<String> statusFiles;

  factory MemoryContract.fromJson(Map<String, dynamic> json) {
    return MemoryContract(
      policy: _map(json['policy']),
      lifecycleFields: _strings(json['lifecycle_fields']),
      writebackActions: _strings(json['writeback_actions']),
      statusFiles: _strings(json['status_files']),
    );
  }
}

class StorageContract {
  const StorageContract({
    required this.backend,
    required this.supportedBackends,
    required this.storageAreas,
    required this.sizes,
    required this.cleanupSuggestions,
    required this.compactionStatus,
    required this.backupExportStatus,
  });

  final String backend;
  final List<String> supportedBackends;
  final Map<String, dynamic> storageAreas;
  final Map<String, dynamic> sizes;
  final List<String> cleanupSuggestions;
  final String compactionStatus;
  final String backupExportStatus;

  factory StorageContract.fromJson(Map<String, dynamic> json) {
    return StorageContract(
      backend: _string(json['storage_backend'], 'local_workspace'),
      supportedBackends: _strings(json['supported_storage_backends']),
      storageAreas: _map(json['storage_areas']),
      sizes: _map(json['sizes']),
      cleanupSuggestions: _strings(json['cleanup_suggestions']),
      compactionStatus: _string(json['compaction_status'], 'not_required'),
      backupExportStatus: _string(json['backup_export_status'], 'available_local_export'),
    );
  }
}

class ErrorContract {
  const ErrorContract({required this.emptyStates, required this.errorStates, required this.statusBadges});

  final List<String> emptyStates;
  final List<String> errorStates;
  final List<String> statusBadges;

  factory ErrorContract.fromJson(Map<String, dynamic> json) {
    return ErrorContract(
      emptyStates: _list(json['empty_states']).map((item) => _string(_map(item)['id'], 'empty')).toList(),
      errorStates: _list(json['error_states']).map((item) => _string(_map(item)['id'], 'error')).toList(),
      statusBadges: _strings(json['status_badges']),
    );
  }
}

class CapabilityContract {
  const CapabilityContract({required this.areas});

  final List<CapabilityArea> areas;

  factory CapabilityContract.fromJson(Map<String, dynamic> json) {
    return CapabilityContract(areas: _list(json['capability_areas']).map((item) => CapabilityArea.fromJson(_map(item))).toList());
  }
}

class CapabilityArea {
  const CapabilityArea({required this.pageId, required this.title, required this.actionIds, required this.reportIds, required this.artifactIds});

  final String pageId;
  final String title;
  final List<String> actionIds;
  final List<String> reportIds;
  final List<String> artifactIds;

  factory CapabilityArea.fromJson(Map<String, dynamic> json) {
    return CapabilityArea(
      pageId: _string(json['page_id'], ''),
      title: _string(json['title'], ''),
      actionIds: _strings(json['action_ids']),
      reportIds: _strings(json['report_ids']),
      artifactIds: _strings(json['artifact_ids']),
    );
  }
}

class ReportContract {
  const ReportContract({required this.reports});

  final List<ContractReport> reports;

  factory ReportContract.fromJson(Map<String, dynamic> json) {
    return ReportContract(reports: _list(json['reports']).map((item) => ContractReport.fromJson(_map(item))).toList());
  }
}

class ContractReport {
  const ContractReport({required this.id, required this.pageId, required this.title});

  final String id;
  final String pageId;
  final String title;

  factory ContractReport.fromJson(Map<String, dynamic> json) {
    return ContractReport(
      id: _string(json['report_id'], 'report'),
      pageId: _string(json['page_id'], ''),
      title: _string(json['title'], ''),
    );
  }
}

class TaskSchemaContract {
  const TaskSchemaContract({required this.statuses});

  final List<String> statuses;

  factory TaskSchemaContract.fromJson(Map<String, dynamic> json) {
    return TaskSchemaContract(statuses: _strings(json['statuses']));
  }
}

class TemplateContract {
  const TemplateContract({required this.templates});

  final List<ContractTemplate> templates;

  factory TemplateContract.fromJson(Map<String, dynamic> json) {
    return TemplateContract(templates: _list(json['templates']).map((item) => ContractTemplate.fromJson(_map(item))).toList());
  }
}

class ContractTemplate {
  const ContractTemplate({required this.id, required this.title});

  final String id;
  final String title;

  factory ContractTemplate.fromJson(Map<String, dynamic> json) {
    return ContractTemplate(id: _string(json['template_id'], 'template'), title: _string(json['title'], ''));
  }
}

class GateContract {
  const GateContract({required this.status, required this.notV4WorkbenchRc, required this.uiFullOperationPending, required this.blockerIds});

  final String status;
  final bool notV4WorkbenchRc;
  final bool uiFullOperationPending;
  final List<String> blockerIds;

  factory GateContract.fromJson(Map<String, dynamic> json) {
    return GateContract(
      status: _string(json['p1_full_operation_gate_status'], 'blocked'),
      notV4WorkbenchRc: _bool(json['not_v4_0_workbench_rc']),
      uiFullOperationPending: _bool(json['ui_full_operation_pending']),
      blockerIds: _strings(json['blocker_ids']),
    );
  }
}

class ContractSource {
  const ContractSource({required this.coreCommit, required this.copiedFrom});

  final String coreCommit;
  final String copiedFrom;

  factory ContractSource.fromJson(Map<String, dynamic> json) {
    return ContractSource(
      coreCommit: _string(json['core_commit'], ''),
      copiedFrom: _string(json['copied_from'], ''),
    );
  }
}

Map<String, dynamic> _map(Object? value) => value is Map<String, dynamic> ? value : <String, dynamic>{};

List<dynamic> _list(Object? value) => value is List ? value : <dynamic>[];

List<String> _strings(Object? value) => _list(value).map((item) => item.toString()).toList();

String _string(Object? value, String fallback) => value?.toString() ?? fallback;

int _int(Object? value) => value is int ? value : int.tryParse(value?.toString() ?? '') ?? 0;

bool _bool(Object? value) => value is bool ? value : value?.toString().toLowerCase() == 'true';
