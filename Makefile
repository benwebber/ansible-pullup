.PHONY: check \
        install \
        uninstall

PROJECT = ansible-pullup

prefix      = /usr/local
exec_prefix = $(prefix)
bindir      = $(exec_prefix)/bin

install:
	install -m 755 $(PROJECT) $(DESTDIR)$(bindir)

check:
	rubocop -D

uninstall:
	$(RM) $(DESTDIR)$(bindir)/$(PROJECT)
