NAME ?=
VERSION ?=
BUILD ?=
SOURCE_FILES ?= Dockerfile

DOCKER_OPTIONS ?=
PORT_MAPPING ?=
VOLUME_MAPPING ?=

TAG = $(NAME):$(VERSION)-$(BUILD)

FILTER_NOT_RUNNING = --filter status=created --filter status=exited
FILTER_ALL = --all

FIELDS_PARSER = BEGIN{FS="  +";split("",idx)}{if(length(idx)==0){for(i=1;i<=NF;i++){idx[$$i]=i};next}}{split("",fld);for(k in idx){fld[k]=$$idx[k]};if(fld["NAMES"]==""){fld["NAMES"]=fld["PORTS"];fld["PORTS"]=""}}

FORCE = --force

ifneq ($(nocache),)
NO_CACHE = --no-cache
endif

ifneq ("$(wildcard envvars)","")
ENV_FILE = --env-file envvars
endif

ERR_FAIL = 1

.PHONY: all build rebuild tag-latest start stop restart launch relaunch upgrade shell clean clean-all

# $(call build)
# $(call build,$(ERR_FAIL))
# $(call build,,$(NO_CACHE))
# $(call build,$(ERR_FAIL),$(NO_CACHE))
define build
@test -z "$$(docker images --quiet $(TAG))" \
  && docker build $2 --tag $(TAG) --rm . \
  || (echo "\nThere is an image tagged $(TAG), please remove it first or touch build.done manually."; exit $1)
endef

# $(call check_container_exists,<exit code if exists>,<exit code if not exists>)
define check_container_exists
@docker ps --all --no-trunc \
  | awk '$(FIELDS_PARSER){print fld["NAMES"] fld["IMAGE"]}' \
  | awk '{if($$1 == "$(NAME)$(TAG)"){exit 1}}' \
  && (echo "Container $(NAME) based on $(TAG) not exists."; exit $2) \
  || (echo "Container $(NAME) based on $(TAG) exists."; exit $1)
endef

# $(call create)
# $(call create,<exit code if no container>)
define create
  @docker create --name $(NAME) $(ENV_FILE) $(DOCKER_OPTIONS) $(PORT_MAPPING) $(VOLUME_MAPPING) $(TAG)
endef

# $(call action,<action name>,<exit code if no container>,<options>)
# $(call action,rm)
# $(call action,rm,,$(FORCE))
# $(call action,rm,$(ERR_FAIL),$(FORCE))
# $(call action,rm,$(ERR_FAIL))
define action
@echo "Trying to $1 container $(NAME) ..."
@test -n "$$(docker ps --all --quiet --filter name=$(NAME))" \
  && docker $1 $3 $(NAME) \
  || (echo "No container with name $(NAME)"; exit $2)
endef

define remove_containers
@echo 'Removing containers based on old images ...'
@docker ps $1 --no-trunc \
  | awk '$(FIELDS_PARSER){print fld["IMAGE"] " " fld["CONTAINER ID"]}' \
  | awk '$$1~/$(NAME)/{if($$1 != "$(TAG)"){print $$2}}' \
  | xargs -I {} docker rm $2 {}
endef

define remove_images
@echo 'Trying to remove old images ...'
@docker images --no-trunc \
  | awk '$(FIELDS_PARSER){if(fld["REPOSITORY"] != "$(NAME)"){next};if(fld["TAG"] == "$(VERSION)-$(BUILD)"){next};print fld["REPOSITORY"] ":" fld["TAG"]}' \
  | xargs -I {} 'docker rmi $1 {} || true'
endef


help:
	@echo $(MAKEFILE_LIST)

build: build.done
build.done: $(SOURCE_FILES)
	$(call build,$(ERR_FAIL),$(NO_CACHE))
	@touch $@

tag-latest:
	docker tag -f $(TAG) $(NAME):latest

create:
	$(call check_container_exists,1)
	$(call create)

run: build.done create
	$(call action,start)

start stop restart:
	$(call action,$@)

upgrade: build.done
	$(call action,stop)
	$(call clean_containers,$(FILTER_NOT_RUNNING))
	$(call check_container_exists,1)
	$(call create)
	$(call action,start)

destroy:
	$(call action,stop)
	$(call action,rm,,$(FORCE))

shell: build.done
	@test -n "$$(docker ps --quiet --filter name=$(NAME))" \
	  && docker exec --interactive --tty $(NAME) /bin/bash \
	  || docker run --interactive --tty $(DOCKER_OPTIONS) $(ENV_FILE) $(TAG) /bin/bash

purge: destroy
	@echo "Removing containers based on $(TAG) with force"
	@docker ps --all --no-trunc \
	  | awk '$(FIELDS_PARSER){if(fld["IMAGE"] == "$(TAG)"){print fld["CONTAINER ID"]}}' \
	  | xargs -I {} docker rm --force {}
	@echo "Removing image $(TAG) ..."
	@test -z "$$(docker images --quiet $(TAG))" \
	  && (echo "There is no image tagged $(TAG)") \
	  || (docker rmi $(TAG))
	rm build.done || true

#>>>
#.target clean
#.summary Remove stopped containers based on exact image name and tag
#<<<
clean:
	@docker ps --all --no-trunc \
	  | awk '$(FIELDS_PARSER){if(fld["STATUS"] ~ /^Up/){next};if(fld["IMAGE"] == "$(TAG)"){print fld["CONTAINER ID"]}}' \
	  | xargs -I {} docker rm $2 {}
	$(call remove_images)


#>>>
#.target clean-all
#.summary Remove stopped containers based on image name only (with any tag)
#<<<
clean-all:
	@docker ps --all --no-trunc \
	  | awk '$(FIELDS_PARSER){if(fld["STATUS"] ~ /^Up/){next};split(fld["IMAGE"],a,":");if(a[1] == $(NAME)){print fld["CONTAINER ID"]}}' \
	  | xargs -I {} docker rm $2 {}
	$(call remove_images)

