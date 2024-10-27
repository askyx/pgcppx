set(PostgreSQL_ROOT_DIRECTORIES ENV PGROOT ENV PGPATH ENV PATH ${PostgreSQL_ROOT})

set(PostgreSQL_COMPILE_DEFINE "")
set(PostgreSQL_COMPILE_OPTIONS "")
set(PostgreSQL_LINK_OPTIONS "")

find_program(
  PG_CONFIG pg_config
  PATHS ${PostgreSQL_ROOT_DIRECTORIES}
  PATH_SUFFIXES bin)

if(NOT PG_CONFIG)
  message(FATAL_ERROR "Could not find pg_config")
else()
  set(PostgreSQL_FOUND TRUE)
endif()

message(STATUS "Found pg_config as ${PG_CONFIG}")

if(PostgreSQL_FOUND)
  macro(PG_CONFIG VAR OPT)
    execute_process(
      COMMAND ${PG_CONFIG} ${OPT}
      OUTPUT_VARIABLE ${VAR}
      OUTPUT_STRIP_TRAILING_WHITESPACE)
  endmacro()

  pg_config(_pg_bindir --bindir)
  pg_config(_pg_includedir --includedir)
  pg_config(_pg_pkgincludedir --pkgincludedir)
  pg_config(_pg_sharedir --sharedir)
  pg_config(_pg_includedir_server --includedir-server)
  pg_config(_pg_libs --libs)
  pg_config(_pg_ldflags --ldflags)
  pg_config(_pg_ldflags_sl --ldflags_sl)
  pg_config(_pg_ldflags_ex --ldflags_ex)
  pg_config(_pg_pkglibdir --pkglibdir)
  pg_config(_pg_libdir --libdir)
  pg_config(_pg_version --version)

  separate_arguments(_pg_ldflags)
  separate_arguments(_pg_ldflags_sl)
  separate_arguments(_pg_ldflags_ex)

  set(_server_lib_dirs ${_pg_libdir} ${_pg_pkglibdir})
  set(_server_inc_dirs ${_pg_includedir} ${_pg_pkgincludedir} ${_pg_includedir_server})
  string(REPLACE ";" " " _shared_link_options
                 "${_pg_ldflags};${_pg_ldflags_sl}")
  set(_link_options ${_pg_ldflags})
  if(_pg_ldflags_ex)
    list(APPEND _link_options ${_pg_ldflags_ex})
  endif()

  set(PostgreSQL_INCLUDE_DIRS
      "${_pg_includedir}"
      CACHE PATH
            "Top-level directory containing the PostgreSQL include directories."
  )
  set(PostgreSQL_EXTENSION_DIR
      "${_pg_sharedir}/extension"
      CACHE PATH "Directory containing extension SQL and control files")
  set(PostgreSQL_SERVER_INCLUDE_DIRS
      "${_server_inc_dirs}"
      CACHE PATH "PostgreSQL include directories for server include files.")
  set(PostgreSQL_LIBRARY_DIRS
      "${_pg_libdir}"
      CACHE PATH "library directory for PostgreSQL")
  set(PostgreSQL_LIBRARIES
      "${_pg_libs}"
      CACHE PATH "Libraries for PostgreSQL")
  set(PostgreSQL_SHARED_LINK_OPTIONS
      "${_shared_link_options}"
      CACHE STRING "PostgreSQL linker options for shared libraries.")
  set(PostgreSQL_LINK_OPTIONS
      "${_pg_ldflags},${_pg_ldflags_ex}"
      CACHE STRING "PostgreSQL linker options for executables.")
  set(PostgreSQL_SERVER_LIBRARY_DIRS
      "${_server_lib_dirs}"
      CACHE PATH "PostgreSQL server library directories.")
  set(PostgreSQL_VERSION_STRING
      "${_pg_version}"
      CACHE STRING "PostgreSQL version string")
  set(PostgreSQL_PACKAGE_LIBRARY_DIR
    "${_pg_pkglibdir}"
    CACHE STRING "PostgreSQL package library directory")

  find_program(
    PG_BINARY postgres
    PATHS ${PostgreSQL_ROOT_DIRECTORIES}
    HINTS ${_pg_bindir}
    PATH_SUFFIXES bin)

  if(NOT PG_BINARY)
    message(FATAL_ERROR "Could not find postgres binary")
  endif()

  message(STATUS "Found postgres binary at ${PG_BINARY}")

  find_program(PG_REGRESS pg_regress HINT
    ${PostgreSQL_PACKAGE_LIBRARY_DIR}/pgxs/src/test/regress)
  if(NOT PG_REGRESS)
    message(STATUS "Could not find pg_regress, tests not executed")
  endif()

  message(STATUS "PostgreSQL version ${PostgreSQL_VERSION_STRING} found")
  message(
    STATUS
    "PostgreSQL package library directory: ${PostgreSQL_PACKAGE_LIBRARY_DIR}")
  message(STATUS "PostgreSQL libraries: ${PostgreSQL_LIBRARIES}")
  message(STATUS "PostgreSQL extension directory: ${PostgreSQL_EXTENSION_DIR}")
  message(STATUS "PostgreSQL linker options: ${PostgreSQL_LINK_OPTIONS}")
  message(
    STATUS "PostgreSQL shared linker options: ${PostgreSQL_SHARED_LINK_OPTIONS}")
endif()

# add_postgresql_extension(NAME ...)
#
# VERSION Version of the extension. Is used when generating the control file.
# Required.
#
# ENCODING Encoding for the control file. Optional.
#
# COMMENT Comment for the control file. Optional.
#
# SOURCES List of source files to compile for the extension.
#
# REQUIRES List of extensions that are required by this extension.
#
# SCRIPTS Script files.
#
# SCRIPT_TEMPLATES Template script files.
#
# MOUDULES List of header files to include in the extension.
#
# TEST_SOURCE Source file for the test suite write in CPP.
function(add_postgresql_extension NAME)
  set(_optional)
  set(_single VERSION ENCODING)
  set(_multi SOURCES SCRIPTS SCRIPT_TEMPLATES REQUIRES MOUDULES TEST_SOURCE)
  cmake_parse_arguments(_ext "${_optional}" "${_single}" "${_multi}" ${ARGN})

  if(NOT _ext_VERSION)
    message(FATAL_ERROR "Extension version not set")
  endif()

  add_library(${NAME} MODULE ${_ext_SOURCES})

  target_sources(
    ${NAME}
      PUBLIC
        FILE_SET CXX_MODULES FILES
        ${_ext_MOUDULES}
  )

  set(_link_flags "${PostgreSQL_SHARED_LINK_OPTIONS}")
  foreach(_dir ${PostgreSQL_SERVER_LIBRARY_DIRS})
    set(_link_flags "${_link_flags} -L${_dir}")
  endforeach()

  # Collect and build script files to install
  set(_script_files ${_ext_SCRIPTS})
  foreach(_template ${_ext_SCRIPT_TEMPLATES})
    string(REGEX REPLACE "\.in$" "" _script ${_template})
    configure_file(${_template} ${_script} @ONLY)
    list(APPEND _script_files ${CMAKE_CURRENT_BINARY_DIR}/${_script})
    message(
      STATUS "Building script file ${_script} from template file ${_template}")
  endforeach()

  if(APPLE)
    set(_link_flags "${_link_flags} -bundle_loader ${PG_BINARY}")
  endif()

  if (_ext_DEPENDS_LIB)
    target_link_libraries(${NAME} PRIVATE ${_ext_DEPENDS_LIB})
    target_link_options(${NAME} PRIVATE "--coverage")
  endif()

  set_target_properties(
    ${NAME}
      PROPERTIES
        PREFIX ""
  )

  target_link_options(
    ${NAME}
      PRIVATE
        ${PostgreSQL_LINK_OPTIONS}
  )

  target_include_directories(
    ${NAME}
      PUBLIC ${PostgreSQL_SERVER_INCLUDE_DIRS}
  )

  target_compile_definitions(
    ${NAME}
      PUBLIC
        ${PostgreSQL_COMPILE_DEFINE}
  )

  target_compile_options(
    ${NAME}
      PUBLIC
        ${PostgreSQL_COMPILE_OPTIONS}
  )

  # Generate control file at build time (which is when GENERATE evaluate the
  # contents). We do not know the target file name until then.
  set(_control_file "${CMAKE_CURRENT_BINARY_DIR}/${NAME}.control")
  file(
    GENERATE
    OUTPUT ${_control_file}
    CONTENT
      "# This file is generated content from add_postgresql_extension.
# No point in modifying it, it will be overwritten anyway.

# Default version, always set
default_version = '${_ext_VERSION}'

# Module pathname generated from target shared library name. Use
# MODULE_PATHNAME in script file.
module_pathname = '$libdir/$<TARGET_FILE_NAME:${NAME}>'

# Comment for extension. Set using COMMENT option. Can be set in
# script file as well.
$<$<NOT:$<BOOL:${_ext_COMMENT}>>:#>comment = '${_ext_COMMENT}'

# Encoding for script file. Set using ENCODING option.
$<$<NOT:$<BOOL:${_ext_ENCODING}>>:#>encoding = '${_ext_ENCODING}'

# Required extensions. Set using REQUIRES option (multi-valued).
$<$<NOT:$<BOOL:${_ext_REQUIRES}>>:#>requires = '$<JOIN:${_ext_REQUIRES},$<COMMA>>'
")

  install(TARGETS ${NAME} LIBRARY DESTINATION ${PostgreSQL_PACKAGE_LIBRARY_DIR})
  install(FILES ${_control_file} ${_script_files}
          DESTINATION ${PostgreSQL_EXTENSION_DIR})

  if(PG_REGRESS)

    set(TEST_DIR ${CMAKE_CURRENT_SOURCE_DIR}/test/regress)
    set(TEST_SCHEDULE ${TEST_DIR}/schedule)
    set(TEST_CONFIG ${TEST_DIR}/regression.conf)

    if(NOT EXISTS ${TEST_SCHEDULE})
      # TODO: scan all test files and create a default schedule.
      message(STATUS "Schedule file ${TEST_SCHEDULE} does not exist, using default schedule")
    else()
      message(STATUS "Test using schedule file ${TEST_SCHEDULE}")
      add_test(
        NAME ${NAME}
        COMMAND
          ${PG_REGRESS} --temp-instance=${CMAKE_BINARY_DIR}/tmp_check
          --temp-config=${TEST_CONFIG}
          --inputdir=${TEST_DIR}
          --outputdir=${CMAKE_CURRENT_BINARY_DIR}/test --load-extension=${NAME}
          --schedule ${TEST_SCHEDULE}
      )
    endif()
  endif()
endfunction()