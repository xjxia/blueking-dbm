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
  <div class="redis-cluster-list-page">
    <div class="operation-box">
      <div>
        <AuthButton
          action-id="redis_cluster_apply"
          class="mb-16"
          theme="primary"
          @click="handleApply">
          {{ t('申请实例') }}
        </AuthButton>
        <DropdownExportExcel
          :ids="selectedIds"
          type="redis" />
        <ClusterIpCopy :selected="selected" />
      </div>
      <DbSearchSelect
        class="operations-right mb-16"
        :data="searchSelectData"
        :get-menu-list="getMenuList"
        :model-value="searchValue"
        :placeholder="t('请输入或选择条件搜索')"
        unique-select
        @change="handleSearchValueChange" />
    </div>
    <div class="table-wrapper-out">
      <div
        class="table-wrapper"
        :class="{ 'is-shrink-table': isStretchLayoutOpen }">
        <DbTable
          ref="tableRef"
          :columns="columns"
          :data-source="getRedisList"
          :disable-select-method="disableSelectMethod"
          :pagination-extra="paginationExtra"
          releate-url-query
          :row-class="getRowClass"
          selectable
          :settings="settings"
          @clear-search="clearSearchValue"
          @column-filter="columnFilterChange"
          @column-sort="columnSortChange"
          @selection="handleSelection"
          @setting-change="updateTableSettings" />
      </div>
    </div>
  </div>
</template>

<script setup lang="tsx">
  import { Message } from 'bkui-vue';
  import InfoBox from 'bkui-vue/lib/info-box';
  import { useI18n } from 'vue-i18n';

  import RedisModel from '@services/model/redis/redis';
  import {
    getRedisInstances,
    getRedisList,
  } from '@services/source/redis';
  import { createTicket } from '@services/source/ticket';
  import { getUserList } from '@services/source/user';
  import {
    ClusterNodeKeys,
  } from '@services/types/clusters';

  import {
    useCopy,
    useLinkQueryColumnSerach,
    useStretchLayout,
    useTableSettings,
    useTicketMessage,
  } from '@hooks';

  import {
    useGlobalBizs,
  } from '@stores';

  import {
    ClusterTypes,
    TicketTypes,
    type TicketTypesStrings,
    UserPersonalSettings,
  } from '@common/const';

  import ClusterCapacityUsageRate from '@components/cluster-capacity-usage-rate/Index.vue'
  import OperationBtnStatusTips from '@components/cluster-common/OperationBtnStatusTips.vue';
  import RenderOperationTag from '@components/cluster-common/RenderOperationTag.vue';
  import DbStatus from '@components/db-status/index.vue';
  import DbTable from '@components/db-table/index.vue';
  import DropdownExportExcel from '@components/dropdown-export-excel/index.vue';
  import RenderInstances from '@components/render-instances/RenderInstances.vue';
  import TextOverflowLayout from '@components/text-overflow-layout/Index.vue';

  import ClusterIpCopy from '@views/db-manage/common/cluster-ip-copy/Index.vue';
  import RenderCellCopy from '@views/db-manage/common/render-cell-copy/Index.vue';
  import RenderHeadCopy from '@views/db-manage/common/render-head-copy/Index.vue';

  import {
    getMenuListSearch,
    getSearchSelectorParams,
  } from '@utils';

  import type {
    SearchSelectData,
    SearchSelectItem,
  } from '@/types/bkui-vue';

  const clusterId = defineModel<number>('clusterId');

  const { t, locale } = useI18n();
  const copy = useCopy();
  const route = useRoute();
  const router = useRouter();
  const globalBizsStore = useGlobalBizs();
  const ticketMessage = useTicketMessage();
  const {
    isOpen: isStretchLayoutOpen,
    splitScreen: stretchLayoutSplitScreen,
  } = useStretchLayout();

  let isInit = true;

  const {
    columnAttrs,
    searchAttrs,
    searchValue,
    sortValue,
    columnCheckedMap,
    batchSearchIpInatanceList,
    columnFilterChange,
    columnSortChange,
    clearSearchValue,
    handleSearchValueChange,
  } = useLinkQueryColumnSerach({
    searchType: ClusterTypes.REDIS,
    attrs: [
      'bk_cloud_id',
      'major_version',
      'region',
      'time_zone',
    ],
    fetchDataFn: () => fetchData(isInit)
  });

  const tableRef = ref<InstanceType<typeof DbTable>>();
  const showEditEntryConfig = ref(false);
  const selected = ref<RedisModel[]>([])

  const searchSelectData = computed(() => [
    {
      name: t('访问入口'),
      id: 'domain',
      multiple: true,
    },
    {
      name: t('IP 或 IP:Port'),
      id: 'instance',
      multiple: true,
    },
    {
      name: 'ID',
      id: 'id',
    },
    {
      name: t('集群名称'),
      id: 'name',
      multiple: true,
    },
    {
      name: t('管控区域'),
      id: 'bk_cloud_id',
      multiple: true,
      children: searchAttrs.value.bk_cloud_id,
    },
    {
      name: t('状态'),
      id: 'status',
      multiple: true,
      children: [
        {
          id: 'normal',
          name: t('正常'),
        },
        {
          id: 'abnormal',
          name: t('异常'),
        },
      ],
    },
    {
      name: t('版本'),
      id: 'major_version',
      multiple: true,
      children: searchAttrs.value.major_version,
    },
    {
      name: t('地域'),
      id: 'region',
      multiple: true,
      children: searchAttrs.value.region,
    },
    {
      name: t('创建人'),
      id: 'creator',
    },
    {
      name: t('时区'),
      id: 'time_zone',
      multiple: true,
      children: searchAttrs.value.time_zone,
    },
  ] as SearchSelectData);

  const paginationExtra = computed(() => {
    if (isStretchLayoutOpen.value) {
      return { small: false };
    }

    return {
      small: true,
      align: 'left',
      layout: ['total', 'limit', 'list'],
    };
  });
  const hasSelected = computed(() => selected.value.length > 0);
  const selectedIds = computed(() => selected.value.map(item => item.id));
  const isCN = computed(() => locale.value === 'zh-cn');
  const tableOperationWidth = computed(() => {
    if (!isStretchLayoutOpen.value) {
      return isCN.value ? 240 : 320;
    }
    return 60;
  });

  const columns = computed(() => [
    {
      label: 'ID',
      field: 'id',
      fixed: 'left',
      width: 60,
    },
    {
      label: t('访问入口'),
      field: 'master_domain',
      width: 300,
      minWidth: 300,
      fixed: 'left',
      renderHead: () => (
        <RenderHeadCopy
          hasSelected={hasSelected.value}
          onHandleCopySelected={handleCopySelected}
          onHandleCopyAll={handleCopyAll}
          config={
            [
              {
                field: 'master_domain',
                label: t('域名')
              },
              {
                field: 'masterDomainDisplayName',
                label: t('域名:端口')
              }
            ]
          }
        >
          {t('访问入口')}
        </RenderHeadCopy>
      ),
      render: ({ data }: { data: RedisModel }) => (
        <TextOverflowLayout>
          {{
            default: () => (
              <auth-button
                action-id="redis_view"
                resource={data.id}
                permission={data.permission.redis_view}
                text
                theme="primary"
                onClick={() => handleToDetails(data.id)}>
                {data.masterDomainDisplayName}
              </auth-button>
            ),
            append: () => (
              <>
                {data.master_domain && (
                  <RenderCellCopy copyItems={
                    [
                      {
                        value: data.domain,
                        label: t('域名')
                      },
                      {
                        value: data.domainDisplayName,
                        label: t('域名:端口')
                      }
                    ]
                  } />
                )}
                <auth-button
                  v-db-console="redis.haClusterManage.modifyEntryConfiguration"
                  v-bk-tooltips={t('修改入口配置')}
                  action-id="access_entry_edit"
                  resource="redis"
                  permission={data.permission.access_entry_edit}
                  text
                  theme="primary"
                  onClick={() => handleOpenEntryConfig(data)}>
                  <db-icon type="edit" />
                </auth-button>
              </>
            ),
          }}
        </TextOverflowLayout>
      ),
    },
    {
      label: t('集群名称'),
      field: 'name',
      minWidth: 200,
      fixed: 'left',
      showOverflowTooltip: false,
      renderHead: () => (
        <RenderHeadCopy
          hasSelected={hasSelected.value}
          onHandleCopySelected={handleCopySelected}
          onHandleCopyAll={handleCopyAll}
          config={
            [
              {
                field: 'cluster_name'
              },
            ]
          }
        >
          {t('集群名称')}
        </RenderHeadCopy>
      ),
      render: ({ data }: { data: RedisModel }) => (
        <div class="cluster-name-container">
          <div
            class="cluster-name text-overflow"
            v-overflow-tips={{
              content: `<p>${t('集群名称')}：${data.cluster_name}</p><p>${t('集群别名')}：${data.cluster_alias}</p>`,
              allowHTML: true,
            }}>
            <span>
              {data.cluster_name}
            </span>
            <p class="cluster-name-alias">
              {data.cluster_alias || '--'}
            </p>
          </div>
          <div class="cluster-tags">
            {
              data.operationTagTips.map(item => <RenderOperationTag class="cluster-tag" data={item} />)
            }
            {
              !data.isOnline && !data.isStarting && (
                <bk-tag size="small">{t('已禁用')}</bk-tag>
              )
            }
            {
              data.isNew && (
                <bk-tag
                  size="small"
                  theme="success">
                  NEW
                </bk-tag>
              )
            }
          </div>
          <db-icon
            v-bk-tooltips={t('复制集群名称')}
            class="mt-4"
            type="copy"
            onClick={() => copy(data.cluster_name)} />
        </div>
      ),
    },
    {
      label: t('管控区域'),
      field: 'bk_cloud_id',
      filter: {
        list: columnAttrs.value.bk_cloud_id,
        checked: columnCheckedMap.value.bk_cloud_id,
      },
      render: ({ data }: { data: RedisModel }) => <span>{data.bk_cloud_name ?? '--'}</span>,
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
      render: ({ data }: { data: RedisModel }) => {
        const info = data.status === 'normal'
          ? { theme: 'success', text: t('正常') } : { theme: 'danger', text: t('异常') };
        return (
          <DbStatus theme={info.theme}>
            {info.text}
          </DbStatus>
        );
      },
    },
    {
      label: t('容量使用率'),
      field: 'cluster_stats',
      width: 240,
      showOverflowTooltip: false,
      render: ({ data }: { data: RedisModel }) => <ClusterCapacityUsageRate clusterStats={data.cluster_stats} />
    },
    {
      label: 'Master',
      field: ClusterNodeKeys.REDIS_MASTER,
      width: 180,
      minWidth: 180,
      showOverflowTooltip: false,
      renderHead: () => (
        <RenderHeadCopy
          hasSelected={hasSelected.value}
          onHandleCopySelected={(field) => handleCopySelected(field, ClusterNodeKeys.REDIS_MASTER)}
          onHandleCopyAll={(field) => handleCopyAll(field, ClusterNodeKeys.REDIS_MASTER)}
          config={
            [
              {
                label: 'IP',
                field: 'ip'
              },
              {
                label: t('实例'),
                field: 'instance'
              }
            ]
          }
        >
          {'Master'}
        </RenderHeadCopy>
      ),
      render: ({ data }: { data: RedisModel }) => (
        <RenderInstances
          highlightIps={batchSearchIpInatanceList.value}
          data={data[ClusterNodeKeys.REDIS_MASTER]}
          title={t('【inst】实例预览', { title: 'Master', inst: data.master_domain })}
          role={ClusterNodeKeys.REDIS_MASTER}
          clusterId={data.id}
          dataSource={getRedisInstances}
        />
      ),
    },
    {
      label: 'Slave',
      field: ClusterNodeKeys.REDIS_SLAVE,
      width: 180,
      minWidth: 180,
      showOverflowTooltip: false,
      renderHead: () => (
        <RenderHeadCopy
          hasSelected={hasSelected.value}
          onHandleCopySelected={(field) => handleCopySelected(field, ClusterNodeKeys.REDIS_SLAVE)}
          onHandleCopyAll={(field) => handleCopyAll(field, ClusterNodeKeys.REDIS_SLAVE)}
          config={
            [
              {
                label: 'IP',
                field: 'ip'
              },
              {
                label: t('实例'),
                field: 'instance'
              }
            ]
          }
        >
          {'Slave'}
        </RenderHeadCopy>
      ),
      render: ({ data }: { data: RedisModel }) => (
        <RenderInstances
          highlightIps={batchSearchIpInatanceList.value}
          data={data[ClusterNodeKeys.REDIS_SLAVE]}
          title={t('【inst】实例预览', { title: 'Slave', inst: data.master_domain })}
          role={ClusterNodeKeys.REDIS_SLAVE}
          clusterId={data.id}
          dataSource={getRedisInstances}
        />
      ),
    },
    {
      label: t('架构版本'),
      field: 'cluster_type_name',
      minWidth: 160,
      render: ({ data }: { data: RedisModel }) => <span>{data.cluster_type_name || '--'}</span>,
    },
    {
      label: t('版本'),
      field: 'major_version',
      minWidth: 100,
      filter: {
        list: columnAttrs.value.major_version,
        checked: columnCheckedMap.value.major_version,
      },
      render: ({ data }: { data: RedisModel }) => <span>{data.major_version || '--'}</span>,
    },
    {
      label: t('地域'),
      field: 'region',
      minWidth: 100,
      filter: {
        list: columnAttrs.value.region,
        checked: columnCheckedMap.value.region,
      },
      render: ({ data }: { data: RedisModel }) => <span>{data.region || '--'}</span>,
    },
    {
      label: t('更新人'),
      field: 'updater',
      width: 140,
      render: ({ data }: { data: RedisModel }) => <span>{data.updater || '--'}</span>,
    },
    {
      label: t('更新时间'),
      field: 'update_at',
      width: 160,
      render: ({ data }: { data: RedisModel }) => <span>{data.updateAtDisplay || '--'}</span>,
    },
    {
      label: t('创建人'),
      field: 'creator',
      width: 140,
      render: ({ data }: { data: RedisModel }) => <span>{data.creator || '--'}</span>,
    },
    {
      label: t('部署时间'),
      field: 'create_at',
      sort: true,
      width: 160,
      render: ({ data }: { data: RedisModel }) => <span>{data.createAtDisplay || '--'}</span>,
    },
    {
      label: t('时区'),
      field: 'cluster_time_zone',
      width: 100,
      filter: {
        list: columnAttrs.value.time_zone,
        checked: columnCheckedMap.value.time_zone,
      },
      render: ({ data }: { data: RedisModel }) => <span>{data.cluster_time_zone || '--'}</span>,
    },
    {
      label: t('操作'),
      field: '',
      width: tableOperationWidth.value,
      fixed: isStretchLayoutOpen.value ? false : 'right',
      render: ({ data }: { data: RedisModel }) => (
        !data.isOnline ? (
            <OperationBtnStatusTips
              data={data}
              v-db-console="redis.haClusterManage.disable">
              <auth-button
                action-id="redis_open_close"
                resource={data.id}
                permission={data.permission.redis_open_close}
                disabled={data.operationDisabled}
                text
                onClick={() => handleSwitchRedis(TicketTypes.REDIS_INSTANCE_PROXY_CLOSE, data)}>
                { t('禁用') }
              </auth-button>
            </OperationBtnStatusTips>
          ) : (
            <>
              <OperationBtnStatusTips
                data={data}
                v-db-console="redis.haClusterManage.enabley">
                <auth-button
                  action-id="redis_open_close"
                  resource={data.id}
                  permission={data.permission.redis_open_close}
                  text
                  disabled={data.isStarting}
                  onClick={() => handleSwitchRedis(TicketTypes.REDIS_INSTANCE_PROXY_OPEN, data)}>
                  { t('启用') }
                </auth-button>
              </OperationBtnStatusTips>
              <OperationBtnStatusTips
                data={data}
                v-db-console="redis.haClusterManage.delete">
                <auth-button
                  class="ml-16"
                  action-id="redis_destroy"
                  resource={data.id}
                  permission={data.permission.redis_destroy}
                  disabled={Boolean(data.operationTicketId)}
                  text
                  onClick={() => handleDeleteCluster(data)}>
                  { t('删除') }
                </auth-button>
              </OperationBtnStatusTips>
            </>
        )
      ),
    },
  ]);

  // 设置用户个人表头信息
  const defaultSettings = {
    fields: (columns.value || []).filter(item => item.field).map(item => ({
      label: item.label,
      field: item.field,
      disabled: item.field === 'master_domain'
    })),
    checked: [
      'bk_cloud_id',
      'name',
      'master_domain',
      'creator',
      'create_at',
      'major_version',
      'region',
      'cluster_time_zone',
      ClusterNodeKeys.REDIS_MASTER,
      ClusterNodeKeys.REDIS_SLAVE,
    ],
    showLineHeight: false,
    trigger: 'manual' as const,
  };

  const {
    settings,
    updateTableSettings,
  } = useTableSettings(UserPersonalSettings.REDIS_HA_TABLE_SETTINGS, defaultSettings);

  const getMenuList = async (item: SearchSelectItem | undefined, keyword: string) => {
    if (item?.id !== 'creator' && keyword) {
      return getMenuListSearch(item, keyword, searchSelectData.value, searchValue.value);
    }

    // 没有选中过滤标签
    if (!item) {
      // 过滤掉已经选过的标签
      const selected = (searchValue.value || []).map(value => value.id);
      return searchSelectData.value.filter(item => !selected.includes(item.id));
    }

    // 远程加载执行人
    if (item.id === 'creator') {
      if (!keyword) {
        return [];
      }
      return getUserList({
        fuzzy_lookups: keyword,
      }).then(res => res.results.map(item => ({
        id: item.username,
        name: item.username,
      })));
    }

    // 不需要远层加载
    return searchSelectData.value.find(set => set.id === item.id)?.children || [];
  };

  const getRowClass = (data: RedisModel) => {
    const classList = [data.isOnline ? '' : 'is-offline'];
    const newClass = data.isNew ? 'is-new-row' : '';
    classList.push(newClass);
    if (data.id === clusterId.value) {
      classList.push('is-selected-row');
    }
    return classList.filter(cls => cls).join(' ');
  };

  const disableSelectMethod = (data: RedisModel) => {
    if (!data.isOnline) {
      return true;
    }

    if (data.operations?.length > 0) {
      const operationData = data.operations[0];
      return ([TicketTypes.REDIS_DESTROY, TicketTypes.REDIS_PROXY_CLOSE] as string[]).includes(operationData.ticket_type);
    }

    return false;
  };

  const fetchData = (loading?: boolean) => {
    const params = {
      ...getSearchSelectorParams(searchValue.value),
      cluster_type: ClusterTypes.REDIS_INSTANCE,
    }
    tableRef.value!.fetchData(params, {
      ...sortValue,
    }, loading);
    isInit = false;
  };

  const handleCopy = <T,>(dataList: T[], field: keyof T) => {
    const copyList = dataList.reduce((prevList, tableItem) => {
      const value = String(tableItem[field]);
      if (value && value !== '--' && !prevList.includes(value)) {
        prevList.push(value);
      }
      return prevList;
    }, [] as string[]);
    copy(copyList.join('\n'));
  }

  // 获取列表数据下的实例子列表
  const getInstanceListByRole = (dataList: RedisModel[], field: keyof RedisModel) => dataList.reduce((result, curRow) => {
    result.push(...curRow[field] as RedisModel['redis_master']);
    return result;
  }, [] as RedisModel['redis_master']);

  const handleCopySelected = <T,>(field: keyof T, role?: keyof RedisModel) => {
    if(role) {
      handleCopy(getInstanceListByRole(selected.value, role) as T[], field)
      return;
    }
    handleCopy(selected.value as T[], field)
  }

  const handleCopyAll = async <T,>(field: keyof T, role?: keyof RedisModel) => {
    const allData = await tableRef.value!.getAllData<RedisModel>();
    if(allData.length === 0) {
      Message({
        theme: 'primary',
        message: t('暂无数据可复制'),
      });
      return;
    }
    if(role) {
      handleCopy(getInstanceListByRole(allData, role) as T[], field)
      return;
    }
    handleCopy(allData as T[], field)
  }

  /**
   * 申请实例
   */
  const handleApply = () => {
    router.push({
      name: 'SelfServiceApplyRedisHa',
      query: {
        bizId: globalBizsStore.currentBizId,
        from: route.name as string,
      },
    });
  };

  const handleSelection = (data: RedisModel, list: RedisModel[]) => {
    selected.value = list;
  };

  /**
   * 查看集群详情
   */
  const handleToDetails = (id: number) => {
    stretchLayoutSplitScreen();
    clusterId.value = id;
  };

  const handleOpenEntryConfig = (row: RedisModel) => {
    showEditEntryConfig.value  = true;
    clusterId.value = row.id;
  };

  /**
   * 集群启停
   */
  const handleSwitchRedis = (type: TicketTypesStrings, data: RedisModel) => {
    const isOpen = type === TicketTypes.REDIS_INSTANCE_PROXY_OPEN;
    const title = isOpen ? t('确定启用该集群') : t('确定禁用该集群');
    InfoBox({
      type: 'warning',
      title,
      content: () => (
        <div style="word-break: all;">
          {
            isOpen
              ? <p>{t('集群【name】启用后将恢复访问', { name: data.cluster_name })}</p>
              : <p>{t('集群【name】被禁用后将无法访问_如需恢复访问_可以再次「启用」', { name: data.cluster_name })}</p>
          }
        </div>
      ),
      onConfirm: async () => {
        try {
          const params = {
            bk_biz_id: globalBizsStore.currentBizId,
            ticket_type: type,
            details: {
              cluster_ids: [data.id],
            },
          };
          await createTicket(params)
            .then((res) => {
              ticketMessage(res.id);
            });
          return true;
        } catch (_) {
          return false;
        }
      },
    });
  };

  /**
   * 删除集群
   */
  const handleDeleteCluster = (data: RedisModel) => {
    const { cluster_name: name } = data;
    InfoBox({
      type: 'warning',
      title: t('确定删除该集群'),
      confirmText: t('删除'),
      confirmButtonTheme: 'danger',
      content: () => (
        <div style="word-break: all; text-align: left; padding-left: 16px;">
          <p>{t('集群【name】被删除后_将进行以下操作', { name })}</p>
          <p>{t('1_删除xx集群', { name })}</p>
          <p>{t('2_删除xx实例数据_停止相关进程', { name })}</p>
          <p>3. {t('回收主机')}</p>
        </div>
      ),
      onConfirm: async () => {
        try {
          const params = {
            bk_biz_id: globalBizsStore.currentBizId,
            ticket_type: TicketTypes.REDIS_DESTROY,
            details: {
              cluster_id: data.id,
            },
          };
          await createTicket(params)
            .then((res) => {
              ticketMessage(res.id);
            });
          return true;
        } catch (_) {
          return false;
        }
      },
    });
  };

  onMounted(() => {
    if (!clusterId.value && route.query.id) {
      handleToDetails(Number(route.query.id));
    }
  });
</script>

<style lang="less" scoped>
  @import '@styles/mixins.less';

  .redis-cluster-list-page {
    height: 100%;
    padding: 24px 0;
    margin: 0 24px;

    .operation-box {
      display: flex;
      flex-wrap: wrap;

      .bk-search-select {
        flex: 1;
        max-width: 500px;
        min-width: 320px;
        margin-left: auto;
      }

      .cluster-dropdown {
        margin-right: auto;

        .cluster-dropdown-icon {
          color: @gray-color;
          transform: rotate(0);
          transition: all 0.2s;
        }

        .cluster-dropdown-icon-active {
          transform: rotate(-90deg);
        }
      }
    }

    .table-wrapper-out {
      flex: 1;
      overflow: hidden;

      .table-wrapper {
        background-color: white;

        .bk-table {
          height: 100% !important;
        }

        :deep(td .cell) {
          line-height: unset !important;

          .db-icon-copy,
          .db-icon-edit {
            display: none;
            margin-top: 1px;
            margin-left: 4px;
            color: @primary-color;
            cursor: pointer;
          }
        }

        :deep(.cluster-name-container) {
          display: flex;
          align-items: flex-start;
          padding: 8px 0;
          overflow: hidden;

          .cluster-name {
            line-height: 16px;

            .cluster-name-alias {
              color: @light-gray;
            }
          }

          .cluster-tags {
            display: flex;
            align-items: center;
            flex-wrap: wrap;
            margin-left: 4px;
          }

          .cluster-tag {
            flex-shrink: 0;
            margin: 2px;
          }
        }

        :deep(.ip-list) {
          padding: 8px 0;

          .ip-list-more {
            display: inline-block;
            margin-top: 2px;
          }
        }

        :deep(.operation-box) {
          .bk-button {
            margin-right: 8px;
          }

          .operations-more {
            .db-icon-more {
              font-size: 16px;
              color: @default-color;
              cursor: pointer;

              &:hover {
                background-color: @bg-disable;
                border-radius: 2px;
              }
            }
          }
        }

        :deep(th:hover),
        :deep(td:hover) {
          .db-icon-copy,
          .db-icon-edit {
            display: inline-block;
          }
        }

        :deep(.is-offline) {
          .cluster-name-container {
            .cluster-name {
              a {
                color: @gray-color;
              }

              .cluster-name-alias {
                color: @disable-color;
              }
            }
          }

          .cell {
            color: @disable-color;
          }
        }

        :deep(.bk-table-body) {
          max-height: calc(100% - 100px);
        }
      }
    }
  }
</style>

<style lang="less">
  .redis-manage-clb-minitag {
    color: #8e3aff;
    cursor: pointer;
    background-color: #f2edff;

    &:hover {
      color: #8e3aff;
      background-color: #e3d9fe;
    }
  }

  .redis-manage-polary-minitag {
    color: #3a84ff;
    cursor: pointer;
    background-color: #edf4ff;

    &:hover {
      color: #3a84ff;
      background-color: #e1ecff;
    }
  }

  .redis-manage-infobox {
    .bk-modal-body {
      .bk-modal-header {
        .bk-dialog-header {
          .bk-dialog-title {
            margin-top: 18px;
            margin-bottom: 16px;
          }
        }
      }

      .bk-modal-footer {
        height: 80px;
      }
    }
  }
</style>
