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
  <BkDialog
    :is-show="isShow"
    :title="$t('库表备份_批量录入')"
    :width="1200"
    @closed="handleClosed">
    <div class="db-table-backup-batch-entry">
      <div class="header">
        <table>
          <thead>
            <tr>
              <th>{{ $t('目标集群') }}</th>
              <!-- <th>{{ $t('备份源') }}</th> -->
              <th>{{ $t('备份DB名') }}</th>
              <th>{{ $t('备份表名') }}</th>
              <th>{{ $t('忽略DB名') }}</th>
              <th>{{ $t('忽略表名') }}</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td>magode.db.oued8:9000</td>
              <!-- <td>{{ $t('Master或Slave') }}</td> -->
              <td>demoDB1，demoDB2</td>
              <td>demoDB%</td>
              <td>{{ $t('无') }}</td>
              <td>
                <span>{{ $t('无') }}</span>
                <span
                  v-bk-tooltips="$t('复制')"
                  class="copy-btn"
                  @click="handleCopy">
                  <DbIcon type="copy" />
                </span>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
      <div ref="inputRef">
        <BkInput
          v-model="localValue"
          :placeholder="placeholder"
          :rows="20"
          style="height: 320px; margin: 12px 0 30px;"
          type="textarea"
          @input="handleInputChange" />
      </div>
      <div class="error-box">
        <span v-if="inputInvalidStack.length > 0">
          <span>{{ $t('n处格式错误', [inputInvalidStack.length]) }}</span>
          <DbIcon
            class="action-btn"
            type="audit"
            @click="handleHighInvalid" />
        </span>
        <span v-if="inputErrorStack.length > 0">
          <span v-if="inputInvalidStack.length > 0">；</span>
          <span>{{ $t('n处缺少匹配对象', [inputErrorStack.length]) }}</span>
          <DbIcon
            class="action-btn"
            type="audit"
            @click="handleHighError" />
        </span>
        <span v-if="inputClusterErrorStack.length > 0">
          <span v-if="inputErrorStack.length > 0">；</span>
          <span>{{ $t('n处目标集群不存在', [inputClusterErrorStack.length]) }}</span>
          <DbIcon
            class="action-btn"
            type="audit"
            @click="handleHighClusterError" />
        </span>
      </div>
    </div>
    <template #footer>
      <BkButton
        class="w-88"
        :loading="isChecking"
        theme="primary"
        @click="handleSubmit">
        {{ $t('确定') }}
      </BkButton>
      <BkButton
        class="ml8"
        @click="handleClosed">
        {{ $t('取消') }}
      </BkButton>
    </template>
  </BkDialog>
</template>
<script lang="ts">
  export interface IValue {
    clusterData: {
      id: number;
      domain: string;
    };
    // backupOn: string,
    dbPatterns: string[];
    tablePatterns: string[];
    ignoreDbs: string[];
    ignoreTables: string[];
  }
</script>
<script setup lang="ts">
  import _ from 'lodash';
  import { ref } from 'vue';
  import { useI18n } from 'vue-i18n';

  import { queryClusters } from '@services/source/mysqlCluster';

  import { useGlobalBizs } from '@stores';

  import { execCopy } from '@/utils';


  interface IInputParse {
    domain: string,
    // backupOn: string,
    dbPatterns: string,
    ignoreDbs: string,
    tablePatterns: string,
    ignoreTables: string,
  }

  interface Props {
    isShow: boolean;
  }
  interface Emits {
    (e: 'update:isShow', value: boolean): void;
    (e: 'change', value: Array<IValue>): void;
  }

  defineProps<Props>();
  const emits = defineEmits<Emits>();

  const { t } = useI18n();
  const getInputTextList = (list: Array<IInputParse>) => list.map(item => `${item.domain} ${item.dbPatterns} ${item.tablePatterns} ${item.ignoreDbs} ${item.ignoreTables}`);

  const { currentBizId } = useGlobalBizs();

  const placeholder = t('请分别输入目标集群_备份DB名_备份表名_忽略DB名_忽略表名_多个对象_换行分隔');

  const inputRef = ref();
  const isChecking = ref(false);
  const localValue = ref('');

  const inputInvalidStack = ref<Array<IInputParse>>([]);
  const inputErrorStack = ref<Array<IInputParse>>([]);
  const inputClusterErrorStack = ref<Array<IInputParse>>([]);

  const handleCopy = () => {
    execCopy('magode.db.oued8:9000    demoDB1,demoDB2    demoDB%    -    -\n');
  };

  const handleClosed = () => {
    emits('update:isShow', false);
  };


  const handleSubmit = () => {
    const inputRecordList =  localValue.value.split('\n');

    const validList: Array<IInputParse> = [];
    const invalidList: Array<IInputParse> = [];
    const errorList: Array<IInputParse> = [];

    inputRecordList.forEach((recordItem) => {
      if (!_.trim(recordItem)) {
        return;
      }
      const recordList = recordItem.split(/ +/).filter(item => _.trim(item));

      if (recordList.length !== 5) {
        errorList.push({
          domain: recordItem,
          // backupOn: '',
          dbPatterns: '',
          tablePatterns: '',
          ignoreDbs: '',
          ignoreTables: '',
        });
        return;
      }
      const [
        domain,
        // backupOn,
        dbPatterns,
        tablePatterns,
        ignoreDbs,
        ignoreTables,
      ] = recordList;
      const payload = {
        domain,
        // backupOn,
        dbPatterns,
        tablePatterns,
        ignoreDbs,
        ignoreTables,
      };
      // 集群、主机为空
      if (!domain || !dbPatterns || !ignoreDbs || !tablePatterns || !ignoreTables) {
        errorList.push(payload);
        return;
      }
      // 集群格式不正确
      if (!/^\w+(:\d+)?/.test(domain)) {
        invalidList.push(payload);
        return;
      }

      validList.push(payload);
    });

    isChecking.value = true;
    queryClusters({
      cluster_filters: validList.map(item => ({
        immute_domain: item.domain,
      })),
      bk_biz_id: currentBizId,
    })
      .then((data: Array<{master_domain: string, id: number}>) => {
        const realDataMap = data.reduce((result, item) => ({
          ...result,
          [item.master_domain]: item.id,
        }), {} as Record<string, number>);

        const resultList: Array<IValue> = [];
        const clusterErrorList: Array<IInputParse> = [];
        validList.forEach((item) => {
          if (!realDataMap[item.domain]) {
            clusterErrorList.push(item);
          } else {
            const {
              // backupOn = '',
              dbPatterns,
              tablePatterns,
              ignoreDbs,
              ignoreTables,
            } = item;

            const getListValue = (str: string) => {
              if (str === '-') {
                return [];
              }
              return str.split(',');
            };
            resultList.push({
              clusterData: {
                id: realDataMap[item.domain],
                domain: item.domain,
              },
              // backupOn,
              dbPatterns: getListValue(dbPatterns),
              tablePatterns: getListValue(tablePatterns),
              ignoreDbs: getListValue(ignoreDbs),
              ignoreTables: getListValue(ignoreTables),
            });
          }
        });
        inputInvalidStack.value = invalidList;
        inputErrorStack.value = errorList;
        inputClusterErrorStack.value = clusterErrorList;
        if (invalidList.length < 1
          && errorList.length < 1
          && clusterErrorList.length < 1) {
          emits('change', resultList);
          handleClosed();
        } else {
          const renderListValue = (arr: string[]) => {
            if (arr.length < 1) {
              return '-';
            }
            return arr.join(',');
          };
          localValue.value = _.filter([
            ...invalidList.map(item => getInputTextList([item])),
            ...errorList.map(item => getInputTextList([item])),
            ...clusterErrorList.map(item => getInputTextList([item])),
            ...resultList.map(item => `${item.clusterData.domain} ${renderListValue(item.dbPatterns)} ${renderListValue(item.tablePatterns)} ${renderListValue(item.ignoreDbs)} ${renderListValue(item.ignoreTables)}`),
          ]).join('\n');
        }
      })
      .finally(() => {
        isChecking.value = false;
      });
  };

  const handleInputChange = () => {
    inputInvalidStack.value = [];
    inputErrorStack.value = [];
    inputClusterErrorStack.value = [];
  };

  const handleHighInvalid = () => {
    const $inputEl = inputRef.value.querySelector('textarea');
    const invalidText = getInputTextList(inputInvalidStack.value).join('\n');
    $inputEl.focus();
    $inputEl.selectionStart = 0;
    $inputEl.selectionEnd = invalidText.length;
  };

  const handleHighError = () => {
    const $inputEl = inputRef.value.querySelector('textarea');
    $inputEl.focus();
    const invalidText = getInputTextList(inputInvalidStack.value).join('\n');
    const errorText = getInputTextList(inputErrorStack.value).join('\n');

    const startIndex = invalidText.length > 0 ? invalidText.length + 1 : 0;
    $inputEl.selectionStart = startIndex;
    $inputEl.selectionEnd = startIndex + errorText.length;
  };

  const handleHighClusterError = () => {
    const $inputEl = inputRef.value.querySelector('textarea');
    $inputEl.focus();
    const invalidText = [
      ...getInputTextList(inputInvalidStack.value),
      ...getInputTextList(inputErrorStack.value),
    ].join('\n');
    const clusterErrorText = getInputTextList(inputClusterErrorStack.value).join('\n');

    const startIndex = invalidText.length > 0 ? invalidText.length + 1 : 0;
    $inputEl.selectionStart = startIndex;
    $inputEl.selectionEnd = startIndex + clusterErrorText.length;
  };
</script>
<style lang="less">
  .db-table-backup-batch-entry {
    .header {
      width: 100%;
      padding: 6px 0;
      font-size: 12px;
      color: #63656e;
      text-align: left;
      background: #f5f7fa;
      border-radius: 2px;

      th,
      td {
        padding: 5px 16px;
        line-height: 16px;
      }

      .copy-btn {
        margin-left: 18px;
        color: #3a84ff;
        cursor: pointer;
      }
    }

    .error-box {
      position: absolute;
      margin-top: -25px;
      font-size: 12px;
      font-weight: bold;
      color: #ea3636;

      .action-btn {
        padding: 0 4px;
        color: #979ba5;
        cursor: pointer;
      }
    }

    textarea {
      &::selection {
        color: #63656e;
        background: #fdd;
      }
    }
  }
</style>
