########################################################

# Makefile for bitmath
#
# useful targets:
#   make sdist ---------------- produce a tarball
#   make rpm  ----------------- produce RPMs
#   make docs ----------------- rebuild the manpages (results are checked in)
#   make pyflakes, make pep8 -- source code checks
#   make test ----------------- run all unit tests (export LOG=true for /tmp/ logging)

########################################################

# > VARIABLE = value
#
# Normal setting of a variable - values within it are recursively
# expanded when the variable is USED, not when it's declared.
#
# > VARIABLE := value
#
# Setting of a variable with simple expansion of the values inside -
# values within it are expanded at DECLARATION time.

########################################################


NAME := bitmath
PKGNAME := python-$(NAME)

# VERSION file provides one place to update the software version.
VERSION := $(shell cat VERSION)
RPMRELEASE = $(shell awk '/global _short_release/{print $$NF; exit}' $(RPMSPEC).in)

RPMSPECDIR := .
RPMSPEC := $(RPMSPECDIR)/$(PKGNAME).spec

# Documentation. YAY!!!!
docs:
	cd docsite; make html; cd -

viewdocs: docs
	xdg-open docsite/build/html/index.html

# Build the spec file on the fly. Substitute version numbers from the
# canonical VERSION file.
python-bitmath.spec: python-bitmath.spec.in
	sed "s/%VERSION%/$(VERSION)/" $< > $@

# Build the distutils setup file on the fly.
setup.py: setup.py.in VERSION python-bitmath.spec.in
	sed -e "s/%VERSION%/$(VERSION)/" -e "s/%RELEASE%/$(RPMRELEASE)/" $< > $@

tag:
	git tag -s -m $(TAG) $(TAG)

tests: uniquetestnames unittests pep8 pyflakes
	:

unittests:
	@echo "#############################################"
	@echo "# Running Unit Tests"
	@echo "#############################################"
	nosetests -v --with-coverage --cover-html --cover-package=bitmath

clean:
	@find . -type f -regex ".*\.py[co]$$" -delete
	@find . -type f \( -name "*~" -or -name "#*" \) -delete
	@rm -fR build cover dist rpm-build MANIFEST htmlcov .coverage bitmathenv bitmathenv3 docsite/build/html/ docsite/build/doctrees/

pep8:
	@echo "#############################################"
	@echo "# Running PEP8 Compliance Tests"
	@echo "#############################################"
	pep8 --ignore=E501,E121,E124 bitmath/

pyflakes:
	@echo "#############################################"
	@echo "# Running Pyflakes Sanity Tests"
	@echo "# Note: most import errors may be ignored"
	@echo "#############################################"
	-pyflakes bitmath

uniquetestnames:
	@echo "#############################################"
	@echo "# Running Unique TestCase checker"
	@echo "#############################################"
	./tests/test_unique_testcase_names.sh


install: clean
	python ./setup.py install

sdist: setup.py clean
	python setup.py sdist -t MANIFEST.in

rpmcommon: sdist python-bitmath.spec setup.py docs
	@mkdir -p rpm-build
	@cp dist/$(NAME)-$(VERSION)-$(RPMRELEASE).tar.gz rpm-build/$(VERSION)-$(RPMRELEASE).tar.gz

srpm5: rpmcommon
	rpmbuild --define "_topdir %(pwd)/rpm-build" \
	--define 'dist .el5' \
	--define "_builddir %{_topdir}" \
	--define "_rpmdir %{_topdir}" \
	--define "_srcrpmdir %{_topdir}" \
	--define "_specdir $(RPMSPECDIR)" \
	--define "_sourcedir %{_topdir}" \
	--define "_source_filedigest_algorithm 1" \
	--define "_binary_filedigest_algorithm 1" \
	--define "_binary_payload w9.gzdio" \
	--define "_source_payload w9.gzdio" \
	--define "_default_patch_fuzz 2" \
	-bs $(RPMSPEC)
	@echo "#############################################"
	@echo "$(PKGNAME) SRPM is built:"
	@find rpm-build -maxdepth 2 -name '$(PKGNAME)*src.rpm' | awk '{print "    " $$1}'
	@echo "#############################################"

srpm: rpmcommon
	rpmbuild --define "_topdir %(pwd)/rpm-build" \
	--define "_builddir %{_topdir}" \
	--define "_rpmdir %{_topdir}" \
	--define "_srcrpmdir %{_topdir}" \
	--define "_specdir $(RPMSPECDIR)" \
	--define "_sourcedir %{_topdir}" \
	-bs $(RPMSPEC)
	@echo "#############################################"
	@echo "$(PKGNAME) SRPM is built:"
	@find rpm-build -maxdepth 2 -name '$(PKGNAME)*src.rpm' | awk '{print "    " $$1}'
	@echo "#############################################"

rpm: rpmcommon
	rpmbuild --define "_topdir %(pwd)/rpm-build" \
	--define "_builddir %{_topdir}" \
	--define "_rpmdir %{_topdir}" \
	--define "_srcrpmdir %{_topdir}" \
	--define "_specdir $(RPMSPECDIR)" \
	--define "_sourcedir %{_topdir}" \
	-ba $(RPMSPEC)
	@echo "#############################################"
	@echo "$(PKGNAME) RPMs are built:"
	@find rpm-build -maxdepth 2 -name '$(PKGNAME)*.rpm' | awk '{print "    " $$1}'
	@echo "#############################################"

virtualenv:
	@echo "#############################################"
	@echo "# Creating a virtualenv"
	@echo "#############################################"
	virtualenv $(NAME)env
	. $(NAME)env/bin/activate && pip install -r requirements.txt
	. $(NAME)env/bin/activate && pip install pep8 nose mock coverage nose-cover3

ci-unittests:
	@echo "#############################################"
	@echo "# Running Unit Tests in virtualenv"
	@echo "#############################################"
	. $(NAME)env/bin/activate && nosetests -v --with-coverage --cover-html --cover-package=bitmath tests/

ci-list-deps:
	@echo "#############################################"
	@echo "# Listing all pip deps"
	@echo "#############################################"
	. $(NAME)env/bin/activate && pip freeze

ci-pep8:
	@echo "#############################################"
	@echo "# Running PEP8 Compliance Tests in virtualenv"
	@echo "#############################################"
	. $(NAME)env/bin/activate && pep8 --ignore=E501,E121,E124 bitmath/

ci-pyflakes:
	@echo "#################################################"
	@echo "# Running Pyflakes Compliance Tests in virtualenv"
	@echo "#################################################"
	. $(NAME)env/bin/activate && pyflakes bitmath/

ci: clean uniquetestnames virtualenv ci-list-deps ci-pep8 ci-pyflakes ci-unittests
	:

virtualenv3:
	@echo ""
	@echo "#############################################"
	@echo "# Creating a virtualenv"
	@echo "#############################################"
	virtualenv $(NAME)env3 --python=python3.3
	. $(NAME)env3/bin/activate && pip install -r requirements.txt
	. $(NAME)env3/bin/activate && pip install pep8 nose mock coverage nose-cover3

ci-unittests3:
	@echo ""
	@echo "#############################################"
	@echo "# Running Unit Tests in virtualenv"
	@echo "# Using python: $(shell ./bitmathenv3/bin/python3.3 --version)"
	@echo "#############################################"
	. $(NAME)env3/bin/activate && nosetests-3.3 -v --with-coverage --cover-html --cover-package=bitmath tests/

ci-list-deps3:
	@echo ""
	@echo "#############################################"
	@echo "# Listing all pip deps"
	@echo "#############################################"
	. $(NAME)env3/bin/activate && pip freeze

ci-pep83:
	@echo ""
	@echo "#############################################"
	@echo "# Running PEP8 Compliance Tests in virtualenv"
	@echo "#############################################"
	. $(NAME)env3/bin/activate && pep8 --ignore=E501,E121,E124 bitmath/

ci-pyflakes3:
	@echo ""
	@echo "#################################################"
	@echo "# Running Pyflakes Compliance Tests in virtualenv"
	@echo "#################################################"
	. $(NAME)env3/bin/activate && pyflakes bitmath/

ci3: clean uniquetestnames virtualenv3 ci-list-deps3 ci-pep83 ci-pyflakes3 ci-unittests3
	:

ci-all: ci ci3
