<script setup>
import { ref, computed } from 'vue';
import { useStore } from 'vuex';
import KanbanTaskCard from './KanbanTaskCard.vue';

const props = defineProps({
  step: {
    type: Object,
    required: true,
  },
  accountId: {
    type: Number,
    required: true,
  },
});

const emit = defineEmits(['task-moved']);

const store = useStore();
const isDragOver = ref(false);
const newTaskTitle = ref('');
const isAddingTask = ref(false);

const tasks = computed(() =>
  store.getters['qualifunnel/kanban/tasksForStep'](props.step.id)
);

const addTask = async () => {
  if (!newTaskTitle.value.trim()) return;
  await store.dispatch('qualifunnel/kanban/createTask', {
    accountId: props.accountId,
    boardId: props.step.board_id,
    data: { title: newTaskTitle.value, board_step_id: props.step.id },
  });
  newTaskTitle.value = '';
  isAddingTask.value = false;
};

const onDragOver = e => {
  e.preventDefault();
  isDragOver.value = true;
};

const onDragLeave = () => {
  isDragOver.value = false;
};

const onDrop = async e => {
  e.preventDefault();
  isDragOver.value = false;
  const taskId = parseInt(e.dataTransfer.getData('taskId'), 10);
  const position = tasks.value.length;
  await store.dispatch('qualifunnel/kanban/moveTask', {
    accountId: props.accountId,
    taskId,
    boardStepId: props.step.id,
    position,
  });
  emit('task-moved');
};

const onDragStart = (e, task) => {
  e.dataTransfer.setData('taskId', task.id);
};

const deleteTask = async task => {
  await store.dispatch('qualifunnel/kanban/deleteTask', {
    accountId: props.accountId,
    taskId: task.id,
  });
};
</script>

<template>
  <div
    class="flex flex-col w-72 min-w-[288px] bg-slate-100 dark:bg-slate-900 rounded-xl p-3 gap-2"
    :class="{ 'ring-2 ring-woot-500': isDragOver }"
    @dragover="onDragOver"
    @dragleave="onDragLeave"
    @drop="onDrop"
  >
    <!-- Header -->
    <div class="flex items-center justify-between px-1">
      <h3 class="text-sm font-semibold text-slate-700 dark:text-slate-200 truncate">
        {{ step.name }}
      </h3>
      <span class="text-xs text-slate-400 bg-slate-200 dark:bg-slate-700 px-2 py-0.5 rounded-full">
        {{ tasks.length }}
      </span>
    </div>

    <!-- Task cards -->
    <div class="flex flex-col gap-2 flex-1 overflow-y-auto max-h-[calc(100vh-260px)]">
      <div
        v-for="task in tasks"
        :key="task.id"
        draggable="true"
        @dragstart="e => onDragStart(e, task)"
      >
        <KanbanTaskCard
          :task="task"
          @delete="deleteTask"
        />
      </div>
    </div>

    <!-- Add task -->
    <div v-if="isAddingTask" class="mt-1">
      <input
        v-model="newTaskTitle"
        type="text"
        placeholder="Título da tarefa..."
        class="w-full text-sm rounded-lg border border-slate-300 dark:border-slate-600 bg-white dark:bg-slate-800 px-3 py-2 focus:outline-none focus:ring-2 focus:ring-woot-500"
        @keyup.enter="addTask"
        @keyup.esc="isAddingTask = false"
      />
      <div class="flex gap-2 mt-2">
        <button
          class="text-xs bg-woot-500 text-white px-3 py-1.5 rounded-lg hover:bg-woot-600"
          @click="addTask"
        >
          Adicionar
        </button>
        <button
          class="text-xs text-slate-500 hover:text-slate-700"
          @click="isAddingTask = false"
        >
          Cancelar
        </button>
      </div>
    </div>

    <button
      v-else
      class="flex items-center gap-1 text-sm text-slate-500 hover:text-slate-700 dark:hover:text-slate-300 px-1 py-1 rounded-lg hover:bg-slate-200 dark:hover:bg-slate-700 transition-colors"
      @click="isAddingTask = true"
    >
      <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
      </svg>
      Adicionar tarefa
    </button>
  </div>
</template>
