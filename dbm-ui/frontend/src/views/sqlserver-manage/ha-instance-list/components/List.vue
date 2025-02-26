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
  <div class="sqlserver-ha-instance-list-page">
    <div class="operation-box">
      <BkButton
        class="mb-16"
        theme="primary"
        @click="handleApply">
        {{ t('申请实例') }}
      </BkButton>
      <DropdownExportExcel
        export-type="instance"
        :has-selected="hasSelected"
        :ids="selectedIds"
        type="sqlserver_ha" />
      <DbSearchSelect
        class="mb-16"
        :data="searchSelectData"
        :model-value="searchValue"
        :placeholder="t('请输入或选择条件搜索')"
        unique-select
        :validate-values="validateSearchValues"
        @change="handleSearchValueChange" />
    </div>
    <div
      class="table-wrapper"
      :class="{ 'is-shrink-table': isStretchLayoutOpen }">
      <DbTable
        ref="tableRef"
        :columns="columns"
        :data-source="getSqlServerInstanceList"
        releate-url-query
        :row-class="setRowClass"
        selectable
        :settings="settings"
        @clear-search="clearSearchValue"
        @column-filter="columnFilterChange"
        @column-sort="columnSortChange"
        @selection="handleSelection"
        @setting-change="updateTableSettings" />
    </div>
  </div>
</template>

<script setup lang="tsx">
  import { useI18n } from 'vue-i18n';

  import SqlServerHaInstanceModel from '@services/model/sqlserver/sqlserver-ha-instance';
  import { getSqlServerInstanceList } from '@services/source/sqlserveHaCluster';

  import {
    useCopy,
    useLinkQueryColumnSerach,
    useStretchLayout,
    useTableSettings,
  } from '@hooks';

  import { useGlobalBizs } from '@stores';

  import {
    ClusterTypes,
    DBTypes,
    UserPersonalSettings,
  } from '@common/const';

  import DbStatus from '@components/db-status/index.vue';
  import DbTable from '@components/db-table/index.vue';
  import DropdownExportExcel from '@components/dropdown-export-excel/index.vue';
  import MiniTag from '@components/mini-tag/index.vue';
  import TextOverflowLayout from '@components/text-overflow-layout/Index.vue';

  import { getSearchSelectorParams } from '@utils';

  const instanceData = defineModel<{
    instanceAddress: string,
    clusterId: number
  }>('instanceData');

  const router = useRouter();
  const globalBizsStore = useGlobalBizs();
  const copy = useCopy();
  const { t } = useI18n();
  const {
    isOpen: isStretchLayoutOpen,
    splitScreen: stretchLayoutSplitScreen,
  } = useStretchLayout();
  const {
    columnAttrs,
    searchAttrs,
    searchValue,
    sortValue,
    columnCheckedMap,
    columnFilterChange,
    columnSortChange,
    clearSearchValue,
    validateSearchValues,
    handleSearchValueChange,
  } = useLinkQueryColumnSerach({
    searchType: ClusterTypes.SQLSERVER_HA,
    attrs: ['role'],
    isCluster: false,
    fetchDataFn: () => fetchData(isInit),
    defaultSearchItem: {
      name: t('访问入口'),
      id: 'domain',
    }
  });

  const searchSelectData = computed(() => [
    {
      name: t('IP 或 IP:Port'),
      id: 'instance',
    },
    {
      name: t('访问入口'),
      id: 'domain',
      multiple: true,
    },
    {
      name: t('集群名称'),
      id: 'name',
    },
    {
      name: t('状态'),
      id: 'status',
      multiple: true,
      children: [
        {
          id: 'running',
          name: t('正常'),
        },
        {
          id: 'unavailable',
          name: t('异常'),
        },
      ],
    },
    {
      name: t('部署角色'),
      id: 'role',
      multiple: true,
      children: searchAttrs.value.role,
    },
    {
      name: t('端口'),
      id: 'port',
    },
  ]);

  const tableRef = ref<InstanceType<typeof DbTable>>();
  const selected = shallowRef<SqlServerHaInstanceModel[]>([]);

  const hasSelected = computed(() => selected.value.length > 0);
  const selectedIds = computed(() => selected.value.map(item => item.id));

  const columns = computed(() => {
    const list = [
      {
        label: t('实例'),
        field: 'instance_address',
        fixed: 'left',
        minWidth: 200,
        showOverflowTooltip: false,
        render: ({ data }: { data: SqlServerHaInstanceModel }) => (
          <TextOverflowLayout>
            {{
              default: () => (
                <bk-button
                  text
                  theme="primary"
                  onClick={() => handleToDetails(data)}>
                  {data.instance_address}
                </bk-button>
              ),
              append: () => (
                <>
                  {
                    data.isNew && (
                      <MiniTag
                        content='NEW'
                        theme='success'
                        class='new-tag'>
                      </MiniTag>
                    )
                  }
                </>
              ),
            }}
          </TextOverflowLayout>
        ),
      },
      {
        label: t('集群名称'),
        field: 'cluster_name',
        minWidth: 200,
        showOverflowTooltip: false,
        render: ({ data }: { data: SqlServerHaInstanceModel }) => (
          <TextOverflowLayout>
            {{
              default: () => (
                <bk-button
                  text
                  theme="primary"
                  onClick={() => handleToClusterDetails(data)}>
                  {data.cluster_name}
                </bk-button>
              ),
              append: () => (
                <db-icon
                  v-bk-tooltips={t('复制集群名称')}
                  type="copy"
                  onClick={() => copy(data.cluster_name)} />
              ),
            }}
          </TextOverflowLayout>
        ),
      },
      {
        label: t('状态'),
        field: 'status',
        width: 140,
        filter: {
          list: [
            {
              value: 'running',
              text: t('正常'),
            },
            {
              value: 'unavailable',
              text: t('异常'),
            },
          ],
          checked: columnCheckedMap.value.status,
        },
        render: ({ data }: { data: SqlServerHaInstanceModel }) => {
          const {
            theme,
            text,
          } = data.statusInfo;
          return <DbStatus theme={theme}>{text}</DbStatus>;
        },
      },
      {
        label: t('主访问入口'),
        field: 'master_domain',
        minWidth: 200,
        showOverflowTooltip: false,
        render: ({ data }: { data: SqlServerHaInstanceModel }) => (
          <TextOverflowLayout>
            {{
              default: () => <span>{data.master_domain}</span>,
              append: () => (
                <db-icon
                  v-bk-tooltips={t('复制主访问入口')}
                  type="copy"
                  onClick={() => copy(data.master_domain)} />
              ),
            }}
          </TextOverflowLayout>
        ),
      },
      {
        label: t('从访问入口'),
        field: 'slave_domain',
        minWidth: 200,
        showOverflowTooltip: false,
        render: ({ data }: { data: SqlServerHaInstanceModel }) => (
          <TextOverflowLayout>
            {{
              default: () => <span>{data.slave_domain}</span>,
              append: () => (
                <db-icon
                  v-bk-tooltips={t('复制从访问入口')}
                  type="copy"
                  onClick={() => copy(data.slave_domain)} />
              ),
            }}
          </TextOverflowLayout>
        ),
      },
      {
        label: t('部署角色'),
        field: 'role',
        filter: {
          list: columnAttrs.value.role,
          checked: columnCheckedMap.value.role,
        },
      },
      {
        label: t('部署时间'),
        field: 'create_at',
        width: 160,
        sort: true,
        render: ({ data }: { data: SqlServerHaInstanceModel }) => <span>{data.createAtDisplay}</span>,
      },
      {
        label: t('操作'),
        field: '',
        fixed: 'right',
        width: 140,
        render: ({ data }: { data: SqlServerHaInstanceModel }) => (
          <bk-button
            theme="primary"
            text
            onClick={() => handleToDetails(data)}>
            { t('查看详情') }
          </bk-button>
        ),
      },
    ];

    if (isStretchLayoutOpen.value) {
      list.pop();
    }

    return list;
  });

  // 设置行样式
  const setRowClass = (row: SqlServerHaInstanceModel) => {
    const classList = [row.isNew ? 'is-new-row' : ''];

    if (row.cluster_id === instanceData.value?.clusterId
      && row.instance_address === instanceData.value?.instanceAddress) {
      classList.push('is-selected-row');
    }

    return classList.filter(cls => cls).join(' ');
  };

  // 设置用户个人表头信息
  const defaultSettings = {
    fields: columns.value.filter(item => item.field).map(item => ({
      label: item.label,
      field: item.field,
      disabled: ['instance_address', 'master_domain'].includes(item.field),
    })),
    checked: columns.value.map(item => item.field).filter(key => !!key) as string[],
    showLineHeight: false,
    trigger: 'manual' as const,
  };

  const {
    settings,
    updateTableSettings,
  } = useTableSettings(UserPersonalSettings.SQLSERVER_HA_INSTANCE_SETTINGS, defaultSettings);

  let isInit = true;
  const fetchData = (loading?: boolean) => {
    tableRef.value!.fetchData(
      {
        db_type: DBTypes.SQLSERVER,
        bk_biz_id: globalBizsStore.currentBizId,
        type: ClusterTypes.SQLSERVER_HA,
        ...getSearchSelectorParams(searchValue.value),
      },
      sortValue,
      loading
    );
    isInit = false;
  };

  const handleSelection = (key: number[], list: Record<number, SqlServerHaInstanceModel>[]) => {
    selected.value = list as unknown as SqlServerHaInstanceModel[];
  };

  /**
   * 查看实例详情
   */
  const handleToDetails = (data: SqlServerHaInstanceModel) => {
    stretchLayoutSplitScreen();
    instanceData.value = {
      instanceAddress: data.instance_address,
      clusterId: data.cluster_id,
    };
  };

  /**
   * 查看集群详情
   */
  const handleToClusterDetails = (data: SqlServerHaInstanceModel) => {
    router.push({
      name: 'SqlServerHaClusterList',
      query: {
        cluster_id: data.cluster_id,
      },
    });
  };

  /**
   * 申请实例
   */
  const handleApply = () => {
    router.push({
      name: 'SqlServiceHaApply',
      query: {
        bizId: globalBizsStore.currentBizId,
      },
    });
  };
</script>

<style lang="less" scoped>
  .sqlserver-ha-instance-list-page {
    height: 100%;
    padding: 24px 0;
    margin: 0 24px;
    overflow: hidden;

    .operation-box {
      display: flex;
      flex-wrap: wrap;

      .bk-search-select {
        flex: 1;
        max-width: 500px;
        min-width: 320px;
        margin-left: auto;
      }
    }
  }

  :deep(.cell) {
    .db-icon-copy {
      display: none;
      margin-left: 4px;
      color: @primary-color;
      cursor: pointer;
    }
  }

  :deep(tr:hover) {
    .db-icon-copy {
      display: inline-block !important;
    }
  }

  .table-wrapper {
    background-color: white;

    .bk-table {
      height: 100% !important;
    }

    :deep(.bk-table-body) {
      max-height: calc(100% - 100px);
    }
  }

  .is-shrink-table {
    :deep(.bk-table-body) {
      overflow: hidden auto;
    }
  }
</style>
