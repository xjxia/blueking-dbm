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
  <div class="ticket-details__info">
    <strong class="ticket-details__info-title">{{ $t('部署模块') }}</strong>
    <div class="ticket-details__list">
      <div class="ticket-details__item">
        <span class="ticket-details__item-label">{{ $t('所属业务') }}：</span>
        <span class="ticket-details__item-value">{{ ticketDetails?.bk_biz_name || '--' }}</span>
      </div>
      <div class="ticket-details__item">
        <span class="ticket-details__item-label">{{ $t('业务英文名') }}：</span>
        <span class="ticket-details__item-value">{{ ticketDetails?.db_app_abbr || '--' }}</span>
      </div>
      <div class="ticket-details__item">
        <span class="ticket-details__item-label">{{ $t('DB模块名') }}：</span>
        <span class="ticket-details__item-value">{{ ticketDetails?.details?.db_module_name || '--' }}</span>
      </div>
    </div>
  </div>
  <div class="ticket-details__info">
    <strong class="ticket-details__info-title">{{ $t('地域要求') }}</strong>
    <div class="ticket-details__list">
      <div class="ticket-details__item">
        <span class="ticket-details__item-label">{{ $t('数据库部署地域') }}：</span>
        <span class="ticket-details__item-value">{{ cityName }}</span>
      </div>
    </div>
  </div>
  <div class="ticket-details__info">
    <strong class="ticket-details__info-title">{{ $t('数据库部署信息') }}</strong>
    <div class="ticket-details__list">
      <div
        v-if="!isSingleType"
        class="ticket-details__item">
        <span class="ticket-details__item-label">{{ $t('容灾要求') }}：</span>
        <span class="ticket-details__item-value">{{ affinity }}</span>
      </div>
      <div
        v-if="!isSingleType"
        class="ticket-details__item">
        <span class="ticket-details__item-label">{{ $t('Proxy起始端口') }}：</span>
        <span class="ticket-details__item-value">{{ ticketDetails?.details?.start_proxy_port || '--' }}</span>
      </div>
      <div class="ticket-details__item">
        <span class="ticket-details__item-label">{{ $t('MySQL起始端口') }}：</span>
        <span class="ticket-details__item-value">{{ ticketDetails?.details?.start_mysql_port || '--' }}</span>
      </div>
    </div>
  </div>
  <div class="ticket-details__info">
    <strong class="ticket-details__info-title">{{ $t('需求信息') }}</strong>
    <div
      class="ticket-details__list"
      style="max-width: unset">
      <div
        class="ticket-details__item"
        style="max-width: 500px">
        <span class="ticket-details__item-label">{{ $t('数量') }}：</span>
        <span class="ticket-details__item-value">{{ ticketDetails?.details?.cluster_count }}</span>
      </div>
      <div
        class="ticket-details__item"
        style="max-width: 500px">
        <span class="ticket-details__item-label">{{ $t('备注') }}：</span>
        <span class="ticket-details__item-value">{{ ticketDetails?.remark || '--' }}</span>
      </div>
      <div
        v-if="ticketDetails?.details?.ip_source === 'resource_pool'"
        class="ticket-details__item whole"
        style="max-width: 1000px">
        <div
          v-if="isSingleType"
          class="ticket-details__item">
          <span class="ticket-details__item-label">{{ $t('后端存储资源规格') }}：</span>
          <span class="ticket-details__item-value">
            <BkPopover
              placement="top"
              theme="light">
              <span
                class="pb-2"
                style="cursor: pointer; border-bottom: 1px dashed #979ba5">
                {{ singleSpec?.spec_name }}（{{ `${singleSpec?.count} ${$t('台')}` }}）
              </span>
              <template #content>
                <SpecInfos :data="singleSpec" />
              </template>
            </BkPopover>
          </span>
        </div>
        <template v-else>
          <div class="ticket-details__item">
            <span class="ticket-details__item-label">{{ $t('Proxy存储资源规格') }}：</span>
            <span class="ticket-details__item-value">
              <BkPopover
                placement="top"
                theme="light">
                <span
                  class="pb-2"
                  style="cursor: pointer; border-bottom: 1px dashed #979ba5">
                  {{ proxySpec?.spec_name }}（{{ `${proxySpec?.count} ${$t('台')}` }}）
                </span>
                <template #content>
                  <SpecInfos :data="proxySpec" />
                </template>
              </BkPopover>
            </span>
          </div>
          <div class="ticket-details__item">
            <span class="ticket-details__item-label">{{ $t('后端存储资源规格') }}：</span>
            <span class="ticket-details__item-value">
              <BkPopover
                placement="top"
                theme="light">
                <span
                  class="pb-2"
                  style="cursor: pointer; border-bottom: 1px dashed #979ba5">
                  {{ backendSpec?.spec_name }}（{{ `${backendSpec?.count} ${$t('台')}` }}）
                </span>
                <template #content>
                  <SpecInfos :data="backendSpec" />
                </template>
              </BkPopover>
            </span>
          </div>
        </template>
      </div>
      <div class="ticket-details__item table">
        <span class="ticket-details__item-label">{{ $t('集群设置') }}：</span>
        <span class="ticket-details__item-value">
          <PreviewTable
            :key="ticketDetails?.ticket_type"
            :data="tableData"
            :is-show-nodes="ticketDetails?.details?.ip_source === 'manual_input'"
            :is-single-type="isSingleType"
            :max-height="240"
            :min-height="0"
            :nodes="ticketDetails?.details?.nodes || []" />
        </span>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
  import { useI18n } from 'vue-i18n';
  import { useRequest } from 'vue-request';

  import type { MySQLDetails } from '@services/model/ticket/details/mysql';
  import TicketModel from '@services/model/ticket/ticket';
  import { getInfrasCities } from '@services/ticket';

  import { useSystemEnviron } from '@stores';

  import { mysqlType, type MysqlTypeString, TicketTypes } from '@common/const';

  import PreviewTable from '@views/mysql/apply/components/PreviewTable.vue';

  import SpecInfos from '../../SpecInfos.vue';

  interface Props {
    ticketDetails: TicketModel<MySQLDetails>;
  }

  const props = defineProps<Props>();

  const { t } = useI18n();

  const { AFFINITY: affinityList } = useSystemEnviron().urls;

  const cityName = ref('--');

  const proxySpec = computed(() => props.ticketDetails?.details?.resource_spec?.proxy || {});
  const backendSpec = computed(() => props.ticketDetails?.details?.resource_spec?.backend || {});
  const singleSpec = computed(() => props.ticketDetails?.details?.resource_spec?.single || {});

  // 是否为单节点类型
  const isSingleType = computed(() => props.ticketDetails?.ticket_type === TicketTypes.MYSQL_SINGLE_APPLY);

  /**
   * preview table data
   */
  const tableData = computed(() =>
    (props.ticketDetails?.details?.domains || []).map((item: any) => {
      const { details } = props.ticketDetails;
      return {
        domain: item.master,
        slaveDomain: item.slave,
        disasterDefence: t('同城跨园区'),
        deployStructure: mysqlType[props.ticketDetails.ticket_type as MysqlTypeString].name,
        version: details?.db_version,
        charset: details?.charset,
        spec: details?.spec_display,
      };
    }),
  );

  const affinity = computed(() => {
    const level = props.ticketDetails?.details?.disaster_tolerance_level;
    if (level && affinityList) {
      return affinityList.find((item) => item.value === level)?.label;
    }
    return '--';
  });

  useRequest(getInfrasCities, {
    onSuccess: (cityList) => {
      const cityCode = props.ticketDetails.details.city_code;
      const name = cityList.find((item) => item.city_code === cityCode)?.city_name;
      cityName.value = name ?? '--';
    },
  });
</script>

<style lang="less" scoped>
  @import '@views/tickets/common/styles/ticketDetails.less';
</style>
