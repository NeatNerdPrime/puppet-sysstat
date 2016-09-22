# == Class: sysstat
#
# A module to manage the sysstat configuration
#
class sysstat(
  # Class parameters are populated from module hiera data
  $package,
  $cron_path,
  $conf_path,
  $sa1_path,
  $sa2_path,
  # Class parameters are populated from External(hiera)/Defaults/Fail
  String $sa1_options = "-S ALL",
  Integer $interval = 2,
  Integer $duration = 2,
  Integer $samples = 1,
  Integer $history = 10,
  Integer $compressafter = 31,
  String $sadc_options = "-S DISK",
  String $zip = "bzip2",
) {

  $duration_seconds = $duration * 60 - 1

  $cron_conf_template = @(END)
# FILE MANAGED BY PUPPET
#
# crontab for sysstat

# Collect data for <%= $duration %> minutes every <%= $interval %> minutes continuously
*/<%= $interval %> * * * * root [ -x <%= $sa1_path %> ] && exec <%= $sa1_path %> <%= $sa1_options %> <%= $duration_seconds %> <%= $samples %>
END

  file { $cron_path:
    ensure  => file,
    content => inline_epp($cron_conf_template, { sa1_path => $sa1_path, sa1_options => $sa1_options, sa2_path => $sa2_path, interval => $interval, duration => $duration, duration_seconds => $duration_seconds, samples => $samples }),
  }

  $sysconfig_conf_template = @(END)
# FILE MANAGED BY PUPPET
#
# sysstat configuration file.

# How long to keep log files (in days).
# If value is greater than 28, then log files are kept in
# multiple directories, one for each month.
HISTORY=<%= $history %>

# Compress (using gzip or bzip2) sa and sar files older than (in days):
COMPRESSAFTER=<%= $compressafter %>

# Parameters for the system activity data collector (see sadc manual page)
# which are used for the generation of log files.
SADC_OPTIONS="<%= $sadc_options %>"

# Compression program to use.
ZIP="<%= $zip %>"
END

  package { $package:
    ensure => latest,
  } ->

  file { $conf_path:
    ensure  => file,
    content => inline_epp($sysconfig_conf_template, { history => $history, compressafter => $compressafter, sadc_options => $sadc_options, zip => $zip }),
  }

}



