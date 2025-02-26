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
      <RenderText
        :data="data.nodeType"
        :is-loading="data.isLoading"
        :placeholder="$t('输入集群后自动生成')" />
    </td>
    <td style="padding: 0">
      <RenderSpec
        :data="data.spec"
        :is-loading="data.isLoading" />
    </td>
    <td style="padding: 0">
      <RenderTargetNumber
        ref="editRef"
        :data="data.targetNum"
        :disabled="!data.cluster"
        :is-loading="data.isLoading"
        :max="data.spec?.count" />
    </td>
    <td style="padding: 0">
      <RenderSwitchMode
        ref="switchRef"
        :data="data.switchMode"
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
  import RenderText from '@components/render-table/columns/text-plain/index.vue';

  import RenderTargetCluster from '@views/redis/common/edit-field/ClusterName.vue';
  import type { SpecInfo } from '@views/redis/common/spec-panel/Index.vue';

  import { random } from '@utils';

  import RenderSwitchMode, { OnlineSwitchType } from './RenderSwitchMode.vue';
  import RenderTargetNumber from './RenderTargetNumber.vue';

  export interface IDataRow {
    rowKey: string;
    isLoading: boolean;
    cluster: string;
    clusterId: number;
    bkCloudId: number;
    nodeType: string;
    switchMode?: string;
    spec?: SpecInfo;
    targetNum?: string;
  }

  export interface InfoItem {
    cluster_id: number;
    bk_cloud_id: number;
    target_proxy_count: number;
    online_switch_type: OnlineSwitchType;
  }

  // 创建表格数据
  export const createRowData = (): IDataRow => ({
    rowKey: random(),
    isLoading: false,
    cluster: '',
    clusterId: 0,
    bkCloudId: 0,
    nodeType: '',
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
  const switchRef = ref<InstanceType<typeof RenderSwitchMode>>();
  const editRef = ref<InstanceType<typeof RenderTargetNumber>>();

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
      return await Promise.all([editRef.value!.getValue(), switchRef.value!.getValue()]).then((data) => {
        const [targetNum, switchMode] = data;
        return {
          cluster_id: props.data.clusterId,
          bk_cloud_id: props.data.bkCloudId,
          target_proxy_count: targetNum,
          online_switch_type: switchMode,
        };
      });
    },
  });
</script>
