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
    <div class="spider-apply-instance-page">
      <DbForm
        ref="formRef"
        auto-label-width
        :model="formdata"
        :rules="rules">
        <DbCard :title="t('业务信息')">
          <BusinessItems
            v-model:app-abbr="formdata.details.db_app_abbr"
            v-model:biz-id="formdata.bk_biz_id"
            perrmision-action-id="tendbcluster_apply"
            @change-biz="handleChangeBiz" />
          <ClusterName v-model="formdata.details.cluster_name" />
          <ClusterAlias
            v-model="formdata.details.cluster_alias"
            :biz-id="formdata.bk_biz_id"
            cluster-type="tendbcluster" />
          <CloudItem v-model="formdata.details.bk_cloud_id" />
        </DbCard>
        <RegionItem
          ref="regionItemRef"
          v-model="formdata.details.city_code" />
        <DbCard :title="t('数据库部署信息')">
          <AffinityItem
            v-model="formdata.details.resource_spec.backend_group.affinity"
            :city-code="formdata.details.city_code" />
        </DbCard>
        <DbCard :title="t('部署需求')">
          <ModuleItem
            v-model="formdata.details.db_module_id"
            :biz-id="formdata.bk_biz_id" />
          <BkFormItem
            :label="t('接入层Master')"
            required>
            <div class="resource-pool-item">
              <BkFormItem
                :label="t('规格')"
                property="details.resource_spec.spider.spec_id"
                required>
                <SpecSelector
                  ref="specProxyRef"
                  v-model="formdata.details.resource_spec.spider.spec_id"
                  :biz-id="formdata.bk_biz_id"
                  :cloud-id="formdata.details.bk_cloud_id"
                  cluster-type="tendbcluster"
                  machine-type="spider" />
              </BkFormItem>
              <BkFormItem
                :label="t('数量')"
                property="details.resource_spec.spider.count"
                required>
                <BkInput
                  v-model="formdata.details.resource_spec.spider.count"
                  :min="2"
                  type="number" />
                <span class="input-desc">{{ t('至少n台', { n: 2 }) }}</span>
              </BkFormItem>
            </div>
          </BkFormItem>
          <BkFormItem
            :label="t('后端存储规格')"
            required>
            <BackendQPSSpec
              ref="specBackendRef"
              v-model="formdata.details.resource_spec.backend_group"
              :biz-id="formdata.bk_biz_id"
              :cloud-id="formdata.details.bk_cloud_id"
              cluster-type="tendbcluster"
              machine-type="remote" />
          </BkFormItem>
          <BkFormItem
            :label="t('访问端口')"
            property="details.spider_port"
            required>
            <BkInput
              v-model="formdata.details.spider_port"
              clearable
              :max="65535"
              :min="3306"
              style="width: 185px"
              type="number" />
            <span class="input-desc">
              {{ t('范围n_min_max', { n: 3306, min: 25000, max: 65535 }) }}
            </span>
          </BkFormItem>
          <BkFormItem :label="t('备注')">
            <BkInput
              v-model="formdata.remark"
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
  import _ from 'lodash';
  import { useI18n } from 'vue-i18n';
  import { useRoute, useRouter } from 'vue-router';

  import type { BizItem } from '@services/types';

  import { useApplyBase } from '@hooks';

  import { nameRegx } from '@common/regex';

  import AffinityItem from '@components/apply-items/AffinityItem.vue';
  import BackendQPSSpec from '@components/apply-items/BackendQPSSpec.vue';
  import BusinessItems from '@components/apply-items/BusinessItems.vue';
  import CloudItem from '@components/apply-items/CloudItem.vue';
  import ClusterAlias from '@components/apply-items/ClusterAlias.vue';
  import ClusterName from '@components/apply-items/ClusterName.vue';
  import RegionItem from '@components/apply-items/RegionItem.vue';
  import SpecSelector from '@components/apply-items/SpecSelector.vue';

  import ModuleItem from './components/ModuleItem.vue';

  const route = useRoute();
  const router = useRouter();
  const { t } = useI18n();

  const getSmartActionOffsetTarget = () => document.querySelector('.bk-form-content');

  const initData = () => ({
    bk_biz_id: '' as number | '',
    remark: '',
    ticket_type: 'TENDBCLUSTER_APPLY',
    details: {
      bk_cloud_id: 0,
      db_app_abbr: '',
      cluster_name: '',
      cluster_alias: '',
      city_code: '',
      db_module_id: null as null | number,
      cluster_shard_num: 0,
      remote_shard_num: 0,
      disaster_tolerance_level: 'NONE',
      resource_spec: {
        spider: {
          spec_id: '' as number | '',
          count: 2,
        },
        backend_group: {
          spec_id: '' as number | '',
          count: 0,
          capacity: '',
          future_capacity: '',
          affinity: 'NONE',
          location_spec: {
            city: '',
            sub_zone_ids: [],
          },
        },
      },
      spider_port: 25000,
    },
  });

  // 基础设置
  const { baseState, bizState, handleCancel, handleCreateAppAbbr, handleCreateTicket } = useApplyBase();

  const formRef = ref();
  const specProxyRef = ref();
  const specBackendRef = ref<InstanceType<typeof BackendQPSSpec>>();
  const formdata = ref(initData());
  const regionItemRef = ref();

  // const isDefaultCity = computed(() => formdata.value.details.city_code === 'default');

  const rules = {
    'details.cluster_name': [
      {
        message: t('以小写英文字母开头_且只能包含英文字母_数字_连字符'),
        trigger: 'blur',
        validator: (value: string) => nameRegx.test(value),
      },
    ],
    'details.resource_spec.backend_group.count': [
      {
        message: t('数量不能为空'),
        validator: (value: number) => value > 0,
      },
    ],
    'details.spider_port': [
      {
        message: t('范围n_min_max', { n: 3306, min: 25000, max: 65535 }),
        trigger: 'change',
        validator: (value: number) => value === 3306 || (value >= 25000 && value <= 65535),
      },
    ],
  };

  /**
   * 变更业务
   */
  const handleChangeBiz = (info: BizItem) => {
    bizState.info = info;
    bizState.hasEnglishName = !!info.english_name;
  };

  /** 重置表单 */
  const handleResetFormdata = () => {
    InfoBox({
      title: t('确认重置表单内容'),
      content: t('重置后_将会清空当前填写的内容'),
      cancelText: t('取消'),
      onConfirm: () => {
        formdata.value = initData();
        nextTick(() => {
          window.changeConfirm = false;
        });
        return true;
      },
    });
  };

  async function handleSubmit() {
    await formRef.value?.validate();

    baseState.isSubmitting = true;

    const getDetails = () => {
      const details: Record<string, any> = _.cloneDeep(formdata.value.details);
      const { cityCode } = regionItemRef.value.getValue();
      // 集群容量需求不需要提交
      delete details.resource_spec.backend_group.capacity;
      delete details.resource_spec.backend_group.future_capacity;

      const regionAndDisasterParams = {
        affinity: details.resource_spec.backend_group.affinity,
        location_spec: {
          city: cityCode,
          sub_zone_ids: [],
        },
      };

      const specInfo = specBackendRef.value!.getData();
      return {
        ...details,
        cluster_shard_num: Number(specInfo.cluster_shard_num),
        remote_shard_num: specInfo.cluster_shard_num / specInfo.machine_pair,
        disaster_tolerance_level: details.resource_spec.backend_group.affinity,
        resource_spec: {
          spider: {
            ...details.resource_spec.spider,
            ...specProxyRef.value.getData(),
            ...regionAndDisasterParams,
            count: Number(details.resource_spec.spider.count),
          },
          backend_group: {
            ...details.resource_spec.backend_group,
            count: specInfo.machine_pair,
            spec_info: specInfo,
            location_spec: {
              city: cityCode,
              sub_zone_ids: [],
            },
          },
        },
      };
    };
    const params = {
      ...formdata.value,
      details: getDetails(),
    };

    // 若业务没有英文名称则先创建业务英文名称再创建单据，反正直接创建单据
    bizState.hasEnglishName ? handleCreateTicket(params) : handleCreateAppAbbr(params);
  }

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
  @import '@styles/applyInstance.less';

  .spider-apply-instance-page {
    .item-input {
      width: 462px;
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

    .db-card {
      & ~ .db-card {
        margin-top: 20px;
      }
    }
  }
</style>
