# puppet-sysstat
Puppet module to manage the installation and configuration of Sysstat on various OSes.

This module will install the sysstat package, update the sysstat crontab file and the main sysstat configuration file.  It has reasonable defaults, but the defaults can be overidden through hiera.

## Instructions
Call the class from your code, e.g. `class { 'sysstat': }` or `include 'sysstat'`

Optionally put the following variables into hiera and adjust to your requirements. The values listed below are the defaults.
```
  sysstat::sa1_options: "-S ALL"
  # interval is in minutes - how often to launch sa1
  sysstat::sa1_interval: 2
  # duration is in minutes - how to run sa1 each time
  sysstat::sa1_duration: 2
  # samples - how many samples to take while running
  sysstat::sa1_samples: 1
  sysstat::sa2_options: "-A"
  sysstat::sa2_hour: '23'
  sysstat::sa2_minute: '53'
  sysstat::history: 10
  # compressafter is in days
  sysstat::compressafter: 31
  sysstat::sadc_options: "-S DISK"
  sysstat::zip: "bzip2"
  sysstat::installpkg: 'yes'
  sysstat::generate_summary: 'yes'
  sysstat::disable: 'no'

```
Setting the `disable` setting to `'yes'` will remove the cron entries, but leave the package installed.

The `generate_summary` option determines whether or not sa2 is active (often called daily summary).

## Limitations
The sa1 invocation duration needs to a minute or greater.  If sub minute sample sizes are required, set the `sa1_samples` parameter to greater than 1 to take multiple samples per invocation of sa1.

## Platform Notes
### Suse
On Suse based systems, the defaults for these parameters are different to match how it ships:
```
  sysstat::sa2_hour: '5,11,17,23'
  sysstat::sa2_minute: '55'

```
### Debian\Ubuntu
Debian based systems normally use the cron.daily to run the summary reports.  This Puppet module will convert this behavior to align with the Red Hat way.  Let me know if this creates any issues for anyone and it can be made into an option or better still create a pull request adding the functionality.
    
## Issues
This module is using hiera data that is embedded in the module rather than using a params class.  This may not play nicely with other modules using the same technique unless you are using hiera 3.0.6 and above (PE 2015.3.2+).
