<script setup>
import { computed, ref, onMounted, watch, nextTick } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import { intlLocale } from 'kanban/constants';
import { useAlert } from 'dashboard/composables';
import { useAdmin } from 'dashboard/composables/useAdmin';
import SettingsLayout from 'dashboard/routes/dashboard/settings/SettingsLayout.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import { parseAPIErrorResponse } from 'dashboard/store/utils/api';

const router = useRouter();
const route = useRoute();
const store = useStore();
const { t, locale } = useI18n();
const { isAdmin } = useAdmin();

const NS = 'qualifunnel/kanban';

const boardId = computed(() => Number(route.params.boardId));
const activeBoard = computed(() => store.getters[`${NS}/activeBoard`]);
const products = computed(() => store.getters[`${NS}/getProducts`]);

const PRODUCT_SORT_KEY = 'kanban_product_sorting';
const loadSortState = () => { try { const s = localStorage.getItem(PRODUCT_SORT_KEY); return s ? JSON.parse(s) : null; } catch { return null; } };

const savedSort = loadSortState();
const searchQuery = ref('');
const showArchived = ref(false);
const activeSort = ref(savedSort?.sort || 'name');
const activeOrdering = ref(savedSort?.order || 'asc');
const isDataLoaded = ref(false);
const showProductModal = ref(false);
const editingProduct = ref(null);
const isSaving = ref(false);
const showDeleteDialog = ref(false);
const showDiscardDialog = ref(false);
const deletingProductId = ref(null);
const isDeleting = ref(false);
const productName = ref('');
const productDescription = ref('');
const productUnitPrice = ref('');

const filteredProducts = computed(() => {
  let list = products.value;
  if (!showArchived.value) list = list.filter(p => !p.archived);
  if (searchQuery.value.trim()) {
    const query = searchQuery.value.toLowerCase();
    list = list.filter(p => p.name.toLowerCase().includes(query) || (p.description && p.description.toLowerCase().includes(query)));
  }
  const sorted = [...list].sort((a, b) => {
    let cmp = 0;
    if (activeSort.value === 'name') cmp = (a.name || '').localeCompare(b.name || '');
    else if (activeSort.value === 'unit_price') cmp = (a.unit_price || 0) - (b.unit_price || 0);
    return activeOrdering.value === 'desc' ? -cmp : cmp;
  });
  return sorted;
});

const toggleColumnSort = field => {
  if (activeSort.value === field) activeOrdering.value = activeOrdering.value === 'asc' ? 'desc' : 'asc';
  else { activeSort.value = field; activeOrdering.value = 'asc'; }
  localStorage.setItem(PRODUCT_SORT_KEY, JSON.stringify({ sort: activeSort.value, order: activeOrdering.value }));
};

const archivedCount = computed(() => products.value.filter(p => p.archived).length);
const currency = computed(() => activeBoard.value?.currency || 'USD');

const currencySymbol = computed(() => {
  return new Intl.NumberFormat(intlLocale(locale.value), { style: 'currency', currency: currency.value })
    .formatToParts(0).find(p => p.type === 'currency')?.value || currency.value;
});

const formatCurrency = value => {
  if (value === null || value === undefined) return '-';
  return new Intl.NumberFormat(intlLocale(locale.value), { style: 'currency', currency: currency.value, minimumFractionDigits: 2, maximumFractionDigits: 2 }).format(value);
};

const formatPriceInput = val => { const num = parseFloat(val); return Number.isNaN(num) ? '' : num.toFixed(2); };

const hasModalChanges = computed(() => {
  if (editingProduct.value) {
    return productName.value !== editingProduct.value.name ||
      productDescription.value !== (editingProduct.value.description || '') ||
      productUnitPrice.value !== formatPriceInput(editingProduct.value.unit_price);
  }
  return productName.value !== '' || productDescription.value !== '' || productUnitPrice.value !== '';
});

const openCreateModal = () => {
  editingProduct.value = null;
  productName.value = ''; productDescription.value = ''; productUnitPrice.value = '';
  showProductModal.value = true;
};
const openEditModal = product => {
  editingProduct.value = product;
  productName.value = product.name; productDescription.value = product.description || ''; productUnitPrice.value = formatPriceInput(product.unit_price);
  showProductModal.value = true;
};
const dismissProductModal = () => {
  productName.value = ''; productDescription.value = ''; productUnitPrice.value = '';
  editingProduct.value = null; showProductModal.value = false;
};
const handleClose = () => { if (isSaving.value) return; if (hasModalChanges.value) showDiscardDialog.value = true; else dismissProductModal(); };
const shouldIgnoreClickOutside = computed(() => hasModalChanges.value || showDiscardDialog.value || isSaving.value);

const saveProduct = async () => {
  if (!productName.value.trim()) return;
  isSaving.value = true;
  try {
    const productData = { name: productName.value.trim(), description: productDescription.value.trim(), unit_price: productUnitPrice.value ? parseFloat(productUnitPrice.value) : 0 };
    if (editingProduct.value) {
      await store.dispatch(`${NS}/updateProduct`, { boardId: boardId.value, productId: editingProduct.value.id, productData });
      useAlert(t('KANBAN.PRODUCTS.UPDATE_SUCCESS'));
    } else {
      await store.dispatch(`${NS}/createProduct`, { boardId: boardId.value, productData });
      useAlert(t('KANBAN.PRODUCTS.CREATE_SUCCESS'));
    }
    dismissProductModal();
  } catch (error) {
    useAlert(parseAPIErrorResponse(error) || t('KANBAN.PRODUCTS.SAVE_ERROR'));
  } finally {
    isSaving.value = false;
  }
};

const toggleArchived = async product => {
  try {
    await store.dispatch(`${NS}/updateProduct`, { boardId: boardId.value, productId: product.id, productData: { archived: !product.archived } });
  } catch (error) {
    useAlert(parseAPIErrorResponse(error) || t('KANBAN.PRODUCTS.SAVE_ERROR'));
  }
};

const confirmDelete = product => { deletingProductId.value = product.id; showDeleteDialog.value = true; };
const deleteProduct = async () => {
  isDeleting.value = true;
  try {
    await store.dispatch(`${NS}/deleteProduct`, { boardId: boardId.value, productId: deletingProductId.value });
    showDeleteDialog.value = false;
    useAlert(t('KANBAN.PRODUCTS.DELETE_SUCCESS'));
  } catch (error) {
    useAlert(parseAPIErrorResponse(error) || t('KANBAN.PRODUCTS.DELETE_ERROR'));
  } finally {
    isDeleting.value = false; deletingProductId.value = null;
  }
};

onMounted(async () => {
  if (!isAdmin.value) { router.push({ name: 'kanban_board_show', params: { boardId: boardId.value } }); return; }
  await store.dispatch(`${NS}/fetchBoards`);
  if (boardId.value) {
    await store.dispatch(`${NS}/setActiveBoard`, { boardId: boardId.value });
    await store.dispatch(`${NS}/fetchProducts`, { boardId: boardId.value });
    isDataLoaded.value = true;
  }
});

const productModalRef = ref(null);
const discardDialogRef = ref(null);
watch(showProductModal, async val => { if (val) { await nextTick(); productModalRef.value?.open(); } else productModalRef.value?.close(); });
watch(showDiscardDialog, async val => { if (val) { await nextTick(); discardDialogRef.value?.open(); } });
</script>

<template>
  <div class="flex h-full w-full flex-col overflow-hidden bg-n-background font-inter">
    <div class="w-full flex justify-center px-6 sm:py-8 lg:px-16 pt-6 sm:pt-8 pb-4">
      <div class="w-full max-w-7xl">
        <SettingsLayout :is-loading="false">
          <template #header>
            <div class="flex items-center gap-4 w-full min-w-0">
              <router-link :to="{ name: 'kanban_board_settings', params: { accountId: route.params.accountId, boardId } }" class="flex items-center">
                <Button icon="i-lucide-arrow-left" variant="ghost" color="slate" size="sm" />
              </router-link>
              <h1 class="text-xl font-medium tracking-tight text-n-slate-12 truncate">{{ t('KANBAN.PRODUCTS.PAGE_TITLE') }}</h1>
              <span v-if="isDataLoaded" class="flex h-5 min-w-[1.25rem] items-center justify-center rounded-full bg-n-slate-5 px-2 text-xs font-medium text-n-slate-12 flex-shrink-0">{{ products.length }}</span>
            </div>
          </template>
        </SettingsLayout>
      </div>
    </div>

    <div v-if="!isDataLoaded" class="flex-1 flex items-center justify-center">
      <div class="animate-pulse flex flex-col gap-4 w-full max-w-7xl px-6">
        <div v-for="i in 5" :key="i" class="h-14 w-full bg-n-slate-3 rounded-lg" />
      </div>
    </div>

    <div v-else class="flex-1 overflow-y-auto px-6 lg:px-16 scrollbar-custom flex justify-center">
      <div class="w-full max-w-7xl">
        <div class="flex flex-col gap-4 pb-6">
          <div class="flex items-center justify-between gap-4">
            <div class="flex items-center gap-3">
              <div class="relative max-w-sm w-full">
                <span class="i-lucide-search size-4 text-n-slate-10 absolute left-3.5 top-1/2 -translate-y-1/2 pointer-events-none z-10" />
                <Input v-model="searchQuery" :placeholder="t('KANBAN.PRODUCTS.SEARCH_PLACEHOLDER')" class="w-full [&_input]:!pl-10" />
              </div>
              <label v-if="archivedCount > 0" class="flex items-center gap-2 text-sm text-n-slate-11 whitespace-nowrap cursor-pointer select-none">
                <input v-model="showArchived" type="checkbox" class="rounded border-n-slate-6" />
                {{ t('KANBAN.PRODUCTS.SHOW_ARCHIVED') }} ({{ archivedCount }})
              </label>
            </div>
            <Button icon="i-lucide-plus" size="sm" @click="openCreateModal">{{ t('KANBAN.PRODUCTS.ADD_PRODUCT') }}</Button>
          </div>

          <div v-if="filteredProducts.length === 0" class="flex flex-col items-center justify-center py-16 text-n-slate-11">
            <span class="i-lucide-package size-12 mb-4 text-n-slate-8" />
            <p class="text-sm">{{ t('KANBAN.PRODUCTS.EMPTY_STATE') }}</p>
          </div>

          <div v-else class="flex flex-col gap-1">
            <div class="grid grid-cols-12 gap-4 px-4 py-2 text-xs font-medium text-n-slate-11 uppercase tracking-wider">
              <button class="col-span-5 flex items-center gap-1 cursor-pointer hover:text-n-slate-12 transition-colors" @click="toggleColumnSort('name')">
                {{ t('KANBAN.PRODUCTS.TABLE.NAME') }}
                <span v-if="activeSort === 'name'" :class="activeOrdering === 'asc' ? 'i-lucide-arrow-up' : 'i-lucide-arrow-down'" class="size-3" />
              </button>
              <div class="col-span-3">{{ t('KANBAN.PRODUCTS.TABLE.DESCRIPTION') }}</div>
              <button class="col-span-2 flex items-center gap-1 justify-end cursor-pointer hover:text-n-slate-12 transition-colors" @click="toggleColumnSort('unit_price')">
                {{ t('KANBAN.PRODUCTS.TABLE.UNIT_PRICE') }}
                <span v-if="activeSort === 'unit_price'" :class="activeOrdering === 'asc' ? 'i-lucide-arrow-up' : 'i-lucide-arrow-down'" class="size-3" />
              </button>
              <div class="col-span-2 text-right">{{ t('KANBAN.PRODUCTS.TABLE.ACTIONS') }}</div>
            </div>
            <div v-for="product in filteredProducts" :key="product.id" class="grid grid-cols-12 gap-4 px-4 py-3 items-center rounded-lg border border-n-slate-3 bg-n-alpha-1 hover:bg-n-alpha-2 transition-colors" :class="{ 'opacity-60': product.archived }">
              <div class="col-span-5 flex items-center gap-2 min-w-0">
                <span v-if="product.archived" v-tooltip="t('KANBAN.PRODUCTS.ARCHIVED')" class="i-lucide-archive size-4 text-n-slate-10 flex-shrink-0" />
                <span class="text-sm font-medium text-n-slate-12 truncate">{{ product.name }}</span>
              </div>
              <div class="col-span-3"><span class="text-sm text-n-slate-11 line-clamp-1">{{ product.description || '-' }}</span></div>
              <div class="col-span-2 text-right"><span class="text-sm font-medium text-n-slate-12">{{ formatCurrency(product.unit_price) }}</span></div>
              <div class="col-span-2 flex items-center justify-end gap-1">
                <Button v-tooltip="product.archived ? t('KANBAN.PRODUCTS.UNARCHIVE') : t('KANBAN.PRODUCTS.ARCHIVE')" variant="ghost" color="slate" size="xs" :icon="product.archived ? 'i-lucide-archive-restore' : 'i-lucide-archive'" @click="toggleArchived(product)" />
                <Button variant="ghost" color="slate" size="xs" icon="i-lucide-pencil" @click="openEditModal(product)" />
                <Button variant="ghost" color="slate" size="xs" icon="i-lucide-trash-2" class="text-n-slate-11 hover:text-n-ruby-11" @click="confirmDelete(product)" />
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <Dialog v-if="showProductModal" ref="productModalRef" :title="editingProduct ? t('KANBAN.PRODUCTS.EDIT_PRODUCT') : t('KANBAN.PRODUCTS.ADD_PRODUCT')" :ignore-click-outside="shouldIgnoreClickOutside" @close="handleClose" @click-outside="handleClose">
      <div class="flex flex-col gap-4">
        <label class="flex flex-col gap-2 text-sm font-medium text-n-slate-12">
          {{ t('KANBAN.PRODUCTS.FORM.NAME_LABEL') }}
          <Input v-model="productName" :placeholder="t('KANBAN.PRODUCTS.FORM.NAME_PLACEHOLDER')" maxlength="255" autocomplete="off" />
        </label>
        <label class="flex flex-col gap-2 text-sm font-medium text-n-slate-12">
          {{ t('KANBAN.PRODUCTS.FORM.DESCRIPTION_LABEL') }}
          <Input v-model="productDescription" :placeholder="t('KANBAN.PRODUCTS.FORM.DESCRIPTION_PLACEHOLDER')" maxlength="500" autocomplete="off" />
        </label>
        <label class="flex flex-col gap-2 text-sm font-medium text-n-slate-12">
          {{ t('KANBAN.PRODUCTS.FORM.UNIT_PRICE_LABEL_WITH_CURRENCY', { symbol: currencySymbol }) }}
          <Input v-model="productUnitPrice" type="number" :placeholder="t('KANBAN.PRODUCTS.FORM.UNIT_PRICE_PLACEHOLDER')" min="0" step="0.01" autocomplete="off" />
        </label>
      </div>
      <template #footer>
        <div class="flex justify-end gap-2">
          <Button variant="ghost" @click="handleClose">{{ t('KANBAN.PRODUCTS.FORM.CANCEL') }}</Button>
          <Button :disabled="!productName.trim() || isSaving" :is-loading="isSaving" @click="saveProduct">
            {{ editingProduct ? t('KANBAN.PRODUCTS.FORM.UPDATE') : t('KANBAN.PRODUCTS.FORM.CREATE') }}
          </Button>
        </div>
      </template>
    </Dialog>

    <Dialog v-if="showDiscardDialog" ref="discardDialogRef" type="alert" :title="t('KANBAN.PRODUCTS.DISCARD_TITLE')" :description="t('KANBAN.PRODUCTS.DISCARD_CONFIRMATION')" @close="showDiscardDialog = false">
      <template #footer>
        <div class="flex items-center justify-between w-full gap-3">
          <Button variant="faded" color="slate" :label="t('KANBAN.PRODUCTS.FORM.CANCEL')" class="w-full" @click="showDiscardDialog = false" />
          <Button color="ruby" :label="t('KANBAN.PRODUCTS.DISCARD')" class="w-full" @click="showDiscardDialog = false; dismissProductModal()" />
        </div>
      </template>
    </Dialog>

    <Dialog v-if="showDeleteDialog" type="alert" :title="t('KANBAN.PRODUCTS.DELETE_TITLE')" :description="t('KANBAN.PRODUCTS.DELETE_CONFIRMATION')" @confirm="deleteProduct" @close="showDeleteDialog = false; deletingProductId = null">
      <template #footer>
        <div class="flex items-center justify-between w-full gap-3">
          <Button variant="faded" color="slate" :label="t('KANBAN.PRODUCTS.FORM.CANCEL')" class="w-full" :disabled="isDeleting" @click="showDeleteDialog = false; deletingProductId = null" />
          <Button color="ruby" :label="t('KANBAN.PRODUCTS.DELETE_CONFIRM')" class="w-full" :is-loading="isDeleting" :disabled="isDeleting" @click="deleteProduct" />
        </div>
      </template>
    </Dialog>
  </div>
</template>

<style scoped>
:deep(main) {
  @apply flex-1 flex flex-col min-h-0;
}
</style>
