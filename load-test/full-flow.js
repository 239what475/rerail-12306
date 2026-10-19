import http from 'k6/http';
import { check, sleep } from 'k6';
import { Counter, Trend } from 'k6/metrics';
import { SharedArray } from 'k6/data';

// ReRail 全流程压测 v5：真实购买负载（2026-10-18 容量基线口径）
//
// 50 个代购账号，每个帮 200 个客户买票（乘客池 10,000 人，seed-agents.sh 幂等生成）
// 每次下单随机选车次（默认 54 车次池 = 4 基础 + 50 克隆，clone 数据依赖
// expand-inventory.sql —— 含 2026-10-18 补的价格表与站序 ORDER BY 修复）
//
// 用户行为模型：
//   70%  纯浏览（查票比价）
//   20%  完整购买（查票 → 下单 → 支付）   ← 支付紧跟成功下单（实测 99.6% 触发）
//   10%  查订单（回访）
//
// 压测口径：constant-arrival-rate，VU 上限 800（防 VU 螺旋污染延迟读数，增补4 方法论）
// 原始口径（1000/12000）见 full-flow.js
// 客户端超时 10s（与服务端「慢请求 >10s」观测口径一致）
//
// 基线结论（见 evidence/capacity-2026-10-18/）：真实购买负载下入口吞吐
// 平台期 ~680/s（ticket 单实例 Tomcat 200 线程，Little 定律吻合），
// 1500 与 3000 两档产出完全持平。

const users = new SharedArray('users', () => JSON.parse(open('./users.json')));
const BASE = __ENV.BASE || (__ENV.ENTRY_IP ? `http://${__ENV.ENTRY_IP}` : null);
if (!BASE) { throw new Error('必须设置 BASE（入口地址），如: BASE=http://<你的入口> k6 run full-flow.js'); }
const RATE = Number(__ENV.RATE || 5);
const DUR = __ENV.DUR || '60s';
// HOST_HEADER：直连 ALB 内网 IP 时模拟域名路由（Ingress 按 host 转发）
const HOST_HEADER = __ENV.HOST_HEADER || '';

function authHeaders(u, extra) {
  const h = { Authorization: u.token, ...(extra || {}) };
  if (HOST_HEADER) h.Host = HOST_HEADER;
  return h;
}
const TRAIN_POOL = (__ENV.TRAIN_POOL || '1,2,3,4,100,101,102,103,104,105,106,107,108,109,110,111,112,113,114,115,116,117,118,119,120,121,122,123,124,125,126,127,128,129,130,131,132,133,134,135,136,137,138,139,140,141,142,143,144,145,146,147,148,149').split(',');

const purchaseOk = new Counter('purchase_ok');
const purchaseFail = new Counter('purchase_fail');
const payCreateOk = new Counter('pay_create_ok');
const payCreateFail = new Counter('pay_create_fail');

export const options = {
  discardResponseBodies: false,
  scenarios: {
    mixed: {
      executor: 'constant-arrival-rate',
      rate: RATE,
      timeUnit: '1s',
      duration: DUR,
      preAllocatedVUs: 800,
      maxVUs: 800,
      gracefulStop: '10s',
    },
  },
};

function pickTrain() {
  return TRAIN_POOL[Math.floor(Math.random() * TRAIN_POOL.length)];
}

function pickPassenger(u) {
  return u.passengers[Math.floor(Math.random() * u.passengers.length)];
}

function browse(u) {
  const res = http.get(
    `${BASE}/api/ticket-service/ticket/query?fromStation=VNP&toStation=HGH&departureDate=2026-10-20`,
    { tags: { api: 'browse' }, timeout: '10s', headers: authHeaders(u) }
  );
  check(res, { 'browse 200': (r) => r.status === 200 });
}

function purchaseAndPay(u, trainId) {
  // Step 1: 下单
  const res = http.post(
    `${BASE}/api/ticket-service/ticket/purchase/v2`,
    JSON.stringify({
      trainId: trainId,
      passengers: [{ passengerId: pickPassenger(u), seatType: 2 }],
      chooseSeats: [],
      departure: '北京南',
      arrival: '杭州东',
    }),
    {
      headers: authHeaders(u, { 'Content-Type': 'application/json' }),
      tags: { api: 'purchase' },
      timeout: '10s',
    }
  );
  if (!check(res, { 'purchase 200': (r) => r.status === 200 })) {
    purchaseFail.add(1);
    return;
  }
  try {
    const body = res.json();
    if (!body.success || !body.data || !body.data.orderSn) {
      purchaseFail.add(1);
      return;
    }
    purchaseOk.add(1);
    const orderSn = body.data.orderSn;
    const amount = body.data.ticketOrderDetails[0].amount;

    // Step 2: 支付
    sleep(0.05); // 模拟用户跳转支付页的间隔
    const payRes = http.post(
      `${BASE}/api/pay-service/pay/create`,
      JSON.stringify({
        orderSn: orderSn,
        outOrderSn: orderSn,
        channel: 0,
        tradeType: 0,
        totalAmount: amount / 100,
        subject: 'ReRail load test',
      }),
      {
        headers: authHeaders(u, { 'Content-Type': 'application/json' }),
        tags: { api: 'pay' },
        timeout: '10s',
      }
    );
    if (check(payRes, { 'pay 200': (r) => r.status === 200 })) {
      payCreateOk.add(1);
    } else {
      payCreateFail.add(1);
    }
  } catch (e) {
    purchaseFail.add(1);
  }
}

function checkOrders(u) {
  const res = http.get(
    `${BASE}/api/order-service/order/ticket/self/page?current=1&size=10`,
    { headers: authHeaders(u), tags: { api: 'order' }, timeout: '10s' }
  );
  check(res, { 'order 200': (r) => r.status === 200 });
}

export default function () {
  const u = users[(__VU - 1) % users.length];
  const r = Math.random();

  if (r < 0.70) {
    browse(u);
    sleep(0.2);
  } else if (r < 0.90) {
    browse(u);
    sleep(0.1);
    purchaseAndPay(u, pickTrain());
    sleep(0.2);
  } else {
    checkOrders(u);
    sleep(0.2);
  }
}
