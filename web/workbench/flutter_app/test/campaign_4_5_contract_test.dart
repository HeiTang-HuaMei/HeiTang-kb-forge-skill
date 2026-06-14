import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:heitang_workbench/core_bridge/core_bridge_contract.dart';
import 'package:heitang_workbench/core_bridge/local_core_bridge.dart';
import 'package:heitang_workbench/workbench/task_model.dart';

void main() {
  test('task status model contains every Campaign 4 state', () {
    expect(
      WorkbenchTaskStatus.values.map((status) => status.value),
      [
        'pending',
        'running',
        'completed',
        'failed',
        'retryable',
        'cancelled',
        'blocked',
      ],
    );
    expect(WorkbenchTaskStatus.running.canCancel, isTrue);
    expect(WorkbenchTaskStatus.retryable.canRetry, isTrue);
    expect(WorkbenchTaskStatus.cancelled.canRetry, isTrue);
  });

  test('initial workflow has six pending stages and no fake completion', () {
    final tasks = initialWorkbenchTasks(r'C:\workspace');

    expect(tasks, hasLength(6));
    expect(
      tasks.map((task) => task.stage),
      WorkbenchTaskStage.values,
    );
    expect(
      tasks.every((task) =>
          task.status == WorkbenchTaskStatus.pending &&
          task.progress == 0 &&
          task.evidencePath.isEmpty),
      isTrue,
    );
  });

  test('completed state requires output and evidence', () {
    expect(
      () => WorkbenchTaskSnapshot(
        stage: WorkbenchTaskStage.validation,
        status: WorkbenchTaskStatus.completed,
        progress: 1,
        currentStep: 'done',
        inputRequired: 'draft_outputs',
        outputTarget: r'C:\workspace\workbench_runs\validation',
        nextSafeAction: 'Review report.',
      ),
      throwsArgumentError,
    );

    final completed = WorkbenchTaskSnapshot(
      stage: WorkbenchTaskStage.validation,
      status: WorkbenchTaskStatus.completed,
      progress: 1,
      currentStep: 'done',
      inputRequired: 'draft_outputs',
      outputTarget: r'C:\workspace\workbench_runs\validation',
      nextSafeAction: 'Review report.',
      evidencePath: r'C:\workspace\workbench_runs\validation\report.json',
    );
    expect(completed.status, WorkbenchTaskStatus.completed);
  });

  test('output contract keeps action paths inside the workspace', () {
    final contract = CoreOutputPathContract(r'C:\workspace');
    final output = contract.forAction('package_validation');

    expect(output, r'C:\workspace\workbench_runs\package_validation');
    expect(contract.contains(output), isTrue);
    expect(contract.contains(r'C:\other\output'), isFalse);
    expect(
      () => contract.forAction('../outside'),
      throwsArgumentError,
    );
  });

  test('bridge rejects output paths outside the workspace', () {
    const bridge = LocalCoreBridge();
    const request = CoreBridgeRequest(
      actionId: 'package_build',
      coreCli: 'heitang-kb-forge',
      workingDirectory: r'C:\repo',
      arguments: [
        'build',
        '--input',
        r'C:\workspace\input',
        '--output',
        r'C:\outside\output',
      ],
      outputPath: r'C:\outside\output',
      allowedOutputRoot: r'C:\workspace',
    );

    expect(
      () => bridge.buildCommand(request),
      throwsA(
        isA<CoreBridgeException>().having(
          (error) => error.errorId,
          'errorId',
          'core_bridge_output_path_rejected',
        ),
      ),
    );
  });

  test('bridge returns cancelled for a cancelled local task', () async {
    final started = Completer<void>();
    final release = Completer<void>();
    final bridge = LocalCoreBridge(
      runner: (request) async {
        started.complete();
        await release.future;
        return const CoreBridgeProcessResult(
          exitCode: 0,
          stdout: 'late result',
          stderr: '',
        );
      },
    );
    final token = CoreBridgeCancellationToken();
    final resultFuture = bridge.run(
      CoreBridgeRequest(
        actionId: 'package_build',
        coreCli: 'heitang-kb-forge',
        workingDirectory: r'C:\repo',
        arguments: const [
          'build',
          '--input',
          r'C:\workspace\input',
          '--output',
          r'C:\workspace\workbench_runs\package_build',
        ],
        outputPath: r'C:\workspace\workbench_runs\package_build',
        allowedOutputRoot: r'C:\workspace',
        cancellationToken: token,
      ),
    );

    await started.future;
    token.cancel();
    final result = await resultFuture;
    release.complete();

    expect(result.status, 'cancelled');
    expect(result.cancelled, isTrue);
    expect(result.retryable, isFalse);
    expect(result.errorId, 'core_operation_cancelled');
  });

  test('process failure is explicitly retryable within policy', () async {
    final bridge = LocalCoreBridge(
      runner: (request) async => const CoreBridgeProcessResult(
        exitCode: 2,
        stdout: '',
        stderr: 'failed',
      ),
    );
    final result = await bridge.run(
      const CoreBridgeRequest(
        actionId: 'package_build',
        coreCli: 'heitang-kb-forge',
        workingDirectory: r'C:\repo',
        arguments: [
          'build',
          '--input',
          r'C:\workspace\input',
          '--output',
          r'C:\workspace\workbench_runs\package_build',
        ],
        outputPath: r'C:\workspace\workbench_runs\package_build',
        allowedOutputRoot: r'C:\workspace',
      ),
    );

    expect(result.status, 'retryable');
    expect(result.retryable, isTrue);
    expect(result.errorId, 'core_operation_failed');
  });

  test('bridge stops offering retry at the configured attempt limit', () async {
    final bridge = LocalCoreBridge(
      runner: (request) async => const CoreBridgeProcessResult(
        exitCode: 2,
        stdout: '',
        stderr: 'failed again',
      ),
    );
    final result = await bridge.run(
      const CoreBridgeRequest(
        actionId: 'package_build',
        coreCli: 'heitang-kb-forge',
        workingDirectory: r'C:\repo',
        arguments: [
          'build',
          '--input',
          r'C:\workspace\input',
          '--output',
          r'C:\workspace\workbench_runs\package_build',
        ],
        outputPath: r'C:\workspace\workbench_runs\package_build',
        allowedOutputRoot: r'C:\workspace',
        attempt: 2,
      ),
    );

    expect(result.status, 'fail');
    expect(result.retryable, isFalse);
    expect(result.attempt, 2);
  });

  test('missing cli produces a structured retryable start failure', () async {
    const bridge = LocalCoreBridge();
    final result = await bridge.run(
      const CoreBridgeRequest(
        actionId: 'package_build',
        coreCli: '__missing_heitang_core_cli__',
        workingDirectory: r'C:\repo',
        arguments: [
          'build',
          '--input',
          r'C:\workspace\input',
          '--output',
          r'C:\workspace\workbench_runs\package_build',
        ],
        outputPath: r'C:\workspace\workbench_runs\package_build',
        allowedOutputRoot: r'C:\workspace',
      ),
    );

    expect(result.status, 'retryable');
    expect(result.retryable, isTrue);
    expect(result.errorId, 'core_operation_start_failed');
    expect(result.exitCode, -1);
  });

  test('invalid working directory produces a structured start failure',
      () async {
    const bridge = LocalCoreBridge();
    final result = await bridge.run(
      CoreBridgeRequest(
        actionId: 'package_build',
        coreCli: Platform.resolvedExecutable,
        workingDirectory: r'C:\__missing_heitang_workspace__',
        arguments: const [
          'build',
          '--input',
          r'C:\workspace\input',
          '--output',
          r'C:\workspace\workbench_runs\package_build',
        ],
        outputPath: r'C:\workspace\workbench_runs\package_build',
        allowedOutputRoot: r'C:\workspace',
      ),
    );

    expect(result.status, 'retryable');
    expect(result.retryable, isTrue);
    expect(result.errorId, 'core_operation_start_failed');
    expect(result.stderr, contains('Core operation failed to start'));
  });

  test('runner exception does not escape LocalCoreBridge.run', () async {
    final bridge = LocalCoreBridge(
      runner: (request) async {
        throw StateError('boom token=sk-live-secret');
      },
    );

    final result = await bridge.run(
      const CoreBridgeRequest(
        actionId: 'package_build',
        coreCli: 'heitang-kb-forge',
        workingDirectory: r'C:\repo',
        arguments: [
          'build',
          '--input',
          r'C:\workspace\input',
          '--output',
          r'C:\workspace\workbench_runs\package_build',
        ],
        outputPath: r'C:\workspace\workbench_runs\package_build',
        allowedOutputRoot: r'C:\workspace',
      ),
    );

    expect(result.status, 'retryable');
    expect(result.retryable, isTrue);
    expect(result.errorId, 'core_operation_start_failed');
    expect(result.stderr, contains('<redacted>'));
    expect(result.stderr, isNot(contains('sk-live-secret')));
  });
}
