# == Class: sysstat
#
# A module to manage the sysstat configuration
#
class sysstat (
  # Class parameters are populated from module hiera data
  String $package,
  String $cron_path,
  String $cron_path2,
  String $conf_path,
  String $sa1_path,
  String $sa2_path,
  String $sa2_hour,
  String $sa2_minute,
  String $sa_dir,

  # Class parameters are populated from External(hiera)/Defaults/Fail
  String    $sa1_options      = '-S ALL',
  Integer   $interval         = 2,
  Integer   $sa1_interval     = $interval,
  Integer   $duration         = 2,
  Integer   $sa1_duration     = $duration,
  Integer   $samples          = 1,
  Integer   $sa1_samples      = $samples,
  String    $sa2_options      = '-A',
  Integer   $history          = 10,
  Integer   $compressafter    = 31,
  String    $sadc_options     = '-S DISK',
  String    $zip              = 'bzip2',
  String    $installpkg       = 'yes',
  String    $generate_summary = 'yes',
  String    $disable          = 'no',
  Integer   $sa2_delay_range  = 0,
  String    $sa_umask         = '0022',
) {
  # Convert duration to seconds
  $sa1_duration_seconds = $sa1_duration * 60 - 1

  if $disable == 'yes' {
    $file_ensure = 'absent'
    $cron_ensure = 'absent'
    $pkg_ensure = 'absent'
  } else {
    $file_ensure = 'file'
    $cron_ensure = 'present'
    $pkg_ensure = 'latest'
  }

  case $::osfamily {
    'AIX': {
      cron { 'sa1_path_weekday':
              ensure  => 'absent',
              command => "${sa1_path} 1200 3 &",
              user    => 'adm',
              hour    => ['8-17'],
              minute  => [0],
              weekday => ['1-5'],
      }
      cron { 'sa1_path_weekday_after_hours':
              ensure  => 'absent',
              command => "${sa1_path} &",
              user    => 'adm',
              minute  => [0],
              hour    => ['18-7'],
              weekday => ['1-5'],
      }
      cron { 'sa1_path_weekend':
              ensure  => 'absent',
              command => "${sa1_path} &",
              user    => 'adm',
              minute  => [0],
              weekday => [0,6],
      }
      cron { 'sa2_path_weekday_after_hours':
              ensure  => $cron_ensure,
              command => "${sa2_path} -s 8:00 -e 18:01 -i 3600 -ubcwyaqvm &",
              user    => 'adm',
              minute  => [5],
              hour    => [18],
              weekday => ['1-5'],
      }
      cron { 'sa1_daily_5_mins':
              ensure  => $cron_ensure,
              command => "${sa1_path} &",
              user    => 'adm',
              minute  => [0,5,10,15,20,25,30,35,40,45,50,55],
              weekday => ['0-6'],
      }
    }
    default: {
      file { $cron_path:
        ensure  => $file_ensure,
        content => epp('sysstat/crontab.epp', {
          sa1_path             => $sa1_path,
          sa1_options          => $sa1_options,
          sa1_interval         => $sa1_interval,
          sa1_duration         => $sa1_duration,
          sa1_duration_seconds => $sa1_duration_seconds,
          sa1_samples          => $sa1_samples,
          sa2_path             => $sa2_path,
          sa2_options          => $sa2_options,
          sa2_minute           => $sa2_minute,
          sa2_hour             => $sa2_hour,
          generate_summary     => $generate_summary,
        }),
      }

      if $installpkg == 'yes' {
        package { $package:
          ensure => installed,
          before => File[$conf_path],
        }
      }
      file { $conf_path:
        ensure  => file,
        content => epp('sysstat/sysconfig.epp', {
          history         => $history,
          compressafter   => $compressafter,
          sa_dir          => $sa_dir,
          sa2_delay_range => $sa2_delay_range,
          sadc_options    => $sadc_options,
          sa_umask        => $sa_umask,
          zip             => $zip,
        }),
      }

      file { $sa_dir:
        ensure => directory,
        owner  => 'root',
        group  => 'root',
      }

      # With this module we disable the Debian uniqueness regardless of whether 
      # the module is disabled or not
      if $facts['os']['family'] == 'Debian' {
        service { 'sysstat':
          ensure => false,
          enable => false,
        }
        file { $cron_path2:
          ensure => absent,
        }
      }
    }
  }
}
