#
# Utilities for Make
#

# Definition of text formatting
RESET  := $(shell tput -Txterm sgr0)
DIM    := $(shell tput -Txterm dim)
BOLD   := $(shell tput bold)
NORMAL := $(shell tput sgr0)

# Definition of colors
RED    := $(shell tput -Txterm setaf 1)
GREEN  := $(shell tput -Txterm setaf 2)
YELLOW := $(shell tput -Txterm setaf 3)
BLUE   := $(shell tput -Txterm setaf 4)
WHITE  := $(shell tput -Txterm setaf 7)

# Checks whether a tool is installed on a machine
define check_dependency
	if which "$(1)" > /dev/null; then                                     \
		RESULT="$(GREEN)PASS$(RESET)";                                    \
		EXIT=0;                                                           \
	else                                                                  \
		RESULT="$(RED)$(BOLD)FAIL$(RESET)";                               \
		EXIT=1;                                                           \
	fi;                                                                   \
                                                                          \
	printf '%6s: %-40s: %s\n' CHECK 'Is tool "$(1)" installed?' $$RESULT; \
	exit $$EXIT
endef
