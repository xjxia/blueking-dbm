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
  <BkLoading :loading="loading">
    <DbOriginalTable
      :columns="columns"
      :data="tableData" />
  </BkLoading>
</template>

<script setup lang="tsx">
  import { useI18n } from 'vue-i18n';
  import { useRequest } from 'vue-request';

  import ResourceSpecModel from '@services/model/resource-spec/resourceSpec';
  import type { RedisAddSlaveDetails } from '@services/model/ticket/details/redis';
  import TicketModel from '@services/model/ticket/ticket';
  import { getResourceSpecList } from '@services/source/dbresourceSpec';
  import { getRedisListByBizId } from '@services/source/redis';

  interface Props {
    ticketDetails: TicketModel<RedisAddSlaveDetails>
  }

  interface RowData {
    hostIp: string,
    clusterName: string,
    clusterType: string,
    sepc: {
      id: number,
      name: string,
    },
    targetNum: number,
  }

  const props = defineProps<Props>();

  const { t } = useI18n();

  const tableData = ref<RowData[]>([]);

  const { infos } = props.ticketDetails.details;

  const columns = [
    {
      label: t('目标主库主机'),
      field: 'hostIp',
      showOverflowTooltip: true,
    },
    {
      label: t('所属集群'),
      field: 'clusterName',
      showOverflowTooltip: true,
    },
    {
      label: t('规格需求'),
      field: 'sepc',
      showOverflowTooltip: true,
      render: ({ data }: {data: RowData}) => <span>{data.sepc.name}</span>,
    },
    {
      label: t('新增从库主机数量'),
      field: 'targetNum',
    },
  ];

  const { loading } = useRequest(getRedisListByBizId, {
    defaultParams: [{
      bk_biz_id: props.ticketDetails.bk_biz_id,
      offset: 0,
      limit: -1,
    }],
    onSuccess: async (result) => {
      if (result.results.length < 1) {
        return;
      }
      const clusterMap = result.results.reduce((obj, item) => {
        Object.assign(obj, { [item.id]: {
          clusterName: item.master_domain,
          clusterType: item.cluster_spec.spec_cluster_type,
        } });
        return obj;
      }, {} as Record<number, {clusterName: string, clusterType: string}>);

      // 避免重复查询
      const clusterTypes = [...new Set(Object.values(clusterMap).map(item => item.clusterType))];

      const sepcMap: Record<string, ResourceSpecModel[]> = {};

      await Promise.all(clusterTypes.map(async (type) => {
        const ret = await getResourceSpecList({
          spec_cluster_type: type,
          limit: -1,
          offset: 0,
        });
        sepcMap[type] = ret.results;
      }));

      loading.value = false;
      tableData.value = infos.reduce((results, item) => {
        const sepcList = sepcMap[clusterMap[item.cluster_id].clusterType];
        item.pairs.forEach((pair) => {
          const specInfo = sepcList.find(row => row.spec_id === pair.redis_slave.spec_id);
          const obj = {
            hostIp: pair.redis_master.ip,
            clusterName: clusterMap[item.cluster_id].clusterName,
            clusterType: clusterMap[item.cluster_id].clusterType,
            sepc: {
              id: pair.redis_slave.spec_id,
              name: specInfo ? specInfo.spec_name : '',
            },
            targetNum: pair.redis_slave.count,
          };
          results.push(obj);
        });
        return results;
      }, [] as RowData[]);
    },
  });
</script>
