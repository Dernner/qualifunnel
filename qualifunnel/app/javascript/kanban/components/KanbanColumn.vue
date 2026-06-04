<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import KanbanTaskCard from './KanbanTaskCard.vue';
import KanbanContextDropdown from './KanbanContextDropdown.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  step: { type: Object, required: true },
  tasks: { type: Array, default: () => [] },
  isCollapsed: { type: Boolean, default: false },
  isDragEnabled: { type: Boolean, default: true },
  isLoading: { type: Boolean, default: false },
  hasMore: { type: Boolean, default: false },
  isCountsLoading: { type: Boolean, default: false },
  currency: { type: String, default: 'USD' },
  columnStyle: { type: Object, default: () => ({}) },
});

const emit = defineEmits([
  'add-task', 'edit-task', 'duplicate-task', 'delete-task',
  'edit-step', 'move-task', 'enable-filter', 'load-more', 'expand-step',
]);

const { t } = useI18n();
const isDragOver = ref(false);
const dragOverTaskId = ref(null);

const tasksCount = computed(() => props.step.tasks_count ?? props.tasks.length);

const stepMenuOptions = computed(() => [
  { id: 'edit', name: t('KANBAN.STEP_MODAL.EDIT_TITLE'), icon: 'i-lucide-pencil' },
]);

const handleMenuSelect = option => {
  if (option.id === 'edit') emit('edit-step');
};

const handleExpand = () => {
  const status = props.step.inferred_task_status;
  if (status === 'completed' || status === 'cancelled') {
    emit('enable-filter', status);
  }
  emit('expand-step');
};

const onTaskDragStart = (e, task) => {
  e.dataTransfer.effectAllowed = 'move';
  e.dataTransfer.setData('text/plain', String(task.id));
  e.dataTransfer.setData('taskId', String(task.id));
};

const onColumnDragOver = e => {
  e.preventDefault();
  e.dataTransfer.dropEffect = 'move';
  isDragOver.value = true;
};

const onColumnDragLeave = e => {
  if (!e.currentTarget.contains(e.relatedTarget)) {
    isDragOver.value = false;
    dragOverTaskId.value = null;
  }
};

const onColumnDrop = e => {
  e.preventDefault();
  isDragOver.value = false;
  dragOverTaskId.value = null;
  const taskId = parseInt(e.dataTransfer.getData('taskId'), 10);
  if (!taskId) return;
  emit('move-task', { task: { id: taskId }, destinationStepId: props.step.id, insertBeforeTaskId: null });
};

const onTaskDragOver = (e, task) => {
  e.preventDefault();
  e.stopPropagation();
  isDragOver.value = true;
  dragOverTaskId.value = task.id;
};

const onTaskDrop = (e, task) => {
  e.preventDefault();
  e.stopPropagation();
  isDragOver.value = false;
  dragOverTaskId.value = null;
  const taskId = parseInt(e.dataTransfer.getData('taskId'), 10);
  if (!taskId) return;
  emit('move-task', { task: { id: taskId }, destinationStepId: props.step.id, insertBeforeTaskId: task.id });
};
</script>

<template>
  <div
    class="flex h-full flex-shrink-0 flex-col overflow-hidden rounded-xl shadow-sm outline outline-1 outline-n-container"
    :style="columnStyle"
  >
    <!-- Header -->
    <div class="flex items-center justify-between px-4 py-3 bg-n-slate-3">
      <div class="flex items-center gap-2 min-w-0">
        <div
          class="w-2 h-2 rounded-full flex-shrink-0"
          :style="{ backgroundColor: step.color || '#94a3b8' }"
        />
        <span class="text-sm font-medium text-n-slate-12 truncate">{{ step.name }}</span>
        <span class="flex h-5 min-w-[1.25rem] items-center justify-center rounded-full bg-n-slate-4 px-1.5 text-xs font-medium text-n-slate-12">
          <span v-if="isCountsLoading" class="w-3 h-3 rounded-full bg-n-slate-5 animate-pulse" />
          <template v-else>{{ tasksCount }}</template>
        </span>
      </div>
      <div class="flex items-center gap-1 flex-shrink-0">
        <template v-if="!isCollapsed">
          <KanbanContextDropdown
            :options="stepMenuOptions"
            :has-thumbnail="false"
            hide-search
            @select="handleMenuSelect"
          >
            <template #trigger="{ open }">
              <Button
                icon="i-lucide-more-horizontal"
                variant="ghost"
                color="slate"
                size="xs"
                @click.stop="open"
              />
            </template>
          </KanbanContextDropdown>
          <Button
            icon="i-lucide-plus"
            variant="ghost"
            color="slate"
            size="xs"
            @click="$emit('add-task')"
          />
        </template>
        <Button
          v-else
          icon="i-lucide-chevron-down"
          variant="ghost"
          color="slate"
          size="xs"
          @click="handleExpand"
        />
      </div>
    </div>

    <!-- Collapsed body -->
    <div
      v-if="isCollapsed"
      class="flex-1 bg-n-slate-1 flex flex-col items-center justify-center cursor-pointer p-4 gap-2 hover:bg-n-slate-2 transition-colors"
      @click="handleExpand"
    >
      <i class="i-lucide-chevrons-down w-4 h-4 text-n-slate-9" />
      <span class="text-xs text-n-slate-11">{{ t('KANBAN.STEP.SHOW', { count: tasksCount }) }}</span>
    </div>

    <!-- Expanded body -->
    <div
      v-else
      class="flex-1 flex flex-col overflow-hidden bg-n-slate-1"
      :class="{ 'ring-2 ring-inset ring-n-blue-9': isDragOver && !dragOverTaskId }"
      @dragover="onColumnDragOver"
      @dragleave="onColumnDragLeave"
      @drop="onColumnDrop"
    >
      <!-- Tasks list -->
      <div class="flex-1 overflow-y-auto p-2 flex flex-col gap-1 scrollbar-custom">
        <template v-for="task in tasks" :key="task.id">
          <div
            v-if="isDragEnabled && dragOverTaskId === task.id"
            class="h-0.5 bg-n-blue-9 rounded-full mx-1"
          />
          <div
            :draggable="isDragEnabled"
            @dragstart="e => onTaskDragStart(e, task)"
            @dragover="e => onTaskDragOver(e, task)"
            @drop="e => onTaskDrop(e, task)"
          >
            <KanbanTaskCard
              :task="task"
              :currency="currency"
              @click="$emit('edit-task', task)"
              @delete="$emit('delete-task', task)"
              @duplicate="$emit('duplicate-task', task)"
            />
          </div>
        </template>

        <div v-if="isLoading" class="flex flex-col gap-2 animate-pulse">
          <div v-for="i in 2" :key="`sk-${i}`" class="h-16 rounded-lg bg-n-slate-3" />
        </div>

        <button
          v-if="hasMore && !isLoading"
          class="w-full text-center py-2 text-xs text-n-slate-11 hover:text-n-slate-12 hover:bg-n-slate-3 rounded-lg transition-colors"
          @click="$emit('load-more')"
        >
          {{ t('KANBAN.STEP.LOAD_MORE') }}
        </button>

        <div
          v-if="tasks.length === 0 && !isLoading"
          class="flex items-center justify-center py-8 min-h-[80px]"
          @dragover.prevent="isDragOver = true"
          @dragleave="isDragOver = false"
          @drop="onColumnDrop"
        >
          <p class="text-xs text-n-slate-9">{{ t('KANBAN.STEP.EMPTY') }}</p>
        </div>
      </div>

      <!-- Add task footer -->
      <div class="p-2 border-t border-n-slate-3">
        <Button
          icon="i-lucide-plus"
          variant="ghost"
          color="slate"
          size="sm"
          :label="t('KANBAN.ADD_TASK')"
          class="w-full justify-start"
          @click="$emit('add-task')"
        />
      </div>
    </div>
  </div>
</template>
