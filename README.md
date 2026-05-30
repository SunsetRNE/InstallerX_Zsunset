
# InstallerX Zsunset

> 暮雨连秋冬 · 模块版  
> 基于 [wxxsfxyzm/InstallerX-Revived](https://github.com/wxxsfxyzm/InstallerX-Revived) 项目，提供精准替换系统安装器的 Magisk/KernelSU/APatch 模块方案（不开发安装器 App 本体，仅提供模块化替换框架）

---

## 📌 简介

**InstallerX Zsunset** 是一个 Magisk / KernelSU / APatch 模块，用于替换 Android 系统内置的包安装器（PackageInstaller），实现系统安装器的精准替换。支持 AOSP、Google、MIUI/HyperOS 等多系统变体，提供在线/离线双版本选择。

---

## ✨ 功能特性

- **多系统兼容** — 自动检测 ROM 类型（AOSP / Google / MIUI / HyperOS / ColorOS / OneUI 等）
- **在线/离线双版本** — 安装时通过音量键选择在线版或离线版安装器
- **多 Root 管理器支持** — Magisk / KernelSU / APatch 全兼容
- **双引擎驱动**：
  - `fix` 引擎 — 通过 Magisk replace 机制替换，适合已有 Meta 模块环境
  - `bind` 引擎 — 通过 bind mount 运行时挂载，适合 KernelSU / APatch
- **防回退守卫** — 防止系统 OTA 更新后安装器被还原
- **快速更新通道** — 支持 `/data/local/installerx_update/` 快速更新 APK
- **三阶段图标修复** — 安装时 / post-fs-data / 开机后三重修复桌面图标
- **桌面图标隐藏/恢复** — 安装器 App 内可设置隐藏图标，拨号盘输入 `*#*#46789#*#*` 恢复
- **安装器 App 多语言支持** — 中文 / English / Русский

---

## 📋 系统要求

| 项目 | 要求 |
|:-----|:------|
| Android | 8.0 (API 26) 及以上 |
| Root | Magisk 20.4+ / KernelSU / APatch |
| 架构 | arm64 / arm / x86_64 |

---

## 🔧 安装方法

### 方式一：Magisk Manager / KernelSU Manager / APatch 直接刷入

1. 下载 `InstallerX_Zsunset.zip`
2. 在 Manager 中刷入模块
3. 重启手机

### 方式二：音量键选择变体

1. 刷入模块后，重启过程中会出现音量键选择界面
2. **音量上键** — 选择在线版（Online）
3. **音量下键** — 选择离线版（Offline）
4. 等待 5 秒无操作则默认选择离线版

### 方式三：快速更新（无需重启）

将更新后的 APK 放入 `/data/local/installerx_update/` 目录，模块会在下次 post-fs-data 阶段自动检测并应用更新。

---

## 🚀 使用方法

### 启动安装器

- **桌面图标**：点击桌面上的安装器图标
- **暗码启动**：拨号盘输入 `*#*#46789#*#*`
- **Action 按钮**：在 Magisk Manager 模块列表中点击 Action 按钮

### 隐藏桌面图标

在安装器 App 设置中开启「隐藏桌面图标」，图标将从桌面消失。可通过暗码或系统设置中的应用详情页重新打开。

---

## 📦 模块结构

```
InstallerX_Zsunset/
├── action.sh                          # Action 按钮启动脚本
├── common.sh                          # 共享函数库
├── customize.sh                       # 安装配置主脚本
├── post-fs-data.sh                    # 早期启动脚本（快速更新 + 防回退 + bind mount）
├── service.sh                         # 开机后脚本（挂载验证 + 图标修复）
├── uninstall.sh                       # 卸载清理脚本
├── module.prop                        # 模块属性
├── launcher.png                       # 模块图标
├── bin/
│   └── keycheck                       # 音量键检测工具
├── files/
│   ├── AndroidPackageInstaller.apk         # AOSP 离线版
│   ├── AndroidPackageInstaller_online.apk  # AOSP 在线版
│   ├── GooglePackageInstaller.apk          # Google 离线版
│   └── GooglePackageInstaller_online.apk   # Google 在线版
└── META-INF/
    └── com/google/android/
        ├── update-binary
        └── updater-script
```

---

## ⚙️ 引擎说明

| 引擎 | 适用场景 | 原理 |
|:-----|:---------|:------|
| `fix` | Magisk + Meta 模块环境 | 通过 `.replace` 文件 + Magisk overlay 机制替换原安装器 |
| `bind` | KernelSU / APatch / 无 Meta 模块 | 通过 `mount --bind` 在运行时挂载替换 |

模块会自动检测环境并选择合适的引擎，也可以手动配置。

---

## 🔄 更新日志

### v26.05.01

- 初始模块版本
- 基于 InstallerX-Revived 26.05.01 模块化方案
- 新增 post-fs-data 快速更新检测
- 新增防回退守卫机制
- 新增三阶段图标修复
- 引擎选择逻辑优化
- 优化卸载脚本

---

## 🙏 致谢

- [wxxsfxyzm/InstallerX-Revived](https://github.com/wxxsfxyzm/InstallerX-Revived) — 原版项目
- [funbox](https://github.com/funbox) — keycheck 音量键检测方案
- Magisk / KernelSU / APatch 开发团队

---

## 📄 许可

无许可证（No License），保留所有权利，仅供学习参考。