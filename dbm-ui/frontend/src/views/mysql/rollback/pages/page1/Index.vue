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
    <div class="rollback-page">
      <BkAlert
        closable
        theme="info"
        :title="t('新建一个单节点实例_通过全备_binlog的方式_将数据库恢复到过去的某一时间点或者某个指定备份文件的状态')" />
      <div
        class="mt16"
        style="display: flex">
        <BkButton @click="handleShowBatchEntry">
          <DbIcon type="add" />
          {{ t('批量录入') }}
        </BkButton>
      </div>
      <div class="title-spot mt-12 mb-10">
        {{ t('时区') }}<span class="required" />
      </div>
      <TimeZonePicker style="width: 450px;" />
      <RenderData
        class="mt16"
        @batch-edit-backup-source="handleBatchEditBackupSource"
        @batch-select-cluster="handleShowBatchSelector">
        <RenderDataRow
          v-for="(item, index) in tableData"
          :key="item.rowKey"
          ref="rowRefs"
          :data="item"
          :removeable="tableData.length < 2"
          @add="(payload: Array<IDataRow>) => handleAppend(index, payload)"
          @remove="handleRemove(index)" />
      </RenderData>
      <ClusterSelector
        v-model:is-show="isShowBatchSelector"
        :cluster-types="[ClusterTypes.TENDBHA]"
        :selected="selectedClusters"
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

  import TendbhaModel from '@services/model/mysql/tendbha';
  import { createTicket } from '@services/source/ticket';

  import { useTicketCloneInfo } from '@hooks';

  import { useGlobalBizs } from '@stores';

  import { ClusterTypes, TicketTypes } from '@common/const';

  import ClusterSelector from '@components/cluster-selector/Index.vue';
  import TimeZonePicker from '@components/time-zone-picker/index.vue';

  import BatchEntry, { type IValue as IBatchEntryValue } from './components/BatchEntry.vue';
  import RenderData from './components/RenderData/Index.vue';
  import RenderDataRow, { createRowData, type IDataRow } from './components/RenderData/Row.vue';

  // 检测列表是否为空
  const checkListEmpty = (list: Array<IDataRow>) => {
    if (list.length > 1) {
      return false;
    }
    const [firstRow] = list;
    return (
      !firstRow.clusterData &&
      !firstRow.rollbackIp &&
      !firstRow.backupid &&
      !firstRow.rollbackTime &&
      !firstRow.databases &&
      !firstRow.databasesIgnore &&
      !firstRow.tables &&
      !firstRow.tablesIgnore
    );
  };

  const router = useRouter();
  const { currentBizId } = useGlobalBizs();
  const { t } = useI18n();

  // 单据克隆
  useTicketCloneInfo({
    type: TicketTypes.MYSQL_ROLLBACK_CLUSTER,
    onSuccess(cloneData) {
      tableData.value = cloneData.tableDataList;
      window.changeConfirm = true;
    },
  });

  const rowRefs = ref();
  const isShowBatchSelector = ref(false);
  const isShowBatchEntry = ref(false);
  const isSubmitting = ref(false);

  const tableData = ref<Array<IDataRow>>([createRowData({})]);
  const selectedClusters = shallowRef<{[key: string]: Array<TendbhaModel>}>({ [ClusterTypes.TENDBHA]: [] });

  // 集群域名是否已存在表格的映射表
  let domainMemo: Record<string, boolean> = {};

  // 批量录入
  const handleShowBatchEntry = () => {
    isShowBatchEntry.value = true;
  };

  // 批量录入
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
  const handleShowBatchSelector = () => {
    isShowBatchSelector.value = true;
  };

  const handleBatchEditBackupSource = (value: string) => {
    if (!value) {
      return;
    }

    tableData.value.forEach((row) => {
      Object.assign(row, {
        backupSource: value,
      });
    });
  };

  // 批量选择
  const handelClusterChange = (selected: Record<string, Array<TendbhaModel>>) => {
    selectedClusters.value = selected;
    const newList = selected[ClusterTypes.TENDBHA].reduce((results, clusterData) => {
      const domain = clusterData.master_domain;
      if (!domainMemo[domain]) {
        const row = createRowData({
          clusterData: {
            id: clusterData.id,
            domain,
            cloudId: clusterData.bk_cloud_id,
          },
        });
        results.push(row);
        domainMemo[domain] = true;
      }
      return results;
    }, [] as IDataRow[]);

    if (checkListEmpty(tableData.value)) {
      tableData.value = newList;
    } else {
      tableData.value = [...tableData.value, ...newList];
    }
    window.changeConfirm = true;
  };

  // 追加一个集群
  const handleAppend = (index: number, appendList: Array<IDataRow>) => {
    const dataList = [...tableData.value];
    dataList.splice(index + 1, 0, ...appendList);
    tableData.value = dataList;
  };

  // 删除一个集群
  const handleRemove = (index: number) => {
    const dataList = [...tableData.value];
    const domain = dataList[index].clusterData?.domain;
    if (domain) {
      delete domainMemo[domain];
      const clustersArr = selectedClusters.value[ClusterTypes.TENDBHA];
      selectedClusters.value[ClusterTypes.TENDBHA] = clustersArr.filter(item => item.master_domain !== domain);
    }
    dataList.splice(index, 1);
    tableData.value = dataList;
  };

  const handleSubmit = () => {
    isSubmitting.value = true;
    Promise.all(rowRefs.value.map((item: { getValue: () => Promise<any> }) => item.getValue()))
      .then((data) =>
        createTicket({
          ticket_type: 'MYSQL_ROLLBACK_CLUSTER',
          remark: '',
          details: {
            infos: data,
          },
          bk_biz_id: currentBizId,
        }).then((data) => {
          window.changeConfirm = false;
          router.push({
            name: 'MySQLDBRollback',
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
    selectedClusters.value[ClusterTypes.TENDBHA] = [];
    domainMemo = {};
    window.changeConfirm = false;
  };
</script>

<style lang="less">
  .rollback-page {
    padding-bottom: 20px;
  }
</style>
