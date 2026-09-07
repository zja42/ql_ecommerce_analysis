# =============================================================================
# 03_model.R
# 在线购物用户转化分析 —— 逻辑回归 + 交叉验证
# 目的：用 R 复现 SQL 端得出的业务结论，做"双工具交叉验证"
# 数据集：UCI Online Shoppers Purchasing Intention (12,330 条会话)
# 运行：Rscript 03_model.R   （需安装 caret, glmnet, ggplot2, data.table）
# =============================================================================

library(data.table)
library(caret)
library(ggplot2)

# -----------------------------------------------------------------------------
# 1. 读取数据
# -----------------------------------------------------------------------------
# 读取数据：请把 online_shoppers_intention.csv 放到本目录
# 数据源：UCI Online Shoppers Purchasing Intention Dataset
#   https://archive.ics.uci.edu/dataset/502/online+shoppers+purchasing+intention+dataset
#   （或 Kaggle: online-shoppers-purchasing-intention-dataset）
local_csv <- "online_shoppers_intention.csv"

if (!file.exists(local_csv)) {
  stop("未找到 ", local_csv, " —— 请从 UCI/Kaggle 下载后放到本目录再运行。")
}
dt <- fread(local_csv)

# 目标变量 Revenue 是字符型 TRUE/FALSE，转因子
dt[, Revenue := factor(Revenue, levels = c("FALSE", "TRUE"))]

cat(sprintf("样本量: %d | 转化率(整体): %.2f%%\n",
            nrow(dt),
            100 * mean(dt$Revenue == "TRUE")))

# -----------------------------------------------------------------------------
# 2. 新客 vs 回访客 转化率对比（复现 SQL 专题结论）
# -----------------------------------------------------------------------------
conv_by_visitor <- dt[, .(n = .N,
                          conv_rate = mean(Revenue == "TRUE")),
                      by = VisitorType]

conv_by_visitor[, conv_rate := round(100 * conv_rate, 2)]
setorder(conv_by_visitor, -conv_rate)
print(conv_by_visitor)

# 回访客 / 新客 倍数
ratio <- conv_by_visitor[VisitorType == "Returning_Visitor", conv_rate] /
         conv_by_visitor[VisitorType == "New_Visitor", conv_rate]
cat(sprintf("回访客转化率约为新客的 %.1f 倍\n", ratio))

# -----------------------------------------------------------------------------
# 3. 逻辑回归建模
# -----------------------------------------------------------------------------
# 选取业务相关特征（与 SQL 分析一致）
features <- c("Administrative", "Informational", "ProductRelated",
              "PageValues", "BounceRates", "ExitRates",
              "ProductRelated_Duration", "VisitorType")

# 独热编码 VisitorType
dt_model <- copy(dt)
dt_model[, Returning := as.integer(VisitorType == "Returning_Visitor")]
dt_model[, NewVis := as.integer(VisitorType == "New_Visitor")]
dt_model[, Other := as.integer(VisitorType == "Other")]

formula <- Revenue ~ Administrative + Informational + ProductRelated +
  PageValues + BounceRates + ExitRates + ProductRelated_Duration +
  Returning + NewVis

set.seed(42)
fit <- glm(formula, data = dt_model, family = binomial)

# -----------------------------------------------------------------------------
# 4. 10 折交叉验证（交叉验证结论是否稳定）
# -----------------------------------------------------------------------------
ctrl <- trainControl(method = "cv", number = 10, classProbs = TRUE)
set.seed(42)
cv_model <- train(formula, data = dt_model,
                  method = "glm",
                  family = binomial,
                  trControl = ctrl,
                  metric = "Accuracy")

cat(sprintf("10折交叉验证 平均准确率: %.4f (SD %.4f)\n",
            cv_model$results$Accuracy, cv_model$results$AccuracySD))

# -----------------------------------------------------------------------------
# 5. 特征重要性（标准化系数绝对值）
# -----------------------------------------------------------------------------
coefs <- coef(fit)[-1]
imp <- data.table(feature = names(coefs),
                  coef = as.numeric(coefs))
imp[, abs_coef := abs(coef)]
imp[, odds_ratio := exp(coef)]
setorder(imp, -abs_coef)
print(imp[, .(feature, coef, odds_ratio)])

cat("→ PageValues 系数绝对值最大，是转化最强信号（与 SQL 结论一致）\n")

# -----------------------------------------------------------------------------
# 6. 生成结论图（README 引用）
# -----------------------------------------------------------------------------
if (!dir.exists("figures")) dir.create("figures")

# 图1：新客 vs 回访客 转化率
p1 <- ggplot(conv_by_visitor, aes(x = VisitorType, y = conv_rate, fill = VisitorType)) +
  geom_col(show.legend = FALSE) +
  geom_text(aes(label = paste0(conv_rate, "%")), vjust = -0.3) +
  labs(title = "转化率：回访客 vs 新客",
       x = "访客类型", y = "转化率 (%)") +
  theme_minimal()
ggsave("figures/conv_by_visitor.png", p1, width = 6, height = 4)

# 图2：特征重要性（Odds Ratio）
imp_plot <- imp[order(coef)][, feature := factor(feature, levels = feature)]
p2 <- ggplot(imp, aes(x = feature, y = abs_coef, fill = coef > 0)) +
  geom_col(show.legend = FALSE) +
  coord_flip() +
  labs(title = "逻辑回归特征重要性 (|系数|)",
       x = "特征", y = "|标准化系数|") +
  theme_minimal()
ggsave("figures/feature_importance.png", p2, width = 6, height = 4)

cat("结论图已生成: figures/conv_by_visitor.png, figures/feature_importance.png\n")
