#!/bin/bash
DB_ROOT_NAME="XXXXXXXX" # DBのルートユーザーを指定
DB_ROOT_PASSWORD="XXXXXXXX" #DBのルートパスワードを指定
DB_USER_NAME="XXXXXXXX" # DBのユーザー名を指定
DB_USER_PASSWORD="XXXXXXXX" # DBのパスワードを指定
POD_NAME="data-platform-common-settings-mysql-kube" # Podの名前を指定
DATABASE_NAME="DataPlatformCommonSettingsMysqlKube" # データベース名を指定
SQL_FILES=( # sqlファイルの名前を複数指定
  )
MYSQL_POD=$(kubectl get pod | grep ${POD_NAME} | awk '{print $1}')

kubectl exec -it ${MYSQL_POD} -- bash -c "mkdir -p /src"

# sqlファイルのコピー
for ((i=0; i<${#SQL_FILES[@]}; i++)) do
  kubectl cp ${SQL_FILES[i]} ${MYSQL_POD}:/src
done

# databaeの作成
kubectl exec -it ${MYSQL_POD} -- bash -c "mysql -u${DB_ROOT_NAME} -p${DB_ROOT_PASSWORD} -e \"CREATE DATABASE IF NOT EXISTS ${DATABASE_NAME} default character set utf8;\""

# userに権限の付与
kubectl exec -it ${MYSQL_POD} -- bash -c "mysql -u${DB_ROOT_NAME} -p${DB_ROOT_NAME} -e \"GRANT ALL ON *.* TO ${DB_USER_NAME}@;\""

kubectl exec -it ${MYSQL_POD} -- bash -c "mysql -u${DB_ROOT_NAME} -p${DB_ROOT_PASSWORD} -e \"USE ${DATABASE_NAME};\""

# テーブルの作成
for ((i=0; i<${#SQL_FILES[@]}; i++)) do
  kubectl exec -it ${MYSQL_POD} -- bash -c "mysql -u${DB_USER_NAME} -p${DB_USER_PASSWORD} -D ${DATABASE_NAME} < /src/${SQL_FILES[i]}"
done
