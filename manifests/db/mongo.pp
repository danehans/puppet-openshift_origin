# TODO- Add documentation
# TODO- Missing Mongo Admin user/password
#
class openshift_origin::db::mongo(
  $bind_ip               = ['127.0.0.1',$::openshift_origin::datastore_bind_ip],
  $bind_port             = $::openshift_origin::datastore_bind_port,
  $smallfiles            = $::openshift_origin::mongodb_smallfiles,
  $verbose               = $::openshift_origin::mongodb_verbose,
  $auth                  = $::openshift_origin::mongodb_auth,
  $rest                  = $::openshift_origin::mongodb_rest,
  $create_db             = $::openshift_origin::mongodb_create_db,
  $create_admin_user     = $::openshift_origin::mongodb_create_admin_user,
  $enable_replica_sets   = $::openshift_origin::enable_replica_sets,
  $replica_sets_name     = $::openshift_origin::replica_sets_name,
  $replica_sets_host1    = $::openshift_origin::datastore1_hostname,
  $replica_sets_host2    = $::openshift_origin::datastore2_hostname,
  $replica_sets_host3    = $::openshift_origin::datastore3_hostname,
  $replica_sets_host1_ip = $::openshift_origin::datastore1_ip,
  $replica_sets_host2_ip = $::openshift_origin::datastore2_ip,
  $replica_sets_host3_ip = $::openshift_origin::datastore3_ip,
  $replica_sets_key      = $::openshift_origin::replica_sets_key,
  $openshift_db_name     = $::openshift_origin::mongodb_name,
  $admin_user            = $::openshift_origin::mongodb_admin_user,
  $admin_password_hash   = $::openshift_origin::mongodb_admin_password_hash,
  $admin_password        = $::openshift_origin::mongodb_admin_password,
  $admin_role            = [
                             'read',
                             'readWrite',
                             'dbAdmin',
                             'userAdmin',
                             'clusterAdmin',
                             'readAnyDatabase',
                             'readWriteAnyDatabase',
                             'userAdminAnyDatabase',
                             'dbAdminAnyDatabase'
                           ],
  $broker_user           = $::openshift_origin::mongodb_broker_user,
  $broker_password       = $::openshift_origin::mongodb_broker_password,
  $broker_role           = ['readWrite', 'dbAdmin', 'userAdmin', 'clusterAdmin']
) {

  if $create_db {
    Mongodb_database[$openshift_db_name] -> Mongodb_user[$broker_user]
  }

  if $::operatingsystem == 'RedHat' {
    require 'mongodb::client'
  }

  if $enable_replica_sets {
    $replica_sets_name_real = $replica_sets_name
    host { $replica_sets_host1:
      ip => $replica_sets_host1_ip,
    }
    host { $replica_sets_host2:
      ip => $replica_sets_host2_ip,
    }
    host { $replica_sets_host3:
      ip => $replica_sets_host3_ip,
    }
    if $create_admin_user {
      Mongodb_user[$admin_user] -> Mongodb_replset[$replica_sets_name]
    }
    if $create_db {
      Mongodb::Db[$openshift_db_name] -> Mongodb_replset[$replica_sets_name]
    }
    mongodb_replset { $replica_sets_name_real:
      ensure   => present,
      auth     => $auth,
      user     => $admin_user,
      password => $admin_password,
      members  => [
                   "${replica_sets_host1}:${bind_port}",
                   "${replica_sets_host2}:${bind_port}",
                   "${replica_sets_host3}:${bind_port}"
                 ],
    }
  } else {
    $replica_sets_name_real = undef
  }

  if $auth and $replica_sets_key {
    $keyfile_real = $::openshift_origin::replica_sets_keyfile
  } else {
    $keyfile_real = undef
  }

  class {'mongodb::server':
    ensure     => true,
    bind_ip    => $bind_ip,
    port       => $bind_port,
    smallfiles => $smallfiles,
    verbose    => $verbose,
    auth       => $auth,
    rest       => $rest,
    replset    => $replica_sets_name_real,
    keyfile    => $keyfile_real,
    key        => $replica_sets_key,
    require    => Class['openshift_origin::yum_install_method'],
  }

  if $create_admin_user {
    mongodb_user { $admin_user:
      ensure        => present,
      auth          => $auth,
      password      => $admin_password,
      password_hash => mongodb_password($admin_user, $admin_password),
      database      => 'admin',
      roles         => $admin_role,
      require       => Class['mongodb::server'],
    }
  }

  if $create_db {
    mongodb::db { $openshift_db_name:
      auth     => $auth,
      user     => $broker_user,
      password => $broker_password,
      roles    => $broker_role,
    }
  }

  firewall{ 'mongo-firewall':
    port      => $bind_port,
    protocol  => 'tcp',
  }
}
