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
  String $aix_provider,

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
  String    $aix_lpp_source   = '',
) {
  # Convert duration to seconds
  $sa1_duration_seconds = $sa1_duration * 60 - 1

  if $disable == 'yes' {
    $ensure = 'absent'
  } else {
    $ensure = 'file'
  }

  case $::osfamily {
    'AIX': {
      cron { 'sa1_path_weekday':
              ensure  => $ensure,
              command => "${sa1_path} 1200 3 &",
              user    => 'adm',
              hour    => '8-17',
              minute  => 0,
              weekday => '1-5',
      }
      cron { 'sa1_path_weekday_after_hours':
              ensure  => $ensure,
              command => "${sa1_path} &",
              user    => 'adm',
              minute  => 0,
              hour    => '18-7',
              weekday => '1-5',
      }
      cron { 'remove_sa1_path_weekend':
              ensure   => absent,
              command  => "${sa1_path} &",
              user     => 'adm',
              minute   => '0',
              hour     => '*',
              month    => '*',
              monthday => '*',
      }
      cron { 'sa1_path_weekend':
              ensure  => $ensure,
              command => "${sa1_path} &",
              user    => 'adm',
              minute  => 0,
              weekday => '6-0',
      }
      cron { 'sa2_path_weekday_after_hours':
              ensure  => $ensure,
              command => "${sa2_path} -s 8:00 -e 18:01 -i 3600 -ubcwyaqvm &",
              user    => 'adm',
              minute  => 5,
              hour    => '18',
              weekday => '1-5',
      }
      if $ensure and empty($aix_lpp_source) {
        fail( 'AIX LPP Source cannot be blank if the sysstat package must be installed')
      }
      $pkg_ensure = $ensure ? { true => latest, default => $ensure }
      package { $package:
        ensure   => $pkg_ensure,
        provider => $aix_provider,
        source   => $aix_lpp_source,
      }
    }
    default: {
      file { $cron_path:
        ensure  => $ensure,
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
        }
      }
      -> file { $conf_path:
        ensure  => file,
        content => epp('sysstat/sysconfig.epp', {
          history       => $history,
          compressafter => $compressafter,
          sadc_options  => $sadc_options,
          zip           => $zip,
        }),
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
