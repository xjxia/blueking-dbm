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
    <div class="version-upgrade-page">
      <BkAlert
        closable
        theme="info"
        :title="t('版本升级：将集群的接入层或存储层，更新到指定版本')" />
      <RenderData
        class="mt16"
        @show-batch-selector="handleShowBatchSelector">
        <RenderDataRow
          v-for="(item, index) in tableData"
          :key="item.rowKey"
          ref="rowRefs"
          :data="item"
          :inputed-clusters="inputedClusters"
          :removeable="tableData.length < 2"
          @add="(payload: Array<IDataRow>) => handleAppend(index, payload)"
          @cluster-input-finish="(rowInfo: RedisModel) => handleChangeCluster(index, rowInfo)"
          @node-type-change="(type: string) => handleNodeTypeChange(index, type)"
          @remove="handleRemove(index)" />
      </RenderData>
      <ClusterSelector
        v-model:is-show="isShowClusterSelector"
        :cluster-types="[ClusterTypes.REDIS]"
        :selected="selectedClusters"
        @change="handelClusterChange" />
    </div>
    <template #action>
      <BkButton
        class="w-88"
        :disabled="totalNum === 0"
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
          class="ml-8 w-88"
          :disabled="isSubmitting">
          {{ t('重置') }}
        </BkButton>
      </DbPopconfirm>
    </template>
  </SmartAction>
</template>

<script setup lang="tsx">
  import { InfoBox } from 'bkui-vue';
  import { useI18n } from 'vue-i18n';
  import { useRouter } from 'vue-router';

  import RedisModel from '@services/model/redis/redis';
  import { createTicket } from '@services/source/ticket';

  import { useGlobalBizs } from '@stores';

  import { ClusterTypes, TicketTypes } from '@common/const';

  import ClusterSelector from '@components/cluster-selector/Index.vue';

  import RenderData from './components/Index.vue';
  import RenderDataRow, {
    createRowData,
    type IDataRow,
    type InfoItem,
  } from './components/Row.vue';

  const { currentBizId } = useGlobalBizs();
  const { t } = useI18n();
  const router = useRouter();

  const rowRefs = ref();
  const isShowClusterSelector = ref(false);
  const isSubmitting = ref(false);
  const tableData = ref([createRowData()]);
  const remark = ref('');

  const selectedClusters = shallowRef<{ [key: string]: Array<RedisModel> }>({ [ClusterTypes.REDIS]: [] });

  const totalNum = computed(() => tableData.value.filter((item) => Boolean(item.cluster)).length);
  const inputedClusters = computed(() => tableData.value.map((item) => item.cluster));

  // const patchEditVersionListParams = computed(() => {
  //   const tableDataList = tableData.value
  //   const params = {
  //     nodeType: '',
  //     clusterType: '',
  //   }
  //   if (tableDataList.length > 0) {
  //     const clusterTypeList = []
  //     for(let i = 0; i < tableDataList.length; i++) {
  //       const dataItem = tableDataList[i]
  //       if (!dataItem.clusterType) {
  //         continue
  //       }
  //       clusterTypeList.push(dataItem.clusterType)
  //       if (clusterTypeList.length > 1) {
  //         return params
  //       }
  //     }
  //     if (clusterTypeList.length === 1) {
  //       const {clusterType, nodeType} = tableDataList[0]
  //       return {
  //         nodeType,
  //         clusterType,
  //       }
  //     }
  //     return params
  //   }
  //   return params
  // })

  // 集群域名是否已存在表格的映射表
  let domainMemo: Record<string, boolean> = {};

  // 检测列表是否为空
  const checkListEmpty = (list: Array<IDataRow>) => {
    if (list.length > 1) {
      return false;
    }
    const [firstRow] = list;
    return !firstRow.cluster;
  };

  // 批量选择
  const handleShowBatchSelector = () => {
    isShowClusterSelector.value = true;
  };

  const handleNodeTypeChange = (index: number, type: string) => {
    tableData.value[index].nodeType = type;
  };

  // 根据集群选择返回的数据加工成table所需的数据
  const generateRowDateFromRequest = (item: RedisModel) => ({
    rowKey: item.master_domain,
    isLoading: false,
    cluster: item.master_domain,
    clusterId: item.id,
    clusterType: item.cluster_spec.spec_cluster_type,
    nodeType: 'Proxy',
  });

  // 批量选择
  const handelClusterChange = async (selected: { [key: string]: Array<RedisModel> }) => {
    selectedClusters.value = selected;
    const list = selected[ClusterTypes.REDIS];
    const newList: IDataRow[] = [];
    for (const item of list) {
      const domain = item.master_domain;
      if (!domainMemo[domain]) {
        const row = generateRowDateFromRequest(item);
        newList.push(row);
        domainMemo[domain] = true;
      }
    }
    if (checkListEmpty(tableData.value)) {
      tableData.value = newList;
    } else {
      tableData.value = [...tableData.value, ...newList];
    }
    window.changeConfirm = true;
  };

  // 输入集群后查询集群信息并填充到table
  const handleChangeCluster = (index: number, rowInfo: RedisModel) => {
    const domain = rowInfo.master_domain;
    if (!domain) {
      const { cluster } = tableData.value[index];
      domainMemo[cluster] = false;
      tableData.value[index].cluster = '';
      return;
    }

    const row = generateRowDateFromRequest(rowInfo);
    tableData.value[index] = row;
    domainMemo[domain] = true;
    selectedClusters.value[ClusterTypes.REDIS].push(rowInfo);
  };

  // 追加一个集群
  const handleAppend = (index: number, appendList: Array<IDataRow>) => {
    tableData.value.splice(index + 1, 0, ...appendList);
  };

  // 删除一个集群
  const handleRemove = (index: number) => {
    const { cluster } = tableData.value[index];
    tableData.value.splice(index, 1);
    delete domainMemo[cluster];
    const clustersArr = selectedClusters.value[ClusterTypes.REDIS];
    selectedClusters.value[ClusterTypes.REDIS] = clustersArr.filter((item) => item.master_domain !== cluster);
  };

  // 点击提交按钮
  const handleSubmit = async () => {
    const infos = await Promise.all(
      rowRefs.value.map((item: { getValue: () => Promise<InfoItem> }) => item.getValue()),
    );

    const params = {
      bk_biz_id: currentBizId,
      ticket_type: TicketTypes.REDIS_VERSION_UPDATE_ONLINE,
      details: {
        infos,
      },
    };

    InfoBox({
      title: t('确认对n个集群版本升级？', { n: totalNum.value }),
      width: 480,
      onConfirm: () => {
        isSubmitting.value = true;
        createTicket(params)
          .then((data) => {
            window.changeConfirm = false;
            router.push({
              name: 'RedisVersionUpgrade',
              params: {
                page: 'success',
              },
              query: {
                ticketId: data.id,
              },
            });
          })
          .finally(() => {
            isSubmitting.value = false;
          });
      },
    });
  };

  const handleReset = () => {
    tableData.value = [createRowData()];
    remark.value = '';
    selectedClusters.value[ClusterTypes.REDIS] = [];
    domainMemo = {};
    window.changeConfirm = false;
  };
</script>

<style lang="less" scoped>
  .version-upgrade-page {
    padding-bottom: 20px;

    .page-action-box {
      display: flex;
      align-items: center;
      margin-top: 16px;

      .safe-action {
        margin-left: auto;

        .safe-action-text {
          padding-bottom: 2px;
          border-bottom: 1px dashed #979ba5;
        }
      }
    }
  }
</style>
