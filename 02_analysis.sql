

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
-- 结论：整体转化约 15~16%；11 月（黑五）最高 → 促销窗口依据

-- 专题 2：访客分群 —— 新客 vs 老客价值对比
-- 业务问题：新访客和回访访客，谁更值钱？
SELECT
    VisitorType,
    COUNT(*)                                          AS sessions,
    SUM(Revenue)                                      AS purchases,
    ROUND(SUM(Revenue) * 100.0 / COUNT(*), 2)         AS conversion_rate_pct,
    ROUND(AVG(PageValues), 2)                         AS avg_page_value
FROM online_shoppers
GROUP BY VisitorType
ORDER BY conversion_rate_pct DESC;
-- 结论：回访客转化率约为新客 2~3 倍 → 运营应重点做老客召回

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

-- 专题 4：高价值会话画像
-- 业务问题：成交会话有什么共同特征？
SELECT
    CASE
        WHEN PageValues = 0 THEN '0（无价值）'
        WHEN PageValues < 10 THEN '1-10'
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
        ELSE '高跳出(>5%)'
    END                                               AS bounce_bucket,
    COUNT(*)                                          AS sessions,
    ROUND(SUM(Revenue) * 100.0 / COUNT(*), 2)         AS conversion_rate_pct
FROM online_shoppers
GROUP BY bounce_bucket
ORDER BY conversion_rate_pct DESC;
-- 结论：PageValues 是转化最强信号（高价值会话转化近 100%）

-- 专题 5：促销节点与周末效应
-- 业务问题：促销日和周末对转化的拉动有多大？
SELECT
    Weekend,
    COUNT(*)                                          AS sessions,
    ROUND(SUM(Revenue) * 100.0 / COUNT(*), 2)         AS conversion_rate_pct
FROM online_shoppers
GROUP BY Weekend;

SELECT
    CASE
        WHEN SpecialDay = 0 THEN '无促销'
        WHEN SpecialDay < 0.4 THEN '促销前(远)'
        WHEN SpecialDay < 0.8 THEN '促销前(近)'
        ELSE '促销当天附近'
    END                                               AS special_day_bucket,
    COUNT(*)                                          AS sessions,
    ROUND(SUM(Revenue) * 100.0 / COUNT(*), 2)         AS conversion_rate_pct
FROM online_shoppers
GROUP BY special_day_bucket
ORDER BY conversion_rate_pct DESC;
-- 结论：促销日越近转化越高，周末略高于工作日 → 排期依据

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
