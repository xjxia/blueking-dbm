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
  <div class="render-mode">
    <div class="action-item">
      <TableEditSelect
        v-model="localBackupType"
        :disabled="editDisabled"
        :list="targetList" />
    </div>
    <div class="action-item">
      <TableEditDateTime
        v-if="localBackupType === 'time'"
        ref="localRollbackTimeRef"
        v-model="localRollbackTime"
        :disabled="editDisabled"
        :disabled-date="disableDate"
        ext-popover-cls="not-seconds-date-picker"
        :rules="timerRules"
        type="datetime" />
      <div
        v-else
        class="local-backup-select">
        <DbIcon
          class="file-flag"
          type="wenjian" />
        <TableEditSelect
          ref="localBackupidRef"
          v-model="localBackupid"
          :disabled="editDisabled"
          :list="logRecordList"
          :rules="rules"
          style="flex: 1" />
      </div>
    </div>
  </div>
</template>
<script setup lang="ts">
  import dayjs from 'dayjs';
  import _ from 'lodash';
  import { computed, ref, watch } from 'vue';
  import { useI18n } from 'vue-i18n';

  import { queryBackupLogFromBklog, queryBackupLogFromLoacal } from '@services/source/fixpointRollback';

  import { useTimeZoneFormat } from '@hooks';

  import { useTimeZone } from '@stores';

  import TableEditDateTime from '@views/mysql/common/edit/DateTime.vue';
  import TableEditSelect from '@views/mysql/common/edit/Select.vue';

  interface Props {
    clusterId: number;
    backupSource?: string;
    backupid?: number;
    rollbackTime?: string;
  }

  interface Exposes {
    getValue: (field: string) => Promise<{
      backupinfo?: any;
      rollback_time?: string;
    }>;
  }

  const props = defineProps<Props>();

  const disableDate = (date: Date) => date && date.valueOf() > Date.now();

  const { t } = useI18n();
  const formatDateToUTC = useTimeZoneFormat();
  const timeZoneStore = useTimeZone();

  const timerRules = [
    {
      validator: (value: string) => !!value,
      message: t('回档时间不能为空'),
    },
  ];

  const rules = [
    {
      validator: (value: string) => !!value,
      message: t('备份记录不能为空'),
    },
  ];

  const targetList = [
    {
      id: 'record',
      name: t('备份记录'),
    },
    {
      id: 'time',
      name: t('回档到指定时间'),
    },
  ];

  const localRollbackTimeRef = ref();
  const localBackupidRef = ref();
  const localBackupType = ref('record');
  const localBackupid = ref(0);
  const localRollbackTime = ref('');

  const logRecordList = shallowRef<Array<{ id: string; name: string }>>([]);

  const editDisabled = computed(() => !props.clusterId || !props.backupSource);

  let logRecordListMemo = [] as any[];

  const fetchLogData = () => {
    logRecordList.value = [];
    logRecordListMemo = [];
    const queryBackupLog = props.backupSource === 'local' ? queryBackupLogFromLoacal : queryBackupLogFromBklog;
    queryBackupLog({
      cluster_id: props.clusterId,
    }).then((dataList) => {
      logRecordList.value = dataList.map((item) => ({
        id: item.backup_id,
        name: `${item.mysql_role} ${dayjs(item.backup_time).tz(timeZoneStore.label).format('YYYY-MM-DD HH:mm:ss ZZ')}`,
      }));
      logRecordListMemo = dataList;
    });
  };

  watch(
    () => [props.backupSource, props.clusterId, timeZoneStore.label],
    () => {
      localBackupid.value = 0;
      localRollbackTime.value = '';
      if (!props.clusterId || !props.backupSource) {
        return;
      }
      fetchLogData();
    },
    {
      immediate: true,
    },
  );

  watch(
    () => props.backupid,
    () => {
      if (props.backupid) {
        localBackupid.value = props.backupid;
      }
      if (props.rollbackTime) {
        localRollbackTime.value = props.rollbackTime;
      }

      localBackupType.value = props.rollbackTime ? 'time' : 'record';
    },
    {
      immediate: true,
    },
  );

  defineExpose<Exposes>({
    getValue() {
      if (localBackupType.value === 'record') {
        return localBackupidRef.value.getValue().then(() => {
          const backupInfo = _.find(logRecordListMemo, (item) => item.backup_id === localBackupid.value);
          return {
            backupinfo: backupInfo,
          };
        });
      }
      return localRollbackTimeRef.value.getValue().then(() => ({
        rollback_time: formatDateToUTC(localRollbackTime.value),
      }));
    },
  });
</script>
<style lang="less" scoped>
  .render-mode {
    display: flex;

    .action-item {
      flex: 0 0 50%;
      overflow: hidden;
    }
  }

  .local-backup-select {
    position: relative;

    :deep(.table-edit-select) {
      .select-result-text {
        padding-left: 14px;
      }

      .select-placeholder {
        left: 30px;
      }
    }

    .file-flag {
      position: absolute;
      top: 14px;
      left: 8px;
      z-index: 1;
      font-size: 16px;
      color: #c4c6cc;
    }
  }
</style>
