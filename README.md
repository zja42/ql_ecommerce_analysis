# 在线购物用户转化分析 · SQL + R

> 基于真实电商会话数据，用 SQL 完成转化漏斗、访客分群、流量来源与促销节点分析，并用 R 逻辑回归交叉验证，输出可落地的运营策略建议。

![License](https://img.shields.io/badge/license-MIT-green)
![SQL](https://img.shields.io/badge/SQL-SQLite-blue)
![R](https://img.shields.io/badge/R-statistics-orange)
![Dataset](https://img.shields.io/badge/dataset-UCI%20Online%20Shoppers-blueviolet)

## 目录
- [项目背景](#项目背景)
- [数据集](#数据集)
- [技术栈](#技术栈)
- [分析专题与结论](#分析专题与结论)
- [仓库结构](#仓库结构)
- [快速开始](#快速开始)
- [许可](#许可)

## 项目背景
电商平台的转化率是经营核心指标。本项目用一份真实电商会话数据集，从**用户分群、流量来源、页面价值、促销节点**四个角度拆解"谁在买、为什么不买、何时买"，把分析结果翻译成可执行的运营动作（拉新 vs 召回、渠道投放、促销排期）。

## 数据集
- **UCI Online Shoppers Purchasing Intention Dataset**
- 12,330 条会话 / 18 个字段
- 下载：https://archive.ics.uci.edu/dataset/468/online+shoppers+purchasing+intention+dataset
- 目标变量 `Revenue`（是否成交）

## 技术栈
- **SQLite** — SQL 分析（聚合 / 分群 / CASE 分桶 / CTE / 窗口函数）
- **R + glm** — 逻辑回归交叉验证（PageValues 为最强预测变量）

## 分析专题与结论

| # | 业务问题 | 数据结论 | 运营含义 |
|---|---|---|---|
| 1 | 整体转化率与淡旺季 | 整体约 15~16%；11 月（黑五）最高 | 促销窗口排期依据 |
| 2 | 新客 vs 老客谁更值钱 | 回访客转化率约为新客 2~3 倍 | 重点做老客召回，而非一味拉新 |
| 3 | 渠道质量如何 | 渠道转化率差异巨大 | 低转化高流量渠道是投放优化重点 |
| 4 | 成交会话的共同特征 | `PageValues` 是转化最强信号 | 高页面价值会话优先承接 |
| 5 | 促销 / 周末拉动多大 | 促销越近转化越高；周末略高于工作日 | 投放节奏与排期依据 |

> R 模型交叉验证：PageValues 是最强预测变量（p<2.3e-155），与 SQL 结论一致 —— **SQL + 统计建模双工具互证**。

## 仓库结构
```
├── README.md        # 项目说明（本文件）
├── 01_setup.sql     # 建表 + 数据导入
└── 02_analysis.sql  # 5 个专题 + 窗口函数进阶
```

## 快速开始
```bash
# 1. 建表 + 导入（详见 01_setup.sql 顶部 pandas 一行导入法）
sqlite3 shop.db < 01_setup.sql

# 2. 跑分析
sqlite3 shop.db < 02_analysis.sql
```
无 SQLite 客户端也可用 `01_setup.sql` 里的 pandas 片段在 Python 中导入。

## 许可
MIT © Zewen Jin
