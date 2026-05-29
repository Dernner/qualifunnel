import axios from 'axios';

const getTasks = (accountId, boardId) =>
  axios.get(`/api/v1/accounts/${accountId}/kanban/boards/${boardId}/tasks`);

const createTask = (accountId, boardId, data) =>
  axios.post(
    `/api/v1/accounts/${accountId}/kanban/boards/${boardId}/tasks`,
    { task: data }
  );

const updateTask = (accountId, taskId, data) =>
  axios.patch(`/api/v1/accounts/${accountId}/kanban/tasks/${taskId}`, {
    task: data,
  });

const deleteTask = (accountId, taskId) =>
  axios.delete(`/api/v1/accounts/${accountId}/kanban/tasks/${taskId}`);

const moveTask = (accountId, taskId, boardStepId, position) =>
  axios.post(
    `/api/v1/accounts/${accountId}/kanban/tasks/${taskId}/move`,
    { board_step_id: boardStepId, position }
  );

export default {
  getTasks,
  createTask,
  updateTask,
  deleteTask,
  moveTask,
};
