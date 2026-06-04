<script setup>
import { ref, computed, onMounted, watch, nextTick, toRef } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { parseAPIErrorResponse } from 'dashboard/store/utils/api';
import { OnClickOutside } from '@vueuse/components';
import Button from 'dashboard/components-next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import ComboBoxDropdown from 'dashboard/components-next/combobox/ComboBoxDropdown.vue';
import TaskProductsAPI from 'kanban/api/taskProducts';
import { useTaskProducts } from 'kanban/composables/useTaskProducts';

const props = defineProps({
  taskId: { type: Number, required: true },
  boardId: { type: Number, required: true },
  currency: { type: String, default: 'USD' },
});

const emit = defineEmits(['update']);
const { t } = useI18n();

const { fetchCatalog, formatCurrency, productDropdownOptions, calculateTotal, catalogProducts } =
  useTaskProducts(toRef(props, 'boardId'), toRef(props, 'currency'));

const lineItems = ref([]);
const showAddDropdown = ref(false);
const productSearchQuery = ref('');
const isLoading = ref(false);
const editingItem = ref(null);
const productDropdownRef = ref(null);

const totalValue = computed(() => calculateTotal(lineItems.value));

const normalizeItem = item => ({
  ...item,
  quantity: parseFloat(item.quantity) || 0,
  unit_price: parseFloat(item.unit_price) || 0,
  discount_percentage: parseFloat(item.discount_percentage) || 0,
  line_total: parseFloat(item.line_total) || 0,
});

const emitState = () => emit('update', { count: lineItems.value.length, total: totalValue.value });

const fetchLineItems = async () => {
  isLoading.value = true;
  try {
    const response = await TaskProductsAPI.get(props.taskId);
    lineItems.value = (response.data.task_products || []).map(normalizeItem);
    emitState();
  } catch {
    // ignore
  } finally {
    isLoading.value = false;
  }
};

const formatNumber = val => String(parseFloat(val) || 0);
const computeLineTotal = li => {
  const qty = parseFloat(li.quantity) || 0;
  const price = parseFloat(li.unit_price) || 0;
  const discount = parseFloat(li.discount_percentage) || 0;
  return qty * price * (1 - discount / 100);
};

const addProduct = async option => {
  showAddDropdown.value = false;
  productSearchQuery.value = '';
  const product = catalogProducts.value.find(p => p.id === option.value);
  if (!product) return;
  const unitPrice = parseFloat(product.unit_price) || 0;
  const optimistic = { tempId: Date.now(), product_id: product.id, product: { id: product.id, name: product.name }, quantity: 1, unit_price: unitPrice, discount_percentage: 0, line_total: unitPrice };
  lineItems.value.push(optimistic);
  emitState();
  try {
    const response = await TaskProductsAPI.create(props.taskId, { product_id: product.id, quantity: 1, unit_price: unitPrice, discount_percentage: 0 });
    const idx = lineItems.value.findIndex(li => li.tempId === optimistic.tempId);
    if (idx !== -1) lineItems.value.splice(idx, 1, normalizeItem(response.data));
  } catch (error) {
    lineItems.value = lineItems.value.filter(li => li.tempId !== optimistic.tempId);
    emitState();
    useAlert(parseAPIErrorResponse(error) || t('KANBAN.PRODUCTS.SAVE_ERROR'));
  }
};

const updateLineItem = async (item, field, value) => {
  const parsedValue = parseFloat(value) || 0;
  const index = lineItems.value.findIndex(li => li.id === item.id);
  if (index === -1) return;
  const original = { ...lineItems.value[index] };
  const updated = { ...original, [field]: parsedValue };
  updated.line_total = computeLineTotal(updated);
  lineItems.value.splice(index, 1, updated);
  emitState();
  try {
    const response = await TaskProductsAPI.update(props.taskId, item.id, { [field]: parsedValue });
    const i = lineItems.value.findIndex(li => li.id === item.id);
    if (i !== -1) lineItems.value.splice(i, 1, normalizeItem(response.data));
  } catch (error) {
    const revertIndex = lineItems.value.findIndex(li => li.id === item.id);
    if (revertIndex !== -1) lineItems.value.splice(revertIndex, 1, original);
    emitState();
    useAlert(parseAPIErrorResponse(error) || t('KANBAN.PRODUCTS.SAVE_ERROR'));
  }
};

const removeLineItem = async item => {
  const originalItems = [...lineItems.value];
  lineItems.value = lineItems.value.filter(li => li.id !== item.id);
  emitState();
  try {
    await TaskProductsAPI.delete(props.taskId, item.id);
  } catch (error) {
    lineItems.value = originalItems;
    emitState();
    useAlert(parseAPIErrorResponse(error) || t('KANBAN.PRODUCTS.DELETE_ERROR'));
  }
};

const toggleAddDropdown = () => {
  showAddDropdown.value = !showAddDropdown.value;
  if (showAddDropdown.value) {
    productSearchQuery.value = '';
    fetchCatalog();
    nextTick(() => productDropdownRef.value?.focus());
  }
};

onMounted(() => { if (props.taskId) { fetchLineItems(); fetchCatalog(); } });
watch(() => props.taskId, newId => { if (newId) { lineItems.value = []; fetchLineItems(); fetchCatalog(); } });
</script>

<template>
  <div class="flex flex-col gap-2">
    <div v-if="isLoading" class="animate-pulse">
      <div class="h-6 w-full bg-n-slate-3 rounded" />
      <div class="h-6 w-full bg-n-slate-3 rounded mt-1" />
    </div>
    <div v-else class="flex flex-col gap-1">
      <div v-for="item in lineItems" :key="item.id || item.tempId" class="flex items-center gap-2 py-1.5 px-2 rounded-md bg-n-alpha-1 border border-n-slate-3 group">
        <template v-if="editingItem !== item.id">
          <div class="flex-1 min-w-0">
            <div class="text-xs text-n-slate-12 truncate">{{ item.product?.name }}</div>
            <div class="text-[10px] text-n-slate-10">
              {{ item.discount_percentage > 0
                ? t('KANBAN.PRODUCTS.LINE_ITEM.SUMMARY_WITH_DISCOUNT', { qty: formatNumber(item.quantity), price: formatCurrency(item.unit_price), discount: formatNumber(item.discount_percentage) })
                : t('KANBAN.PRODUCTS.LINE_ITEM.SUMMARY', { qty: formatNumber(item.quantity), price: formatCurrency(item.unit_price) }) }}
            </div>
          </div>
          <span class="text-xs font-medium text-n-slate-11 whitespace-nowrap">{{ formatCurrency(item.line_total) }}</span>
          <div class="flex items-center gap-0.5 opacity-0 group-hover:opacity-100 transition-opacity">
            <Button variant="ghost" size="xs" icon="i-lucide-pencil" class="text-n-slate-10 hover:text-n-slate-12 !size-5" @click="editingItem = item.id" />
            <Button variant="ghost" size="xs" icon="i-lucide-x" class="text-n-slate-10 hover:text-n-ruby-11 !size-5" @click="removeLineItem(item)" />
          </div>
        </template>
        <template v-else>
          <div class="flex flex-col gap-1.5 w-full">
            <div class="text-xs font-medium text-n-slate-12 truncate">{{ item.product?.name }}</div>
            <div class="grid grid-cols-3 gap-1.5">
              <div>
                <div class="text-[10px] text-n-slate-10 mb-0.5">{{ t('KANBAN.PRODUCTS.LINE_ITEM.QTY') }}</div>
                <Input :model-value="formatNumber(item.quantity || 1)" type="number" min="1" class="text-xs [&_input]:!py-0.5 [&_input]:!px-1.5" @change="updateLineItem(item, 'quantity', $event.target.value)" />
              </div>
              <div>
                <div class="text-[10px] text-n-slate-10 mb-0.5">{{ t('KANBAN.PRODUCTS.LINE_ITEM.PRICE') }}</div>
                <Input :model-value="formatNumber(item.unit_price)" type="number" min="0" step="0.01" class="text-xs [&_input]:!py-0.5 [&_input]:!px-1.5" @change="updateLineItem(item, 'unit_price', $event.target.value)" />
              </div>
              <div>
                <div class="text-[10px] text-n-slate-10 mb-0.5">{{ t('KANBAN.PRODUCTS.LINE_ITEM.DISCOUNT') }}</div>
                <Input :model-value="formatNumber(item.discount_percentage)" type="number" min="0" max="100" step="0.1" class="text-xs [&_input]:!py-0.5 [&_input]:!px-1.5" @change="updateLineItem(item, 'discount_percentage', $event.target.value)" />
              </div>
            </div>
            <div class="flex justify-end">
              <Button variant="ghost" size="xs" color="slate" icon="i-lucide-check" class="!size-5" @click="editingItem = null" />
            </div>
          </div>
        </template>
      </div>
    </div>

    <OnClickOutside @trigger="showAddDropdown = false">
      <div class="relative">
        <Button variant="ghost" color="slate" size="xs" icon="i-lucide-plus" class="w-full justify-start text-n-slate-11 hover:text-n-slate-12" @click="toggleAddDropdown">
          {{ t('KANBAN.PRODUCTS.ADD_LINE_ITEM') }}
        </Button>
        <ComboBoxDropdown
          ref="productDropdownRef"
          :open="showAddDropdown"
          :options="productDropdownOptions"
          :search-value="productSearchQuery"
          :search-placeholder="t('KANBAN.PRODUCTS.SEARCH_CATALOG')"
          :empty-state="t('KANBAN.PRODUCTS.NO_PRODUCTS_AVAILABLE')"
          @update:search-value="productSearchQuery = $event"
          @select="addProduct"
        />
      </div>
    </OnClickOutside>

    <div v-if="lineItems.length" class="flex items-center justify-between pt-1.5 border-t border-n-slate-3">
      <span class="text-xs font-medium text-n-slate-12">{{ t('KANBAN.PRODUCTS.TOTAL') }}</span>
      <span class="text-xs font-semibold text-n-slate-12">{{ formatCurrency(totalValue) }}</span>
    </div>
  </div>
</template>
