package dbmysql

import (
	"fmt"

	"dbm-services/common/dbha/ha-module/constvar"
	"dbm-services/common/dbha/ha-module/dbutil"
)

// MySQLProxySwitch define proxy switch detail info
type MySQLProxySwitch struct {
	MySQLCommonSwitch
	AdminPort int
	Entry     dbutil.BindEntry
}

// CheckSwitch check whether proxy allowed swtich, always true at present
func (ins *MySQLProxySwitch) CheckSwitch() (bool, error) {
	return true, nil
}

// DoSwitch mysql-proxy do switch
// delete ip under the entry
func (ins *MySQLProxySwitch) DoSwitch() error {
	//1. delete name service
	isSingle, err := ins.SingleAddressUnderDomain(ins.Entry)
	if err != nil {
		ins.ReportLogs(constvar.FailResult, fmt.Sprintf("check whether single address under domain failed:%s",
			err.Error()))
		return err
	}
	if isSingle {
		return fmt.Errorf("only single address under this domain, skip release domain")
	} else {
		ins.ReportLogs(constvar.InfoResult, fmt.Sprintf("try to release ip[%s#%d] from all cluster entry",
			ins.Ip, ins.Port))
		return ins.DeleteNameService(ins.Entry)
	}
}

// ShowSwitchInstanceInfo display switch proxy info
func (ins *MySQLProxySwitch) ShowSwitchInstanceInfo() string {
	str := fmt.Sprintf("<%s#%d IDC:%d Status:%s Bzid:%s ClusterType:%s MachineType:%s> switch",
		ins.Ip, ins.Port, ins.IdcID, ins.Status, ins.App, ins.ClusterType, ins.MetaType)
	return str
}

// RollBack proxy do rollback
func (ins *MySQLProxySwitch) RollBack() error {
	return nil
}
