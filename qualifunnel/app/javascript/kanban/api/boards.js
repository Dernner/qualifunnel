import axios from 'axios';

const getBoards = accountId =>
  axios.get(`/api/v1/accounts/${accountId}/kanban/boards`);

const getBoard = (accountId, boardId) =>
  axios.get(`/api/v1/accounts/${accountId}/kanban/boards/${boardId}`);

const createBoard = (accountId, data) =>
  axios.post(`/api/v1/accounts/${accountId}/kanban/boards`, { board: data });

const updateBoard = (accountId, boardId, data) =>
  axios.patch(`/api/v1/accounts/${accountId}/kanban/boards/${boardId}`, {
    board: data,
  });

const deleteBoard = (accountId, boardId) =>
  axios.delete(`/api/v1/accounts/${accountId}/kanban/boards/${boardId}`);

const getSteps = (accountId, boardId) =>
  axios.get(
    `/api/v1/accounts/${accountId}/kanban/boards/${boardId}/steps`
  );

const createStep = (accountId, boardId, data) =>
  axios.post(
    `/api/v1/accounts/${accountId}/kanban/boards/${boardId}/steps`,
    { step: data }
  );

const updateStep = (accountId, boardId, stepId, data) =>
  axios.patch(
    `/api/v1/accounts/${accountId}/kanban/boards/${boardId}/steps/${stepId}`,
    { step: data }
  );

const deleteStep = (accountId, boardId, stepId) =>
  axios.delete(
    `/api/v1/accounts/${accountId}/kanban/boards/${boardId}/steps/${stepId}`
  );

export default {
  getBoards,
  getBoard,
  createBoard,
  updateBoard,
  deleteBoard,
  getSteps,
  createStep,
  updateStep,
  deleteStep,
};
