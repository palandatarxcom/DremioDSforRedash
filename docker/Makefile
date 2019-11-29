EDITOR=vim

all: build

build:
	docker build -t palan/redash:v5.0.0-beta .

run: build
	docker run -ti --privileged -p 80:80 -v palan/redash:v5.0.0-beta

detach: build
	docker run -d --privileged -p 80:80 palan/redash:v5.0.0-beta

clean:
	docker ps -aq --no-trunc | xargs docker stop
	docker ps -aq --no-trunc | xargs docker rm
	docker volume prune --force

exec:
	docker exec -ti `docker ps | grep redash:v5.0.0-beta |head -1 | awk -e '{print $$1}'` /bin/bash


stop:
	docker stop `docker ps | grep redash:v5.0.0-beta |head -1| awk -e '{print $$1}'`
