<template>
  <FunController module-id="redis">
    <BkMenuGroup name="Redis">
      <BkSubmenu
        key="RedisManage"
        :title="t('集群')">
        <template #icon>
          <DbIcon type="fenbushijiqun" />
        </template>
        <BkMenuItem key="DatabaseRedisList">
          <span
            v-overflow-tips.right
            class="text-overflow">
            {{ t('集群管理') }}
          </span>
        </BkMenuItem>
        <BkMenuItem
          key="DatabaseRedisInstanceList"
          v-db-console="'redis.instanceManage'">
          <span
            v-overflow-tips.right
            class="text-overflow">
            {{ t('实例视图') }}
          </span>
        </BkMenuItem>
      </BkSubmenu>
      <BkSubmenu
        key="RedisHaManage"
        v-db-console="'redis.haClusterManage'"
        :title="t('主从')">
        <template #icon>
          <DbIcon type="cluster" />
        </template>
        <BkMenuItem key="DatabaseRedisHaList">
          <span
            v-overflow-tips.right
            class="text-overflow">
            {{ t('主从管理') }}
          </span>
        </BkMenuItem>
        <BkMenuItem
          key="DatabaseRedisHaInstanceList"
          v-db-console="'redis.haInstanceManage'">
          <span
            v-overflow-tips.right
            class="text-overflow">
            {{ t('实例视图') }}
          </span>
        </BkMenuItem>
      </BkSubmenu>
      <div
        v-if="Object.keys(favorMeunMap).length > 0"
        class="split-line" />
      <ToolboxMenu
        v-for="toolboxGroupId in toolboxMenuSortList"
        :id="toolboxGroupId"
        :key="toolboxGroupId"
        v-db-console="'redis.toolbox'"
        :favor-map="favorMeunMap"
        :toolbox-menu-config="toolboxMenuConfig" />
      <FunController
        controller-id="toolbox"
        module-id="redis">
        <BkMenuItem
          key="RedisToolbox"
          v-db-console="'redis.toolbox'">
          <template #icon>
            <DbIcon type="tools" />
          </template>
          <span
            v-overflow-tips.right
            class="text-overflow">
            {{ t('工具箱') }}
          </span>
        </BkMenuItem>
      </FunController>
    </BkMenuGroup>
  </FunController>
</template>
<script setup lang="ts">
  import { onBeforeUnmount, shallowRef } from 'vue';
  import { useI18n } from 'vue-i18n';

  import { useEventBus } from '@hooks';

  import { useUserProfile } from '@stores';

  import { UserPersonalSettings } from '@common/const';

  import toolboxMenuConfig from '@views/redis/toolbox-menu';

  import { makeMap } from '@utils';

  import ToolboxMenu from './components/ToolboxMenu.vue';

  const userProfile = useUserProfile();
  const { t } = useI18n();
  const eventBus = useEventBus();

  const toolboxMenuSortList = shallowRef<string[]>([]);
  const favorMeunMap = shallowRef<Record<string, boolean>>({});

  const renderToolboxMenu = () => {
    toolboxMenuSortList.value =
      userProfile.profile[UserPersonalSettings.REDIS_TOOLBOX_MENUS] || toolboxMenuConfig.map((item) => item.id);
    favorMeunMap.value = makeMap(userProfile.profile[UserPersonalSettings.REDIS_TOOLBOX_FAVOR]);
  };

  renderToolboxMenu();

  eventBus.on('REDIS_TOOLBOX_CHANGE', renderToolboxMenu);

  onBeforeUnmount(() => {
    eventBus.off('REDIS_TOOLBOX_CHANGE', renderToolboxMenu);
  });
</script>
