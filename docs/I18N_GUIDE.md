# I18N Guide

v1.2.3 supports:

- default locale: `zh-CN`
- English locale: `en-US`

The desktop UI stores language choice in localStorage and keeps JSON keys, CLI flags, file names, and raw outputs in their native form.

## File

```text
desktop/tauri/src/i18n.ts
```

The file exports:

- `defaultLocale = "zh-CN"`
- zh-CN messages
- en-US messages

## Rules

- Navigation labels use i18n.
- Buttons use i18n.
- Form labels use i18n where practical.
- Empty, success, and error states use i18n.
- Do not hardcode large blocks of UI copy in JSX.
