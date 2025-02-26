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
  <BkFormItem
    v-if="affinityList && affinityList.length > 0"
    :label="t('容灾要求')"
    required>
    <BkRadioGroup
      v-model="localValue"
      @change="handleRadioChange">
      <BkRadio
        v-for="item in regionList"
        :key="item.value"
        :label="item.value">
        {{ item.label }}
      </BkRadio>
    </BkRadioGroup>
  </BkFormItem>
</template>
<script setup lang="ts">
  import { useI18n } from 'vue-i18n';

  import { useSystemEnviron } from '@stores';

  interface Props {
    cityCode?: string;
  }

  const props = defineProps<Props>();
  const modelValue = defineModel<string>({
    default: '',
  });

  const { t } = useI18n();
  const { AFFINITY: affinityList } = useSystemEnviron().urls;

  const localValue = ref('');
  const regionList = ref<{
    label: string;
    value: string;
  }[]>([]);

  watch(modelValue, (value) => {
    localValue.value = value;
  });

  watch(() => [affinityList, props.cityCode], () => {
    if (props.cityCode !== 'default') {
      if (affinityList && affinityList.length > 0) {
        regionList.value = affinityList;
        if (modelValue.value) {
          const index = affinityList.findIndex(affinityItem => affinityItem.value === modelValue.value);
          modelValue.value = index > -1 ? modelValue.value : affinityList[0].value;
        } else {
          modelValue.value = affinityList[0].value;
        }
      }
    } else {
      regionList.value = [
        {
          label: t('无容灾要求'),
          value: 'NONE',
        },
        {
          label: t('跨机架部署'),
          value: 'CROSS_RACK',
        }
      ];
      modelValue.value = 'NONE';
    }

  }, {
    immediate: true,
  });

  const handleRadioChange = (value: string) => {
    modelValue.value = value;
  };

  onBeforeUnmount(() => {
    modelValue.value = 'NONE';
  });
</script>
