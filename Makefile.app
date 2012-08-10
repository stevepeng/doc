#include ../../Makefile
#include ../../config.git/makefile.app
pkgname=$(shell basename `pwd`)
specfile=$(shell ls SPECS/*.spec)

.PHONY: rpmbuild
rpmbuild:
	mkdir -p $${HOME}/rpmbuild/$(pkgname);\
	rpmbuild -ba --clean --define '%_specdir /tmp/$(pkgname)' --define '%_sourcedir /tmp/$(pkgname)/SOURCES' --define '%_builddir ${HOME}/rpmbuild/$(pkgname)/BUILD' --define '%_buildrootdir ${HOME}/rpmbuild/$(pkgname)/BUILDROOT' --define '%_rpmdir  ${HOME}/rpmbuild/$(pkgname)/RPMS' --define '%_srcrpmdir ${HOME}/rpmbuild/$(pkgname)/SRPMS' $(specfile)
