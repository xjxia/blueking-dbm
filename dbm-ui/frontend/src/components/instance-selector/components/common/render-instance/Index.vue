<template>
  <div class="instance-renderer">
    <div
      v-for="item in displayList"
      :key="item.instance"
      class="instance-item">
      <DbStatus :theme="item.theme" />
      <span>{{ item.instance }}</span>
    </div>
    <BkButton
      v-if="data.length >= 3"
      class="ml-20"
      text
      theme="primary"
      @click.stop="showAll = !showAll">
      {{ showAll ? t('收起') : t('更多') }}
      <DbIcon
        class="show-all-icon"
        :type="showAll ? 'up-big' : 'down-big'" />
    </BkButton>
  </div>
</template>

<script setup lang="ts">
  import { useI18n } from 'vue-i18n';

  import DbStatus from '@components/db-status/index.vue';

  interface Props {
    data: {
      instance: string;
      status: string;
    }[];
  }

  const props = defineProps<Props>();

  const { t } = useI18n();

  const showAll = ref(false);

  const getStatusInfo = (status: string) => (status === 'running' ? 'success' : 'danger');

  const displayList = computed(() => {
    const formatDataList = props.data.map((dataItem) => ({
      ...dataItem,
      theme: getStatusInfo(dataItem.status),
    }));
    return showAll.value ? formatDataList : formatDataList.slice(0, 3);
  });
</script>

<style lang="less" scoped>
  .instance-renderer {
    .instance-item {
      height: 20px;
    }

    .show-all-icon {
      font-size: 16px;
      margin-left: 2px;
    }
  }
</style>
