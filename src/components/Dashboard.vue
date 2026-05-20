<template>
  <div class="space-y-5">

    <!-- ── 지표 카드 4개 ──────────────────────────────────────────────── -->
    <div class="grid grid-cols-2 gap-3 lg:grid-cols-4">
      <div v-for="m in metrics" :key="m.label" class="card-bk p-5">
        <p class="label-caps mb-3">{{ m.label }}</p>
        <p class="font-mono text-2xl font-bold" :class="m.accent ? 'text-bk-yellow' : 'text-bk-text'">
          {{ m.value }}
        </p>
        <p class="mt-1 text-xs text-bk-text-3">{{ m.sub }}</p>
      </div>
    </div>

    <div class="grid grid-cols-1 gap-5 lg:grid-cols-2">

      <!-- ── 보유 종목 ────────────────────────────────────────────────── -->
      <div class="card-bk">
        <div class="flex items-center justify-between border-b border-bk-border px-5 py-4">
          <p class="label-caps">보유 종목</p>
          <button class="flex items-center gap-1 text-xs text-bk-yellow hover:underline" @click="$emit('goto', 'portfolio')">
            전체 보기 <i class="fa-solid fa-arrow-right text-xs"></i>
          </button>
        </div>

        <div v-if="investments.length === 0" class="px-5 py-10 text-center text-sm text-bk-text-3">
          <i class="fa-solid fa-briefcase mb-2 block text-2xl"></i>
          보유 종목이 없습니다
        </div>

        <table v-else class="w-full">
          <thead>
            <tr class="border-b border-bk-border">
              <th class="px-5 py-2 text-left label-caps text-xs">종목</th>
              <th class="px-3 py-2 text-right label-caps text-xs">수량</th>
              <th class="px-5 py-2 text-right label-caps text-xs">평균단가</th>
            </tr>
          </thead>
          <tbody>
            <tr
              v-for="inv in investments.slice(0, 6)"
              :key="inv.id"
              class="border-b border-bk-border last:border-0 hover:bg-bk-elevated transition-colors"
            >
              <td class="px-5 py-3">
                <div class="flex items-center gap-2">
                  <i :class="[assetIcon(inv.asset_type), 'text-bk-text-3 w-3.5 text-center text-sm']"></i>
                  <div>
                    <p class="font-medium text-bk-text">{{ inv.asset_name }}</p>
                    <p class="font-mono text-xs text-bk-text-3">{{ inv.ticker }}</p>
                  </div>
                </div>
              </td>
              <td class="px-3 py-3 text-right font-mono text-sm text-bk-text">
                {{ inv.quantity.toLocaleString() }}
              </td>
              <td class="px-5 py-3 text-right font-mono text-sm text-bk-text-2">
                {{ inv.avg_price.toLocaleString() }}
                <span class="ml-0.5 text-xs text-bk-text-3">{{ inv.currency }}</span>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <!-- ── 다가오는 일정 ────────────────────────────────────────────── -->
      <div class="card-bk">
        <div class="flex items-center justify-between border-b border-bk-border px-5 py-4">
          <p class="label-caps">다가오는 일정</p>
          <button class="flex items-center gap-1 text-xs text-bk-yellow hover:underline" @click="$emit('goto', 'calendar')">
            캘린더 <i class="fa-solid fa-arrow-right text-xs"></i>
          </button>
        </div>

        <div v-if="upcomingEvents.length === 0" class="px-5 py-10 text-center text-sm text-bk-text-3">
          <i class="fa-solid fa-calendar-check mb-2 block text-2xl"></i>
          예정된 일정이 없습니다
        </div>

        <ul v-else class="divide-y divide-bk-border">
          <li
            v-for="ev in upcomingEvents"
            :key="ev.id"
            class="flex items-start gap-3 px-5 py-3 hover:bg-bk-elevated transition-colors"
          >
            <!-- 이벤트 타입 아이콘 -->
            <span
              class="mt-0.5 flex h-7 w-7 flex-shrink-0 items-center justify-center text-xs"
              :style="{ color: eventColor(ev.event_type), border: `1px solid ${eventColor(ev.event_type)}22`, background: `${eventColor(ev.event_type)}18` }"
            >
              <i :class="eventIcon(ev.event_type)"></i>
            </span>

            <div class="min-w-0 flex-1">
              <p class="truncate text-sm font-medium text-bk-text">{{ ev.title }}</p>
              <p class="mt-0.5 font-mono text-xs text-bk-text-3">{{ formatDate(ev.start) }}</p>
            </div>

            <div class="flex flex-shrink-0 items-center gap-1.5">
              <span v-if="ev.is_ai_recommended"
                class="rounded px-1.5 py-0.5 text-xs font-bold"
                style="background: rgba(245,197,24,0.12); color: #F5C518;">
                AI
              </span>
              <span
                class="rounded px-1.5 py-0.5 text-xs"
                :class="priorityClass(ev.priority)"
              >{{ ev.priority }}</span>
            </div>
          </li>
        </ul>
      </div>
    </div>

    <!-- ── AI 추천 배너 ────────────────────────────────────────────────── -->
    <div class="card-bk flex items-center justify-between gap-4 p-5"
         style="border-left: 3px solid #F5C518;">
      <div class="flex items-center gap-4">
        <i class="fa-solid fa-robot text-2xl text-bk-yellow"></i>
        <div>
          <p class="font-bold text-bk-text">AI 투자 비서</p>
          <p class="text-sm text-bk-text-2">포트폴리오를 분석하여 최적 투자 일정을 제안합니다</p>
        </div>
      </div>
      <button
        class="btn-yellow flex-shrink-0 flex items-center gap-2 px-5 py-2.5 text-sm"
        @click="$emit('goto', 'ai')"
      >
        <i class="fa-solid fa-wand-magic-sparkles"></i>
        AI 추천 받기
      </button>
    </div>

  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue';

type Investment = {
  id: number; ticker: string; asset_name: string; asset_type: string;
  quantity: number; avg_price: number; currency: string;
};
type InvestmentEvent = {
  id: number; title: string; event_type: string; ticker: string;
  start: string; end: string; notes: string;
  is_ai_recommended: boolean; priority: string; status: string;
};

const props = defineProps<{ investments: Investment[]; events: InvestmentEvent[] }>();
defineEmits<{ (e: 'goto', view: string): void }>();

const krwTotal = computed(() => {
  const t = props.investments.filter(i => i.currency === 'KRW').reduce((s, i) => s + i.quantity * i.avg_price, 0);
  return t >= 100_000_000 ? (t / 100_000_000).toFixed(1) + '억' : t >= 1_000_000 ? (t / 1_000_000).toFixed(0) + '만' : t.toLocaleString();
});

const usdTotal = computed(() => {
  const t = props.investments.filter(i => i.currency === 'USD').reduce((s, i) => s + i.quantity * i.avg_price, 0);
  return '$' + t.toLocaleString(undefined, { maximumFractionDigits: 0 });
});

const thisMonthEvents = computed(() => {
  const n = new Date();
  return props.events.filter(e => { const d = new Date(e.start); return d.getFullYear() === n.getFullYear() && d.getMonth() === n.getMonth(); }).length;
});

const upcomingEvents = computed(() =>
  props.events.filter(e => new Date(e.start) >= new Date() && e.status === 'planned').slice(0, 7)
);

const metrics = computed(() => [
  { label: '보유 종목', value: props.investments.length + '종목', sub: 'Total Holdings', accent: false },
  { label: 'KRW 평가액',  value: krwTotal.value + '원',          sub: '원화 기준 평가',   accent: true },
  { label: 'USD 평가액',  value: usdTotal.value,                 sub: '달러 기준 평가',   accent: true },
  { label: '이번 달 일정', value: thisMonthEvents.value + '건',  sub: 'Scheduled Events', accent: false },
]);

function formatDate(iso: string) {
  const d = new Date(iso);
  return `${d.getFullYear()}.${String(d.getMonth()+1).padStart(2,'0')}.${String(d.getDate()).padStart(2,'0')}`;
}

function assetIcon(type: string) {
  return { stock:'fa-solid fa-chart-line', etf:'fa-solid fa-layer-group',
           bond:'fa-solid fa-file-contract', crypto:'fa-brands fa-bitcoin',
           reit:'fa-solid fa-building' }[type] ?? 'fa-solid fa-circle-dot';
}

const EVENT_COLORS: Record<string, string> = {
  buy:'#00C896', sell:'#FF4D6D', dividend:'#4B9EFF',
  earnings:'#FF8C42', rebalance:'#9B72F4', watch:'#22D4F5', general:'#6E8099',
};

function eventColor(type: string) { return EVENT_COLORS[type] ?? EVENT_COLORS.general; }

function eventIcon(type: string) {
  return { buy:'fa-solid fa-arrow-trend-up', sell:'fa-solid fa-arrow-trend-down',
           dividend:'fa-solid fa-money-bill-wave', earnings:'fa-solid fa-chart-bar',
           rebalance:'fa-solid fa-scale-balanced', watch:'fa-solid fa-eye',
           general:'fa-solid fa-circle-dot' }[type] ?? 'fa-solid fa-circle-dot';
}

function priorityClass(p: string) {
  return { HIGH:'bg-red-900/40 text-red-400', MEDIUM:'bg-yellow-900/30 text-yellow-500',
           LOW:'bg-bk-elevated text-bk-text-3' }[p] ?? 'bg-bk-elevated text-bk-text-3';
}
</script>
