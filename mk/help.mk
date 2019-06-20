TARGET_MAX_CHAR_NUM := 25
MAX_VAR_VALUE_CHAR_NUM := 20
define HELP_AWK = 
# catch target definitions (targets starting with underscore are ignored)
/^[a-zA-Z\-0-9\%/][a-zA-Z\-\_0-9\%/\.]*:/ {
	helpMessage = get_help_message();
	if (helpMessage) {
		helpCommand = substr($$1, 0, index($$1, ":")-1);
        prefix = "$(YELLOW)";
		if (match(helpCommand, /[\%]/)) {
			prefix = prefix"$(DIM)";
		}
		printf "    %s%-$(TARGET_MAX_CHAR_NUM)s$(RESET) $(GREEN)%s$(RESET)\n", prefix, helpCommand, helpMessage;
	}
}
# extract the help message from the last line
function get_help_message() {
	helpMessage = match(lastLine, /^[#]+[[:blank:]]*(.*)/, groups);
	if (helpMessage) {
		helpMessage = groups[1];
	} else {
		helpMessage = "<not documented>";
	}
	return helpMessage;
}

# catch optional environment variable definitions
/^[[:blank:]]*(export[[:blank:]]+)?[a-zA-Z\-0-9][a-zA-Z\-0-9\_]*[[:blank:]]+\?=/ {
	delimiter = match($$0, /[[:blank:]]*(.*)[[:blank:]]+\?=[[:blank:]]*(.*)/, groups);
	variable = groups[1];
    if (!(variable in env_var_defaults)) {
        if (groups[2]) {
            doc = groups[2];
            # limit displayed default value length
            if (length(doc) > $(MAX_VAR_VALUE_CHAR_NUM)) {
                doc = substr(doc, 0, $(MAX_VAR_VALUE_CHAR_NUM) - 3)"...";
            }
            env_var_defaults[variable] = doc;
        } else {
            env_var_defaults[variable] = "<none>";
        }
        env_var_documentation[variable] = get_help_message();
    }
}

# print out the collected environment variables
function print_env_vars() {
	if (length(env_var_defaults)>0) {
		print "\n  environment variables:";
		for (variable in env_var_defaults) {
            printf "    $(BLUE)%-$(TARGET_MAX_CHAR_NUM)s$(RESET) ($(DIM)%-$(MAX_VAR_VALUE_CHAR_NUM)s$(RESET)) $(GREEN)%s$(RESET)\n", variable, env_var_defaults[variable], env_var_documentation[variable];
		}
        # clear environment variable collections
		split("", env_var_defaults);
		split("", env_var_documentation);
	}
}
BEGIN { 
    split("", env_var_defaults); 
    split("", env_var_documentation);
}
FNR==1 { print_env_vars() }
END { print_env_vars() }

# open a new file section
FNR==1 {
	printf "\n $(WHITE)%s$(RESET):\n", FILENAME;
	header=1;
}
/^#/ {
	if (header) {
        match($$0, /^[#]+[[:blank:]]*(.*)/, groups);
		documentation = groups[1]
		if (documentation) {
			printf "  "documentation"\n";
		}
	}
}
/^[^#]/ { header=0; }
/^$$/ { header=0; }	
# update the last line variable
{ lastLine = $$0 }
endef

.PHONY: help
# print a list of goals
help:
	@echo ''
	@echo 'Usage:'
	@echo '  ${YELLOW}make${RESET} ${GREEN}<target>${RESET}'
	@echo ''
	@echo 'Targets:'
	@awk '$(HELP_AWK)' $(MAKEFILE_LIST)
