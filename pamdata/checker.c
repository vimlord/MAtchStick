#include "checker.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <unistd.h>
#include <sys/wait.h>

#include <errno.h>

/**
 * Checks whether or not a given password and hash match.
 */
int check(const char *passwd, const char *hash) {
    pid_t pid;

    // Pipe from SHA
    int out[2];

    if (pipe(out) == -1) {
        perror("pipe");
        exit(1);
    }

    if ((pid = fork()) == -1) {
        perror("fork");
        return 0;
    } else if (!pid) {
        // Child does not need to read
        close(out[0]);

        // Stdout of the child goes through the pipe
        while (dup2(out[1], STDOUT_FILENO) != -1 && errno == EINTR);

        char *cmd[3] = {
            "hashit", strdup(passwd), NULL
        };

        // Execute the hash script
        execvp(cmd[0], cmd);
        perror("execvp");
        _exit(1);
    }

    char res[96];

    // Parent does not write to the child
    close(out[1]);

    // Read in the hash
    while (1) {
        ssize_t n = read(out[0], res, sizeof(res));

        if (n == -1) {
            if (errno == EINTR)
                continue;
            else {
                perror("read");
                close(out[0]);
                return 0;
            }
        } else if (n) {
            // Remove everything from the space onwards
            int i;
            for (i = 0; res[i] && res[i] != ' '; ++i);
            res[i] = 0;
            // Check the results, then tear down
            n = strcmp(res, hash) == 0;
            close(out[0]);
            return n;
        } else {
            printf("Read nothing\n");
            close(out[0]);
            return 0;
        }
    }
}

int check_password(const char *passwd) {
    FILE *fp;
    char buff[2048];

    fp = popen("getkeys", "r");
    if (!fp) return 0;
    
    // Read
    fgets(buff, sizeof(buff), fp);
    
    // Wipe the non-hash components
    buff[64] = 0;
    
    // Get the answer
    int res = check(passwd, buff);

    // Terminate the program
    pclose(fp);
    
    // Provide the answer
    if (res) {
        return buff[65] == '0' ? 1 : -1;
    } else {
        return 0;
    }
}

int check_verbose(char *passwd) {
    if (check_password(passwd)) {
        printf("Yes\n");
    } else {
        printf("No\n");
    }
}

