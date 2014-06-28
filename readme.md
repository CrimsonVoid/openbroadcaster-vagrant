## Setup
  1. Download [virtualbox](https://www.virtualbox.org/wiki/Downloads) and
      [vagrant](http://downloads.vagrantup.com/)
  2. Run `vagrant up` to start and configure the VM. This will need to download a
      ~360 MB file the first time you run it. The provisioning step will take a
      while during which nothing will be printed; if you would like confirmation
      something is happening uncomment line 21 in Vagrantfile.
  3. Go to "localhost:8080" in your browser and login with admin/admin
      If port 8080 is in use by another program this will differ. Look for
      a line like
      `[default] Fixed port collision for 80 => 8080. Now on port 2200.`
      and substite the appropriate port.
  4. When you are done working shut down the VM with `vagrant halt`


## Basic Usage
  - `vagrant up`        Boots and provisions VM according to Vagrantfile
  - `vagrant provision` Configures an already running VM
  - `vagrant ssh`       SSH into a running VM
  
  - `vagrant suspend` Saves the VM state allowing you to resume exactly where you left
       off, bypassing boot sequence. This will use extra disk space to save RAM but
       no longer uses RAM or CPU cycles
  - `vagrant resume`  Resumes a suspended VM
  - `vagrant halt`    Shuts down VM
  - `vagrant destroy` Deletes VM from disk
