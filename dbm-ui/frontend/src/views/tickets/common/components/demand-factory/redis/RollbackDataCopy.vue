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
  <div class="ticket-details__info">
    <div
      class="ticket-details__item"
      style="align-items: flex-start">
      <span class="ticket-details__item-label">{{ t('需求信息') }}：</span>
      <span class="ticket-details__item-value">
        <DbOriginalTable
          :columns="columns"
          :data="tableData" />
      </span>
    </div>
  </div>
  <div class="ticket-details__info">
    <div class="ticket-details__list">
      <div class="ticket-details__item">
        <span class="ticket-details__item-label">{{ t('写入类型') }}：</span>
        <span class="ticket-details__item-value">{{ writeTypesMap[ticketDetails.details.write_mode] }}</span>
      </div>
    </div>
  </div>
</template>

<script setup lang="tsx">
  import { useI18n } from 'vue-i18n';

  import type { RedisRollbackDataCopyDetails } from '@services/model/ticket/details/redis';
  import TicketModel from '@services/model/ticket/ticket';

  import { writeTypeList } from '@views/redis/common/const';

  interface Props {
    ticketDetails: TicketModel<RedisRollbackDataCopyDetails>
  }

  interface RowData {
    entry: string,
    taregtClusterName: string,
    time: string,
    includeKeys: string[],
    excludeKeys: string[],
  }

  const props = defineProps<Props>();

  const { t } = useI18n();

  const writeTypesMap = writeTypeList.reduce((obj, item) => {
    Object.assign(obj, { [item.value]: item.label });
    return obj;
  }, {} as Record<string, string>);

  const columns = [
    {
      label: t('构造产物访问入口'),
      field: 'entry',
      showOverflowTooltip: true,
    },
    {
      label: t('目标集群'),
      field: 'taregtClusterName',
      showOverflowTooltip: true,
    },
    {
      label: t('构造到指定时间'),
      field: 'time',
      showOverflowTooltip: true,
    },
    {
      label: t('包含 Key'),
      field: 'includeKeys',
      showOverflowTooltip: true,
      render: ({ data }: {data: RowData}) => {
        if (data.includeKeys.length > 0) {
          return data.includeKeys.map((key, index) => <bk-tag key={index} type="stroke">{key}</bk-tag>);
        }
        return <span>--</span>;
      },
    },
    {
      label: t('排除 Key'),
      field: 'excludeKeys',
      showOverflowTooltip: true,
      render: ({ data }: {data: RowData}) => {
        if (data.excludeKeys.length > 0) {
          return data.excludeKeys.map((key, index) => <bk-tag key={index} type="stroke">{key}</bk-tag>);
        }
        return <span>--</span>;
      },
    },
  ];

  const tableData = computed(() => {
    const {
      clusters,
      infos,
    } = props.ticketDetails.details;

    return infos.map(item => ({
      entry: item.src_cluster,
      taregtClusterName: clusters[item.dst_cluster].immute_domain,
      time: item.recovery_time_point,
      includeKeys: item.key_white_regex === '' ? [] : item.key_white_regex.split('\n'),
      excludeKeys: item.key_black_regex === '' ? [] : item.key_black_regex.split('\n'),
    }))
  });
</script>

<style lang="less" scoped>
  @import '@views/tickets/common/styles/ticketDetails.less';
</style>
