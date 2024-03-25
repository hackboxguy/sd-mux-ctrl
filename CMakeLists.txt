#cmake file for building sd-mux(taken from: https://git.tizen.org/cgit/tools/testlab/sd-mux/tree/src/CMakeLists.txt)
#details of the SDWire hw are found here: https://shop.3mdeb.com/shop/open-source-hardware/sdwire/)
#this utility depends on libftdi1 and libpopt
cmake_minimum_required(VERSION 2.8.9)
set(COMPONENT_NAME sd-mux-ctrl)  #set the name of the binary
project(${COMPONENT_NAME})

file(GLOB SOURCES "*.cpp")
add_executable(${COMPONENT_NAME} ${SOURCES})

# Specify component's dependency.
target_link_libraries(${COMPONENT_NAME} ftdi1 popt)
install(TARGETS ${COMPONENT_NAME} DESTINATION usr/sbin/)

#file(GLOB  INSTALLFILES "*.conf")
#install(FILES ${INSTALLFILES} DESTINATION etc/supervisor.d/)


#for cross compiling
#cmake -H. -BOutput -DCMAKE_TOOLCHAIN_FILE=/path/to/toolchain-arm-backup.cmake -DCMAKE_INSTALL_PREFIX=/home/user/tmp/
#cmake --build Output -- all
#cmake --build Output -- install

#for local compiling
#cmake -H. -BOutput
#cmake --build Output -- all

#for cleaning make generated output
#rm -rf Output
