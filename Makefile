include config.mk

SHELL := bash
D := docker
DC := docker-compose

SERVICE_NGINX := nginx
SERVICE_MANTISBT := mantisbt
SERVICE_MANTISBT_INSTALL := mantisbt-install
SERVICE_MYSQL := mysql
SERVICES := $(SERVICE_NGINX) $(SERVICE_MANTISBT) $(SERVICE_MYSQL)
INSTALLATION_SERVICES := $(SERVICE_MYSQL) $(SERVICE_MANTISBT_INSTALL)

CFG_FILES := .env .mt_config.env ./mantisbt/mtbt.ini ./nginx/mtbt.conf.template

ifeq ($(USER_ID), )
	USER_ID := $(shell id -u)
endif

ifeq ($(GROUP_ID),)
	GROUP_ID := $(shell id -g)
endif

.PHONY: help
help:
	@echo "Usage:" && \
		echo "make start - build (if necessary) and start services" && \
		echo "make stop - stop services" && \
		echo "make ps - show the running status of the services" && \
		echo "make logs - show the containers logs in life time" && \
		echo "make recreate - force rebuild services" && \
		echo "make backup - backup the current state" && \
		echo "make restore - restore a state from the last backup"

.PHONY: start
start: $(CFG_FILES) ./mantisbt_src/
	@$(DC) up --build --remove-orphans -d $(SERVICES)

.PHONY: stop
stop: $(CFG_FILES)
	@$(DC) stop $(SERVICES)

.PHONY: restart
restart: stop start

.PHONY: ps
ps: $(CFG_FILES)
	@$(DC) ps

.PHONY: logs
logs: $(CFG_FILES)
	@$(DC) logs -f

.PHONY: recreate
recreate: $(CFG_FILES)
	@$(DC) up --build --force-recreate -d $(SERVICES)

.PHONY: remove
remove:
	@$(DC) down --remove-orphans

.PHONY: clear
clear:
	@$(DC) down --remove-orphans --rmi all -v && (rm $(CFG_FILES); rm -rf ./mantisbt_src) &>/dev/null || true

.PHONY: backup
backup: .my.cnf $(BACKUP_DIR)
	@cp .my.cnf $(BACKUP_DIR)/.my.cnf && \
		echo -n "Backuping... " && \
		$(DC) run --rm -u $$(id -u):$$(id -g) -v $(BACKUP_DIR)/:/tmp/backup/ $(SERVICE_MYSQL) \
			bash -c "mysqldump --defaults-file=/tmp/backup/.my.cnf  bugtracker | gzip > /tmp/backup/$(BACKUP_SQL_FILE_NAME)" && \
		echo "[done]" || echo "[failed]" && \
		echo "MySQL backup: $(BACKUP_SQL_FILE)"

.PHONY: restore
restore: .my.cnf $(BACKUP_DIR)
	@test -f $(BACKUP_SQL_FILE) && \
		( \
			read -p "Do you really want to restore from a backup? [y/N]: " answer && \
				test  "$${answer}" == "y" && \
				( \
					cp .my.cnf $(BACKUP_DIR)/.my.cnf && \
					echo -n "Restoring the dump... " && \
					$(DC) run --rm -u $$(id -u):$$(id -g) -v $(BACKUP_DIR)/:/tmp/backup/ $(SERVICE_MYSQL) \
						bash -c "cat /tmp/backup/$(BACKUP_SQL_FILE_NAME) | gunzip | mysql --defaults-file=/tmp/backup/.my.cnf $(MYSQL_DATABASE)" && \
					echo "[done]" \
				) || true \
		) || echo "$(BACKUP_SQL_FILE) does not exist"

$(BACKUP_DIR):
	@echo -n "Creating the backup dir... " && mkdir -p $(BACKUP_DIR) &> /dev/null && echo "[done]" || echo "[failed]"

.mt_config.env: config.mk .mt_config.env.tmpl
	@cat ./.mt_config.env.tmpl | envsubst > $@

.my.cnf: config.mk
	@echo -e "[mysql]\nhost=mysql\nuser=root\npassword=${MYSQL_ROOT_PASSWORD}" > $@ && \
		echo -e "\n[mysqldump]\nhost=mysql\nuser=root\npassword=${MYSQL_ROOT_PASSWORD}" >> $@

.env: config.mk .env.tmpl
	@cat ./.env.tmpl | envsubst > $@

./mantisbt/mtbt.ini: config.mk ./mantisbt/mtbt.ini.tmpl
	@cat ./mantisbt/mtbt.ini.tmpl | envsubst > $@

./nginx/mtbt.conf.template: export DSIGN=$$
./nginx/mtbt.conf.template: config.mk ./nginx/mtbt.conf.tmpl
	@cat ./nginx/mtbt.conf.tmpl | envsubst > $@

./mantisbt_src/:
	@mkdir $@ && $(DC) up --build -d $(SERVICE_MYSQL) && $(DC) up --build $(SERVICE_MANTISBT_INSTALL) && $(DC) rm -fsv $(SERVICE_MANTISBT_INSTALL)

config.mk: config.mk.example
	@cp $< $@
