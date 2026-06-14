import 'package:flutter/material.dart';

class RuntimeCacheSettings {
  const RuntimeCacheSettings({
    required this.runtimeCachePath,
    required this.markerModelCachePath,
    required this.suryaModelCachePath,
  });

  factory RuntimeCacheSettings.forWorkspace(String workspace) {
    final root = _join(workspace, '.heitang/runtime_cache');
    return RuntimeCacheSettings(
      runtimeCachePath: root,
      markerModelCachePath: _join(root, 'marker'),
      suryaModelCachePath: _join(root, 'surya'),
    );
  }

  final String runtimeCachePath;
  final String markerModelCachePath;
  final String suryaModelCachePath;

  Map<String, String> environmentForAction(String actionId) {
    if (actionId.contains('marker')) {
      return <String, String>{
        'HEITANG_RUNTIME_MODEL_CACHE': runtimeCachePath,
        'HEITANG_MARKER_MODEL_CACHE': markerModelCachePath,
        'MODEL_CACHE_DIR': markerModelCachePath,
        'TORCH_DEVICE': 'cpu',
      };
    }
    if (actionId.contains('surya')) {
      return <String, String>{
        'HEITANG_RUNTIME_MODEL_CACHE': runtimeCachePath,
        'HEITANG_SURYA_MODEL_CACHE': suryaModelCachePath,
        'MODEL_CACHE_DIR': suryaModelCachePath,
        'TORCH_DEVICE': 'cpu',
      };
    }
    return const <String, String>{};
  }
}

class RuntimeCacheSettingsCard extends StatelessWidget {
  const RuntimeCacheSettingsCard({
    super.key,
    required this.settings,
    required this.localeCode,
  });

  final RuntimeCacheSettings settings;
  final String localeCode;

  @override
  Widget build(BuildContext context) {
    final zh = localeCode == 'zh-CN';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              zh ? '运行时缓存设置' : 'Runtime Cache Settings',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            _CachePath(
                label: 'Runtime cache', value: settings.runtimeCachePath),
            _CachePath(
                label: 'Marker model cache',
                value: settings.markerModelCachePath),
            _CachePath(
                label: 'Surya model cache',
                value: settings.suryaModelCachePath),
            const SizedBox(height: 6),
            Text(
              zh
                  ? '桌面 Core Bridge 会按 action 注入缓存环境变量；静态 Web 不执行本地模型。'
                  : 'The desktop Core Bridge injects cache variables per action; static web does not execute local models.',
            ),
          ],
        ),
      ),
    );
  }
}

class _CachePath extends StatelessWidget {
  const _CachePath({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: SelectableText('$label: $value'),
    );
  }
}

String _join(String root, String suffix) {
  final separator = root.contains(r'\') ? r'\' : '/';
  final normalizedRoot = root.endsWith('/') || root.endsWith(r'\')
      ? root.substring(0, root.length - 1)
      : root;
  return '$normalizedRoot$separator${suffix.replaceAll('/', separator)}';
}
