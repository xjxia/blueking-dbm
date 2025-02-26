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
  <BkDialog
    v-model:is-show="modelValue"
    class="import-host-dialog"
    :esc-close="false"
    :quick-close="false"
    :width="width">
    <BkResizeLayout
      :border="false"
      collapsible
      :initial-divide="400"
      placement="right"
      :style="layoutStyle">
      <template #main>
        <SelectHostPanel
          v-if="modelValue"
          v-model="hostSelectList"
          :content-height="contentHeight" />
      </template>
      <template #aside>
        <FormPanel
          ref="formRef"
          v-model:host-list="hostSelectList" />
      </template>
    </BkResizeLayout>
    <template #footer>
      <div>
        <span
          v-bk-tooltips="{
            disabled: hostSelectList.length > 1,
            content: t('请选择主机'),
          }">
          <BkButton
            :disabled="hostSelectList.length < 1"
            :loading="isSubmiting"
            theme="primary"
            @click="handleSubmit">
            {{ t('确定') }}
          </BkButton>
        </span>
        <BkButton
          class="ml-8"
          @click="handleCancel">
          {{ t('取消') }}
        </BkButton>
      </div>
    </template>
  </BkDialog>
</template>
<script setup lang="ts">
  import { ref, shallowRef } from 'vue';
  import { useI18n } from 'vue-i18n';

  import type ImportHostModel from '@services/model/db-resource/import-host';
  import { importResource } from '@services/source/dbresourceResource';

  import { messageSuccess } from '@utils';

  import FormPanel from './components/FormPanel.vue';
  import SelectHostPanel from './components/select-host-panel/Index.vue';

  interface Emits {
    (e: 'change'): void;
  }

  const emits = defineEmits<Emits>();

  const modelValue = defineModel<boolean>('isShow', {
    default: false,
  });

  const { t } = useI18n();

  const formRef = ref();
  const isSubmiting = ref(false);
  const hostSelectList = shallowRef<ImportHostModel[]>([]);
  const width = Math.ceil(window.innerWidth * 0.8);

  const contentHeight = Math.ceil(window.innerHeight * 0.8 - 48);
  const layoutStyle = {
    height: `${contentHeight}px`,
  };

  const handleSubmit = () => {
    isSubmiting.value = true;
    formRef.value
      .getValue()
      .then((data: any) =>
        importResource({
          for_bizs: data.for_bizs,
          resource_types: data.resource_types,
          hosts: hostSelectList.value.map((item) => ({
            ip: item.ip,
            host_id: item.host_id,
            bk_cloud_id: item.cloud_id,
          })),
        }).then(() => {
          window.changeConfirm = false;
          messageSuccess(t('操作成功'));
          handleCancel();
          emits('change');
        }),
      )
      .finally(() => {
        isSubmiting.value = false;
      });
  };

  const handleCancel = () => {
    modelValue.value = false;
  };
</script>
<style lang="less">
  .import-host-dialog {
    .bk-modal-header {
      display: none;
    }
    .bk-dialog-content {
      padding: 0;
      margin: 0;
    }
  }
</style>
