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
  <div class="render-data">
    <RenderTable>
      <template #default>
        <RenderTableHeadColumn
          :min-width="150"
          :width="180">
          <span>{{ $t('源集群') }}</span>
        </RenderTableHeadColumn>
        <RenderTableHeadColumn
          :min-width="120"
          :required="false"
          :width="180">
          <span>{{ $t('集群类型') }}</span>
        </RenderTableHeadColumn>
        <RenderTableHeadColumn
          :min-width="150"
          :width="180">
          <span>{{ $t('访问密码') }}</span>
        </RenderTableHeadColumn>
        <RenderTableHeadColumn
          :min-width="120"
          :width="300">
          <span>{{ $t('目标集群') }}</span>
        </RenderTableHeadColumn>
        <RenderTableHeadColumn
          :min-width="100"
          :width="180">
          <span>{{ $t('包含Key') }}</span>
        </RenderTableHeadColumn>
        <RenderTableHeadColumn
          :min-width="100"
          :required="false"
          :width="180">
          <span>{{ $t('排除Key') }}</span>
        </RenderTableHeadColumn>
        <RenderTableHeadColumn
          fixed="right"
          :required="false"
          :width="100">
          {{ $t('操作') }}
        </RenderTableHeadColumn>
      </template>

      <template #data>
        <RenderDataRow
          v-for="(item, index) in tableData"
          :key="item.rowKey"
          ref="rowRefs"
          :cluster-list="clusterList"
          :data="item"
          :removeable="tableData.length < 2"
          @add="(payload: Array<IDataRow>) => handleAppend(index, payload)"
          @cluster-input-finish="(domain: string) => handleChangeCluster(index, domain)"
          @remove="handleRemove(index)" />
      </template>
    </RenderTable>
  </div>
</template>
<script setup lang="ts">
  import RedisDSTHistoryJobModel from '@services/model/redis/redis-dst-history-job';
  import type { RedisClusterType as ClusterType } from '@services/model/ticket/details/redis';

  import { useTicketCloneInfo } from '@hooks';

  import { LocalStorageKeys, TicketTypes } from '@common/const';

  import RenderTableHeadColumn from '@components/render-table/HeadColumn.vue';
  import RenderTable from '@components/render-table/Index.vue';

  import type { SelectItem } from '@views/redis/db-data-copy/pages/page1/components/RenderTargetCluster.vue';
  import type { SelfbuiltClusterToIntraInfoItem } from '@views/redis/db-data-copy/pages/page1/Index.vue';

  import { destroyLocalStorage } from '../../Index.vue';

  import RenderDataRow, { createRowData, type IDataRow } from './Row.vue';

  interface Props {
    clusterList: SelectItem[];
  }

  interface Exposes {
    getValue: () => Promise<SelfbuiltClusterToIntraInfoItem[]>;
    resetTable: () => void;
  }

  defineProps<Props>();

  const emits = defineEmits<{
    'change-table-available': [status: boolean];
  }>();

  // 单据克隆
  useTicketCloneInfo({
    type: TicketTypes.REDIS_CLUSTER_DATA_COPY,
    onSuccess(cloneData) {
      tableData.value = cloneData.tableList;
      window.changeConfirm = true;
    },
  });

  const tableData = ref([createRowData()]);
  const rowRefs = ref();
  const tableAvailable = computed(() => tableData.value.findIndex((item) => Boolean(item.srcCluster)) > -1);

  watch(
    () => tableAvailable.value,
    (status) => {
      emits('change-table-available', status);
    },
  );

  onMounted(() => {
    checkandRecoverDataListFromLocalStorage();
  });

  const checkandRecoverDataListFromLocalStorage = () => {
    const r = localStorage.getItem(LocalStorageKeys.REDIS_DB_DATA_RECORD_RECOPY);
    if (!r) {
      return;
    }
    const item = JSON.parse(r) as RedisDSTHistoryJobModel;
    tableData.value = [
      {
        rowKey: item.src_cluster,
        isLoading: false,
        srcCluster: item.src_cluster,
        targetClusterId: item.dst_cluster_id,
        includeKey: item.key_white_regex === '' ? [] : item.key_white_regex.split('\n'),
        excludeKey: item.key_black_regex === '' ? [] : item.key_black_regex.split('\n'),
        clusterType: item.src_cluster_type as ClusterType,
        password: '',
      },
    ];
    destroyLocalStorage();
  };

  const handleChangeCluster = async (index: number, domain: string) => {
    tableData.value[index].srcCluster = domain;
  };

  // 追加一个集群
  const handleAppend = (index: number, appendList: Array<IDataRow>) => {
    tableData.value.splice(index + 1, 0, ...appendList);
  };
  // 删除一个集群
  const handleRemove = (index: number) => {
    tableData.value.splice(index, 1);
  };

  defineExpose<Exposes>({
    getValue: () =>
      Promise.all<SelfbuiltClusterToIntraInfoItem[]>(
        rowRefs.value.map((item: { getValue: () => Promise<SelfbuiltClusterToIntraInfoItem> }) => item.getValue()),
      ),
    resetTable: () => {
      tableData.value = [createRowData()];
    },
  });
</script>
<style lang="less">
  .render-data {
    .batch-edit-btn {
      margin-left: 4px;
      color: #3a84ff;
      cursor: pointer;
    }
  }
</style>
