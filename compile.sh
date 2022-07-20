#!/bin/bash

# Exit on first error
set -e



#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Collecting data on OS & intended build

DEBUG=0
TEST=0
case "${1}" in
  release)
    ;; # for now
  debug)
    DEBUG=1;;
  test)
    DEBUG=1
    TEST=1;;
  *)
    echo "Syntax: ${0} <release|debug|test>"
    exit 1;;
esac

# Detect operating system
case "$(uname -s)" in
  Darwin)
    OS=mac;;
  Linux)
    OS=linux;;
  CYGWIN*|MINGW32*|MSYS*|MINGW*)
    OS=windows;; # my condolences
  *)
    echo "Unsupported OS"
    exit 1;;
esac

# Detect architecture
BITS=$(getconf LONG_BIT)



#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Ensuring we have everything we need

# Download updated submodules (Eigen, etc.)
git submodule update --init --recursive

# Download NaoQI SDK if not already present
if [ ! -d ./naoqi-sdk ]
then
  # V5 SDKS ARE ALL HERE, THEY'RE JUST SO OLD THERE ARE NO LINKS TO THIS PAGE ANYWHERE <3
  # https://www.softbankrobotics.com/emea/en/support/nao-6/downloads-softwares/former-versions

  # Download
  wget -O naoqi-sdk.tar.gz "https://community-static.aldebaran.com/resources/2.1.4.13/sdk-c%2B%2B/naoqi-sdk-2.1.4.13-${OS}${BITS}.tar.gz"
  
  # Unpack
  # This is going to make Git go berserk
  tar -xzf naoqi-sdk.tar.gz
  
  # Remove the horrific filename extension
  # The resulting folder (naoqi-sdk) is .gitignore'd
  find . -type d -maxdepth 1 -iname 'naoqi-sdk*' -print -quit | xargs -t -I{} mv {} ./naoqi-sdk
  
  # Delete the original compressed file
  rm naoqi-sdk.tar.gz
fi

if [ "${DEBUG}" -eq 1 ]
then
  # Download SDL2 if not already present
  sdl2-config --version > /dev/null || (\
    git clone https://github.com/libsdl-org/SDL && \
    cd SDL && \
    mkdir build && cd build && \
    ../configure && \
    make -j$(nproc --all) && \
    sudo make install)
fi



#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Now begin the compilation process

MACROS="-D_BITS=${BITS} -D_DEBUG=${DEBUG} -D_IMAGE_W=1280 -D_IMAGE_H=960 -D_DISPLAY_ON=${TEST} -D_XOPEN_SOURCE=700"
INCLUDES="-I./src -I./eigen -I./naoqi_driver/include"
FLAGS="-march=native -funit-at-a-time -Wall -Wextra -Werror"

if [ "${DEBUG}" -eq 1 ]
then
  FLAGS="${FLAGS} -g -O0"
  INCLUDES="${INCLUDES} $(sdl2-config --cflags)"
else
  FLAGS="${FLAGS} -Ofast"
fi

ALL="${FLAGS} ${MACROS} ${INCLUDES}"

if [ "${TEST}" -eq 1 ]
then
  ./code_checker.sh
  find ./src -type f -name '*.*pp' | xargs -t -I{} clang++ -c -std=c++20 -o ./tmp_compiled {} ${ALL}
  find ./src -type f -name '*.c' | xargs -t -I{} clang -c -std=c17 -o ./tmp_compiled {} ${ALL}
	rm -f ./tmp_compiled
fi

clang++ -std=c++20 -o run ./src/main.cpp ${ALL}