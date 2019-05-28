
#include <security/pam_appl.h>
#include <security/pam_misc.h>
#include <stdio.h>

static struct pam_conv conv = {
    misc_conv, NULL
};

int main(int argc, char *argv[]) {
    pam_handle_t *pamh = NULL;
    int n;
    const char *user = "sourcecode";

    if (argc == 2) {
        user = argv[1];
    } else if (argc > 2) {
        fprintf(stderr, "usage: pamapp [username]\n");
        exit(1);
    }

    const char *service = "pamtest";
    printf("Will attempt to validate via the '%s' module\n", service);
    
    // Initialize PAM
    n = pam_start(service, user, &conv, &pamh);

    if (n == PAM_SUCCESS) {
        printf("start() successful\n");
        // Try to authenticate
        n = pam_authenticate(pamh, 0);
    }
    
    if (n == PAM_SUCCESS) {
        printf("authenticate() successful\n");
        // Check user permissions
        n = pam_acct_mgmt(pamh, 0);
    }

    if (n == PAM_SUCCESS) {
        printf("acct_mgmt() successful\n");
        // Authentication is successful
        fprintf(stdout, "Authenticated\n");
    } else {
        printf("acct_mgmt() unsuccessful; returned %i\n", n);
        // Authentication failed
        fprintf(stdout, "Not Authenticated\n");
    }

    // Close PAM
    if (pam_end(pamh, n) != PAM_SUCCESS) {
        pamh = NULL;
        fprintf(stderr, "pamapp: failed to release pam\n");
        exit(1);
    }
    
    // Return end result
    return n == PAM_SUCCESS ? 0 : 1;
    
}

