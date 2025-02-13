DELETE FROM tb_config_name_def WHERE namespace = 'tendb' AND  conf_type = 'mysql_monitor' AND conf_file = 'items-config.yaml';
REPLACE INTO tb_config_name_def( namespace, conf_type, conf_file, conf_name, value_type, value_default, value_allowed, value_type_sub, flag_status, flag_disable, flag_locked, flag_encrypt, need_restart) VALUES( 'tendb', 'mysql_monitor', 'items-config.yaml', 'character-consistency', 'STRING', '{"role":[],"schedule":"0 0 14 * * 1","enable":true,"machine_type":["single","backend","remote","spider"],"name":"character-consistency"}', '', 'MAP', 1, 0, 0, 0, 1);
REPLACE INTO tb_config_name_def( namespace, conf_type, conf_file, conf_name, value_type, value_default, value_allowed, value_type_sub, flag_status, flag_disable, flag_locked, flag_encrypt, need_restart) VALUES( 'tendb', 'mysql_monitor', 'items-config.yaml', 'routine-definer', 'STRING', '{"machine_type":["single","backend","remote"],"name":"routine-definer","enable":true,"schedule":"0 0 15 * * 1","role":[]}', '', 'MAP', 1, 0, 0, 0, 1);
REPLACE INTO tb_config_name_def( namespace, conf_type, conf_file, conf_name, value_type, value_default, value_allowed, value_type_sub, flag_status, flag_disable, flag_locked, flag_encrypt, need_restart) VALUES( 'tendb', 'mysql_monitor', 'items-config.yaml', 'view-definer', 'STRING', '{"enable":true,"machine_type":["single","backend","remote"],"name":"view-definer","role":[],"schedule":"0 0 15 * * 1"}', '', 'MAP', 1, 0, 0, 0, 1);
REPLACE INTO tb_config_name_def( namespace, conf_type, conf_file, conf_name, value_type, value_default, value_allowed, value_type_sub, flag_status, flag_disable, flag_locked, flag_encrypt, need_restart) VALUES( 'tendb', 'mysql_monitor', 'items-config.yaml', 'trigger-definer', 'STRING', '{"machine_type":["single","backend","remote"],"name":"trigger-definer","enable":true,"schedule":"0 0 15 * * 1","role":[]}', '', 'MAP', 1, 0, 0, 0, 1);
REPLACE INTO tb_config_name_def( namespace, conf_type, conf_file, conf_name, value_type, value_default, value_allowed, value_type_sub, flag_status, flag_disable, flag_locked, flag_encrypt, need_restart) VALUES( 'tendb', 'mysql_monitor', 'items-config.yaml', 'engine', 'STRING', '{"schedule":"0 10 1 * * *","role":["slave","orphan"],"machine_type":["single","backend","remote"],"name":"engine","enable":true}', '', 'MAP', 1, 0, 0, 0, 1);
REPLACE INTO tb_config_name_def( namespace, conf_type, conf_file, conf_name, value_type, value_default, value_allowed, value_type_sub, flag_status, flag_disable, flag_locked, flag_encrypt, need_restart) VALUES( 'tendb', 'mysql_monitor', 'items-config.yaml', 'ext3-check', 'STRING', '{"schedule":"0 0 16 * * 1","role":[],"name":"ext3-check","machine_type":["single","backend","remote"],"enable":true}', '', 'MAP', 1, 0, 0, 0, 1);
REPLACE INTO tb_config_name_def( namespace, conf_type, conf_file, conf_name, value_type, value_default, value_allowed, value_type_sub, flag_status, flag_disable, flag_locked, flag_encrypt, need_restart) VALUES( 'tendb', 'mysql_monitor', 'items-config.yaml', 'ibd-statistic', 'STRING', '{"name":"ibd-statistic","machine_type":["single","backend","remote"],"enable":true,"schedule":"0 45 23 * * *","role":["slave","orphan"],"options":{"topk_num":"0","disable_merge_rules":"","disable_merge_partition":"","merge_rules":[{"to":"${db}_MERGED._MERGED","from":"(?P<db>stage_truncate_).+\\..*"},{"from":"(?P<db>bak_20\\d\\d).+\\..*","to":"${db}_MERGED._MERGED"},{"to":"${1}_MERGED.${table}","from":"(bak_cbs)_.+\\.(?P<table>.+)"}]}}', '', 'MAP', 1, 0, 0, 0, 1);
REPLACE INTO tb_config_name_def( namespace, conf_type, conf_file, conf_name, value_type, value_default, value_allowed, value_type_sub, flag_status, flag_disable, flag_locked, flag_encrypt, need_restart) VALUES( 'tendb', 'mysql_monitor', 'items-config.yaml', 'master-slave-heartbeat', 'STRING', '{"schedule":"@every 1m","role":["master","repeater","slave","spider_master"],"name":"master-slave-heartbeat","machine_type":["backend","remote","spider"],"enable":true}', '', 'MAP', 1, 0, 0, 0, 1);
REPLACE INTO tb_config_name_def( namespace, conf_type, conf_file, conf_name, value_type, value_default, value_allowed, value_type_sub, flag_status, flag_disable, flag_locked, flag_encrypt, need_restart) VALUES( 'tendb', 'mysql_monitor', 'items-config.yaml', 'mysql-config-diff', 'STRING', '{"schedule":"0 5 10 * * *","role":[],"machine_type":["single","backend","remote","spider"],"name":"mysql-config-diff","enable":true}', '', 'MAP', 1, 0, 0, 0, 1);
REPLACE INTO tb_config_name_def( namespace, conf_type, conf_file, conf_name, value_type, value_default, value_allowed, value_type_sub, flag_status, flag_disable, flag_locked, flag_encrypt, need_restart) VALUES( 'tendb', 'mysql_monitor', 'items-config.yaml', 'mysql-connlog-size', 'STRING', '{"role":[],"schedule":"0 0 12 * * *","enable":false,"machine_type":["single","backend","remote","spider"],"name":"mysql-connlog-size"}', '', 'MAP', 1, 0, 0, 0, 1);
REPLACE INTO tb_config_name_def( namespace, conf_type, conf_file, conf_name, value_type, value_default, value_allowed, value_type_sub, flag_status, flag_disable, flag_locked, flag_encrypt, need_restart) VALUES( 'tendb', 'mysql_monitor', 'items-config.yaml', 'mysql-connlog-rotate', 'STRING', '{"role":[],"schedule":"0 30 23 * * *","enable":false,"machine_type":["single","backend","remote","spider"],"name":"mysql-connlog-rotate"}', '', 'MAP', 1, 0, 0, 0, 1);
REPLACE INTO tb_config_name_def( namespace, conf_type, conf_file, conf_name, value_type, value_default, value_allowed, value_type_sub, flag_status, flag_disable, flag_locked, flag_encrypt, need_restart) VALUES( 'tendb', 'mysql_monitor', 'items-config.yaml', 'mysql-err-notice', 'STRING', '{"schedule":"@every 1m","role":[],"name":"mysql-err-notice","machine_type":["single","backend","remote"],"enable":false}', '', 'MAP', 1, 0, 0, 0, 1);
REPLACE INTO tb_config_name_def( namespace, conf_type, conf_file, conf_name, value_type, value_default, value_allowed, value_type_sub, flag_status, flag_disable, flag_locked, flag_encrypt, need_restart) VALUES( 'tendb', 'mysql_monitor', 'items-config.yaml', 'mysql-err-critical', 'STRING', '{"name":"mysql-err-critical","machine_type":["single","backend","remote"],"enable":false,"schedule":"@every 1m","role":[]}', '', 'MAP', 1, 0, 0, 0, 1);
REPLACE INTO tb_config_name_def( namespace, conf_type, conf_file, conf_name, value_type, value_default, value_allowed, value_type_sub, flag_status, flag_disable, flag_locked, flag_encrypt, need_restart) VALUES( 'tendb', 'mysql_monitor', 'items-config.yaml', 'spider-err-notice', 'STRING', '{"schedule":"@every 1m","role":[],"machine_type":["spider"],"name":"spider-err-notice","enable":false}', '', 'MAP', 1, 0, 0, 0, 1);
REPLACE INTO tb_config_name_def( namespace, conf_type, conf_file, conf_name, value_type, value_default, value_allowed, value_type_sub, flag_status, flag_disable, flag_locked, flag_encrypt, need_restart) VALUES( 'tendb', 'mysql_monitor', 'items-config.yaml', 'spider-err-warn', 'STRING', '{"enable":false,"machine_type":["spider"],"name":"spider-err-warn","role":[],"schedule":"@every 1m"}', '', 'MAP', 1, 0, 0, 0, 1);
REPLACE INTO tb_config_name_def( namespace, conf_type, conf_file, conf_name, value_type, value_default, value_allowed, value_type_sub, flag_status, flag_disable, flag_locked, flag_encrypt, need_restart) VALUES( 'tendb', 'mysql_monitor', 'items-config.yaml', 'spider-err-critical', 'STRING', '{"enable":false,"name":"spider-err-critical","machine_type":["spider"],"role":[],"schedule":"@every 1m"}', '', 'MAP', 1, 0, 0, 0, 1);
REPLACE INTO tb_config_name_def( namespace, conf_type, conf_file, conf_name, value_type, value_default, value_allowed, value_type_sub, flag_status, flag_disable, flag_locked, flag_encrypt, need_restart) VALUES( 'tendb', 'mysql_monitor', 'items-config.yaml', 'mysqld-restarted', 'STRING', '{"machine_type":["single","backend","remote","spider"],"name":"mysqld-restarted","enable":true,"schedule":"@every 1m","role":[]}', '', 'MAP', 1, 0, 0, 0, 1);
REPLACE INTO tb_config_name_def( namespace, conf_type, conf_file, conf_name, value_type, value_default, value_allowed, value_type_sub, flag_status, flag_disable, flag_locked, flag_encrypt, need_restart) VALUES( 'tendb', 'mysql_monitor', 'items-config.yaml', 'mysql-lock', 'STRING', '{"role":["master","slave","spider_master","orphan"],"schedule":"@every 1m","enable":true,"machine_type":["single","backend","remote","spider"],"name":"mysql-lock"}', '', 'MAP', 1, 0, 0, 0, 1);
REPLACE INTO tb_config_name_def( namespace, conf_type, conf_file, conf_name, value_type, value_default, value_allowed, value_type_sub, flag_status, flag_disable, flag_locked, flag_encrypt, need_restart) VALUES( 'tendb', 'mysql_monitor', 'items-config.yaml', 'mysql-inject', 'STRING', '{"schedule":"@every 1m","role":[],"machine_type":["single","backend","spider"],"name":"mysql-inject","enable":true}', '', 'MAP', 1, 0, 0, 0, 1);
REPLACE INTO tb_config_name_def( namespace, conf_type, conf_file, conf_name, value_type, value_default, value_allowed, value_type_sub, flag_status, flag_disable, flag_locked, flag_encrypt, need_restart) VALUES( 'tendb', 'mysql_monitor', 'items-config.yaml', 'proxy-backend', 'STRING', '{"schedule":"@every 1m","role":[],"machine_type":["proxy"],"name":"proxy-backend","enable":true}', '', 'MAP', 1, 0, 0, 0, 1);
REPLACE INTO tb_config_name_def( namespace, conf_type, conf_file, conf_name, value_type, value_default, value_allowed, value_type_sub, flag_status, flag_disable, flag_locked, flag_encrypt, need_restart) VALUES( 'tendb', 'mysql_monitor', 'items-config.yaml', 'proxy-user-list', 'STRING', '{"schedule":"0 55 23 * * *","role":[],"machine_type":["proxy"],"name":"proxy-user-list","enable":true}', '', 'MAP', 1, 0, 0, 0, 1);
REPLACE INTO tb_config_name_def( namespace, conf_type, conf_file, conf_name, value_type, value_default, value_allowed, value_type_sub, flag_status, flag_disable, flag_locked, flag_encrypt, need_restart) VALUES( 'tendb', 'mysql_monitor', 'items-config.yaml', 'rotate-slowlog', 'STRING', '{"enable":true,"name":"rotate-slowlog","machine_type":["single","backend","remote","spider"],"role":[],"schedule":"0 55 23 * * *"}', '', 'MAP', 1, 0, 0, 0, 1);
REPLACE INTO tb_config_name_def( namespace, conf_type, conf_file, conf_name, value_type, value_default, value_allowed, value_type_sub, flag_status, flag_disable, flag_locked, flag_encrypt, need_restart) VALUES( 'tendb', 'mysql_monitor', 'items-config.yaml', 'slave-status', 'STRING', '{"enable":true,"machine_type":["backend","remote"],"name":"slave-status","role":["slave","repeater"],"schedule":"@every 1m"}', '', 'MAP', 1, 0, 0, 0, 1);
REPLACE INTO tb_config_name_def( namespace, conf_type, conf_file, conf_name, value_type, value_default, value_allowed, value_type_sub, flag_status, flag_disable, flag_locked, flag_encrypt, need_restart) VALUES( 'tendb', 'mysql_monitor', 'items-config.yaml', 'ctl-replicate', 'STRING', '{"name":"ctl-replicate","machine_type":["spider"],"enable":true,"schedule":"@every 1m","role":["spider_master"]}', '', 'MAP', 1, 0, 0, 0, 1);
REPLACE INTO tb_config_name_def( namespace, conf_type, conf_file, conf_name, value_type, value_default, value_allowed, value_type_sub, flag_status, flag_disable, flag_locked, flag_encrypt, need_restart) VALUES( 'tendb', 'mysql_monitor', 'items-config.yaml', 'spider-remote', 'STRING', '{"enable":true,"name":"spider-remote","machine_type":["spider"],"role":[],"schedule":"@every 1m"}', '', 'MAP', 1, 0, 0, 0, 1);
REPLACE INTO tb_config_name_def( namespace, conf_type, conf_file, conf_name, value_type, value_default, value_allowed, value_type_sub, flag_status, flag_disable, flag_locked, flag_encrypt, need_restart) VALUES( 'tendb', 'mysql_monitor', 'items-config.yaml', 'spider-table-schema-consistency', 'STRING', '{"schedule":"0 10 1 * * *","role":["spider_master"],"machine_type":["spider"],"name":"spider-table-schema-consistency","enable":false}', '', 'MAP', 1, 0, 0, 0, 1);
REPLACE INTO tb_config_name_def( namespace, conf_type, conf_file, conf_name, value_type, value_default, value_allowed, value_type_sub, flag_status, flag_disable, flag_locked, flag_encrypt, need_restart) VALUES( 'tendb', 'mysql_monitor', 'items-config.yaml', 'dbha-heartbeat', 'STRING', '{"schedule":"@every 2h","role":[],"name":"dbha-heartbeat","machine_type":["spider","remote","backend"],"enable":true}', '', 'MAP', 1, 0, 0, 0, 1);
REPLACE INTO tb_config_name_def( namespace, conf_type, conf_file, conf_name, value_type, value_default, value_allowed, value_type_sub, flag_status, flag_disable, flag_locked, flag_encrypt, need_restart) VALUES( 'tendb', 'mysql_monitor', 'items-config.yaml', 'unique-ctl-master', 'STRING', '{"machine_type":["spider"],"name":"unique-ctl-master","enable":true,"schedule":"@every 1m","role":["spider_master"]}', '', 'MAP', 1, 0, 0, 0, 1);
REPLACE INTO tb_config_name_def( namespace, conf_type, conf_file, conf_name, value_type, value_default, value_allowed, value_type_sub, flag_status, flag_disable, flag_locked, flag_encrypt, need_restart) VALUES( 'tendb', 'mysql_monitor', 'items-config.yaml', 'scene-snapshot', 'STRING', '{"role":[],"schedule":"@every 1m","enable":false,"machine_type":["spider","remote","backend","single"],"name":"scene-snapshot"}', '', 'MAP', 1, 0, 0, 0, 1);
REPLACE INTO tb_config_name_def( namespace, conf_type, conf_file, conf_name, value_type, value_default, value_allowed, value_type_sub, flag_status, flag_disable, flag_locked, flag_encrypt, need_restart) VALUES( 'tendb', 'mysql_monitor', 'items-config.yaml', 'mysql-timezone-change', 'STRING', '{"role":[],"schedule":"@every 1m","enable":true,"name":"mysql-timezone-change","machine_type":["spider","remote","backend","single"]}', '', 'MAP', 1, 0, 0, 0, 1);
REPLACE INTO tb_config_name_def( namespace, conf_type, conf_file, conf_name, value_type, value_default, value_allowed, value_type_sub, flag_status, flag_disable, flag_locked, flag_encrypt, need_restart) VALUES( 'tendb', 'mysql_monitor', 'items-config.yaml', 'sys-timezone-change', 'STRING', '{"machine_type":["spider","proxy","remote","backend","single"],"name":"sys-timezone-change","enable":true,"schedule":"@every 1m","role":[]}', '', 'MAP', 1, 0, 0, 0, 1);
REPLACE INTO tb_config_name_def( namespace, conf_type, conf_file, conf_name, value_type, value_default, value_allowed, value_type_sub, flag_status, flag_disable, flag_locked, flag_encrypt, need_restart) VALUES( 'tendb', 'mysql_monitor', 'items-config.yaml', 'rotate-proxy-connlog', 'STRING', '{"role":[],"schedule":"0 55 23 * * *","enable":true,"name":"rotate-proxy-connlog","machine_type":["proxy"]}', '', 'MAP', 1, 0, 0, 0, 1);
REPLACE INTO tb_config_name_def( namespace, conf_type, conf_file, conf_name, value_type, value_default, value_allowed, value_type_sub, flag_status, flag_disable, flag_locked, flag_encrypt, need_restart) VALUES( 'tendb', 'mysql_monitor', 'items-config.yaml', 'get-ctl-primary', 'STRING', '{"role":["spider_master"],"schedule":"@every 1m","enable":true,"name":"get-ctl-primary","machine_type":["spider"]}', '', 'MAP', 1, 0, 0, 0, 1);
REPLACE INTO tb_config_name_def( namespace, conf_type, conf_file, conf_name, value_type, value_default, value_allowed, value_type_sub, flag_status, flag_disable, flag_locked, flag_encrypt, need_restart) VALUES( 'tendb', 'mysql_monitor', 'items-config.yaml', 'priv-check', 'STRING', '{"schedule":"0 40 9 * * 2","role":[],"name":"priv-check","machine_type":["spider","remote","backend","single"],"enable":true}', '', 'MAP', 1, 0, 0, 0, 1);
REPLACE INTO tb_config_name_def( namespace, conf_type, conf_file, conf_name, value_type, value_default, value_allowed, value_type_sub, flag_status, flag_disable, flag_locked, flag_encrypt, need_restart) VALUES( 'tendb', 'mysql_monitor', 'items-config.yaml', 'proxy-rebind', 'STRING', '{"enable":true,"machine_type":["proxy"],"name":"proxy-rebind","role":[],"schedule":"0 55 9 * * *"}', '', 'MAP', 1, 0, 0, 0, 1);
