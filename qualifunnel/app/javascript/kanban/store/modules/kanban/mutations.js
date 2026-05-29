export const mutations = {
  SET_BOARDS(state, boards) {
    state.boards = boards;
  },

  ADD_BOARD(state, board) {
    state.boards.push(board);
  },

  UPDATE_BOARD(state, updatedBoard) {
    const idx = state.boards.findIndex(b => b.id === updatedBoard.id);
    if (idx !== -1) state.boards.splice(idx, 1, updatedBoard);
    if (state.currentBoard?.id === updatedBoard.id) {
      state.currentBoard = updatedBoard;
    }
  },

  REMOVE_BOARD(state, boardId) {
    state.boards = state.boards.filter(b => b.id !== boardId);
    if (state.currentBoard?.id === boardId) state.currentBoard = null;
  },

  SET_CURRENT_BOARD(state, board) {
    state.currentBoard = board;
  },

  SET_STEPS(state, steps) {
    state.steps = steps;
  },

  ADD_STEP(state, step) {
    state.steps.push(step);
  },

  SET_TASKS(state, tasks) {
    state.tasks = tasks;
  },

  ADD_TASK(state, task) {
    state.tasks.push(task);
  },

  UPDATE_TASK(state, updatedTask) {
    const idx = state.tasks.findIndex(t => t.id === updatedTask.id);
    if (idx !== -1) state.tasks.splice(idx, 1, updatedTask);
  },

  REMOVE_TASK(state, taskId) {
    state.tasks = state.tasks.filter(t => t.id !== taskId);
  },
};
