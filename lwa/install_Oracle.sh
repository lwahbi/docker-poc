#!/bin/bash


#Check if the Oracle Database image is already available
if docker images | grep -q "container-registry.oracle.com/database/enterprise:19.3.0.0"; then
  echo "Oracle Database image is already available."
else
  # Login to Oracle Container Registry
  docker login container-registry.oracle.com -u "lwahbi@gmail.com" -p "Root0421&"

  # Pull the Oracle Database Docker image from Oracle Container Registry
  docker pull container-registry.oracle.com/database/enterprise:19.3.0.0
fi

# Check if the Docker network exists
if ! docker network inspect oracle_network_lwa &> /dev/null ; then
  # Create a Docker network (if not already exists)
  docker network create --driver bridge oracle_network
fi



# Stop the Oracle Database container (if running)
if docker ps -a --format '{{.Names}}' | grep -q "oracle_db_lwa"; then
  echo "Stopping Oracle Database container..."
  docker stop oracle_db
fi

# Remove the Oracle Database container (if it exists)
if docker ps -a --format '{{.Names}}' | grep -q "oracle_db"; then
  echo "Removing Oracle Database container..."
  docker rm oracle_db
fi

# Start a Docker container with Oracle Database
docker run -d --env-file ./ora_db_env.dat \
  --name oracle_db \
  --network=oracle_network \
  --shm-size=1g \
  -p 1521:1521 \
  -v /path/to/data:/opt/oracle/oradata \
  container-registry.oracle.com/database/enterprise:19.3.0.0

echo "Starting Database container..."


# Attente que la base de données soit prête (à adapter)
sleep 30s 

# Création d'un utilisateur et d'un schéma (peut être externalisé)
# Execute SQL script to create a user and schema
# winpty docker cp create_user.sql oracle_db:/tmp/
# winpty docker exec -it oracle_db 
# sqlplus sys/MyPassword123@localhost/ORCLPDB1 AS SYSDBA @create_users_and_tables.sql

#echo "Creating users and schema..."
docker cp ./create_users_and_tables.sql oracle_db:/tmp/
docker exec -it oracle_db sqlplus sys/MyPassword123@localhost/ORCLCDB AS SYSDBA @/tmp/create_users_and_tables.sql

echo "Database setup complete."

#connexion base : sqlplus sys/MyPassword123@localhost/ORCLCDB AS SYSDBA
# SELECT instance_name, status FROM v$instance; // si INSTANCE_NAME= ORCLCDB  /  STATUS=MOUNTED
# ALTER DATABASE OPEN; // si ORA-01154 : database busy
		# SELECT sid, serial#, status FROM v$session; 
