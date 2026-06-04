/* global axios */
import ApiClient from 'dashboard/api/ApiClient';

class TaskProductsAPI extends ApiClient {
  constructor() {
    super('kanban/tasks', { accountScoped: true, apiVersion: 'v1' });
  }

  get(taskId) {
    return axios.get(`${this.url}/${taskId}/products`);
  }

  create(taskId, data) {
    return axios.post(`${this.url}/${taskId}/products`, { task_product: data });
  }

  update(taskId, taskProductId, data) {
    return axios.patch(`${this.url}/${taskId}/products/${taskProductId}`, { task_product: data });
  }

  delete(taskId, taskProductId) {
    return axios.delete(`${this.url}/${taskId}/products/${taskProductId}`);
  }
}

export default new TaskProductsAPI();
