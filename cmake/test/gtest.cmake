_generate_function_if_testing_is_disabled("catkin_add_gtest")

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
  _warn_if_skip_testing("catkin_add_gtest")

  # XXX look for optional TIMEOUT argument, #2645
  cmake_parse_arguments(ARG "" "TIMEOUT;WORKING_DIRECTORY" "" ${ARGN})
  if(ARG_TIMEOUT)
    message(WARNING "TIMEOUT argument to catkin_add_gtest() is ignored")
  endif()

  catkin_add_executable_with_gtest(${target} ${ARG_UNPARSED_ARGUMENTS} EXCLUDE_FROM_ALL)

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
  if(NOT GTEST_FOUND AND NOT GTEST_FROM_SOURCE_FOUND)
    message(WARNING "skipping gtest '${target}' in project '${PROJECT_NAME}'")
    return()
  endif()

  if(NOT DEFINED CMAKE_RUNTIME_OUTPUT_DIRECTORY)
    message(FATAL_ERROR "catkin_add_executable_with_gtest() must be called after catkin_package() so that default output directories for the executables are defined")
  endif()

  cmake_parse_arguments(ARG "EXCLUDE_FROM_ALL" "" "" ${ARGN})

  # create the executable, with basic + gtest build flags
  include_directories(${GTEST_INCLUDE_DIRS})
  link_directories(${GTEST_LIBRARY_DIRS})
  add_executable(${target} ${ARG_UNPARSED_ARGUMENTS})
  if(ARG_EXCLUDE_FROM_ALL)
    set_target_properties(${target} PROPERTIES EXCLUDE_FROM_ALL TRUE)
  endif()

  assert(GTEST_LIBRARIES)
  target_link_libraries(${target} ${GTEST_LIBRARIES} ${THREADS_LIBRARY})
endfunction()

hunter_add_package(GTest)

find_package(GTest CONFIG REQUIRED)
message(STATUS "Using hunterised GTest: gtests will be built")
set(GMOCK_LIBRARIES GMock::main CACHE INTERNAL "")
set(GTEST_LIBRARIES GTest::main CACHE INTERNAL "")
set(GMOCK_FOUND TRUE)
set(GTEST_FOUND TRUE)
