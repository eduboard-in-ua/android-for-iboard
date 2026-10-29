#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd -P)
cd "$repo_root"

for tool in git clang; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        printf 'ERROR: %s is required for the static source checks.\n' "$tool" >&2
        exit 1
    fi
done

if [ "$(git rev-parse --show-toplevel)" != "$repo_root" ]; then
    printf 'ERROR: Run this script from its iBoard Git checkout.\n' >&2
    exit 1
fi

work_dir=$(mktemp -d "${TMPDIR:-/tmp}/iboard-android-check.XXXXXX")
trap 'rm -rf -- "$work_dir"' 0
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

baseline=$(git rev-list --max-parents=0 HEAD)
git diff --check "$baseline" HEAD --
git diff --cached --check
git diff --check
printf 'PASS: committed, staged and working-tree whitespace checks.\n'

require_branding()
{
    if ! grep -Fq "$1" "$2"; then
        printf 'ERROR: expected iBoard branding is missing from %s.\n' "$2" >&2
        exit 1
    fi
}
require_branding 'printf("iBoard RK3588 OPS U-Boot Board Init Start\n");' snippets/board.c
require_branding 'printf("iBoard RK3588 OPS Board Init Complete\n");' snippets/board.c
require_branding 'model = "iBoard RK3588 Android OPS Board";' snippets/rk3588-android-ops.dtsi
printf 'PASS: iBoard initialization messages and Device Tree model.\n'

cat > "$work_dir/environment.c" <<'EOF'
#include <stddef.h>
#include <stdio.h>
#include <string.h>

#define BOOTENV_SHARED_MTD ""
#define ENV_MEM_LAYOUT_SETTINGS ""
#define PARTS_RKIMG "test-partitions"
#include "boot-env.h"

static const char environment[] = CONFIG_EXTRA_ENV_SETTINGS;

int main(void)
{
    const size_t size = sizeof(environment);
    size_t offset = 0;
    size_t entries = 0;

    if (size < 2 || environment[size - 1] || environment[size - 2]) {
        fputs("ERROR: environment must end with two NUL bytes.\n", stderr);
        return 1;
    }

    while (offset < size - 1) {
        const char *entry = environment + offset;
        const char *end = memchr(entry, '\0', size - 1 - offset);
        const char *equals;

        if (!end || end == entry) {
            fputs("ERROR: empty or unterminated environment entry.\n", stderr);
            return 1;
        }
        equals = memchr(entry, '=', (size_t)(end - entry));
        if (!equals || equals == entry) {
            fputs("ERROR: environment entries need a nonempty key.\n", stderr);
            return 1;
        }
        offset = (size_t)(end - environment) + 1;
        ++entries;
    }

    if (!entries) {
        fputs("ERROR: environment has no entries.\n", stderr);
        return 1;
    }
    printf("PASS: %zu NUL-separated environment entries (test macros).\n", entries);
    return 0;
}
EOF

clang -std=c11 -Wall -Wextra -Werror -I "$repo_root/snippets" \
    "$work_dir/environment.c" -o "$work_dir/environment"
"$work_dir/environment"

for mode in normal spl; do
    if [ "$mode" = spl ]; then
        set -- -DCONFIG_SPL_BUILD
    else
        set --
    fi
    clang --target=aarch64-none-elf -x assembler-with-cpp -c \
        -DCONFIG_SYS_INIT_SP_ADDR=0x80000 -DCONFIG_SPL_STACK=0x40000 \
        "$@" snippets/startup.S -o "$work_dir/startup-$mode.o"
    printf 'PASS: AArch64 %s startup syntax (test stack constants).\n' "$mode"
done

printf '%s\n' \
    'INTEGRATION REQUIRED: confirm Android boot arguments, fan states, GPIO mapping and board hooks against the target BSP; see README.' \
    'PASS: static source checks only; BSP integration and hardware behavior remain unvalidated.'
