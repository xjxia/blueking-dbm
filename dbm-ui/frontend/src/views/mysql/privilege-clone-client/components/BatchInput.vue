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
    :quick-close="false"
    :title="$t('客户端权限克隆_批量录入')"
    :width="700"
    @closed="handleClose">
    <div class="batch-input">
      <div class="batch-input-format">
        <div class="batch-input-format-item">
          <strong>{{ $t('源客户端IP') }}({{ $t('管控区域_IP') }})</strong>
          <p class="pt-8">
            {{ $t('如_xx', ['10:127.0.0.1']) }}
          </p>
        </div>
        <div class="batch-input-format-item">
          <strong>{{ $t('新客户端IP') }}</strong>
          <p class="pt-8">
            127.0.0.2,127.0.0.3
            <DbIcon
              v-bk-tooltips="$t('复制格式')"
              class="batch-input-copy"
              type="copy"
              @click="handleCopy" />
          </p>
        </div>
      </div>
      <BkInput
        ref="inputRef"
        v-model="state.values"
        class="batch-input-textarea"
        :placeholder="placeholder"
        :rows="20"
        style="height: 320px; margin: 12px 0 30px;"
        type="textarea"
        @input="handleInput" />
      <div class="batch-input-errors">
        <span
          v-if="state.formatError.show"
          class="mr-8">
          <I18nT
            keypath="n处缺少对应IP"
            tag="span">
            <strong>{{ state.formatError.count }}</strong>
          </I18nT>
          <DbIcon
            v-bk-tooltips="$t('标记错误')"
            class="batch-input-errors-icon"
            type="audit"
            @click="handleSelectionError('formatError')" />
        </span>
        <span v-if="state.ipError.show">
          <I18nT
            keypath="n处IP格式错误"
            tag="span">
            <strong>{{ state.ipError.count }}</strong>
          </I18nT>
          <DbIcon
            v-bk-tooltips="$t('标记错误')"
            class="batch-input-errors-icon"
            type="audit"
            @click="handleSelectionError('ipError')" />
        </span>
      </div>
    </div>
    <template #footer>
      <BkButton
        class="mr-8 w-88"
        theme="primary"
        @click="handleConfirm">
        {{ $t('确定') }}
      </BkButton>
      <BkButton
        class="w-88"
        @click="handleClose">
        {{ $t('取消') }}
      </BkButton>
    </template>
  </BkDialog>
</template>

<script setup lang="ts">
  import { useI18n } from 'vue-i18n';

  import { useCopy } from '@hooks';

  import { ipv4 } from '@common/regex';

  interface Emits {
    (e: 'update:isShow', value: boolean): void
    (e: 'change', value: Array<{ source: string, target: string }>): void
  }

  interface Props {
    isShow: boolean,
  }

  defineProps<Props>();
  const emits = defineEmits<Emits>();

  const { t } = useI18n();
  const copy = useCopy();
  const inputRef = ref();
  const placeholder = t('请分别输入源客户端IP_单个_新客户端IP_可为多个英文逗号分隔_多个对象_换行分隔');

  const state = reactive({
    values: '',
    formatError: {
      show: false,
      selectionStart: 0,
      selectionEnd: 0,
      count: 0,
    },
    ipError: {
      show: false,
      selectionStart: 0,
      selectionEnd: 0,
      count: 0,
    },
  });

  /**
   * 复制格式
   */
  function handleCopy() {
    copy('10:127.0.0.1    127.0.0.2,127.0.0.3');
  }

  /**
   * 标记错误信息
   */
  function handleSelectionError(key: 'ipError' | 'formatError') {
    const { selectionStart, selectionEnd } = state[key];
    const textarea = inputRef.value?.$el?.getElementsByTagName?.('textarea')?.[0];
    if (textarea) {
      (textarea as HTMLInputElement).focus();
      (textarea as HTMLInputElement).setSelectionRange(selectionStart, selectionEnd);
    }
  }

  function handleInput() {
    state.formatError.show = false;
    state.ipError.show = false;
  }

  function handleClose() {
    const init = {
      show: false,
      selectionStart: 0,
      selectionEnd: 0,
      count: 0,
    };
    state.formatError = { ...init };
    state.ipError = { ...init };
    state.values = '';
    emits('update:isShow', false);
  }

  function handleConfirm() {
    if (state.values === '') {
      handleClose();
      return;
    }

    const newLines: string[] = [];
    const lines = state.values.split('\n').filter(text => text);
    const getContents = (value: string) => {
      const contents = value.trim() // 清除前后空格
        .replace(/\s+/g, ' ') // 替换多余空格
        .split(' '); // 通过空格分割
      return contents;
    };

    // 缺少对应 IP 格式错误
    for (let i = lines.length - 1; i >= 0; i--) {
      const contents = getContents(lines[i]);
      if (contents.length !== 2 || contents.some(text => !text)) {
        const remove = lines.splice(i, 1);
        newLines.push(...remove);
      }
    }
    const count = newLines.length;
    state.formatError.count = count;
    state.formatError.selectionStart = 0;
    state.formatError.selectionEnd = newLines.join('\n').length;
    state.formatError.show = count > 0;

    // ip 格式错误
    for (let i = lines.length - 1; i >= 0; i--) {
      const [source, target] = getContents(lines[i]);
      const [cloud, ip] = source.split(':');
      if (
        /^\d+$/.test(cloud) === false
        || ipv4.test(ip) === false
        || target.split(',').some(ip => ipv4.test(ip) === false)
      ) {
        const remove = lines.splice(i, 1);
        newLines.push(...remove);
      }
    }
    state.ipError.count = newLines.length - count;
    state.ipError.selectionStart = state.formatError.selectionEnd === 0 ? 0 : state.formatError.selectionEnd + 1;
    state.ipError.selectionEnd = newLines.join('\n').length;
    state.ipError.show = newLines.slice(count).length > 0;

    // 将调整好的内容回填显示
    newLines.push(...lines); // 没有错误内容回填
    state.values = newLines.join('\n');

    if (state.ipError.show || state.formatError.show) return;

    const res = newLines.map((item) => {
      const [source, target] = getContents(item);
      return {
        source,
        target: target.replace(',', '\n'),
      };
    });
    emits('change', res);
    handleClose();
  }
</script>

<style lang="less" scoped>
  .batch-input {
    position: relative;

    .batch-input-format {
      display: flex;
      padding: 16px;
      background-color: #f5f7fa;
      border-radius: 2px;

      .batch-input-format-item {
        margin-right: 24px;
        font-size: @font-size-mini;
      }
    }

    .batch-input-copy {
      color: @primary-color;
      cursor: pointer;
    }

    .batch-input-textarea {
      height: 310px;
      margin: 16px 0 30px;

      :deep(textarea) {
        &::selection {
          background-color: #fdd;
        }
      }
    }

    .batch-input-errors {
      position: absolute;
      bottom: 8px;
      font-size: @font-size-mini;
      color: @danger-color;

      .batch-input-errors-icon {
        font-size: @font-size-large;
        color: @gray-color;
        cursor: pointer;

        &:hover {
          color: @default-color;
        }
      }
    }
  }
</style>
