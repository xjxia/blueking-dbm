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
  <!-- <FlowContentInnerFlow
    v-if="content?.todos?.length > 0 && content.flow_type === 'INNER_FLOW' && isTodos === false"
    :content="content"
    @fetch-data="handleEmitFetchData" /> -->
  <template v-if="content.todos?.length > 0 && content.flow_type === 'INNER_FLOW' && content.status === 'RUNNING'">
    <ManualConfirm
      v-for="item in content.todos"
      :key="item.id"
      :content="content"
      :data="item"
      @processed="handleEmitFetchData" />
  </template>
  <template
    v-else-if="content?.todos?.length > 0 && ['TERMINATED', 'SUCCEEDED'].includes(content.status) && isTodos === false">
    <FlowContentTodo
      v-for="item of content.todos"
      :key="item.id"
      :data="item"
      :href-target="getHrefTarget(content)" />
  </template>
  <!-- 人工确认 -->
  <template v-else-if="content.status === 'PENDING' && content.flow_type === 'PAUSE'">
    <I18nT keypath="等待C确认是否执行T">
      <span>{{ ticketData.creator }}</span>
      <span>{{ manualNexFlowDisaply }}</span>
    </I18nT>
  </template>
  <template v-else-if="isPause && isTodos === false">
    <div
      v-for="(todosItem, index) in content.todos"
      :key="index">
      <span>{{ t('处理人') }}: </span>
      <span>{{ todosItem.operators.join(',') }}</span>
      <template v-if="content.summary">
        ，{{ t('耗时') }}：
        <CostTimer
          :is-timing="content.status === 'RUNNING'"
          :start-time="utcTimeToSeconds(content.start_time)"
          :value="content.cost_time" />
      </template>
      <div
        v-if="todosItem.operators.includes(username)"
        class="mt-8">
        <BkPopConfirm
          :content="t('继续执行单据后无法撤回，请谨慎操作！')"
          :title="t('是否确认继续执行单据')"
          trigger="click"
          :width="320"
          @confirm="handleProcessTicket('APPROVE', todosItem)">
          <BkButton
            class="w-88 mr-8"
            theme="primary">
            {{ t('确认执行') }}
          </BkButton>
        </BkPopConfirm>
        <BkPopConfirm
          :content="t('终止单据后无法撤回，请谨慎操作！')"
          :title="t('是否确认终止单据')"
          trigger="click"
          :width="320"
          @confirm="handleProcessTicket('TERMINATE', todosItem)">
          <BkButton
            class="w-88 mr-8"
            theme="danger">
            {{ t('终止单据') }}
          </BkButton>
        </BkPopConfirm>
      </div>
    </div>
  </template>
  <template v-if="content.flow_type !== 'PAUSE'">
    <div>
      <template
        v-if="
          content.status === 'RUNNING' &&
          (content.flow_type === 'RESOURCE_APPLY' || content.flow_type === 'RESOURCE_BATCH_APPLY')
        ">
        <DbIcon
          class="resource-apply-exclamation-fill"
          type="exclamation-fill" />
        <I18nT
          keypath="主机资源不足_等待管理员users补货_补货完成后可以前往place重试"
          tag="span">
          <template #users>
            {{ (content.todos[0]?.context?.administrators ?? []).join(';') }}
          </template>
          <template #place>
            <RouterLink
              :to="{
                name: 'MyTodos',
                query: {
                  id: content.ticket,
                },
              }">
              {{ t('我的待办') }}
            </RouterLink>
          </template>
        </I18nT>
      </template>
      <template v-else-if="isPause && isTodos === false">
        <span>{{ t('处理人') }}: </span>
        <span>{{ _.uniq(_.flatten(content.todos.map((item) => item.operators))).join(',') }}</span>
      </template>
      <template v-else>
        <span
          :style="{
            color: content.status === 'TERMINATED' ? '#ea3636' : '#63656e',
          }">
          {{ content.summary }}
        </span>
      </template>
      <template v-if="content.summary">
        ，{{ t('耗时') }}：
        <CostTimer
          :is-timing="content.status === 'RUNNING'"
          :start-time="utcTimeToSeconds(content.start_time)"
          :value="content.cost_time" />
      </template>
      <template v-if="content.url">
        ，
        <a
          :href="content.url"
          :target="getHrefTarget(content)">
          {{ t('查看详情') }} &gt;
        </a>
      </template>
      <slot name="extra-text" />
    </div>
    <div
      v-if="content.end_time"
      class="flow-time">
      {{ utcDisplayTime(content.end_time) }}
    </div>
    <!-- <BkPopover
      v-if="content.err_code === 2"
      v-model:is-show="state.confirmTips"
      theme="light"
      trigger="manual"
      :width="320">
      <BkButton
        ref="retryButtonRef"
        class="w-88 mt-8"
        :loading="state.isLoading"
        theme="primary"
        @click="handleConfirmToggle">
        {{ t('重试') }}
      </BkButton>
      <template #content>
        <div
          v-clickoutside:[retryButtonRef?.$el]="handleConfirmCancel"
          class="ticket-flow-content">
          <div class="ticket-flow-content-desc">
            {{ t('是否确认重新执行单据') }}
          </div>
          <div class="ticket-flow-content-buttons">
            <BkButton
              :loading="state.isLoading"
              size="small"
              theme="primary"
              @click="handleConfirm(content)">
              {{ t('确认') }}
            </BkButton>
            <BkButton
              :disabled="state.isLoading"
              size="small"
              @click="handleConfirmCancel">
              {{ t('取消') }}
            </BkButton>
          </div>
        </div>
      </template>
    </BkPopover> -->
    <div class="mt-8">
      <BkPopConfirm
        v-if="content.err_code === 2"
        :content="t('重新执行后无法撤回，请谨慎操作！')"
        :title="t('是否确认重新执行单据')"
        trigger="click"
        :width="320"
        @confirm="handleConfirm(content)">
        <BkButton
          class="w-88 mt-8"
          theme="primary">
          {{ t('重试') }}
        </BkButton>
      </BkPopConfirm>
    </div>
  </template>
</template>

<script setup lang="ts">
  import _ from 'lodash';
  import { useI18n } from 'vue-i18n';

  import TicketModel from '@services/model/ticket/ticket';
  import { processTicketTodo, retryTicketFlow  } from '@services/source/ticket';
  import type { FlowItem } from '@services/types/ticket';

  import { useUserProfile } from '@stores';

  import CostTimer from '@components/cost-timer/CostTimer.vue';

  import ManualConfirm from '@views/tickets/my-todos/components/details/components/flow/components/approve/ManualConfirm.vue';

  import { utcDisplayTime, utcTimeToSeconds } from '@utils';

  // import FlowContentInnerFlow from './components/ContentInnerFlow.vue';
  import FlowContentTodo from './components/ContentTodo.vue';


  interface Emits {
    (e: 'fetch-data'): void;
  }

  interface Props {
    ticketData: TicketModel<unknown>,
    content: FlowItem,
    flows?: FlowItem[],
    isTodos?: boolean
  }

  const props = withDefaults(defineProps<Props>(), {
    isTodos: false,
    flows: () => [],
  });
  const emits = defineEmits<Emits>();

  const { t } = useI18n();
  // const { username } = useUserProfile();

  // const retryButtonRef = ref();
  // const state = reactive({
  //   confirmTips: false,
  //   isLoading: false,
  // });
  const { username } = useUserProfile();

  const manualNexFlowDisaply = computed(() => {
    if (props.flows.length > 0) {
      const manualIndex = props.flows.findIndex(item => item.flow_type === 'PAUSE');
      if (manualIndex > -1) {
        return props.flows[manualIndex + 1].flow_type_display;
      }
    }
    return '';
  });

  const isPause = computed(() => {
    const { content } = props;
    return content.status === 'RUNNING' && content.flow_type === 'PAUSE';
  });

  const getHrefTarget = (content: FlowItem) => (content.flow_type === 'BK_ITSM' ? '_blank' : '_self');

  const handleConfirm = (item: FlowItem) => retryTicketFlow({
    ticketId: item.ticket,
    flow_id: item.id,
  })
    .then(() => {
      emits('fetch-data');
    });

  const handleProcessTicket = (action: 'APPROVE' | 'TERMINATE', todoItem: FlowItem['todos'][number]) => processTicketTodo({
    action,
    todo_id: todoItem.id,
    ticket_id: props.content.ticket,
    params: {},
  })
    .then(() => {
      emits('fetch-data');
    });

  const handleEmitFetchData = () => {
    emits('fetch-data');
  };

  // function handleConfirmToggle() {
  //   state.confirmTips = !state.confirmTips;
  // }

  // function handleConfirmCancel() {
  //   state.confirmTips = false;
  // }
</script>

<style lang="less" scoped>
  .resource-apply-exclamation-fill {
    margin-right: 4px;
    font-size: 14px;
    color: #ff9c01;
  }
</style>

<style lang="less">
  .todos-tips-content {
    .todos-tips-content__desc {
      padding: 8px 0 24px;
      font-size: @font-size-mini;
      color: @title-color;
    }

    .todos-tips-content__buttons {
      text-align: right;

      .bk-button {
        min-width: 62px;
        margin-left: 8px;
        font-size: @font-size-mini;
      }
    }
  }
</style>
