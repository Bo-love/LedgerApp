# 记账本 iOS App — 使用说明

## 文件清单

| 文件 | 说明 |
|------|------|
| `main.m` | 程序入口 |
| `LedgerAppDelegate.h/m` | AppDelegate，初始化 TabBar 根控制器 |
| `LedgerRecord.h/m` | 数据模型（支持 NSCoding 归档） |
| `LedgerStore.h/m` | 本地存储（NSUserDefaults + NSKeyedArchiver），首次启动自动写入示例数据 |
| `LedgerRootViewController.h/m` | TabBar 根控制器，包含四个 Tab |
| `LedgerDayViewController.h/m` | 日记账（按日/周浏览，左滑删除，点击编辑） |
| `LedgerMonthViewController.h/m` | 月汇总（分类支出统计 + 月度明细） |
| `LedgerYearViewController.h/m` | 年报表（12个月卡片，点击跳转月汇总） |
| `LedgerStatsViewController.h/m` | 统计分析（环形饼图 + 分类排行，纯 UIKit 无第三方库） |
| `LedgerAddViewController.h/m` | 添加/编辑记录弹窗 |
| `Makefile` | Theos 编译配置 |
| `Info.plist` | App 基本信息 |
| `ents.plist` | 签名 entitlements |

## 功能

- **日记账**：按日/周切换，左右翻页，收支三栏汇总，左滑删除，点击行编辑
- **月汇总**：月度收支总额，支出分类占比列表，完整月度明细
- **年报表**：12 个月卡片（含进度条），点击跳转对应月汇总
- **统计分析**：环形饼图（纯 Core Graphics，无第三方），分类金额排行，支持年份切换和收/支类型切换
- **添加记录**：支出（10类）/ 收入（6类），UIDatePicker 选日期，金额验证
- **本地存储**：NSUserDefaults + NSKeyedArchiver，数据完全本地，无需联网

## 编译步骤（Theos 环境）

```bash
# 在越狱设备 / Theos 编译机上执行
cd /path/to/LedgerApp

# 编译并安装到已连接设备
make package install

# 仅生成 IPA
make package
# IPA 位于 packages/ 目录
```

## 修改 Bundle ID

编辑 `Info.plist` 和 `ents.plist` 中的 `com.yourname.ledger`，改为自己的 Bundle ID。

## 最低系统要求

iOS 13.0+，arm64

## 分类说明

**支出分类（10类）**：餐饮 🍜 · 购物 🛍 · 交通 🚌 · 住房 🏠 · 医疗 💊 · 娱乐 🎮 · 教育 📚 · 美容 💄 · 礼物 🎁 · 其他 📦

**收入分类（6类）**：工资 💰 · 奖金 🎉 · 投资 📈 · 兼职 💼 · 租金 🏘 · 其他 💵
