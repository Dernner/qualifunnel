import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { intlLocale } from 'kanban/constants';
import ProductsAPI from 'kanban/api/products';

export function useTaskProducts(boardId, currency) {
  const { locale } = useI18n();
  const catalogProducts = ref([]);

  const fetchCatalog = async () => {
    try {
      const response = await ProductsAPI.get(boardId.value, { active: true });
      catalogProducts.value = response.data.products || [];
    } catch {
      // ignore
    }
  };

  const formatCurrency = value => {
    if (value === null || value === undefined) return '-';
    return new Intl.NumberFormat(intlLocale(locale.value), {
      style: 'currency',
      currency: currency.value,
      minimumFractionDigits: 2,
      maximumFractionDigits: 2,
    }).format(value);
  };

  const productDropdownOptions = computed(() =>
    catalogProducts.value
      .filter(p => !p.archived)
      .map(p => ({
        value: p.id,
        label: `${p.name} - ${formatCurrency(p.unit_price)}`,
      }))
  );

  const calculateTotal = lineItems =>
    lineItems.reduce((sum, item) => {
      const qty = parseFloat(item.quantity) || 0;
      const price = parseFloat(item.unit_price) || 0;
      const discount = parseFloat(item.discount_percentage) || 0;
      return sum + qty * price * (1 - discount / 100);
    }, 0);

  return { catalogProducts, fetchCatalog, formatCurrency, productDropdownOptions, calculateTotal };
}
