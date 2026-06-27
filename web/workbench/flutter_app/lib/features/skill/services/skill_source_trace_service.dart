import 'dart:io';

import '../repositories/skill_source_trace_repository.dart';

class SkillSourceTraceService {
  const SkillSourceTraceService({
    SkillSourceTraceRepository repository = const SkillSourceTraceRepository(),
  }) : _repository = repository;

  final SkillSourceTraceRepository _repository;

  Future<SkillSourceTraceWriteResult> materializeSourceTrace({
    required Directory workspace,
    required Directory skillRoot,
    required Iterable<String> sourceKbIds,
    required String primarySkillId,
  }) {
    return _repository.writeSourceTrace(
      workspace: workspace,
      skillRoot: skillRoot,
      sourceKbIds: sourceKbIds,
      skillId: primarySkillId,
    );
  }
}
