<script setup>
import KanbanColumn from './KanbanColumn.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import { KANBAN_COLUMN_WIDTH_STYLES } from 'kanban/constants';
import { useI18n } from 'vue-i18n';

defineProps({
  steps: { type: Array, default: () => [] },
  tasksByStep: { type: Object, default: () => ({}) },
  collapsedStepIds: { type: Array, default: () => [] },
  isDragEnabled: { type: Boolean, default: true },
  stepLoadingMap: { type: Object, default: () => ({}) },
  stepMetaMap: { type: Object, default: () => ({}) },
  stepFetchedMap: { type: Object, default: () => ({}) },
  isCountsLoading: { type: Boolean, default: false },
  currency: { type: String, default: 'USD' },
});

const emit = defineEmits([
  'add-task', 'edit-task', 'duplicate-task', 'delete-task',
  'edit-step', 'add-step', 'update-task', 'move-task',
  'enable-filter', 'load-more', 'expand-step',
]);

const { t } = useI18n();
const columnStyle = KANBAN_COLUMN_WIDTH_STYLES;
</script>

<template>
  <div class="flex gap-4 px-1 pb-4 h-full items-start">
    <KanbanColumn
      v-for="step in steps"
      :key="step.id"
      :step="step"
      :tasks="tasksByStep[step.id] || []"
      :is-collapsed="collapsedStepIds.includes(step.id)"
      :is-drag-enabled="isDragEnabled"
      :is-loading="stepLoadingMap[step.id] || false"
      :has-more="stepMetaMap[step.id]?.hasMore || false"
      :is-counts-loading="isCountsLoading"
      :currency="currency"
      :column-style="columnStyle"
      @add-task="emit('add-task', step.id)"
      @edit-task="emit('edit-task', $event)"
      @duplicate-task="emit('duplicate-task', $event)"
      @delete-task="emit('delete-task', $event)"
      @edit-step="emit('edit-step', step)"
      @move-task="emit('move-task', $event)"
      @enable-filter="emit('enable-filter', $event)"
      @load-more="emit('load-more', step.id)"
      @expand-step="emit('expand-step', step.id)"
    />

    <div class="flex-shrink-0 flex pt-2">
      <Button
        icon="i-lucide-plus"
        variant="ghost"
        color="slate"
        size="sm"
        :label="t('KANBAN.SETTINGS.ADD_STEP')"
        @click="emit('add-step')"
      />
    </div>
  </div>
</template>
