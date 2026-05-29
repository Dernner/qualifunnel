<script setup>
import { computed, onMounted, ref } from 'vue';
import { useStore } from 'vuex';
import { useRouter } from 'vue-router';

const store = useStore();
const router = useRouter();
const accountId = computed(() => store.getters['auth/getCurrentAccount']?.id);
const boards = computed(() => store.getters['qualifunnel/kanban/allBoards']);

const isCreating = ref(false);
const newBoardName = ref('');
const newBoardDesc = ref('');

onMounted(async () => {
  if (accountId.value) {
    await store.dispatch('qualifunnel/kanban/fetchBoards', accountId.value);
  }
});

const createBoard = async () => {
  if (!newBoardName.value.trim()) return;
  const board = await store.dispatch('qualifunnel/kanban/createBoard', {
    accountId: accountId.value,
    data: { name: newBoardName.value, description: newBoardDesc.value },
  });
  newBoardName.value = '';
  newBoardDesc.value = '';
  isCreating.value = false;
  router.push({ name: 'kanban_board', params: { boardId: board.id } });
};

const openBoard = board => {
  router.push({ name: 'kanban_board', params: { boardId: board.id } });
};
</script>

<template>
  <div class="p-6">
    <div class="flex items-center justify-between mb-6">
      <h1 class="text-xl font-semibold text-slate-800 dark:text-slate-100">
        Kanban
      </h1>
      <button
        class="flex items-center gap-2 bg-woot-500 hover:bg-woot-600 text-white text-sm font-medium px-4 py-2 rounded-lg transition-colors"
        @click="isCreating = true"
      >
        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
        </svg>
        Novo board
      </button>
    </div>

    <!-- Create board form -->
    <div
      v-if="isCreating"
      class="mb-6 p-4 bg-white dark:bg-slate-800 rounded-xl shadow-sm border border-slate-200 dark:border-slate-700"
    >
      <h2 class="text-sm font-semibold text-slate-700 dark:text-slate-200 mb-3">
        Novo Board
      </h2>
      <input
        v-model="newBoardName"
        type="text"
        placeholder="Nome do board"
        class="w-full text-sm rounded-lg border border-slate-300 dark:border-slate-600 bg-white dark:bg-slate-900 px-3 py-2 mb-2 focus:outline-none focus:ring-2 focus:ring-woot-500"
      />
      <input
        v-model="newBoardDesc"
        type="text"
        placeholder="Descrição (opcional)"
        class="w-full text-sm rounded-lg border border-slate-300 dark:border-slate-600 bg-white dark:bg-slate-900 px-3 py-2 mb-3 focus:outline-none focus:ring-2 focus:ring-woot-500"
      />
      <div class="flex gap-2">
        <button
          class="text-sm bg-woot-500 text-white px-4 py-2 rounded-lg hover:bg-woot-600"
          @click="createBoard"
        >
          Criar
        </button>
        <button
          class="text-sm text-slate-500 hover:text-slate-700"
          @click="isCreating = false"
        >
          Cancelar
        </button>
      </div>
    </div>

    <!-- Boards grid -->
    <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
      <button
        v-for="board in boards"
        :key="board.id"
        class="text-left p-4 bg-white dark:bg-slate-800 rounded-xl shadow-sm border border-slate-200 dark:border-slate-700 hover:shadow-md hover:border-woot-300 transition-all duration-150"
        @click="openBoard(board)"
      >
        <h3 class="text-sm font-semibold text-slate-800 dark:text-slate-100 truncate">
          {{ board.name }}
        </h3>
        <p v-if="board.description" class="mt-1 text-xs text-slate-500 dark:text-slate-400 line-clamp-2">
          {{ board.description }}
        </p>
      </button>
    </div>

    <div v-if="boards.length === 0 && !isCreating" class="text-center py-16 text-slate-400">
      <p class="text-sm">Nenhum board criado ainda.</p>
    </div>
  </div>
</template>
