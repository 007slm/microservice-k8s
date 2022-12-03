#！/bin/bash
echo "usage: $0 [namespace]"

echo "定义备份变量"
BACKUP_PATH=/mnt/d/java/microservice-k8s/data/k8s-backup-restore
BACKUP_PATH_BIN=$BACKUP_PATH/bin
BACKUP_PATH_DATA=$BACKUP_PATH/data/backup/`date +%Y%m%d%H%M%S`
BACKUP_PATH_LOG=$BACKUP_PATH/log
BACKUP_LOG_FILE=$BACKUP_PATH_LOG/k8s-backup.log

echo  "开始设置备份类型"
CONFIG_TYPE="deployment service deploy configmap secret job cronjob replicaset daemonset statefulset"

echo  "创建备份目录"
mkdir -p $BACKUP_PATH_BIN
mkdir -p $BACKUP_PATH_DATA
mkdir -p $BACKUP_PATH_LOG
cd $BACKUP_PATH_DATA
echo "查询namespace"
kubectl config view
ns_list=`kubectl get ns | awk '{print $1}' | grep -v NAME`
if [ $# -ge 1 ]; then
ns_list="$@"
fi
echo "define counters"
COUNT0=0
COUNT1=0
COUNT2=0
COUNT3=0
echo "print hint"
echo "`date` 开始备份 [namespaces: ${ns_list}] 数据."
echo "`date` 开始备份 [type: ${CONFIG_TYPE}]."
echo "`date` 如果需要查看备份指令请输入: 'tail -100f ${BACKUP_LOG_FILE} '"
message="备份 kubernetes cluster to yaml files."
echo ${message} 2>&1 > $BACKUP_LOG_FILE
echo ${message}

for ns in $ns_list; do
  COUNT0=`expr $COUNT0 + 1`

  echo "`date` 备份 No..${COUNT0} namespace [namespace: ${ns}]."
  COUNT2=0
  ## loop for types
  for type in $CONFIG_TYPE; do
    echo "`date` 备份 type [namespace: ${ns}, type: ${type}]."
    item_list=`kubectl -n $ns get $type | awk '{print $1}' | grep -v NAME | grep -v "No "`
    COUNT1=0
    ## loop for items
    for item in $item_list; do
      file_name=$BACKUP_PATH_DATA/${ns}_${type}_${item}.yaml
      echo "`date` 备份 kubernetes config yaml [namespace: ${ns}, type: ${type}, item: ${item}] to file: ${file_name}"
      kubectl -n $ns get $type $item -o yaml > $file_name
      COUNT1=`expr $COUNT1 + 1`
      COUNT2=`expr $COUNT2 + 1`
      COUNT3=`expr $COUNT3 + 1`
      echo "`date` 备份 No.$COUNT3 结束."
    done;
  done;
  echo "`date` Backup ${COUNT2} 结束.  [namespace: ${ns}]."
done;
echo "show stats"
message="`date` 共备份 yaml 文件： ${COUNT3}  个."
echo ${message}
echo ${message} 2>&1 >> $BACKUP_LOG_FILE
echo "`date` kubernetes 备份全部完成." 2>&1 >> $BACKUP_LOG_FILE exit 0