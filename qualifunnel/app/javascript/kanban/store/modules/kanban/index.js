import { actions } from './actions';
import { mutations } from './mutations';

const state = {
  boards: [],
  currentBoard: null,
  steps: [],
  tasks: [],
};

const getters = {
  allBoards: s => s.boards,
  currentBoard: s => s.currentBoard,
  stepsForCurrentBoard: s => s.steps,
  tasksForStep: s => stepId =>
    s.tasks
      .filter(t => t.board_step_id === stepId)
      .sort((a, b) => a.position - b.position),
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
