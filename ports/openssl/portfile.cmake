if(VCPKG_CMAKE_SYSTEM_NAME STREQUAL "WindowsStore")
    include(${CMAKE_CURRENT_LIST_DIR}/portfile-uwp.cmake)
    return()
endif()

include(vcpkg_common_functions)
set(OPENSSL_VERSION 1.0.2k)
set(MASTER_COPY_SOURCE_PATH ${CURRENT_BUILDTREES_DIR}/src/openssl-${OPENSSL_VERSION})
vcpkg_find_acquire_program(PERL)
find_program(NMAKE nmake)

get_filename_component(PERL_EXE_PATH ${PERL} DIRECTORY)
set(ENV{PATH} "${PERL_EXE_PATH};$ENV{PATH}")

vcpkg_download_distfile(OPENSSL_SOURCE_ARCHIVE
    URLS "https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz"
    FILENAME "openssl-${OPENSSL_VERSION}.tar.gz"
	SHA512 0d314b42352f4b1df2c40ca1094abc7e9ad684c5c35ea997efdd58204c70f22a1abcb17291820f0fff3769620a4e06906034203d31eb1a4d540df3e0db294016
)

vcpkg_extract_source_archive(${OPENSSL_SOURCE_ARCHIVE})
vcpkg_apply_patches(
    SOURCE_PATH ${MASTER_COPY_SOURCE_PATH}
    PATCHES ${CMAKE_CURRENT_LIST_DIR}/PerlScriptSpaceInPathFixes.patch
            ${CMAKE_CURRENT_LIST_DIR}/ConfigureIncludeQuotesFix.patch
            ${CMAKE_CURRENT_LIST_DIR}/STRINGIFYPatch.patch
)

if(VCPKG_CRT_LINKAGE STREQUAL "static")
    vcpkg_apply_patches(
        SOURCE_PATH ${MASTER_COPY_SOURCE_PATH}
        PATCHES ${CMAKE_CURRENT_LIST_DIR}/StaticCRT.patch
    )
endif()

set(CONFIGURE_COMMAND ${PERL} Configure
    enable-static-engine
    enable-capieng
    no-asm
    no-ssl2
)

if(TARGET_TRIPLET MATCHES "x86-windows")
    set(OPENSSL_ARCH VC-WIN32)
    set(OPENSSL_DO "ms\\do_ms.bat")
elseif(TARGET_TRIPLET MATCHES "x64")
    set(OPENSSL_ARCH VC-WIN64A)
    set(OPENSSL_DO "ms\\do_win64a.bat")
else()
    message(FATAL_ERROR "Unsupported target triplet: ${TARGET_TRIPLET}")
endif()

file(REMOVE_RECURSE ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-dbg)

message(STATUS "Build ${TARGET_TRIPLET}-rel")
file(COPY ${MASTER_COPY_SOURCE_PATH} DESTINATION ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel)
set(SOURCE_PATH_RELEASE ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel/openssl-${OPENSSL_VERSION})
set(OPENSSLDIR_RELEASE ${CURRENT_PACKAGES_DIR})

vcpkg_execute_required_process(
    COMMAND ${CONFIGURE_COMMAND} ${OPENSSL_ARCH} "--prefix=${OPENSSLDIR_RELEASE}" "--openssldir=${OPENSSLDIR_RELEASE}"
    WORKING_DIRECTORY ${SOURCE_PATH_RELEASE}
    LOGNAME configure-perl-${TARGET_TRIPLET}-${CMAKE_BUILD_TYPE}-rel
)
vcpkg_execute_required_process(
    COMMAND ${OPENSSL_DO}
    WORKING_DIRECTORY ${SOURCE_PATH_RELEASE}
    LOGNAME configure-do-${TARGET_TRIPLET}-${CMAKE_BUILD_TYPE}-rel
)

if(VCPKG_LIBRARY_LINKAGE STREQUAL dynamic)
    vcpkg_execute_required_process(COMMAND ${NMAKE} -f ms\\ntdll.mak install
                                   WORKING_DIRECTORY ${SOURCE_PATH_RELEASE}
                                   LOGNAME build-${TARGET_TRIPLET}-rel)
else()
    vcpkg_execute_required_process(COMMAND ${NMAKE} -f ms\\nt.mak install
                                   WORKING_DIRECTORY ${SOURCE_PATH_RELEASE}
                                   LOGNAME build-${TARGET_TRIPLET}-rel)
endif()


message(STATUS "Build ${TARGET_TRIPLET}-rel done")

message(STATUS "Build ${TARGET_TRIPLET}-dbg")
file(COPY ${MASTER_COPY_SOURCE_PATH} DESTINATION ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-dbg)
set(SOURCE_PATH_DEBUG ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-dbg/openssl-${OPENSSL_VERSION})
set(OPENSSLDIR_DEBUG ${CURRENT_PACKAGES_DIR}/debug)

vcpkg_execute_required_process(
    COMMAND ${CONFIGURE_COMMAND} debug-${OPENSSL_ARCH} "--prefix=${OPENSSLDIR_DEBUG}" "--openssldir=${OPENSSLDIR_DEBUG}"
    WORKING_DIRECTORY ${SOURCE_PATH_DEBUG}
    LOGNAME configure-perl-${TARGET_TRIPLET}-${CMAKE_BUILD_TYPE}-dbg
)
vcpkg_execute_required_process(
    COMMAND ${OPENSSL_DO}
    WORKING_DIRECTORY ${SOURCE_PATH_DEBUG}
    LOGNAME configure-do-${TARGET_TRIPLET}-${CMAKE_BUILD_TYPE}-dbg
)

if(VCPKG_LIBRARY_LINKAGE STREQUAL dynamic)
    vcpkg_execute_required_process(COMMAND ${NMAKE} -f ms\\ntdll.mak install
                                   WORKING_DIRECTORY ${SOURCE_PATH_DEBUG}
                                   LOGNAME build-${TARGET_TRIPLET}-dbg)
else()
    vcpkg_execute_required_process(COMMAND ${NMAKE} -f ms\\nt.mak install
                                   WORKING_DIRECTORY ${SOURCE_PATH_DEBUG}
                                   LOGNAME build-${TARGET_TRIPLET}-dbg)
endif()

message(STATUS "Build ${TARGET_TRIPLET}-dbg done")

file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/debug/include)
file(REMOVE
    ${CURRENT_PACKAGES_DIR}/debug/bin/openssl.exe
    ${CURRENT_PACKAGES_DIR}/bin/openssl.exe
    ${CURRENT_PACKAGES_DIR}/debug/openssl.cnf
    ${CURRENT_PACKAGES_DIR}/openssl.cnf
)

file(INSTALL ${CMAKE_CURRENT_LIST_DIR}/LICENSE DESTINATION ${CURRENT_PACKAGES_DIR}/share/openssl RENAME copyright)

if(VCPKG_LIBRARY_LINKAGE STREQUAL static)
    # They should be empty, only the exes deleted above were in these directories
    file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/debug/bin/)
    file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/bin/)
endif()

vcpkg_copy_pdbs()