##WRT Buildroot Manager ("WBM")

This is a buildroot-inspired project manager for streamlining usage of the OpenWRT build root for your own
custom images. It is designed to be particularly useful when working with several different configurations
concurrently.

It should also work with OpenWRT forks such as [CeroWRT](https://github.com/dtaht/cerowrt-3.10).

###Features

* Maintain a clean dot config seed file
* Run `git clean -x -f -d` in project without destroying the compiled host buildroot `build_dir/host` and 
  having to recompile world.
* Manage image additions and patches
* Simple configuration file
* Git repository integration
* Improved cohesion of settings compared to using `scripts/env`

###Advanced Features

* Support for using a vendor/GPL sources kernel tree against the OpenWRT userspace
* Support for tuning by stripping CONFIG_BOARD_XXX code for irrelevant boards

Other techniques:

* WRT-kernel config management
* uClibc config patching
* feeds management
* patch management
* files management
* Shared download area with git-annex management

###How it Works

A WBM project consists of a git repository that contains all settings relevant to the build. This builds on the
concept embodied by OpenWRT `scripts/env` but without all the mucking around with symbolic links, and with
more transparent integration with git.

The OperWRT buildroot is a working subdirectories to the working copy.

Essentially a WBM project git working copy is similar in concept to a project in a tool like like Eclipse IDE.
The project directory will be initialised with a configuration file, and a convenience shell script that sets
the PATH and fetches the WBM code from git as needed.

##Usage

###Installation

    git clone path/to/wbm/repo wrt-buildroot-manager
    path/to/wrt-buildroot-manager/configure.sh

###To start a session (for regular use, recommend this be added to your bashrc/profile)

This will add `wrt-project` to your PATH and set any other necessary environment variables.

    source path/to/wrt-buildroot-manager/wrt-buildroot-manager.source

###Creating a new WBM project

    wrt-project create path/to/project-dir
    cd path/to/project-dir
    wrt-project build 

The new directory `project-dir` is created with a new git repository and the following files:

* custom.project
* .gitignore
* bootstrap.sh
* dot.config
* README.md

The following additional files are not created initially but are used in the build process if present:

* feeds.conf
* files/*

In the future it would be desirable to use a Kconfig like mechanism to provide a nice user interface.
For the time being, open `custom.project` in a text editor and tune as desired.

The file `bootstrap.sh` is provided as a convenience for downloading wrt-buildroot-manager from GitHub if you
don't have it yet.

If you have to create a lot of projects that have a similar core of options, you can set a template for
custom.project files. This is merged over the default `custom.project` with the template taking precedence.

    wrt-project create template=path/to/template/dir

To avoid init'ing a git repository - useful if you have multiple projects inside one top level git repository -

    wrt-project create --no-git
    # or
    wrt-project create --no-git template=path/to/template/dir

###To start using an existing WBM project

    git clone path/to/wbm/project/repo project
    cd path/to/project
    wrt-project build 

###Using a WBM project 

The 'build' command will execute _a lot_ of prerequisite activities, including heavy Internet traffic, 
if they haven't happened yet.  In full:

* Clone the OpenWRT git repository specified in custom.project to `openwrt/`
* Apply quilt series `patches/preliminary/*` to `openwrt/`
* Copy $(CUSTOM_FEEDS) to `openwrt/feeds.conf`
* Run OpenWRT `scripts/feeds update`
* Install packages using `scripts/feeds install` as listed in file $(CUSTOM_PACKAGES) if it exits
* The above steps will only happen once with build; a .stamp file is created to control this.
* Run OpenWRT `make defconfig` as described below in Enhanced .config file maintenance
* Apply quilt series `patches/routine/*` to `openwrt/`
* Apply quilt series `patches/uClibc/*` to `openwrt/`
* Apply kernel configuration
* Copy $(CUSTOM_FILES)/ to `openwrt/files/`
* Run OpenWRT `make world` which will do the following:
** Build the host tools, including source download if not present in WRT $(CONFIG_DOWNLOAD_FOLDER)
** Build the toolchain, including source download if not present in WRT $(CONFIG_DOWNLOAD_FOLDER)
** Build the Linux kernel, including source download if not present in WRT $(CONFIG_DOWNLOAD_FOLDER)
** Build the packages, including source download if not present in WRT $(CONFIG_DOWNLOAD_FOLDER)

The 'make' command assumes most things are as they should be and just does:

* Uses rsync to refresh `openwrt/files/` from $(CUSTOM_FILES)/
* Run OpenWRT `make world`

##WRT Updates (Security)

_not yet implemented_

It is recommended initially to track Barrier Breaker (*stable, at time of preparation) before experimenting 
with trunk.

It is strongly recommended if using Barrier Breaker to keep the `openwrt/` build root updated.

To force update (recommended), which will do a `git pull` after cleaning many things:

    wrt-project upstream pull

To update without necessarily building everything:

    wrt-project upstream rebase

Technically this also does a pull, but will attempt to reapply all your project patches and wont clean stuff.
(See Patches.)

##Customisation

When setting up a project, it would be useful to have a local OpenWRT git repository handy already.
This similarly applies to using a downloads cache directory.  Some notes about using git-annex with a download
cache directory are described later.

These can be set by modifying `custom.project` before running 'build' the first time. The 'create' template
feature can be useful here for a build workstation.

By default, the OpenWRT package feeds will be restricted to the core set of packages.
You can enable a feeds.conf file by simply setting `CUSTOM_FEEDS`  in `custom.project` and ensuring it exists
in the project directory. Additional packages can be installed from feeds via `CUSTOM_PACKAGES`.

Like making a local clone of OpenWRT it can also be useful to locally clone the various packages repositories
and use file:// URI in the feeds.conf file. 

###Custom image files

The directory `files/` if present is copied to `openwrt/files` and merged into the firmware image as per normal
OpenWRT processing.  The directory can be changed to another relative directory using `CUSTOM_FILES`

###Interaction with git in the OpenWRT buildroot

If you ran `git status` in `openwrt` you may well see a lot of diffs. By design these are meant to be discarded
unless you are actually developing on OpenWRT itself. (See Patches.)

###Patches

_not yet implemented_

Patches are a little tricky, because some might need to be applied at different stages. Also this needs to be
synchronised with updates to the OpenWRT source (rebasing, anyone?)

Project patches are saved in the `patches/openwrt` directory by default and we should use `quilt` to manage
them.

Patches that MUST be applied to the buildroot on a fresh clone are saved in `patches/preliminary`
It will be most likely to want to apply patches _after_ the feeds are updated and packages installed, these are
saved in `patches/routine`.

The 'refresh' command will refresh the routine patch set using quilt.

    wrt-project patch-refresh

The 'wizard' command will attempt to detect uncaptured differences and create a new proposed patch in 
`patches/routine`, in conjuction with 'wizard-prepare'

    wrt-project patch-wizard-prepare local-branch-name
    # make changes to OpenWRT code base
    wrt-project patch-wizard-collect

This works as follows.

    wrt-project patch-wizard-prepare local-branch-name

* Assume that `openwrt` is a local working copy (which it should be)
* Create a new branch local-branch-name
* Commit _everything_ unchanged at that point.
** How this works may need some further thought, because some things might need to be cleaned first

    wrt-project patch-wizard-collect

* Generate a patch from the git difference

The usual time to do 'patch-wizard-prepare' would be after a build before you start hacking.

<FUTURE ENHANCEMENT:>Integrate / automate quilt

###Manual configuration

_not yet implemented_

    wrt-project config

This will run `make menuconfig` and attempt to collect just changes back as appended to $(CUSTOM_CONFIG)
(This is a work in progress, because unlike 'buildroot', the OpenWRT project has no `make savedefconfig`)

###Kernel configuration

_not yet implemented_

Until used, the OpenWRT supplied kernel config is used by the build.

    wrt-project config-kernel

The kernel configuration is actually a primary file in OpenWRT. The 'config-kernel' command will first check
that no kernel config files have been modified in the `openwrt/` git and will halt if so.

It will then run `make kernel_menuconfig` and then save the new kernel .config back to the project as
$(CUSTOM_KERNEL_CONFIG), and the patch application code will ensure that the kernel configuration is applied.

    wrt-project config-kernel-diff

Will report diffs.

We do it this way because you may need an entire kernel .config for some reason.
Also, remember the interaction in OpenWRT between devices and kmod packages when tuning the kernel.

###uClibC configuration (advanced)

_not yet implemented_

This will build the system to the point that uClibc is unpacked, then run the uClibc Kconfig and capture the
patches back to `patches/uClibc`

###Vendor kernel

It can be useful to want to use a GPL source kernel with a OpenWRT user space, especially for a device not yet
ported.

_not yet implemented_

FIXME Instructions for modifying the configuration to do this

##Clean

This operation will cause a 'build' to 'do' everything again (except Internet downloads)

    wrt-project clean

This removes the following:

* all .stamp files
* .config.cache
* openwrt/feeds.conf
* openwrt/.config{.old}
* openwrt/files

It also runs:

* WRT scripts/feeds clean

To really clean everything:

    wrt-project distclean

which additionally runs:

* In the openwrt/ directory: `git clean -x -f -d`

##Internals

###The wrt-project tool

This command operates on the current working directory where it is invoked; it assumes that $PWD a WBM project
working copy.

###Enhanced .config file maintenance

OpenWRT features the ability to take a short .config (seed) and generate a full OpenWRT .config file.
This is less useful in that it is not easy to generate changes to the seed file when using `make menuconfig`
(etc) for subsequent changes.  The OpenWRT `scripts/env` tool if used the right way can add some limited
git version control but it is tedious. 

The config file used to seed defconfig is specified in custom.project 

    wrt-project build

The 'build' command will do the following when invoked:

_not yet implemented_

* compare openwrt/.config with .config.cache
** if present, and different (either you have manually edited or manually run `make menuconfig`) will halt
** you can then examine and resolve the situation
* copy $(CUSTOM_CONFIG) over openwrt/.config
* run `make defconfig`
* copy resulting openwrt/.config to .config.cache
* proceed with build - by default `make -j4 world`

    wrt-project make

The 'make' command by contrast will not touch openwrt/.config and will simply:

* proceed with build - by default `make -j4 world`

If the seed file is incomplete or ambiguous then OpenWRT will automatically invoke `make menuconfig`.
If you do not address the missing elements this will happen every time you run 'build'!

One main reason for an incomplete seed config is choosing an item which has a dependency on a 'higher level'
item.  For example, if you try and set `CONFIG_BUILD_LOG` without also setting `CONFIG_DEVEL=y`.

To assist in resolving manual edits, which cause 'build' to halt early:

_not yet implemented_

    wrt-project config-mergetool

This will:

* Create a diff between .config.cache and openwrt/.config
* If $(CUSTOM_CONFIG) is unchanged in git, will append the difference to $(CUSTOM_CONFIG) and you thus get
  a chance to edit
* If $(CUSTOM_CONFIG) is changed in git, will `git add` $(CUSTOM_CONFIG) first
* If $(CUSTOM_CONFIG) is changed and modified in git, will stop and advise of the situation
* If the project is not a git working copy, $(CUSTOM_CONFIG) simply has the differences appended.

Doing this will mitigate chances for loss of human-edited changes.

<FUTURE ENHANCEMENT:>To assist in automating resolution of incomplete seed configs, the tool can scan the
OpenWRT Kconfig mechanism and append best guess at missing dependencies to $(CUSTOM_CONFIG), with change
rules as above

###The custom.project file

    CUSTOM_OPENWRT_GIT         # <-- Git repository to clone OpenWRT
		CUSTOM_OPENWRT_GIT_BRANCH  # <-- Initially checked out branch in git repository (default: master)
    CUSTOM_CONFIG              # <-- seed filename for OpenWRT `make defconfig` as described above
    CUSTOM_FEEDS               # <-- feeds.conf file to use
		CUSTOM_PACKAGES            # <-- file to use to generate arguments for `scripts/feeds install`
    CUSTOM_FILES               # <-- files/ directory
		CUSTOM_MAKE_CONCURRENCY    # <-- default value for -j

##Notes

###Using git

_todo_

###Using git-annex and a download cache directory

_todo_

###Managing patch sets against different openwrt versions

_todo_

###Colocated package feed

_todo_


