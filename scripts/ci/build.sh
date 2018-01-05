#!/usr/bin/env bash

# Build wheel packages containing both CLI product and tests. The script doesn't rely on a pre-existing virtual
# environment.

set -e

##############################################
# clean up and dir search
mkdir -p ./artifacts
echo `git rev-parse --verify HEAD` > ./artifacts/build.sha

mkdir -p ./artifacts/build
mkdir -p ./artifacts/source
mkdir -p ./artifacts/app
mkdir -p ./artifacts/testsrc

output_dir=$(cd artifacts/build && pwd)
sdist_dir=$(cd artifacts/source && pwd)
testsrc_dir=$(cd artifacts/testsrc && pwd)
app_dir=$(cd artifacts/app && pwd)
script_dir=`cd $(dirname $0); pwd`

##############################################
# Define colored output func
function title {
    LGREEN='\033[1;32m'
    CLEAR='\033[0m'

    echo -e ${LGREEN}$1${CLEAR}
}


##############################################
# Update version strings
title 'Determine version'
. $script_dir/version.sh $1
echo -n $version > ./artifacts/version

##############################################
# build product packages
title 'Build Azure CLI and its command modules'
for setup_file in $(find src -name 'setup.py'); do
    pushd $(dirname $setup_file) >/dev/null
    echo "Building module at $(pwd) ..."
    python setup.py -q bdist_wheel -d $output_dir
    python setup.py -q sdist -d $sdist_dir
    popd >/dev/null
done

##############################################
# build test packages
title 'Build Azure CLI tests package'

for test_src in $(find src/command_modules -name tests -type d); do
    rel_path=${test_src##src/command_modules/}
    rel_path=(${rel_path/\// })
    rel_path=${rel_path[1]}

    mkdir -p $testsrc_dir/$rel_path
    cp -R $test_src/* $testsrc_dir/$rel_path
done

for test_src in $(find src -name tests | grep -v command_modules); do
    rel_path=${test_src##src/}
    rel_path=(${rel_path/\// })
    rel_path=${rel_path[1]}

    mkdir -p $testsrc_dir/$rel_path
    cp -R $test_src/* $testsrc_dir/$rel_path
done

cat >$testsrc_dir/setup.py <<EOL
#!/usr/bin/env python

from setuptools import setup

VERSION = "1.0.0.dev$version"

CLASSIFIERS = [
    'Development Status :: 3 - Alpha',
    'Intended Audience :: Developers',
    'Programming Language :: Python',
    'Programming Language :: Python :: 2',
    'Programming Language :: Python :: 2.7',
    'Programming Language :: Python :: 3',
    'Programming Language :: Python :: 3.4',
    'Programming Language :: Python :: 3.5',
    'Programming Language :: Python :: 3.6',
    'License :: OSI Approved :: MIT License',
]

DEPENDENCIES = [
    'azure-cli',
    'azure-cli-testsdk'
]

setup(
    name='azure-cli-fulltest',
    version=VERSION,
    description='Microsoft Azure Command-Line Tools Full Tests',
    license='MIT',
    author='Microsoft Corporation',
    author_email='azpycli@microsoft.com',
    url='https://github.com/Azure/azure-cli',
    zip_safe=False,
    classifiers=CLASSIFIERS,
    packages=[
        'azure.cli.core.tests',
EOL

for name in $(ls src/command_modules | grep azure-cli-); do
    module_name=${name##azure-cli-}
    if [ -d src/command_modules/$name/azure/cli/command_modules/$module_name/tests ]; then
        echo "        'azure.cli.command_modules.$module_name.tests'," >>$testsrc_dir/setup.py
    fi
done


cat >>$testsrc_dir/setup.py <<EOL
    ],
    package_data={'': ['recordings/**/*.yaml',
                       'data/*.zip',
                       'data/*.whl',
                       '*.pem',
                       '*.pfx',
                       '*.txt',
                       '*.json',
                       '*.byok',
                       '*.js',
                       '*.md',
                       '*.bat',
                       '*.txt',
                       '*.cer',
                       '**/*.cer',
                       '**/*.pem',
                       '**/*.pfx',
                       '**/*.txt',
                       '**/*.json',
                       '**/*.byok',
                       '**/*.js',
                       '**/*.md',
                       '**/*.bat',
                       '**/*.txt']},
    install_requires=DEPENDENCIES
)
EOL

cat >>$testsrc_dir/setup.cfg <<EOL
[bdist_wheel]
universal=1
EOL

cat >>$testsrc_dir/README.txt <<EOL
Azure CLI Test Cases
EOL

pushd $testsrc_dir >/dev/null
python setup.py -q bdist_wheel -d $output_dir
python setup.py -q sdist -d $sdist_dir
popd >/dev/null

##############################################
# clear afterwards
rm -rf $testsrc_dir
git checkout src

##############################################
# summary
title 'Results'
echo $(ls $sdist_dir | wc -l) packages created.
