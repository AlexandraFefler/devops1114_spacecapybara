provider "kubernetes" {
  host                   = "https://${google_container_cluster.primary.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(google_container_cluster.primary.master_auth[0].cluster_ca_certificate)
}

data "google_client_config" "default" {}

variable "namespace" {
  default     = "default"
  description = "Namespace to deploy resources"
}

variable "init_sql_content" {
  default     = <<EOT
-- Create the database if it doesn't already exist
CREATE DATABASE IF NOT EXISTS mydatabase;

-- Use the database
USE mydatabase;

CREATE TABLE IF NOT EXISTS visitor_counter (
    id INT PRIMARY KEY AUTO_INCREMENT,
    count INT DEFAULT 0
);

INSERT INTO visitor_counter (count) VALUES (0) ON DUPLICATE KEY UPDATE count = count;

CREATE TABLE IF NOT EXISTS images (
  idimages INT NOT NULL AUTO_INCREMENT,
  imagescol VARCHAR(300) NULL,
  PRIMARY KEY (idimages)
);

INSERT INTO images (idimages, imagescol)
SELECT 1, 'https://api.capy.lol/v1/capybara' 
WHERE NOT EXISTS (SELECT 1 FROM images WHERE idimages = 1);

INSERT INTO images (idimages, imagescol)
SELECT 2, 'https://media.tenor.com/inZYR5pCZP8AAAAM/capybara-cat.gif'
WHERE NOT EXISTS (SELECT 1 FROM images WHERE idimages = 2);

INSERT INTO images (idimages, imagescol)
SELECT 3, 'https://media0.giphy.com/media/bnl7xKaEXMLhI475je/200w.gif?cid=6c09b952idcgtsfmgcpfuq9d4cmh9lwin5815h5g632ti0d4&ep=v1_gifs_search&rid=200w.gif&ct=g'
WHERE NOT EXISTS (SELECT 1 FROM images WHERE idimages = 3);

INSERT INTO images (idimages, imagescol)
SELECT 4, 'https://i.dailymail.co.uk/i/pix/2017/07/04/10/4203D62400000578-0-image-a-48_1499161248603.jpg'
WHERE NOT EXISTS (SELECT 1 FROM images WHERE idimages = 4);
EOT
  description = "Content of the init.sql file"
}

resource "kubernetes_config_map" "init_sql_config" {
  # depends_on = [google_container_cluster.primary]
  depends_on = [
    google_container_cluster.primary,
    google_container_node_pool.primary_nodes
  ]
  
  metadata {
    name      = "init-sql-config"
    namespace = var.namespace
  }

  data = {
    "init.sql" = var.init_sql_content
  }
}

resource "kubernetes_manifest" "init_mysql_job" {
  # depends_on = [google_container_cluster.primary]
  depends_on = [
    google_container_cluster.primary,
    google_container_node_pool.primary_nodes,
    kubernetes_config_map.init_sql_config
  ]

  manifest = yamldecode(<<YAML
apiVersion: batch/v1
kind: Job
metadata:
  name: init-mysql-job
  namespace: ${var.namespace}
spec:
  backoffLimit: 4
  template:
    spec:
      containers:
      - name: init-mysql
        image: mysql:8.0
        command:
        - sh
        - -c
        - |
          echo "Waiting for MySQL to be ready..."
          until mysqladmin ping -h mysql-service --silent; do
            echo "Waiting for MySQL...";
            sleep 3;
          done;
          echo "Initializing database..."
          mysql -h mysql-service -u root -padmin < /docker-entrypoint-initdb.d/init.sql
        volumeMounts:
        - name: init-sql-volume
          mountPath: /docker-entrypoint-initdb.d/
      restartPolicy: OnFailure
      volumes:
      - name: init-sql-volume
        configMap:
          name: init-sql-config
YAML
  )
}

resource "kubernetes_manifest" "mysql_deployment" {
  # depends_on = [google_container_cluster.primary]
  depends_on = [
    google_container_cluster.primary,
    google_container_node_pool.primary_nodes,
    kubernetes_config_map.init_sql_config
  ]

  manifest = yamldecode(<<YAML
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mysql
  namespace: ${var.namespace}
  labels:
    app: mysql
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mysql
  template:
    metadata:
      labels:
        app: mysql
    spec:
      containers:
      - name: mysql
        image: mysql:8.0
        ports:
        - containerPort: 3306
        env:
        - name: MYSQL_ROOT_PASSWORD
          value: "admin"
        - name: MYSQL_DATABASE
          value: "mydatabase"
        - name: MYSQL_USER
          value: "user"
        - name: MYSQL_PASSWORD
          value: "password"
YAML
  )
}

resource "kubernetes_manifest" "mysql_service" {
  # depends_on = [google_container_cluster.primary]
  depends_on = [
    google_container_cluster.primary,
    google_container_node_pool.primary_nodes,
    kubernetes_config_map.init_sql_config
  ]

  manifest = yamldecode(<<YAML
apiVersion: v1
kind: Service
metadata:
  name: mysql-service
  namespace: ${var.namespace}
  labels:
    app: mysql
spec:
  selector:
    app: mysql
  ports:
  - protocol: TCP
    port: 3306
    targetPort: 3306
  type: ClusterIP
YAML
  )
}

resource "kubernetes_manifest" "space_capybara_deployment" {
  # depends_on = [google_container_cluster.primary]
  depends_on = [
    google_container_cluster.primary,
    google_container_node_pool.primary_nodes,
    kubernetes_config_map.init_sql_config
  ]

  manifest = yamldecode(<<YAML
apiVersion: apps/v1
kind: Deployment
metadata:
  name: space-capybara-web
  namespace: ${var.namespace}
  labels:
    app: space-capybara
spec:
  replicas: 3
  selector:
    matchLabels:
      app: space-capybara
  template:
    metadata:
      labels:
        app: space-capybara
    spec:
      initContainers:
      - name: wait-for-mysql
        image: mysql:8.0
        command:
        - sh
        - -c
        - |
          echo "Waiting for MySQL to be ready..."
          until mysqladmin ping -h mysql-service --silent; do
            echo "Waiting for MySQL...";
            sleep 3;
          done;
          echo "MySQL is up and running!"
      containers:
      - name: web
        image: sashafefler/spacecapybara:v6
        ports:
        - containerPort: 5002
        env:
        - name: FLASK_ENV
          value: "development"
        - name: MYSQL_HOST
          value: "mysql-service"
        - name: MYSQL_USER
          value: "user"
        - name: MYSQL_PASSWORD
          value: "password"
        - name: MYSQL_DATABASE
          value: "mydatabase"
        - name: WEB_PORT
          value: "5002"
YAML
  )
}

resource "kubernetes_manifest" "space_capybara_service" {
  # depends_on = [google_container_cluster.primary]
  depends_on = [
    google_container_cluster.primary,
    google_container_node_pool.primary_nodes,
    kubernetes_config_map.init_sql_config
  ]

  manifest = yamldecode(<<YAML
apiVersion: v1
kind: Service
metadata:
  name: space-capybara-web
  namespace: ${var.namespace}
  labels:
    app: space-capybara
spec:
  selector:
    app: space-capybara
  ports:
  - protocol: TCP
    port: 5002
    targetPort: 5002
  type: LoadBalancer
YAML
  )
}
