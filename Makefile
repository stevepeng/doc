#include ../../Makefile
#include ../../config.git/makefile.app
SHELL = /bin/bash -x
GIT_USER := steve
GIT_SERVER_IP := 127.0.0.1
GIT_PATH := /var/git
PROJECT_SAVE_PATH := /tmp
DB_PATH := /home/steve
DBNAME := project.db3
PKGNAME = $(firstword $(subst ., ,$(lastword $(subst /, ,$(CURDIR)))))
PKGVERSION := $(word 1, $(shell rpm -q --queryformat "%{VERSION}-%{RELEASE}\n" --specfile SPECS/$(PKGNAME).spec))
RESULTDIR := $(HOME)/mock

.PHONY : help list clone push pull fetch rebase build_i386 build_x86_64 build_arm build_armhfp

help:
	@echo build_i386
	@echo build_x86_64
	@echo build_arm
	@echo build_armhfp

list:
	@sqlite3 -line $(DB_PATH)/$(DBNAME) "select name from project" 

query:
	@read -p "input project name: " project && \
        sqlite3 -line $(DB_PATH)/$(DBNAME) "select name,owner,path,status from project where name like \"$$project\""

clone:
	@read -p "input project name: " project && \
        git clone $(GIT_USER)@$(GIT_SERVER_IP):$(GIT_PATH)/$$project.git $(PROJECT_SAVE_PATH)/$$project.git && \
	cd $(PROJECT_SAVE_PATH)/$$project.git && \
        git checkout -b develop origin/develop

push:
	branchname=`git branch | grep "^* develop"`; \
        if [ -z "$$branchname" ]; then \
          echo "Error!!"; \
          exit 1; \
        fi
	git add .
	git commit
	git push

fetch:
	git fetch
pull:
	git pull

rebase:
	branchname=`git branch | grep "^* develop"`; \
        if [ -z "$$branchname" ]; then \
          git checkout develop; \
        fi
	ver_change=`git diff HEAD^ HEAD SPECS/$(PKGNAME).spec`; \
        if [ -z "$$ver_change" ]; then \
          echo $(PKGNAME).spec dose not change; \
          exit; \
        fi; \
        git tag -a $(PKGVERSION) && \
        git push origin --tags && \
        git checkout master && \
        git rebase develop && \
        git push

build_i386:
	mock -r fedora-17-i386 --clean
	mock --no-cleanup-after -r fedora-17-i386 --buildsrpm --spec SPECS/$(PKGNAME).spec --sources SOURCES --resultdir=$(RESULTDIR)
	mock --no-clean --resultdir=$(RESULTDIR) -r fedora-17-i386 $(RESULTDIR)/$(PKGNAME)-$(PKGVERSION).src.rpm 

build_x86_64:
	mock -r fedora-17-x86_64 --clean
	mock -r fedora-17-x86_64 --buildsrpm --spec SPECS/$(PKGNAME).spec --sources SOURCES --resultdir=$(RESULTDIR)
	mock --no-clean --resultdir=$(RESULTDIR) -r fedora-17-x86_64 $(RESULTDIR)/$(PKGNAME)-$(PKGVERSION).src.rpm 

build_arm:
	mock -r fedora-17-arm --clean
	mock -r fedora-17-arm --buildsrpm --spec SPECS/$(PKGNAME).spec --sources SOURCES --resultdir=$(RESULTDIR)
	mock --no-clean --resultdir=$(RESULTDIR) -r fedora-17-arm $(RESULTDIR)/$(PKGNAME)-$(PKGVERSION).src.rpm 

build_armhfp:
	mock -r fedora-17-armhfp --clean
	mock -r fedora-17-armhfp --buildsrpm --spec SPECS/$(PKGNAME).spec --sources SOURCES --resultdir=$(RESULTDIR)
	mock --no-clean --resultdir=$(RESULTDIR) -r fedora-17-armhfp $(RESULTDIR)/$(PKGNAME)-$(PKGVERSION).src.rpm 

print:
