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
    v-bkloading="{ loading: isLoading }"
    class="pulsar-detail-page">
    <BkTab
      v-model:active="activePanelKey"
      class="detail-tab"
      type="card-tab">
      <BkTabPanel
        v-if="checkDbConsole('pulsar.clusterManage.clusterTopo')"
        :label="t('集群拓扑')"
        name="topo" />
      <BkTabPanel
        :label="t('节点列表')"
        name="nodeList" />
      <BkTabPanel
        :label="t('基本信息')"
        name="baseInfo" />
      <BkTabPanel
        v-if="checkDbConsole('pulsar.clusterManage.changeLog')"
        :label="t('变更记录')"
        name="record" />
      <BkTabPanel
        v-for="item in monitorPanelList"
        :key="item.name"
        :label="item.label"
        :name="item.name" />
    </BkTab>
    <div class="content-wrapper">
      <ClusterTopo
        v-if="activePanelKey === 'topo'"
        :id="clusterId"
        cluster-type="pulsar"
        db-type="bigdata" />
      <BaseInfo
        v-if="activePanelKey === 'baseInfo' && clusterData"
        :data="clusterData" />
      <NodeList
        v-if="activePanelKey === 'nodeList'"
        :key="clusterId"
        :cluster-id="clusterId" />
      <ClusterEventChange
        v-if="activePanelKey === 'record'"
        :id="clusterId" />
      <MonitorDashboard
        v-if="activePanelKey === activePanel?.name"
        :url="activePanel?.link" />
    </div>
  </div>
</template>
<script setup lang="ts">
  import { ref } from 'vue';
  import { useI18n } from 'vue-i18n';
  import { useRequest } from 'vue-request';

  import { getMonitorUrls } from '@services/source/monitorGrafana';
  import { getPulsarDetail } from '@services/source/pulsar';

  import { useGlobalBizs } from '@stores';

  import { ClusterTypes } from '@common/const';

  import ClusterTopo from '@components/cluster-details/ClusterTopo.vue';
  import ClusterEventChange from '@components/cluster-event-change/EventChange.vue';
  import MonitorDashboard from '@components/cluster-monitor/MonitorDashboard.vue';

  import { checkDbConsole } from '@utils';

  import BaseInfo from './components/BaseInfo.vue';
  import NodeList from './components/node-list/Index.vue';

  interface Props {
    clusterId: number;
  }

  interface PanelItem {
    label: string;
    name: string;
    link: string;
  }

  const props = defineProps<Props>();

  const { t } = useI18n();
  const { currentBizId } = useGlobalBizs();

  const activePanelKey = ref('topo');
  const monitorPanelList = ref<PanelItem[]>([]);

  const activePanel = computed(() => {
    const targetPanel = monitorPanelList.value.find((item) => item.name === activePanelKey.value);
    return targetPanel;
  });

  const {
    loading: isLoading,
    data: clusterData,
    run: fetchResourceDetails,
  } = useRequest(getPulsarDetail, {
    manual: true,
  });

  const { run: runGetMonitorUrls } = useRequest(getMonitorUrls, {
    manual: true,
    onSuccess(res) {
      if (res.urls.length > 0) {
        monitorPanelList.value = res.urls.map((item) => ({
          label: item.view,
          name: item.view,
          link: item.url,
        }));
      }
    },
  });

  watch(
    () => props.clusterId,
    () => {
      if (props.clusterId) {
        fetchResourceDetails({
          id: props.clusterId,
        });
        runGetMonitorUrls({
          bk_biz_id: currentBizId,
          cluster_type: ClusterTypes.PULSAR,
          cluster_id: props.clusterId,
        });
      }
    },
    {
      immediate: true,
    },
  );
</script>
<style lang="less">
  .pulsar-detail-page {
    height: 100%;
    background: #fff;

    .detail-tab {
      .bk-tab-content {
        padding: 0;
      }
    }

    .content-wrapper {
      height: calc(100vh - 168px);
      padding: 0 24px;
      overflow: auto;
    }
  }
</style>
