USERBIN := ${HOME}/.local/bin
TARGET := $(USERBIN)/updb
SOURCE := updb.sh

install:
	mkdir -p $(USERBIN)
	cp $(SOURCE) $(TARGET)
	chmod +x $(TARGET)

.PHONY: install
