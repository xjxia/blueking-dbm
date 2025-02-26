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
    <div class="password-temporary-modify">
      <div
        v-if="submitting"
        class="submitting-mask">
        <DbIcon
          class="submitting-icon"
          svg
          type="sync-pending" />
        <p class="submitting-text">
          {{ t('密码正在修改中，请稍等') }}
        </p>
      </div>
      <UpdateResult
        v-else-if="submitted"
        :submit-length="submitLength"
        :submit-res="submitRes"
        :submit-role-map="submitRoleMap"
        @refresh="handleRefresh"
        @retry="handleSubmit" />
      <DbForm
        v-else
        ref="formRef"
        class="password-form"
        :label-width="200"
        :model="formData">
        <BkFormItem
          class="pr-32"
          :label="t('需要修改的实例')"
          property="instanceList"
          required>
          <BkButton
            class="mb-16"
            @click="handleAddInstance">
            <DbIcon
              class="mr-8"
              type="add" />
            {{ t('添加实例') }}
          </BkButton>
          <DbOriginalTable
            :columns="columns"
            :data="formData.instanceList"
            show-overflow-tooltip />
        </BkFormItem>
        <BkFormItem
          ref="passwordItemRef"
          :label="t('统一临时密码')"
          property="password"
          required
          :rules="passwordRules">
          <BkComposeFormItem>
            <BkInput
              ref="passwordRef"
              v-model="formData.password"
              class="form-item-input password-input"
              type="password"
              @blur="handlePasswordBlur"
              @focus="handlePasswordFocus" />
            <BkButton
              class="form-item-suffix"
              outline
              theme="primary"
              @click="randomlyGenerate">
              {{ t('随机生成') }}
            </BkButton>
          </BkComposeFormItem>
        </BkFormItem>
        <BkFormItem
          :label="t('有效时长')"
          property="validDuration"
          required>
          <BkComposeFormItem>
            <BkInput
              v-model="formData.validDuration"
              class="form-item-input"
              :clearable="false"
              :min="1"
              :precision="0"
              type="number" />
            <BkSelect
              v-model="formData.validDurationType"
              class="form-item-suffix"
              :clearable="false">
              <BkOption
                v-for="item in VALID_DURATION_OPTIONS"
                :key="item.value"
                :label="item.label"
                :value="item.value" />
            </BkSelect>
          </BkComposeFormItem>
          <div class="anticipated-effective-time">{{ t('预计失效时间') }}：{{ anticipatedEffectiveTime }}</div>
        </BkFormItem>
      </DbForm>
    </div>
    <template
      v-if="!submitting && !submitted"
      #action>
      <BkButton
        class="w-88"
        theme="primary"
        @click="submitValidator">
        {{ t('提交') }}
      </BkButton>
      <DbPopconfirm
        :confirm-handler="handleReset"
        :content="t('重置将会清空当前填写的所有内容_请谨慎操作')"
        :title="t('确认重置页面')">
        <BkButton class="ml8 w-88">
          {{ t('重置') }}
        </BkButton>
      </DbPopconfirm>
    </template>
  </SmartAction>
  <InstanceSelector
    v-model="instanceSelectorShow"
    @change="handleInstanceChange" />
  <PasswordSideslider v-model="passwordSidesliderShow" />
  <div
    id="passwordStrength"
    class="password-strength-wrapper">
    <div class="password-strength">
      <div
        v-for="(item, index) of passwordStrength"
        :key="index"
        class="password-strength-item">
        <span
          class="password-strength-status"
          :class="[getStrenthStatus(item)]" />
        <span>{{ item.text }}</span>
      </div>
    </div>
  </div>
  <Teleport to="#dbContentHeaderAppend">
    <div
      ref="subTitleRef"
      class="password-temporary-modify-head">
      <span class="head-subtitle"> ( {{ t('修改的是管理账号的密码') }} ) </span>
      <AuthButton
        v-if="!submitting && !submitted"
        action-id="admin_pwd_view"
        resource="mysql"
        text
        theme="primary"
        @click="passwordSidesliderShow = true">
        <div class="head-button">
          <DbIcon type="history-2 mr-4" />
          <span class="head-button-text">{{ t('临时密码生效的实例') }}</span>
        </div>
      </AuthButton>
    </div>
  </Teleport>
</template>

<script setup lang="tsx">
  import dayjs from 'dayjs';
  import JSEncrypt from 'jsencrypt';
  import _ from 'lodash';
  import type { Instance } from 'tippy.js';
  import { useI18n } from 'vue-i18n';
  import { useRequest } from 'vue-request';

  import {
    getPasswordPolicy,
    getRandomPassword,
    getRSAPublicKeys,
    modifyMysqlAdminPassword,
    queryMysqlAdminPassword,
    verifyPasswordStrength,
  } from '@services/permission';

  import type { ClusterTypes } from '@common/const';
  import { dbTippy } from '@common/tippy';

  import type {
    InstanceSelectorValue,
    InstanceSelectorValues,
  } from './components/password-instance-selector/common/types';
  import InstanceSelector from './components/password-instance-selector/Index.vue';
  import PasswordSideslider from './components/PasswordSideslider.vue';
  import UpdateResult from './components/UpdateResult.vue';

  const getEncyptPassword = () => {
    const encypt = new JSEncrypt();
    encypt.setPublicKey(publicKey);
    const encyptPassword = encypt.encrypt(formData.password);
    return typeof encyptPassword === 'string' ? encyptPassword : '';
  };

  const verifyPassword = () => verifyPasswordStrength({
    password: getEncyptPassword(),
  })
    .then((verifyResult) => {
      passwordValidate.value = verifyResult;
      return verifyResult.is_strength;
    });

  const debounceVerifyPassword = _.debounce(verifyPassword, 300);

  interface StrengthItem {
    keys: string[],
    text: string
  }

  interface TableRow {
    data: InstanceSelectorValue & {
      isExpired: boolean
    },
    index: number
  }

  type PasswordPolicyKeys = keyof typeof PASSWORD_POLICY;
  type PasswordPolicy = ServiceReturnType<typeof getPasswordPolicy>
  type PasswordStrength = ServiceReturnType<typeof verifyPasswordStrength>

  const { t } = useI18n();

  const createDefaultData = () => ({
    instanceList: [] as InstanceSelectorValue[],
    password: '',
    validDuration: 1,
    validDurationType: VALID_DURATION_TYPE.DAY,
  });

  const formatInstance = (instance: {
    cloudId: number,
    ip: string,
    port: number
  }) => `${instance.cloudId}:${instance.ip}:${instance.port}`;

  const VALID_DURATION_TYPE = {
    DAY: 'day',
    HOUR: 'hour',
  };

  const VALID_DURATION_OPTIONS = [
    {
      label: t('天'),
      value: VALID_DURATION_TYPE.DAY,
    },
    {
      label: t('小时'),
      value: VALID_DURATION_TYPE.HOUR,
    },
  ];

  const PASSWORD_POLICY = {
    lowercase: t('包含小写字母'),
    uppercase: t('包含大写字母'),
    numbers: t('包含数字'),
    symbols: t('包含特殊字符_除空格外'),
    follow_keyboards: t('键盘序'),
    follow_letters: t('字母序'),
    follow_numbers: t('数字序'),
    follow_symbols: t('特殊符号序'),
  };

  const passwordRules = [
    {
      trigger: 'blur',
      message: t('密码不满足要求'),
      validator: debounceVerifyPassword,
    },
  ];

  const columns = [
    {
      label: t('实例'),
      field: 'instance_address',
      width: 200,
      render: ({ data }: TableRow) => (
        <div class="password-form-instance">
          <span>{ data.instance_address }</span>
          {
            !data.isExpired && <db-icon
              v-bk-tooltips={ t('当前临时密码未过期，继续修改将会覆盖原来的密码') }
              class='ml-4 instance-tip'
              type="attention-fill" />
          }
        </div>
      ),
    },
    {
      label: t('DB类型'),
      field: 'db_type',
      width: 200,
      render: ({ data }: TableRow) => (
        <>
          <db-icon type={ data.db_type } class='mr-8 type-icon' />
          <span>{ data.cluster_type }</span>
        </>
      ),
    },
    {
      label: t('所属集群'),
      field: 'master_domain',
    },
    {
      label: t('操作'),
      field: 'operations',
      width: 100,
      render: ({ index }: TableRow) => (
        <bk-button
          text
          theme="primary"
          onClick={ () => handleInstanceDelete(index) }>
          { t('删除') }
        </bk-button>
      ),
    },
  ];

  const passwordKeys: string[] = [];
  const passwordFollowKeys: string[] = [];
  let instance: Instance | null = null;
  let publicKey = '';

  Object.keys(PASSWORD_POLICY).forEach((key) => {
    if (key.includes('follow_')) {
      passwordFollowKeys.push(key);
    } else {
      passwordKeys.push(key);
    }
  });

  const passwordStrength = ref<StrengthItem[]>([]);
  const passwordValidate = ref({} as PasswordStrength);
  const submitted = ref(false);
  const submitLength = ref(0);
  const passwordSidesliderShow = ref(false);
  const instanceSelectorShow = ref(false);
  const formRef = ref();
  const passwordRef = ref();
  const passwordItemRef = ref();
  const submitRoleMap = shallowRef<Record<string, string>>({});
  const formData = reactive(createDefaultData());

  const anticipatedEffectiveTime = computed(() => {
    const {
      validDuration,
      validDurationType,
    } = formData;
    const currentDate = dayjs();
    let hours = formData.validDuration;

    if (validDurationType === VALID_DURATION_TYPE.DAY) {
      hours = validDuration * 24;
    }

    return currentDate.add(hours, 'hour').format('YYYY-MM-DD HH:mm');
  });

  useRequest(getRSAPublicKeys, {
    defaultParams: [{ names: ['password'] }],
    onSuccess(publicKeyRes) {
      publicKey = publicKeyRes[0]?.content || '';
    },
  });

  useRequest(getPasswordPolicy, {
    onSuccess(passwordPolicyRes) {
      const {
        min_length: minLength,
        max_length: maxLength,
        include_rule: includeRule,
        exclude_continuous_rule: excludeContinuousRule,
      } = passwordPolicyRes.rule;

      passwordStrength.value = [{
        keys: ['min_length_valid', 'max_length_valid'],
        text: t('密码长度为_min_max', [minLength, maxLength]),
      }];

      for (const passwordKey of passwordKeys) {
        if (includeRule[passwordKey as keyof PasswordPolicy['rule']['include_rule']]) {
          passwordStrength.value.push({
            keys: [`${passwordKey}_valid`],
            text: PASSWORD_POLICY[passwordKey as PasswordPolicyKeys],
          });
        }
      }

      if (excludeContinuousRule.repeats) {
        passwordStrength.value.push({
          keys: ['repeats_valid'],
          text: t('不能连续重复n位字母_数字_特殊符号', { n: excludeContinuousRule.limit }),
        });
      }

      const special = passwordFollowKeys.reduce((values: StrengthItem[], passwordFollowKey: string) => {
        const valueKey = passwordFollowKey.replace('follow_', '') as keyof PasswordPolicy['rule']['exclude_continuous_rule'];
        if (excludeContinuousRule[valueKey]) {
          values.push({
            keys: [`${passwordFollowKey}_valid`],
            text: PASSWORD_POLICY[passwordFollowKey as PasswordPolicyKeys],
          });
        }
        return values;
      }, []);

      if (special.length > 0) {
        const keys: string[] = [];
        const texts: string[] = [];
        for (const item of special) {
          keys.push(...item.keys);
          texts.push(item.text);
        }
        passwordStrength.value.push({
          keys,
          text: texts.join('、'),
        });
      }

      const template = document.getElementById('passwordStrength');
      const content = template?.querySelector?.('.password-strength');
      if (passwordRef.value?.$el && content) {
        const el = passwordRef.value.$el as HTMLDivElement;
        instance?.destroy();
        instance = dbTippy(el, {
          trigger: 'manual',
          theme: 'light',
          content,
          arrow: true,
          placement: 'top-end',
          interactive: true,
          allowHTML: true,
          hideOnClick: false,
          zIndex: 9999,
          onDestroy: () => template?.append?.(content),
          appendTo: () => document.body,
        });
      }
    },
  });

  const {
    run: getRandomPasswordRun,
  } = useRequest(getRandomPassword, {
    manual: true,
    onSuccess(randomPasswordRes) {
      formData.password = randomPasswordRes.password;
    },
  });

  const {
    loading: submitting,
    run: modifyMysqlAdminPasswordRun,
    data: submitRes,
  } = useRequest(modifyMysqlAdminPassword, {
    manual: true,
    onSuccess() {
      submitted.value = true;
      window.changeConfirm = false;
    },
  });

  const {
    run: queryMysqlAdminPasswordRun,
  } = useRequest(queryMysqlAdminPassword, {
    manual: true,
    onSuccess(adminPasswordList) {
      const instanceMap: Record<string, boolean> = {};
      const { instanceList } = formData;

      adminPasswordList.results.forEach((adminPasswordItem) => {
        const instance = formatInstance({
          cloudId: adminPasswordItem.bk_cloud_id,
          ip: adminPasswordItem.ip,
          port: adminPasswordItem.port,
        });

        instanceMap[instance] = false;
      });

      formData.instanceList = instanceList.reduce((newInstanceListPrev, instanceItem) => {
        const instance = formatInstance({
          cloudId: instanceItem.bk_cloud_id,
          ip: instanceItem.ip,
          port: instanceItem.port,
        });

        return [...newInstanceListPrev, {
          ...instanceItem,
          isExpired: instanceMap[instance] === undefined ? true : instanceMap[instance],
        }];
      }, [] as TableRow['data'][]);
    },
    onError(error){
      console.log('error = ', error)
      formData.instanceList = []
    }
  });

  watch(() => formData.password, (newVal) => {
    if (newVal) {
      debounceVerifyPassword();
    }
  });

  const getSmartActionOffsetTarget = () => document.querySelector('.bk-form-content');

  const handleAddInstance = () => {
    instanceSelectorShow.value = true;
  };

  const handleInstanceDelete = (index: number) => {
    formData.instanceList.splice(index, 1);
  };

  const randomlyGenerate = () => {
    getRandomPasswordRun();
  };

  const handlePasswordFocus = () => {
    instance?.show();
    passwordItemRef.value?.clearValidate();
  };

  const handlePasswordBlur = () => {
    instance?.hide();
  };

  const getStrenthStatus = (item: StrengthItem) => {
    if (!passwordValidate.value || Object.keys(passwordValidate.value).length === 0) {
      return '';
    }

    const isPass = item.keys.every((key) => {
      const verifyInfo = passwordValidate.value.password_verify_info || {};
      return verifyInfo[key as keyof PasswordStrength['password_verify_info']];
    });
    return `password-strength-status-${isPass ? 'success' : 'failed'}`;
  };

  const handleInstanceChange = (instanceValues: InstanceSelectorValues) => {
    const instanceList = Object.values(instanceValues)
      .reduce((instanceListPrev, instanceValuesItem) => [...instanceListPrev, ...instanceValuesItem], []);

    queryMysqlAdminPasswordRun({
      instances: instanceList.map(instanceItem => formatInstance({
        cloudId: instanceItem.bk_cloud_id,
        ip: instanceItem.ip,
        port: instanceItem.port,
      })).join(','),
    });
    formData.instanceList = instanceList;
  };

  const submitValidator = async () => {
    await formRef.value.validate();

    handleSubmit(formData.instanceList);
  };

  const handleSubmit = (instanceList: {
    ip: string
    port: number
    bk_cloud_id: number
    cluster_type: ClusterTypes
    role: string
  }[] = []) => {
    const instanceListParam: typeof instanceList = [];
    const roleMap: Record<string, string> = {};
    instanceList.forEach((instance) => {
      const {
        ip,
        port,
        bk_cloud_id,
        role,
        cluster_type,
      } = instance;

      roleMap[`${ip}:${port}`] = role;
      instanceListParam.push({
        ip,
        port,
        bk_cloud_id,
        role,
        cluster_type,
      });
    });

    let lockHour = formData.validDuration;
    if (formData.validDurationType === VALID_DURATION_TYPE.DAY) {
      lockHour = formData.validDuration * 24;
    }

    const params = {
      lock_hour: lockHour,
      password: formData.password,
      instance_list: instanceListParam,
    };

    submitLength.value = instanceListParam.length;
    submitRoleMap.value = roleMap;
    modifyMysqlAdminPasswordRun(params);
  };

  const handleReset = () => {
    Object.assign(formData, createDefaultData());
  };

  const handleRefresh = () => {
    handleReset();
    submitted.value = false;
  };
</script>

<style lang="less" scoped>
  .password-temporary-modify-head {
    display: flex;
    margin-left: 8px;
    flex: 1;
    line-height: 1.7;
    justify-content: space-between;

    .head-subtitle {
      font-size: 12px;
      color: #979ba5;
    }

    .head-button {
      display: flex;
      align-items: center;

      .head-button-text {
        font-size: 12px;
      }
    }
  }

  .password-temporary-modify {
    background-color: #fff;
    border-radius: 2px;
    margin-bottom: 32px;

    .submitting-mask {
      padding: 90px 0 138px;
      text-align: center;

      .submitting-icon {
        font-size: 64px;
        color: @primary-color;
        animation: rotate 2s linear infinite;
      }

      .submitting-text {
        margin-top: 36px;
        font-size: 24px;
        color: #313238;
      }

      @keyframes rotate {
        0% {
          transform: rotate(0deg);
        }

        100% {
          transform: rotate(-360deg);
        }
      }
    }

    .password-form {
      padding: 32px 0 24px;
      box-shadow: 0 3px 4px 0 #0000000a;
      border-radius: 2px;

      :deep(.password-form-instance) {
        display: flex;
        align-items: center;
      }
    }

    .btn-area {
      padding: 24px 0 24px 200px;
      background-color: #f5f7fa;
    }

    :deep(.instance-tip) {
      color: #ff9c01;
    }

    :deep(.type-icon) {
      font-size: 16px;
    }

    .form-item-input {
      min-width: 300px;
    }

    .form-item-suffix {
      width: 88px;
    }

    .password-input {
      border-right: none;
    }

    .anticipated-effective-time {
      font-size: 12px;
      line-height: 12px;
    }
  }

  .password-strength-wrapper {
    position: relative;
    z-index: -1;
    display: none;
  }

  .password-strength {
    padding-top: 4px;
    font-size: @font-size-mini;

    .password-strength-item {
      display: flex;
      padding-bottom: 4px;
      align-items: center;
    }

    .password-strength-status {
      width: 6px;
      height: 6px;
      margin-right: 8px;
      background-color: @bg-disable;
      border-radius: 50%;
    }

    .password-strength-status-success {
      background-color: @bg-success;
    }

    .password-strength-status-failed {
      background-color: @bg-danger;
    }
  }
</style>

<!-- <style>
.main-breadcrumbs-current {
  width: 100%;
  margin-right: 0 !important;

  #dbmPageSubtitle {
    flex: 1;
  }
}
</style> -->
