# Copyright 2019
# Created by Christopher Hittner and Justin Barish
# All Rights Reserved.

PAM_NAME=pamela
APP_NAME=app

FILENAME=pam_$(PAM_NAME).so

all: pam app

app: pam
	# Building app
	cc -o $(APP_NAME) app.c -lpam -lpam_misc

pam: clean
	# Create the pam library object
	cc -fPIC -fno-stack-protector -c pam.c -o pam.o
	cc -fPIC -fno-stack-protector -c checker.c -o checker.o
	# Create the PAM library file
	ld -x --shared -o /lib/security/$(FILENAME) pam.o checker.o
	# Move the PAM config into place
	cp $(PAM_NAME) /etc/pam.d/

clean:
	rm -f pam.o checker.o

fclean: clean
    # Deleting all generated files
	rm -f /etc/pam.d/$(PAM_NAME) /lib/security/$(FILENAME) ./$(APP_NAME)

