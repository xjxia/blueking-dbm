<template>
  <NoticeComponent :api-url="noticeApi" />
  <Layout>
    <template #navigationHeaderRight>
      <SystemSearch
        class="mr-8"
        style="margin-left: auto" />
      <LocaleSwitch />
      <BkPopover
        placement="bottom"
        theme="light top-action-menu-theme"
        @after-hidden="isShowHelp = false"
        @after-show="isShowHelp = true">
        <div class="top-action-btn mr-8">
          <DbIcon type="help-fill" />
        </div>
        <template #content>
          <div
            class="item"
            @click="handleShowSystemVersionLog">
            {{ t('版本日志') }}
          </div>
        </template>
      </BkPopover>
      <BkPopover
        placement="bottom"
        theme="light top-action-menu-theme"
        @after-hidden="isShowLogout = false"
        @after-show="isShowLogout = true">
        <div class="user-info-box">
          <span class="username-text">{{ userProfileStore.username }}</span>
          <DbIcon
            class="user-info-arrow"
            :class="{
              'is-active': isShowLogout,
            }"
            type="down-shape" />
        </div>
        <template #content>
          <div
            class="item"
            @click="handleSignOut">
            {{ t('退出登录') }}
          </div>
        </template>
      </BkPopover>
    </template>
    <template #content-header>
      <RouterBack />
    </template>
    <DbRouterView style="height: 100%" />
  </Layout>
  <SystemVersionLog v-model:is-show="isShowSystemVersionLog" />
</template>
<script setup lang="ts">
  import InfoBox from 'bkui-vue/lib/info-box';
  import urlJoin from 'url-join';
  import { onMounted, watch } from 'vue';
  import { useI18n } from 'vue-i18n';

  import { getLogout } from '@services/source/logout';

  import { useSQLTaskNotify } from '@hooks';

  import { useFunController,useUserProfile } from '@stores';

  import DbRouterView from '@components/db-router-view/Index.vue';
  import LocaleSwitch from '@components/locale-switch/Index.vue';
  import RouterBack from '@components/router-back/Index.vue';
  import SystemSearch from '@components/system-search/Index.vue';
  import SystemVersionLog from '@components/system-version-log/Index.vue';

  import NoticeComponent from '@blueking/notice-component';

  import Layout from './layout/Index.vue';

  import '@blueking/notice-component/dist/style.css';

  const userProfileStore = useUserProfile();
  userProfileStore.fetchProfile();
  const { t, locale } = useI18n();
  const { funControllerData } = useFunController();

  const documentTitles: Record<string, string> = {
    en: 'DBM | Tencent BlueKing',
    'zh-cn': '数据库管理 | 腾讯蓝鲸智云',
  };

  const noticeApi = urlJoin(window.PROJECT_ENV.VITE_AJAX_URL_PREFIX, '/notice/announcements/');
  const isShowHelp = ref(false);
  const isShowLogout = ref(false);
  const isShowSystemVersionLog = ref(false);

  watch(
    locale,
    () => {
      document.title = documentTitles[locale.value];
    },
    { immediate: true },
  );

  const handleShowSystemVersionLog = () => {
    isShowSystemVersionLog.value = true;
  };

  const handleSignOut = () => {
    InfoBox({
      title: t('确认退出登录'),
      onConfirm: () =>
        getLogout().then(() => {
          window.changeConfirm = false;
          window.location.reload();
          return true;
        }),
    });
  };

  onMounted(() => {
    if (funControllerData.getFlatData('mysql').toolbox) {
      useSQLTaskNotify();
    }
  });
</script>
<style lang="less">
  .bk-popover[data-theme~='top-action-menu-theme'] {
    padding-right: 0 !important;
    padding-left: 0 !important;

    .item {
      display: flex;
      height: 32px;
      padding: 0 16px;
      font-size: 12px;
      color: #63656e;
      cursor: pointer;
      align-items: center;

      &.active,
      &:hover {
        color: #3a84ff;
        background-color: #eaf3ff;
      }
    }
  }

  .top-action-btn {
    position: relative;
    display: inline-flex;
    width: 32px;
    height: 32px;
    font-size: 16px;
    color: #979ba5;
    cursor: pointer;
    border-radius: 50%;
    transition: background 0.15s;
    align-items: center;
    justify-content: center;

    &:hover,
    &.active {
      color: @primary-color;
      background-color: #f0f1f5;
    }
  }

  .user-info-box {
    cursor: pointer;

    .username-text {
      padding-right: 4px;
    }

    .user-info-arrow {
      display: inline-block;
      font-size: 12px;
      transition: all 0.2s;

      &.is-active {
        transform: rotate(180deg);
      }
    }
  }
</style>
