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
  <DbOriginalTable
    class="details-flashback__table"
    :columns="columns"
    :data="dataList" />
</template>

<script setup lang="tsx">
  import { useI18n } from 'vue-i18n';

  import type { MySQLFlashback } from '@services/model/ticket/details/mysql';
  import TicketModel from '@services/model/ticket/ticket';

  import { utcDisplayTime } from '@utils';

  interface Props {
    ticketDetails: TicketModel<MySQLFlashback>
  }

  const props = defineProps<Props>();

  const { t } = useI18n();

  const columns = [
    {
      label: t('集群名称'),
      field: 'cluster_name',
      render: ({ cell }: { cell: string }) => <span>{cell || '--'}</span>,
    },
    {
      label: t('开始时间'),
      field: 'start_time',
      showOverflowTooltip: true,
      render: ({ cell }: { cell: string }) => <span>{utcDisplayTime(cell) || '--'}</span>,
    },
    {
      label: t('结束时间'),
      field: 'end_time',
      showOverflowTooltip: true,
      render: ({ cell }: { cell: string }) => <span>{utcDisplayTime(cell) || '--'}</span>,
    },
    {
      label: t('目标库'),
      field: 'databases',
      showOverflowTooltip: false,
      render: ({ cell }: { cell: string[] }) => (
      <div class="text-overflow" v-overflow-tips={{
          content: cell,
        }}>
        {cell.map(item => <bk-tag>{item}</bk-tag>)}
      </div>
    ),
    },
    {
      label: t('目标表'),
      field: 'tables',
      showOverflowTooltip: false,
      render: ({ cell }: { cell: string[] }) => (
      <div class="text-overflow" v-overflow-tips={{
          content: cell,
        }}>
        {cell.map(item => <bk-tag>{item}</bk-tag>)}
      </div>
    ),
    },
    {
      label: t('忽略库'),
      field: 'databases_ignore',
      showOverflowTooltip: false,
      render: ({ cell }: { cell: string[] }) => (
      <div class="text-overflow" v-overflow-tips={{
          content: cell,
        }}>
        {cell.length > 0 ? cell.map(item => <bk-tag>{item}</bk-tag>) : '--'}
      </div>
    ),
    },
    {
      label: t('忽略表'),
      field: 'tables_ignore',
      showOverflowTooltip: false,
      render: ({ cell }: { cell: string[] }) => (
      <div class="text-overflow" v-overflow-tips={{
          content: cell,
        }}>
        {cell.length > 0 ? cell.map(item => <bk-tag>{item}</bk-tag>) : '--'}
      </div>
    ),
    },
  ];

  const dataList = computed(() => {
    const { clusters, infos } = props.ticketDetails.details;
    return infos.map(item => ({
      ...item,
      cluster_name: clusters[item.cluster_id].immute_domain,
    }));
  });
</script>

<style lang="less" scoped>
  @import '@views/tickets/common/styles/DetailsTable.less';
</style>
