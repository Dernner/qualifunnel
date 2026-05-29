<script setup>
import { computed } from 'vue';
import { useStore } from 'vuex';
import KanbanColumn from './KanbanColumn.vue';

const props = defineProps({
  accountId: {
    type: Number,
    required: true,
  },
});

const store = useStore();
const steps = computed(() => store.getters['qualifunnel/kanban/stepsForCurrentBoard']);
</script>

<template>
  <div class="flex gap-4 p-4 overflow-x-auto h-full items-start">
    <KanbanColumn
      v-for="step in steps"
      :key="step.id"
      :step="step"
      :account-id="accountId"
    />

    <div
      v-if="steps.length === 0"
      class="flex items-center justify-center w-full h-64 text-slate-400"
    >
      <p class="text-sm">Nenhuma coluna configurada. Adicione colunas ao board.</p>
    </div>
  </div>
</template>
