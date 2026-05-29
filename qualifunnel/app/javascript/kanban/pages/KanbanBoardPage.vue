<script setup>
import { computed, onMounted } from 'vue';
import { useStore } from 'vuex';
import { useRoute, useRouter } from 'vue-router';
import KanbanBoard from '../components/KanbanBoard.vue';

const store = useStore();
const route = useRoute();
const router = useRouter();

const accountId = computed(() => store.getters['auth/getCurrentAccount']?.id);
const board = computed(() => store.getters['qualifunnel/kanban/currentBoard']);

onMounted(async () => {
  if (!accountId.value) return;
  await store.dispatch('qualifunnel/kanban/fetchBoard', {
    accountId: accountId.value,
    boardId: route.params.boardId,
  });
});
</script>

<template>
  <div class="flex flex-col h-full">
    <!-- Header -->
    <div class="flex items-center gap-3 px-4 py-3 border-b border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800">
      <button
        class="text-slate-500 hover:text-slate-700 dark:hover:text-slate-300"
        @click="router.push({ name: 'kanban_overview' })"
      >
        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7" />
        </svg>
      </button>
      <h1 class="text-base font-semibold text-slate-800 dark:text-slate-100">
        {{ board?.name ?? 'Carregando...' }}
      </h1>
    </div>

    <!-- Board body -->
    <div class="flex-1 overflow-hidden">
      <KanbanBoard v-if="board" :account-id="accountId" />
    </div>
  </div>
</template>
