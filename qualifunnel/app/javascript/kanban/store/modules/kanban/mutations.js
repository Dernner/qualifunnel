import * as types from '../../mutation-types';

function recalcStepValues(state, stepId) {
  const step = state.steps.find(s => String(s.id) === String(stepId));
  if (!step) return;
  const tasks = state.stepTasks[stepId] || [];
  const total = tasks.reduce((sum, t) => {
    const v = Number(t.value);
    return sum + (Number.isNaN(v) ? 0 : v);
  }, 0);
  step.value_sum = total > 0 ? total : undefined;
  step.weighted_value_sum =
    total > 0 ? (total * (step.probability ?? 100)) / 100 : undefined;
}

export default {
  [types.SET_BOARDS](state, boards) {
    state.boards = boards;
  },
  [types.SET_SELECTED_BOARD_ID](state, id) {
    state.selectedBoardId = id;
  },
  [types.SET_STEPS](state, steps) {
    state.steps = Array.isArray(steps) ? steps : [];
  },
  [types.SET_KANBAN_LOADING](state, isLoading) {
    state.isLoading = isLoading;
  },
  [types.ADD_TASK](state, task) {
    const stepId = task.board_step_id;
    if (!state.stepTasks[stepId]) state.stepTasks[stepId] = [];
    if (!state.stepTasks[stepId].some(t => t.id === task.id)) {
      state.stepTasks[stepId] = [task, ...state.stepTasks[stepId]];
      const step = state.steps.find(s => String(s.id) === String(stepId));
      if (step) step.tasks_count += 1;
      recalcStepValues(state, stepId);
    }
  },
  [types.UPDATE_TASK](state, updatedTask) {
    let oldTask = null;
    let oldStepId = null;
    const stepIds = Object.keys(state.stepTasks);
    stepIds.some(stepId => {
      const found = state.stepTasks[stepId]?.find(t => t.id === updatedTask.id);
      if (found) { oldTask = found; oldStepId = stepId; return true; }
      return false;
    });

    if (!oldTask) return;

    const mergedTask = { ...oldTask, ...updatedTask };
    const newStepId = mergedTask.board_step_id;
    const stepsToRecalc = new Set();

    if (oldStepId !== String(newStepId) && oldStepId !== newStepId) {
      state.stepTasks[oldStepId] = state.stepTasks[oldStepId].filter(t => t.id !== mergedTask.id);
      if (!state.stepTasks[newStepId]) state.stepTasks[newStepId] = [];
      state.stepTasks[newStepId] = [...state.stepTasks[newStepId].filter(t => t.id !== mergedTask.id), mergedTask];

      const oldStep = state.steps.find(s => String(s.id) === String(oldStepId));
      if (oldStep && oldStep.tasks_count > 0) oldStep.tasks_count -= 1;
      const newStep = state.steps.find(s => String(s.id) === String(newStepId));
      if (newStep) newStep.tasks_count += 1;

      stepsToRecalc.add(String(oldStepId));
      stepsToRecalc.add(String(newStepId));
    } else {
      const stepIndex = state.stepTasks[oldStepId].findIndex(t => t.id === mergedTask.id);
      if (stepIndex !== -1) state.stepTasks[oldStepId].splice(stepIndex, 1, mergedTask);
      if (Number(oldTask.value) !== Number(mergedTask.value)) stepsToRecalc.add(String(oldStepId));
    }

    stepsToRecalc.forEach(stepId => recalcStepValues(state, stepId));
  },
  [types.MOVE_TASK](state, { task, sourceStepId, destinationStepId, insertBeforeTaskId }) {
    if (state.stepTasks[sourceStepId]) {
      state.stepTasks[sourceStepId] = state.stepTasks[sourceStepId].filter(t => t.id !== task.id);
    }
    if (!state.stepTasks[destinationStepId]) state.stepTasks[destinationStepId] = [];

    if (insertBeforeTaskId) {
      const index = state.stepTasks[destinationStepId].findIndex(t => t.id === insertBeforeTaskId);
      if (index !== -1) {
        state.stepTasks[destinationStepId].splice(index, 0, task);
      } else {
        state.stepTasks[destinationStepId].push(task);
      }
    } else {
      state.stepTasks[destinationStepId].push(task);
    }

    if (sourceStepId !== destinationStepId) {
      const oldStep = state.steps.find(s => String(s.id) === String(sourceStepId));
      if (oldStep && oldStep.tasks_count > 0) oldStep.tasks_count -= 1;
      const newStep = state.steps.find(s => String(s.id) === String(destinationStepId));
      if (newStep) newStep.tasks_count += 1;
      recalcStepValues(state, sourceStepId);
      recalcStepValues(state, destinationStepId);
    }
  },
  [types.DELETE_TASK](state, taskId) {
    const stepIds = Object.keys(state.stepTasks);
    stepIds.some(stepId => {
      const task = state.stepTasks[stepId]?.find(t => t.id === taskId);
      if (task) {
        state.stepTasks[stepId] = state.stepTasks[stepId].filter(t => t.id !== taskId);
        const step = state.steps.find(s => String(s.id) === String(stepId));
        if (step && step.tasks_count > 0) step.tasks_count -= 1;
        recalcStepValues(state, stepId);
        return true;
      }
      return false;
    });
  },
  [types.UPDATE_STEP](state, updatedStep) {
    const index = state.steps.findIndex(s => s.id === updatedStep.id);
    if (index !== -1) {
      const existing = state.steps[index];
      const merged = { ...existing, ...updatedStep };
      if (!('value_sum' in updatedStep) && existing.value_sum != null) {
        merged.weighted_value_sum = (existing.value_sum * (merged.probability ?? 100)) / 100;
      }
      state.steps.splice(index, 1, merged);
    }
  },
  [types.ADD_STEP](state, step) {
    if (!state.steps.some(s => s.id === step.id)) state.steps.push(step);
  },
  [types.ADD_BOARD](state, board) {
    state.boards.push(board);
  },
  [types.UPDATE_BOARD](state, updatedBoard) {
    const index = state.boards.findIndex(f => f.id === updatedBoard.id);
    if (index !== -1) state.boards.splice(index, 1, updatedBoard);
  },
  [types.DELETE_BOARD](state, boardId) {
    const index = state.boards.findIndex(f => f.id === boardId);
    if (index !== -1) state.boards.splice(index, 1);
  },
  [types.SET_KANBAN_PREFERENCES](state, preferences) {
    state.preferences = { ...state.preferences, ...preferences };
  },
  [types.SET_STEP_TASKS](state, { stepId, tasks }) {
    state.stepTasks = { ...state.stepTasks, [stepId]: tasks };
    state.stepFetched = { ...state.stepFetched, [stepId]: true };
  },
  [types.APPEND_STEP_TASKS](state, { stepId, tasks }) {
    const existing = state.stepTasks[stepId] || [];
    const newTaskIds = new Set(tasks.map(t => t.id));
    const filtered = existing.filter(t => !newTaskIds.has(t.id));
    state.stepTasks = { ...state.stepTasks, [stepId]: [...filtered, ...tasks] };
  },
  [types.SET_STEP_LOADING](state, { stepId, isLoading }) {
    state.stepLoading = { ...state.stepLoading, [stepId]: isLoading };
  },
  [types.SET_STEP_META](state, { stepId, meta }) {
    state.stepMeta = { ...state.stepMeta, [stepId]: meta };
  },
  [types.RESET_STEP_TASKS](state) {
    state.stepTasks = {};
    state.stepMeta = {};
    state.stepLoading = {};
    state.stepFetched = {};
    state.stepRequestVersion = {};
  },
  [types.INCREMENT_STEP_REQUEST_VERSION](state, stepId) {
    const current = state.stepRequestVersion[stepId] || 0;
    state.stepRequestVersion = { ...state.stepRequestVersion, [stepId]: current + 1 };
  },
  [types.SET_PRODUCTS](state, products) {
    state.products = Array.isArray(products) ? products : [];
  },
  [types.ADD_PRODUCT](state, product) {
    state.products = [product, ...state.products];
  },
  [types.UPDATE_PRODUCT](state, updatedProduct) {
    const index = state.products.findIndex(p => p.id === updatedProduct.id);
    if (index !== -1) state.products.splice(index, 1, updatedProduct);
  },
  [types.DELETE_PRODUCT](state, productId) {
    state.products = state.products.filter(p => p.id !== productId);
  },
};
