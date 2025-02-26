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
  <tbody>
    <tr>
      <td style="padding: 0">
        <RenderSourceDb
          ref="sourceDbRef"
          v-model="localRowData.source_db"
          :cluster-id="clusterId" />
      </td>
      <td>
        {{ t('所有表') }}
      </td>
      <td style="padding: 0">
        <RenderTableData
          ref="tableDataRef"
          check-exist
          :cluster-id="clusterId"
          :model-value="localRowData.data_tblist"
          :placeholder="t('表名支持通配符“%”，含通配符的仅支持单个，为空则不克隆表数据')"
          :required="false" />
      </td>
      <td style="padding: 0">
        <RenderTargetDbPattern
          ref="targetDbPatternRef"
          v-model="localRowData.target_db_pattern"
          :db-name="localRowData.source_db" />
      </td>
      <OperateColumn
        :removeable="removeable"
        @add="handleAppend"
        @remove="handleRemove" />
    </tr>
  </tbody>
</template>
<script lang="ts">
  import OperateColumn from '@components/render-table/columns/operate-column/index.vue';

  import RenderTableData from '@views/mysql/common/edit-field/TableName.vue';

  import { random } from '@utils';

  // 创建表格数据
  export const createRowData = (data = {} as Partial<IDataRow>) => ({
    rowKey: random(),
    source_db: data.source_db || '',
    schema_tblist: data.schema_tblist || [],
    data_tblist: data.data_tblist || [],
    target_db_pattern: data.target_db_pattern || '',
  });
</script>
<script setup lang="ts">
  import { useI18n } from 'vue-i18n';

  import RenderSourceDb from './RenderSourceDb.vue';
  import RenderTargetDbPattern from './RenderTargetDbPattern.vue';

  export interface IData {
    source_db: string;
    schema_tblist: string[];
    data_tblist: string[];
    target_db_pattern: string;
  }

  export interface IDataRow extends IData {
    rowKey: string;
  }

  interface Props {
    data: IDataRow;
    removeable: boolean;
    clusterId: number;
  }

  interface Emits {
    (e: 'add', params: Array<IDataRow>): void;
    (e: 'remove'): void;
  }

  interface Exposes {
    getValue: () => Promise<Required<IData>>;
  }

  const props = defineProps<Props>();

  const emits = defineEmits<Emits>();

  const { t } = useI18n();

  const sourceDbRef = ref<InstanceType<typeof RenderSourceDb>>();
  const tableDataRef = ref<InstanceType<typeof RenderTableData>>();
  const targetDbPatternRef = ref<InstanceType<typeof RenderTargetDbPattern>>();

  const localRowData = reactive(createRowData());

  watch(
    () => props.data,
    () => {
      Object.assign(localRowData, props.data);
    },
    {
      immediate: true,
      deep: true,
    },
  );

  const handleAppend = () => {
    emits('add', [createRowData()]);
  };

  const handleRemove = () => {
    if (props.removeable) {
      return;
    }
    emits('remove');
  };

  defineExpose<Exposes>({
    getValue() {
      return Promise.all([
        sourceDbRef.value!.getValue(),
        tableDataRef.value!.getValue('data_tblist'),
        targetDbPatternRef.value!.getValue(),
      ]).then(([sourceDbData, tableDataData, targetDbPatternData]) => ({
        ...sourceDbData,
        ...tableDataData,
        ...targetDbPatternData,
        schema_tblist: ['*'],
      }));
    },
  });
</script>
