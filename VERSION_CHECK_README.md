# 版本檢查系統

這個版本檢查系統允許你分開管理「當前版本」和「伺服器上最新版本」，並在應用啟動時自動檢查是否需要更新。

## 功能特點

### 1. 自動版本檢查
- 應用啟動時自動檢查版本
- 支援強制更新和建議更新
- 防止重複提示（24小時冷卻期）

### 2. 語義化版本管理
- 使用 `major.minor.patch` 格式
- Major/Minor 更新：強制更新
- Patch 更新：建議更新

### 3. 多種遠端配置支援
- Firestore 文檔配置
- Firebase Remote Config 配置
- 可擴展的配置源

## 檔案結構

```
lib/
├── utils/
│   ├── version_checker.dart      # 核心版本檢查邏輯
│   └── version_check_wrapper.dart # 版本檢查包裝器
├── widgets/
│   └── version_update_dialog.dart # 更新對話框 UI
└── main.dart                     # 整合版本檢查
```

## 核心組件

### VersionChecker
負責版本比較和遠端版本獲取：

```dart
final checker = VersionChecker();

// 檢查是否需要強制更新
bool shouldForceUpdate = await checker.shouldForceUpdate();

// 檢查是否為 patch 更新
bool isPatchUpdate = await checker.isPatchUpdate();

// 獲取版本字串
String localVersion = await checker.getLocalVersionString();
String latestVersion = await checker.getLatestVersionString();
```

### VersionCheckWrapper
提供高層級的版本檢查功能：

```dart
// 應用啟動時檢查
await VersionCheckWrapper.checkVersionOnStartup(context);

// 手動檢查版本
await VersionCheckWrapper.manualVersionCheck(context);
```

### VersionUpdateDialog
美觀的更新對話框，支援：
- 強制更新模式（不可關閉）
- 建議更新模式（可選擇稍後再說）
- 自動打開應用商店

## 配置說明

### 1. 本地版本配置
在 `pubspec.yaml` 中設置：

```yaml
version: 0.0.1+1
```

### 2. 遠端版本配置

#### Firestore 方式（推薦）
在 Firestore 中創建文檔：
- 集合：`config`
- 文檔 ID：`app`
- 欄位：`latestVersion: "0.1.0"`

#### Remote Config 方式
在 Firebase Console 中設置：
- 參數名：`latest_version`
- 參數值：`0.1.0`

## 使用方式

### 1. 自動檢查
版本檢查已整合到 `main.dart` 中，應用啟動時會自動執行。

### 2. 手動檢查
在設定頁面中已添加「檢查更新」選項，用戶可以手動觸發版本檢查。

### 3. 自定義檢查
```dart
// 在任何地方調用
await VersionCheckWrapper.manualVersionCheck(context);
```

## 更新策略

### 強制更新（Major/Minor 變更）
- 當 `major` 或 `minor` 版本不同時觸發
- 顯示不可關閉的對話框
- 用戶必須更新才能繼續使用應用

### 建議更新（Patch 變更）
- 當只有 `patch` 版本不同時觸發
- 顯示可關閉的對話框
- 24小時內不會重複提示
- 用戶可以選擇稍後再說

## 錯誤處理

系統包含完善的錯誤處理：
- 網路連接失敗時不會阻止應用啟動
- 配置錯誤時會記錄日誌
- 版本解析失敗時有預設行為

## 自定義配置

### 修改冷卻期
在 `version_check_wrapper.dart` 中修改：

```dart
static const Duration _patchUpdateCooldown = Duration(days: 1);
```

### 修改應用商店 URL
在 `version_update_dialog.dart` 中修改：

```dart
String _getStoreUrl() {
  return 'https://play.google.com/store/apps/details?id=com.example.metro';
}
```

### 切換配置源
在 `version_checker.dart` 中修改：

```dart
// 使用 Firestore
final remoteVersion = await _getFirestoreVersion();

// 或使用 Remote Config
final remoteVersion = await _getRemoteConfigVersion();
```

## 測試建議

1. **設置測試環境**
   - 在 Firestore 中設置測試版本
   - 修改本地版本號進行測試

2. **測試場景**
   - 測試強制更新（修改 major/minor）
   - 測試建議更新（修改 patch）
   - 測試冷卻期功能
   - 測試錯誤處理

3. **生產環境部署**
   - 確保 Firestore 規則允許讀取
   - 設置正確的應用商店 URL
   - 配置 CI/CD 自動更新版本

## 依賴套件

- `package_info_plus`: 獲取本地版本資訊
- `pub_semver`: 語義化版本比較
- `cloud_firestore`: Firestore 配置讀取
- `firebase_remote_config`: Remote Config 支援
- `url_launcher`: 打開應用商店
- `shared_preferences`: 本地偏好設定存儲 