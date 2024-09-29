br:
	bin/rails

# DOCKER
create_network:
	docker network create tia_ruby_nw
	
run_container:
	docker run --network tia_ruby_nw --name tia_ruby_psql -p 9999:5432 --env-file ".docker.env" -d postgres:16.2 

start_container:
	docker start tia_ruby_psql

create_db:
	docker exec tia_ruby_psql psql -U tiarubyuser -c "create database tia;" 

exec_db:
	docker exec -it tia_ruby_psql psql -U tiarubyuser