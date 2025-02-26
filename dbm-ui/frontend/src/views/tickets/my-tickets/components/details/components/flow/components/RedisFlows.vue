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
  <BkTimeline :list="flowTimeline">
    <template #content="{ content }">
      <FlowContent
        :content="content"
        :flows="flows"
        :ticket-data="ticketData"
        @fetch-data="handleFetchData">
        <template #extra-text>
          <template v-if="content.isLast && content.status === 'SUCCEEDED'">
            ，
            <a
              href="javascript:"
              @click="handleShowResultFile(content.flow_obj_id)">
              {{ $t('查看结果文件') }}
            </a>
          </template>
        </template>
      </FlowContent>
    </template>
  </BkTimeline>
  <RedisResultFiles
    :id="fileState.id"
    v-model="fileState.isShow" />
</template>

<script setup lang="tsx">
  import TicketModel from '@services/model/ticket/ticket';
  import type { FlowItem } from '@services/types/ticket';

  import RedisResultFiles from '@views/task-history/components/RedisResultFiles.vue';
  import FlowIcon from '@views/tickets/common/components/flow-content/components/FlowIcon.vue';
  import FlowContent from '@views/tickets/common/components/flow-content/Index.vue';

  interface Props {
    ticketData: TicketModel<unknown>,
    flows?: FlowItem[]
  }

  interface Emits {
    (e: 'fetch-data'): void
  }

  const props = withDefaults(defineProps<Props>(), {
    flows: () => [],
  });
  const emits = defineEmits<Emits>();

  const fileState = reactive({
    isShow: false,
    id: '',
  });
  const flowTimeline = computed(() => props.flows.map((flow: FlowItem, index: number) => {
    const isLast = index === props.flows.length - 1;
    // const prevFlow = props.flows[index - 1];
    // const flowObjId = isLast && prevFlow ? prevFlow.flow_obj_id : flow.flow_obj_id;
    return {
      tag: flow.flow_type_display,
      type: 'default',
      filled: true,
      content: Object.assign(flow, { isLast }),
      // color,
      icon: () => <FlowIcon data={flow} />,
    };
  }));

  const handleShowResultFile = (id: string) => {
    fileState.isShow = true;
    fileState.id = id;
  };

  const handleFetchData = () => {
    emits('fetch-data');
  };
</script>
