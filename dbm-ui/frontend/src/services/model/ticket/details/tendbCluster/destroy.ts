import type { DetailBase, DetailClusters } from '../common';

export interface Destroy extends DetailBase {
  clusters: DetailClusters;
  cluster_ids: number[];
  force: boolean;
  is_only_add_slave_domain: boolean;
  is_only_delete_slave_domain: boolean;
}