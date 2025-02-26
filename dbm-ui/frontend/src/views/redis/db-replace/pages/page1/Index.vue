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
    <div class="master-slave-cutoff-page">
      <BkAlert
        closable
        theme="info"
        :title="t('整机替换：将原主机上的所有实例搬迁到同等规格的新主机')" />
      <RenderData
        class="mt16"
        @show-master-batch-selector="handleShowMasterBatchSelector">
        <RenderDataRow
          v-for="(item, index) in tableData"
          :key="item.rowKey"
          ref="rowRefs"
          :data="item"
          :inputed-ips="inputedIps"
          :removeable="tableData.length < 2"
          @add="(payload: Array<IDataRow>) => handleAppend(index, payload)"
          @on-ip-input-finish="(ip: string) => handleChangeHostIp(index, ip)"
          @remove="handleRemove(index)" />
      </RenderData>
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
    <InstanceSelector
      v-model:is-show="isShowMasterInstanceSelector"
      active-tab="idleHosts"
      db-type="redis"
      :panel-list="['idleHosts', 'manualInput']"
      role="ip"
      :selected="selected"
      @change="handelMasterProxyChange" />
  </SmartAction>
</template>

<script setup lang="tsx">
  import { InfoBox } from 'bkui-vue';
  import { useI18n } from 'vue-i18n';
  import { useRouter } from 'vue-router';

  import {
    queryInfoByIp,
    queryMasterSlavePairs,
  } from '@services/source/redisToolbox';
  import { createTicket } from '@services/source/ticket';
  import type { SubmitTicket } from '@services/types/ticket';

  import { useTicketCloneInfo } from '@hooks';

  import { useGlobalBizs } from '@stores';

  import { TicketTypes } from '@common/const';

  import { switchToNormalRole } from '@utils';

  import RenderData from './components/Index.vue';
  import InstanceSelector, {
    type InstanceSelectorValues,
  } from './components/instance-selector/Index.vue';
  import RenderDataRow, {
    createRowData,
    type IDataRow,
  } from './components/Row.vue';

  interface SpecItem {
    ip: string;
    spec_id: number
  }
  interface InfoItem {
    cluster_id: number;
    bk_cloud_id: number;
    cluster_domain: string;
    proxy: SpecItem[];
    redis_master: SpecItem[];
    redis_slave: SpecItem[];
  }

  const { currentBizId } = useGlobalBizs();
  const { t } = useI18n();
  const router = useRouter();

  // 单据克隆
  useTicketCloneInfo({
    type: TicketTypes.REDIS_CLUSTER_CUTOFF,
    onSuccess(cloneData) {
      tableData.value = cloneData;
      sortTableByCluster();
      updateSlaveMasterMap();
      window.changeConfirm = true;
    }
  });

  const rowRefs = ref();
  const isShowMasterInstanceSelector = ref(false);
  const isSubmitting  = ref(false);

  const tableData = ref([createRowData()]);
  const selected = shallowRef({
    idleHosts: [],
  } as InstanceSelectorValues);
  const totalNum = computed(() => tableData.value.filter(item => Boolean(item.ip)).length);
  const inputedIps = computed(() => tableData.value.map(item => item.ip));

  // slave <-> master
  const slaveMasterMap: Record<string, string> = {};

  // 检测列表是否为空
  const checkListEmpty = (list: Array<IDataRow>) => {
    if (list.length === 0) {
      return true;
    }
    if (list.length > 1) {
      return false;
    }
    const [firstRow] = list;
    return !firstRow.ip;
  };

  // 更新slave -> master 映射表
  const updateSlaveMasterMap = async () => {
    const clusterIds = [...new Set(tableData.value.map(item => item.clusterId))];
    const retArr = await Promise.all(clusterIds.map(id => queryMasterSlavePairs({
      cluster_id: id,
    }).catch(() => null)));
    retArr.forEach((pairs) => {
      if (pairs !== null) {
        pairs.forEach((item) => {
          slaveMasterMap[item.slave_ip] = item.master_ip;
          slaveMasterMap[item.master_ip] = item.slave_ip;
        });
      }
    });
  };

  // Master 批量选择
  const handleShowMasterBatchSelector = () => {
    isShowMasterInstanceSelector.value = true;
  };

  // ip 是否已存在表格的映射表
  let ipMemo = {} as Record<string, boolean>;

  // 批量选择
  const handelMasterProxyChange = (data: InstanceSelectorValues) => {
    selected.value = data;
    const newList: IDataRow[] = [];
    data.idleHosts.forEach((item) => {
      const { ip } = item;
      if (!ipMemo[ip]) {
        newList.push({
          rowKey: ip,
          isLoading: false,
          ip,
          role: item.role,
          clusterId: item.cluster_id,
          bkCloudId: item.bk_cloud_id,
          cluster: {
            domain: item.cluster_domain,
            isStart: false,
            isGeneral: true,
            rowSpan: 1,
          },
          spec: item.spec_config,
        });
        ipMemo[ip] = true;
      }
    });
    if (checkListEmpty(tableData.value)) {
      tableData.value = newList;
    } else {
      tableData.value = [...tableData.value, ...newList];
    }
    sortTableByCluster();
    updateSlaveMasterMap();
    window.changeConfirm = true;
  };

  // 输入IP后查询详细信息
  const handleChangeHostIp = async (index: number, ip: string) => {
    if (!ip) {
      const { ip } = tableData.value[index];
      ipMemo[ip] = false;
      tableData.value[index].ip = '';
      return;
    }
    tableData.value[index].isLoading = true;
    tableData.value[index].ip = ip;
    const ret = await queryInfoByIp({ ips: [ip] }).finally(() => {
      tableData.value[index].isLoading = false;
    });
    const data = ret[0];
    const obj = {
      rowKey: tableData.value[index].rowKey,
      isLoading: false,
      ip,
      role: switchToNormalRole(data.role),
      clusterId: data.cluster.id,
      bkCloudId: data.cluster.bk_cloud_id,
      cluster: {
        domain: data.cluster?.immute_domain,
        isStart: false,
        isGeneral: true,
        rowSpan: 1,
      },
      spec: data.spec_config,
    };
    tableData.value[index] = obj;
    ipMemo[ip]  = true;
    sortTableByCluster();
    updateSlaveMasterMap();
    selected.value.idleHosts.push(Object.assign(data, {
      cluster_id: obj.clusterId,
      cluster_domain: data.cluster?.immute_domain,
    }));
  };

  // 追加一个集群
  const handleAppend = (index: number, appendList: Array<IDataRow>) => {
    tableData.value.splice(index + 1, 0, ...appendList);
    sortTableByCluster();
  };

  // 删除一个集群
  const handleRemove = (index: number) => {
    const removeItem = tableData.value[index];
    const removeIp = removeItem.ip;
    tableData.value.splice(index, 1);
    delete ipMemo[removeIp];
    let masterIp = '';
    // slave 与 master 删除联动
    if (removeItem.role === 'slave') {
      masterIp = slaveMasterMap[removeItem.ip];
      if (masterIp) {
        // 看看表中有没有对应的master
        let masterIndex = -1;
        for (let i = 0; i < tableData.value.length; i++) {
          if (tableData.value[i].ip === masterIp) {
            masterIndex = i;
            break;
          }
        }
        if (masterIndex !== -1) {
          // 表格中存在master记录
          tableData.value.splice(masterIndex, 1);
          delete ipMemo[masterIp];
        }
      }
    }
    sortTableByCluster();
    const ipsArr = selected.value.idleHosts;
    selected.value.idleHosts = ipsArr.filter(item => ![removeIp, masterIp].includes(item.ip));
    if (tableData.value.length === 0) {
      tableData.value = [createRowData()];
      return;
    }
  };

  // 根据表格数据生成提交单据请求参数
  const generateRequestParam = () => {
    const clusterMap: Record<string, IDataRow[]> = {};
    const clusterIds = new Set<number>();
    tableData.value.forEach((item) => {
      if (item.ip) {
        clusterIds.add(item.clusterId);
        const clusterName = item.cluster.domain;
        if (!clusterMap[clusterName]) {
          clusterMap[clusterName] = [item];
        } else {
          clusterMap[clusterName].push(item);
        }
      }
    });
    const domains = Object.keys(clusterMap);
    const infos = domains.map((domain) => {
      const sameArr = clusterMap[domain];
      const infoItem: InfoItem = {
        cluster_domain: domain,
        cluster_id: sameArr[0].clusterId,
        bk_cloud_id: sameArr[0].bkCloudId,
        proxy: [],
        redis_master: [],
        redis_slave: [],
      };
      const needDeleteSlaves: string[] = [];
      sameArr.forEach((item) => {
        const specObj = {
          ip: item.ip,
          spec_id: item.spec?.id ?? 0,
        };
        if (item.role === 'slave') {
          infoItem.redis_slave.push(specObj);
        } else if (item.role === 'master') {
          infoItem.redis_master.push(specObj);
          const deleteSlaveIp = slaveMasterMap[item.ip];
          if (deleteSlaveIp) needDeleteSlaves.push(deleteSlaveIp);
        } else {
          infoItem.proxy.push(specObj);
        }
      });
      // 当选择了master的时候，对应的slave不要传给后端
      infoItem.redis_slave = infoItem.redis_slave.filter(item => !needDeleteSlaves.includes(item.ip));
      return infoItem;
    });
    return infos;
  };

  // 提交
  const handleSubmit = async () => {
    await Promise.all(rowRefs.value.map((item: {
      getValue: () => void
    }) => item.getValue()));
    const infos = generateRequestParam();
    const params: SubmitTicket<TicketTypes, InfoItem[]> = {
      bk_biz_id: currentBizId,
      ticket_type: TicketTypes.REDIS_CLUSTER_CUTOFF,
      details: {
        ip_source: 'resource_pool',
        infos,
      },
    };
    InfoBox({
      title: t('确认整机替换n台主机？', { n: totalNum.value }),
      subTitle: t('替换后所有的数据将会迁移到新的主机上，请谨慎操作！'),
      width: 480,
      onConfirm: () => {
        isSubmitting.value = true;
        createTicket(params).then((data) => {
          window.changeConfirm = false;
          router.push({
            name: 'RedisDBReplace',
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
      } });
  };

  // 重置
  const handleReset = () => {
    tableData.value = [createRowData()];
    selected.value.idleHosts = [];
    ipMemo = {};
    window.changeConfirm = false;
  };

  // 表格排序，方便合并集群显示
  const sortTableByCluster = () => {
    const arr = tableData.value;
    const clusterMap: Record<string, IDataRow[]> = {};
    arr.forEach((item) => {
      const { domain } = item.cluster;
      if (!clusterMap[domain]) {
        clusterMap[domain] = [item];
      } else {
        clusterMap[domain].push(item);
      }
    });
    const keys = Object.keys(clusterMap);
    const retArr = [];
    for (const key of keys) {
      const sameArr = clusterMap[key];
      let isFirst = true;
      let isGeneral = true;
      if (sameArr.length > 1) {
        isGeneral  = false;
      }
      for (const item of sameArr) {
        if (isFirst) {
          item.cluster.isStart = true;
          item.cluster.rowSpan = sameArr.length;
          isFirst = false;
        } else {
          item.cluster.isStart = false;
        }
        item.cluster.isGeneral = isGeneral;
        retArr.push(item);
      }
    }
    tableData.value = retArr;
  };
</script>

<style lang="less" scoped>
  .master-slave-cutoff-page {
    padding-bottom: 20px;

    .page-action-box {
      display: flex;
      align-items: center;
      margin-top: 16px;
    }
  }
</style>
