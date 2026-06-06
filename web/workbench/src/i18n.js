export const defaultLocale = "zh-CN";

export const messages = {
  "zh-CN": {
    "product.kicker": "Mock-only UI Prototype",
    "product.title": "HeiTang Knowledge Workbench",
    "common.mock": "模拟数据",
    "common.futureApi": "预留 API 接入点",
    "common.open": "打开",
    "common.export": "导出",
    "common.review": "复核",
    "common.saveDraft": "保存草稿"
  },
  "en-US": {
    "product.kicker": "Mock-only UI Prototype",
    "product.title": "HeiTang Knowledge Workbench",
    "common.mock": "Mock data",
    "common.futureApi": "Reserved API integration",
    "common.open": "Open",
    "common.export": "Export",
    "common.review": "Review",
    "common.saveDraft": "Save draft"
  }
};

export function t(locale, key) {
  return messages[locale]?.[key] ?? messages[defaultLocale][key] ?? key;
}
