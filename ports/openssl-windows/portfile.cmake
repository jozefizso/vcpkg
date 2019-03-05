if(VCPKG_CMAKE_SYSTEM_NAME)
    message(FATAL_ERROR "This port is only for building openssl on Windows Desktop")
endif()

include(vcpkg_common_functions)
set(OPENSSL_VERSION 1.1.1b)
set(MASTER_COPY_SOURCE_PATH ${CURRENT_BUILDTREES_DIR}/src/openssl-${OPENSSL_VERSION})

vcpkg_find_acquire_program(PERL)

get_filename_component(PERL_EXE_PATH ${PERL} DIRECTORY)
set(ENV{PATH} "$ENV{PATH};${PERL_EXE_PATH}")

vcpkg_download_distfile(OPENSSL_SOURCE_ARCHIVE
    URLS "https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz"
    FILENAME "openssl-${OPENSSL_VERSION}.tar.gz"
    SHA512 b54025fbb4fe264466f3b0d762aad4be45bd23cd48bdb26d901d4c41a40bfd776177e02230995ab181a695435039dbad313f4b9a563239a70807a2e19ecf045d
)

vcpkg_extract_source_archive(${OPENSSL_SOURCE_ARCHIVE})
vcpkg_apply_patches(
    SOURCE_PATH ${MASTER_COPY_SOURCE_PATH}
)

vcpkg_find_acquire_program(NASM)
get_filename_component(NASM_EXE_PATH ${NASM} DIRECTORY)
set(ENV{PATH} "${NASM_EXE_PATH};$ENV{PATH}")

find_program(NMAKE nmake)

set(OPENSSL_MAKEFILE "makefile")

set(CONFIGURE_COMMAND ${PERL} Configure
    enable-static-engine
    enable-capieng
    no-makedepend
    no-tests
)

if(VCPKG_TARGET_ARCHITECTURE STREQUAL "x86")
    set(OPENSSL_ARCH VC-WIN32)
elseif(VCPKG_TARGET_ARCHITECTURE STREQUAL "x64")
    set(OPENSSL_ARCH VC-WIN64A)
elseif(VCPKG_TARGET_ARCHITECTURE STREQUAL "arm")
    set(OPENSSL_ARCH VC-WIN32)
    set(OPENSSL_DO "ms\\do_ms.bat")
    set(CONFIGURE_COMMAND ${CONFIGURE_COMMAND}
        -D_ARM_WINAPI_PARTITION_DESKTOP_SDK_AVAILABLE
    )
else()
    message(FATAL_ERROR "Unsupported target architecture: ${VCPKG_TARGET_ARCHITECTURE}")
endif()

if(VCPKG_LIBRARY_LINKAGE STREQUAL dynamic)
    set(CONFIGURE_COMMAND ${CONFIGURE_COMMAND} shared)
else()
    set(CONFIGURE_COMMAND ${CONFIGURE_COMMAND} no-shared)
endif()

file(REMOVE_RECURSE ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-dbg)


if(NOT DEFINED VCPKG_BUILD_TYPE OR VCPKG_BUILD_TYPE STREQUAL "release")
    file(COPY ${MASTER_COPY_SOURCE_PATH} DESTINATION ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel)
    set(SOURCE_PATH_RELEASE ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel/openssl-${OPENSSL_VERSION})
    set(OPENSSLDIR_RELEASE ${CURRENT_PACKAGES_DIR})

    message(STATUS "Configure ${TARGET_TRIPLET}-rel")
    vcpkg_execute_required_process(
        COMMAND ${CONFIGURE_COMMAND} ${OPENSSL_ARCH} "--prefix=${OPENSSLDIR_RELEASE}" "--openssldir=${OPENSSLDIR_RELEASE}" "CPPFLAGS=/utf-8 /MP /FS"
        WORKING_DIRECTORY ${SOURCE_PATH_RELEASE}
        LOGNAME configure-perl-${TARGET_TRIPLET}-${CMAKE_BUILD_TYPE}-rel
    )
    message(STATUS "Configure ${TARGET_TRIPLET}-rel done")

    message(STATUS "Build ${TARGET_TRIPLET}-rel")
    vcpkg_execute_required_process(
        COMMAND nmake -f ${OPENSSL_MAKEFILE}
        WORKING_DIRECTORY ${SOURCE_PATH_RELEASE}
        LOGNAME build-${TARGET_TRIPLET}-rel-0
    )
    vcpkg_execute_required_process(
        COMMAND nmake -f ${OPENSSL_MAKEFILE} install
        WORKING_DIRECTORY ${SOURCE_PATH_RELEASE}
        LOGNAME build-${TARGET_TRIPLET}-rel-1
    )

    message(STATUS "Build ${TARGET_TRIPLET}-rel done")
endif()


if(NOT DEFINED VCPKG_BUILD_TYPE OR VCPKG_BUILD_TYPE STREQUAL "debug")
    message(STATUS "Configure ${TARGET_TRIPLET}-dbg")
    file(COPY ${MASTER_COPY_SOURCE_PATH} DESTINATION ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-dbg)
    set(SOURCE_PATH_DEBUG ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-dbg/openssl-${OPENSSL_VERSION})
    set(OPENSSLDIR_DEBUG ${CURRENT_PACKAGES_DIR}/debug)

    vcpkg_execute_required_process(
        COMMAND ${CONFIGURE_COMMAND} debug-${OPENSSL_ARCH} "--prefix=${OPENSSLDIR_DEBUG}" "--openssldir=${OPENSSLDIR_DEBUG}" "CPPFLAGS=/utf-8 /MP /FS"
        WORKING_DIRECTORY ${SOURCE_PATH_DEBUG}
        LOGNAME configure-perl-${TARGET_TRIPLET}-${CMAKE_BUILD_TYPE}-dbg
    )
    message(STATUS "Configure ${TARGET_TRIPLET}-dbg done")

    message(STATUS "Build ${TARGET_TRIPLET}-dbg")
    vcpkg_execute_required_process(
        COMMAND nmake -f ${OPENSSL_MAKEFILE}
        WORKING_DIRECTORY ${SOURCE_PATH_DEBUG}
        LOGNAME build-${TARGET_TRIPLET}-dbg-0
    )
    vcpkg_execute_required_process(
        COMMAND nmake -f ${OPENSSL_MAKEFILE} install
        WORKING_DIRECTORY ${SOURCE_PATH_DEBUG}
        LOGNAME build-${TARGET_TRIPLET}-dbg-1
    )

    message(STATUS "Build ${TARGET_TRIPLET}-dbg done")
endif()


file(REMOVE_RECURSE
    ${CURRENT_PACKAGES_DIR}/debug/certs
    ${CURRENT_PACKAGES_DIR}/debug/html
    ${CURRENT_PACKAGES_DIR}/debug/include
    ${CURRENT_PACKAGES_DIR}/debug/lib/engines-1_1
    ${CURRENT_PACKAGES_DIR}/debug/misc
    ${CURRENT_PACKAGES_DIR}/debug/private
    ${CURRENT_PACKAGES_DIR}/certs
    ${CURRENT_PACKAGES_DIR}/html
    ${CURRENT_PACKAGES_DIR}/lib/engines-1_1
    ${CURRENT_PACKAGES_DIR}/misc
    ${CURRENT_PACKAGES_DIR}/private
)
file(REMOVE
    ${CURRENT_PACKAGES_DIR}/debug/bin/openssl.exe
    ${CURRENT_PACKAGES_DIR}/debug/bin/openssl.pdb
    ${CURRENT_PACKAGES_DIR}/debug/bin/c_rehash.pl
    ${CURRENT_PACKAGES_DIR}/debug/ct_log_list.cnf
    ${CURRENT_PACKAGES_DIR}/debug/ct_log_list.cnf.dist
    ${CURRENT_PACKAGES_DIR}/debug/openssl.cnf
    ${CURRENT_PACKAGES_DIR}/debug/openssl.cnf.dist
    ${CURRENT_PACKAGES_DIR}/bin/openssl.pdb
    ${CURRENT_PACKAGES_DIR}/bin/c_rehash.pl
    ${CURRENT_PACKAGES_DIR}/ct_log_list.cnf
    ${CURRENT_PACKAGES_DIR}/ct_log_list.cnf.dist
    ${CURRENT_PACKAGES_DIR}/openssl.cnf
    ${CURRENT_PACKAGES_DIR}/openssl.cnf.dist
)

file(MAKE_DIRECTORY ${CURRENT_PACKAGES_DIR}/tools/openssl/)
file(RENAME ${CURRENT_PACKAGES_DIR}/bin/openssl.exe ${CURRENT_PACKAGES_DIR}/tools/openssl/openssl.exe)

vcpkg_copy_tool_dependencies(${CURRENT_PACKAGES_DIR}/tools/openssl)

if(VCPKG_LIBRARY_LINKAGE STREQUAL static)
    # They should be empty, only the exes deleted above were in these directories
    file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/debug/bin/)
    file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/bin/)
endif()

vcpkg_copy_pdbs()

file(COPY ${CMAKE_CURRENT_LIST_DIR}/usage DESTINATION ${CURRENT_PACKAGES_DIR}/share/${PORT})
file(INSTALL ${MASTER_COPY_SOURCE_PATH}/LICENSE DESTINATION ${CURRENT_PACKAGES_DIR}/share/${PORT} RENAME copyright)

vcpkg_test_cmake(PACKAGE_NAME OpenSSL MODULE)
