#! /usr/bin/env bash

$(cd .. | git branch androidx_migrate)
$(cd .. | git checkout androidx_migrate)


SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPTS_DIR}"/.. && pwd)"
MAPPING_FILE="$SCRIPTS_DIR/androidx_class_map.csv"
ARTIFACT_MAPPING_FILE="$SCRIPTS_DIR/androidx-artifact-mapping.csv"
BUILD_FILE="${PROJECT_DIR}/build.gradle"

# upgrade gradle wrapper
$(cd ${PROJECT_DIR} && ./gradlew wrapper --gradle-version 5.4.1 >/dev/null)

# upgrade gradle tool
$(sed -i "" "s/com.android.tools.build:gradle:.*/com.android.tools.build:gradle:3.5.2/g;
s/com.google.protobuf:protobuf-gradle-plugin:.*/com.google.protobuf:protobuf-gradle-plugin:0.8.6/g" ${BUILD_FILE})

from_pkgs=""
replace=""
while IFS=, read -r from_pkg to_pkg
do
    from_pkgs+=" -e $from_pkg"
    replace+="; s/$from_pkg/$to_pkg/g"
done <<< "$(tail -n +2 $MAPPING_FILE)"

rg --files-with-matches -t java -t kotlin -t xml -F $from_pkgs $PROJECT_DIR | xargs perl -pi -e "$replace"

echo '\nandroid.useAndroidX=true
android.enableJetifier=true' >>$PROJECT_DIR/gradle.properties

from_pkgs=""
replace=""
while IFS=, read -r from_pkg to_pkg
do
    from_pkgs+=" -e $from_pkg"
    replace+="; s/(\"|')$from_pkg.*(\"|')/\"$to_pkg\"/g"
#replace+="; s/\(\\\"\|'\)$from_pkg.*\(\\\"\|'\)/\\\"$to_pkg\\\"/g"
done <<< "$(tail -n +2 $ARTIFACT_MAPPING_FILE)"

rg --files-with-matches -t groovy -F $from_pkgs $PROJECT_DIR | xargs perl -pi -e "$replace"

#find $PROJECT_DIR -name "*.gradle" >artifact.txt
#
#while read line
#do
#gsed -i "$replace" $line
#done <artifact.txt
#$(rm -rf artifact.txt)

exit 0