<template>
  <div class="redis-backend-spec">
    <BkFormItem
      :label="targetCapacityTitle"
      property="details.resource_spec.backend_group.capacity"
      required>
      <BkInput
        :min="1"
        :model-value="modelValue.capacity"
        style="width: 314px"
        type="number"
        @change="handleChangeCapacity" />
      <span class="input-desc">G</span>
    </BkFormItem>
    <BkFormItem
      :label="futureCapacityTitle"
      property="details.resource_spec.backend_group.future_capacity"
      required>
      <BkInput
        :min="Number(modelValue.capacity)"
        :model-value="modelValue.future_capacity"
        style="width: 314px"
        type="number"
        @change="handleChangeFutureCapacity" />
      <span class="input-desc">G</span>
    </BkFormItem>
    <BkFormItem
      ref="specRef"
      :label="t('集群部署方案')"
      property="details.resource_spec.backend_group.spec_id"
      required>
      <DbOriginalTable
        v-bkloading="{ loading: isLoading }"
        class="custom-edit-table"
        :columns="columns"
        :data="specs"
        @row-click="handleRowClick">
        <template #empty>
          <p
            v-if="!modelValue.capacity || !modelValue.future_capacity"
            style="width: 100%; line-height: 128px; text-align: center">
            <DbIcon
              class="mr-4"
              type="attention" />
            <span>{{ t('请先设置容量') }}</span>
          </p>
          <BkException
            v-else
            :description="t('无匹配的资源规格_请先修改容量设置')"
            scene="part"
            style="font-size: 12px"
            type="empty" />
        </template>
      </DbOriginalTable>
    </BkFormItem>
  </div>
</template>

<script setup lang="tsx">
  import _ from 'lodash';
  import { useI18n } from 'vue-i18n';

  import ClusterSpecModel from '@services/model/resource-spec/cluster-sepc';
  import { getSpecResourceCount } from '@services/source/dbresourceResource';
  import { getFilterClusterSpec } from '@services/source/dbresourceSpec';

  import { ClusterTypes } from '@common/const';

  import TextOverflowLayout from '@components/text-overflow-layout/Index.vue';

  interface ModelValue {
    spec_id: number,
    capacity: number | string,
    future_capacity: number | string,
  }

  interface Props {
    clusterType: string,
    machineType: string,
    bizId: number | string,
    cloudId: number | string,
  }

  const props = defineProps<Props>();
  const modelValue = defineModel<ModelValue>({ required: true });

  const { t } = useI18n();


  const specRef = ref();
  const specs = shallowRef<ClusterSpecModel[]>([]);
  const isLoading = ref(false);
  const countMap = shallowRef({} as Record<number, number>)

  const isTendisCache = computed(() => props.clusterType === ClusterTypes.TWEMPROXY_REDIS_INSTANCE);
  const targetCapacityTitle = computed(() => (isTendisCache.value ? t('集群容量需求(内存容量)') : t('集群容量需求(磁盘容量)')));
  const futureCapacityTitle = computed(() => (isTendisCache.value ? t('未来集群容量需求(内存容量)') : t('未来集群容量需求(磁盘容量)')));

  const columns = [
    {
      field: 'spec_name',
      label: t('资源规格'),
      width: 300,
      showOverflowTooltip: false,
      render: ({ data, index }: { data: ClusterSpecModel, index: number }) => (
        <TextOverflowLayout>
          {{
            default: () => (
              <bk-radio
                v-model={modelValue.value.spec_id}
                label={data.spec_id}
                key={index}
                class="spec-radio">
                  {data.spec_name}
              </bk-radio>
            ),
            append: () => (
              (countMap.value[data.spec_id] || 0) < data.machine_pair && (
                <bk-tag
                  class='ml-6'
                  size="small"
                  theme="danger">
                    {t('资源不足')}
                  </bk-tag>
              )
            )
          }}
        </TextOverflowLayout>
      ),
    },
    {
      field: 'machine_pair',
      label: t('需机器组数'),
      sort: true,
    },
    {
      field: 'cluster_shard_num',
      label: t('集群分片'),
      sort: true,
    },
    {
      field: 'cluster_capacity',
      label: t('集群容量G'),
      sort: true,
    },
    {
      field: 'count',
      label: t('可用主机数'),
      render: ({ data }: { data: ClusterSpecModel }) => countMap.value[data.spec_id] || 0
    },
  ];

  let timer = 0;

  watch(() => modelValue.value.spec_id, () => {
    if (modelValue.value.spec_id) {
      specRef.value.clearValidate();
    }
  });

  watch([
    () => props.bizId,
    () => props.cloudId,
    specs,
  ], () => {
    if (
      typeof props.bizId === 'number'
      && props.bizId > 0
      && typeof props.cloudId === 'number'
      && specs.value.length > 0
    ) {
      fetchSpecResourceCount();
    }
  }, { immediate: true, deep: true });

  watch([
    () => modelValue.value.capacity,
    () => modelValue.value.future_capacity,
  ], ([capacityValue, futureCapacityValue]) => {
    if (capacityValue === '' || futureCapacityValue === '') {
      resetSlider();
    } else {
      modelValue.value.spec_id = -1;
      clearTimeout(timer);
      timer = setTimeout(() => {
        fetchFilterClusterSpec();
      }, 400);
    }
  });

  const resetSlider = () => {
    specs.value = [];
  };

  const fetchFilterClusterSpec = () => {
    const { capacity, future_capacity: futureCapacity } = modelValue.value;

    if (!capacity || !futureCapacity) {
      return;
    }

    isLoading.value = true;
    getFilterClusterSpec({
      spec_cluster_type: props.clusterType,
      spec_machine_type: props.machineType,
      capacity: Number(capacity),
      future_capacity: Number(futureCapacity),
    })
      .then((res) => {
        specs.value = res;
      })
      .catch(() => {
        specs.value = [];
      })
      .finally(() => {
        isLoading.value = false;
        countMap.value = {}
      });
  };

  const handleChangeCapacity = (value: string) => {
    if (value === '') {
      modelValue.value.capacity = value;
      return;
    }

    const capacityValue = Number(value);
    const futureCapacityValue = Number(modelValue.value.future_capacity);

    if (modelValue.value.future_capacity === '') {
      modelValue.value.capacity = capacityValue;
    } else {
      modelValue.value.capacity = capacityValue > futureCapacityValue ? futureCapacityValue : capacityValue;
    }
  };

  const handleChangeFutureCapacity = (value: string) => {
    if (value === '') {
      modelValue.value.future_capacity = value;
      return;
    }

    const futureCapacityValue = Number(value);
    const capacityValue = Number(modelValue.value.capacity);

    if (modelValue.value.future_capacity === '') {
      modelValue.value.future_capacity = futureCapacityValue;
    } else {
      modelValue.value.future_capacity = capacityValue > futureCapacityValue ? capacityValue : futureCapacityValue;
    }
  };

  const fetchSpecResourceCount = _.debounce(() => {
    getSpecResourceCount({
      bk_biz_id: Number(props.bizId),
      bk_cloud_id: Number(props.cloudId),
      spec_ids: specs.value.map(item => item.spec_id),
    }).then((data) => {
      countMap.value = data
    });
  }, 100);

  const handleRowClick = (event: Event, row: ClusterSpecModel) => {
    modelValue.value.spec_id = row.spec_id;
  };

  defineExpose({
    getData() {
      const item = specs.value.find(item => item.spec_id === Number(modelValue.value.spec_id));
      return item ?? {};
    },
  });
</script>

<style lang="less" scoped>
  .redis-backend-spec {
    max-width: 1200px;
    padding: 24px 24px 24px 10px;
    background-color: #f5f7fa;
    border-radius: 2px;

    .input-desc {
      padding-left: 12px;
      font-size: 12px;
      line-height: 20px;
      color: #63656e;
    }

    :deep(.spec-radio) {
      display: flex;
      max-width: 100%;

      .bk-radio-input {
        flex-shrink: 0;
        width: 16px;
      }

      .bk-radio-label {
        flex: 1;
        font-size: 12px;
      }
    }

    .custom-edit-table {
      :deep(.bk-table-body) {
        .cell {
          height: 42px !important;
        }

        tr:hover td {
          background-color: #f5f7fa !important;
        }
      }
    }
  }
</style>
