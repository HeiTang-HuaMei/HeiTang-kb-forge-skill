import '../core_bridge/core_bridge_contract.dart';

enum WorkbenchTaskStatus {
  queued,
  pending,
  running,
  succeeded,
  completed,
  failed,
  retryable,
  cancelled,
  blocked,
  degraded,
}

extension WorkbenchTaskStatusValue on WorkbenchTaskStatus {
  String get value => name;

  bool get canRetry =>
      this == WorkbenchTaskStatus.retryable ||
      this == WorkbenchTaskStatus.cancelled ||
      this == WorkbenchTaskStatus.degraded;

  bool get canCancel => this == WorkbenchTaskStatus.running;

  bool get countsAsSucceeded =>
      this == WorkbenchTaskStatus.succeeded ||
      this == WorkbenchTaskStatus.completed;
}

enum WorkbenchTaskStage {
  fileImport,
  parsing,
  knowledgeSplitting,
  skillGeneration,
  agentPackageGeneration,
  validation,
}

extension WorkbenchTaskStageValue on WorkbenchTaskStage {
  String get id {
    switch (this) {
      case WorkbenchTaskStage.fileImport:
        return 'file_import';
      case WorkbenchTaskStage.parsing:
        return 'parsing';
      case WorkbenchTaskStage.knowledgeSplitting:
        return 'knowledge_splitting';
      case WorkbenchTaskStage.skillGeneration:
        return 'skill_generation';
      case WorkbenchTaskStage.agentPackageGeneration:
        return 'agent_package_generation';
      case WorkbenchTaskStage.validation:
        return 'validation';
    }
  }
}

class WorkbenchTaskSnapshot {
  factory WorkbenchTaskSnapshot({
    required WorkbenchTaskStage stage,
    required WorkbenchTaskStatus status,
    required double progress,
    required String currentStep,
    required String inputRequired,
    required String outputTarget,
    required String nextSafeAction,
    String evidencePath = '',
    String failureReason = '',
  }) {
    if (progress < 0 || progress > 1) {
      throw ArgumentError.value(
          progress, 'progress', 'must be between 0 and 1');
    }
    if (status.countsAsSucceeded &&
        (progress != 1 || evidencePath.isEmpty || outputTarget.isEmpty)) {
      throw ArgumentError(
        'succeeded tasks require 100% progress, an output target, and evidence',
      );
    }
    return WorkbenchTaskSnapshot._(
      stage: stage,
      status: status,
      progress: progress,
      currentStep: currentStep,
      inputRequired: inputRequired,
      outputTarget: outputTarget,
      nextSafeAction: nextSafeAction,
      evidencePath: evidencePath,
      failureReason: failureReason,
    );
  }

  const WorkbenchTaskSnapshot._({
    required this.stage,
    required this.status,
    required this.progress,
    required this.currentStep,
    required this.inputRequired,
    required this.outputTarget,
    required this.nextSafeAction,
    required this.evidencePath,
    required this.failureReason,
  });

  final WorkbenchTaskStage stage;
  final WorkbenchTaskStatus status;
  final double progress;
  final String currentStep;
  final String inputRequired;
  final String outputTarget;
  final String nextSafeAction;
  final String evidencePath;
  final String failureReason;
}

List<WorkbenchTaskSnapshot> initialWorkbenchTasks(String workspace) {
  final outputContract = CoreOutputPathContract(workspace);

  return WorkbenchTaskStage.values
      .map(
        (stage) => WorkbenchTaskSnapshot(
          stage: stage,
          status: WorkbenchTaskStatus.pending,
          progress: 0,
          currentStep: 'awaiting_input_or_previous_stage',
          inputRequired: _inputFor(stage),
          outputTarget: outputContract.forAction(stage.id),
          nextSafeAction: _nextActionFor(stage),
        ),
      )
      .toList(growable: false);
}

String _inputFor(WorkbenchTaskStage stage) {
  switch (stage) {
    case WorkbenchTaskStage.fileImport:
      return 'local_file_or_folder';
    case WorkbenchTaskStage.parsing:
      return 'import_manifest';
    case WorkbenchTaskStage.knowledgeSplitting:
      return 'parsed_content';
    case WorkbenchTaskStage.skillGeneration:
      return 'knowledge_package_draft';
    case WorkbenchTaskStage.agentPackageGeneration:
      return 'validated_skill_draft';
    case WorkbenchTaskStage.validation:
      return 'draft_outputs';
  }
}

String _nextActionFor(WorkbenchTaskStage stage) {
  switch (stage) {
    case WorkbenchTaskStage.fileImport:
      return 'Select a local input and review the import boundary.';
    case WorkbenchTaskStage.parsing:
      return 'Complete file import before starting a local parser action.';
    case WorkbenchTaskStage.knowledgeSplitting:
      return 'Validate parsed content before building knowledge chunks.';
    case WorkbenchTaskStage.skillGeneration:
      return 'Review the knowledge package draft before Skill generation.';
    case WorkbenchTaskStage.agentPackageGeneration:
      return 'Generate a package draft only; executable runtime is out of scope.';
    case WorkbenchTaskStage.validation:
      return 'Validate manifests and reports without claiming Full Review.';
  }
}
