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
      <RenderTargetCluster
        ref="clusterRef"
        :data="data.cluster"
        :inputed="inputedClusters"
        @input-finish="handleInputFinish" />
    </td>
    <td style="padding: 0">
      <RenderInstance
        ref="instanceRef"
        :cluster-type="data.clusterType"
        :data="data.instances"
        :is-loading="data.isLoading"
        @change="handleChoosedListChange" />
    </td>
    <td style="padding: 0">
      <RenderSpec
        :data="data.spec"
        is-ignore-counts
        :is-loading="data.isLoading" />
    </td>
    <td style="padding: 0">
      <RenderTargetHostNumber
        ref="hostNumRef"
        :data="data.hostNum"
        :is-loading="data.isLoading"
        :max="targetMax" />
    </td>
    <td style="padding: 0">
      <RenderTargetDateTime
        ref="timeRef"
        :data="data.targetDateTime"
        :is-loading="data.isLoading" />
    </td>
    <OperateColumn
      :removeable="removeable"
      @add="handleAppend"
      @remove="handleRemove" />
  </tr>
</template>
<script lang="ts">
  import RedisModel from '@services/model/redis/redis';

  import OperateColumn from '@components/render-table/columns/operate-column/index.vue';
  import RenderSpec from '@components/render-table/columns/spec-display/Index.vue';

  import RenderTargetCluster from '@views/redis/common/edit-field/ClusterName.vue';
  import type { SpecInfo } from '@views/redis/common/spec-panel/Index.vue';

  import { random } from '@utils';

  import RenderInstance from './RenderInstance.vue';
  import RenderTargetDateTime from './RenderTargetDateTime.vue';
  import RenderTargetHostNumber from './RenderTargetHostNumber.vue';

  export interface IDataRow {
    rowKey: string;
    isLoading: boolean;
    cluster: string;
    clusterId: number;
    bkCloudId: number;
    clusterType: string;
    instances?: string[];
    spec?: SpecInfo;
    hostNum?: string;
    targetDateTime?: string;
  }

  export interface InfoItem {
    cluster_id: number;
    bk_cloud_id: number;
    master_instances: string[];
    recovery_time_point: string;
    resource_spec: {
      redis: {
        spec_id: number;
        count: number;
      };
    };
  }

  // 创建表格数据
  export const createRowData = (): IDataRow => ({
    rowKey: random(),
    isLoading: false,
    cluster: '',
    clusterType: '',
    clusterId: 0,
    bkCloudId: 0,
  });
</script>
<script setup lang="ts">
  interface Props {
    data: IDataRow;
    removeable: boolean;
    inputedClusters?: string[];
  }

  interface Emits {
    (e: 'add', params: Array<IDataRow>): void;
    (e: 'remove'): void;
    (e: 'clusterInputFinish', value: RedisModel): void;
  }

  interface Exposes {
    getValue: () => Promise<InfoItem>;
  }

  const props = withDefaults(defineProps<Props>(), {
    inputedClusters: () => [],
  });

  const emits = defineEmits<Emits>();

  const clusterRef = ref<InstanceType<typeof RenderTargetCluster>>();
  const instanceRef = ref<InstanceType<typeof RenderInstance>>();
  const hostNumRef = ref<InstanceType<typeof RenderTargetHostNumber>>();
  const timeRef = ref<InstanceType<typeof RenderTargetDateTime>>();
  const targetMax = ref(0);

  const handleChoosedListChange = (arr: string[]) => {
    targetMax.value = arr.length;
  };

  const handleInputFinish = (value: RedisModel) => {
    emits('clusterInputFinish', value);
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
    async getValue() {
      await clusterRef.value!.getValue(true);
      return Promise.all([instanceRef.value!.getValue(), hostNumRef.value!.getValue(), timeRef.value!.getValue()]).then(
        (data) => {
          const [instances, hostNum, targetDateTime] = data;
          return {
            cluster_id: props.data.clusterId,
            bk_cloud_id: props.data.bkCloudId,
            master_instances: instances,
            recovery_time_point: targetDateTime,
            resource_spec: {
              redis: {
                spec_id: props.data.spec?.id ?? 0,
                count: Number(hostNum),
              },
            },
          };
        },
      );
    },
  });
</script>
