import boardsAPI from '../../../api/boards';
import tasksAPI from '../../../api/tasks';

export const actions = {
  async fetchBoards({ commit }, accountId) {
    const { data } = await boardsAPI.getBoards(accountId);
    commit('SET_BOARDS', data);
  },

  async fetchBoard({ commit }, { accountId, boardId }) {
    const [boardRes, stepsRes, tasksRes] = await Promise.all([
      boardsAPI.getBoard(accountId, boardId),
      boardsAPI.getSteps(accountId, boardId),
      tasksAPI.getTasks(accountId, boardId),
    ]);
    commit('SET_CURRENT_BOARD', boardRes.data);
    commit('SET_STEPS', stepsRes.data);
    commit('SET_TASKS', tasksRes.data);
  },

  async createBoard({ commit }, { accountId, data }) {
    const { data: board } = await boardsAPI.createBoard(accountId, data);
    commit('ADD_BOARD', board);
    return board;
  },

  async updateBoard({ commit }, { accountId, boardId, data }) {
    const { data: board } = await boardsAPI.updateBoard(accountId, boardId, data);
    commit('UPDATE_BOARD', board);
    return board;
  },

  async deleteBoard({ commit }, { accountId, boardId }) {
    await boardsAPI.deleteBoard(accountId, boardId);
    commit('REMOVE_BOARD', boardId);
  },

  async createStep({ commit }, { accountId, boardId, data }) {
    const { data: step } = await boardsAPI.createStep(accountId, boardId, data);
    commit('ADD_STEP', step);
    return step;
  },

  async createTask({ commit }, { accountId, boardId, data }) {
    const { data: task } = await tasksAPI.createTask(accountId, boardId, data);
    commit('ADD_TASK', task);
    return task;
  },

  async updateTask({ commit }, { accountId, taskId, data }) {
    const { data: task } = await tasksAPI.updateTask(accountId, taskId, data);
    commit('UPDATE_TASK', task);
    return task;
  },

  async moveTask({ commit }, { accountId, taskId, boardStepId, position }) {
    const { data: task } = await tasksAPI.moveTask(
      accountId,
      taskId,
      boardStepId,
      position
    );
    commit('UPDATE_TASK', task);
    return task;
  },

  async deleteTask({ commit }, { accountId, taskId }) {
    await tasksAPI.deleteTask(accountId, taskId);
    commit('REMOVE_TASK', taskId);
  },
};
