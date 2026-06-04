import * as types from '../../mutation-types';
import BoardsAPI from 'kanban/api/boards';
import PreferencesAPI from 'kanban/api/preferences';
import TasksAPI from 'kanban/api/tasks';
import ProductsAPI from 'kanban/api/products';

export default {
  async fetchBoards({ commit }, params = {}) {
    commit(types.SET_KANBAN_LOADING, true);
    try {
      const response = await BoardsAPI.get(params);
      const { boards, preferences } = response.data;
      if (preferences) commit(types.SET_KANBAN_PREFERENCES, preferences);
      commit(types.SET_BOARDS, boards);
    } catch {
      // ignore
    } finally {
      commit(types.SET_KANBAN_LOADING, false);
    }
  },

  async fetchSteps({ commit, state }, { boardId, agentId, inboxId } = {}) {
    const targetBoardId = boardId || state.selectedBoardId;
    if (!targetBoardId) return;
    try {
      const response = await BoardsAPI.getSteps(targetBoardId, { agentId, inboxId });
      if (state.selectedBoardId === targetBoardId) {
        const steps = Array.isArray(response.data)
          ? response.data
          : response.data.steps || [];
        commit(types.SET_STEPS, steps);
      }
    } catch {
      // ignore
    }
  },

  async setActiveBoard({ commit, dispatch }, { boardId, agentId, inboxId }) {
    commit(types.SET_KANBAN_LOADING, true);
    commit(types.SET_SELECTED_BOARD_ID, boardId);
    commit(types.SET_STEPS, []);
    try {
      await dispatch('fetchSteps', { boardId, agentId, inboxId });
    } finally {
      commit(types.SET_KANBAN_LOADING, false);
    }
  },

  async toggleFavoriteBoard({ commit, state }, boardId) {
    const previousFavorites = [...(state.preferences.favorite_board_ids || [])];
    const newFavorites = previousFavorites.includes(boardId)
      ? previousFavorites.filter(id => id !== boardId)
      : [...previousFavorites, boardId];

    commit(types.SET_KANBAN_PREFERENCES, { ...state.preferences, favorite_board_ids: newFavorites });

    try {
      const response = await BoardsAPI.toggleFavorite(boardId);
      const { favorite_board_ids } = response.data;
      commit(types.SET_KANBAN_PREFERENCES, { ...state.preferences, favorite_board_ids });
    } catch {
      commit(types.SET_KANBAN_PREFERENCES, { ...state.preferences, favorite_board_ids: previousFavorites });
    }
  },

  async createBoard({ commit }, boardData) {
    const response = await BoardsAPI.create(boardData);
    commit(types.ADD_BOARD, response.data);
    return response.data;
  },

  async createTask({ commit }, taskData) {
    const response = await TasksAPI.create(taskData);
    commit(types.ADD_TASK, response.data);
    return response.data;
  },

  async updateTask({ commit, state }, { id, task }) {
    let originalTask = null;
    const stepIds = Object.keys(state.stepTasks);
    stepIds.some(stepId => {
      originalTask = state.stepTasks[stepId]?.find(t => t.id === id);
      return !!originalTask;
    });

    if (originalTask) {
      commit(types.UPDATE_TASK, { ...originalTask, ...(task || {}) });
    }

    try {
      const response = await TasksAPI.update(id, { task });
      commit(types.UPDATE_TASK, response.data);
      return response.data;
    } catch (error) {
      if (originalTask) commit(types.UPDATE_TASK, originalTask);
      throw error;
    }
  },

  async moveTask(
    { commit, state, dispatch },
    { taskId, destinationStepId, insertBeforeTaskId, refreshStepId = null }
  ) {
    let task = null;
    const stepIds = Object.keys(state.stepTasks);
    stepIds.some(stepId => {
      task = state.stepTasks[stepId]?.find(t => t.id === taskId);
      return !!task;
    });
    if (!task) return;

    const sourceStepId = task.board_step_id;

    const getTasksOrder = stepId => state.preferences.tasks_order?.[stepId] || [];
    let sourceStepTasksOrder = [...getTasksOrder(sourceStepId)].filter(id => id !== taskId);
    let destinationStepTasksOrder =
      sourceStepId === destinationStepId ? [...sourceStepTasksOrder] : [...getTasksOrder(destinationStepId)];

    if (insertBeforeTaskId) {
      const index = destinationStepTasksOrder.indexOf(insertBeforeTaskId);
      if (index !== -1) {
        destinationStepTasksOrder.splice(index, 0, taskId);
      } else {
        destinationStepTasksOrder.push(taskId);
      }
    } else {
      destinationStepTasksOrder.push(taskId);
    }

    commit(types.MOVE_TASK, {
      task: { ...task, board_step_id: destinationStepId },
      sourceStepId,
      destinationStepId,
      insertBeforeTaskId,
    });

    const originalPreferences = { ...state.preferences };
    commit(types.SET_KANBAN_PREFERENCES, {
      ...state.preferences,
      tasks_order: {
        ...(state.preferences.tasks_order || {}),
        [sourceStepId]: sourceStepTasksOrder,
        [destinationStepId]: destinationStepTasksOrder,
      },
    });

    try {
      await TasksAPI.move(taskId, {
        board_step_id: destinationStepId,
        insert_before_task_id: insertBeforeTaskId,
      });

      if (refreshStepId) {
        dispatch('fetchTasksForStep', { stepId: refreshStepId, page: 1, perPage: 10 });
      }
    } catch {
      commit(types.UPDATE_TASK, task);
      commit(types.SET_KANBAN_PREFERENCES, originalPreferences);
    }
  },

  async deleteTask({ commit }, id) {
    await TasksAPI.delete(id);
    commit(types.DELETE_TASK, id);
  },

  async updateStep({ commit, state }, { boardId, stepId, ...data }) {
    const originalStep = state.steps.find(s => s.id === stepId);
    if (originalStep && data.step) {
      commit(types.UPDATE_STEP, { ...originalStep, ...data.step });
    }

    try {
      const response = await BoardsAPI.updateStep(boardId, stepId, data);
      commit(types.UPDATE_STEP, response.data);
      return response.data;
    } catch (error) {
      if (originalStep) commit(types.UPDATE_STEP, originalStep);
      throw error;
    }
  },

  async deleteStep({ dispatch, commit }, { boardId, stepId }) {
    await BoardsAPI.deleteStep(boardId, stepId);
    commit(types.RESET_STEP_TASKS);
    await dispatch('fetchSteps', { boardId });
  },

  async createStep({ commit }, { boardId, ...stepData }) {
    const response = await BoardsAPI.createStep(boardId, stepData);
    commit(types.ADD_STEP, response.data);
    return response.data;
  },

  async updateBoard({ commit }, { id, board }) {
    const response = await BoardsAPI.update(id, { board });
    commit(types.UPDATE_BOARD, response.data);
    return response.data;
  },

  async updateBoardAgents({ commit }, { boardId, agentIds }) {
    const response = await BoardsAPI.updateAgents(boardId, agentIds);
    commit(types.UPDATE_BOARD, response.data);
    return response.data;
  },

  async updateBoardInboxes({ commit }, { boardId, inboxIds }) {
    const response = await BoardsAPI.updateInboxes(boardId, inboxIds);
    commit(types.UPDATE_BOARD, response.data);
    return response.data;
  },

  async deleteBoard({ commit }, boardId) {
    await BoardsAPI.delete(boardId);
    commit(types.DELETE_BOARD, boardId);
  },

  async updateBoardFilters({ commit, state }, { boardId, agentId, inboxId, showCompleted, showCancelled }) {
    const previousPreferences = { ...state.preferences };
    commit(types.SET_KANBAN_PREFERENCES, {
      ...state.preferences,
      board_filters: {
        ...(state.preferences.board_filters || {}),
        [boardId]: { agent_id: agentId, inbox_id: inboxId, show_completed: showCompleted, show_cancelled: showCancelled },
      },
    });

    try {
      await PreferencesAPI.update({
        board_filters: { [boardId]: { agent_id: agentId, inbox_id: inboxId, show_completed: showCompleted, show_cancelled: showCancelled } },
      });
    } catch {
      commit(types.SET_KANBAN_PREFERENCES, previousPreferences);
    }
  },

  addTaskFromEvent({ commit }, task) {
    commit(types.ADD_TASK, task);
  },

  updateTaskFromEvent({ commit, state }, task) {
    let currentStepId = null;
    const stepIds = Object.keys(state.stepTasks);
    stepIds.some(stepId => {
      const found = state.stepTasks[stepId]?.find(t => t.id === task.id);
      if (found) { currentStepId = stepId; return true; }
      return false;
    });

    const newStepId = task.board_step_id;
    const stepChanged =
      currentStepId &&
      String(currentStepId) !== String(newStepId) &&
      currentStepId !== newStepId;

    const hasMovePositionInfo = Object.hasOwn(task, 'insert_before_task_id');

    if (hasMovePositionInfo && currentStepId) {
      commit(types.MOVE_TASK, {
        task: { ...task, board_step_id: newStepId },
        sourceStepId: currentStepId,
        destinationStepId: newStepId,
        insertBeforeTaskId: task.insert_before_task_id,
      });
    } else if (stepChanged) {
      commit(types.MOVE_TASK, {
        task: { ...task, board_step_id: newStepId },
        sourceStepId: currentStepId,
        destinationStepId: newStepId,
        insertBeforeTaskId: null,
      });
    } else {
      commit(types.UPDATE_TASK, task);
    }
  },

  deleteTaskFromEvent({ commit }, taskId) {
    commit(types.DELETE_TASK, taskId);
  },

  addStepFromEvent({ commit }, step) {
    commit(types.ADD_STEP, step);
  },

  updateStepFromEvent({ commit }, step) {
    commit(types.UPDATE_STEP, step);
  },

  updateBoardFromEvent({ commit }, board) {
    commit(types.UPDATE_BOARD, board);
  },

  async fetchTasksForStep({ commit, state }, { stepId, page = 1, perPage = 10, append = false }) {
    if (state.stepLoading[stepId]) return;

    commit(types.INCREMENT_STEP_REQUEST_VERSION, stepId);
    const requestVersion = state.stepRequestVersion[stepId];
    commit(types.SET_STEP_LOADING, { stepId, isLoading: true });

    try {
      const activeBoardId = state.selectedBoardId;
      const savedSort = state.preferences.task_sorting?.[activeBoardId] || {};
      const sort = savedSort.sort || 'position';
      const order = savedSort.order || 'asc';
      const boardFilters = state.preferences.board_filters?.[activeBoardId] || {};
      const agentId = boardFilters.agent_id;
      const inboxId = boardFilters.inbox_id;

      const response = await TasksAPI.getByStep(stepId, {
        page,
        perPage,
        sort: sort === 'position' ? undefined : sort,
        order: sort === 'position' ? undefined : order,
        agentId: agentId !== 'all' ? agentId : undefined,
        inboxId: inboxId !== 'all' ? inboxId : undefined,
      });

      if (state.stepRequestVersion[stepId] !== requestVersion) return;

      const { tasks, meta } = response.data;

      if (append) {
        commit(types.APPEND_STEP_TASKS, { stepId, tasks });
      } else {
        commit(types.SET_STEP_TASKS, { stepId, tasks });
      }

      if (meta) {
        const actualHasMore = meta.has_more && tasks.length > 0;
        commit(types.SET_STEP_META, {
          stepId,
          meta: { totalCount: meta.total_count, page: meta.page, perPage: meta.per_page, hasMore: actualHasMore },
        });
      }
    } catch {
      commit(types.SET_STEP_META, {
        stepId,
        meta: { ...state.stepMeta[stepId], hasMore: false },
      });
    } finally {
      commit(types.SET_STEP_LOADING, { stepId, isLoading: false });
    }
  },

  async fetchMoreTasksForStep({ dispatch, state }, stepId) {
    const meta = state.stepMeta[stepId];
    if (!meta || !meta.hasMore) return;
    await dispatch('fetchTasksForStep', { stepId, page: meta.page + 1, perPage: meta.perPage, append: true });
  },

  async initializeStepTasks({ commit, dispatch }, { stepIds }) {
    commit(types.RESET_STEP_TASKS);
    await Promise.all(stepIds.map(stepId => dispatch('fetchTasksForStep', { stepId, page: 1, perPage: 10 })));
  },

  resetStepTasks({ commit }) {
    commit(types.RESET_STEP_TASKS);
  },

  async updateTaskSorting({ commit, state }, { boardId, sort, order }) {
    const previousPreferences = { ...state.preferences };
    const newPreferences = {
      ...state.preferences,
      task_sorting: { ...(state.preferences.task_sorting || {}), [boardId]: { sort, order } },
    };
    commit(types.SET_KANBAN_PREFERENCES, newPreferences);

    try {
      await PreferencesAPI.update({ task_sorting: newPreferences.task_sorting });
    } catch {
      commit(types.SET_KANBAN_PREFERENCES, previousPreferences);
    }
  },

  async fetchProducts({ commit }, { boardId }) {
    try {
      const response = await ProductsAPI.get(boardId);
      const products = Array.isArray(response.data)
        ? response.data
        : response.data.products || [];
      commit(types.SET_PRODUCTS, products);
    } catch {
      // ignore
    }
  },

  async createProduct({ commit }, { boardId, productData }) {
    const response = await ProductsAPI.create(boardId, productData);
    commit(types.ADD_PRODUCT, response.data);
    return response.data;
  },

  async updateProduct({ commit }, { boardId, productId, productData }) {
    const response = await ProductsAPI.update(boardId, productId, productData);
    commit(types.UPDATE_PRODUCT, response.data);
    return response.data;
  },

  async deleteProduct({ commit }, { boardId, productId }) {
    await ProductsAPI.delete(boardId, productId);
    commit(types.DELETE_PRODUCT, productId);
  },
};
