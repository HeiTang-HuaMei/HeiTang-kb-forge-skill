export const defaultLocale = "zh-CN";

export const messages = {
  "zh-CN": {
    "product.kicker": "Windows Desktop Workbench",
    "product.title": "HeiTang Knowledge Workbench",
    "common.mock": "模拟数据",
    "common.futureApi": "预留 API 接入点",
    "common.open": "打开",
    "common.export": "导出",
    "common.review": "复核",
    "common.saveDraft": "保存草稿",
    "common.searchPlaceholder": "搜索知识、技能、文档...",
    "common.terminal": "终端",
    "common.notify": "通知",
    "common.localFirst": "本地优先 · 隐私安全",
    "common.localFirstDetail": "所有数据仅保存在本机",
    "common.systemStatus": "系统状态",
    "common.normal": "正常运行",
    "common.location": "位置",
    "common.version": "版本",
    "common.checkUpdates": "检查更新"
  },
  "en-US": {
    "product.kicker": "Windows Desktop Workbench",
    "product.title": "HeiTang Knowledge Workbench",
    "common.mock": "Mock data",
    "common.futureApi": "Reserved API integration",
    "common.open": "Open",
    "common.export": "Export",
    "common.review": "Review",
    "common.saveDraft": "Save draft",
    "common.searchPlaceholder": "Search knowledge, skills, docs...",
    "common.terminal": "Terminal",
    "common.notify": "Notify",
    "common.localFirst": "Local first · private",
    "common.localFirstDetail": "All data stays on this device",
    "common.systemStatus": "System",
    "common.normal": "Normal",
    "common.location": "Location",
    "common.version": "Version",
    "common.checkUpdates": "Check updates"
  }
};

export function t(locale, key) {
  return messages[locale]?.[key] ?? messages[defaultLocale][key] ?? key;
}
