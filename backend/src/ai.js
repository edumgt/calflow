import Anthropic from '@anthropic-ai/sdk';

const client = new Anthropic({ apiKey: process.env.ANTHROPIC_API_KEY });

const TODAY = () => new Date().toISOString().split('T')[0];

function addDays(base, n) {
  const d = new Date(base);
  d.setDate(d.getDate() + n);
  return d.toISOString().split('T')[0];
}

function mockRecommendations(portfolio) {
  const today = TODAY();
  const tickers = portfolio.slice(0, 3);
  return {
    recommendations: [
      {
        ticker: tickers[0]?.ticker || 'ETF',
        asset_name: tickers[0]?.asset_name || '지수 ETF',
        action: 'BUY',
        category: '매수',
        reason:
          '글로벌 금리 인하 기대감으로 성장주 중심 반등이 예상됩니다. 현재 가격은 120일 이동평균선 부근으로 기술적 지지선이 형성되어 있습니다.',
        suggested_date: addDays(today, 3),
        priority: 'HIGH',
      },
      {
        ticker: tickers[1]?.ticker || 'BOND',
        asset_name: tickers[1]?.asset_name || '채권 ETF',
        action: 'REBALANCE',
        category: '리밸런싱',
        reason:
          '주식 비중이 목표 대비 8% 초과되어 포트폴리오 리밸런싱이 필요합니다. 일부를 채권 ETF로 전환하여 변동성을 낮추세요.',
        suggested_date: addDays(today, 7),
        priority: 'MEDIUM',
      },
      {
        ticker: tickers[2]?.ticker || 'WATCH',
        asset_name: tickers[2]?.asset_name || '관심 종목',
        action: 'WATCH',
        category: '실적확인',
        reason:
          '다음 분기 실적 발표가 예정되어 있습니다. 어닝 서프라이즈 가능성이 높으며 매수 타이밍을 포착하세요.',
        suggested_date: addDays(today, 14),
        priority: 'MEDIUM',
      },
      {
        ticker: 'DIVIDEND',
        asset_name: '배당 수령 예정',
        action: 'WATCH',
        category: '배당',
        reason:
          '보유 ETF의 분기 배당 지급일이 다가옵니다. 배당 재투자 전략을 미리 계획하세요.',
        suggested_date: addDays(today, 21),
        priority: 'LOW',
      },
      {
        ticker: tickers[0]?.ticker || 'SELL',
        asset_name: tickers[0]?.asset_name || '매도 검토 종목',
        action: 'SELL',
        category: '매도',
        reason:
          '목표 수익률에 근접했습니다. 분할 매도를 통해 수익을 실현하고 다음 투자 기회를 준비하세요.',
        suggested_date: addDays(today, 30),
        priority: 'MEDIUM',
      },
    ],
  };
}

export async function generateRecommendations(portfolio) {
  if (!process.env.ANTHROPIC_API_KEY) {
    return mockRecommendations(portfolio);
  }

  const today = TODAY();
  const portfolioText = portfolio
    .map(
      (p) =>
        `- ${p.asset_name}(${p.ticker}): ${p.quantity}주 × 평균단가 ${p.avg_price.toLocaleString()} ${p.currency}`,
    )
    .join('\n');

  const prompt = `당신은 한국의 개인 투자 비서 AI입니다. 사용자의 포트폴리오를 분석하고 향후 투자 일정 5개를 제안하세요.

오늘 날짜: ${today}

[사용자 포트폴리오]
${portfolioText}

다음 JSON 형식으로만 응답하세요 (다른 텍스트 없이):
{
  "recommendations": [
    {
      "ticker": "종목코드",
      "asset_name": "자산명 (한국어)",
      "action": "BUY 또는 SELL 또는 REBALANCE 또는 WATCH",
      "category": "매수 또는 매도 또는 리밸런싱 또는 실적확인 또는 배당",
      "reason": "추천 이유 (한국어, 2-3문장, 구체적 근거 포함)",
      "suggested_date": "YYYY-MM-DD (오늘로부터 3~60일 이내)",
      "priority": "HIGH 또는 MEDIUM 또는 LOW"
    }
  ]
}

규칙:
- 반드시 5개의 추천을 생성하세요
- 실제 시장 논리에 기반한 현실적인 추천을 하세요
- 포트폴리오에 없는 종목도 추천할 수 있습니다
- 날짜는 주말을 피해 평일로 설정하세요`;

  const message = await client.messages.create({
    model: 'claude-sonnet-4-6',
    max_tokens: 1500,
    system:
      '투자 일정 추천 전문가입니다. 요청된 JSON 형식으로만 응답합니다.',
    messages: [{ role: 'user', content: prompt }],
  });

  const text = message.content[0].text.trim();
  const jsonMatch = text.match(/\{[\s\S]*\}/);
  if (!jsonMatch) throw new Error('AI 응답 파싱 실패');
  return JSON.parse(jsonMatch[0]);
}
