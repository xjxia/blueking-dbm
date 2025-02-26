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
  <SmartAction
    class="apply-es-page"
    :offset-target="getSmartActionOffsetTarget">
    <DbForm
      ref="formRef"
      auto-label-width
      :model="formData"
      :rules="rules"
      style="margin-bottom: 16px">
      <DbCard :title="t('业务信息')">
        <BusinessItems
          v-model:app-abbr="formData.details.db_app_abbr"
          v-model:biz-id="formData.bk_biz_id"
          perrmision-action-id="es_apply"
          @change-biz="handleChangeBiz" />
        <ClusterName v-model="formData.details.cluster_name" />
        <ClusterAlias
          v-model="formData.details.cluster_alias"
          :biz-id="formData.bk_biz_id"
          cluster-type="es" />
        <CloudItem
          v-model="formData.details.bk_cloud_id"
          @change="handleChangeCloud" />
      </DbCard>
      <RegionItem
        ref="regionItemRef"
        v-model="formData.details.city_code" />
      <!-- <DbCard
        v-if="!isDefaultCity"
        :title="t('数据库部署信息')">
        <AffinityItem v-model="formData.details.disaster_tolerance_level" />
      </DbCard> -->
      <DbCard :title="t('部署需求')">
        <BkFormItem
          :label="t('ES版本')"
          property="details.db_version"
          required>
          <DeployVersion
            v-model="formData.details.db_version"
            db-type="es"
            query-key="es" />
        </BkFormItem>
        <BkFormItem
          :label="t('服务器选择')"
          property="details.ip_source"
          required>
          <BkRadioGroup v-model="formData.details.ip_source">
            <BkRadioButton label="resource_pool">
              {{ t('自动从资源池匹配') }}
            </BkRadioButton>
            <BkRadioButton label="manual_input">
              {{ t('业务空闲机') }}
            </BkRadioButton>
          </BkRadioGroup>
        </BkFormItem>
        <Transition
          mode="out-in"
          name="dbm-fade">
          <div
            v-if="formData.details.ip_source === 'manual_input'"
            class="mb-24">
            <DbFormItem
              :label="t('Master节点')"
              property="details.nodes.master"
              required>
              <div>
                <IpSelector
                  :biz-id="formData.bk_biz_id"
                  :cloud-info="cloudInfo"
                  :data="formData.details.nodes.master"
                  :disable-dialog-submit-method="masterDisableDialogSubmitMethod"
                  :disable-host-method="masterDisableHostMethod"
                  :os-types="[OSTypes.Linux]"
                  required
                  :show-view="false"
                  style="display: inline-block"
                  @change="handleMasterIpListChange">
                  <template #submitTips="{ hostList }">
                    <I18nT
                      keypath="至少n台_已选n台"
                      style="font-size: 14px; color: #63656e"
                      tag="span">
                      <span style="font-weight: bold; color: #2dcb56"> 3 </span>
                      <span style="font-weight: bold; color: #3a84ff"> {{ hostList.length }} </span>
                    </I18nT>
                  </template>
                  <template #desc>
                    {{ t('至少3台_且为奇数_建议规格至少2核4G') }}
                  </template>
                </IpSelector>
              </div>
              <RenderHostTable
                v-model:data="formData.details.nodes.master"
                :biz-id="formData.bk_biz_id" />
            </DbFormItem>
            <DbFormItem
              :label="t('Client节点')"
              property="details.nodes.client">
              <IpSelector
                :biz-id="formData.bk_biz_id"
                :cloud-info="cloudInfo"
                :data="formData.details.nodes.client"
                :disable-host-method="clientDisableHostMethod"
                :os-types="[OSTypes.Linux]"
                :show-view="false"
                @change="handleClientIpListChange" />
              <RenderHostTable
                v-model:data="formData.details.nodes.client"
                :biz-id="formData.bk_biz_id" />
            </DbFormItem>
            <BkFormItem label=" ">
              <BkAlert
                style="width: 655px"
                :theme="tipTheme"
                :title="t('请确保冷节点和热节点的总数至少为一台')" />
            </BkFormItem>
            <DbFormItem
              :label="t('热节点')"
              property="details.nodes.hot">
              <IpSelector
                :biz-id="formData.bk_biz_id"
                :cloud-info="cloudInfo"
                :data="formData.details.nodes.hot"
                :disable-host-method="hotDisableHostMethod"
                :os-types="[OSTypes.Linux]"
                :show-view="false"
                @change="handleHotIpListChange" />
              <WithInstanceHostTable
                v-model:data="formData.details.nodes.hot"
                :biz-id="formData.bk_biz_id" />
            </DbFormItem>
            <DbFormItem
              :label="t('冷节点')"
              property="details.nodes.cold">
              <IpSelector
                :biz-id="formData.bk_biz_id"
                :cloud-info="cloudInfo"
                :data="formData.details.nodes.cold"
                :disable-host-method="coldDisableHostMethod"
                :os-types="[OSTypes.Linux]"
                :show-view="false"
                @change="handleColdIpListChange" />
              <WithInstanceHostTable
                v-model:data="formData.details.nodes.cold"
                :biz-id="formData.bk_biz_id" />
            </DbFormItem>
          </div>
          <div
            v-else
            class="mb-24">
            <BkFormItem
              :label="t('Master节点')"
              required>
              <div class="resource-pool-item">
                <BkFormItem
                  :label="t('规格')"
                  property="details.resource_spec.master.spec_id"
                  required>
                  <SpecSelector
                    ref="specMasterRef"
                    v-model="formData.details.resource_spec.master.spec_id"
                    :biz-id="formData.bk_biz_id"
                    :cloud-id="formData.details.bk_cloud_id"
                    cluster-type="es"
                    machine-type="es_master" />
                </BkFormItem>
                <BkFormItem
                  :label="t('数量')"
                  property="details.resource_spec.master.count"
                  required>
                  <BkInput
                    v-model="formData.details.resource_spec.master.count"
                    :min="3"
                    type="number" />
                  <span class="input-desc">{{ t('至少3台_且为奇数') }}</span>
                </BkFormItem>
              </div>
            </BkFormItem>
            <BkFormItem :label="t('Client节点')">
              <div class="resource-pool-item">
                <BkFormItem
                  :label="t('规格')"
                  property="details.resource_spec.client.spec_id">
                  <SpecSelector
                    ref="specClientRef"
                    v-model="formData.details.resource_spec.client.spec_id"
                    :biz-id="formData.bk_biz_id"
                    :cloud-id="formData.details.bk_cloud_id"
                    cluster-type="es"
                    machine-type="es_client" />
                </BkFormItem>
                <BkFormItem
                  :label="t('数量')"
                  property="details.resource_spec.client.count">
                  <div style="display: flex; align-items: center">
                    <span style="flex-shrink: 0">
                      <BkInput
                        v-model="formData.details.resource_spec.client.count"
                        :min="0"
                        type="number" />
                    </span>
                  </div>
                </BkFormItem>
              </div>
            </BkFormItem>
            <BkFormItem label=" ">
              <BkAlert
                style="width: 655px"
                :theme="tipTheme"
                :title="t('请确保冷节点和热节点的总数至少为一台')" />
            </BkFormItem>
            <BkFormItem :label="t('热节点')">
              <div class="resource-pool-item">
                <BkFormItem
                  :label="t('规格')"
                  property="details.resource_spec.hot.spec_id"
                  required>
                  <SpecSelector
                    ref="specHotRef"
                    v-model="formData.details.resource_spec.hot.spec_id"
                    :biz-id="formData.bk_biz_id"
                    :cloud-id="formData.details.bk_cloud_id"
                    cluster-type="es"
                    machine-type="es_datanode" />
                </BkFormItem>
                <BkFormItem
                  :label="t('数量')"
                  property="details.resource_spec.hot.count"
                  required>
                  <BkInput
                    v-model="formData.details.resource_spec.hot.count"
                    :min="0"
                    type="number" />
                </BkFormItem>
              </div>
            </BkFormItem>
            <BkFormItem :label="t('冷节点')">
              <div class="resource-pool-item">
                <BkFormItem
                  :label="t('规格')"
                  property="details.resource_spec.cold.spec_id">
                  <SpecSelector
                    ref="specColdRef"
                    v-model="formData.details.resource_spec.cold.spec_id"
                    :biz-id="formData.bk_biz_id"
                    :cloud-id="formData.details.bk_cloud_id"
                    cluster-type="es"
                    machine-type="es_datanode" />
                </BkFormItem>
                <BkFormItem
                  :label="t('数量')"
                  property="details.resource_spec.cold.count">
                  <BkInput
                    v-model="formData.details.resource_spec.cold.count"
                    :min="0"
                    type="number" />
                </BkFormItem>
              </div>
            </BkFormItem>
            <BkFormItem :label="t('总容量')">
              <BkInput
                disabled
                :model-value="totalCapacity"
                style="width: 184px" />
              <span class="input-desc">G</span>
            </BkFormItem>
          </div>
        </Transition>
        <BkFormItem
          :label="t('访问端口')"
          property="details.http_port"
          required>
          <BkInput
            v-model="formData.details.http_port"
            clearable
            :min="1"
            show-clear-only-hover
            style="width: 185px"
            type="number" />
        </BkFormItem>
        <BkFormItem :label="t('备注')">
          <BkInput
            v-model="formData.remark"
            :maxlength="100"
            :placeholder="t('请提供更多有用信息申请信息_以获得更快审批')"
            style="width: 655px"
            type="textarea" />
        </BkFormItem>
      </DbCard>
    </DbForm>
    <template #action>
      <div>
        <BkButton
          :loading="baseState.isSubmitting"
          style="width: 88px"
          theme="primary"
          @click="handleSubmit">
          {{ t('提交') }}
        </BkButton>
        <BkButton
          class="ml8 w-88"
          :disabled="baseState.isSubmitting"
          @click="handleReset">
          {{ t('重置') }}
        </BkButton>
        <BkButton
          class="ml8 w-88"
          :disabled="baseState.isSubmitting"
          @click="handleCancel">
          {{ t('取消') }}
        </BkButton>
      </div>
    </template>
  </SmartAction>
</template>
<script setup lang="ts">
  import InfoBox from 'bkui-vue/lib/info-box';
  import _ from 'lodash';
  import { useI18n } from 'vue-i18n';
  import {
    useRoute,
    useRouter,
  } from 'vue-router';

  import type {
    BizItem,
    HostDetails,
  } from '@services/types';

  import { useApplyBase  } from '@hooks';

  import { OSTypes } from '@common/const';

  // import AffinityItem from '@components/apply-items/AffinityItem.vue';
  import BusinessItems from '@components/apply-items/BusinessItems.vue';
  import CloudItem from '@components/apply-items/CloudItem.vue';
  import ClusterAlias from '@components/apply-items/ClusterAlias.vue';
  import ClusterName from '@components/apply-items/ClusterName.vue';
  import DeployVersion from '@components/apply-items/DeployVersion.vue';
  import RegionItem from '@components/apply-items/RegionItem.vue';
  import SpecSelector from '@components/apply-items/SpecSelector.vue';
  import WithInstanceHostTable, {
    type IHostTableDataWithInstance,
  } from '@components/cluster-common/big-data-host-table/es-host-table/index.vue';
  import RenderHostTable, {
    type IHostTableData,
  } from '@components/cluster-common/big-data-host-table/RenderHostTable.vue';
  import IpSelector from '@components/ip-selector/IpSelector.vue';

  const route = useRoute();
  const router = useRouter();
  const { t } = useI18n();

  const makeMapByHostId = (hostList: HostDetails[]) =>  hostList.reduce((result, item) => ({
    ...result,
    [item.host_id]: true,
  }), {} as Record<number, boolean>);

  const genDefaultFormData = () => ({
    bk_biz_id: '' as number | '',
    remark: '',
    ticket_type: 'ES_APPLY',
    details: {
      bk_cloud_id: 0,
      db_app_abbr: '',
      cluster_name: '',
      cluster_alias: '',
      city_code: '',
      db_version: '',
      ip_source: 'resource_pool',
      disaster_tolerance_level: 'NONE', // 同 affinity
      nodes: {
        master: [] as Array<IHostTableData>,
        client: [] as Array<IHostTableData>,
        hot: [] as Array<IHostTableDataWithInstance>,
        cold: [] as Array<IHostTableDataWithInstance>,
      },
      resource_spec: {
        master: {
          spec_id: '',
          count: 3,
        },
        client: {
          spec_id: '',
          count: 0,
        },
        hot: {
          spec_id: '',
          count: 0,
        },
        cold: {
          spec_id: '',
          count: 0,
        },
      },
      http_port: 9200,
    },
  });

  const formatIpDataWidthInstance = (data: HostDetails[]) => data.map(item => ({
    instance_num: 1,
    ...item,
  }));


  const formRef = ref();
  const specMasterRef = ref();
  const specClientRef = ref();
  const specHotRef = ref();
  const specColdRef = ref();
  const regionItemRef = ref();

  const formData = reactive(genDefaultFormData());

  const totalCapacity = ref(0);

  const cloudInfo = reactive({
    id: '' as number | string,
    name: '',
  });
  const isClickSubmit = ref(false);

  const tipTheme = computed(() => {
    if (isClickSubmit.value === false) {
      return 'info';
    };

    const {
      hot,
      cold,
    } = formData.details.resource_spec;

    const {
      hot: hotNodes,
      cold: coldNodes,
    } = formData.details.nodes;
    const isPass = Boolean(hot.spec_id && hot.count) || Boolean(cold.spec_id && cold.count) || hotNodes.length > 0 || coldNodes.length > 0;
    return (isPass ? 'info' : 'danger');
  });

  // const isDefaultCity = computed(() => formData.details.city_code === 'default');

  const rules = {
    'details.nodes.master': [
      {
        validator: (value: Array<any>) => value.length >= 3 && value.length % 2 === 1,
        message: t('Master节点数至少为3台_且为奇数'),
        trigger: 'change',
      },
    ],
    'details.nodes.hot': [
      {
        validator: () => formData.details.nodes.hot.length > 0 || formData.details.nodes.cold.length > 0,
        message: t('请保证冷/热节点至少存在一台'),
        trigger: 'change',
      },
    ],
    'details.nodes.cold': [
      {
        validator: () => formData.details.nodes.hot.length > 0 || formData.details.nodes.cold.length > 0,
        message: t('请保证冷/热节点至少存在一台'),
        trigger: 'change',
      },
    ],
    'details.resource_spec.master.count': [
      {
        validator: (value: number) => value >= 3 && value % 2 === 1,
        message: t('至少3台_且为奇数'),
        trigger: 'change',
      },
    ],
  };

  watch([
    () => formData.details.resource_spec.hot,
    () => formData.details.resource_spec.cold,
  ], () => {
    const hotCount = Number(formData.details.resource_spec.hot.count);
    const coldCount = Number(formData.details.resource_spec.cold.count);
    if (specHotRef.value && specColdRef.value) {
      const { storage_spec: hotStorageSpec = [] } = specHotRef.value.getData();
      const { storage_spec: coldStorageSpec = [] } = specColdRef.value.getData();
      const hotDisk = hotStorageSpec.reduce((total: number, item: { size: number }) => (
        total + Number(item.size || 0)
      ), 0);
      const coldDisk = coldStorageSpec.reduce((total: number, item: { size: number }) => (
        total + Number(item.size || 0)
      ), 0);
      totalCapacity.value = hotDisk * hotCount + coldCount * coldDisk;
    }
  }, { flush: 'post', deep: true });

  const getSmartActionOffsetTarget = () => document.querySelector('.bk-form-content');

  const {
    baseState,
    bizState,
    handleCreateAppAbbr,
    handleCreateTicket,
    handleCancel,
  } = useApplyBase();

  // 切换业务，需要重置 IP 相关的选择
  function handleChangeBiz(info: BizItem) {
    bizState.info = info;
    bizState.hasEnglishName = !!info.english_name;

    formData.details.nodes.hot = [];
    formData.details.nodes.cold = [];
    formData.details.nodes.client = [];
    formData.details.nodes.master = [];
  }

  /**
   * 变更所属管控区域
   */
  function handleChangeCloud(info: {id: number | string, name: string}) {
    cloudInfo.id = info.id;
    cloudInfo.name = info.name;

    formData.details.nodes.hot = [];
    formData.details.nodes.cold = [];
    formData.details.nodes.client = [];
    formData.details.nodes.master = [];
  }

  // master、client、热节点、冷节点互斥
  const masterDisableHostMethod = (data: any) => {
    const clientHostMap = makeMapByHostId(formData.details.nodes.client);
    if (clientHostMap[data.host_id]) {
      return t('主机已被client节点使用');
    }
    const hotHostMap = makeMapByHostId(formData.details.nodes.hot);
    if (hotHostMap[data.host_id]) {
      return t('主机已被热节点使用');
    }
    const coldHostMap = makeMapByHostId(formData.details.nodes.cold);
    if (coldHostMap[data.host_id]) {
      return t('主机已被冷节点使用');
    }

    return false;
  };

  // master、client、热节点、冷节点互斥
  const clientDisableHostMethod = (data: any) => {
    const masterHostMap = makeMapByHostId(formData.details.nodes.master);
    if (masterHostMap[data.host_id]) {
      return t('主机已被Master节点使用');
    }
    const hotHostMap = makeMapByHostId(formData.details.nodes.hot);
    if (hotHostMap[data.host_id]) {
      return t('主机已被热节点使用');
    }
    const coldHostMap = makeMapByHostId(formData.details.nodes.cold);
    if (coldHostMap[data.host_id]) {
      return t('主机已被冷节点使用');
    }

    return false;
  };

  // master、client、热节点、冷节点互斥
  const hotDisableHostMethod = (data: any) => {
    const masterHostMap = makeMapByHostId(formData.details.nodes.master);
    if (masterHostMap[data.host_id]) {
      return t('主机已被Master节点使用');
    }
    const clientHostMap = makeMapByHostId(formData.details.nodes.client);
    if (clientHostMap[data.host_id]) {
      return t('主机已被client节点使用');
    }
    const coldHostMap = makeMapByHostId(formData.details.nodes.cold);
    if (coldHostMap[data.host_id]) {
      return t('主机已被冷节点使用');
    }

    return false;
  };

  // master、client、热节点、冷节点互斥
  const coldDisableHostMethod = (data: any) => {
    const masterHostMap = makeMapByHostId(formData.details.nodes.master);
    if (masterHostMap[data.host_id]) {
      return t('主机已被Master节点使用');
    }
    const clientHostMap = makeMapByHostId(formData.details.nodes.client);
    if (clientHostMap[data.host_id]) {
      return t('主机已被client节点使用');
    }
    const hotHostMap = makeMapByHostId(formData.details.nodes.hot);
    if (hotHostMap[data.host_id]) {
      return t('主机已被热节点使用');
    }
    return false;
  };

  // master 节点 IP 选择器提交
  const masterDisableDialogSubmitMethod = (hostList: Array<any>) => (hostList.length >= 3 ? false : t('至少n台', { n: 3 }));
  // 更新 master 节点
  const handleMasterIpListChange = (data: HostDetails[]) => {
    formData.details.nodes.master = data;
  };
  // 更新 client 节点IP
  const handleClientIpListChange = (data: HostDetails[]) => {
    formData.details.nodes.client = data;
  };
  // 更新热节点IP
  const handleHotIpListChange = (data: HostDetails[]) => {
    formData.details.nodes.hot = formatIpDataWidthInstance(data);
  };
  // 更新冷节点IP
  const handleColdIpListChange = (data: HostDetails[]) => {
    formData.details.nodes.cold = formatIpDataWidthInstance(data);
  };

  // 提交
  const handleSubmit = () => {
    isClickSubmit.value = true;
    formRef.value.validate()
      .then(() => {
        if (tipTheme.value === 'danger' && formData.details.ip_source === 'resource_pool') {
          return Promise.reject(t('请确保冷节点和热节点的总数至少为一台'));
        }
        baseState.isSubmitting = true;

        const mapIpField = (ipList: Array<IHostTableData>) => ipList.map(item => ({
          bk_host_id: item.host_id,
          ip: item.ip,
          bk_cloud_id: item.cloud_area.id,
          bk_biz_id: item.biz.id,
        }));
        const mapIpFieldWithInstance = (ipList: Array<IHostTableDataWithInstance>) => ipList.map(item => ({
          bk_host_id: item.host_id,
          ip: item.ip,
          bk_cloud_id: item.cloud_area.id,
          instance_num: item.instance_num,
          bk_biz_id: item.biz.id,
        }));

        const getDetails = () => {
          const details: Record<string, any> = _.cloneDeep(formData.details);
          const { cityCode } = regionItemRef.value.getValue();

          if (formData.details.ip_source === 'resource_pool') {
            delete details.nodes;

            const regionAndDisasterParams = {
              affinity: details.disaster_tolerance_level,
              location_spec: {
                city: cityCode,
                sub_zone_ids: [],
              },
            };

            const result: Record<string, any> = {
              ...details,
              resource_spec: {
                master: {
                  ...details.resource_spec.master,
                  ...specMasterRef.value.getData(),
                  ...regionAndDisasterParams,
                  count: Number(details.resource_spec.master.count),
                },
              },
            };

            const clientCount = Number(details.resource_spec.client.count);
            const hotCount = Number(details.resource_spec.hot.count);
            const coldCount = Number(details.resource_spec.cold.count);
            if (clientCount > 0) {
              result.resource_spec.client = {
                ...details.resource_spec.client,
                ...specClientRef.value.getData(),
                ...regionAndDisasterParams,
                count: clientCount,
              };
            }
            if (hotCount > 0) {
              result.resource_spec.hot = {
                ...details.resource_spec.hot,
                ...specHotRef.value.getData(),
                ...regionAndDisasterParams,
                count: hotCount,
              };
            }
            if (coldCount > 0) {
              result.resource_spec.cold = {
                ...details.resource_spec.cold,
                ...specColdRef.value.getData(),
                ...regionAndDisasterParams,
                count: coldCount,
              };
            }
            return result;
          }

          delete details.resource_spec;
          return {
            ...details,
            nodes: {
              master: mapIpField(formData.details.nodes.master),
              client: mapIpField(formData.details.nodes.client),
              hot: mapIpFieldWithInstance(formData.details.nodes.hot),
              cold: mapIpFieldWithInstance(formData.details.nodes.cold),
            },
          };
        };

        const params = {
          ...formData,
          details: getDetails(),
        };
        // 若业务没有英文名称则先创建业务英文名称再创建单据，否则直接创建单据
        bizState.hasEnglishName ? handleCreateTicket(params) : handleCreateAppAbbr(params);
      });
  };

  // 重置表单
  const handleReset = () => {
    InfoBox({
      title: t('确认重置表单内容'),
      content: t('重置后_将会清空当前填写的内容'),
      onConfirm: () => {
        isClickSubmit.value = false;
        Object.assign(formData, genDefaultFormData());
        formRef.value.clearValidate();
        nextTick(() => {
          window.changeConfirm = false;
        });
        return true;
      },
    });
  };

  defineExpose({
    routerBack() {
      if (!route.query.from) {
        router.back();
        return;
      }
      router.push({
        name: route.query.from as string,
      });
    },
  });
</script>
<style lang="less">
  .apply-es-page {
    display: block;

    .db-card {
      & ~ .db-card {
        margin-top: 20px;
      }
    }

    .bk-radio-group {
      width: 435px;

      .bk-radio-button {
        flex: auto;
      }
    }

    .item-input {
      width: 435px;
    }

    .input-desc {
      padding-left: 12px;
      font-size: 12px;
      line-height: 20px;
      color: #63656e;
    }

    .resource-pool-item {
      width: 655px;
      padding: 24px 0;
      background-color: #f5f7fa;
      border-radius: 2px;

      .bk-form-item {
        .bk-form-label {
          width: 120px !important;
        }

        .bk-form-content {
          margin-left: 120px !important;

          .bk-select,
          .bk-input {
            width: 314px;
          }
        }
      }
    }
  }
</style>
