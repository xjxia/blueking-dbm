package gm

import (
	"dbm-services/common/dbha/ha-module/util"
	"net"
	"strconv"
	"sync"
	"time"

	"dbm-services/common/dbha/ha-module/config"
	"dbm-services/common/dbha/ha-module/constvar"
	"dbm-services/common/dbha/ha-module/dbutil"
	"dbm-services/common/dbha/ha-module/log"
	"dbm-services/common/dbha/ha-module/types"
)

// GDM work struct
type GDM struct {
	AgentChan     chan DoubleCheckInstanceInfo
	GMMChan       chan DoubleCheckInstanceInfo
	ListenPort    int
	ReporterCache map[string]*reporterCacheItem
	cacheMutex    sync.Mutex
	DupExpire     int
	ScanInterval  int
	Conf          *config.Config
	reporter      *HAReporter
}

// reporterCacheItem gdm去重缓存项
// status为上报时的快照，ins.db会在GMM双重检查时被修改，不能直接用于去重比较
type reporterCacheItem struct {
	ins          *DoubleCheckInstanceInfo
	status       types.CheckStatus
	receivedTime time.Time
}

// NewGDM init gdm
func NewGDM(conf *config.Config, ch chan DoubleCheckInstanceInfo,
	reporter *HAReporter) *GDM {
	return &GDM{
		AgentChan:     make(chan DoubleCheckInstanceInfo, 10),
		GMMChan:       ch,
		ListenPort:    conf.GMConf.ListenPort,
		ReporterCache: map[string]*reporterCacheItem{},
		cacheMutex:    sync.Mutex{},
		DupExpire:     conf.GMConf.GDM.DupExpire,
		ScanInterval:  conf.GMConf.GDM.ScanInterval,
		Conf:          conf,
		reporter:      reporter,
	}
}

// Run gdm main entry
func (gdm *GDM) Run() {
	gdm.Init()
	for {
		select {
		case ins := <-gdm.AgentChan:
			gdm.Process(ins)
		case <-time.After(time.Duration(gdm.Conf.GMConf.ReportInterval) * time.Second):
		}

		gdm.reporter.DoReport(ModuleReportInfo{
			Module: constvar.GDM,
		})
		gdm.PostProcess()
	}
}

// Init gdm do init
func (gdm *GDM) Init() {
	go func() {
		gdm.listenAndDoAccept()
	}()
}

// Process gdm process instance
func (gdm *GDM) Process(ins DoubleCheckInstanceInfo) {
	if !gdm.isReporterRecently(&ins) {
		gdm.PushInstance2Next(ins)
	}
}

// PostProcess gdm post instance info
func (gdm *GDM) PostProcess() {
	gdm.flushCache()
	return
}

// PushInstance2Next gdm push instance to gmm chan
func (gdm *GDM) PushInstance2Next(ins DoubleCheckInstanceInfo) {
	gdm.GMMChan <- ins
	return
}

// listenAndDoAccept TODO
// gdm do listen
func (gdm *GDM) listenAndDoAccept() {
	addr := "0.0.0.0:" + strconv.Itoa(gdm.ListenPort)
	log.Logger.Infof("gdm start listen %s\n", addr)
	listen, err := net.Listen("tcp", addr)
	if err != nil {
		log.Logger.Fatalf("gdm listen failed. err:%s", err.Error())
	}
	defer func() {
		err = listen.Close()
		if err != nil {
			log.Logger.Errorf("close socket failed. err:%s", err.Error())
		}
	}()

	for {
		conn, err := listen.Accept()
		if err != nil {
			log.Logger.Errorf("accept socket failed. err:%s", err.Error())
			continue
		} else {
			log.Logger.Infof("gdm accept success, Local: %v, Remote: %v",
				conn.LocalAddr().String(), conn.RemoteAddr().String())
		}
		agentConn := AgentConnection{
			NetConnection: conn,
			GDMChan:       gdm.AgentChan,
			Conf:          gdm.Conf,
		}
		go func(agentConn AgentConnection) {
			agentConn.Init()
			err = agentConn.Read()
			if err != nil {
				log.Logger.Warnf("agentConn close. err:%s\n", err.Error())
				return
			}
		}(agentConn)
	}
}

func (gdm *GDM) isReporterRecently(ins *DoubleCheckInstanceInfo) bool {
	ip, port := ins.db.GetAddress()
	gdm.cacheMutex.Lock()
	defer gdm.cacheMutex.Unlock()
	cache, ok := gdm.ReporterCache[ip]
	status := ins.db.GetStatus()
	if ok && cache.status == status {
		log.Logger.Infof("instance[%s#%d] cached, skip report", ip, port)
		return true
	}
	log.Logger.Infof("gdm cache instance:%s, %s",
		util.GraceStructString(ins), util.GraceStructString(ins.db))
	// 刷新缓存
	gdm.ReporterCache[ip] = &reporterCacheItem{
		ins:          ins,
		status:       status,
		receivedTime: ins.ReceivedTime,
	}
	return false
}

func (gdm *GDM) flushCache() {
	now := time.Now()
	gdm.cacheMutex.Lock()
	defer gdm.cacheMutex.Unlock()
	// 清除超过DupExpire的缓存
	for key, val := range gdm.ReporterCache {
		if now.After(val.receivedTime.Add(time.Second * time.Duration(gdm.DupExpire))) {
			log.Logger.Debugf("clean cache for instance[%v]", key)
			delete(gdm.ReporterCache, key)
		}
	}
}

// SyncCacheStatus 双重检查结束后，将缓存状态同步为双重检查的最终状态
// 与修复前"缓存直接引用db对象、状态随双重检查改变"的效果一致：之后同一故障再次上报可重新进入双重检查，
// 但不暴露Detection过程中的中间状态，避免并发上报绕过去重
func (gdm *GDM) SyncCacheStatus(db dbutil.DataBaseDetect) {
	ip, port := db.GetAddress()
	gdm.cacheMutex.Lock()
	defer gdm.cacheMutex.Unlock()
	cache, ok := gdm.ReporterCache[ip]
	if !ok || cache.ins.db != db {
		// 缓存已过期或已被其他上报覆盖，无需同步
		return
	}
	status := db.GetStatus()
	log.Logger.Infof("instance[%s#%d] double check done, sync cache status %s -> %s",
		ip, port, cache.status, status)
	cache.status = status
}

// InstanceSwitchDone 清除超过一分钟且已经切换结束（非正常切换结束，即double check成功或者延迟切换）的缓存
// 当切换结束后，将ReceiveTime - DupExpire + 1 minute，通过flushCache的逻辑来将缓存清除
func (gdm *GDM) InstanceSwitchDone(ip string, port int, dbType string) {
	gdm.cacheMutex.Lock()
	defer gdm.cacheMutex.Unlock()
	cache, ok := gdm.ReporterCache[ip]
	if !ok {
		log.Logger.Warnf(
			"ip:%s, port:%d, dbtype:%s switch done, but cache not exist", ip, port, dbType)
		return
	}
	log.Logger.Infof("ip:%s, port:%d, dbtype:%s switch done", ip, port, dbType)
	cache.receivedTime.Add(time.Minute - time.Duration(gdm.DupExpire)*time.Second)
}
