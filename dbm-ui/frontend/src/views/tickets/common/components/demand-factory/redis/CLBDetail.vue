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
    :columns="columns"
    :data="tableData" />
</template>

<script setup lang="tsx">
  import { useI18n } from 'vue-i18n';

  import type { RedisCLBDetails } from '@services/model/ticket/details/redis';
  import TicketModel from '@services/model/ticket/ticket';

  interface Props {
    ticketDetails: TicketModel<RedisCLBDetails>;
  }

  const props = defineProps<Props>();

  const { t } = useI18n();

  const columns = [
    {
      label: t('集群'),
      field: 'clusterName',
      showOverflowTooltip: true,
    },
  ];

  const tableData = computed(() =>
    Object.values(props.ticketDetails.details.clusters).map((item) => ({
      clusterName: item.immute_domain,
    })),
  );
</script>
