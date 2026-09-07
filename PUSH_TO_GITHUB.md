# 直接推送到 GitHub 的步骤

## 前提
- GitHub 仓库已建：`zja42/sql-ecommerce-analysis`（空仓库，Public）
- 本机已安装 Git

## 1. 清空并解压
在任意位置新建空文件夹，把 `sql_ecommerce_analysis.zip` 解压进去。

> 不要解压到已经有 README.md 的目录，否则会产生 `README(1).md` 这种重复文件。

解压后结构应为：

```
sql_ecommerce_analysis/
├── README.md
├── 01_setup.sql
├── 02_analysis.sql
├── 03_model.R
├── LICENSE
├── PUSH_TO_GITHUB.md
└── figures/
    └── key_findings.svg
```

## 2. 初始化并推送

```bash
# 进入解压后的目录
cd sql_ecommerce_analysis

# 初始化仓库
git init

# 添加所有文件
git add .

# 提交
git commit -m "init: SQL + R ecommerce conversion analysis"

# 关联远程仓库（换成你自己的用户名和仓库名）
git remote add origin https://github.com/zja42/sql-ecommerce-analysis.git

# 推送
git branch -M main
git push -u origin main
```

## 3. 网申链接
推送成功后，把下面链接贴到网申「项目链接」栏：

```
https://github.com/zja42/sql-ecommerce-analysis
```

## 4. 跑 R 脚本（可选，用于出真实数字图）

1. 从 UCI 下载 `online_shoppers_intention.csv`：
   https://archive.ics.uci.edu/dataset/502/online+shoppers+purchasing+intention+dataset
2. 把 csv 放到仓库根目录（和 `03_model.R` 同级）
3. 运行：
   ```bash
   Rscript 03_model.R
   ```
4. 生成的图在 `figures/` 下，README 会自动显示。
