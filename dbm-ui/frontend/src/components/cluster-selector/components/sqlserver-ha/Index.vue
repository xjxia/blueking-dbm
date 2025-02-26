<!--
 * TencentBlueKing is pleased to support the open source community by making 蓝鲸智云-DB管理系统(BlueKing-BK-DBM) available.
 *
 * Copyright (C) 2017-2023 THL A29 Limited, a Tencent company. All rights reserved.
 *
 * Licensed under the MIT License (the "License"); you may not use this file except in compliance with the License.
 * You may obtain a copy of the License athttps://opensource.org/licenses/MIT
 *
 * Unless required by applicable law or agreed to in writing, software distributed under the License is distributed
 * on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for
 * the specific language governing permissions and limitations under the License.
-->

<template>
  <div>
    <SerachBar
      v-model="searchValue"
      :cluster-type="activeTab"
      :search-attrs="searchAttrs"
      :search-select-list="searchSelectList"
      @search-value-change="handleSearchValueChange" />
    <BkLoading
      :loading="isLoading"
      :z-index="2">
      <DbOriginalTable
        class="table-box"
        :columns="generatedColumns"
        :data="tableData"
        :is-anomalies="isAnomalies"
        :is-searching="searchSelectValue.length > 0"
        :max-height="528"
        :pagination="pagination.count < 10 ? false : pagination"
        remote-pagination
        row-style="cursor: pointer;"
        @clear-search="clearSearchValue"
        @column-filter="columnFilterChange"
        @page-limit-change="handleTableLimitChange"
        @page-value-change="handleTablePageChange"
        @refresh="fetchResources"
        @row-click.stop.prevent="handleRowClick" />
    </BkLoading>
  </div>
</template>

<script setup lang="tsx">
  import { shallowRef } from 'vue';
  import { useI18n } from 'vue-i18n';

  import SqlServerHaClusterModel from '@services/model/sqlserver/sqlserver-ha-cluster';
  import SqlServerSingleClusterModel from '@services/model/sqlserver/sqlserver-single-cluster';

  import { useLinkQueryColumnSerach } from '@hooks';

  import { ClusterTypes } from '@common/const';

  import DbStatus from '@components/db-status/index.vue';

  import { makeMap } from '@utils';

  import type { TabItem } from '../../Index.vue';
  import SerachBar from '../common/SearchBar.vue';
  import ClusterRelatedTasks from '../common/task-panel/Index.vue';

  import { useClusterData } from './useClusterData';

  interface Props {
    activeTab: ClusterTypes,
    selected: Record<string, (SqlServerSingleClusterModel | SqlServerHaClusterModel)[]>,
    // eslint-disable-next-line vue/no-unused-properties
    getResourceList: TabItem['getResourceList'],
    disabledRowConfig: NonNullable<TabItem['disabledRowConfig']>,
    columnStatusFilter?: TabItem['columnStatusFilter'],
    customColums?: TabItem['customColums'],
    searchSelectList?: TabItem['searchSelectList'],
  }

  type ResourceItem = ValueOf<SelectedMap>[0];

  interface Emits {
    (e: 'change', value: Record<string, Record<string, ResourceItem>>): void,
  }

  type SelectedMap = Props['selected'];

  const props = defineProps<Props>();
  const emits = defineEmits<Emits>();

  const { t } = useI18n();

  const {
    columnAttrs,
    searchAttrs,
    searchValue,
    columnCheckedMap,
    clearSearchValue,
    columnFilterChange,
    handleSearchValueChange,
  } = useLinkQueryColumnSerach({
    searchType: ClusterTypes.SQLSERVER_HA,
    attrs: [
      'bk_cloud_id',
      'db_module_id',
      'major_version',
    ],
    defaultSearchItem: {
      name: t('访问入口'),
      id: 'domain',
    }
  });

  const columns = computed(() => [
    {
      width: 60,
      label: () => (
        <bk-checkbox
          key={`${pagination.current}_${activeTab.value}`}
          model-value={isSelectedAll.value}
          indeterminate={isIndeterminate.value}
          disabled={mainSelectDisable.value}
          label={true}
          onClick={(e: Event) => e.stopPropagation()}
          onChange={handleSelecteAll}
        />
      ),
      render: ({ data }: { data: ResourceItem }) => {
        const disabledRowConfig = props.disabledRowConfig.find(item => item.handler(data));
        if (disabledRowConfig) {
          return (
            <bk-popover
              theme="dark"
              placement="top"
              popoverDelay={0}>
              {{
                default: () => <bk-checkbox style="vertical-align: middle;" disabled />,
                content: () => <span>{disabledRowConfig.tip}</span>,
              }}
            </bk-popover>
          );
        }
        return (
          <bk-checkbox
            style="vertical-align: middle;"
            model-value={Boolean(selectedDomainMap.value[data.id])}
            label={true}
            onChange={(value: boolean) => handleSelecteRow(data, value)}
          />
        );
      },
    },
    {
      label: t('访问入口'),
      field: 'cluster_name',
      showOverflowTooltip: true,
      render: ({ data }: { data: ResourceItem }) => (
        <div class="cluster-name-box">
            <div class="cluster-name">{data.master_domain}</div>
            {
              !data.isOnline && (
                <bk-tag
                  class="ml-8"
                  size="small">
                  {t('已禁用')}
                </bk-tag>
              )
            }
            {
              data.operations && data.operations.length > 0 && (
                <bk-popover
                  theme="light"
                  width="360">
                  {{
                    default: () => <bk-tag theme="info" class="tag-box">{data.operations.length}</bk-tag>,
                    content: () => <ClusterRelatedTasks data={data.operations} />,
                  }}
                </bk-popover>
              )
            }
        </div>
      ),
    },
    {
      label: t('状态'),
      field: 'status',
      width: 100,
      filter: {
        list: [
          {
            value: 'normal',
            text: t('正常'),
          },
          {
            value: 'abnormal',
            text: t('异常'),
          },
        ],
        checked: columnCheckedMap.value.status,
      },
      render: ({ data }: { data: ResourceItem }) => {
        const isNormal = props.columnStatusFilter ? props.columnStatusFilter(data) : data.status === 'normal';
        const info = isNormal ? { theme: 'success', text: t('正常') } : { theme: 'danger', text: t('异常') };
        return <DbStatus theme={info.theme}>{info.text}</DbStatus>;
      },
    },
    {
      label: t('集群名称'),
      field: 'cluster_name',
      showOverflowTooltip: true,
    },
    {
      label: t('所属模块'),
      field: 'db_module_id',
      width: 130,
      showOverflowTooltip: true,
      filter: {
        list: columnAttrs.value.db_module_id,
        checked: columnCheckedMap.value.db_module_id,
      },
      render: ({ data }: { data: ResourceItem }) => <span>{data.db_module_name || '--'}</span>,
    },
    {
      label: t('管控区域'),
      field: 'bk_cloud_id',
      showOverflowTooltip: true,
      filter: {
        list: columnAttrs.value.bk_cloud_id,
        checked: columnCheckedMap.value.bk_cloud_id,
      },
      render: ({ data }: { data: ResourceItem }) => <span>{data.bk_cloud_name}</span>,
    },
  ]);

  const activeTab = ref(props.activeTab);
  const isSelectedAll = ref(false);
  const selectedMap = shallowRef<Record<string, Record<string, ResourceItem>>>({});

  const {
    isLoading,
    pagination,
    isAnomalies,
    data: tableData,
    searchSelectValue,
    fetchResources,
    handleChangePage,
    handeChangeLimit,
  } = useClusterData<ResourceItem>(searchValue);

  // 选中域名列表
  const selectedDomainMap = computed(() => Object.values(selectedMap.value)
    .reduce((result, selectItem) => {
      const masterDomainMap  = makeMap(Object.keys(selectItem));
      return Object.assign({}, result, masterDomainMap);
    }, {} as Record<string, boolean>));

  const isIndeterminate = computed(() => !isSelectedAll.value
    && selectedMap.value[activeTab.value] && Object.keys(selectedMap.value[activeTab.value]).length > 0);

  const mainSelectDisable = computed(() => tableData.value.filter(data => props.disabledRowConfig
    .find(item => item.handler(data))).length === tableData.value.length);

  const generatedColumns = computed(() => {
    if (props.customColums) {
      return [columns.value[0], ...props.customColums];
    }
    return columns.value;
  });

  watch(() => [props.activeTab, props.selected], () => {
    if (props.activeTab) {
      activeTab.value = props.activeTab;
      if (!props.selected || !props.selected[props.activeTab]) {
        return;
      }
      // eslint-disable-next-line max-len
      const tabSelectMap = props.selected[props.activeTab].reduce((selectResult, selectItem) => Object.assign({}, selectResult, {
        [selectItem.id]: selectItem,
      }), {} as Record<string, ResourceItem>);
      selectedMap.value = {
        [props.activeTab]: tabSelectMap,
      };
    }
  }, {
    immediate: true,
    deep: true,
  });

  watch(() => activeTab.value, (tab) => {
    if (tab) {
      searchSelectValue.value = [];
    }
  });

  watch(isLoading, (status) => {
    if (!status) {
      checkSelectedAll();
    }
  });

  /**
   * 全选当页数据
   */
  const handleSelecteAll = (value: boolean) => {
    for (const data of tableData.value) {
      if (!props.disabledRowConfig.find(item => item.handler(data))) {
        handleSelecteRow(data, value);
      }
    }
  };

  const checkSelectedAll = () => {
    if (tableData.value.filter(data => props.disabledRowConfig.find(item => item.handler(data))).length > 0) {
      nextTick(() => {
        isSelectedAll.value = false;
      });
      return;
    }
    const currentSelected = selectedMap.value[activeTab.value];
    if (!currentSelected || Object.keys(currentSelected).length < 1) {
      isSelectedAll.value = false;
      return;
    }
    for (let i = 0; i < tableData.value.length; i++) {
      if (!currentSelected[tableData.value[i].id]) {
        isSelectedAll.value = false;
        return;
      }
    }
    isSelectedAll.value = true;
  };

  /**
   * 选择当行数据
   */
  const handleSelecteRow = (data: ResourceItem, value: boolean) => {
    const selectedMapMemo = { ...selectedMap.value };
    if (!selectedMapMemo[activeTab.value]) {
      selectedMapMemo[activeTab.value] = {};
    }
    if (value) {
      selectedMapMemo[activeTab.value][data.id] = data;
    } else {
      delete selectedMapMemo[activeTab.value][data.id];
    }
    selectedMap.value = selectedMapMemo;
    emits('change', selectedMap.value);
    checkSelectedAll();
  };

  const handleRowClick = (row:any, data: ResourceItem) => {
    if (props.disabledRowConfig.find(item => item.handler(data))) {
      return;
    }
    const currentSelected = selectedMap.value[activeTab.value];
    const isChecked = !!(currentSelected && currentSelected[data.id]);
    handleSelecteRow(data, !isChecked);
  };

  const handleTablePageChange = (value: number) => {
    handleChangePage(value)
      .then(() => {
        checkSelectedAll();
      });
  };

  const handleTableLimitChange = (value: number) => {
    handeChangeLimit(value)
      .then(() => {
        checkSelectedAll();
      });
  };
</script>

<style lang="less" scoped>
  .table-box {
    :deep(.cluster-name-box) {
      display: flex;
      width: 100%;
      align-items: center;
      overflow: hidden;

      .cluster-name {
        width: auto;
        margin-right: 8px;
        overflow: hidden;
        text-overflow: ellipsis;
        white-space: nowrap;
      }

      .tag-box {
        height: 16px;
        color: #3a84ff;
        border-radius: 8px !important;
      }
    }
  }
</style>
