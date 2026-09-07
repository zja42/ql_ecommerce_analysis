-- ============================================================
-- 01_setup.sql — 建表 + 导入数据
-- 数据库：SQLite（最快跑通，重点在 SQL 熟练度）
-- ============================================================

-- 1) 建表
CREATE TABLE IF NOT EXISTS online_shoppers (
    id INT PRIMARY KEY,
    Administrative INT,
    Administrative_Duration DECIMAL(10,2),
    Informational INT,
    Informational_Duration DECIMAL(10,2),
    ProductRelated INT,
    ProductRelated_Duration DECIMAL(10,2),
    BounceRates DECIMAL(6,4),
    ExitRates DECIMAL(6,4),
    PageValues DECIMAL(10,2),
    SpecialDay DECIMAL(4,2),
    Month VARCHAR(10),
    OperatingSystems INT,
    Browser INT,
    Region INT,
    TrafficType INT,
    VisitorType VARCHAR(20),
    Weekend TINYINT,
    Revenue TINYINT
);

-- 2) 导入数据
-- 下载 online_shoppers_intention.csv 后，用 Python 一行导入：
--
--   import pandas as pd
--   import sqlite3
--   df = pd.read_csv("online_shoppers_intention.csv")
--   df.insert(0, "id", range(1, len(df) + 1))   -- 补自增主键
--   con = sqlite3.connect("shop.db")
--   df.to_sql("online_shoppers", con, if_exists="append", index=False)
--
-- 或用 SQLite 自带 .import（注意首列 id 需先生成）。

-- 3) 校验
-- SELECT COUNT(*) FROM online_shoppers;   -- 应返回 12330
