#!/usr/bin/python3

import argparse
import crypt
from hmac import compare_digest


def get_entry(username):
    result = None

    with open('auth.txt') as f:
        for line in f:
            line = line.rstrip().split(':')
            if line[0] == username:
                # we intentionally don't short circuit here
                result = line

    if result is not None and len(result) > 2:
        return (result[0], result[1], result[2])
    elif result is not None and len(result) == 2:
        return (result[0], result[1], "")
    else:
        return None


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--user', required=True)
    parser.add_argument('--password', required=True)
    args = parser.parse_args()

    entry = get_entry(args.user)
    if entry is not None:
        hashed_password = crypt.crypt(args.password, entry[1])
        if compare_digest(hashed_password, entry[1]):
            print('true')
            print(entry[2])
        else:
            print('false')
    else:
        print('false')
