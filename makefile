SHELL=/bin/bash

.PHONY: lint linttest lintall pylint pylinttest pylintall code codetest \
codeall doc doctest docall test testdoc serve serve-local serve-heroku-local \
push-production-heroku serve-production push-staging-heroku serve-staging \
production staging  tags ltags  serve-dev serve-dev-network-accessible \
production-connect-heroku staging-connect-heroku logs logs-staging production \
staging production-push staging-push push-production push-staging \
circleci-validate-config  gunicorn-local serve-local production-push-ci \
stagingpush-ci logs-heroku logs-staging-heroku validations validate \
connect-staging connect-prod connect connect-vim connect-vim-staging \
log log-staging
#heroku-setup heroku-setup-staging heroku-setup-production

# DEVELOPMENT
## Linting
SRC=./
TEST=./test/
### All linting
lint:
	${LINT_SRC}; ${CODE_SRC}; ${DOC_SRC}
	# If you want to run this command directly, use the following:
	# python -m pylint --output-format=colorized --reports=n xform-test_web
	# test; \
	# python -m pycodestyle xform_test_web test; \
	# python -m pydocstyle xform_test_web test
linttest:
	${LINT_TEST}; ${CODE_TEST}; ${DOC_TEST}
lintall: lint linttest
### Pylint only
PYLINT=python -m pylint \
	--output-format=colorized \
	--reports=n
LINT_SRC=${PYLINT} ${SRC}
LINT_TEST=${PYLINT} ${TEST}
pylint:
	${LINT_SRC}
pylinttest:
	${LINT_TEST}
pylintall: pylint pylinttest
### Pycodestyle only
PYCODESTYLE=python -m pycodestyle
CODE_SRC=${PYCODESTYLE} ${SRC}
CODE_TEST=${PYCODESTYLE} ${TEST}
code:
	${CODE_SRC}
codetest:
	${CODE_TEST}
codeall: code codetest
### Pydocstyle only
PYDOCSTYLE=python -m pydocstyle
DOC_SRC=${PYDOCSTYLE} ${SRC}
DOC_TEST=${PYDOCSTYLE} ${TEST}
doc:
	${DOC_SRC}
doctest:
	${DOC_TEST}
docall: doc doctest

## Testing
test:
	python -m unittest discover -v
testdoc:
	python -m test.test --doctests-only

## Validations
circleci-validate-config:
	echo Make sure that Docker is running, or this command will fail.; \
	circleci config validate

# SERVERS & ENVIRONMENTS
GUNICORN=gunicorn app:app
## Local
serve-local-flask:
#	python xform_test_web/xform_test_web.py
	open http://localhost:8080; \
	python app.py
serve-heroku-local:
	heroku local
serve-dev-network-accessible:
	${GUNICORN} \
	--access-logfile logs/access-logfile.log \
	--error-logfile logs/error-logfile.log \
	--capture-output \
	--pythonpath python
gunicorn-local: serve-dev-network-accessible

## Heroku
### Setup
#heroku-setup-staging:
#	heroku buildpacks:add --index 1 heroku/jvm --app xform-test-staging; \
#	heroku buildpacks:add --index 2 heroku/python --app xform-test-staging
#heroku-setup-production:
#	heroku buildpacks:add --index 1 heroku/jvm --app xform-test; \
#	heroku buildpacks:add --index 2 heroku/python --app xform-test
#heroku-setup:
#	make heroku-setup-staging; \
#	make heroku-setup-production

### Pushing & Serving
push-production-heroku:
	git status; \
	printf "\nGit status should have reported 'nothing to commit, working tree\
	 clean'. Otherwise you should cancel this command, make sure changes are\
	  committed, and run it again.\n\n"; \
	git checkout master; \
	git branch -D production; \
	git checkout -b production; \
	git push -u trunk production --force; \
	git checkout master; \
	open https://dashboard.heroku.com/apps/xform-test-api/activity; \
	open https://circleci.com/gh/PMA-2020/workflows/xform-test-api
push-staging-heroku:
	git status; \
	printf "\nGit status should have reported 'nothing to commit, working tree\
	 clean'. Otherwise you should cancel this command, make sure changes are\
	  committed, and run it again.\n\n"; \
	git checkout develop; \
	git branch -D staging; \
	git checkout -b staging; \
	git push -u trunk staging --force; \
	git checkout develop; \
	open https://dashboard.heroku.com/apps/xform-test-api-staging/activity; \
	open https://circleci.com/gh/PMA-2020/workflows/xform-test-api
serve-production:
	${GUNICORN}
serve-staging: serve-production

### SSH
production-connect-heroku:
	heroku run bash --app xform-test
staging-connect-heroku:
	heroku run bash --app xform-test-staging
	production-connect: production-connect-heroku
install-vim-on-server:
	mkdir ~/vim; \
	cd ~/vim; \
	curl 'https://s3.amazonaws.com/bengoa/vim-static.tar.gz' | tar -xz; \
	export VIMRUNTIME="$HOME/vim/runtime"; \
	export PATH="$HOME/vim:$PATH"; \
	cd -

### Logs
logs-heroku:
	heroku logs --app xform-test-api --tail
logs-staging-heroku:
	heroku logs --app xform-test-api-staging --tail

## Aliases and defaults
production-push-heroku: push-production-heroku
staging-push-heroku: push-staging-heroku
production: push-production-heroku
staging: push-staging-heroku
serve: serve-local-flask
production-push-ci: production-push-heroku
staging-push-ci: staging-push-heroku
production-push: production-push-ci
staging-push: staging-push-ci
push-production: production-push
push-staging: staging-push
gunicorn: serve-production
serve-local: serve
serve-dev: serve-local-flask
staging-connect: staging-connect-heroku
connect-staging: staging-connect-heroku
connect-prod: production-connect-heroku
connect: production-connect-heroku
logs: logs-heroku
logs-staging: logs-staging-heroku
validations: circleci-validate-config
validate: validations
log: logs
log-staging: logs-staging
