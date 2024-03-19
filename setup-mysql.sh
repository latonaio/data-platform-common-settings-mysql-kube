#!/bin/bash
# Usage:
#   bash setup-mysql.sh [Option1] [Option2]
# Option1:
#   create   Choose [Option2] from [database | table | all]
#   delete   Choose [Option2] from [database | table]
#   grant    Do not Choose [Option2]

DB_ROOT_NAME="XXXXXXXX" # DBのルートユーザーを指定
DB_ROOT_PASSWORD="XXXXXXXX" #DBのルートパスワードを指定
DB_USER_NAME="XXXXXXXX" # DBのユーザー名を指定
DB_USER_PASSWORD="XXXXXXXX" # DBのパスワードを指定
POD_NAME="data-platform-common-settings-mysql-kube" # Podの名前を指定
DATABASE_NAME="DataPlatformCommonSettingsMysqlKube" # データベース名を指定
SQL_FILES=( # sqlファイルの名前を（複数）指定（親テーブルのsqlファイルが最初）
  "data-platform-api-request-to-rmq-mapper-sql.sql"
)
TABLE_NAMES=( # tableの名前を（複数）指定（親テーブルが最後）
  "data_platform_api_request_to_rmq_mapper"
)
MYSQL_POD=$(kubectl get pod | grep ${POD_NAME} | awk '{print $1}')

kubectl exec -it ${MYSQL_POD} -- bash -c "mkdir -p /src"

# sqlファイルのコピー
for ((i=0; i<${#SQL_FILES[@]}; i++)) do
  kubectl cp ${SQL_FILES[i]} ${MYSQL_POD}:/src
done

case "$1" in
  "create")
    case "$2" in
      "database")
        # データベースの作成
        kubectl exec -it ${MYSQL_POD} -- bash -c "mysql -u${DB_ROOT_NAME} -p${DB_ROOT_PASSWORD} -e \"CREATE DATABASE IF NOT EXISTS ${DATABASE_NAME} default character set utf8 ;\""
        echo "CREATE ${DATABASE_NAME}!"
        ;;
      "table")
        # テーブルの作成
        for ((i=0; i<${#SQL_FILES[@]}; i++)) do
          kubectl exec -it ${MYSQL_POD} -- bash -c "mysql -u${DB_ROOT_NAME} -p${DB_ROOT_PASSWORD} -D ${DATABASE_NAME} < /src/${SQL_FILES[i]}"
          echo "CREATE ${SQL_FILES[i]}!"
        done
        ;;
      "all")
        # データベースの作成
        kubectl exec -it ${MYSQL_POD} -- bash -c "mysql -u${DB_ROOT_NAME} -p${DB_ROOT_PASSWORD} -e \"CREATE DATABASE IF NOT EXISTS ${DATABASE_NAME} default character set utf8 ;\""
        echo "CREATE ${DATABASE_NAME}!"

        # テーブルの作成
        for ((i=0; i<${#SQL_FILES[@]}; i++)) do
          kubectl exec -it ${MYSQL_POD} -- bash -c "mysql -u${DB_ROOT_NAME} -p${DB_ROOT_PASSWORD} -D ${DATABASE_NAME} < /src/${SQL_FILES[i]}"
          echo "CREATE ${SQL_FILES[i]}!"
        done
        ;;
      *)
        echo "Subject is not defined!";;
    esac
    ;;
  "delete")
    case "$2" in
      "database")
        # データベースの削除
        kubectl exec -it ${MYSQL_POD} -- bash -c "mysql -u${DB_ROOT_NAME} -p${DB_ROOT_PASSWORD} -e \"DROP DATABASE ${DATABASE_NAME};\""
        echo "DELETE ${DATABASE_NAME}!"
        ;;
      "table")
        # テーブルの削除
        for ((i=0; i<${#TABLE_NAMES[@]}; i++)) do
          kubectl exec -it ${MYSQL_POD} -- bash -c "mysql -u${DB_ROOT_NAME} -p${DB_ROOT_PASSWORD} -e \"DROP TABLE ${DATABASE_NAME}.${TABLE_NAMES[i]};\""
          echo "DELETE ${TABLE_NAMES[i]}!"
        done
        ;;
      *)
        echo "Subject is not defined!";;
    esac
    ;;
  "grant")
    # userに権限の付与
    kubectl exec -it ${MYSQL_POD} -- bash -c "mysql -u${DB_ROOT_NAME} -p${DB_ROOT_PASSWORD} -e \"GRANT ALL ON *.* TO ${DB_USER_NAME}@;\""
    echo "GRANT ALL Authorization!"
    ;;
  *)
    echo "Operation is not defined!";;
esac