#
# Makefile
#
#
#

###########################

# You need to edit these values.

# DICT_NAME		=	"My Dictionary"
DICT_NAME		=	"Erlang OTP Reference"
DICT_SRC_PATH		=	erldict.xml
CSS_PATH		=	erldict.css
PLIST_PATH		=	info.plist

DICT_BUILD_OPTS		=
# Suppress adding supplementary key.
# DICT_BUILD_OPTS		=	-s 0	# Suppress adding supplementary key.

###########################

# The DICT_BUILD_TOOL_DIR value is used also in "build_dict.sh" script.
# You need to set it when you invoke the script directly.

DICT_BUILD_TOOL_DIR	=	"/Developer/Extras/Dictionary Development Kit"
DICT_BUILD_TOOL_BIN	=	"$(DICT_BUILD_TOOL_DIR)/bin"

###########################

DICT_DEV_KIT_OBJ_DIR	=	./objects
export	DICT_DEV_KIT_OBJ_DIR

DESTINATION_FOLDER	=	~/Library/Dictionaries
RM			=	/bin/rm
RUBY = ruby
OPEN = open
###########################

all: xml dict

dev: xml_d dict install open

dict:
	"$(DICT_BUILD_TOOL_BIN)/build_dict.sh" $(DICT_BUILD_OPTS) $(DICT_NAME) $(DICT_SRC_PATH) $(CSS_PATH) $(PLIST_PATH)

install:
	echo "Installing into $(DESTINATION_FOLDER)".
	mkdir -p $(DESTINATION_FOLDER)
	ditto --noextattr --norsrc $(DICT_DEV_KIT_OBJ_DIR)/$(DICT_NAME).dictionary  $(DESTINATION_FOLDER)/$(DICT_NAME).dictionary
	touch $(DESTINATION_FOLDER)

uninstall:
	$(RM) -rf $(DESTINATION_FOLDER)/$(DICT_NAME).dictionary

clean:
	$(RM) -rf $(DICT_DEV_KIT_OBJ_DIR) erldict.xml erldict.dmg

xml:
	$(RUBY) erldict.rb

xml_d:
	$(RUBY) -d erldict.rb

open:
	$(OPEN) /Applications/Dictionary.app

dmg:
	rm -f objects/*.offsets objects/*.txt objects/*.body erldict.dmg
	cp README_DICT.md objects/README.txt
	cp -r erlre objects
	cp -r erlre_rb objects
	hdiutil create -volname erldict -srcfolder objects erldict.dmg

