CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ── 사용자 ──────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS users (
  id           SERIAL PRIMARY KEY,
  username     VARCHAR(50)  UNIQUE NOT NULL,
  display_name VARCHAR(100) NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  created_at   TIMESTAMPTZ DEFAULT NOW()
);

-- ── 포트폴리오 보유 종목 ─────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS investments (
  id          SERIAL PRIMARY KEY,
  user_id     INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  ticker      VARCHAR(20)  NOT NULL,
  asset_name  VARCHAR(200) NOT NULL,
  asset_type  VARCHAR(30)  NOT NULL DEFAULT 'stock', -- stock | etf | bond | crypto | reit
  quantity    DECIMAL(15,4) NOT NULL DEFAULT 0,
  avg_price   DECIMAL(15,2) NOT NULL DEFAULT 0,
  currency    VARCHAR(10)  NOT NULL DEFAULT 'KRW',
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- ── 투자 캘린더 이벤트 ───────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS investment_events (
  id                SERIAL PRIMARY KEY,
  user_id           INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  title             VARCHAR(200) NOT NULL,
  event_type        VARCHAR(30)  NOT NULL DEFAULT 'general',
  -- buy | sell | dividend | earnings | rebalance | watch | general
  ticker            VARCHAR(20),
  start_at          TIMESTAMPTZ NOT NULL,
  end_at            TIMESTAMPTZ NOT NULL,
  notes             TEXT,
  is_ai_recommended BOOLEAN     NOT NULL DEFAULT FALSE,
  priority          VARCHAR(10) NOT NULL DEFAULT 'MEDIUM', -- HIGH | MEDIUM | LOW
  status            VARCHAR(20) NOT NULL DEFAULT 'planned', -- planned | completed | cancelled
  created_at        TIMESTAMPTZ DEFAULT NOW()
);

-- ═══════════════════════════════════════════════════════════════════════════
-- 테스트 계정 (비밀번호: Passw0rd!)
-- ═══════════════════════════════════════════════════════════════════════════
INSERT INTO users (username, display_name, password_hash) VALUES
  ('test1', '테스트 사용자',  crypt('123456', gen_salt('bf'))),
  ('alice', 'Alice Kim',     crypt('Passw0rd!', gen_salt('bf'))),
  ('bob',   'Bob Lee',       crypt('Passw0rd!', gen_salt('bf'))),
  ('carol', 'Carol Park',    crypt('Passw0rd!', gen_salt('bf')))
ON CONFLICT (username) DO NOTHING;

-- ═══════════════════════════════════════════════════════════════════════════
-- test1 포트폴리오 시드
-- ═══════════════════════════════════════════════════════════════════════════
INSERT INTO investments (user_id, ticker, asset_name, asset_type, quantity, avg_price, currency)
SELECT u.id, v.ticker, v.asset_name, v.asset_type, v.quantity, v.avg_price, v.currency
FROM (VALUES
  ('005930', '삼성전자',          'stock', 100,  70000.00, 'KRW'),
  ('000660', 'SK하이닉스',        'stock',  30, 178000.00, 'KRW'),
  ('360750', 'TIGER 미국S&P500', 'etf',    50,  15800.00, 'KRW'),
  ('AAPL',   'Apple Inc.',       'stock',   8,   182.00,  'USD'),
  ('NVDA',   'NVIDIA Corp.',     'stock',   3,   780.00,  'USD')
) AS v(ticker, asset_name, asset_type, quantity, avg_price, currency)
JOIN users u ON u.username = 'test1'
WHERE NOT EXISTS (
  SELECT 1 FROM investments i WHERE i.user_id = u.id AND i.ticker = v.ticker
);

INSERT INTO investment_events (user_id, title, event_type, ticker, start_at, end_at, notes, is_ai_recommended, priority)
SELECT u.id, v.title, v.event_type, v.ticker,
       v.start_at::timestamptz, v.end_at::timestamptz,
       v.notes, v.is_ai, v.priority
FROM (VALUES
  ('삼성전자 2Q 실적발표 대기',  'earnings',  '005930',
   '2026-07-31T09:00:00+09:00', '2026-07-31T10:00:00+09:00',
   'HBM 출하량 및 반도체 업황 컨퍼런스콜 참고', FALSE, 'HIGH'),
  ('NVIDIA 분기 매도 검토',      'sell',      'NVDA',
   '2026-06-15T10:00:00+09:00', '2026-06-15T11:00:00+09:00',
   '목표가 $1,000 도달 시 30% 부분 매도 실행', TRUE, 'HIGH'),
  ('S&P500 ETF 분기 리밸런싱',   'rebalance', '360750',
   '2026-06-30T10:00:00+09:00', '2026-06-30T11:00:00+09:00',
   '전체 포트폴리오 비중 점검 및 채권 비중 확대 검토', TRUE, 'MEDIUM'),
  ('Apple 배당 수령',             'dividend',  'AAPL',
   '2026-05-29T00:00:00+09:00', '2026-05-29T01:00:00+09:00',
   '$0.25/주, 권리락일 확인 후 보유 유지', FALSE, 'LOW')
) AS v(title, event_type, ticker, start_at, end_at, notes, is_ai, priority)
JOIN users u ON u.username = 'test1'
WHERE NOT EXISTS (
  SELECT 1 FROM investment_events ie WHERE ie.user_id = u.id AND ie.title = v.title
);

-- ═══════════════════════════════════════════════════════════════════════════
-- alice 포트폴리오 시드
-- ═══════════════════════════════════════════════════════════════════════════
INSERT INTO investments (user_id, ticker, asset_name, asset_type, quantity, avg_price, currency)
SELECT u.id, v.ticker, v.asset_name, v.asset_type, v.quantity, v.avg_price, v.currency
FROM (VALUES
  ('005930', '삼성전자',            'stock', 50,   71500.00, 'KRW'),
  ('000660', 'SK하이닉스',          'stock', 20,  182000.00, 'KRW'),
  ('360750', 'TIGER 미국S&P500',   'etf',   30,   16200.00, 'KRW'),
  ('AAPL',   'Apple Inc.',         'stock',  5,     185.00, 'USD'),
  ('069500', 'KODEX 200',          'etf',   40,   37800.00, 'KRW')
) AS v(ticker, asset_name, asset_type, quantity, avg_price, currency)
JOIN users u ON u.username = 'alice'
WHERE NOT EXISTS (
  SELECT 1 FROM investments i WHERE i.user_id = u.id AND i.ticker = v.ticker
);

-- bob 포트폴리오 시드
INSERT INTO investments (user_id, ticker, asset_name, asset_type, quantity, avg_price, currency)
SELECT u.id, v.ticker, v.asset_name, v.asset_type, v.quantity, v.avg_price, v.currency
FROM (VALUES
  ('NVDA',   'NVIDIA Corp.',       'stock', 10,     620.00, 'USD'),
  ('379800', 'KODEX 미국나스닥100', 'etf',   50,   18500.00, 'KRW'),
  ('BTC',    'Bitcoin',            'crypto', 0.1, 95000000.00, 'KRW')
) AS v(ticker, asset_name, asset_type, quantity, avg_price, currency)
JOIN users u ON u.username = 'bob'
WHERE NOT EXISTS (
  SELECT 1 FROM investments i WHERE i.user_id = u.id AND i.ticker = v.ticker
);

-- ═══════════════════════════════════════════════════════════════════════════
-- alice 투자 이벤트 시드
-- ═══════════════════════════════════════════════════════════════════════════
INSERT INTO investment_events (user_id, title, event_type, ticker, start_at, end_at, notes, is_ai_recommended, priority)
SELECT u.id, v.title, v.event_type, v.ticker,
       v.start_at::timestamptz, v.end_at::timestamptz,
       v.notes, v.is_ai, v.priority
FROM (VALUES
  ('삼성전자 1Q 실적발표',  'earnings',  '005930',
   '2026-04-30T09:00:00+09:00', '2026-04-30T10:00:00+09:00',
   'FY2025 1분기 실적 컨퍼런스콜', FALSE, 'HIGH'),

  ('SK하이닉스 매수 검토',  'buy',       '000660',
   '2026-05-26T10:00:00+09:00', '2026-05-26T11:00:00+09:00',
   'HBM3 수요 증가 기대, 조정 시 추가 매수', TRUE, 'MEDIUM'),

  ('TIGER S&P500 분기 리밸런싱', 'rebalance', '360750',
   '2026-06-02T10:00:00+09:00', '2026-06-02T11:00:00+09:00',
   '비중 30% 초과 시 일부 매도 후 채권 ETF 편입', TRUE, 'MEDIUM'),

  ('AAPL 분기 배당 수령',  'dividend',  'AAPL',
   '2026-05-29T00:00:00+09:00', '2026-05-29T01:00:00+09:00',
   '$0.25/주 · 권리락일 확인 필요', FALSE, 'LOW'),

  ('삼성전자 매도 목표가 도달 모니터링', 'watch', '005930',
   '2026-06-10T09:00:00+09:00', '2026-06-10T10:00:00+09:00',
   '목표가 85,000원 도달 시 30% 매도 검토', TRUE, 'HIGH'),

  ('KODEX 200 월간 점검',  'general',   '069500',
   '2026-06-15T14:00:00+09:00', '2026-06-15T15:00:00+09:00',
   '지수 추종 현황 및 괴리율 확인', FALSE, 'LOW')
) AS v(title, event_type, ticker, start_at, end_at, notes, is_ai, priority)
JOIN users u ON u.username = 'alice'
WHERE NOT EXISTS (
  SELECT 1 FROM investment_events ie WHERE ie.user_id = u.id AND ie.title = v.title
);
