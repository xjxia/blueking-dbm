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
  <!-- <div
    class="render-host-box"
    @mouseenter="handleControlShowEdit(true)"
    @mouseleave="handleControlShowEdit(false)">
    <BkPopover
      :is-show="isShowOverflowTip"
      placement="top"
      :popover-delay="0"
      theme="light"
      trigger="manual">
      <div
        class="content-box"
        :class="{ 'is-empty': !clusterData, 'is-error': Boolean(errorMessage) }">
        <span
          v-if="localHostList.length === 0"
          class="placehold">
          {{ t('请选择主机') }}
        </span>
        <span
          v-else
          ref="contentRef"
          class="content-text">
          {{ localHostList.map((item) => item.ip).join(',  ') }}
        </span>
        <BkPopover
          v-if="!!clusterData && showEditIcon"
          :content="t('从业务拓扑选择')"
          placement="top"
          theme="dark">
          <div
            class="edit-btn"
            @click="handleShowIpSelector">
            <div class="edit-btn-inner">
              <DbIcon
                class="select-icon"
                type="host-select" />
            </div>
          </div>
        </BkPopover>
        <div
          v-if="errorMessage"
          class="input-error">
          <DbIcon
            v-bk-tooltips="errorMessage"
            type="exclamation-fill" />
        </div>
      </div>
      <template #content>
        <div
          v-for="item in localHostList"
          :key="item.ip">
          {{ item.ip }}
        </div>
      </template>
    </BkPopover>
  </div> -->
  <RenderHost
    :data="renderText"
    :is-disabled="localHostList.length === 0"
    :placeholder="t('请选择IP')"
    @click="handleShowIpSelector" />
  <IpSelector
    v-if="clusterData"
    v-model:show-dialog="isShowIpSelector"
    :biz-id="clusterData.bk_biz_id"
    button-text=""
    :cloud-info="{
      id: clusterData.bk_cloud_id,
      name: clusterData.bk_cloud_name,
    }"
    :data="localHostList"
    :os-types="[OSTypes.Linux]"
    :panel-list="['staticTopo', 'dbmWhitelist', 'manualInput']"
    service-mode="all"
    :show-view="false"
    @change="handleHostChange"
    @change-whitelist="handleWhitelistChange" />
</template>
<script setup lang="ts">
  import _ from 'lodash';
  import { useI18n } from 'vue-i18n';

  import { checkHost } from '@services/source/ipchooser';
  import type { HostDetails } from '@services/types/ip';

  import { OSTypes } from '@common/const';

  import IpSelector, { type IPSelectorResult } from '@components/ip-selector/IpSelector.vue';
  import RenderHost from '@components/render-table/columns/select-disable/index.vue';

  import type { IDataRow } from './Row.vue';
  // import useValidtor from './useValidtor';

  interface Props {
    data?: IDataRow['authorizeIps'];
    clusterData?: IDataRow['clusterData'];
  }

  interface Exposes {
    getValue: () => Promise<{
      authorize_ips: string[];
    }>;
  }

  const props = withDefaults(defineProps<Props>(), {
    data: () => [],
    clusterData: undefined,
  });

  const { t } = useI18n();

  // const contentRef = ref();
  const isShowIpSelector = ref(false);
  // const showEditIcon = ref(false);
  // const isOverflow = ref(false);

  const localHostList = shallowRef<HostDetails[]>([]);

  // const isShowOverflowTip = computed(() => isOverflow.value && showEditIcon.value);

  const renderText = computed(() => localHostList.value.map((item) => item.ip).join(',  '));

  // const { validator } = useValidtor([]);

  watch(
    () => props.data,
    async () => {
      if (props.data.length) {
        const hosts = await checkHost({
          ip_list: props.data,
          mode: 'all',
          scope_list: [
            {
              scope_id: window.PROJECT_CONFIG.BIZ_ID,
              scope_type: 'biz',
            },
          ],
        });

        localHostList.value = hosts;
      }
    },
    {
      immediate: true,
    },
  );

  // watch(
  //   localHostList,
  //   (list) => {
  //     if (list.length > 0) {
  //       setTimeout(() => {
  //         isOverflow.value = contentRef.value.clientWidth < contentRef.value.scrollWidth;
  //       });
  //     }
  //   },
  //   {
  //     deep: true,
  //   },
  // );

  // const handleControlShowEdit = (isShow: boolean) => {
  //   showEditIcon.value = isShow;
  // };

  const handleShowIpSelector = () => {
    isShowIpSelector.value = true;
  };

  const handleHostChange = (hostList: HostDetails[]) => {
    localHostList.value = hostList;
  };

  const handleWhitelistChange = (whiteList: IPSelectorResult['dbm_whitelist']) => {
    const localIps = localHostList.value.map((item) => item.ip);
    const whiteIps = _.flatMap(whiteList.map((item) => item.ips));
    const finalIps = Array.from(new Set([...localIps, ...whiteIps]));
    localHostList.value = finalIps.map((ip) => ({ ip }) as HostDetails);
  };

  defineExpose<Exposes>({
    getValue() {
      return Promise.resolve({
        authorize_ips: localHostList.value.map(({ ip }) => ip),
      });
    },
  });
</script>
<style lang="less" scoped>
  .render-host-box {
    position: relative;
    display: flex;
    align-items: center;
    overflow: hidden;

    .content-box {
      position: relative;
      display: flex;
      width: 100%;
      height: 42px;
      align-items: center;
      padding: 0 25px 0 17px;
      overflow: hidden;
      border: solid transparent 1px;

      &:hover {
        cursor: pointer;
        border-color: #a3c5fd;

        .edit-btn-inner {
          background-color: #f0f1f5;
        }
      }

      .placehold {
        color: #c4c6cc;
      }

      .content-text {
        flex: 1;
        overflow: hidden;
        text-overflow: ellipsis;
        white-space: nowrap;
      }

      .edit-btn {
        position: absolute;
        right: 5px;
        z-index: 999;
        display: flex;
        width: 24px;
        height: 40px;
        align-items: center;

        .edit-btn-inner {
          display: flex;
          width: 24px;
          height: 24px;
          cursor: pointer;
          border-radius: 2px;
          align-items: center;
          justify-content: center;

          .select-icon {
            font-size: 16px;
            color: #979ba5;
          }

          &:hover {
            background: #f0f1f5;

            .select-icon {
              color: #3a84ff;
            }
          }
        }
      }

      .input-error {
        position: absolute;
        inset: 0;
        display: flex;
        padding-right: 35px;
        font-size: 14px;
        color: #ea3636;
        align-items: center;
        justify-content: flex-end;
      }
    }

    .is-empty {
      background-color: #fafbfd;
      border: none;

      :hover {
        border: none;
      }
    }

    .is-error {
      background-color: #fff1f1;
    }

    .host-input {
      flex: 1;

      :deep(.inner-input) {
        padding-right: 24px;
        background-color: #fff;
        border: solid transparent 1px;

        &:hover {
          background-color: #fafbfd;
          border-color: #a3c5fd;
        }
      }

      &:hover {
        cursor: pointer;
      }
    }
  }
</style>
