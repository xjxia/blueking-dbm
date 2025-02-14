import type { HostInfo, InstanceListSpecConfig, InstanceRelatedCluster } from '@services/types';

import { ClusterTypes } from '@common/const';

export default class RiakInstance {
  bk_cloud_id: number;
  bk_cloud_name: string;
  bk_host_id: number;
  bk_os_name: string;
  bk_rack_id: number;
  bk_sub_zone: string;
  bk_sub_zone_id: number;
  bk_svr_device_cls_name: string;
  cluster_id: number;
  cluster_name: string;
  cluster_type: ClusterTypes;
  create_at: string;
  db_module_id: number;
  db_module_name: string;
  host_info: HostInfo;
  id: number;
  instance_address: string;
  ip: string;
  master_domain: string;
  port: number;
  related_clusters: InstanceRelatedCluster[];
  role: string;
  slave_domain: string;
  spec_config: InstanceListSpecConfig;
  status: string;
  version: string;

  constructor(payload = {} as RiakInstance) {
    this.bk_cloud_id = payload.bk_cloud_id;
    this.bk_cloud_name = payload.bk_cloud_name;
    this.bk_host_id = payload.bk_host_id;
    this.bk_os_name = payload.bk_os_name;
    this.bk_rack_id = payload.bk_rack_id;
    this.bk_sub_zone = payload.bk_sub_zone;
    this.bk_sub_zone_id = payload.bk_sub_zone_id;
    this.bk_svr_device_cls_name = payload.bk_svr_device_cls_name;
    this.cluster_id = payload.cluster_id;
    this.cluster_name = payload.cluster_name;
    this.cluster_type = payload.cluster_type;
    this.create_at = payload.create_at;
    this.db_module_id = payload.db_module_id;
    this.db_module_name = payload.db_module_name;
    this.host_info = payload.host_info || {};
    this.id = payload.id;
    this.instance_address = payload.instance_address;
    this.ip = payload.ip;
    this.master_domain = payload.master_domain;
    this.port = payload.port;
    this.related_clusters = payload.related_clusters || [];
    this.role = payload.role;
    this.slave_domain = payload.slave_domain;
    this.spec_config = payload.spec_config;
    this.status = payload.status;
    this.version = payload.version;
  }
}
