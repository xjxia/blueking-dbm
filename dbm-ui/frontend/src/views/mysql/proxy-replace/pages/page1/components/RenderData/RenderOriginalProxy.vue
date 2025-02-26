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
  <TableEditInput
    ref="editRef"
    v-model="localInstanceAddress"
    multi-input
    :placeholder="$t('请输入IP_Port_使用换行分割一次可输入多个')"
    :rules="rules"
    @multi-input="handleMultiInput" />
</template>
<script lang="ts">
  const instanceAddreddMemo: { [key: string]: Record<string, boolean> } = {};
</script>
<script setup lang="ts">
  import { useI18n } from 'vue-i18n';

  import { checkMysqlInstances } from '@services/source/instances';

  import { useGlobalBizs } from '@stores';

  import TableEditInput from '@views/mysql/common/edit/Input.vue';

  import { random } from '@utils';

  import type { IProxyData } from './Row.vue';

  interface Props {
    modelValue?: IProxyData,
  }

  interface Emits {
    (e: 'inputCreate', value: Array<string>): void,
    (e: 'inputFinish', value: IProxyData): void
  }

  interface Exposes {
    getValue: () => Array<number>
  }

  const props = defineProps<Props>();
  const emits = defineEmits<Emits>();

  const instanceKey = `render_original_proxy_${random()}`;
  instanceAddreddMemo[instanceKey] = {};
  let proxyInstanceMemo = {} as IProxyData;

  const { currentBizId } = useGlobalBizs();
  const { t } = useI18n();

  const editRef = ref();

  const localClusterId = ref(0);
  const localInstanceAddress = ref('');
  const isShowEdit = ref(true);

  const rules = [
    {
      validator: (value: string) => {
        if (value) {
          return true;
        }
        return false;
      },
      message: t('目标Proxy不能为空'),
    },
    {
      validator: () => checkMysqlInstances({
        bizId: currentBizId,
        instance_addresses: [localInstanceAddress.value],
      }).then((data) => {
        if (data.length < 1) {
          return false;
        }
        instanceAddreddMemo[instanceKey][localInstanceAddress.value] = true;

        const [currentInstanceData] = data;
        proxyInstanceMemo = currentInstanceData;
        emits('inputFinish', proxyInstanceMemo);
        localClusterId.value = currentInstanceData.cluster_id;
        return true;
      }),
      message: t('目标Proxy不存在'),
    },
    {
      validator: () => {
        const currentClusterSelectMap = instanceAddreddMemo[instanceKey];
        const otherClusterMemoMap = { ...instanceAddreddMemo };
        delete otherClusterMemoMap[instanceKey];

        const otherClusterIdMap = Object.values(otherClusterMemoMap).reduce((result, item) => ({
          ...result,
          ...item,
        }), {} as Record<string, boolean>);

        const currentSelectClusterIdList = Object.keys(currentClusterSelectMap);
        for (let i = 0; i < currentSelectClusterIdList.length; i++) {
          if (otherClusterIdMap[currentSelectClusterIdList[i]]) {
            return false;
          }
        }
        return true;
      },
      message: t('目标Proxy重复'),
    },
  ];

  // 同步外部值
  watch(() => props.modelValue, () => {
    if (props.modelValue) {
      proxyInstanceMemo = props.modelValue;
      localClusterId.value = props.modelValue.cluster_id;
      localInstanceAddress.value = props.modelValue.instance_address;

      if (localInstanceAddress.value) {
        instanceAddreddMemo[instanceKey][localInstanceAddress.value] = true;
      }

      isShowEdit.value = !props.modelValue.instance_address;
    }
  }, {
    immediate: true,
  });

  // 获取关联集群
  watch(localClusterId, () => {
    if (!localClusterId.value) {
      return;
    }
  }, {
    immediate: true,
  });

  const handleMultiInput = (list: Array<string>) => {
    nextTick(() => {
      emits('inputCreate', list);
    });
  };

  onBeforeUnmount(() => {
    delete instanceAddreddMemo[instanceKey]
  })

  defineExpose<Exposes>({
    getValue() {
      const {
        bk_host_id,
        bk_cloud_id,
        ip,
        port,
      } = proxyInstanceMemo;

      const result = {
        cluster_ids: [localClusterId.value],
        origin_proxy: {
          bk_biz_id: currentBizId,
          bk_host_id,
          bk_cloud_id,
          ip,
          port,
        },
      };

      return editRef.value.getValue().then(() => result);
    },
  });
</script>
