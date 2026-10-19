#!/usr/bin/env python3
"""生成 07-seed-loadtest.sql：50个代购用户（乘客通过API创建，因ShardingSphere加密）"""
def java_hash(s):
    h = 0
    for c in s:
        h = (31 * h + ord(c)) & 0xFFFFFFFF
    if h >= 0x80000000:
        h -= 0x100000000
    return h

def shard(username):
    h = abs(java_hash(username))
    v = h % 32
    return v // 16, v

W = [7,9,10,5,8,4,2,1,6,3,7,9,10,5,8,4,2]
M = "10X98765432"
_seq = 0
def gen_idcard():
    global _seq
    _seq += 1
    body = "110101" + "19900101" + f"{_seq:03d}"
    return body + M[sum(int(c)*w for c,w in zip(body,W)) % 11]

N_AGENTS = 50
PASSWORD = "12345678"

user_sql = {}
for i in range(1, N_AGENTS + 1):
    uname = f"agent{i:03d}"
    db, tbl = shard(uname)
    uid = 3000000000000000000 + i
    user_sql.setdefault((db, tbl), []).append(
        f"({uid},'{uname}','{PASSWORD}','agent{i:03d}','0',0,'{gen_idcard()}','159{i:08d}','','agent{i:03d}@rerail.dev',0,1,'','',NOW(),NOW(),0)"
    )

lines = []
lines.append("-- 幂等清理")
for tbl in range(16):
    lines.append(f"DELETE IGNORE FROM `12306_user_0`.`t_user_{tbl}` WHERE `id` >= 3000000000000000000;")
for tbl in range(16, 32):
    lines.append(f"DELETE IGNORE FROM `12306_user_1`.`t_user_{tbl}` WHERE `id` >= 3000000000000000000;")
lines.append("")
for (db, tbl), rows in sorted(user_sql.items()):
    lines.append(f"INSERT INTO `12306_user_{db}`.`t_user_{tbl}` (`id`,`username`,`password`,`real_name`,`region`,`id_type`,`id_card`,`phone`,`telephone`,`mail`,`user_type`,`verify_status`,`post_code`,`address`,`create_time`,`update_time`,`del_flag`) VALUES")
    lines.append(",\n".join(rows) + ";")
    lines.append("")
lines.append(f"-- {N_AGENTS} agents (passengers via API due to ShardingSphere encryption)")
print("\n".join(lines))
