#!/bin/bash
service redis-server start
service postgresql start
# An admin account has to be created before Google OAuth can be finalized so this command runs after the first restart
if [ -f "/secondtime" ]; then
	if [ -n "$GOOGLE_CLIENT_ID" ]; then
		cd $REDASH_BASE_PATH/current
		sudo -u redash bin/run ./manage.py org set_google_apps_domains ${BASE_URL}
	fi
	rm -f /secondtime
fi
# These commands run only the first time the container is started to setup the environment
if [ -f "/firstime" ]; then
	COOKIE_SECRET=$(pwgen -1s 32)
    	echo "export REDASH_COOKIE_SECRET=$COOKIE_SECRET" >> $REDASH_BASE_PATH/.env
	# Google SSO
	if [ -n "$GOOGLE_CLIENT_ID" ]; then
		echo "export REDASH_GOOGLE_CLIENT_ID=\"${GOOGLE_CLIENT_ID}\"" >> $REDASH_BASE_PATH/.env
		echo "export REDASH_GOOGLE_CLIENT_SECRET=\"${GOOGLE_CLIENT_SECRET}\"" >> $REDASH_BASE_PATH/.env
	fi
	# Gmail email sending
	if [ -n "$GMAIL_ADDR" ]; then
		echo "export REDASH_MAIL_DEFAULT_SENDER=\"${GMAIL_ADDR}\"" >> $REDASH_BASE_PATH/.env
		echo "[smtp.gmail.com]:587 ${GMAIL_ADDR}:${GMAIL_PASSWD}" > /etc/postfix/sasl_passwd
		chmod 600 /etc/postfix/sasl_passwd
		postmap hash:/etc/postfix/sasl_passwd
	else
		echo "export REDASH_MAIL_DEFAULT_SENDER=\"nobody@dezota.com\"" >> $REDASH_BASE_PATH/.env
	fi
	# Set Base URL
	if [ -n "$BASE_URL" ]; then
		echo "export REDASH_HOST=\"${BASE_URL}\"" >> $REDASH_BASE_PATH/.env
	fi
	rm -f /firstime
	touch /secondtime
fi
service postfix start
service nginx start
service supervisor start
tail -f /var/log/supervisor/*
