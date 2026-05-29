import KanbanOverviewPage from '../pages/KanbanOverviewPage.vue';
import KanbanBoardPage from '../pages/KanbanBoardPage.vue';

export const kanbanRoutes = [
  {
    path: 'kanban',
    name: 'kanban_overview',
    component: KanbanOverviewPage,
    meta: { title: 'Kanban' },
  },
  {
    path: 'kanban/boards/:boardId',
    name: 'kanban_board',
    component: KanbanBoardPage,
    meta: { title: 'Kanban Board' },
  },
];
