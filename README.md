# puppet-sysstat
Puppet module to manage the installation and configuration of Sysstat on various OSes.

This module will install the sysstat package, update the sysstat crontab file and the main sysstat configuration file.  It has reasonable defaults, but the defaults can be overidden through hiera.

## Instructions
Put the following values into hiera.  The values below are the defaults, so you can ommit them if you are happy with the defaults.
```
  sysstat::sa1_options = "-S ALL",
  sysstat::interval = 2,
  sysstat::duration = 2,
  sysstat::samples = 1,
  sysstat::history = 10,
  sysstat::compressafter = 31,
  sysstat::sadc_options = "-S DISK",
  sysstat::zip = "bzip2",
```
    
Call the class from your code, e.g. `class { 'sysstat': }`

## Issues
This module is using hiera data that is embedded in the module rather than using a params class.  This may not play nicely with other modules using the same technique unless you are using hiera 3.0.6 and above (PE 2015.3.2+).
