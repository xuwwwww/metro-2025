 Firebase 版本配置設置

## Firestore 配置

在 Firestore 中創建以下文檔結構：

### 集合：`config`
### 文檔 ID：`app`
### 欄位：
```json
{
  "latestVersion": "0.1.0"
}
```

## Remote Config 配置（可選）

在 Firebase Console → Remote Config 中創建參數：

### 參數名稱：`latest_version`
### 參數值：`0.1.0`

## 版本管理說明

### 版本號格式
使用語義化版本號：`major.minor.patch`
- `major`: 重大更新，需要強制更新
- `minor`: 次要更新，需要強制更新  
- `patch`: 修補更新，建議更新

### 更新策略
1. **Major/Minor 更新** (0.0.1 → 0.1.0 或 1.0.0)
   - 應用會強制顯示更新對話框
   - 用戶必須更新才能繼續使用

2. **Patch 更新** (0.0.1 → 0.0.2)
   - 應用會顯示建議更新對話框
   - 用戶可以選擇稍後再說
   - 24小時內不會重複提示

### 自動化流程建議
在 CI/CD 流程中，當發布新版本時自動更新 Firestore 或 Remote Config：

```bash
# 更新 Firestore
firebase firestore:set config/app '{"latestVersion": "0.1.0"}'

# 更新 Remote Config
firebase remoteconfig:set latest_version=0.1.0
```

## 測試步驟

1. 設置 Firestore 文檔
2. 修改 `pubspec.yaml` 中的版本號
3. 重新編譯應用
4. 啟動應用測試版本檢查功能 