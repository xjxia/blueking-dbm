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
  <div class="instance-selector-manual-input-host">
    <BkResizeLayout
      :border="false"
      collapsible
      initial-divide="480px"
      :max="600"
      :min="420">
      <template #aside>
        <div class="manual-input-wrapper">
          <BkInput
            ref="inputRef"
            v-model.trim="inputState.values"
            class="manual-input-textarea"
            :placeholder="inputState.placeholder"
            type="textarea"
            @input="handleInput" />
          <div class="manual-input-errors">
            <span
              v-if="errorState.format.show"
              class="mr-8">
              <I18nT
                keypath="n处格式错误"
                tag="span">
                <strong>{{ errorState.format.count }}</strong>
              </I18nT>
              <DbIcon
                v-bk-tooltips="t('标记错误')"
                class="manual-input-icons"
                type="audit"
                @click="handleSelectionError('format')" />
            </span>
            <span v-if="errorState.ip.show">
              <I18nT
                keypath="n处IP不存在"
                tag="span">
                <strong>{{ errorState.ip.count }}</strong>
              </I18nT>
              <DbIcon
                v-bk-tooltips="t('标记错误')"
                class="manual-input-icons"
                type="audit"
                @click="handleSelectionError('ip')" />
            </span>
          </div>
          <div class="manual-input-buttons">
            <BkButton
              class="mr-8"
              :disabled="!inputState.values"
              :loading="inputState.isLoading"
              outline
              size="small"
              theme="primary"
              @click="handleParsingValues">
              {{ t('解析并添加') }}
            </BkButton>
            <BkButton
              class="w-88"
              size="small"
              @click="handleClear">
              {{ t('清空') }}
            </BkButton>
          </div>
        </div>
      </template>
      <template #main>
        <BkLoading :loading="inputState.isLoading">
          <RenderManualHost
            :active-panel-id="manualConfig.activePanelId"
            :firsr-column="firsrColumn"
            :get-table-list="getTableList"
            is-manul
            :last-values="lastValues"
            :manual-table-data="inputState.tableData"
            :status-filter="statusFilter"
            :table-setting="tableSetting"
            @change="handleHostChange" />
        </BkLoading>
      </template>
    </BkResizeLayout>
  </div>
</template>
<script setup lang="ts" generic="T extends IValue">
  import { useI18n } from 'vue-i18n';

  import type { ListBase } from '@services/types'

  import { useGlobalBizs } from '@stores';

  import { ipv4 } from '@common/regex';

  import type { InstanceSelectorValues, IValue, PanelListType, TableSetting } from '../../../Index.vue';

  import RenderManualHost from './table/Index.vue';

  type TableConfigType = Required<PanelListType[number]>['tableConfig'];
  type ManualConfigType = Required<PanelListType[number]>['manualConfig'];

  interface Props {
    lastValues: InstanceSelectorValues<T>,
    manualConfig: Required<ManualConfigType>,
    // clusterId?: number,
    tableSetting: TableSetting,
    firsrColumn?: TableConfigType['firsrColumn'],
    statusFilter?: TableConfigType['statusFilter'],
    getTableList: NonNullable<TableConfigType['getTableList']>;
  }

  interface Emits {
    (e: 'change', value: InstanceSelectorValues<T>): void
  }
  const props = withDefaults(defineProps<Props>(), {
    firsrColumn: undefined,
    statusFilter: undefined,
    // clusterId: undefined,
  });
  const emits = defineEmits<Emits>();

  const { t } = useI18n();
  const { currentBizId } = useGlobalBizs();
  const inputRef = ref();

  const inputState = reactive({
    values: '',
    placeholder: t('请输入IP_如_1_1_1_1多个可使用换行_空格或_分隔'),
    isLoading: false,
    tableData: [] as T[],
  });
  const errorState = reactive({
    format: {
      show: false,
      selectionStart: 0,
      selectionEnd: 0,
      count: 0,
    },
    ip: {
      show: false,
      selectionStart: 0,
      selectionEnd: 0,
      count: 0,
    },
  });

  const handleHostChange = (values: InstanceSelectorValues<T>) => {
    emits('change', values);
  };

  const handleInput = () => {
    errorState.format.show = false;
    errorState.ip.show = false;
  };

  /**
   * 标记错误
   */
  const handleSelectionError = (key: 'format' | 'ip') => {
    const { selectionStart, selectionEnd } = errorState[key];
    const textarea = inputRef.value?.$el?.getElementsByTagName?.('textarea')?.[0];
    if (textarea) {
      (textarea as HTMLInputElement).focus();
      (textarea as HTMLInputElement).setSelectionRange(selectionStart, selectionEnd);
    }
  };

  /**
   * 处理分隔内容，过滤空内容
   */
  const getValues = () => inputState.values
    .replace(/\s+|[；，｜]/g, ' ') // 将空格 换行符 ；，｜符号统一为空格
    .split(' ')
    .filter(value => value);

  /**
   * 解析输入内容
   */
  const handleParsingValues = async () => {
    const newLines: string[] = [];
    const lines = getValues();

    // 处理格式错误
    for (let i = lines.length - 1; i >= 0; i--) {
      const value = lines[i];
      if (!ipv4.test(value)) {
        const remove = lines.splice(i, 1);
        newLines.push(...remove);
      }
    }
    const count = newLines.length;
    errorState.format.count = count;
    errorState.format.selectionStart = 0;
    errorState.format.selectionEnd = newLines.join('\n').length;

    // 检查 IP 是否存在
    inputState.isLoading = true;
    try {
      const params = {
        bizId: currentBizId,
        ip: lines.join(','),
      };
      // if (props.clusterId) {
      //   Object.assign(params, {
      //     cluster_ids: [props.clusterId],
      //   });
      // }
      const res = await (props.manualConfig.checkInstances as (params: any) => Promise<ListBase<any[]>>)(params);
      const hostList = res.results
      const legalInstances = [];
      for (let i = lines.length - 1; i >= 0; i--) {
        const item = lines[i];
        const infos = hostList[i];
        const remove = lines.splice(i, 1);
        const isExisted = hostList.find(existItem => (
          existItem[props.manualConfig.checkKey] === item
        ));
        if (!isExisted) {
          newLines.push(...remove);
        } else {
          legalInstances.push(infos);
        }
      }
      inputState.tableData.splice(0, inputState.tableData.length, ...legalInstances);
      errorState.ip.count = newLines.length - count;
      const { selectionEnd } = errorState.format;
      errorState.ip.selectionStart = selectionEnd === 0 ? 0 : selectionEnd + 1;
      errorState.ip.selectionEnd = newLines.join('\n').length;

      // 解析完成后选中
      const lastValues = { ...props.lastValues };
      for (const item of inputState.tableData) {
        const type = props.manualConfig.activePanelId;
        if (!lastValues[type]) {
          lastValues[type] = [];
        }
        const list = lastValues[type];
        const isExisted = list.length > 0 && list.find(i => `${i[props.manualConfig.checkKey]}_${i.bk_cloud_id}` === `${item[props.manualConfig.checkKey]}_${item.bk_cloud_id}`);
        if (!isExisted) {
          lastValues[type].push({
            bk_host_id: item.bk_host_id,
            bk_cloud_id: item.bk_cloud_id,
            ip: item.ip,
            cluster_id: item.related_clusters[0].id,
            port: 0,
            instance_address: '',
            cluster_type: '',
            master_domain: item.related_clusters[0].immute_domain,
            bk_cloud_name: item.bk_cloud_name,
            related_instances: (item.related_instances || []).map(instanceItem => ({
              instance: instanceItem.instance,
              status: instanceItem.status
            })),
            spec_config: item.spec_config
          } as T);
        }
      }
      emits('change', {
        ...props.lastValues,
        ...lastValues,
      });
    } catch (_) {
      console.error(_);
    }
    errorState.format.show = count > 0;
    errorState.ip.show = newLines.slice(count).length > 0;
    inputState.isLoading = false;

    // 将调整好的内容回填显示
    newLines.push(...lines); // 没有错误内容回填
    inputState.values = newLines.join('\n');
  };

  const handleClear = () => {
    inputState.values = '';
    errorState.format.show = false;
    errorState.ip.show = false;
  };
</script>

<style lang="less">
  .instance-selector-manual-input-host {
    height: 585px;
    padding-top: 16px;

    .bk-resize-layout {
      height: 100%;
    }

    .manual-input-wrapper {
      padding: 0 16px;
    }

    .manual-input-textarea {
      height: 508px;
      margin-bottom: 8px;

      textarea {
        &::selection {
          background-color: #fdd;
        }
      }
    }

    .manual-input-errors {
      font-size: @font-size-mini;
      color: @danger-color;
    }

    .manual-input-icons {
      font-size: @font-size-large;
      color: @gray-color;
      cursor: pointer;

      &:hover {
        color: @default-color;
      }
    }

    .manual-input-buttons {
      display: flex;
      align-items: center;
      margin-top: 5px;

      .bk-button {
        &:first-child {
          flex: 1;
        }
      }
    }
  }
</style>
