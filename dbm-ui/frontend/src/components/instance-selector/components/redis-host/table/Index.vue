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
  <div class="instance-selector-render-topo-host">
    <SerachBar
      v-model="searchValue"
      is-host
      :placeholder="t('请输入或选择条件搜索')"
      :search-attrs="searchAttrs"
      :validate-search-values="validateSearchValues"
      @search-value-change="handleSearchValueChange" />
    <BkLoading
      :loading="isLoading"
      :z-index="2">
      <DbOriginalTable
        :columns="columns"
        :data="tableData"
        :max-height="530"
        :pagination="pagination.count < 10 ? false : pagination"
        :remote-pagination="isRemotePagination"
        :settings="tableSettings"
        style="margin-top: 12px"
        @clear-search="clearSearchValue"
        @column-filter="columnFilterChange"
        @page-limit-change="handeChangeLimit"
        @page-value-change="handleChangePage" />
    </BkLoading>
  </div>
</template>
<script setup lang="tsx" generic="T extends IValue">
  import type { Ref } from 'vue';
  import { useI18n } from 'vue-i18n';

  import { useLinkQueryColumnSerach } from '@hooks';

  import { ClusterTypes } from '@common/const';

  import DbStatus from '@components/db-status/index.vue';

  import { firstLetterToUpper } from '@utils';

  import {
    activePanelInjectionKey,
    type InstanceSelectorValues,
    type IValue,
    type PanelListType,
  } from '../../../Index.vue';
  import SerachBar from '../../common/SearchBar.vue';

  import { useTableData } from './useTableData';

  type TableConfigType = Required<PanelListType[number]>['tableConfig'];
  type DataRow = Record<string, any>;

  interface Props {
    lastValues: InstanceSelectorValues<T>,
    clusterId?: number,
    isRemotePagination?: TableConfigType['isRemotePagination'],
    firsrColumn?: TableConfigType['firsrColumn'],
    // eslint-disable-next-line vue/no-unused-properties
    roleFilterList?: TableConfigType['roleFilterList'],
    disabledRowConfig?: TableConfigType['disabledRowConfig'],
    // eslint-disable-next-line vue/no-unused-properties
    getTableList?: TableConfigType['getTableList'],
    // eslint-disable-next-line vue/no-unused-properties
    statusFilter?: TableConfigType['statusFilter'],
  }

  interface Emits {
    (e: 'change', value: InstanceSelectorValues<T>): void;
  }

  const props = withDefaults(defineProps<Props>(), {
    clusterId: undefined,
    firsrColumn: undefined,
    statusFilter: undefined,
    isRemotePagination: true,
    disabledRowConfig: undefined,
    roleFilterList: undefined,
    getTableList: undefined,
  });

  const emits = defineEmits<Emits>();

  const formatValue = (data: T) => ({
    bk_host_id: data.bk_host_id,
    bk_cloud_id: data.bk_cloud_id,
    ip: data.ip,
    cluster_id: data.related_clusters[0].id,
    port: 0,
    instance_address: '',
    cluster_type: '',
    master_domain: data.related_clusters[0].immute_domain,
    bk_cloud_name: data.bk_cloud_name,
    related_instances: (data.related_instances || []).map(instanceItem => ({
      instance: instanceItem.instance,
      status: instanceItem.status
    })),
    spec_config: data.spec_config,
    db_module_id: data.db_module_id,
    db_module_name: data.db_module_name,
  });

  const { t } = useI18n();

  const {
    columnAttrs,
    searchAttrs,
    searchValue,
    columnCheckedMap,
    clearSearchValue,
    columnFilterChange,
    validateSearchValues,
    handleSearchValueChange,
  } = useLinkQueryColumnSerach({
    searchType: ClusterTypes.REDIS,
    attrs: [
      'bk_cloud_id'
    ],
    fetchDataFn: () => fetchResources(),
    defaultSearchItem: {
      name: t('IP 或 IP:Port'),
      id: 'instance',
    },
    isDiscardNondefault: true,
  });

  const activePanel = inject(activePanelInjectionKey) as Ref<string> | undefined;

  const checkedMap = shallowRef({} as DataRow);

  const initRole = computed(() => props.firsrColumn?.role);
  const selectClusterId = computed(() => props.clusterId);
  const firstColumnFieldId = computed(() => (props.firsrColumn?.field || 'ip'));
  const mainSelectDisable = computed(() => (props.disabledRowConfig
    ? tableData.value.filter(data => props.disabledRowConfig?.handler(data)).length === tableData.value.length : false));

  const {
    isLoading,
    data: tableData,
    pagination,
    fetchResources,
    handleChangePage,
    handeChangeLimit,
  } = useTableData<T>(searchValue, initRole, selectClusterId);

  const isSelectedAll = computed(() => (
    tableData.value.length > 0
    && tableData.value.length === tableData.value.filter(item => checkedMap.value[item[firstColumnFieldId.value]]).length
  ));

  let isSelectedAllReal = false;

  const columns = computed(() => [
    {
      width: 60,
      fixed: 'left',
      label: () => (
        <bk-checkbox
          label={true}
          model-value={isSelectedAll.value}
          disabled={mainSelectDisable.value}
          onChange={handleSelectPageAll}
        />
      ),
      render: ({ data }: DataRow) => {
        if (props.disabledRowConfig && props.disabledRowConfig.handler(data)) {
          return (
            <bk-popover theme="dark" placement="top" popoverDelay={0}>
              {{
                default: () => <bk-checkbox style="vertical-align: middle;" disabled />,
                content: () => <span>{props.disabledRowConfig?.tip}</span>,
              }}
            </bk-popover>
          );
        }
        return (
          <bk-checkbox
            style="vertical-align: middle;"
            label={true}
            model-value={Boolean(checkedMap.value[data[firstColumnFieldId.value]])}
            onChange={(value: boolean) => handleTableSelectOne(value, data)}
          />
        );
      },
    },
    {
      fixed: 'left',
      minWidth: 160,
      label: props.firsrColumn?.label ? firstLetterToUpper(props.firsrColumn.label) : t('实例'),
      field: props.firsrColumn?.field ? props.firsrColumn.field : 'instance_address',
    },
    {
      minWidth: 100,
      label: t('云区域'),
      field: 'bk_cloud_id',
      showOverflowTooltip: true,
      filter: {
        list: columnAttrs.value.bk_cloud_id,
        checked: columnCheckedMap.value.bk_cloud_id,
      },
      render: ({ data }: DataRow) => <span>{data.bk_cloud_name ?? '--'}</span>,
    },
    {
      minWidth: 100,
      label: t('Agent状态'),
      field: 'alive',
      render: ({ data }: DataRow) => {
        const info = data.host_info?.alive === 1 ? { theme: 'success', text: t('正常') } : { theme: 'danger', text: t('异常') };
        return <DbStatus theme={info.theme}>{info.text}</DbStatus>;
      },
    },
    {
      label: t('主机名称'),
      field: 'host_name',
      showOverflowTooltip: true,
      render: ({ data }: DataRow) => data.host_info?.host_name || '--',
    },
    {
      label: t('OS名称'),
      field: 'os_name',
      showOverflowTooltip: true,
      render: ({ data }: DataRow) => data.host_info?.os_name || '--',
    },
    {
      label: t('所属云厂商'),
      field: 'cloud_vendor',
      showOverflowTooltip: true,
      render: ({ data }: DataRow) => data.host_info?.cloud_vendor || '--',
    },
    {
      label: t('OS类型'),
      field: 'os_type',
      showOverflowTooltip: true,
      render: ({ data }: DataRow) => data.host_info.os_type || '--',
    },
    {
      label: t('主机ID'),
      field: 'host_id',
      showOverflowTooltip: true,
      render: ({ data }: DataRow) => data.host_info?.host_id || '--',
    },
    {
      label: 'Agent ID',
      field: 'agent_id',
      showOverflowTooltip: true,
      render: ({ data }: DataRow) => data.host_info?.agent_id || '--',
    },
  ]);

  const tableSettings = computed(() => ({
    fields: columns.value.filter(item => item.field).map(item => ({
      label: item.label,
      field: item.field,
      disabled: firstColumnFieldId.value === item.field,
    })),
    checked: [firstColumnFieldId.value, 'bk_cloud_id', 'role', 'status', 'cloud_area', 'alive', 'host_name', 'os_name'],
  }))


  watch(() => props.lastValues, () => {
    // 切换 tab 回显选中状态 \ 预览结果操作选中状态
    if (activePanel?.value && activePanel.value !== 'manualInput') {
      checkedMap.value = {};
      const checkedList = props.lastValues[activePanel.value];
      if (checkedList) {
        for (const item of checkedList) {
          checkedMap.value[item[firstColumnFieldId.value]] = item;
        }
      }
    }
  }, { immediate: true, deep: true });

  watch(() => props.clusterId, () => {
    if (props.clusterId) {
      fetchResources();
    }
  }, {
    immediate: true,
  });

  const triggerChange = () => {
    const result = Object.values(checkedMap.value).reduce((result, item) => {
      result.push({
        ...item,
      });
      return result;
    }, [] as T[]);

    if (activePanel?.value) {
      emits('change', {
        ...props.lastValues,
        [activePanel.value]: result,
      });
    }
  };

  const handleSelectPageAll = (checked: boolean) => {
    const list = tableData.value;
    if (props.disabledRowConfig) {
      isSelectedAllReal = !isSelectedAllReal;
      for (const data of list) {
        if (!props.disabledRowConfig.handler(data)) {
          handleTableSelectOne(isSelectedAllReal, data);
        }
      }
      return;
    }
    for (const item of list) {
      handleTableSelectOne(checked, item);
    }
  };

  const handleTableSelectOne = (checked: boolean, data: T) => {
    const lastCheckMap = { ...checkedMap.value };
    if (checked) {
      lastCheckMap[data[firstColumnFieldId.value]] = formatValue(data);
    } else {
      delete lastCheckMap[data[firstColumnFieldId.value]];
    }
    checkedMap.value = lastCheckMap;
    triggerChange();
  };
</script>

<style lang="less">
  .instance-selector-render-topo-host {
    padding: 0 24px;

    .bk-table-body {
      tr {
        cursor: pointer;
      }
    }
  }
</style>
