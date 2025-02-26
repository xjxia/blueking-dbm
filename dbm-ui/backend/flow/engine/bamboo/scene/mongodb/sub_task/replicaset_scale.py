# -*- coding: utf-8 -*-
"""
TencentBlueKing is pleased to support the open source community by making 蓝鲸智云-DB管理系统(BlueKing-BK-DBM) available.
Copyright (C) 2017-2023 THL A29 Limited, a Tencent company. All rights reserved.
Licensed under the MIT License (the "License"); you may not use this file except in compliance with the License.
You may obtain a copy of the License at https://opensource.org/licenses/MIT
Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on
an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the
specific language governing permissions and limitations under the License.
"""

from copy import deepcopy
from typing import Dict, Optional

from django.utils.translation import ugettext as _

from backend.db_meta.enums.cluster_type import ClusterType
from backend.flow.consts import MongoDBClusterRole
from backend.flow.engine.bamboo.scene.common.builder import SubBuilder
from backend.flow.engine.bamboo.scene.mongodb.mongodb_install import install_plugin
from backend.flow.plugins.components.collections.mongodb.exec_actuator_job import ExecuteDBActuatorJobComponent
from backend.flow.plugins.components.collections.mongodb.send_media import ExecSendMediaOperationComponent
from backend.flow.utils.mongodb.mongodb_dataclass import ActKwargs

from .mongod_replace import mongod_replace


def replicaset_scale(
    root_id: str, ticket_data: Optional[Dict], sub_kwargs: ActKwargs, info: dict, cluster_role: str
) -> SubBuilder:
    """
    replicaset 容量变更流程
    info 表示replicaset信息
    """

    # 获取变量
    sub_get_kwargs = deepcopy(sub_kwargs)

    # 创建子流程
    sub_pipeline = SubBuilder(root_id=root_id, data=ticket_data)

    if not cluster_role:
        # 获取集群信息并计算对应关系
        sub_get_kwargs.calc_scale(info=info)

        # 获取主机信息
        sub_get_kwargs.get_host_scale(mongodb_type=ClusterType.MongoReplicaSet.value, info=info)

        # 安装蓝鲸插件
        install_plugin(pipeline=sub_pipeline, get_kwargs=sub_get_kwargs, new_cluster=False)

        # 介质下发
        kwargs = sub_get_kwargs.get_send_media_kwargs(media_type="all")
        sub_pipeline.add_act(
            act_name=_("MongoDB-介质下发"), act_component_code=ExecSendMediaOperationComponent.code, kwargs=kwargs
        )

        # 创建原子任务执行目录
        kwargs = sub_get_kwargs.get_create_dir_kwargs()
        sub_pipeline.add_act(
            act_name=_("MongoDB-创建原子任务执行目录"), act_component_code=ExecuteDBActuatorJobComponent.code, kwargs=kwargs
        )

        # 机器初始化
        kwargs = sub_get_kwargs.get_os_init_kwargs()
        sub_pipeline.add_act(
            act_name=_("MongoDB-机器初始化"), act_component_code=ExecuteDBActuatorJobComponent.code, kwargs=kwargs
        )

    instance_relationships = sub_get_kwargs.payload["instance_relationships"]
    sub_get_kwargs.calc_param_replace(
        info=instance_relationships[0], instance_num=instance_relationships[0].get("node_replica_count", 0)
    )

    # 复制集进行替换——串行
    # backup节点优先替换
    instance_relationships.reverse()
    for instance_relationship in instance_relationships:
        sub_get_kwargs.db_instance = instance_relationship["instances"][0]
        instance_relationship["db_type"] = "replicaset_mongodb"
        sub_sub_pipeline = mongod_replace(
            root_id=root_id,
            ticket_data=ticket_data,
            sub_sub_kwargs=sub_get_kwargs,
            cluster_role=cluster_role,
            info=instance_relationship,
            mongod_scale=True,
        )
        sub_pipeline.add_sub_pipeline(sub_sub_pipeline)

    if not cluster_role:
        name = "replicaset"
    else:
        if cluster_role == MongoDBClusterRole.ShardSvr.value:
            name = "shard"
    return sub_pipeline.build_sub_process(sub_name=_("MongoDB--{}容量变更".format(name)))
