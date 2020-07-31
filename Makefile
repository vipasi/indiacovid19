site: wiki
	. ./venv && python3 makesite.py
	if [ -e wiki1.txt ]; then cp wiki1.txt _site/wiki1.txt; fi
	if [ -e wiki2.txt ]; then cp wiki2.txt _site/wiki2.txt; fi
	if [ -e wiki2.txt ]; then cp wiki3.txt _site/wiki3.txt; fi

COLOR_DIFF = sed "s/^-/$$(tput setaf 1)&/; s/^+/$$(tput setaf 2)&/; s/^@/$$(tput setaf 6)&/; s/$$/$$(tput sgr0)/"

mohfw:
	python3 -m py.mohfw

wiki:
	python3 -m py.wiki -1 -2 -3
	$(COLOR_DIFF) wiki1.diff
	$(COLOR_DIFF) wiki2.diff
	$(COLOR_DIFF) wiki3.diff

wiki1:
	python3 -m py.wiki -1
	$(COLOR_DIFF) wiki1.diff
	make copy FILE=wiki1.txt

wiki2:
	python3 -m py.wiki -2
	$(COLOR_DIFF) wiki2.diff
	make copy FILE=wiki2.txt

wiki3:
	python3 -m py.wiki -3
	$(COLOR_DIFF) wiki3.diff
	make copy FILE=wiki3.txt

copy:
	if command -v pbcopy > /dev/null; then \
	    pbcopy < "$(FILE)"; \
	elif command -v xclip > /dev/null; then \
	    xclip < "$(FILE)"; \
	fi

push:
	clear
	git diff usacovid19.json
	@echo
	@echo Press enter to commit
	@read
	clear
	git add usacovid19.json
	date=$$(git diff --cached usacovid19.json | \
	        cut -d '"' -f4 | grep "[0-9]\{4\}" | tail -n 1); \
	git commit -m "Add case numbers from MoHFW for $$date"
	git log -n 1
	git status
	@echo
	@echo Press enter to push repository
	@read
	git push origin master

plot:
	. ./venv && python3 -m py.plot

wideplot:
	. ./venv && python3 -m py.plot -w

scan:
	beeps(){ while true; do printf "\a"; sleep 1; done; }; \
	[ $$(date +"%p") = AM ] && h=0 || h=1; \
	while true; \
	    do make mohfw > /tmp/m; \
	    cat /tmp/m; \
	    grep "$$(date +"%Y-%m-%d") $$h" /tmp/m && beeps; \
	    sleep 10; \
	done

venv:
	python3 -m venv ~/.venv/usacovid19
	echo . ~/.venv/usacovid19/bin/activate > venv
	. ./venv && pip3 install matplotlib==3.2.1

favicon:
	wget https://publicdomainvectors.org/photos/1462438735.png
	mv 1462438735.png logo.png
	convert -resize 256x256 logo.png static/favicon.png
	convert -resize 256x256 logo.png static/favicon.ico
	rm logo.png

TMP_REV = /tmp/rev.txt
CAT_REV = cat $(TMP_REV)
GIT_SRC = https://github.com/usacovid19/usacovid19
GIT_DST = https://github.com/usacovid19/usacovid19.github.io
WEB_URL = https://usacovid19.github.io/
TMP_GIT = /tmp/tmpgit
README  = $(TMP_GIT)/README.md

publish: site
	#
	# Push source code.
	git push origin master
	#
	# Stage website.
	rm -rf $(TMP_GIT)
	cp -R _site $(TMP_GIT)
	git rev-parse --short HEAD > $(TMP_REV) || echo 0000000 > $(TMP_REV)
	echo usacovid19.github.io >> $(README)
	echo ====================== >> $(README)
	echo >> $(README)
	echo Generated from [usacovid19/usacovid19][GIT_SRC] >> $(README)
	echo "([$$($(CAT_REV))][GIT_REV])". >> $(README)
	echo >> $(README)
	echo Visit $(WEB_URL) to view the the website. >> $(README)
	echo >> $(README)
	echo [GIT_SRC]: $(GIT_SRC) >> $(README)
	echo [WEB_URL]: $(WEB_URL) >> $(README)
	echo [GIT_REV]: $(GIT_SRC)/commit/$$($(CAT_REV)) >> $(README)
	#
	# Push website.
	cd $(TMP_GIT) && git init
	cd $(TMP_GIT) && git config user.name "Susam Pal"
	cd $(TMP_GIT) && git config user.email susam@susam.in
	cd $(TMP_GIT) && git add .
	cd $(TMP_GIT) && git commit -m "Generated from $(GIT_SRC) - $$($(CAT_REV))"
	cd $(TMP_GIT) && git remote add origin "$(GIT_DST).git"
	cd $(TMP_GIT) && git log
	cd $(TMP_GIT) && git push -f origin master
