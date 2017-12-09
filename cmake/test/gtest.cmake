_generate_function_if_testing_is_disabled(
  "catkin_add_gtest"
  "catkin_add_gmock")

#
# Add a GTest based test target.
#
# An executable target is created with the source files, it is linked
# against GTest and added to the set of unit tests.
#
# .. note:: The test can be executed by calling the binary directly
#   or using: ``make run_tests_${PROJECT_NAME}_gtest_${target}``
#
# :param target: the target name
# :type target: string
# :param source_files: a list of source files used to build the test
#   executable
# :type source_files: list of strings
# :param TIMEOUT: currently not supported
# :type TIMEOUT: integer
# :param WORKING_DIRECTORY: the working directory when executing the
#   executable
# :type WORKING_DIRECTORY: string
#
# @public
#
function(catkin_add_gtest target)
  _catkin_add_google_test("gtest" ${target} ${ARGN})
endfunction()

#
# Add a GMock based test target.
#
# An executable target is created with the source files, it is linked
# against GTest and GMock and added to the set of unit tests.
#
# .. note:: The test can be executed by calling the binary directly
#   or using: ``make run_tests_${PROJECT_NAME}_gtest_${target}``
#
# :param target: the target name
# :type target: string
# :param source_files: a list of source files used to build the test
#   executable
# :type source_files: list of strings
# :param TIMEOUT: currently not supported
# :type TIMEOUT: integer
# :param WORKING_DIRECTORY: the working directory when executing the
#   executable
# :type WORKING_DIRECTORY: string
#
# @public
#
function(catkin_add_gmock target)
  _catkin_add_google_test("gmock" ${target} ${ARGN})
endfunction()

#
# This is an internal function, use catkin_add_gtest or catkin_add_gmock
# instead.
#
# :param type: "gtest" or "gmock"
# The remaining arguments are the same as for catkin_add_gtest and
# catkin_add_gmock.
#
function(_catkin_add_google_test type target)
  if (NOT "${type}" STREQUAL "gtest" AND NOT "${type}" STREQUAL "gmock")
    message(FATAL_ERROR
      "Invalid use of _catkin_add_google_test function, "
      "first argument must be 'gtest' or 'gmock'")
  endif()
  _warn_if_skip_testing("catkin_add_${type}")

  # XXX look for optional TIMEOUT argument, #2645
  cmake_parse_arguments(ARG "" "TIMEOUT;WORKING_DIRECTORY" "" ${ARGN})
  if(ARG_TIMEOUT)
    message(WARNING "TIMEOUT argument to catkin_add_${type}() is ignored")
  endif()

  _catkin_add_executable_with_google_test(${type} ${target} ${ARG_UNPARSED_ARGUMENTS} EXCLUDE_FROM_ALL)

  if(TARGET ${target})
    # make sure the target is built before running tests
    add_dependencies(tests ${target})

    # XXX we DONT use rosunit to call the executable to get process control, #1629, #3112
    get_target_property(_target_path ${target} RUNTIME_OUTPUT_DIRECTORY)
    set(cmd "${_target_path}/${target} --gtest_output=xml:${CATKIN_TEST_RESULTS_DIR}/${PROJECT_NAME}/gtest-${target}.xml")
    catkin_run_tests_target("gtest" ${target} "gtest-${target}.xml" COMMAND ${cmd} DEPENDENCIES ${target} WORKING_DIRECTORY ${ARG_WORKING_DIRECTORY})
  endif()
endfunction()

#
# Add a GTest executable target.
#
# An executable target is created with the source files, it is linked
# against GTest.
# If you also want to register the executable as a test use
# ``catkin_add_gtest()`` instead.
#
# :param target: the target name
# :type target: string
# :param source_files: a list of source files used to build the test
#   executable
# :type source_files: list of strings
#
# Additionally, the option EXCLUDE_FROM_ALL can be specified.
# @public
#
function(catkin_add_executable_with_gtest target)
  _catkin_add_executable_with_google_test("gtest" ${target} ${ARGN})
endfunction()

#
# Add a GMock executable target.
#
# An executable target is created with the source files, it is linked
# against GTest and GMock.
# If you also want to register the executable as a test use
# ``catkin_add_gtest()`` instead.
#
# :param target: the target name
# :type target: string
# :param source_files: a list of source files used to build the test
#   executable
# :type source_files: list of strings
#
# Additionally, the option EXCLUDE_FROM_ALL can be specified.
# @public
#
function(catkin_add_executable_with_gmock target)
  _catkin_add_executable_with_google_test("gmock" ${target} ${ARGN})
endfunction()

#
# This is an internal function, use catkin_add_executable_with_gtest
# or catkin_add_executable_with_gmock instead.
#
# :param type: "gtest" or "gmock"
# The remaining arguments are the same as for
# catkin_add_executable_with_gtest and
# catkin_add_executable_with_gmock.
#
function(_catkin_add_executable_with_google_test type target)
  if (NOT "${type}" STREQUAL "gtest" AND NOT "${type}" STREQUAL "gmock")
    message(FATAL_ERROR "Invalid use of _catkin_add_executable_google_test function, first argument must be 'gtest' or 'gmock'")
  endif()
  string(TOUPPER "${type}" type_upper)
  if(NOT ${type_upper}_FOUND AND NOT ${type_upper}_FROM_SOURCE_FOUND)
    message(WARNING "skipping ${type} '${target}' in project '${PROJECT_NAME}' because ${type} was not found")
    return()
  endif()

  if(NOT DEFINED CMAKE_RUNTIME_OUTPUT_DIRECTORY)
    message(FATAL_ERROR "catkin_add_executable_with_${type}() must be called after catkin_package() so that default output directories for the executables are defined")
  endif()

  cmake_parse_arguments(ARG "EXCLUDE_FROM_ALL" "" "" ${ARGN})

  if ("${type}" STREQUAL "gmock")
    # gmock requires gtest headers and libraries
    list(APPEND GMOCK_INCLUDE_DIRS ${GTEST_INCLUDE_DIRS})
    list(APPEND GMOCK_LIBRARY_DIRS ${GTEST_LIBRARY_DIRS})
    list(APPEND GMOCK_LIBRARIES ${GTEST_LIBRARIES})
  endif()

  # create the executable, with basic + gtest/gmock build flags
  include_directories(${${type_upper}_INCLUDE_DIRS})
  link_directories(${${type_upper}_LIBRARY_DIRS})
  add_executable(${target} ${ARG_UNPARSED_ARGUMENTS})
  if(ARG_EXCLUDE_FROM_ALL)
    set_target_properties(${target} PROPERTIES EXCLUDE_FROM_ALL TRUE)
  endif()

  assert(${type_upper}_LIBRARIES)
  target_link_libraries(${target} ${${type_upper}_LIBRARIES} ${THREADS_LIBRARY})

  # make sure gtest/gmock is built before the target
  add_dependencies(${target} ${${type_upper}_LIBRARIES})
endfunction()

hunter_add_package(GTest)

if(NOT EXISTS "${GTest_LICENSES}")
  message(FATAL_ERROR "File not found: '${GTest_LICENSES}")
endif()
message("GTest License file: '${GTest_LICENSES}'")

find_package(GMock CONFIG REQUIRED)
find_package(GTest CONFIG REQUIRED)
message(STATUS "Using hunterised GMock/GTest: gmock and gtests will be built")
set(GMOCK_LIBRARIES GMock::main CACHE INTERNAL "")
set(GTEST_LIBRARIES GTest::main CACHE INTERNAL "")
set(GMOCK_FOUND TRUE)
set(GTEST_FOUND TRUE)
