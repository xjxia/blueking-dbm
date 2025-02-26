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
  <div
    v-if="isRender"
    class="render-cluster-opration-tag">
    <span ref="rootRef">
      <BkTag
        size="small"
        :style="iconStyle">
        {{ data.icon }}
      </BkTag>
    </span>
    <I18nT
      ref="popRef"
      keypath="xx_跳转_单据_查看进度"
      style="font-size: 12px; line-height: 16px; color: #63656e"
      tag="div">
      <span>{{ data.tip }}</span>
      <AuthRouterLink
        v-if="isShown"
        action-id="ticket_view"
        :resource="data.ticketId"
        target="_blank"
        :to="{
          name: 'SelfServiceMyTickets',
          query: {
            id: data.ticketId,
          },
        }">
        {{ t('单据') }}
      </AuthRouterLink>
    </I18nT>
  </div>
</template>
<script setup lang="ts">
  import tippy, { type Instance, type SingleTarget } from 'tippy.js';
  import { useI18n } from 'vue-i18n';

  interface Props {
    data: {
      icon: string;
      tip: string;
      ticketId: number;
    };
  }

  const props = defineProps<Props>();

  const { t } = useI18n();

  const iconMap: Record<string, Record<string, string>> = {
    [t('销毁中')]: {
      color: '#EA3536',
      background: '#FEEBEA',
    },
    [t('迁移中')]: {
      color: '#8E3AFF',
      background: '#F2EDFF',
    },
    [t('删除中')]: {
      color: '#EA3536',
      background: '#FEEBEA',
    },
    [t('启用中')]: {
      color: '#74BC09',
      background: '#EDFFD3',
    },
    [t('禁用中')]: {
      color: '#FE9C00',
      background: '#FFF1DB',
    },
  };

  const rootRef = ref();
  const popRef = ref();
  const isShown = ref(false);
  const iconStyle = computed(() => iconMap[props.data.icon] ?? '');
  const isRender = computed(() => props.data.icon && props.data.tip && props.data.ticketId);

  let tippyIns: Instance;

  const destroyInst = () => {
    if (tippyIns) {
      tippyIns.hide();
      tippyIns.unmount();
      tippyIns.destroy();
    }
  };

  watch(
    isRender,
    () => {
      if (isRender.value) {
        destroyInst();
        nextTick(() => {
          tippyIns = tippy(rootRef.value as SingleTarget, {
            content: popRef.value.$el,
            placement: 'top',
            appendTo: () => document.body,
            theme: 'light',
            maxWidth: 'none',
            interactive: true,
            arrow: true,
            offset: [0, 8],
            zIndex: 999999,
            hideOnClick: true,
            onShow() {
              isShown.value = true;
            },
            onHide() {
              isShown.value = false;
            },
          });
        });
      }
    },
    {
      immediate: true,
    },
  );

  onBeforeUnmount(() => {
    destroyInst();
  });
</script>
<style lang="less" scoped>
  .render-cluster-opration-tag {
    display: inline-block;
    margin-right: 4px;

    .tag-placeholder {
      display: inline-block;
      height: 16px;
      padding: 0 4px;
      line-height: 16px;
      cursor: pointer;

      .icon-text {
        display: inline-block;
        font-size: 10px;
      }
    }

    .default-icon {
      color: #63656e;
      background: #f0f1f5;
    }
  }
</style>
