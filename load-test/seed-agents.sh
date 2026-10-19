#!/bin/bash
# seed-agents.sh — 用户已在 init SQL 里，此脚本只做：登录拿token + API创建乘客
# 用法: ./seed-agents.sh [BASE_URL] [乘客数/用户]
set -e
BASE="${1:-${BASE:-http://<你的域名>}}"
N_PAX="${2:-200}"
python3 - "$BASE" "$N_PAX" <<'PYEOF'
import json, urllib.request, urllib.error, time, sys

base, n_pax = sys.argv[1], int(sys.argv[2])

def req(method, path, data=None, token=None, retry=3):
    headers = {"Content-Type": "application/json"}
    if token: headers["Authorization"] = token
    r = urllib.request.Request(base + path,
        data=json.dumps(data).encode() if data else None,
        headers=headers, method=method)
    for attempt in range(retry):
        try:
            with urllib.request.urlopen(r, timeout=15) as resp:
                return json.loads(resp.read())
        except urllib.error.HTTPError as e:
            return json.loads(e.read())
        except Exception as e:
            if attempt < retry - 1:
                time.sleep(2)
            else:
                print(f"RETRY_FAIL {path}: {e}")
                return {}

W = [7,9,10,5,8,4,2,1,6,3,7,9,10,5,8,4,2]
M = "10X98765432"
_seq = 0
def gen_idcard():
    global _seq
    _seq += 1
    day = (_seq // 1000) + 1  # 1-10，每 1000 个换一天
    serial = _seq % 1000       # 0-999
    birth = f"199001{day:02d}"  # 19900101-19900110
    body = "110101" + birth + f"{serial:03d}"  # 6+8+3=17
    return body + M[sum(int(c)*w for c,w in zip(body,W)) % 11]

# 预热
for _ in range(3):
    req("GET", "/api/ticket-service/ticket/query?fromStation=VNP&toStation=HGH&departureDate=2026-10-20")

users = []
for i in range(1, 51):
    u = f"agent{i:03d}"
    lg = req("POST", "/api/user-service/v1/login",
        {"usernameOrMailOrPhone": u, "password": "12345678"})
    tok = (lg.get("data") or {}).get("accessToken")
    if not tok:
        print(f"LOGIN_FAIL {u}")
        continue
    # 幂等：先查已有乘客，不足才补建（重复跑不会膨胀乘客池）
    # 首查偶发返回空（新鲜 token 竞态），带重试
    pids = []
    for _try in range(3):
        ql = req("GET", "/api/user-service/passenger/query", token=tok)
        pids = [str(p.get("id","")) for p in (ql.get("data") or []) if p.get("id")]
        if pids:
            break
        time.sleep(1)
    need = n_pax - len(pids)
    for j in range(1, need + 1):
        sv = req("POST", "/api/user-service/passenger/save", {
            "id": "", "realName": f"pax{i:03d}{j:03d}",
            "idType": 0, "idCard": gen_idcard(),
            "discountType": 0, "phone": f"158{i:04d}{j:04d}"},
            token=tok)
        if not sv.get("success") and j == 1:
            print(f"PAX_FAIL {u}: {sv.get('message')}")
            break
    if need > 0:
        ql = req("GET", "/api/user-service/passenger/query", token=tok)
        pids = [str(p.get("id","")) for p in (ql.get("data") or []) if p.get("id")]
    users.append({"username": u, "token": tok, "passengers": pids})
    print(f"[{i}/50] {u}: {len(pids)} pax")

json.dump(users, open("users.json", "w"), ensure_ascii=False)
print(f"\nDONE: {len(users)} agents, {sum(len(u['passengers']) for u in users)} passengers")
PYEOF
