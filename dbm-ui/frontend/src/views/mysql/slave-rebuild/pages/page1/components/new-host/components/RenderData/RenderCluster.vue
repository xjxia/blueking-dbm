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
  <BkLoading :loading="isLoading">
    <div
      v-if="renderDomainList.length > 0"
      class="slave-rebuild-related-cluster"
      :style="{background: oldSlave ? '#FFF' : '#FAFBFD' }">
      <div
        v-for="(domain, index) in renderDomainList"
        :key="index"
        class="domain-item">
        <span>{{ domain }}</span>
      </div>
    </div>
    <RenderText
      v-else
      ref="displayRef"
      :placeholder="t('自动生成')"
      :rules="rules" />
  </BkLoading>
</template>
<script setup lang="ts">
  import { computed, shallowRef } from 'vue';
  import { useI18n } from 'vue-i18n';
  import { useRequest } from 'vue-request';

  import { checkMysqlInstances } from '@services/source/instances';

  import { useGlobalBizs } from '@stores';

  import RenderText from '@components/render-table/columns/text-plain/index.vue';

  import type { IDataRow } from './Row.vue';

  interface Props {
    oldSlave?: IDataRow['oldSlave'];
  }

  interface Exposes {
    getValue: () => Promise<{ cluster_ids: number[] }>
  }

  const props = defineProps<Props>();

  const { t } = useI18n();
  const { currentBizId } = useGlobalBizs();

  const displayRef = ref();

  const localRelateClusterList = shallowRef<ServiceReturnType<typeof checkMysqlInstances>[0]['related_clusters']>([]);

  const renderDomainList = computed(() => {
    if (localRelateClusterList.value?.length < 1) {
      return [];
    }
    return localRelateClusterList.value.map(item => item.master_domain);
  });

  const rules = [
    {
      validator: (value: string) => !!value,
      message: t('不能为空'),
    },
  ];

  const {
    loading: isLoading,
    run: fetchCheckMysqlInstances,
  } = useRequest(checkMysqlInstances, {
    manual: true,
    onSuccess(data) {
      const [instanceData] = data;
      localRelateClusterList.value = instanceData.related_clusters;
    },
  });

  watch(
    () => props.oldSlave,
    () => {
      localRelateClusterList.value = [];
      if (!props.oldSlave) {
        return;
      }
      fetchCheckMysqlInstances({
        bizId: currentBizId,
        instance_addresses: [props.oldSlave.ip],
      });
    },
    {
      immediate: true,
    },
  );

  defineExpose<Exposes>({
    getValue() {
      if (localRelateClusterList.value.length < 1) {
        return displayRef.value.getValue();
      }
      return Promise.resolve({
        cluster_ids: localRelateClusterList.value.map(item => item.id),
      });
    },
  });
</script>
<style lang="less">
.slave-rebuild-related-cluster {
  padding: 10px 16px;
  line-height: 20px;

  .domain-item {
    width: 100%;
    overflow-x: hidden;
    text-overflow: ellipsis;
  }

  .default-text {
    font-size: 12px;
    color: #C4C6CC;
  }
}
</style>
