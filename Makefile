#==============================================================================#
#                                  MAKE CONFIG                                 #
#==============================================================================#

MAKE	= make -C
BEAR_CMD := $(shell command -v bear >/dev/null 2>&1 && echo "bear --" || echo "")
SHELL	:= bash --rcfile ~/.bashrc

# Default test values
MODE			?= 
DEBUG			?= 0
IN_PATH		?= $(SRC_PATH)
ARG				=

#==============================================================================#
#                                     NAMES                                    #
#==============================================================================#

NAME				= zosc_logger.out

### Message Vars
_NAME	 		= [$(MAG)$(NAME)$(D)]
_SUCCESS 		= [$(GRN)SUCCESS$(D)]
_INFO 			= [$(BLU)INFO$(D)]
_SEP	 			= ===================================================

#==============================================================================#
#                                    PATHS                                     #
#==============================================================================#

SRC_PATH		= src
INC_PATH		= inc
LIBS_PATH		= lib
BUILD_PATH	= .build
TEMP_PATH		= .temp
TEST_PATH		=

FILES			= main.cpp

TEST_FILES	= 

SRC				= $(addprefix $(SRC_PATH)/, $(FILES))
OBJS			= $(SRC:$(SRC_PATH)/%.cpp=$(BUILD_PATH)/%.o)

TEST_SRC		= $(addprefix ./, $(TEST_FILES))
TEST_OBJS		= $(TEST_SRC:$(TEST_PATH)/%.cpp=$(BUILD_PATH)/%.o)

ZOSC_PATH		= $(LIBS_PATH)/zosclib
ZOSC_ARC		= $(ZOSC_PATH)/zosclib.a

#==============================================================================#
#                              COMPILER & FLAGS                                #
#==============================================================================#

CXX					= g++
CXXFLAGS	  = -Wall -Wextra -Werror
CXXFLAGS	  += -Wshadow

DEBUG_FLAGS	= -g -O0 -D DEBUG

ASAN_FLAGS	= -fsanitize=address,undefined

INC					= -I $(INC_PATH)

#==============================================================================#
#                                COMMANDS                                      #
#==============================================================================#

### Core Utils
RM			= rm -rf
AR			= ar rcs
MKDIR_P	= mkdir -p

### Valgrind
# VAL_SUP 	= --suppressions=
VAL_LEAK	= --leak-check=full --show-leak-kinds=all --trace-children=yes
VAL_FD		= --track-fds=yes --track-origins=yes
VGDB_ARGS	= --vgdb-error=0 $(VAL_LEAK) $(VAL_SUP) $(VAL_FD)

#==============================================================================#
#                                  RULES                                       #
#==============================================================================#

##@ Compilation Rules 🏗

all: deps $(NAME)	## Compile

$(NAME): $(BUILD_PATH) $(OBJS) $(ZOSC_ARC)	# Compile
	@echo "$(YEL)Archiving $(MAG)$(NAME)$(YEL)$(D)"
	$(BEAR_CMD) $(CXX) $(CXXFLAGS) $(OBJS) $(INC) $(ZOSC_ARC) -o $(NAME)
	@echo "* $(_NAME) archived: $(_SUCCESS) $(YEL)🖔$(D)"

exec: all 		## Run
	@echo "$(YEL)Running $(MAG)$(EXEC)$(YEL)$(D)"
	./$(NAME) $(ARG)

rexec: re 		## Re & Run
	@echo "$(YEL)Running $(MAG)$(EXEC)$(YEL)$(D)"
	./$(NAME) $(ARG)

export CXXFLAGS
debug: CXXFLAGS += $(DEBUG_FLAGS)
debug: fclean $(TEMP_PATH) all 		## Compile w/ debug symbols

asan: CXXFLAGS += $(ASAN_FLAGS) 
asan: $(BUILD_PATH) $(ZOSC_ARC) $(OBJS)   ## Compile with Sanitizers
	@echo "$(YEL)Compiling $(MAG)$(NAME)$(YEL) with Address Sanitizer$(D)"
	$(CXX) $(CXXFLAGS) $(OBJS) $(INC) $(ZOSC_ARC) -o $(NAME)
	@echo "[$(_SUCCESS) compiling $(MAG)$(NAME)$(D) with Sanitizers $(YEL)🖔$(D)]"

deps:		## Download/Update deps
	@if test ! -d "$(ZOSC_PATH)"; then make get_zosclib; \
		else echo "$(YEL)zosclib$(D) folder found 🖔"; fi
	@echo " $(RED)$(D) [$(GRN)Nothing to be done!$(D)]"

get_zosclib:
	@echo "* $(CYA)Getting $(YEL)zosclib$(CYA) submodule$(D)]"
	@if test ! -d "$(ZOSC_PATH)"; then \
		git clone git@github.com:PedroZappa/zosclib.git $(ZOSC_PATH); \
		echo "* $(GRN)zosclib submodule download$(D): $(_SUCCESS)"; \
	else \
		echo "* $(GRN)zosclib submodule already exists 🖔"; \
	echo " $(RED)$(D) [$(GRN)Nothing to be done!$(D)]"; \
	fi

-include $(BUILD_PATH)/%.d

$(BUILD_PATH)/%.o: $(SRC_PATH)/%.cpp
	@echo -n "$(MAG)█$(D)"
	$(CXX) $(CXXFLAGS) -MMD -MP -c $< -o $@

$(BUILD_PATH):
	$(MKDIR_P) $(BUILD_PATH)
	@echo "* $(YEL)Creating $(CYA)$(BUILD_PATH)$(YEL) folder:$(D) $(_SUCCESS)"

$(TEMP_PATH):
	$(MKDIR_P) $(TEMP_PATH)
	@echo "* $(YEL)Creating $(CYA)$(TEMP_PATH)$(YEL) folder:$(D) $(_SUCCESS)"

$(ZOSC_ARC):
	$(MAKE) $(ZOSC_PATH) debug

##@ Test Rules 🧪

test_all:						## Run All tests
	echo "Test!"


##@ Debug Rules 

gdb: debug $(NAME) $(TEMP_PATH)			## Debug w/ gdb
	tmux split-window -h "gdb --tui --args ./$(NAME)"
	tmux resize-pane -L 5
	# tmux split-window -v "btop"
	make get_log

vgdb: debug $(NAME) $(TEMP_PATH)			## Debug w/ valgrind (memcheck) & gdb
	tmux split-window -h "valgrind $(VGDB_ARGS) --log-file=gdb.txt ./$(NAME) $(ARG)"
	make vgdb_cmd
	tmux split-window -v "gdb --tui -x $(TEMP_PATH)/gdb_commands.txt $(NAME)"
	tmux resize-pane -U 18
	# tmux split-window -v "btop"
	make get_log

valgrind: debug $(NAME) $(TEMP_PATH)			## Debug w/ valgrind (memcheck)
	tmux set-option remain-on-exit on
	tmux split-window -h "valgrind $(VAL_LEAK) $(VAL_FD) ./$(NAME) $(ARG)"

massif: all $(TEMP_PATH)		## Run Valgrind w/ Massif (gather profiling information)
	@TIMESTAMP=$(shell date +%Y%m%d%H%M%S); \
	if [ -f massif.out.* ]; then \
		mv -f massif.out.* $(TEMP_PATH)/massif.out.$$TIMESTAMP; \
	fi
	@echo " 🔎 [$(YEL)Massif Profiling$(D)]"
	valgrind --tool=massif --time-unit=B ./$(NAME) $(ARG)
	ms_print massif.out.*
# Learn more about massif and ms_print:
### https://valgrind.org/docs/manual/ms-manual.html

get_log:
	touch gdb.txt
	@if command -v lnav; then \
		lnav gdb.txt; \
	else \
		tail -f gdb.txt; \
	fi

vgdb_cmd: $(NAME) $(TEMP_PATH)
	@printf "target remote | vgdb --pid=" > $(TEMP_PATH)/gdb_commands.txt
	@printf "$(shell pgrep -f valgrind)" >> $(TEMP_PATH)/gdb_commands.txt
	@printf "\n" >> $(TEMP_PATH)/gdb_commands.txt
	@cat .vgdbinit >> $(TEMP_PATH)/gdb_commands.txt

##@ Clean-up Rules 󰃢

clean: 				## Remove object files
	@echo "*** $(YEL)Removing $(MAG)$(NAME)$(D) and deps $(YEL)object files$(D)"
	@if [ -d "$(BUILD_PATH)" ] || [ -d "$(TEMP_PATH)" ]; then \
		if [ -d "$(BUILD_PATH)" ]; then \
			$(RM) $(BUILD_PATH); \
			echo "* $(YEL)Removing $(CYA)$(BUILD_PATH)$(D) folder & files$(D): $(_SUCCESS)"; \
		fi; \
		if [ -d "$(TEMP_PATH)" ]; then \
			$(RM) $(TEMP_PATH); \
			echo "* $(YEL)Removing $(CYA)$(TEMP_PATH)$(D) folder & files:$(D) $(_SUCCESS)"; \
		fi; \
	else \
		echo " $(RED)$(D) [$(GRN)Nothing to clean!$(D)]"; \
	fi

fclean: clean			## Remove executable and .gdbinit
	$(RM) compile_commands.json
	@if [ -f "$(NAME)" ]; then \
		$(RM) $(NAME); \
		echo "* $(YEL)Removing $(CYA)$(NAME)$(D) file: $(_SUCCESS)"; \
	fi
	@if [ -f "$(EXEC)" ]; then \
		$(RM) $(EXEC); \
		echo "* $(YEL)Removing $(CYA)$(EXEC)$(D) file: $(_SUCCESS)"; \
	fi
	@if [ ! -f "$(NAME)" ] && [ ! -f "$(EXEC)" ]; then \
		echo " $(RED)$(D) [$(GRN)Nothing to be fcleaned!$(D)]"; \
	fi
	@if [ -f "$(NAME)" ]; then \
		$(RM) $(NAME); \
		echo "* $(YEL)Removing $(CYA)$(NAME)$(D) file: $(_SUCCESS)"; \
	fi

libclean: fclean	## Remove libs
	$(RM) $(LIBS_PATH)
	$(RM) compile_commands.json
	@echo "* $(YEL)Removing lib folder & files!$(D) : $(_SUCCESS)"

re: fclean all	## Purge & Recompile

##@ Help 󰛵

help: 			## Display this help page
	@awk 'BEGIN {FS = ":.*##"; \
			printf "\n=> Usage:\n\tmake $(GRN)<target>$(D)\n"} \
		/^[a-zA-Z_0-9-]+:.*?##/ { \
			printf "\t$(GRN)%-18s$(D) %s\n", $$1, $$2 } \
		/^##@/ { \
			printf "\n=> %s\n", substr($$0, 5) } ' Makefile
## Tweaked from source:
### https://www.padok.fr/en/blog/beautiful-makefile-awk

.PHONY: bonus clean fclean re help

#==============================================================================#
#                                  UTILS                                       #
#==============================================================================#

# Colors
#
# Run the following command to get list of available colors
# bash -c 'for c in {0..255}; do tput setaf $c; tput setaf $c | cat -v; echo =$c; done'
#
B  		= $(shell tput bold)
BLA		= $(shell tput setaf 0)
RED		= $(shell tput setaf 1)
GRN		= $(shell tput setaf 2)
YEL		= $(shell tput setaf 3)
BLU		= $(shell tput setaf 4)
MAG		= $(shell tput setaf 5)
CYA		= $(shell tput setaf 6)
WHI		= $(shell tput setaf 7)
GRE		= $(shell tput setaf 8)
BRED 	= $(shell tput setaf 9)
BGRN	= $(shell tput setaf 10)
BYEL	= $(shell tput setaf 11)
BBLU	= $(shell tput setaf 12)
BMAG	= $(shell tput setaf 13)
BCYA	= $(shell tput setaf 14)
BWHI	= $(shell tput setaf 15)
D 		= $(shell tput sgr0)
BEL 	= $(shell tput bel)
CLR 	= $(shell tput el 1)
