class profile::windows_sqlserver(
  String $svc_acct,
  String $svc_pwd,
  String $sa_acct,
Optional[String] $sec_mode,
  Array $app_adm_acct,
  String $instance,
  String $source,
  Array $features,
  Integer $enable_tcp,
  String $dir_inst,
  String $dir_share,
  String $dir_wow,
  String $dir_data,
  String $dir_log,
  String $dir_backup,
  String $dir_tmp,
  String $postinstall,
  String $sql_ver,
  ){ 

# Ensure .NET3.5 is installled
  windowsfeature { 'NET-Framework-Core':
    ensure => present,
    before => Exec['sqlserver_dnld'],
  }
  $srvname  = $::facts['hostname']
  $download = "profile/windows/${sql_ver}.ps1"
    exec { 'sqlserver_dnld':
      command  => file($download),
      provider => powershell,
      timeout  => 7200,
      creates  => "C:\\Program Files (x86)\\Microsoft SQL Server\\110\\COM\\instapi110.dll",
    } 

    if ($app_adm_acct != undef) {
      user { $app_adm_acct:
        ensure   => present,
        password => $svc_pwd,
        groups   => ['Administrators'],
      }

    } 

    # Install SQL Server

      sqlserver_instance { $instance:
        source                => $source,
        features              => $features,
        security_mode         => $sec_mode,
        sql_sysadmin_accounts => $sa_acct,
        sql_svc_account       => $svc_acct,
        sql_svc_password      => $svc_pwd,
        install_switches      => {
          'TCPENABLED'          => $enable_tcp,
          'SQLTEMPDBLOGDIR'     => $dir_log,
          'SQLUSERDBLOGDIR'     => $dir_log,
          'SQLBACKUPDIR'        => $dir_backup,
          'SQLTEMPDBDIR'        => $dir_tmp,
          'INSTALLSQLDATADIR'   => $dir_data,
          'INSTANCEDIR'         => $dir_inst,
          'INSTALLSHAREDDIR'    => $dir_share,
          'INSTALLSHAREDWOWDIR' => $dir_wow,
          'UpdateEnabled'       => 0,
        },
        require               => User[$app_adm_acct],
      }
 

      sqlserver_features { 'Generic Features':
        source           => $source,
        features         => ['IS', 'MDS', 'SSMS'],
        install_switches => {
          'UpdateEnabled'  => 0,
        },
      } 

      # OPTIONAL Application Admin Group should be members of the Administrators group if provided.

 

      # Profile for SQL Post installation
    #  exec { 'sql_post_install':
    #  command   => "powershell.exe -File ${postinstall} ${srvname} ${instance}",
    #  provider  => powershell,
    #  logoutput => true,
    #  }
 

      # Remove the setup directory & files
      file {'remove_directory':
        ensure  => absent,
        path    => 'C:/DBA',
        recurse => true,
        purge   => true,
        force   => true,
      }
}
