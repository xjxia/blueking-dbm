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
    class="details-slave__table"
    :columns="columns"
    :data="dataList" />
</template>

<script setup lang="tsx">
  import { useI18n } from 'vue-i18n';

  import type { MysqlIpItem, MySQLRestoreSlaveDetails } from '@services/model/ticket/details/mysql';
  import TicketModel from '@services/model/ticket/ticket';

  interface Props {
    ticketDetails: TicketModel<MySQLRestoreSlaveDetails>
  }

  const props = defineProps<Props>();

  const { t } = useI18n();

  type restoreSlaveItem = {
    backup_source: string,
    cluster_ids: number[],
    new_slave: MysqlIpItem,
    old_slave: MysqlIpItem,
    immute_domain: string,
    name: string,
  }

  // MySQL Slave重建
  const columns = [
    {
      label: t('集群ID'),
      field: 'cluster_ids',
      render: ({ cell }: { cell: number }) => <span>{cell || '--'}</span>,
    },
    {
      label: t('集群名称'),
      field: 'immute_domain',
      showOverflowTooltip: false,
      render: ({ data }: { data: restoreSlaveItem }) => (
      <div class="cluster-name text-overflow"
        v-overflow-tips={{
          content: `
            <p>${t('域名')}：${data.immute_domain}</p>
            ${data.name ? `<p>${('集群别名')}：${data.name}</p>` : null}
          `,
          allowHTML: true,
      }}>
        <span>{data.immute_domain}</span><br />
        <span class="cluster-name__alias">{data.name}</span>
      </div>
    ),
    },
    {
      label: t('旧从库主机'),
      field: 'old_slave',
      render: ({ cell }: { cell: string }) => <span>{cell || '--'}</span>,
    },
    {
      label: t('新从库主机'),
      field: 'new_slave',
      render: ({ cell }: { cell: string }) => <span>{cell || '--'}</span>,
    },
    {
      label: t('备份源'),
      field: 'backup_source',
      render: ({ cell }: { cell: string }) => <span>{cell === 'local' ? t('本地备份') : '--'}</span>,
    }
  ];

  const dataList = computed(() => {
    const list: restoreSlaveItem[] = [];
    const {
      clusters,
      backup_source,
      infos,
    } = props.ticketDetails.details;
    infos.forEach((item) => {
      if (item.cluster_ids) {
        item.cluster_ids.forEach((id) => {
          const clusterData = clusters[id];
          list.push(Object.assign({
            cluster_ids: id,
            new_slave: item.new_slave.ip,
            old_slave: item.old_slave.ip,
            backup_source,
            immute_domain: clusterData.immute_domain,
            name: clusterData.name,
          }));
        });
      }
    });
    return list;
  });
</script>

<style lang="less" scoped>
  @import '@views/tickets/common/styles/DetailsTable.less';
</style>
