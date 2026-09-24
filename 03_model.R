# =============================================================================
# 03_model.R
# 在线购物用户转化分析 —— 全量数据的辅助 R 分析
# 本脚本复核访客分组并演示普通逻辑回归；final report 的检验在独立 notebook 中。
# 数据集：UCI Online Shoppers Purchasing Intention (12,330 条会话)
# 运行：Rscript 03_model.R   （需安装 caret, ggplot2, data.table）
# =============================================================================

library(data.table)
library(caret)
library(ggplot2)

# -----------------------------------------------------------------------------
# 1. 读取数据
# -----------------------------------------------------------------------------
# 读取数据：请把 online_shoppers_intention.csv 放到本目录
# 数据源：UCI Online Shoppers Purchasing Intention Dataset
#   https://archive.ics.uci.edu/dataset/468/online+shoppers+purchasing+intention+dataset
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

# 新访客 / 回访客倍数；使用未四舍五入的比例计算。
new_rate <- mean(dt[VisitorType == "New_Visitor", Revenue == "TRUE"])
returning_rate <- mean(dt[VisitorType == "Returning_Visitor", Revenue == "TRUE"])
cat(sprintf("新访客 %.2f%%，回访访客 %.2f%%；新访客约为回访访客的 %.2f 倍\n",
            100 * new_rate, 100 * returning_rate, new_rate / returning_rate))

# -----------------------------------------------------------------------------
# 3. 逻辑回归建模
# -----------------------------------------------------------------------------
# 独热编码 VisitorType
dt_model <- copy(dt)
dt_model[, Returning := as.integer(VisitorType == "Returning_Visitor")]
dt_model[, NewVis := as.integer(VisitorType == "New_Visitor")]

formula <- Revenue ~ Administrative + Informational + ProductRelated +
  PageValues + BounceRates + ExitRates + ProductRelated_Duration +
  Returning + NewVis

set.seed(42)
fit <- glm(formula, data = dt_model, family = binomial)

# -----------------------------------------------------------------------------
# 4. 10 折交叉验证：仅作本脚本的准确率演示，不是 final report 的 AUC
# -----------------------------------------------------------------------------
ctrl <- trainControl(method = "cv", number = 10, classProbs = FALSE)
set.seed(42)
cv_model <- train(formula, data = dt_model,
                  method = "glm",
                  family = binomial,
                  trControl = ctrl,
                  metric = "Accuracy")

cat(sprintf("10折交叉验证 平均准确率: %.4f (SD %.4f)\n",
            cv_model$results$Accuracy, cv_model$results$AccuracySD))

# -----------------------------------------------------------------------------
# 5. 原始系数检查：变量量纲不同，绝对值不能直接用于重要性排名
# -----------------------------------------------------------------------------
coefs <- coef(fit)[-1]
imp <- data.table(feature = names(coefs),
                  coef = as.numeric(coefs))
imp[, abs_coef := abs(coef)]
imp[, odds_ratio := exp(coef)]
setorder(imp, -abs_coef)
print(imp[, .(feature, coef, odds_ratio)])

cat("系数基于不同量纲；请结合变量定义解读，勿将其绝对值当作重要性排名。\n")

# -----------------------------------------------------------------------------
# 6. 生成结论图（README 引用）
# -----------------------------------------------------------------------------
if (!dir.exists("figures")) dir.create("figures")

# 图1：新客 vs 回访客 转化率
p1 <- ggplot(conv_by_visitor, aes(x = VisitorType, y = conv_rate, fill = VisitorType)) +
  geom_col(show.legend = FALSE) +
  geom_text(aes(label = paste0(conv_rate, "%")), vjust = -0.3) +
  labs(title = "会话转化率：新访客 vs 回访访客",
       x = "访客类型", y = "转化率 (%)") +
  theme_minimal()
ggsave("figures/conv_by_visitor.png", p1, width = 6, height = 4)

# 图2：原始系数绝对值（仅用于模型检查）
imp_plot <- imp[order(coef)][, feature := factor(feature, levels = feature)]
p2 <- ggplot(imp, aes(x = feature, y = abs_coef, fill = coef > 0)) +
  geom_col(show.legend = FALSE) +
  coord_flip() +
  labs(title = "逻辑回归原始系数绝对值（未标准化）",
       x = "特征", y = "|标准化系数|") +
  theme_minimal()
ggsave("figures/coefficient_magnitudes.png", p2, width = 6, height = 4)

cat("图已生成: figures/conv_by_visitor.png, figures/coefficient_magnitudes.png\n")
