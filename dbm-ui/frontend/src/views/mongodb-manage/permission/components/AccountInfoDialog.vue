<template>
  <BkDialog
    dialog-type="show"
    :draggable="false"
    :is-show="isShow"
    quick-close
    :title="t('账号信息')"
    :width="480"
    @closed="handleClose">
    <div class="mongo-account-details">
      <div class="mongo-account-details">
        <div
          v-for="column of accountColumns"
          :key="column.key"
          class="details-item">
          <div class="details-label">{{ column.label }}：</div>
          <div class="details-value">
            {{ column.value ?? props.info?.account?.[column.key] }}
          </div>
        </div>
        <div
          v-if="isDelete"
          class="details-item">
          <span class="details-label" />
          <span class="details-value">
            <BkButton
              hover-theme="danger"
              @click="handleDeleteAccount()">
              {{ t('删除账号') }}
            </BkButton>
          </span>
        </div>
      </div>
    </div>
  </BkDialog>
</template>

<script setup lang="ts">
  import { useI18n } from 'vue-i18n';

  import MongodbPermissonAccountModel from '@services/model/mongodb-permission/mongodb-permission-account';

  import { useDeleteAccount } from '../hooks/useDeleteAccount';

  interface Props {
    info: MongodbPermissonAccountModel;
  }

  interface Emits {
    (e: 'deleteAccount'): void;
  }

  const props = defineProps<Props>();
  const emits = defineEmits<Emits>();
  const isShow = defineModel<boolean>({
    required: true,
    default: false,
  });

  const { t } = useI18n();
  const { deleteAccountReq } = useDeleteAccount();

  const accountColumns: Array<{
    label: string;
    key: keyof MongodbPermissonAccountModel['account'];
    value?: string;
  }> = [
    {
      label: t('账号名'),
      key: 'user',
    },
    {
      label: t('密码'),
      key: 'password',
      value: '****************',
    },
    {
      label: t('创建时间'),
      key: 'create_time',
    },
    {
      label: t('创建人'),
      key: 'creator',
    },
  ];

  const isDelete = computed(() => !props.info?.rules?.length);

  const handleDeleteAccount = () => {
    const { user, account_id: accountId } = props.info.account;

    deleteAccountReq(user, accountId, () => {
      emits('deleteAccount');
    });
  };

  const handleClose = () => {
    isShow.value = false;
  };
</script>

<style lang="less" scoped>
  .mongo-account-details {
    font-size: @font-size-mini;

    .details-item {
      display: flex;
      padding-bottom: 16px;
    }

    .details-label {
      width: 90px;
      text-align: right;
      flex-shrink: 0;
    }

    .details-value {
      color: @title-color;
    }
  }
</style>
