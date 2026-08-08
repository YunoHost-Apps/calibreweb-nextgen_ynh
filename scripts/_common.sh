#!/bin/bash

#=================================================
# COMMON VARIABLES AND CUSTOM HELPERS
#=================================================

# Path for the service to retrieve the Calibre tools
path_with_calibre="$install_dir/tools/calibre:$install_dir/bin:$data_dir/bin:$PATH"

log_file=/var/log/$app/$app.log
access_log_file=/var/log/$app/$app-access.log

_ynh_create_koplugin() {
 if [ -d "$install_dir/build/koreader/plugins/cwasync.koplugin" ]; then \
    cd $install_dir/build/koreader/plugins && \
    # Calculate digest of all files in the plugin for debugging purposes
    PLUGIN_DIGEST=$(find cwasync.koplugin -type f -name "*.lua" -o -name "*.json" | sort | xargs sha256sum | sha256sum | cut -d' ' -f1) && \
    echo "Plugin digest: $PLUGIN_DIGEST" && \
    # Create a file named after the digest inside the plugin folder
    echo "Plugin files digest: $PLUGIN_DIGEST" > cwasync.koplugin/${PLUGIN_DIGEST}.digest && \
    echo "Build date: $(date)" >> cwasync.koplugin/${PLUGIN_DIGEST}.digest && \
    echo "Files included:" >> cwasync.koplugin/${PLUGIN_DIGEST}.digest && \
    find cwasync.koplugin -type f -name "*.lua" -o -name "*.json" | sort >> cwasync.koplugin/${PLUGIN_DIGEST}.digest && \
    zip -r koplugin.zip cwasync.koplugin/ && \
    echo "Created koplugin.zip from cwasync.koplugin folder with digest file: ${PLUGIN_DIGEST}.digest"; \
  else \
    echo "Warning: cwasync.koplugin folder not found, skipping zip creation"; \
  fi && \
  	# Move koplugin.zip to static directory
  if [ -f "$install_dir/build/koreader/plugins/koplugin.zip" ]; then \
    mkdir -p $install_dir/build/cps/static && \
    cp $install_dir/build/koreader/plugins/koplugin.zip $install_dir/build/cps/static/ && \
    echo "Moved koplugin.zip to static directory"; \
  else \
    echo "Warning: koplugin.zip not found, skipping move to static directory"; \
  fi
}

_ynh_adapt_cwng_db() {
  # Correct path of binaries
  sqlite3 $install_dir/config/app.db "UPDATE settings SET config_kepubifypath='$install_dir/tools/kepubify'"
  sqlite3 $install_dir/config/app.db "UPDATE settings SET config_binariesdir='$install_dir/tools/calibre'"
  sqlite3 $install_dir/config/app.db "UPDATE settings SET config_converterpath='$install_dir/tools/calibre/ebook-convert'"

  # Add correct ldap values for ldap support
  sqlite3 $install_dir/config/app.db "UPDATE settings SET config_login_type='1'"
  sqlite3 $install_dir/config/app.db "UPDATE settings SET config_ldap_provider_url='localhost'"
  sqlite3 $install_dir/config/app.db "UPDATE settings SET config_ldap_dn='dc=yunohost,dc=org'"
  sqlite3 $install_dir/config/app.db "UPDATE settings SET config_ldap_user_object='(&(objectClass=posixAccount)(permission=cn=$app.main,ou=permission,dc=yunohost,dc=org)(uid=%s))'"
  sqlite3 $install_dir/config/app.db "UPDATE settings SET config_ldap_group_object_filter='(&(objectClass=posixGroup)(cn=%s.main))'"

  # Correct logs path
  sqlite3 $install_dir/config/app.db "UPDATE settings SET config_logfile='$log_file'"
  sqlite3 $install_dir/config/app.db "UPDATE settings SET config_access_log='1'"
  sqlite3 $install_dir/config/app.db "UPDATE settings SET config_access_logfile='$access_log_file'"

  # Correct mail settings
  sqlite3 $install_dir/config/app.db "UPDATE settings SET mail_server='$domain'"
  sqlite3 $install_dir/config/app.db "UPDATE settings SET mail_port='587'"
  sqlite3 $install_dir/config/app.db "UPDATE settings SET mail_use_ssl='1'"
  sqlite3 $install_dir/config/app.db "UPDATE settings SET mail_login='$app'"
  sqlite3 $install_dir/config/app.db "UPDATE settings SET mail_password='$mail_pwd'"
  sqlite3 $install_dir/config/app.db "UPDATE settings SET mail_from='$app@$domain'"

  # Correct misc
  sqlite3 $install_dir/config/app.db "UPDATE settings SET config_external_port='$port'"
}
