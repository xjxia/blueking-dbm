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
  <tr>
    <td style="padding: 0">
      <RenderMaster
        ref="masterHostRef"
        :model-value="data.masterData"
        @change="handleMasterHostChange" />
    </td>
    <td style="padding: 0">
      <RenderHost
        ref="slaveHostRef"
        :cluster-list="relatedClusterList"
        :data="localSlaveData" />
    </td>
    <td style="padding: 0">
      <RenderCluster
        ref="clusterRef"
        :master-data="localMasterData"
        @change="handleClusterChange" />
    </td>
    <td>
      <div class="action-box">
        <div
          class="action-btn"
          @click="handleAppend">
          <DbIcon type="plus-fill" />
        </div>
        <div
          class="action-btn"
          :class="{
            disabled: removeable,
          }"
          @click="handleRemove">
          <DbIcon type="minus-fill" />
        </div>
      </div>
    </td>
  </tr>
</template>
<script lang="ts">
  import { ref, shallowRef, watch } from 'vue';

  import { random } from '@utils';

  import RenderCluster from './RenderCluster.vue';
  import RenderMaster from './RenderMaster.vue';
  import RenderHost from './RenderSlave.vue';

  export type IHostData = {
    bk_host_id: number;
    bk_cloud_id: number;
    ip: string;
  };

  export interface IDataRow {
    rowKey: string;
    masterData?: IHostData;
    slaveData?: IHostData;
    clusterData?: {
      id: number;
      domain: string;
    };
  }

  // 创建表格数据
  export const createRowData = (data = {} as Partial<IDataRow>) => ({
    rowKey: random(),
    masterData: data.masterData,
    slaveData: data.slaveData,
    clusterData: data.clusterData,
  });
</script>
<script setup lang="ts">
  interface Props {
    data: IDataRow;
    removeable: boolean;
  }
  interface Emits {
    (e: 'add', params: Array<IDataRow>): void;
    (e: 'remove'): void;
  }

  interface Exposes {
    getValue: () => Promise<any>;
  }

  const props = defineProps<Props>();

  const emits = defineEmits<Emits>();

  const masterHostRef = ref();
  const slaveHostRef = ref();
  const clusterRef = ref();

  const localMasterData = ref<IHostData>();
  const localSlaveData = ref<IHostData>();

  const relatedClusterList = shallowRef<number[]>([]);

  watch(
    () => props.data,
    () => {
      localMasterData.value = props.data.masterData;
      localSlaveData.value = props.data.slaveData;
    },
    {
      immediate: true,
    },
  );

  const handleMasterHostChange = (data: IHostData) => {
    localMasterData.value = data;
    localSlaveData.value = undefined;
  };

  const handleClusterChange = (data: number[]) => {
    relatedClusterList.value = data;
  };

  const handleAppend = () => {
    emits('add', [createRowData()]);
  };

  const handleRemove = () => {
    if (props.removeable) {
      return;
    }
    emits('remove');
  };

  defineExpose<Exposes>({
    getValue() {
      return Promise.all([
        masterHostRef.value.getValue('master_ip'),
        slaveHostRef.value.getValue(),
        clusterRef.value.getValue(),
      ]).then(([masterHostData, slaveHostData, clusterData]) => ({
        ...masterHostData,
        ...slaveHostData,
        ...clusterData,
      }));
    },
  });
</script>
<style lang="less" scoped>
  .action-box {
    display: flex;
    align-items: center;

    .action-btn {
      display: flex;
      font-size: 14px;
      color: #c4c6cc;
      cursor: pointer;
      transition: all 0.15s;

      &:hover {
        color: #979ba5;
      }

      &.disabled {
        color: #dcdee5;
        cursor: not-allowed;
      }

      & ~ .action-btn {
        margin-left: 18px;
      }
    }
  }
</style>
