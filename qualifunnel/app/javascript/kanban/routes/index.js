import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import KanbanOverviewPage from '../pages/KanbanOverviewPage.vue';
import KanbanBoardPage from '../pages/KanbanBoardPage.vue';
import KanbanBoardSettingsPage from '../pages/KanbanBoardSettingsPage.vue';
import KanbanProductsPage from '../pages/KanbanProductsPage.vue';

const KANBAN_PERMISSIONS = ['administrator', 'agent', 'custom_role'];

export const kanbanRoutes = [
  {
    path: 'kanban/overview',
    name: 'kanban_list',
    component: KanbanOverviewPage,
    meta: { title: 'Kanban', permissions: KANBAN_PERMISSIONS },
  },
  {
    path: 'kanban/:boardId/settings',
    name: 'kanban_board_settings',
    component: KanbanBoardSettingsPage,
    meta: { title: 'Kanban Settings', permissions: KANBAN_PERMISSIONS, featureFlag: FEATURE_FLAGS.KANBAN },
  },
  {
    path: 'kanban/:boardId/products',
    name: 'kanban_board_products',
    component: KanbanProductsPage,
    meta: { title: 'Kanban Products', permissions: KANBAN_PERMISSIONS, featureFlag: FEATURE_FLAGS.KANBAN },
  },
  {
    path: 'kanban/:boardId?',
    name: 'kanban_board_show',
    component: KanbanBoardPage,
    meta: { title: 'Kanban Board', permissions: KANBAN_PERMISSIONS, featureFlag: FEATURE_FLAGS.KANBAN },
    children: [
      {
        path: 'create',
        name: 'kanban_task_create',
        component: KanbanBoardPage,
        meta: { permissions: KANBAN_PERMISSIONS, featureFlag: FEATURE_FLAGS.KANBAN },
      },
      {
        path: 'task/:taskId',
        name: 'kanban_task_show',
        component: KanbanBoardPage,
        meta: { permissions: KANBAN_PERMISSIONS, featureFlag: FEATURE_FLAGS.KANBAN },
      },
    ],
  },
];
