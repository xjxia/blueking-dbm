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
  <SmartAction>
    <div class="spider-manage-rollback-page">
      <BkAlert
        closable
        theme="info"
        :title="
          t(
            '定点构造：新建一个单节点实例，通过全备 +binlog 的方式，将数据库恢复到过去的某一时间点或者某个指定备份文件的状态',
          )
        " />
      <div class="title-spot mt-12 mb-10">{{ t('时区') }}<span class="required" /></div>
      <TimeZonePicker style="width: 450px" />
      <RenderData
        class="mt16"
        @batch-select-cluster="handleShowBatchSelector">
        <RenderDataRow
          v-for="item in tableData"
          :key="item.rowKey"
          ref="rowRefs"
          :data="item" />
      </RenderData>
      <ClusterSelector
        v-model:is-show="isShowBatchSelector"
        :cluster-types="[ClusterTypes.TENDBCLUSTER]"
        :selected="selectedClusters"
        :tab-list-config="tabListConfig"
        @change="handelClusterChange" />
      <BatchEntry
        v-model:is-show="isShowBatchEntry"
        @change="handleBatchEntry" />
    </div>
    <template #action>
      <BkButton
        class="w-88"
        :loading="isSubmitting"
        theme="primary"
        @click="handleSubmit">
        {{ t('提交') }}
      </BkButton>
      <DbPopconfirm
        :confirm-handler="handleReset"
        :content="t('重置将会清空当前填写的所有内容_请谨慎操作')"
        :title="t('确认重置页面')">
        <BkButton
          class="ml8 w-88"
          :disabled="isSubmitting">
          {{ t('重置') }}
        </BkButton>
      </DbPopconfirm>
    </template>
  </SmartAction>
</template>

<script setup lang="tsx">
  import { useI18n } from 'vue-i18n';
  import { useRouter } from 'vue-router';

  import SpiderModel from '@services/model/spider/spider';
  import { createTicket } from '@services/source/ticket';

  import { useGlobalBizs } from '@stores';

  import { ClusterTypes } from '@common/const';

  import ClusterSelector from '@components/cluster-selector/Index.vue';
  import TimeZonePicker from '@components/time-zone-picker/index.vue';

  import BatchEntry, { type IValue as IBatchEntryValue } from './components/BatchEntry.vue';
  import RenderData from './components/RenderData/Index.vue';
  import RenderDataRow, { createRowData, type IDataRow } from './components/RenderData/Row.vue';

  const router = useRouter();
  const { currentBizId } = useGlobalBizs();
  const { t } = useI18n();

  const rowRefs = ref();
  const isShowBatchSelector = ref(false);
  const isShowBatchEntry = ref(false);
  const isSubmitting = ref(false);

  const tableData = shallowRef<Array<IDataRow>>([createRowData({})]);
  const selectedClusters = shallowRef<{ [key: string]: Array<SpiderModel> }>({ [ClusterTypes.TENDBCLUSTER]: [] });

  const tabListConfig = {
    [ClusterTypes.TENDBCLUSTER]: {
      multiple: false,
    },
  };

  // 集群域名是否已存在表格的映射表
  // let domainMemo: Record<string, boolean> = {};

  // 检测列表是否为空
  const checkListEmpty = (list: Array<IDataRow>) => {
    if (list.length > 1) {
      return false;
    }
    const [firstRow] = list;
    return (
      !firstRow.clusterData &&
      !firstRow.rollbackTime &&
      !firstRow.databases &&
      !firstRow.databasesIgnore &&
      !firstRow.tables &&
      !firstRow.tablesIgnore
    );
  };

  // 批量选择
  const handleShowBatchSelector = () => {
    isShowBatchSelector.value = true;
  };

  // 批量选择
  const handleBatchEntry = (list: Array<IBatchEntryValue>) => {
    const newList = list.map((item) => createRowData(item));
    if (checkListEmpty(tableData.value)) {
      tableData.value = newList;
    } else {
      tableData.value = [...tableData.value, ...newList];
    }
    window.changeConfirm = true;
  };

  // 批量选择
  const handelClusterChange = (selected: { [key: string]: Array<SpiderModel> }) => {
    selectedClusters.value = selected;
    const list = selected[ClusterTypes.TENDBCLUSTER];
    const newList = list.reduce((result, item) => {
      // const domain = item.master_domain;
      // if (!domainMemo[domain]) {
      const row = createRowData({
        clusterData: {
          id: item.id,
          domain: item.master_domain,
          cloudId: item.bk_cloud_id,
        },
      });
      result.push(row);
      // domainMemo[domain] = true;
      // }
      return result;
    }, [] as IDataRow[]);
    tableData.value = newList;
    // if (checkListEmpty(tableData.value)) {
    //   tableData.value = newList;
    // } else {
    //   tableData.value = [...tableData.value, ...newList];
    // }
    window.changeConfirm = true;
  };

  const handleSubmit = () => {
    isSubmitting.value = true;
    Promise.all(rowRefs.value.map((item: { getValue: () => Promise<any> }) => item.getValue()))
      .then((data) =>
        createTicket({
          ticket_type: 'TENDBCLUSTER_ROLLBACK_CLUSTER',
          remark: '',
          details: data[0],
          bk_biz_id: currentBizId,
        }).then((data) => {
          window.changeConfirm = false;
          router.push({
            name: 'spiderRollback',
            params: {
              page: 'success',
            },
            query: {
              ticketId: data.id,
            },
          });
        }),
      )
      .finally(() => {
        isSubmitting.value = false;
      });
  };

  const handleReset = () => {
    tableData.value = [createRowData()];
    selectedClusters.value[ClusterTypes.TENDBCLUSTER] = [];
    // domainMemo = {};
    window.changeConfirm = false;
  };
</script>

<style lang="less">
  .spider-manage-rollback-page {
    padding-bottom: 20px;
  }
</style>
