<script setup>
import { computed, ref, onMounted, watch, nextTick } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useAdmin } from 'dashboard/composables/useAdmin';
import { copyTextToClipboard } from 'shared/helpers/clipboard';
import Draggable from 'vuedraggable';
import SettingsLayout from 'dashboard/routes/dashboard/settings/SettingsLayout.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import Editor from 'dashboard/components-next/Editor/Editor.vue';
import Switch from 'dashboard/components-next/switch/Switch.vue';
import Select from 'dashboard/components-next/select/Select.vue';
import TagMultiSelectComboBox from 'dashboard/components-next/combobox/TagMultiSelectComboBox.vue';
import KanbanStepModal from 'kanban/components/KanbanStepModal.vue';
import { parseAPIErrorResponse } from 'dashboard/store/utils/api';
import { CURRENCY_CODES } from 'kanban/constants';

const router = useRouter();
const route = useRoute();
const store = useStore();
const { t } = useI18n();
const { isAdmin } = useAdmin();

const NS = 'qualifunnel/kanban';

const boardId = computed(() => Number(route.params.boardId));
const activeBoard = computed(() => store.getters[`${NS}/activeBoard`]);
const steps = computed(() => store.getters[`${NS}/orderedSteps`]);
const agents = computed(() => store.state.agents.records);
const inboxes = computed(() => store.getters['inboxes/getInboxes']);

const agentOptions = computed(() => agents.value.map(a => ({ value: a.id, label: a.name })));
const inboxOptions = computed(() => inboxes.value.map(i => ({ value: i.id, label: i.name })));

const boardName = ref('');
const boardDescription = ref('');
const boardCurrency = ref('USD');
const currencyOptions = computed(() => CURRENCY_CODES.map(code => ({ value: code, label: t(`KANBAN.CURRENCIES.${code}`) })));
const headerBoardName = ref('');
const selectedAgents = ref([]);
const selectedInboxes = ref([]);
const autoCreateTaskForConversation = ref(false);
const autoAssignTaskToAgent = ref(false);
const syncTaskAndConversationAgents = ref(false);
const autoResolveConversationOnTaskEnd = ref(false);
const autoCompleteTaskOnConversationResolve = ref(false);
const syncTaskAndConversationLabelsPriority = ref(false);
const automationSettingRefs = {
  autoCreateTaskForConversation,
  autoAssignTaskToAgent,
  syncTaskAndConversationAgents,
  autoResolveConversationOnTaskEnd,
  autoCompleteTaskOnConversationResolve,
  syncTaskAndConversationLabelsPriority,
};

const isSaving = ref(false);
const isSavingAutomation = ref(false);
const showStepModal = ref(false);
const selectedStep = ref(null);
const isSavingStep = ref(false);
const isDeletingStep = ref(false);
const isInitialized = ref(false);
const isDataLoaded = ref(false);
const showDeleteBoardDialog = ref(false);
const isDeletingBoard = ref(false);

const fetchBoards = () => store.dispatch(`${NS}/fetchBoards`);
const setActiveBoard = id => store.dispatch(`${NS}/setActiveBoard`, { boardId: id });
const updateBoard = data => store.dispatch(`${NS}/updateBoard`, data);
const createStep = data => store.dispatch(`${NS}/createStep`, data);
const updateStep = data => store.dispatch(`${NS}/updateStep`, data);
const removeStep = data => store.dispatch(`${NS}/deleteStep`, data);
const fetchAgents = () => store.dispatch('agents/get');
const fetchInboxes = () => store.dispatch('inboxes/get');
const updateBoardAgents = data => store.dispatch(`${NS}/updateBoardAgents`, data);
const updateBoardInboxes = data => store.dispatch(`${NS}/updateBoardInboxes`, data);
const deleteBoard = id => store.dispatch(`${NS}/deleteBoard`, id);

const saveBoardInfo = async () => {
  isSaving.value = true;
  try {
    await updateBoard({ id: boardId.value, board: { name: boardName.value, description: boardDescription.value } });
    headerBoardName.value = boardName.value;
    useAlert(t('KANBAN.SETTINGS.UPDATE_SUCCESS'));
  } catch (error) {
    useAlert(parseAPIErrorResponse(error) || t('KANBAN.SETTINGS.UPDATE_ERROR'));
  } finally {
    isSaving.value = false;
  }
};

const saveAgents = async () => {
  try {
    await updateBoardAgents({ boardId: boardId.value, agentIds: selectedAgents.value });
    useAlert(t('KANBAN.SETTINGS.UPDATE_SUCCESS'));
  } catch (error) {
    useAlert(parseAPIErrorResponse(error) || t('KANBAN.SETTINGS.UPDATE_ERROR'));
  }
};

const saveInboxes = async () => {
  try {
    await updateBoardInboxes({ boardId: boardId.value, inboxIds: selectedInboxes.value });
    useAlert(t('KANBAN.SETTINGS.UPDATE_SUCCESS'));
  } catch (error) {
    useAlert(parseAPIErrorResponse(error) || t('KANBAN.SETTINGS.UPDATE_ERROR'));
  }
};

const saveAutomationSettings = async () => {
  isSavingAutomation.value = true;
  try {
    await updateBoard({
      id: boardId.value,
      board: {
        settings: {
          ...activeBoard.value.settings,
          auto_create_task_for_conversation: autoCreateTaskForConversation.value,
          auto_assign_task_to_agent: autoAssignTaskToAgent.value,
          sync_task_and_conversation_agents: syncTaskAndConversationAgents.value,
          auto_resolve_conversation_on_task_end: autoResolveConversationOnTaskEnd.value,
          auto_complete_task_on_conversation_resolve: autoCompleteTaskOnConversationResolve.value,
          sync_task_and_conversation_labels_priority: syncTaskAndConversationLabelsPriority.value,
        },
      },
    });
    useAlert(t('KANBAN.SETTINGS.UPDATE_SUCCESS'));
  } catch (error) {
    useAlert(parseAPIErrorResponse(error) || t('KANBAN.SETTINGS.UPDATE_ERROR'));
  } finally {
    isSavingAutomation.value = false;
  }
};

const watchSetting = ref => watch(ref, async (newValue, oldValue) => {
  if (!isInitialized.value || newValue === oldValue) return;
  await saveAutomationSettings();
});
watchSetting(autoCreateTaskForConversation);
watchSetting(autoAssignTaskToAgent);
watchSetting(syncTaskAndConversationAgents);
watchSetting(autoResolveConversationOnTaskEnd);
watchSetting(autoCompleteTaskOnConversationResolve);
watchSetting(syncTaskAndConversationLabelsPriority);

const saveCurrency = async () => {
  try {
    await updateBoard({ id: boardId.value, board: { currency: boardCurrency.value } });
    useAlert(t('KANBAN.SETTINGS.UPDATE_SUCCESS'));
  } catch (error) {
    useAlert(parseAPIErrorResponse(error) || t('KANBAN.SETTINGS.UPDATE_ERROR'));
  }
};

watch(boardCurrency, async (newValue, oldValue) => {
  if (!isInitialized.value || newValue === oldValue) return;
  await saveCurrency();
});

const handleAgentsChange = agentIds => {
  selectedAgents.value = [...agentIds];
  if (isInitialized.value) saveAgents();
};

const handleInboxesChange = inboxIds => {
  selectedInboxes.value = [...inboxIds];
  if (isInitialized.value) saveInboxes();
};

const initializeBoardData = () => {
  if (!activeBoard.value) return;
  boardName.value = activeBoard.value.name || '';
  headerBoardName.value = activeBoard.value.name || '';
  boardDescription.value = activeBoard.value.description || '';
  boardCurrency.value = activeBoard.value.currency || 'USD';
  selectedAgents.value = (activeBoard.value.assigned_agents || []).map(a => a.id);
  selectedInboxes.value = (activeBoard.value.assigned_inboxes || []).map(i => i.id);
  autoCreateTaskForConversation.value = activeBoard.value.settings?.auto_create_task_for_conversation || false;
  autoAssignTaskToAgent.value = activeBoard.value.settings?.auto_assign_task_to_agent || false;
  syncTaskAndConversationAgents.value = activeBoard.value.settings?.sync_task_and_conversation_agents || false;
  autoResolveConversationOnTaskEnd.value = activeBoard.value.settings?.auto_resolve_conversation_on_task_end || false;
  autoCompleteTaskOnConversationResolve.value = activeBoard.value.settings?.auto_complete_task_on_conversation_resolve || false;
  syncTaskAndConversationLabelsPriority.value = activeBoard.value.settings?.sync_task_and_conversation_labels_priority || false;
  isDataLoaded.value = true;
  nextTick(() => { isInitialized.value = true; });
};

watch(isDataLoaded, loaded => {
  if (loaded && route.hash) {
    nextTick(() => {
      const element = document.querySelector(route.hash);
      if (element) {
        element.scrollIntoView({ behavior: 'smooth' });
        setTimeout(() => { element.classList.add('highlight-section'); setTimeout(() => element.classList.remove('highlight-section'), 2000); }, 500);
      }
    });
  }
});

onMounted(async () => {
  if (!isAdmin.value) {
    router.push({ name: 'kanban_board_show', params: { boardId: boardId.value } });
    return;
  }
  await Promise.all([fetchBoards(), fetchAgents(), fetchInboxes()]);
  if (boardId.value) {
    await setActiveBoard(boardId.value);
    initializeBoardData();
  }
});

const getStepTaskCount = stepId => steps.value.find(s => s.id === stepId)?.tasks_count ?? 0;

const updateStepsOrder = async newSteps => {
  const stepIds = newSteps.map(step => step.id);
  const originalBoard = { ...activeBoard.value };
  store.commit(`${NS}/UPDATE_BOARD`, { ...activeBoard.value, steps_order: stepIds });
  try {
    await updateBoard({ id: boardId.value, board: { steps_order: stepIds } });
    useAlert(t('KANBAN.SETTINGS.UPDATE_SUCCESS'));
  } catch (error) {
    store.commit(`${NS}/UPDATE_BOARD`, originalBoard);
    useAlert(parseAPIErrorResponse(error) || t('KANBAN.SETTINGS.UPDATE_ERROR'));
  }
};

const totalTasksCount = computed(() => activeBoard.value?.total_tasks_count || 0);
const stepsCount = computed(() => steps.value.length);

const canStepHaveStatusFlag = index => steps.value.length > 1 && index !== 0;

const getStepStatusBadge = step => {
  if (steps.value.length <= 1) return null;
  if (step.cancelled) return t('KANBAN.STATUS.CANCELLED');
  if (step.completed) return t('KANBAN.STATUS.COMPLETED');
  return null;
};

const getStepStatusBadgeClass = step => {
  if (step.cancelled) return 'bg-n-ruby-3 text-n-ruby-11';
  if (step.completed) return 'bg-n-teal-3 text-n-teal-11';
  return '';
};

const toggleStepFlag = async (step, flag, value) => {
  const oppositeFlag = flag === 'completed' ? 'cancelled' : 'completed';
  const previouslyFlaggedStep = value ? steps.value.find(s => s[flag] && s.id !== step.id) : null;
  const clearOpposite = value && step[oppositeFlag];
  const originalStep = { ...step };

  store.commit(`${NS}/UPDATE_STEP`, { ...step, [flag]: value, ...(clearOpposite ? { [oppositeFlag]: false } : {}) });
  if (previouslyFlaggedStep) store.commit(`${NS}/UPDATE_STEP`, { ...previouslyFlaggedStep, [flag]: false });

  try {
    const payload = { [flag]: value };
    if (clearOpposite) payload[oppositeFlag] = false;
    await updateStep({ boardId: boardId.value, stepId: step.id, step: payload });
    useAlert(t('KANBAN.SETTINGS.UPDATE_SUCCESS'));
  } catch (error) {
    store.commit(`${NS}/UPDATE_STEP`, originalStep);
    if (previouslyFlaggedStep) store.commit(`${NS}/UPDATE_STEP`, { ...previouslyFlaggedStep, [flag]: true });
    useAlert(parseAPIErrorResponse(error) || t('KANBAN.SETTINGS.UPDATE_ERROR'));
  }
};

const toggleStepCancelled = (step, value) => toggleStepFlag(step, 'cancelled', value);
const toggleStepCompleted = (step, value) => toggleStepFlag(step, 'completed', value);

const openCreateStepModal = () => { selectedStep.value = null; showStepModal.value = true; };
const openEditStepModal = step => { selectedStep.value = step; showStepModal.value = true; };
const closeStepModal = () => { showStepModal.value = false; selectedStep.value = null; };

const saveStep = async data => {
  isSavingStep.value = true;
  try {
    if (data.id) await updateStep({ boardId: boardId.value, stepId: data.id, step: data });
    else await createStep({ boardId: boardId.value, step: data });
    closeStepModal();
  } catch (error) {
    useAlert(parseAPIErrorResponse(error) || t('KANBAN.SETTINGS.UPDATE_ERROR'));
  } finally {
    isSavingStep.value = false;
  }
};

const deleteStep = async id => {
  isDeletingStep.value = true;
  try { await removeStep({ boardId: boardId.value, stepId: id }); closeStepModal(); } catch (error) {
    useAlert(parseAPIErrorResponse(error) || t('KANBAN.SETTINGS.UPDATE_ERROR'));
  } finally {
    isDeletingStep.value = false;
  }
};

const isStepDeletable = computed(() => !selectedStep.value || steps.value.length > 1);

const copyId = async () => {
  await copyTextToClipboard(boardId.value);
  useAlert(t('COMPONENTS.CODE.COPY_SUCCESSFUL'));
};

const openDeleteBoardDialog = () => { showDeleteBoardDialog.value = true; };
const closeDeleteBoardDialog = () => { showDeleteBoardDialog.value = false; };

const confirmDeleteBoard = async () => {
  if (isDeletingBoard.value) return;
  isDeletingBoard.value = true;
  try {
    await deleteBoard(boardId.value);
    router.push({ name: 'kanban_list', params: { accountId: route.params.accountId } });
  } catch (error) {
    useAlert(parseAPIErrorResponse(error) || t('KANBAN.SETTINGS.DELETE_ERROR'));
  } finally {
    isDeletingBoard.value = false;
    closeDeleteBoardDialog();
  }
};
</script>

<template>
  <div class="flex h-full w-full flex-col overflow-hidden bg-n-background font-inter">
    <div class="w-full flex justify-center px-6 sm:py-8 lg:px-16 pt-6 sm:pt-8 pb-4">
      <div class="w-full max-w-7xl">
        <SettingsLayout :is-loading="false">
          <template #header>
            <div class="flex items-center gap-4 w-full min-w-0">
              <router-link :to="{ name: 'kanban_board_show', params: { accountId: route.params.accountId, boardId } }" class="flex items-center">
                <Button icon="i-lucide-arrow-left" variant="ghost" color="slate" size="sm" />
              </router-link>
              <div v-if="!isDataLoaded" class="h-7 w-48 bg-n-slate-3 rounded animate-pulse" />
              <h1 v-else class="text-xl font-medium tracking-tight text-n-slate-12 truncate">{{ headerBoardName }}</h1>
              <span class="flex h-5 min-w-[1.25rem] items-center justify-center rounded-full bg-n-slate-5 px-2 text-xs font-medium text-n-slate-12 flex-shrink-0">{{ totalTasksCount }}</span>
              <div class="flex items-center gap-2 ml-auto flex-shrink-0">
                <span class="text-xs font-medium text-n-slate-11 whitespace-nowrap">{{ t('KANBAN.MODAL.ID_LABEL') }} {{ boardId }}</span>
                <Button variant="ghost" color="slate" size="xs" icon="i-lucide-copy" @click="copyId" />
              </div>
            </div>
          </template>
        </SettingsLayout>
      </div>
    </div>

    <div v-if="!isDataLoaded" class="flex-1 overflow-y-auto px-6 lg:px-16 scrollbar-custom flex justify-center">
      <div class="w-full max-w-7xl animate-pulse">
        <div class="flex flex-col gap-4 pb-6">
          <div v-for="i in 4" :key="i" class="h-24 w-full bg-n-slate-3 rounded-xl" />
        </div>
      </div>
    </div>

    <div v-else class="flex-1 overflow-y-auto px-6 lg:px-16 scrollbar-custom flex justify-center">
      <div class="w-full max-w-7xl">
        <div class="flex flex-col gap-4 pb-6">
          <!-- Basic Info -->
          <section class="flex flex-col gap-4">
            <div class="flex items-center justify-between">
              <h2 class="text-lg font-medium text-n-slate-12">{{ t('KANBAN.SETTINGS.BASIC_INFO') }}</h2>
              <Button :disabled="isSaving" size="sm" @click="saveBoardInfo">{{ t('KANBAN.SETTINGS.SAVE') }}</Button>
            </div>
            <div class="flex flex-col gap-4">
              <Input v-model="boardName" :label="t('KANBAN.SETTINGS.NAME_LABEL')" :placeholder="t('KANBAN.SETTINGS.NAME_PLACEHOLDER')" autocomplete="off" maxlength="60" />
              <Editor v-model="boardDescription" :label="t('KANBAN.SETTINGS.DESCRIPTION_LABEL')" :placeholder="t('KANBAN.SETTINGS.DESCRIPTION_PLACEHOLDER')" :max-length="2000" enable-line-breaks />
            </div>
          </section>

          <!-- Steps -->
          <section id="board-steps" class="flex flex-col gap-4">
            <div class="flex items-center gap-2">
              <h2 class="text-lg font-medium text-n-slate-12">{{ t('KANBAN.SETTINGS.STEPS') }}</h2>
              <span class="flex h-5 min-w-[1.25rem] items-center justify-center rounded-full bg-n-slate-5 px-2 text-xs font-medium text-n-slate-12">{{ stepsCount }}</span>
            </div>
            <Draggable v-if="stepsCount > 0" :model-value="steps" animation="200" ghost-class="ghost" item-key="id" handle=".drag-handle" class="flex flex-col gap-2" @update:model-value="updateStepsOrder">
              <template #item="{ element: step, index }">
                <div class="flex items-center gap-3 p-2 border rounded-lg border-n-slate-3 bg-n-alpha-1 hover:bg-n-alpha-2 transition-colors">
                  <button class="drag-handle cursor-grab active:cursor-grabbing text-n-slate-9 hover:text-n-slate-11">
                    <i class="i-lucide-grip-vertical w-5 h-5" />
                  </button>
                  <div class="w-3 h-3 rounded-full flex-shrink-0" :style="{ backgroundColor: step.color }" />
                  <div class="flex items-center gap-2 flex-1 min-w-0">
                    <span class="text-sm font-medium text-n-slate-12 truncate">{{ step.name }}</span>
                    <span class="flex h-5 min-w-[1.25rem] items-center justify-center rounded-full bg-n-slate-5 px-2 text-xs font-medium text-n-slate-12 flex-shrink-0">{{ getStepTaskCount(step.id) }}</span>
                    <span v-if="step.probability != null && step.probability < 100" class="flex h-5 items-center justify-center rounded-full bg-n-slate-3 px-2 text-xs font-medium text-n-slate-11 flex-shrink-0">{{ step.probability }}%</span>
                    <span v-if="getStepStatusBadge(step)" class="flex h-5 items-center justify-center rounded-full px-2 text-xs font-medium flex-shrink-0" :class="getStepStatusBadgeClass(step)">{{ getStepStatusBadge(step) }}</span>
                  </div>
                  <div v-if="canStepHaveStatusFlag(index)" class="flex items-center gap-2">
                    <span class="text-xs text-n-slate-11">{{ t('KANBAN.SETTINGS.COMPLETED_LABEL') }}</span>
                    <Switch :model-value="step.completed" size="sm" @update:model-value="toggleStepCompleted(step, $event)" />
                  </div>
                  <div v-if="canStepHaveStatusFlag(index)" class="flex items-center gap-2">
                    <span class="text-xs text-n-slate-11">{{ t('KANBAN.SETTINGS.CANCELLED_LABEL') }}</span>
                    <Switch :model-value="step.cancelled" size="sm" @update:model-value="toggleStepCancelled(step, $event)" />
                  </div>
                  <Button icon="i-lucide-pencil" variant="ghost" color="slate" size="xs" @click="openEditStepModal(step)" />
                </div>
              </template>
            </Draggable>
            <button type="button" class="flex items-center justify-center gap-2 p-3 border-2 border-dashed rounded-lg border-n-slate-3 bg-n-alpha-1 text-n-slate-11 hover:border-n-slate-4 hover:bg-n-alpha-2 hover:text-n-slate-12 transition-colors" @click="openCreateStepModal">
              <i class="i-lucide-plus w-4 h-4" />
              <span class="text-sm font-medium">{{ t('KANBAN.SETTINGS.ADD_STEP') }}</span>
            </button>
          </section>

          <!-- Agents -->
          <section id="board-agents" class="flex flex-col gap-4">
            <h2 class="text-lg font-medium text-n-slate-12">{{ t('KANBAN.SETTINGS.AGENTS') }}</h2>
            <TagMultiSelectComboBox :model-value="selectedAgents" :options="agentOptions" :placeholder="t('KANBAN.SETTINGS.AGENTS_PLACEHOLDER')" :search-placeholder="t('FORMS.MULTISELECT.ENTER_TO_SELECT')" :empty-state="t('KANBAN.SETTINGS.NO_AGENTS_AVAILABLE')" @update:model-value="handleAgentsChange" />
          </section>

          <!-- Inboxes -->
          <section id="board-inboxes" class="flex flex-col gap-4">
            <h2 class="text-lg font-medium text-n-slate-12">{{ t('KANBAN.SETTINGS.INBOXES') }}</h2>
            <TagMultiSelectComboBox :model-value="selectedInboxes" :options="inboxOptions" :placeholder="t('KANBAN.SETTINGS.INBOXES_PLACEHOLDER')" :search-placeholder="t('FORMS.MULTISELECT.ENTER_TO_SELECT')" :empty-state="t('KANBAN.SETTINGS.NO_INBOXES_AVAILABLE')" @update:model-value="handleInboxesChange" />
          </section>

          <!-- Opportunities (Currency + Products) -->
          <section id="board-opportunities" class="flex flex-col gap-4">
            <h2 class="text-lg font-medium text-n-slate-12">{{ t('KANBAN.SETTINGS.OPPORTUNITIES_TITLE') }}</h2>
            <div class="flex flex-col gap-1">
              <label class="text-sm font-medium text-n-slate-12">{{ t('KANBAN.SETTINGS.CURRENCY_LABEL') }}</label>
              <Select v-model="boardCurrency" :options="currencyOptions" />
            </div>
            <div class="flex flex-col gap-1">
              <label class="text-sm font-medium text-n-slate-12">{{ t('KANBAN.SETTINGS.PRODUCTS_LABEL') }}</label>
              <p class="text-sm text-n-slate-11">{{ t('KANBAN.SETTINGS.PRODUCTS_DESCRIPTION') }}</p>
              <router-link :to="{ name: 'kanban_board_products', params: { accountId: route.params.accountId, boardId: route.params.boardId } }">
                <Button variant="outline" size="sm" icon="i-lucide-package">{{ t('KANBAN.SETTINGS.MANAGE_PRODUCTS') }}</Button>
              </router-link>
            </div>
          </section>

          <!-- Automation -->
          <section id="board-automation" class="flex flex-col gap-4">
            <div class="flex flex-col gap-1">
              <h2 class="text-lg font-medium text-n-slate-12">{{ t('KANBAN.AUTOMATION.TITLE') }}</h2>
              <p class="text-sm text-n-slate-11">{{ t('KANBAN.AUTOMATION.SUBHEADER') }}</p>
            </div>
            <label v-for="(setting, key) in { autoCreateTaskForConversation: 'AUTO_CREATE_TASK', autoAssignTaskToAgent: 'AUTO_ASSIGN_TASK', syncTaskAndConversationAgents: 'SYNC_TASK_CONVERSATION_AGENTS', autoResolveConversationOnTaskEnd: 'AUTO_RESOLVE_CONVERSATION', autoCompleteTaskOnConversationResolve: 'AUTO_COMPLETE_TASK', syncTaskAndConversationLabelsPriority: 'SYNC_TASK_CONVERSATION_LABELS_PRIORITY' }" :key="key" class="flex items-start gap-3">
              <Switch
                :model-value="automationSettingRefs[key].value"
                @update:model-value="automationSettingRefs[key].value = $event"
              />
              <div class="flex flex-col gap-1">
                <span class="text-sm font-medium text-n-slate-12">{{ t(`KANBAN.AUTOMATION.${setting}`) }}</span>
                <span class="text-sm text-n-slate-11">{{ t(`KANBAN.AUTOMATION.${setting}_DESCRIPTION`) }}</span>
              </div>
            </label>
          </section>

          <!-- Delete Board -->
          <section class="flex flex-col gap-4 pt-4 border-t border-n-slate-6">
            <div class="flex flex-col gap-2">
              <h2 class="text-lg font-medium text-n-ruby-11">{{ t('KANBAN.SETTINGS.DELETE_BOARD') }}</h2>
              <p class="text-sm text-n-slate-11">{{ t('KANBAN.SETTINGS.DELETE_BOARD_WARNING') }}</p>
            </div>
            <Button variant="outline" color="ruby" size="sm" icon="i-lucide-trash-2" @click="openDeleteBoardDialog">{{ t('KANBAN.SETTINGS.DELETE_BOARD') }}</Button>
          </section>
        </div>
      </div>
    </div>

    <KanbanStepModal v-if="showStepModal" :show="showStepModal" :step="selectedStep" :board-name="boardName" :is-saving="isSavingStep" :is-deleting="isDeletingStep" :can-delete="isStepDeletable" @close="closeStepModal" @save="saveStep" @delete="deleteStep" />

    <woot-confirm-delete-modal
      v-if="showDeleteBoardDialog"
      v-model:show="showDeleteBoardDialog"
      :title="t('KANBAN.SETTINGS.DELETE_BOARD_CONFIRM_TITLE')"
      :message="t('KANBAN.SETTINGS.DELETE_BOARD_CONFIRM_MESSAGE', { name: boardName })"
      :confirm-text="t('KANBAN.SETTINGS.DELETE_BOARD_CONFIRM_YES', { name: boardName })"
      :reject-text="t('KANBAN.SETTINGS.DELETE_BOARD_CONFIRM_NO', { name: boardName })"
      :confirm-value="boardName"
      :confirm-place-holder-text="t('KANBAN.SETTINGS.DELETE_BOARD_PLACEHOLDER', { name: boardName })"
      :is-loading="isDeletingBoard"
      @on-confirm="confirmDeleteBoard"
      @on-close="closeDeleteBoardDialog"
    />
  </div>
</template>

<style scoped>
:deep(main) {
  @apply flex-1 flex flex-col min-h-0;
}

@keyframes highlight {
  0% { background-color: transparent; }
  20%, 50% { @apply bg-n-slate-3 dark:bg-n-alpha-2; }
  100% { background-color: transparent; }
}

.highlight-section {
  animation: highlight 2s ease-out;
  @apply rounded-lg -m-2 p-2;
}
</style>
