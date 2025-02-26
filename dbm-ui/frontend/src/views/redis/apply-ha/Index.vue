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
  <SmartAction :offset-target="getSmartActionOffsetTarget">
    <div class="apply-instance">
      <DbForm
        ref="formRef"
        auto-label-width
        class="apply-form mb-16"
        :model="formData">
        <DbCard :title="t('业务信息')">
          <BusinessItems
            v-model:app-abbr="formData.details.db_app_abbr"
            v-model:biz-id="formData.bk_biz_id"
            perrmision-action-id="mongodb_apply"
            @change-biz="handleChangeBiz" />
          <CloudItem
            v-model="formData.details.bk_cloud_id"
            @change="handleChangeCloud" />
        </DbCard>
        <RegionItem
          ref="regionItemRef"
          v-model="formData.details.city_code" />
        <DbCard :title="t('数据库部署信息')">
          <AffinityItem
            v-if="!isAppend"
            v-model="formData.details.disaster_tolerance_level"
            :city-code="formData.details.city_code" />
          <BkFormItem
            :label="t('部署方式')"
            property="details.appendApply"
            required>
            <BkRadioGroup v-model="formData.details.appendApply">
              <BkRadio
                key="new"
                label="new">
                {{ t('全新主机部署') }}
              </BkRadio>
              <BkRadio
                key="append"
                label="append">
                {{ t('已有主从所在主机追加部署') }}
              </BkRadio>
            </BkRadioGroup>
          </BkFormItem>
        </DbCard>
        <DbCard :title="t('部署需求')">
          <BkFormItem
            v-if="!isAppend"
            :label="t('Redis 版本')"
            property="details.db_version"
            required>
            <DeployVersion
              v-model="formData.details.db_version"
              db-type="redis"
              query-key="redis" />
          </BkFormItem>
          <BkFormItem
            :label="t('集群数量')"
            property="details.cluster_count"
            required>
            <BkInput
              v-model="formData.details.cluster_count"
              clearable
              :min="1"
              show-clear-only-hover
              style="width: 185px"
              type="number" />
          </BkFormItem>
          <BkFormItem
            v-if="!isAppend"
            :label="t('每组主机部署集群')"
            property="details.group_count"
            required>
            <BkInput
              v-model="formData.details.group_count"
              clearable
              :min="1"
              show-clear-only-hover
              style="width: 185px"
              type="number" />
          </BkFormItem>
          <BkFormItem
            v-if="!isAppend"
            :label="t('Redis 起始端口')"
            property="details.port"
            required>
            <BkInput
              v-model="formData.details.port"
              :max="65535"
              :min="1025"
              style="width: 185px"
              type="number" />
            <span class="apply-form__tips ml-10">{{
              t('按主机分配（集群实例），系统将从“起始端口”开始自动分配')
            }}</span>
          </BkFormItem>
          <PasswordInput
            v-model="formData.details.redis_pwd"
            property="details.redis_pwd" />
          <BkFormItem
            v-if="!isAppend"
            :label="t('服务器选择')"
            property="details.ip_source"
            required>
            <BkRadioGroup
              v-model="formData.details.ip_source"
              class="item-input">
              <BkRadioButton
                key="resource_pool"
                label="resource_pool">
                {{ t('自动从资源池匹配') }}
              </BkRadioButton>
              <!-- 暂时去掉手动录入IP -->
              <!-- <BkRadioButton
                v-for="item of Object.values(redisIpSources)"
                :key="item.id"
                :label="item.id">
                {{ item.text }}
              </BkRadioButton> -->
            </BkRadioGroup>
          </BkFormItem>
          <BkFormItem
            v-if="!isAppend"
            :label="t('后端存储规格')"
            property="details.resource_spec.spec_id"
            required>
            <SpecSelector
              ref="specRef"
              v-model="formData.details.resource_spec.spec_id"
              :biz-id="formData.bk_biz_id"
              :cloud-id="formData.details.bk_cloud_id"
              :cluster-type="ClusterTypes.REDIS_INSTANCE"
              :machine-type="MachineTypes.TENDISCACHE"
              style="width: 314px" />
          </BkFormItem>
          <BkFormItem
            class="service"
            :label="t('域名设置')"
            required>
            <DomainTable
              v-model:domains="formData.details.infos"
              :app-abbr="formData.details.db_app_abbr"
              :biz-id="formData.bk_biz_id"
              :city-name="cityName"
              :cloud-id="cloudInfo.id"
              :is-append="isAppend"
              :max-memory="maxMemory"
              :port="formData.details.port"
              @host-change="handleHostChange" />
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
    </div>
    <template #action>
      <BkButton
        class="w-88"
        :loading="baseState.isSubmitting"
        theme="primary"
        @click="handleSubmit">
        {{ t('提交') }}
      </BkButton>
      <BkButton
        class="ml-8 w-88"
        :disabled="baseState.isSubmitting"
        @click="handleResetFormdata">
        {{ t('重置') }}
      </BkButton>
      <BkButton
        class="ml-8 w-88"
        :disabled="baseState.isSubmitting"
        @click="handleCancel">
        {{ t('取消') }}
      </BkButton>
    </template>
  </SmartAction>
</template>

<script setup lang="ts">
  import InfoBox from 'bkui-vue/lib/info-box';
  import _ from 'lodash'
  import type { UnwrapRef } from 'vue';
  import { useI18n } from 'vue-i18n';

  import { getRedisMachineList } from '@services/source/redis'
  import { queryMasterSlaveByIp } from '@services/source/redisToolbox';
  import type { BizItem } from '@services/types';

  import {
    useApplyBase,
  } from '@hooks';

  import {
    ClusterTypes,
    MachineTypes,
    TicketTypes,
  } from '@common/const';

  import AffinityItem from '@components/apply-items/AffinityItem.vue';
  import BusinessItems from '@components/apply-items/BusinessItems.vue';
  import CloudItem from '@components/apply-items/CloudItem.vue';
  import DeployVersion from '@components/apply-items/DeployVersion.vue';
  import RegionItem from '@components/apply-items/RegionItem.vue';
  import SpecSelector from '@components/apply-items/SpecSelector.vue';
  import DbForm from '@components/db-form/index.vue';

  import PasswordInput from '@views/redis/common/password-input/Index.vue';

  import DomainTable, { type Domain } from './components/domain-table/Index.vue';

  const initData = () => ({
    bk_biz_id: '' as number | '',
    ticket_type: TicketTypes.REDIS_INS_APPLY,
    remark: '',
    details: {
      db_app_abbr: '',
      bk_cloud_id: 0,
      cluster_type: ClusterTypes.REDIS_INSTANCE,
      db_version: '', // 追加就非必填
      infos: [] as Domain[],
      port: 30000, // 追加就非必填
      redis_pwd: '',
      cluster_count: 1,
      group_count: 1,
      city_code: '', // 追加就非必填
      disaster_tolerance_level: 'SAME_SUBZONE_CROSS_SWTICH',
      appendApply: 'new', // 是否是追加部署
      ip_source: 'resource_pool',
      resource_spec: {
        spec_id: '',
        count: 2,
      },
    },
  });

  const { t } = useI18n();
  const route = useRoute();
  const router = useRouter();
  const {
    baseState,
    bizState,
    handleCancel,
    handleCreateAppAbbr,
    handleCreateTicket,
  } = useApplyBase();

  const formRef = ref<InstanceType<typeof DbForm>>();
  const regionItemRef = ref<InstanceType<typeof RegionItem>>();
  const specRef = ref<InstanceType<typeof SpecSelector>>();
  const cloudInfo = ref({
    id: '' as number | string,
    name: '',
  });
  const maxMemory = ref(0)
  const cityName = ref('')

  const formData = reactive(initData());

  const isAppend = computed(() => formData.details.appendApply === 'append')
  const machineCount = computed(() => formData.details.cluster_count / formData.details.group_count)

  watch(() => formData.details.city_code, () => {
    cityName.value = regionItemRef.value!.getValue().cityName
  })

  watch([() => formData.details.resource_spec.spec_id, machineCount], ([newSpecId]) => {
    nextTick(() => {
      if (newSpecId) {
        const { storage_spec: storageSpec } = specRef.value!.getData()
        const specCapacity = (storageSpec || []).reduce((sizePrev, storageItem) => sizePrev + storageItem.size, 0)
        maxMemory.value = specCapacity * 0.9 * machineCount.value / formData.details.cluster_count * 1024
      } else {
        maxMemory.value = 0
      }
    })
  }, {
    deep: true
  })

  // 设置 domain 数量
  watch(() => formData.details.cluster_count, (count) => {
    if (count > 0 && count <= 200) {
      const len = formData.details.infos.length;
      if (count > len) {
        const appends = Array.from({ length: count - len }, () => ({
          cluster_name: '',
          databases: 2,
          masterHost: {
            ip: '',
            bk_cloud_id: 0,
            bk_host_id: 0
          },
          slaveHost: {
            ip: '',
            bk_cloud_id: 0,
            bk_host_id: 0
          },
        }));
        formData.details.infos.push(...appends);
        return;
      }
      if (count < len) {
        formData.details.infos.splice(count, len - count);
        return;
      }
    }
  }, {
    immediate: true,
  });

  const getSmartActionOffsetTarget = () => document.querySelector('.bk-form-content');

  const handleChangeBiz = (info: BizItem) => {
    bizState.info = info;
    bizState.hasEnglishName = !!info.english_name;
  };

  const handleChangeCloud = (info: {
    id: number | string,
    name: string
  }) => {
    cloudInfo.value = info;
  };

  const handleHostChange = async (filedName: string, value: string, index: number) => {
    await formRef.value!.validate(filedName);
    getRedisMachineList({
      ip: value,
      instance_role: 'redis_master',
      bk_cloud_id: formData.details.bk_cloud_id,
      bk_city_name: cityName.value
    }).then((data) => {
      const redisMachineList = data.results;
      if (redisMachineList.length) {
        const [redisMachineItem] = redisMachineList
        Object.assign(formData.details.infos[index], {
          masterHost: {
            ip: value,
            bk_cloud_id: redisMachineItem.bk_cloud_id,
            bk_host_id: redisMachineItem.bk_host_id
          }
        })
        queryMasterSlaveByIp({ips: [value]}).then(slavaList => {
          if (slavaList.length > 0) {
            const [slavaItem] = slavaList
            const {slave_host_info: slaveHostInfo} = slavaItem
            Object.assign(formData.details.infos[index], {
              slaveHost: {
                ip: slavaItem.slave_ip,
                bk_cloud_id: slaveHostInfo.bk_cloud_id,
                bk_host_id: slaveHostInfo.bk_host_id
              }})
          }
        })
      }
    })
  }

  const handleResetFormdata = () => {
    InfoBox({
      title: t('确认重置表单内容'),
      content: t('重置后_将会清空当前填写的内容'),
      cancelText : t('取消'),
      onConfirm: () => {
        Object.assign(formData, initData());
        nextTick(() => {
          window.changeConfirm = false;
        });
        return true;
      },
    });
  };

  const handleSubmit = async () => {
    await formRef.value!.validate();

    baseState.isSubmitting = true;

    const getDetails = () => {
      const { details } : { details: Partial<UnwrapRef<typeof formData>['details']> } = _.cloneDeep(formData);

      if (details.appendApply === 'new') {
        Object.assign(details, {
          resource_spec: {
            backend_group: {
              count: Math.ceil(machineCount.value),
              spec_id: details.resource_spec!.spec_id,
              ...specRef.value!.getData(),
            },
          },
          infos: details.infos!.map(infoItem => ({
            cluster_name: infoItem.cluster_name,
            databases: infoItem.databases,
          }))
        })
      } else {
        delete details.port
        delete details.city_code
        delete details.db_version
        delete details.resource_spec

        Object.assign(details, {
          infos: details.infos!.map(infoItem => ({
            cluster_name: infoItem.cluster_name,
            databases: infoItem.databases,
            backend_group: {
              master: infoItem.masterHost,
              slave: infoItem.slaveHost
            }
          }))
        })
      }

      delete details.cluster_count
      delete details.group_count
      delete details.appendApply

      return {
        ...details,
        append_apply: isAppend.value,
        ip_source: isAppend.value ? 'manual_input' : 'resource_pool',
      }
    }

    const params = {
      ...formData,
      details: getDetails(),
    };

    // 若业务没有英文名称则先创建业务英文名称再创建单据，反正直接创建单据
    bizState.hasEnglishName ? handleCreateTicket(params) : handleCreateAppAbbr(params);
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

<style lang="less" scoped>
  @import '@styles/applyInstance.less';

  .apply-instance {
    :deep(.item-input) {
      width: 435px;
    }

    .input-desc {
      margin-left: 12px;
      font-size: 12px;
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
