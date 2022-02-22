#!/bin/bash
## NOTEs:
### This simple build process is useful so the created date/time field only change for the new and updated charts (and remains the same for the old ones)
### We also will build only the package with new git TAGs

helm_package() {
    local chart_path=$1
    helm package -u -d build/ "$chart_path"
}

git_tag() {
    local chart_path=$1
    local chart_name=$(helm show chart "$chart_path" | grep "name:" | awk -F ': ' '{ print $2 }');
    local chart_version=$(helm show chart "$chart_path" | grep "version:" | awk -F ': ' '{ print $2 }');
    git tag "$chart_name-$chart_version"
}

build() {
    local chart_path=$1
    git_tag "$1"
    if [ $? -eq 0 ]; then
        helm_package "$1"
    fi
}

## create build dir
mkdir -p build/

build "src/webmethods-apigateway"
build "src/webmethods-devportal"
build "src/webmethods-microgateway"
build "src/webmethods-terracotta"
build "src/samplejavaapis-sidecar-microgateway"

## check if anything was added to the build folder, and index if yes
built_packages=$(ls build/*.tgz)
if [ $? -eq 0 ]; then
    ## create new index with only the new modified charts
    helm repo index --merge docs/index.yaml build/

    ## copy new index ot the final repo location
    cp -f build/index.yaml docs/
    cp -f build/*.tgz docs/

    ## clean up
    rm -Rf build/
else
    echo "No package was build in the build folder...nothing to change"
fi