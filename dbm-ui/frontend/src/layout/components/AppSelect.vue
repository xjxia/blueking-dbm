<template>
  <DbAppSelect
    :list="bizList"
    :model-value="currentBiz"
    style="margin: 0 12px"
    theme="dark"
    @change="handleAppChange">
  </DbAppSelect>
</template>
<script setup lang="ts">
  import _ from 'lodash';
  import {
    computed,
  } from 'vue';
  import {
    useRoute,
    useRouter,
  } from 'vue-router';

  import { getBizs } from '@services/source/cmdb';

  import {
    useGlobalBizs,
  } from '@stores';

  import DbAppSelect from '@components/db-app-select/Index.vue';

  type IAppItem = ServiceReturnType<typeof getBizs>[number]

  const route = useRoute();
  const router = useRouter();

  const {
    bizs: bizList,
  } = useGlobalBizs();

  const currentBiz = computed(() => _.find(bizList, item => item.bk_biz_id === window.PROJECT_CONFIG.BIZ_ID));

  const handleAppChange = (appInfo: IAppItem) => {
    const {
      bk_biz_id: bkBizId,
    } = appInfo;

    const pathRoot = `/${bkBizId}`;
    if (!window.PROJECT_CONFIG.BIZ_ID) {
      window.location.href = pathRoot;
      return;
    }

    const reload = (targetPath: string) => {
      setTimeout(() => {
        const path = targetPath.replace(/^\/[\d]+/, pathRoot);
        window.location.href = path;
      }, 100);
    };
    // 1，当前路由不带参数，切换业务时停留在当前页面
    let currentRouteHasNotParams = true;
    Object.keys(route.params).forEach((paramKey) => {
      if (route.params[paramKey] === undefined || route.params[paramKey] === null) {
        return;
      }
      currentRouteHasNotParams = false;
    });
    if (currentRouteHasNotParams) {
      reload(route.path);
      return;
    }
    const { matched } = route;
    // 2，当前路由带有请求参数，切换业务时则需要做回退处理
    // 路由只匹配到了一个
    if (matched.length < 2) {
      const [{ path }] = matched;
      reload(path);
      return;
    }

    // 路由有多层嵌套
    const {
      path,
      redirect,
    } = matched[1];
    // 重定向到指定的路由path
    if (_.isString(redirect)) {
      reload(redirect);
      return;
    }
    // 重定向到指定的路由name
    if (redirect && _.isPlainObject(redirect)) {
      const redirectName = (redirect as {name: string}).name;
      if (redirectName) {
        const route = router.resolve({
          name: redirectName,
        });
        reload(route.href);
        return;
      }
    }
    reload(path);
  };
</script>
