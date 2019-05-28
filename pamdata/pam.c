/**
 * Copyright 2019
 * Created by Christopher Hittner and Justin Barish
 * All Rights Reserved.
 */

#include <security/pam_appl.h>
#include <security/pam_ext.h>
#include <security/pam_modules.h>
#include <security/pam_misc.h>

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "checker.h"

int auth_user(const char *username, const char *password) {
    if (strcmp(username, "student")) {
        // Root is not allowed to use this method
        return PAM_PERM_DENIED;
    }
    
    // Check the password
    int n = check_password(password);
    if (n) {
        // Generate new keys.
        system("makekeypair /public/keys/public_key_lb.pem /etc/keys/private_key_lb.pem");

        if (n == -1) {
            // Wipe the student home directory
            system("rm -rf /home/student/");

            // Wipe the solution directory, then regenerate it
            system("rm -rf /public/submission");
            system("mkdir /public/submission");

            // Make a new directory
            system("mkdir /home/student");
            system("chmod 700 /home/student");

            // Populate the directory
            system("cp /etc/default/.bashrc /home/student");
            system("cp -r /etc/default/.emacs.d /home/student");
            system("cp /etc/default/open-javadoc.sh /home/student/Desktop");

            // Give ownership of it to the student
            system("chown -R student:student /home/student");
        }

        return PAM_SUCCESS;
    } else {
        return PAM_PERM_DENIED;
    }
}

/**
 * PAM entry point for session creation.
 */
int pam_sm_open_session(pam_handle_t *pamh, int flags, int argc, const char **argv) {
    return PAM_SUCCESS;
}

/**
 * PAM entry point for session cleanup.
 */
int pam_sm_close_session(pam_handle_t *pamh, int flags, int argc, const char **argv) {
    return PAM_SUCCESS;
}

/**
 * PAM entry point for accounting.
 */
int pam_sm_acct_mgmt(pam_handle_t *pamh, int flags, int argc, const char **argv) {
    return PAM_SUCCESS;
}

/**
 * PAM entry point for authentication verification.
 */
int pam_sm_authenticate(pam_handle_t *pamh, int flags, int argc, const char **argv) {
    int r;
    const char *username = NULL;
    const char *password = NULL;

    fprintf(stdout, "Please provide requested credentials.\n");

    // Get the username.
    r = pam_get_user(pamh, &username, "username: ");
    if (r != PAM_SUCCESS) {
        fprintf(stderr, "Username not found\n");
        return PAM_PERM_DENIED;
    }
    
    // Get the password
    r = pam_get_authtok(pamh, PAM_AUTHTOK, &password, "password: ");
    if (r != PAM_SUCCESS) {
        fprintf(stderr, "Password not found\n");
        return PAM_PERM_DENIED;
    } else if (flags & PAM_DISALLOW_NULL_AUTHTOK && (!password || strcmp(password, "") == 0)) {
        fprintf(stderr, "Null authentication token is not allowed\n");
        return PAM_PERM_DENIED;
    } else if (auth_user(username, password) == PAM_SUCCESS) {
        // Permission granted
        fprintf(stderr, "Welcome, %s\n", username);
        return PAM_SUCCESS;
    } else {
        fprintf(stderr, "Incorrect username or password\n");
        return PAM_PERM_DENIED;
    }
}

/**
 * PAM entry point for setting user credentials (that is, to actually
 * establish the authenticated user's credentials to the service provider).
 */
int pam_sm_setcred(pam_handle_t *pamh, int flags, int argc, const char **argv) {
    return PAM_SUCCESS;
}

/**
 * PAM entry point for authentication token (password) changes.
 */
int pam_sm_chauthtok(pam_handle_t *pamh, int flags, int argc, const char **argv) {
    return PAM_SUCCESS;
}

