USE 12306_ticket;
-- ReRail 库存扩容 v2：修正列名
CREATE TEMPORARY TABLE IF NOT EXISTS nums (n INT PRIMARY KEY);
TRUNCATE nums;
INSERT INTO nums VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9),
(10),(11),(12),(13),(14),(15),(16),(17),(18),(19),
(20),(21),(22),(23),(24),(25),(26),(27),(28),(29),
(30),(31),(32),(33),(34),(35),(36),(37),(38),(39),
(40),(41),(42),(43),(44),(45),(46),(47),(48),(49);

-- 1. t_train
INSERT INTO t_train (id, train_number, train_type, train_tag, train_brand,
  start_station, end_station, start_region, end_region,
  sale_time, sale_status, departure_time, arrival_time, create_time, update_time, del_flag)
SELECT
  100 + n.n, CONCAT('G', 100 + n.n),
  t.train_type, t.train_tag, t.train_brand,
  t.start_station, t.end_station, t.start_region, t.end_region,
  t.sale_time, 0, t.departure_time, t.arrival_time, NOW(), NOW(), 0
FROM t_train t CROSS JOIN nums n WHERE t.id = 1;

-- 2. t_train_station（列名不同：有 station_id, stopover_time）
--    ORDER BY 必须保留：载体 purchase 校验的 loader SELECT 无 ORDER BY，靠行的主键序返回；
--    CROSS JOIN 默认顺序是倒的 → 倒序站序被 Redis 缓存(数天TTL) → indexOf 校验必败
--    报「列车车站数据错误」（2026-10-18 排障实录）
INSERT INTO t_train_station (train_id, station_id, sequence, departure, arrival,
  start_region, end_region, arrival_time, departure_time, stopover_time,
  create_time, update_time, del_flag)
SELECT
  100 + n.n, ts.station_id, ts.sequence, ts.departure, ts.arrival,
  ts.start_region, ts.end_region, ts.arrival_time, ts.departure_time, ts.stopover_time,
  NOW(), NOW(), 0
FROM t_train_station ts CROSS JOIN nums n WHERE ts.train_id = 1
ORDER BY n.n, CAST(ts.sequence AS UNSIGNED);

-- 3. t_train_station_relation（departure_flag/arrival_flag 在这张表）
INSERT INTO t_train_station_relation (train_id, departure, arrival,
  start_region, end_region, departure_flag, arrival_flag,
  departure_time, arrival_time,
  create_time, update_time, del_flag)
SELECT
  100 + n.n, tsr.departure, tsr.arrival,
  tsr.start_region, tsr.end_region, tsr.departure_flag, tsr.arrival_flag,
  tsr.departure_time, tsr.arrival_time,
  NOW(), NOW(), 0
FROM t_train_station_relation tsr CROSS JOIN nums n WHERE tsr.train_id = 1;

-- 4. t_carriage
INSERT INTO t_carriage (train_id, carriage_number, carriage_type, seat_count,
  create_time, update_time, del_flag)
SELECT
  100 + n.n, c.carriage_number, c.carriage_type, c.seat_count,
  NOW(), NOW(), 0
FROM t_carriage c CROSS JOIN nums n WHERE c.train_id = 1;

-- 5. t_seat（全部可用）
INSERT INTO t_seat (train_id, carriage_number, seat_number, seat_type,
  start_station, end_station, price, seat_status,
  create_time, update_time, del_flag)
SELECT
  100 + n.n, s.carriage_number, s.seat_number, s.seat_type,
  s.start_station, s.end_station, s.price, 0,
  NOW(), NOW(), 0
FROM t_seat s CROSS JOIN nums n WHERE s.train_id = 1;

-- 6. t_train_station_price（2026-10-18 补漏）
--    当年漏克隆此表：购买 v2 计算票价查不到分段价格 → A000001「列车车站数据错误」
--    （错误文案极具误导性——t_train/t_train_station 逐列对比完全一致，真因是价格表为空，
--     导致 92.6% 打到 clone 车次的购买毫秒级失败、pay 流量近乎为零）
INSERT INTO t_train_station_price (train_id, departure, arrival, seat_type, price,
  create_time, update_time, del_flag)
SELECT
  100 + n.n, p.departure, p.arrival, p.seat_type, p.price,
  NOW(), NOW(), 0
FROM t_train_station_price p CROSS JOIN nums n
WHERE p.train_id = 1
  AND NOT EXISTS (SELECT 1 FROM (SELECT 1 FROM t_train_station_price WHERE train_id = 100 + n.n LIMIT 1) guard);

-- 验证
SELECT '新增车次' as item, COUNT(*) as cnt FROM t_train WHERE id >= 100
UNION ALL SELECT '新增车站', COUNT(*) FROM t_train_station WHERE train_id >= 100
UNION ALL SELECT '新增路段', COUNT(*) FROM t_train_station_relation WHERE train_id >= 100
UNION ALL SELECT '新增车厢', COUNT(*) FROM t_carriage WHERE train_id >= 100
UNION ALL SELECT '新增座位', COUNT(*) FROM t_seat WHERE train_id >= 100
UNION ALL SELECT '新增价格', COUNT(*) FROM t_train_station_price WHERE train_id >= 100
UNION ALL SELECT '总可用座位', COUNT(*) FROM t_seat WHERE seat_status = 0;
