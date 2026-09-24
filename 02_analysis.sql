-- ============================================================
-- 02_analysis.sql — 5 个业务专题 + 窗口函数进阶
-- 每条 SQL 都要能说出一句「业务结论」
-- ============================================================

-- 专题 1：整体转化率与月度趋势
-- 业务问题：整体购买转化率是多少？有没有淡旺季？
SELECT
    COUNT(*)                                          AS total_sessions,
    SUM(Revenue)                                      AS purchase_sessions,
    ROUND(SUM(Revenue) * 100.0 / COUNT(*), 2)         AS conversion_rate_pct
FROM online_shoppers;

SELECT
    Month,
    COUNT(*)                                          AS sessions,
    SUM(Revenue)                                      AS purchases,
    ROUND(SUM(Revenue) * 100.0 / COUNT(*), 2)         AS conversion_rate_pct
FROM online_shoppers
GROUP BY Month
ORDER BY CASE Month
    WHEN 'Feb' THEN 1 WHEN 'Mar' THEN 2 WHEN 'May' THEN 3
    WHEN 'June' THEN 4 WHEN 'Jul' THEN 5 WHEN 'Aug' THEN 6
    WHEN 'Sep' THEN 7 WHEN 'Oct' THEN 8 WHEN 'Nov' THEN 9
    WHEN 'Dec' THEN 10 END;
-- 全量数据：整体转化率 15.47%；11 月 25.35%，为样本中最高。
-- 月份差异是描述性观察，不能单凭此查询归因于黑五。

-- 专题 2：访客分群 —— 新访客 vs 回访访客的会话转化
-- 业务问题：两类会话的转化率和成交量各是多少？
SELECT
    VisitorType,
    COUNT(*)                                          AS sessions,
    SUM(Revenue)                                      AS purchases,
    ROUND(SUM(Revenue) * 100.0 / COUNT(*), 2)         AS conversion_rate_pct,
    ROUND(AVG(PageValues), 2)                         AS avg_page_value
FROM online_shoppers
GROUP BY VisitorType
ORDER BY conversion_rate_pct DESC;
-- 全量数据：新访客 422/1694 = 24.91%；回访访客 1470/10551 = 13.93%。
-- 回访访客贡献更多成交会话，但该标签不等于曾购买的老客户。

-- 专题 3：流量来源质量分析
-- 业务问题：哪些渠道转化最好？哪些是「只看不买」的低质流量？
SELECT
    TrafficType,
    COUNT(*)                                          AS sessions,
    SUM(Revenue)                                      AS purchases,
    ROUND(SUM(Revenue) * 100.0 / COUNT(*), 2)         AS conversion_rate_pct
FROM online_shoppers
GROUP BY TrafficType
HAVING COUNT(*) >= 50
ORDER BY conversion_rate_pct DESC;
-- 结论：渠道转化率差异巨大；低转化高流量渠道是投放优化重点

-- 专题 4：高价值会话画像（分桶分析）
-- 业务问题：成交会话有什么共同特征？
SELECT
    CASE
        WHEN PageValues = 0 THEN '0（无价值）'
        WHEN PageValues < 10 THEN '0-10（不含 0）'
        WHEN PageValues < 50 THEN '10-50'
        ELSE '50+（高价值）'
    END                                               AS page_value_bucket,
    COUNT(*)                                          AS sessions,
    SUM(Revenue)                                      AS purchases,
    ROUND(SUM(Revenue) * 100.0 / COUNT(*), 2)         AS conversion_rate_pct
FROM online_shoppers
GROUP BY page_value_bucket
ORDER BY conversion_rate_pct DESC;

SELECT
    CASE
        WHEN BounceRates < 0.01 THEN '低跳出(<1%)'
        WHEN BounceRates < 0.05 THEN '中跳出(1-5%)'
        ELSE '高跳出(>=5%)'
    END                                               AS bounce_bucket,
    COUNT(*)                                          AS sessions,
    ROUND(SUM(Revenue) * 100.0 / COUNT(*), 2)         AS conversion_rate_pct
FROM online_shoppers
GROUP BY bounce_bucket
ORDER BY conversion_rate_pct DESC;
-- PageValues = 0：370/9600 = 3.85%；PageValues >= 50：331/408 = 81.13%。
-- 这是相关性；上线前须确认 PageValues 在预测时已可用。

-- 专题 5：促销节点与周末效应
-- 业务问题：促销日和周末对转化的拉动有多大？
SELECT
    Weekend,
    COUNT(*)                                          AS sessions,
    SUM(Revenue)                                      AS purchases,
    ROUND(SUM(Revenue) * 100.0 / COUNT(*), 2)         AS conversion_rate_pct
FROM online_shoppers
GROUP BY Weekend;

SELECT
    CASE
        WHEN SpecialDay = 0 THEN 'SpecialDay = 0'
        WHEN SpecialDay < 0.4 THEN '0 < SpecialDay < 0.4'
        WHEN SpecialDay < 0.8 THEN '0.4 <= SpecialDay < 0.8'
        ELSE 'SpecialDay >= 0.8'
    END                                               AS special_day_bucket,
    COUNT(*)                                          AS sessions,
    SUM(Revenue)                                      AS purchases,
    ROUND(SUM(Revenue) * 100.0 / COUNT(*), 2)         AS conversion_rate_pct
FROM online_shoppers
GROUP BY special_day_bucket
ORDER BY conversion_rate_pct DESC;
-- 特殊日：SpecialDay = 0 为 16.53%，>= 0.8 为 4.38%；不支持“越近越高”。
-- 周末 17.40%，工作日 14.89%；均为描述性结果，非因果效果。

-- 进阶：窗口函数（展示 SQL 深度，面试加分项）
-- 用 CTE + 窗口函数给各渠道转化率排名
WITH channel_stats AS (
    SELECT
        TrafficType,
        COUNT(*)                                      AS sessions,
        ROUND(SUM(Revenue) * 100.0 / COUNT(*), 2)     AS conversion_rate_pct
    FROM online_shoppers
    GROUP BY TrafficType
)
SELECT
    TrafficType,
    sessions,
    conversion_rate_pct,
    RANK() OVER (ORDER BY conversion_rate_pct DESC)   AS conv_rank
FROM channel_stats;
