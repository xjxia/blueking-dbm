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
  <div class="my-tickets-page">
    <List @change="handleChangeTicket" />
    <div
      v-if="activeTicket"
      class="ticket-detail-wrapper">
      <Details
        :data="activeTicket"
        @update-active-ticket="handleChangeTicket" />
      <!-- <TicketClone :data="activeTicket" /> -->
    </div>
  </div>
</template>
<script setup lang="ts">
  import TicketModel from '@services/model/ticket/ticket';

  import Details from './components/details/Index.vue';
  import List from './components/list/Index.vue';

  const activeTicket = ref<TicketModel<unknown>>();

  const handleChangeTicket = (data: TicketModel<unknown>) => {
    activeTicket.value = data;
  };
</script>
<style lang="less">
  .my-tickets-page {
    display: flex;
    height: 100%;

    .ticket-detail-wrapper {
      position: relative;
      height: 100%;
      flex: 1;
      overflow-y: auto;
    }
  }
</style>
