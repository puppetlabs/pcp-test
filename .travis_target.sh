#!/bin/bash
set -ev

# Set compiler to GCC 4.8 here, as Travis overrides the global variables.
export CC=gcc-5 CXX=g++-5

if [ ${TRAVIS_TARGET} == CPPCHECK ]; then
  # grab a pre-built cppcheck from s3
  wget https://s3.amazonaws.com/kylo-pl-bucket/pcre-8.36_install.tar.bz2
  tar xjvf pcre-8.36_install.tar.bz2 --strip 1 -C $USERDIR
  wget https://s3.amazonaws.com/kylo-pl-bucket/cppcheck-1.69_install.tar.bz2
  tar xjvf cppcheck-1.69_install.tar.bz2 --strip 1 -C $USERDIR
elif [ ${TRAVIS_TARGET} == DEBUG ]; then
  # Install coveralls.io update utility
  pip install --user cpp-coveralls
fi

# Install cpp-pcp-client
git clone https://github.com/puppetlabs/cpp-pcp-client
cd cpp-pcp-client
git checkout $CPP_PCP_CLIENT_VERSION
cmake -DCMAKE_INSTALL_PREFIX=$USERDIR .
make install -j2
cd ..

# Generate build files
if [ ${TRAVIS_TARGET} == DEBUG ]; then
  TARGET_OPTS="-DCMAKE_BUILD_TYPE=Debug -DCOVERALLS=ON"
fi
cmake $TARGET_OPTS -DCMAKE_INSTALL_PREFIX=$USERDIR .

if [ ${TRAVIS_TARGET} == CPPLINT ]; then
  make cpplint
elif [ ${TRAVIS_TARGET} == CPPCHECK ]; then
  make cppcheck
else
  make -j2
  make test ARGS=-V

  # Make sure installation succeeds
  make install

  # Disable coveralls for private repos
  if [ ${TRAVIS_TARGET} == DEBUG ]; then
    # Ignore coveralls failures, keep service success uncoupled
    coveralls --gcov gcov-4.8 --gcov-options '\-lp' >/dev/null || true
  fi
fi
