<template>
  <div
    class="es-cluster-replace-resource-pool-selector"
    :class="{
      'is-error': error,
    }">
    <div class="mr-8">
      <span>{{ t('匹配规格') }}</span>
      <span style="color: #ea3636">*</span>
    </div>
    <div class="select-box">
      <BkSelect
        :loading="isResourceSpecLoading"
        :model-value="modelValue.spec_id || undefined"
        :placeholder="t('请选择匹配规格')"
        @change="handleChange">
        <BkOption
          v-for="item in resourceSpecList?.results"
          :key="item.spec_id"
          :label="item.spec_name"
          :value="item.spec_id">
          <BkPopover
            :offset="20"
            placement="right"
            theme="light"
            width="580">
            <div style="display: flex; width: 100%; align-items: center">
              <div>{{ item.spec_name }}</div>
              <BkTag style="margin-left: auto">
                {{ specCountMap[item.spec_id] }}
              </BkTag>
            </div>
            <template #content>
              <SpecDetail :data="item" />
            </template>
          </BkPopover>
        </BkOption>
      </BkSelect>
      <div
        v-if="error"
        v-bk-tooltips="t('请选择匹配规格')"
        class="error-tips">
        <DbIcon type="exclamation-fill" />
      </div>
    </div>
  </div>
</template>
<script setup lang="ts">
  import { shallowRef } from 'vue';
  import { useI18n } from 'vue-i18n';
  import { useRequest } from 'vue-request';

  import { getSpecResourceCount } from '@services/source/dbresourceResource';
  import { fetchRecommendSpec, getResourceSpecList } from '@services/source/dbresourceSpec';

  import SpecDetail from '@components/cluster-common/SpecDetailForPopover.vue';

  import type { TReplaceNode } from '../Index.vue';

  interface Props {
    data: TReplaceNode;
    error: boolean;
    cloudInfo: {
      id: number;
      name: string;
    };
  }

  const props = defineProps<Props>();

  const modelValue = defineModel<TReplaceNode['resourceSpec']>({
    required: true,
  });

  const { t } = useI18n();

  const specCountMap = shallowRef<Record<number, number>>({});

  const { run: fetchSpecResourceCount } = useRequest(getSpecResourceCount, {
    manual: true,
    onSuccess(data) {
      specCountMap.value = data;
    },
  });

  const { loading: isResourceSpecLoading, data: resourceSpecList } = useRequest(getResourceSpecList, {
    defaultParams: [
      {
        spec_cluster_type: props.data.specClusterType,
        spec_machine_type: props.data.specMachineType,
        limit: -1,
      },
    ],
    onSuccess(data) {
      fetchSpecResourceCount({
        bk_biz_id: window.PROJECT_CONFIG.BIZ_ID,
        bk_cloud_id: props.cloudInfo.id,
        spec_ids: data.results.map((item) => item.spec_id),
      });
    },
  });

  useRequest(fetchRecommendSpec, {
    defaultParams: [
      {
        cluster_id: props.data.clusterId,
        role: props.data.role,
      },
    ],
    onSuccess(recommendSpecList) {
      if (recommendSpecList.length > 0) {
        modelValue.value.spec_id = recommendSpecList[0].spec_id;
      }
    },
  });

  const handleChange = (value: number) => {
    modelValue.value = {
      spec_id: value,
      count: props.data.nodeList.length,
      instance_num: resourceSpecList.value?.results.find((item) => item.spec_id === value)?.instance_num ?? 1,
    };
  };
</script>
<style lang="less">
  .es-cluster-replace-resource-pool-selector {
    display: flex;
    align-items: center;
    justify-content: center;

    .bk-select {
      width: 240px;
    }

    &.is-error {
      .bk-select {
        .bk-input {
          border-color: #ea3636;
        }
      }
    }

    .select-box {
      position: relative;

      .error-tips {
        position: absolute;
        top: 50%;
        right: 9px;
        color: #ea3636;
        transform: translateY(-50%);
      }
    }
  }
</style>
