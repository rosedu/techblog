---
date: 2011-09-25
title: Python environment
author: Alex Morega
tags: python, virtualenv, pip
---

This article is a quick guide to setting up a Python work environment.  It
walks you through installing Python with some basic package management tools
(`distribute`, `pip`, `virtualenv`), setting up projects, and installing
packages.

### Bootstrapping

First of all we need to have a working Python interpreter. You want to
install the latest release of `2.7` for now (September 2011). Python 3
is gathering momentum but many libraries don't support it yet.

* In most Linux distributions, and in Mac OS, some Python is
  already installed. You may, of course, install a different one from
  scratch. For Mac OS, the [homebrew][] version is highly recommended.
* On Windows you can install a pre-compiled release from
  <http://python.org/download/>.
* To install from source, you need a C compiler, and a tarball from
  <http://python.org/download/>. The usual `./configure; make; make
  install` should work just fine. Consider installing into a separate
  folder, e.g. `./configure --prefix=/usr/local/Python-2.7`, so you can
  easily remove it at some point in the future.

Now, the typical mistake is to declare victory, and use this Python
installation for everything. In time, you want to use various libraries,
so you install them on top of Python. Eventually you get a version
conflict (some project requires a library which is too new for another
project). Fortunately there is a better way: `virtualenv`.

The command-line examples use `$MYPYTHON` as placeholder for the Python
installation path. This can be `/usr` for a Linux distribution install,
`/usr/local` for default manual installation,
`/usr/local/Cellar/python/2.7.2` for mac Homebrew, or even `C:\Python27`
on Windows.

If you're on Linux, and use a Python package from the distribution, it's
a good bet they have `virtualenv` too. For Debian, Ubuntu and Fedora, the
name is `python-virtualenv`. This may be outdated, so if you experience
problems, check the version and consider installing the latest one (see
below).

In a fresh Python installation, to get `virtualenv`, we need to install
`distribute` and `pip` first. `distribute` is an older package manager,
and `pip` is newer and more powerful, but it depends on the older one to
do heavy lifting. So, download
[`distribute_setup.py`][distribute-setup], and, assuming you installed
Python in a folder called `$MYPYTHON`, do the following:

    $ $MYPYTHON/bin/python distribute_setup.py
    $ $MYPYTHON/bin/easy_install pip
    $ $MYPYTHON/bin/pip install virtualenv

If everything worked out fine, you should have a script called
`virtualenv` in `$MYPYTHON/bin`, and you can safely remove
`distribute_setup.py` and `distribute-x.y.z.tar.gz`.

That's all you normally install in the global Python folder. Maybe throw
in some commonly-used, slow-to-change, takes-a-while-to-compile package
like [PIL][] or [SciPy][], or the odd manually-installed kits on
Windows, but everything else goes into a virtualenv.

[homebrew]: http://brew.sh/
[distribute-setup]: http://python-distribute.org/distribute_setup.py
[pil]: http://www.pythonware.com/products/pil/
[scipy]: http://www.scipy.org/


### Virtual insanity

Say you want to work on [WoUSO][], and the documentation tells you that
you need to install [Django][]. The very first thing you do is create a
virtualenv. We'll use `$MYENV` as placeholder for the path to a new
folder where you want to work:

    $ $MYPYTHON/bin/virtualenv $MYENV

`virtualenv` will create the folder, write some files, then run off and
get `distribute` and `pip`; it should all take a few seconds. When it's
done, you have `$MYENV/bin/python`, which is a fully functional Python
interpreter. Next to it, there is `$MYENV/bin/pip`, which you can now
use to install things:

    $ $MYENV/bin/pip install Django

This will go to [PyPI][], look for a package named `Django`, and install
the latest version. The installation happens inside `$MYENV`, in the
`lib/python2.7/site-packages` subfolder. This Django doesn't affect the
original Python installation or any other virtualenvs you create. Of
course, multiple virtualenvs can have different versions of Django.


### Bits and pieces

Now, if you start happily creating many virtualenvs, installing a lot of
packages, you'll be downloading the same files over and over again.
Fortunately, pip can be configured to cache the downloads:

    $ cat ~/.pip/pip.conf
    [global]
    download_cache = ~/.pip/cache

Depending on the setup, sometimes you have to deal with
globally-installed packages, for example if you're using the Python from
a Linux distribution. It's still possible to create a virtualenv that
ignores those packages by passing the `--no-site-packages` option to
virtualenv. This simply leaves out the global `site-packages` folder
from Python's import path.

Some projects include a `requirements.txt` file in their source tree,
which lists dependencies. You install these with `pip install -r
requirements.txt`. Writing your own `requirements.txt` is easy: each
line is a set of arguments for one invocation of pip. Or simply run `pip
freeze`, it generates a list of all the installed packages and their
versions.

When you get tired of typing `$MYENV/bin/something` all the time, you
may want to `activate` the virtualenv. This is a fancy name which simply
means that `$MYENV/bin` is prepended to your current `$PATH` (and your
`$PS1` is enhanced):

    $ . $MYENV/bin/activate
    (myenv)$ # "python" invokes "$MYENV/bin/python"
    (myenv)$ deactivate
    $ # back to the original shell environment

If you find yourself working on a package, the kind that has `setup.py`
and installs with pip, you want to install the package in "edit" mode.
Check out the source tree, then (assuming you're in the same folder with
`setup.py`) run `pip install -e .`. This will install the package
in-place. Technically, a link is made in `site-packages` that extends
Python's import path to find your package, any dependencies in
`setup.py` are installed, and scripts are installed in `$MYENV/bin`, if
the package has any.

[wouso]: https://projects.rosedu.org/projects/wousodjango
[django]: https://www.djangoproject.com/
[pypi]: http://pypi.python.org/


### Further reading

These wonderful tools are available on [PyPI][], the Python Package
Index. Most of them have good documentation that explains more features
that did not fit in this article. Also, remember `docs.python.org`
(behold the [table of contents][]), where you can find documentation on
the language, a nice tutorial, and excellent documentation for the
standard library.

[table of contents]: http://docs.python.org/contents.html
