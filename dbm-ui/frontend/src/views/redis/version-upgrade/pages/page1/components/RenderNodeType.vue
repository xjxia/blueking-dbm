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
  <TableEditSelect
    ref="selectRef"
    v-model="localValue"
    :list="selectList"
    :placeholder="t('请选择')"
    :rules="rules"
    @change="(value) => handleChange(value as string)" />
</template>
<script setup lang="ts">
  import { useI18n } from 'vue-i18n';

  import TableEditSelect from '@views/redis/common/edit/Select.vue';

  import type { IDataRow } from './Row.vue';

  interface Props {
    data?: IDataRow['nodeType']
  }

  interface Emits {
    (e: 'change', value: string): void
  }

  const props = defineProps<Props>();
  const emits = defineEmits<Emits>();

  const { t } = useI18n();

  const selectRef = ref<InstanceType<typeof TableEditSelect>>();
  const localValue = ref(props.data ? props.data : 'Proxy');

  const selectList = [
    {
      value: 'Proxy',
      label: 'Proxy',
    },
    {
      value: 'Backend',
      label: 'Backend',
    },
  ];

  const rules = [
    {
      validator: (value: string) => Boolean(value),
      message: t('请先输入集群'),
    },
  ];

  const handleChange = (value: string) => {
    emits('change', value);
  };
</script>
