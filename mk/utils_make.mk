#
# Utilities for Make
#

# Definition of colors
GREEN  := $(shell tput -Txterm setaf 2)
YELLOW := $(shell tput -Txterm setaf 3)
BLUE   := $(shell tput -Txterm setaf 4)
WHITE  := $(shell tput -Txterm setaf 7)

# Definition of text formatting
RESET  := $(shell tput -Txterm sgr0)
DIM    := $(shell tput -Txterm dim)
BOLD   := $(shell tput bold)
NORMAL := $(shell tput sgr0)
