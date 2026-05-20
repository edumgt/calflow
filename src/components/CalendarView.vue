<template>
  <div class="space-y-4">

    <!-- ── 상단 툴바 ───────────────────────────────────────────────────── -->
    <div class="card-bk flex flex-wrap items-center justify-between gap-3 px-5 py-3">
      <!-- 범례 -->
      <div class="flex flex-wrap items-center gap-2">
        <span v-for="c in calendarList" :key="c.id"
          class="inline-flex items-center gap-1.5 px-2 py-1 text-xs font-medium"
          :style="{ color: c.color, border: `1px solid ${c.color}44`, background: `${c.color}18` }">
          <i :class="c.icon" class="text-xs"></i>{{ c.name }}
        </span>
      </div>
      <!-- 일정 추가 -->
      <button class="btn-yellow flex items-center gap-2 px-4 py-2 text-sm" @click="showAddModal = true">
        <i class="fa-solid fa-calendar-plus"></i> 일정 추가
      </button>
    </div>

    <!-- ── 캘린더 컨테이너 ─────────────────────────────────────────────── -->
    <div class="card-bk overflow-hidden">
      <!-- 네비게이션 헤더 -->
      <div class="flex items-center justify-between border-b border-bk-border px-5 py-3">
        <button class="btn-ghost px-3 py-1.5 text-sm" @click="movePrev">
          <i class="fa-solid fa-chevron-left"></i>
        </button>
        <span class="font-mono font-semibold text-bk-text">{{ currentTitle }}</span>
        <button class="btn-ghost px-3 py-1.5 text-sm" @click="moveNext">
          <i class="fa-solid fa-chevron-right"></i>
        </button>
      </div>
      <div ref="calendarEl" class="min-h-[600px]"></div>
    </div>

    <!-- ── 일정 추가 모달 ─────────────────────────────────────────────── -->
    <Teleport to="body">
      <div v-if="showAddModal"
        class="fixed inset-0 z-50 flex items-center justify-center bg-black/70 p-4">
        <div class="card-bk w-full max-w-md">

          <!-- 모달 헤더 -->
          <div class="flex items-center justify-between border-b border-bk-border px-6 py-4">
            <p class="label-caps">투자 일정 추가</p>
            <button class="text-bk-text-3 hover:text-bk-text" @click="showAddModal = false">
              <i class="fa-solid fa-xmark text-lg"></i>
            </button>
          </div>

          <!-- 모달 본문 -->
          <form class="space-y-4 px-6 py-5" @submit.prevent="submitAdd">
            <div>
              <label class="label-caps mb-2 block">제목 *</label>
              <input v-model="form.title" class="input-bk" placeholder="예: 삼성전자 추가 매수" required />
            </div>

            <div class="grid grid-cols-2 gap-3">
              <div>
                <label class="label-caps mb-2 block">이벤트 유형</label>
                <select v-model="form.event_type" class="input-bk">
                  <option value="buy">매수</option>
                  <option value="sell">매도</option>
                  <option value="dividend">배당</option>
                  <option value="earnings">실적발표</option>
                  <option value="rebalance">리밸런싱</option>
                  <option value="watch">모니터링</option>
                  <option value="general">일반</option>
                </select>
              </div>
              <div>
                <label class="label-caps mb-2 block">우선순위</label>
                <select v-model="form.priority" class="input-bk">
                  <option value="HIGH">HIGH</option>
                  <option value="MEDIUM">MEDIUM</option>
                  <option value="LOW">LOW</option>
                </select>
              </div>
            </div>

            <div>
              <label class="label-caps mb-2 block">티커 (선택)</label>
              <input v-model="form.ticker" class="input-bk font-mono" placeholder="예: 005930" />
            </div>

            <div class="grid grid-cols-2 gap-3">
              <div>
                <label class="label-caps mb-2 block">시작일시 *</label>
                <input v-model="form.start" type="datetime-local" class="input-bk text-sm" required />
              </div>
              <div>
                <label class="label-caps mb-2 block">종료일시 *</label>
                <input v-model="form.end" type="datetime-local" class="input-bk text-sm" required />
              </div>
            </div>

            <div>
              <label class="label-caps mb-2 block">메모</label>
              <textarea v-model="form.notes" class="input-bk resize-none" rows="2"
                placeholder="투자 근거, 목표가 등"></textarea>
            </div>

            <p v-if="formError" class="flex items-center gap-1.5 text-sm text-red-400">
              <i class="fa-solid fa-circle-exclamation"></i>{{ formError }}
            </p>

            <div class="flex gap-3 border-t border-bk-border pt-4">
              <button type="button" class="btn-ghost flex-1 py-2.5 text-sm" @click="showAddModal = false">
                취소
              </button>
              <button type="submit" :disabled="submitting" class="btn-yellow flex-1 flex items-center justify-center gap-2 py-2.5 text-sm">
                <i v-if="submitting" class="fa-solid fa-spinner fa-spin"></i>
                {{ submitting ? '저장 중...' : '저장' }}
              </button>
            </div>
          </form>
        </div>
      </div>
    </Teleport>
  </div>
</template>

<script setup lang="ts">
import { onBeforeUnmount, onMounted, reactive, ref, watch } from 'vue';
import Calendar from 'tui-calendar';
import 'tui-calendar/dist/tui-calendar.css';

type InvestmentEvent = {
  id: number; title: string; event_type: string; ticker: string;
  start: string; end: string; notes: string;
  is_ai_recommended: boolean; priority: string; status: string;
};

const props = defineProps<{ events: InvestmentEvent[]; apiUrl: string; token: string }>();
const emit = defineEmits<{ (e: 'event-added'): void }>();

const calendarEl = ref<HTMLDivElement | null>(null);
let calendar: Calendar | null = null;
const currentTitle = ref('');
const showAddModal = ref(false);
const submitting = ref(false);
const formError = ref('');

const form = reactive({
  title: '', event_type: 'buy', ticker: '',
  start: '', end: '', notes: '', priority: 'MEDIUM',
});

const calendarList = [
  { id:'buy',       name:'매수',     color:'#00C896', icon:'fa-solid fa-arrow-trend-up' },
  { id:'sell',      name:'매도',     color:'#FF4D6D', icon:'fa-solid fa-arrow-trend-down' },
  { id:'dividend',  name:'배당',     color:'#4B9EFF', icon:'fa-solid fa-money-bill-wave' },
  { id:'earnings',  name:'실적발표', color:'#FF8C42', icon:'fa-solid fa-chart-bar' },
  { id:'rebalance', name:'리밸런싱', color:'#9B72F4', icon:'fa-solid fa-scale-balanced' },
  { id:'watch',     name:'모니터링', color:'#22D4F5', icon:'fa-solid fa-eye' },
  { id:'general',   name:'일반',     color:'#6E8099', icon:'fa-solid fa-circle-dot' },
];

function toSchedules(events: InvestmentEvent[]) {
  return events.map(e => ({
    id: String(e.id),
    calendarId: calendarList.some(c => c.id === e.event_type) ? e.event_type : 'general',
    title: e.ticker ? `[${e.ticker}] ${e.title}` : e.title,
    category: 'time',
    start: e.start,
    end: e.end,
    body: e.notes,
  }));
}

function updateTitle() {
  if (!calendar) return;
  const d = calendar.getDate() as unknown as Date;
  currentTitle.value = `${d.getFullYear()}년 ${d.getMonth() + 1}월`;
}

function movePrev() { calendar?.prev(); updateTitle(); }
function moveNext() { calendar?.next(); updateTitle(); }

onMounted(() => {
  if (!calendarEl.value) return;
  calendar = new Calendar(calendarEl.value, {
    defaultView: 'month',
    taskView: false,
    scheduleView: ['time'],
    calendars: calendarList.map(c => ({
      id: c.id, name: c.name,
      color: '#FFFFFF', bgColor: c.color, borderColor: c.color,
    })),
    template: {
      monthDayname: d =>
        `<span style="color:#3A4F65;font-size:12px;font-weight:700;letter-spacing:0.06em;text-transform:uppercase">${d.label}</span>`,
    },
  });
  calendar.createSchedules(toSchedules(props.events));
  updateTitle();
});

watch(() => props.events, evs => {
  if (!calendar) return;
  calendar.clear();
  calendar.createSchedules(toSchedules(evs));
}, { deep: true });

onBeforeUnmount(() => { calendar?.destroy(); calendar = null; });

async function submitAdd() {
  formError.value = '';
  submitting.value = true;
  try {
    const res = await fetch(`${props.apiUrl}/api/calendar/events`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${props.token}` },
      body: JSON.stringify({
        title: form.title, event_type: form.event_type,
        ticker: form.ticker || null,
        start: new Date(form.start).toISOString(),
        end: new Date(form.end).toISOString(),
        notes: form.notes || null, priority: form.priority,
      }),
    });
    if (!res.ok) throw new Error((await res.json()).message);
    showAddModal.value = false;
    Object.assign(form, { title:'', event_type:'buy', ticker:'', start:'', end:'', notes:'', priority:'MEDIUM' });
    emit('event-added');
  } catch (err) {
    formError.value = err instanceof Error ? err.message : '저장 실패';
  } finally {
    submitting.value = false;
  }
}
</script>
