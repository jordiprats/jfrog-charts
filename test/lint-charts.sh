#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

readonly IMAGE_TAG=${CHART_TESTING_TAG}
readonly IMAGE_REPOSITORY="quay.io/helmpack/chart-testing"
readonly REPO_ROOT="${REPO_ROOT:-$(git rev-parse --show-toplevel)}"

# shellcheck source=test/common.sh
source "${REPO_ROOT}/test/common.sh"

check_changelog_version() {
    local changed_charts=("")
    while IFS='' read -r line; do changed_charts+=("$line"); done < <(get_changed_charts)
    echo "Changed Charts: ${changed_charts[*]}"
    for chart_name in ${changed_charts[*]} ; do
        echo "Checking CHANGELOG for chart ${chart_name}"
        local chart_version
        chart_version=$(grep "version:" "${REPO_ROOT}/${chart_name}/Chart.yaml")
        ## Check that the version has an entry in the changelog
        if ! grep -q "\[${chart_version}\]" "${REPO_ROOT}/${chart_name}/CHANGELOG.md"; then
            echo "No CHANGELOG entry for chart ${chart_name} version ${chart_version}"
            exit 1
        else
            echo "Found CHANGELOG entry for chart ${chart_name} version ${chart_version}"
        fi
    done
    echo "Done CHANGELOG Check!"
}


main() {
    git_fetch

    mkdir -p tmp
    docker run --rm -v "$(pwd):/workdir" --workdir /workdir "$IMAGE_REPOSITORY:$IMAGE_TAG" ct lint --config /workdir/test/ct.yaml | tee tmp/lint.log

    check_changelog_version

    echo "Done Charts Linting!"
}

main
