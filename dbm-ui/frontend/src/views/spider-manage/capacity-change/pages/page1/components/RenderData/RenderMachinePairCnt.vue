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
    ref="inputRef"
    :model-value="`${clusterData ? clusterData.machinePairCnt : ''}`"
    :placeholder="t('输入集群后自动生成')"
    readonly
    textarea />
</template>
<script setup lang="ts">
  import { ref } from 'vue';
  import { useI18n } from 'vue-i18n';

  import TableEditInput from '@views/spider-manage/common/edit/Input.vue';

  import type { IDataRow } from './Row.vue';

  interface Props {
    clusterData: IDataRow['clusterData'];
  }

  interface Exposes {
    getValue: () => Promise<string>;
  }

  defineProps<Props>();

  const { t } = useI18n();

  const inputRef = ref<InstanceType<typeof TableEditInput>>();

  defineExpose<Exposes>({
    getValue() {
      return inputRef.value!.getValue();
    },
  });
</script>
