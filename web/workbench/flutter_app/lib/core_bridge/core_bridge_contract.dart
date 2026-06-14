class CoreOutputPathContract {
  CoreOutputPathContract(this.workspace) {
    if (workspace.trim().isEmpty) {
      throw ArgumentError.value(workspace, 'workspace', 'must not be empty');
    }
  }

  final String workspace;

  String forAction(String actionId) {
    if (!RegExp(r'^[a-z0-9_]+$').hasMatch(actionId)) {
      throw ArgumentError.value(actionId, 'actionId', 'is not path-safe');
    }
    return _join(workspace, 'workbench_runs/$actionId');
  }

  bool contains(String candidate) {
    final root = _normalize(workspace);
    final path = _normalize(candidate);
    if (root == '.') {
      return !_isAbsolute(path) && !path.split('/').contains('..');
    }
    return path == root || path.startsWith('$root/');
  }
}

class CoreBridgeRetryPolicy {
  const CoreBridgeRetryPolicy({
    this.maxAttempts = 2,
    this.retryOnTimeout = true,
    this.retryOnProcessFailure = true,
  }) : assert(maxAttempts > 0);

  final int maxAttempts;
  final bool retryOnTimeout;
  final bool retryOnProcessFailure;
}

String _join(String root, String suffix) {
  final separator = root.contains(r'\') ? r'\' : '/';
  final normalizedRoot = root.endsWith('/') || root.endsWith(r'\')
      ? root.substring(0, root.length - 1)
      : root;
  return '$normalizedRoot$separator${suffix.replaceAll('/', separator)}';
}

String _normalize(String value) {
  final slashPath =
      value.trim().replaceAll('\\', '/').replaceAll(RegExp('/+'), '/');
  final drive = RegExp(r'^[A-Za-z]:').firstMatch(slashPath)?.group(0);
  final absolute = slashPath.startsWith('/');
  final source = drive != null
      ? slashPath.substring(drive.length)
      : absolute
          ? slashPath.substring(1)
          : slashPath;
  final parts = <String>[];
  for (final part in source.split('/')) {
    if (part.isEmpty || part == '.') {
      continue;
    }
    if (part == '..') {
      if (parts.isNotEmpty && parts.last != '..') {
        parts.removeLast();
      } else {
        parts.add(part);
      }
    } else {
      parts.add(part.toLowerCase());
    }
  }
  if (drive != null) {
    return '${drive.toLowerCase()}/${parts.join('/')}';
  }
  if (absolute) {
    return '/${parts.join('/')}';
  }
  return parts.isEmpty ? '.' : parts.join('/');
}

bool _isAbsolute(String path) =>
    path.startsWith('/') || RegExp(r'^[a-z]:/').hasMatch(path);
