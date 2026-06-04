<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { KANBAN_PRIORITIES, intlLocale } from 'kanban/constants';
import KanbanContextDropdown from './KanbanContextDropdown.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  task: { type: Object, required: true },
  currency: { type: String, default: 'USD' },
});

const emit = defineEmits(['click', 'delete', 'duplicate']);

const { t, locale } = useI18n();

const isOverdue = computed(() => {
  if (!props.task.due_date) return false;
  return new Date(props.task.due_date) < new Date();
});

const formattedDueDate = computed(() => {
  if (!props.task.due_date) return null;
  return new Date(props.task.due_date).toLocaleDateString(intlLocale(locale.value), {
    month: 'short',
    day: 'numeric',
  });
});

const priority = computed(
  () =>
    KANBAN_PRIORITIES.find(p => p.id === props.task.priority) ||
    KANBAN_PRIORITIES[KANBAN_PRIORITIES.length - 1]
);

const formattedValue = computed(() => {
  const val = Number(props.task.value);
  if (!val || val <= 0) return '';
  return new Intl.NumberFormat(intlLocale(locale.value), {
    style: 'currency',
    currency: props.currency,
    notation: 'compact',
    minimumFractionDigits: 0,
    maximumFractionDigits: 1,
  }).format(val);
});

const contextOptions = computed(() => [
  { id: 'duplicate', name: t('KANBAN.MODAL.DUPLICATE'), icon: 'i-lucide-copy' },
  { id: 'delete', name: t('KANBAN.MODAL.DELETE'), icon: 'i-lucide-trash-2' },
]);

const handleContextSelect = option => {
  if (option.id === 'duplicate') emit('duplicate');
  else if (option.id === 'delete') emit('delete');
};

const visibleAgents = computed(() => (props.task.assigned_agents || []).slice(0, 3));
</script>

<template>
  <div
    class="group relative p-3 bg-n-background border border-n-slate-3 rounded-lg shadow-sm hover:border-n-slate-4 hover:shadow-md transition-all cursor-pointer flex flex-col gap-2"
    @click="emit('click')"
  >
    <!-- Title + context menu -->
    <div class="flex items-start justify-between gap-1">
      <p class="text-sm font-medium text-n-slate-12 leading-snug flex-1 min-w-0">
        {{ task.title }}
      </p>
      <KanbanContextDropdown
        :options="contextOptions"
        :has-thumbnail="false"
        hide-search
        @select="handleContextSelect"
      >
        <template #trigger="{ open }">
          <Button
            icon="i-lucide-more-horizontal"
            variant="ghost"
            color="slate"
            size="xs"
            class="flex-shrink-0 opacity-0 group-hover:opacity-100 transition-opacity -mt-0.5 -mr-1"
            @click.stop="open"
          />
        </template>
      </KanbanContextDropdown>
    </div>

    <!-- Description -->
    <p v-if="task.description" class="text-xs text-n-slate-11 line-clamp-2">
      {{ task.description }}
    </p>

    <!-- Footer: priority, due date, value, agents -->
    <div class="flex items-center justify-between gap-2 mt-0.5">
      <div class="flex items-center gap-1.5 flex-wrap min-w-0">
        <!-- Priority icon -->
        <i :class="[priority.icon, 'w-3.5 h-3.5 flex-shrink-0']" :style="{ color: priority.color }" />

        <!-- Due date -->
        <span
          v-if="formattedDueDate"
          class="inline-flex items-center gap-0.5 text-xs px-1.5 py-0.5 rounded-md"
          :class="isOverdue ? 'bg-n-red-3 text-n-red-11' : 'bg-n-slate-3 text-n-slate-11'"
        >
          <i class="i-lucide-calendar w-3 h-3" />
          {{ formattedDueDate }}
        </span>

        <!-- Value -->
        <span
          v-if="formattedValue"
          class="text-xs px-1.5 py-0.5 rounded-md bg-n-slate-3 text-n-slate-11 inline-flex items-center gap-0.5"
        >
          <i class="i-lucide-banknote w-3 h-3" />
          {{ formattedValue }}
        </span>
      </div>

      <!-- Agent avatars -->
      <div v-if="visibleAgents.length" class="flex flex-shrink-0">
        <img
          v-for="agent in visibleAgents"
          :key="agent.id"
          :src="agent.avatar_url"
          :alt="agent.name"
          :title="agent.name"
          class="w-5 h-5 rounded-full border border-n-background object-cover shadow ltr:[&:not(:first-child)]:-ml-1.5 rtl:[&:not(:first-child)]:-mr-1.5"
        />
      </div>
    </div>
  </div>
</template>
