<script setup>
import { computed } from 'vue';
import { useStore } from 'vuex';

const props = defineProps({
  task: {
    type: Object,
    required: true,
  },
});

const emit = defineEmits(['click', 'delete']);

const store = useStore();

const isOverdue = computed(() => {
  if (!props.task.due_date) return false;
  return new Date(props.task.due_date) < new Date();
});

const formattedDueDate = computed(() => {
  if (!props.task.due_date) return null;
  return new Date(props.task.due_date).toLocaleDateString();
});
</script>

<template>
  <div
    class="bg-white dark:bg-slate-800 rounded-lg p-3 shadow-sm border border-slate-200 dark:border-slate-700 cursor-pointer hover:shadow-md transition-shadow duration-150"
    @click="emit('click', task)"
  >
    <p class="text-sm font-medium text-slate-800 dark:text-slate-100 leading-snug">
      {{ task.title }}
    </p>

    <p
      v-if="task.description"
      class="mt-1 text-xs text-slate-500 dark:text-slate-400 line-clamp-2"
    >
      {{ task.description }}
    </p>

    <div v-if="task.due_date" class="mt-2 flex items-center gap-1">
      <span
        class="text-xs px-1.5 py-0.5 rounded"
        :class="isOverdue
          ? 'bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-400'
          : 'bg-slate-100 text-slate-600 dark:bg-slate-700 dark:text-slate-300'"
      >
        {{ formattedDueDate }}
      </span>
    </div>

    <div class="mt-2 flex items-center justify-end">
      <button
        class="text-slate-400 hover:text-red-500 transition-colors"
        @click.stop="emit('delete', task)"
      >
        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
        </svg>
      </button>
    </div>
  </div>
</template>
