/* global axios */
import ApiClient from 'dashboard/api/ApiClient';

class ProductsAPI extends ApiClient {
  constructor() {
    super('kanban/boards', { accountScoped: true, apiVersion: 'v1' });
  }

  get(boardId, params = {}) {
    return axios.get(`${this.url}/${boardId}/products`, { params });
  }

  create(boardId, data) {
    return axios.post(`${this.url}/${boardId}/products`, { product: data });
  }

  update(boardId, productId, data) {
    return axios.patch(`${this.url}/${boardId}/products/${productId}`, { product: data });
  }

  delete(boardId, productId) {
    return axios.delete(`${this.url}/${boardId}/products/${productId}`);
  }
}

export default new ProductsAPI();
