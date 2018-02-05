#! /usr/bin/env sh
set -e

this_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
temp_dir=$(mktemp -d)
trap "rm -rf $temp_dir" EXIT SIGTERM
ls "$temp_dir"
cp "$this_dir/../go.sh" "$temp_dir/"
cd "$temp_dir"

input=$(cat <<HERE
set timeout 5

# Test required input and stop setup
spawn ./go.sh

expect {
  "CLI name (required)(no special characters):" { send "\r" }
  timeout { exit 1 }
}

expect {
  "CLI name (required)(no special characters):" { send "my-cli\r" }
  timeout { exit 1 }
}

expect {
 "Setup git repo? (yes/no):" { send "\r" }
  timeout { exit 1 }
}

expect {
  "Setup git repo? (yes/no):" { send "text\r" }
  timeout { exit 1 }
}

expect {
  "Setup git repo? (yes/no):" { send "no\r" }
  timeout { exit 1 }
}

expect {
  "Create cli *my-cli* in *$temp_dir* with git repo *no*. Ok? (yes/no): " { send "no\r" }
  timeout { exit 1 }
}

expect {
  "*Setup aborted*" {}
  timeout { exit 1 }
}

interact

HERE
)

echo "$input" | expect --

test_2=$(cat <<HERE
set timeout 5

# Test required input and stop setup
spawn ./go.sh

expect {
  "CLI name (required)(no special characters):" { send "my-cli\r" }
  timeout { exit 1 }
}

expect {
  "Setup git repo? (yes/no):" { send "yes\r" }
  timeout { exit 1 }
}

expect {
  "Create cli *my-cli* in *$temp_dir* with git repo *yes*. Ok? (yes/no): " { send "yes\r" }
  timeout { exit 1 }
}

expect {
  "*Setup complete*" {}
  timeout { exit 1 }
}

interact

HERE
)

echo "$test_2" | expect --

git_test="$(git log -1 --pretty=%B)"

if [[ "$git_test" != "Initial commit" ]]
then
  echo fail
  exit 3
fi

output=$(./bin/my-cli)
expected=$(cat <<HERE
Downloading sdoc

Usage: my-cli <command> [args]

Built-in Commands:
  help        h     Show help for all commands or a specific command
  edit        e     Edit the implementation of a command
  edit-config ec    Edit the configuration file
  view        v     View the implementation of a command

Commands:
  hello             Prints hello world
HERE
)

if [[ "$output" != "$expected" ]]
then
  echo fail
  exit 4
fi

exit 0
