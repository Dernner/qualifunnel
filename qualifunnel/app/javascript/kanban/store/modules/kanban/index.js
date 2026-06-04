import actions from './actions';
import getters from './getters';
import mutations from './mutations';

const state = {
  boards: [],
  selectedBoardId: null,
  steps: [],
  isLoading: false,
  preferences: {},
  products: [],
  stepTasks: {},
  stepMeta: {},
  stepLoading: {},
  stepFetched: {},
  stepRequestVersion: {},
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
