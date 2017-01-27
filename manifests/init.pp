# == Class: sysstat
#
# A module to manage the sysstat configuration
#
class sysstat(
  # Class parameters are populated from module hiera data
  String $package,
  String $cron_path,
  String $conf_path,
  String $sa1_path,
  String $sa2_path,

  # Class parameters are populated from External(hiera)/Defaults/Fail
  String    $sa1_options   = '-S ALL',
  Integer   $interval      = 2,
  Integer   $duration      = 2,
  Integer   $samples       = 1,
  Integer   $history       = 10,
  Integer   $compressafter = 31,
  String    $sadc_options  = '-S DISK',
  String    $zip           = 'bzip2',
  String    $installpkg    = 'yes',
) {

  $duration_seconds = $duration * 60 - 1

  file { $cron_path:
    ensure  => file,
    content => epp('sysstat/crontab.epp', {
      sa1_path         => $sa1_path,
      sa1_options      => $sa1_options,
      sa2_path         => $sa2_path,
      interval         => $interval,
      duration         => $duration,
      duration_seconds => $duration_seconds,
      samples          => $samples
    }),
  }

  if $installpkg == 'yes' {
    package { $package:
      ensure => installed,
    }
  } ->

  file { $conf_path:
    ensure  => file,
    content => epp('sysstat/sysconfig.epp', {
      history       => $history,
      compressafter => $compressafter,
      sadc_options  => $sadc_options,
      zip           => $zip,
    }),
  }

}



