#include ../../Makefile
#include ../../config.git/makefile.app
SHELL = /bin/bash -x
GIT_USER := steve
GIT_SERVER_IP := 192.168.1.90
GIT_PATH := /tmp
PROJECT_SAVE_PATH := /tmp
PKGNAME = $(firstword $(subst ., ,$(lastword $(subst /, ,$(CURDIR)))))
PKGVERSION := $(word 1, $(shell rpm -q --queryformat "%{VERSION}-%{RELEASE}\n" --specfile SPECS/$(PKGNAME).spec))
RESULTDIR := $(HOME)/mock

.PHONY : help list query init clone push fetch pull rebase build_i386 build_x86_64 build_arm build_armhfp

help:
	@echo -e help"\t\t"使用說明
	@echo -e list"\t\t"列出所有的專案
	@echo -e query"\t\t"查詢專案。
	@echo -e clone"\t\t"將 repository 內的檔案複製下來
	@echo -e push"\t\t"將修改完成的檔案上傳至 repository
	@echo -e fetch"\t\t"更新到最新版本
	@echo -e pull"\t\t"先執行 fetch 然後再執行 merge
	@echo -e rebase"\t\t"重新定義參考基準
	@echo -e build_x86"\t"建立 x86 平台的RPM 和 SRPM
	@echo -e build_x86_64"\t"建立 x86_64 平台的RPM 和 SRPM
	@echo -e build_arm"\t"建立 arm 平台的RPM 和 SRPM
	@echo -e build_armhfp"\t"建立 armhfp 平台的RPM 和 SRPM

list:
	@ssh $(GIT_USER)@$(GIT_SERVER_IP) "ls -R $(GIT_PATH)/*_project | grep git: | awk -F"/" '{ print \$$NF }' | cut -d "." -f 1"

query:
	@read -p "input project name: " project && \
	ssh $(GIT_USER)@$(GIT_SERVER_IP) "ls -R $(GIT_PATH)/*_project | grep git: | grep git: | awk -F"/" '{ print \$$NF }' | \
cut -d "." -f 1 | grep $$project | sort"

init:
	@ssh $(GIT_USER)@$(GIT_SERVER_IP) "mkdir $(GIT_PATH)/$(PKGNAME).git && cd $(GIT_PATH)/$(PKGNAME).git && \
git init --bare --shared" && \
        git init && \
        git add . && \
        git commit && \
        git remote add origin $(GIT_USER)@$(GIT_SERVER_IP):$(GIT_PATH)/$(PKGNAME).git && \
        git push origin master || exit && \
        git push origin master:refs/heads/develop

clone:
	@read -p "input project name: " project && \
        git clone $(GIT_USER)@$(GIT_SERVER_IP):$(GIT_PATH)/$$project.git $(PROJECT_SAVE_PATH)/$$project.git && \
	cd $(PROJECT_SAVE_PATH)/$$project.git && \
        git checkout -b develop origin/develop

push:
	@branchname=`git branch | grep "^* develop"`; \
        if [ -z "$$branchname" ]; then \
          echo "You are not in develop branch，please execute git checkout develop"; \
          exit 1; \
        fi
	git add .
	git commit
	git push origin

fetch:
	@git fetch
pull:
	@git pull

rebase:
	@branchname=`git branch | grep "^* develop"`; \
        if [ -z "$$branchname" ]; then \
          echo "You are not in develop branch，please execute git checkout develop"; \
          exit 2; \
        fi ;\
        ver_change=`git diff HEAD^ HEAD SPECS/$(PKGNAME).spec`; \
        if [ -z "$$ver_change" ]; then \
          echo $(PKGNAME).spec dose not change; \
          exit 3; \
        fi; \
        git tag -a $(PKGVERSION) && \
        git push origin --tags && \
        git checkout master && \
        git rebase develop && \
        git push

build_x86:
	@mock -r fedora-17-i386 --clean
	@mock --no-cleanup-after -r fedora-17-i386 --buildsrpm --spec SPECS/$(PKGNAME).spec --sources SOURCES --resultdir=$(RESULTDIR)
	@mock --no-clean --resultdir=$(RESULTDIR) -r fedora-17-i386 $(RESULTDIR)/$(PKGNAME)-$(PKGVERSION).src.rpm 

build_x86_64:
	@mock -r fedora-17-x86_64 --clean
	@mock --no-cleanup-after -r fedora-17-x86_64 --buildsrpm --spec SPECS/$(PKGNAME).spec --sources SOURCES --resultdir=$(RESULTDIR)
	@mock --no-clean --resultdir=$(RESULTDIR) -r fedora-17-x86_64 $(RESULTDIR)/$(PKGNAME)-$(PKGVERSION).src.rpm 

build_arm:
	@mock -r fedora-17-arm --clean
	@mock --no-cleanup-after -r fedora-17-arm --buildsrpm --spec SPECS/$(PKGNAME).spec --sources SOURCES --resultdir=$(RESULTDIR)
	@mock --no-clean --resultdir=$(RESULTDIR) -r fedora-17-arm $(RESULTDIR)/$(PKGNAME)-$(PKGVERSION).src.rpm 

build_armhfp:
	@mock -r fedora-17-armhfp --clean
	@mock ---no-cleanup-after r fedora-17-armhfp --buildsrpm --spec SPECS/$(PKGNAME).spec --sources SOURCES --resultdir=$(RESULTDIR)
	@mock --no-clean --resultdir=$(RESULTDIR) -r fedora-17-armhfp $(RESULTDIR)/$(PKGNAME)-$(PKGVERSION).src.rpm 
